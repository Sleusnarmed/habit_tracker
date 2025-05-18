import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

part 'task.g.dart'; // Generated file

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

@HiveType(typeId: 0)
class Task {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String category;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final TaskPriority priority;

  @HiveField(6)
  final DateTime? dueDate;

  @HiveField(7)
  final TimeOfDay? startTime;

  @HiveField(8)
  final TimeOfDay? endTime;

  @HiveField(9)
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

  static void registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TaskPriorityAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TaskRepetitionAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TimeOfDayAdapter());
    }
  }
}

class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override
  final int typeId = 1;

  @override
  TaskPriority read(BinaryReader reader) {
    return TaskPriority.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, TaskPriority obj) {
    writer.writeByte(obj.index);
  }
}

class TaskRepetitionAdapter extends TypeAdapter<TaskRepetition> {
  @override
  final int typeId = 2;

  @override
  TaskRepetition read(BinaryReader reader) {
    return TaskRepetition.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, TaskRepetition obj) {
    writer.writeByte(obj.index);
  }
}

class TimeOfDayAdapter extends TypeAdapter<TimeOfDay> {
  @override
  final int typeId = 3;

  @override
  TimeOfDay read(BinaryReader reader) {
    final hour = reader.readByte();
    final minute = reader.readByte();
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void write(BinaryWriter writer, TimeOfDay obj) {
    writer.writeByte(obj.hour);
    writer.writeByte(obj.minute);
  }
}
