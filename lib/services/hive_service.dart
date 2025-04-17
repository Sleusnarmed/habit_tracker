import 'package:habit_tracker/models/task.dart';
import 'package:hive/hive.dart';

class HiveService {
  // Add a task
  Future<void> addTask(Task task) async {
    final box = Hive.box<Task>('tasks');
    await box.put(task.id, task); // Use ID as key
  }

  // Get all tasks
  List<Task> getTasks() {
    final box = Hive.box<Task>('tasks');
    return box.values.toList();
  }

  // Update a task
  Future<void> updateTask(Task task) async {
    final box = Hive.box<Task>('tasks');
    await box.put(task.id, task);
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    final box = Hive.box<Task>('tasks');
    await box.delete(taskId);
  }
}