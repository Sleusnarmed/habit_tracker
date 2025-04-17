// providers/task_provider.dart
import 'package:flutter/material.dart';
import 'package:habit_tracker/models/task.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TaskProvider with ChangeNotifier {
  final Box<Task> _tasksBox;

  TaskProvider(this._tasksBox);

  List<Task> get tasks => _tasksBox.values.toList();

  List<Task> getTasksByCategory(String category) {
    if (category == 'All') return tasks;
    return tasks.where((task) => task.category == category).toList();
  }

  List<String> get categories {
    final allCategories = tasks.map((task) => task.category).toSet().toList();
    return ['All', ...allCategories];
  }

  Future<void> addTask(Task task) async {
    await _tasksBox.put(task.id, task);
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    await _tasksBox.put(task.id, task);
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksBox.delete(taskId);
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updatedTask);
  }

  Future<void> addCategory(String category) async {
    // Categories are derived from tasks, so we just need to notify
    notifyListeners();
  }
}