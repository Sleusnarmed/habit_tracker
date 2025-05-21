import 'package:flutter/material.dart';
import 'package:habit_tracker/models/task.dart';
import 'package:habit_tracker/services/firebase_service.dart';

class TaskProvider with ChangeNotifier {
  final FirebaseService _firebaseService;
  List<Task> _tasks = [];
  List<String> _customCategories = ['Work', 'Study', 'Shopping'];
  bool _isLoading = false;

  TaskProvider({required FirebaseService firebaseService})
    : _firebaseService = firebaseService {
    _loadTasks();
    _loadCategories();
  }

  List<Task> get tasks => _tasks;
  List<String> get categories => ['All', ..._customCategories];
  bool get isLoading => _isLoading;

  Future<void> _loadTasks() async {
    try {
      _isLoading = true;
      notifyListeners();

      _firebaseService.getTasksStream().listen((tasks) {
        _tasks = tasks;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Error loading tasks: $e');
    }
  }

  Future<void> _loadCategories() async {
    // Puedes implementar esto si quieres guardar categorías en Firestore
    // Por ahora mantenemos las categorías locales
  }

  List<Task> getTasksByCategory(String category) {
    if (category == 'All') return _tasks;
    return _tasks.where((task) => task.category == category).toList();
  }

  Future<void> addTask(Task task) async {
    try {
      await _firebaseService.addTask(task);
      // No necesitas notifyListeners() porque el stream ya lo maneja
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _firebaseService.updateTask(task);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firebaseService.deleteTask(taskId);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updatedTask);
  }

  Future<void> addCategory(String category) async {
    if (!_customCategories.contains(category)) {
      _customCategories.add(category);
      notifyListeners();

      // Opcional: Guardar en Firestore si lo necesitas
      // await _firebaseService.saveCategories(_customCategories);
    }
  }

  Future<void> removeCategory(String category) async {
    _customCategories.remove(category);
    notifyListeners();

    // Opcional: Actualizar en Firestore
    // await _firebaseService.saveCategories(_customCategories);

    // Opcional: Actualizar tareas de esta categoría
    final tasksInCategory =
        _tasks.where((t) => t.category == category).toList();
    for (final task in tasksInCategory) {
      await updateTask(task.copyWith(category: 'Uncategorized'));
    }
  }
}
