// providers/task_provider.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  final Box<Task> _tasksBox;
  late final Box<List<String>> _categoriesBox;
  List<String> _customCategories = ['Work', 'Study', 'Shopping'];

  TaskProvider(this._tasksBox) {
    // Initialize categories box
    _initCategories();
  }

  Future<void> _initCategories() async {
    _categoriesBox = await Hive.openBox<List<String>>('categories_box');
    _customCategories = _categoriesBox.get('categories', defaultValue: _customCategories) ?? _customCategories;
  }

  List<Task> get tasks => _tasksBox.values.whereType<Task>().toList();
  List<String> get categories => ['All', ..._customCategories];

  List<Task> getTasksByCategory(String category) {
    if (category == 'All') return tasks;
    return tasks.where((task) => task.category == category).toList();
  }

  Future<void> _saveCategories() async {
    await _categoriesBox.put('categories', _customCategories);
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
    if (!_customCategories.contains(category)) {
      _customCategories.add(category);
      await _saveCategories();
      notifyListeners();
    }
  }

  Future<void> removeCategory(String category) async {
    _customCategories.remove(category);
    await _saveCategories();
    notifyListeners();
  }
}