import 'package:flutter/material.dart'; // Add this import
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../models/task.dart';

class TaskDataSource extends CalendarDataSource {
  TaskDataSource(List<Task> tasks) {
    // Filter out tasks without valid startDateTime
    appointments = tasks.where((task) => task.startDateTime != null).toList();
  }

  @override
  DateTime getStartTime(int index) {
    return _getTask(index).startDateTime!;
  }

  @override
  DateTime getEndTime(int index) {
    final task = _getTask(index);
    return task.endDateTime ?? 
           task.startDateTime!.add(const Duration(hours: 1));
  }

  @override
  String getSubject(int index) {
    return _getTask(index).title;
  }

  @override
  Color getColor(int index) {
    return _getPriorityColor(_getTask(index).priority);
  }

  Task _getTask(int index) {
    return appointments![index] as Task;
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.none:
        return Colors.blue;
    }
  }
}