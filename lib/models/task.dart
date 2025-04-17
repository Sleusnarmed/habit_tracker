import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'task.g.dart'; // Generated file

enum TaskPriority { high, medium, low, none }
enum TaskRepetition { never, daily, weekly, monthly, yearly, weekends, weekdays }

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
  final DateTime? dueTime;
  
  @HiveField(7)
  final Duration? duration;
  
  @HiveField(8)
  final TaskRepetition repetition;
  
  Task({
    required this.id,
    required this.title,
    required this.category,
    this.isCompleted = false,
    this.description = '',
    this.priority = TaskPriority.none,
    this.dueTime,
    this.duration,
    this.repetition = TaskRepetition.never,
  }) {
    // Validate that duration doesn't cross midnight if dueTime is set
    if (dueTime != null && duration != null) {
      final endTime = dueTime!.add(duration!);
      if (endTime.day != dueTime!.day) {
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
    DateTime? dueTime,
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
      dueTime: dueTime ?? this.dueTime,
      duration: duration ?? this.duration,
      repetition: repetition ?? this.repetition,
    );
  }
  
  // Helper method to format time for display
  String? get formattedTime {
    if (dueTime == null) return null;
    return DateFormat.jm().format(dueTime!);
  }
  
  // Helper method to format duration for display
  String? get formattedDuration {
    if (duration == null || dueTime == null) return null;
    final endTime = dueTime!.add(duration!);
    return '${DateFormat.jm().format(dueTime!)} - ${DateFormat.jm().format(endTime)}';
  }
  
  // Helper method to check if task is due today
  bool get isDueToday {
    if (dueTime == null) return false;
    final now = DateTime.now();
    return dueTime!.year == now.year && 
           dueTime!.month == now.month && 
           dueTime!.day == now.day;
  }
}

// Adapter for enum serialization
class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override
  final int typeId = 10;

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
  final int typeId = 11;

  @override
  TaskRepetition read(BinaryReader reader) {
    return TaskRepetition.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, TaskRepetition obj) {
    writer.writeByte(obj.index);
  }
}