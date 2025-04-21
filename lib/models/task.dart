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
  final TimeOfDay? dueTime;

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
    this.dueTime,
    this.duration,
    this.repetition = TaskRepetition.never,
  }) {
    if (dueDate != null && dueTime != null && duration != null) {
      final endTime = dueDateTime!.add(duration!);
      if (endTime.day != dueDate!.day) {
        throw ArgumentError('Task duration cannot cross midnight to another day');
      }
    }
  }

  Task copyWith({
    String? id,
    String? title,
    String? category,
    bool? isCompleted,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    TimeOfDay? dueTime,
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
      dueTime: dueTime ?? this.dueTime,
      duration: duration ?? this.duration,
      repetition: repetition ?? this.repetition,
    );
  }

  DateTime? get dueDateTime {
    if (dueDate == null) return null;
    if (dueTime == null) return DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      dueTime!.hour,
      dueTime!.minute,
    );
  }

  String? get formattedTime {
    if (dueTime == null) return null;
    return _formatTimeOfDay(dueTime!);
  }

  String? get formattedDuration {
    if (duration == null || dueTime == null) return null;
    final endTime = TimeOfDay(
      hour: dueTime!.hour + duration!.inHours,
      minute: dueTime!.minute + (duration!.inMinutes % 60),
    );
    return '${_formatTimeOfDay(dueTime!)} - ${_formatTimeOfDay(endTime)}';
  }

  String get formattedDueDate {
    if (dueDate == null) return '';
    if (dueTime == null) return DateFormat('MMM d').format(dueDate!);
    return DateFormat('MMM d, h:mm a').format(dueDateTime!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

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