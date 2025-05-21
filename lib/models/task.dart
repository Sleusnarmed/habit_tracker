import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { high, medium, low, none }

enum TaskRepetition {
  never,
  daily,
  weekly,
  monthly,
  yearly,
  weekends,
  weekdays,
}

class Task {
  final String id;
  final String title;
  final String category;
  bool isCompleted;
  final String description;
  final TaskPriority priority;
  final DateTime? dueDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final TaskRepetition repetition;

  Task({
    required this.id,
    required this.title,
    required this.category,
    this.isCompleted = false,
    this.description = '',
    this.priority = TaskPriority.none,
    this.dueDate,
    this.startTime,
    this.endTime,
    this.repetition = TaskRepetition.never,
  }) {
    // Validate time consistency
    if (startTime != null && endTime != null) {
      if (!_isTimeAfter(startTime!, endTime!)) {
        throw ArgumentError('End time must be after start time');
      }
    }
  }

  /// Convierte el objeto Task a un Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'isCompleted': isCompleted,
      'description': description,
      'priority': priority.index,
      'dueDate': dueDate?.toIso8601String(),
      'startTime':
          startTime != null
              ? {'hour': startTime!.hour, 'minute': startTime!.minute}
              : null,
      'endTime':
          endTime != null
              ? {'hour': endTime!.hour, 'minute': endTime!.minute}
              : null,
      'repetition': repetition.index,
      'createdAt': FieldValue.serverTimestamp(), // Opcional para ordenamiento
      'updatedAt': FieldValue.serverTimestamp(), // Opcional para seguimiento
    };
  }

  /// Crea un Task desde un DocumentSnapshot de Firestore
  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: data['id'],
      title: data['title'],
      category: data['category'],
      isCompleted: data['isCompleted'] ?? false,
      description: data['description'] ?? '',
      priority:
          TaskPriority.values[data['priority'] ?? TaskPriority.none.index],
      dueDate: data['dueDate'] != null ? DateTime.parse(data['dueDate']) : null,
      startTime:
          data['startTime'] != null
              ? TimeOfDay(
                hour: data['startTime']['hour'],
                minute: data['startTime']['minute'],
              )
              : null,
      endTime:
          data['endTime'] != null
              ? TimeOfDay(
                hour: data['endTime']['hour'],
                minute: data['endTime']['minute'],
              )
              : null,
      repetition:
          TaskRepetition.values[data['repetition'] ??
              TaskRepetition.never.index],
    );
  }

  /// Returns true if this task has both start and end times
  bool get hasTimeRange => startTime != null && endTime != null;

  /// Returns true if this task has only start time
  bool get hasSingleTime => startTime != null && endTime == null;

  /// Returns the start DateTime (combination of dueDate and startTime)
  DateTime? get startDateTime {
    if (dueDate == null) return null;
    final localDate = dueDate!.toLocal();
    if (startTime == null)
      return DateTime(localDate.year, localDate.month, localDate.day);
    return DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      startTime!.hour,
      startTime!.minute,
    );
  }

  /// Returns the end DateTime (combination of dueDate and endTime)
  DateTime? get endDateTime {
    if (dueDate == null || endTime == null) return null;
    return DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      endTime!.hour,
      endTime!.minute,
    );
  }

  /// Calculated duration based on start and end times
  Duration? get duration {
    if (!hasTimeRange) return null;
    return _calculateDuration(startTime!, endTime!);
  }

  Task copyWith({
    String? id,
    String? title,
    String? category,
    bool? isCompleted,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    TaskRepetition? repetition,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      repetition: repetition ?? this.repetition,
    );
  }

  /// Formatted time range
  String? get formattedTimeRange {
    if (!hasTimeRange) {
      if (startTime == null) return null;
      return _formatTimeOfDay(startTime!);
    }
    return '${_formatTimeOfDay(startTime!)} - ${_formatTimeOfDay(endTime!)}';
  }

  /// Formatted duration in hours and minutes
  String? get formattedDuration {
    if (!hasTimeRange) return null;
    final dur = duration!;
    return '${dur.inHours}h ${dur.inMinutes.remainder(60)}m';
  }

  String get formattedDueDate {
    if (dueDate == null) return '';
    if (startTime == null) return DateFormat('MMM d').format(dueDate!);
    return DateFormat('MMM d, h:mm a').format(startDateTime!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    if (dueDay == today) return true;

    switch (repetition) {
      case TaskRepetition.daily:
        return true;
      case TaskRepetition.weekdays:
        return now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
      case TaskRepetition.weekends:
        return now.weekday == DateTime.saturday ||
            now.weekday == DateTime.sunday;
      case TaskRepetition.weekly:
        return dueDate!.weekday == now.weekday;
      case TaskRepetition.monthly:
        if (dueDate!.day > now.day && now.month == DateTime.december) {
          return false;
        }
        return dueDate!.day == now.day;
      case TaskRepetition.yearly:
        return dueDate!.month == now.month && dueDate!.day == now.day;
      case TaskRepetition.never:
      default:
        return false;
    }
  }

  bool isTimeWithinDuration(TimeOfDay time) {
    if (!hasTimeRange) return false;

    final timeInMinutes = time.hour * 60 + time.minute;
    final startInMinutes = startTime!.hour * 60 + startTime!.minute;
    final endInMinutes = endTime!.hour * 60 + endTime!.minute;

    return timeInMinutes >= startInMinutes && timeInMinutes <= endInMinutes;
  }

  // Helper method to check if time b is after time a
  bool _isTimeAfter(TimeOfDay a, TimeOfDay b) {
    return b.hour > a.hour || (b.hour == a.hour && b.minute > a.minute);
  }

  // Helper method to calculate duration between two times
  Duration _calculateDuration(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (endMinutes > startMinutes) {
      return Duration(minutes: endMinutes - startMinutes);
    } else {
      return Duration(minutes: (24 * 60 - startMinutes) + endMinutes);
    }
  }

  // Helper method to format TimeOfDay
  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          category == other.category &&
          isCompleted == other.isCompleted &&
          description == other.description &&
          priority == other.priority &&
          dueDate == other.dueDate &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          repetition == other.repetition;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      category.hashCode ^
      isCompleted.hashCode ^
      description.hashCode ^
      priority.hashCode ^
      dueDate.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      repetition.hashCode;
}
