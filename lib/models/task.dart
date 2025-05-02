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
  final TimeOfDay? startTime; // Renamed from dueTime for clarity

  @HiveField(8)
  final Duration? duration;

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
    this.duration,
    this.repetition = TaskRepetition.never,
  }) {
    // Validate that duration doesn't cross midnight when date and time are provided
    if (hasDuration) {
      if (endDateTime!.day != startDateTime!.day) {
        throw ArgumentError(
          'Task duration cannot cross midnight to another day',
        );
      }
    }
  }

  /// Returns true if this task has both start time and duration
  bool get hasDuration => startTime != null && duration != null;

  /// Returns true if this task has a specific time (without duration)
  bool get hasTime => startTime != null && duration == null;

  /// Returns the start DateTime (combination of dueDate and startTime)
  DateTime? get startDateTime {
    if (dueDate == null) return null;
    if (startTime == null)
      return DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      startTime!.hour,
      startTime!.minute,
    );
  }

  /// Returns the end DateTime (startDateTime + duration)
  DateTime? get endDateTime {
    if (!hasDuration) return null;
    return startDateTime!.add(duration!);
  }

  /// Returns the end TimeOfDay
  TimeOfDay? get endTime {
    if (!hasDuration) return null;
    final end = endDateTime!;
    return TimeOfDay(hour: end.hour, minute: end.minute);
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
    Duration? duration,
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
      duration: duration ?? this.duration,
      repetition: repetition ?? this.repetition,
    );
  }

  /// Formatted time range (e.g., "7:00 PM - 8:00 PM")
  String? get formattedTimeRange {
    if (!hasDuration) {
      if (startTime == null) return null;
      return _formatTimeOfDay(startTime!);
    }
    return '${_formatTimeOfDay(startTime!)} - ${_formatTimeOfDay(endTime!)}';
  }

  /// Formatted duration in hours and minutes (e.g., "1h 30m")
  String? get formattedDuration {
    if (duration == null) return null;
    return '${duration!.inHours}h ${duration!.inMinutes.remainder(60)}m';
  }

  String get formattedDueDate {
    if (dueDate == null) return '';
    if (startTime == null) return DateFormat('MMM d').format(dueDate!);
    return DateFormat('MMM d, h:mm a').format(startDateTime!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  /// Checks if the given time falls within this task's duration
  bool isTimeWithinDuration(TimeOfDay time) {
    if (!hasDuration) return false;

    final timeInMinutes = time.hour * 60 + time.minute;
    final startInMinutes = startTime!.hour * 60 + startTime!.minute;
    final endInMinutes = endTime!.hour * 60 + endTime!.minute;

    return timeInMinutes >= startInMinutes && timeInMinutes <= endInMinutes;
  }

  /// Helper method to format TimeOfDay
  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  static void registerAdapters() {
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(TaskPriorityAdapter());
    Hive.registerAdapter(TaskRepetitionAdapter());
    Hive.registerAdapter(TimeOfDayAdapter());
    Hive.registerAdapter(DurationAdapter());
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
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void write(BinaryWriter writer, TimeOfDay obj) {
    writer.writeByte(obj.hour);
    writer.writeByte(obj.minute);
  }
}

class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = 4;

  @override
  Duration read(BinaryReader reader) {
    final microseconds = reader.readInt();
    return Duration(microseconds: microseconds);
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMicroseconds);
  }
}
