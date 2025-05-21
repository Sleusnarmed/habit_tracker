import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habit_tracker/models/task.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Referencia directa a la colección de tareas
  CollectionReference get _tasksCollection => _firestore.collection('tasks');

  // Añadir tarea
  Future<void> addTask(Task task) async {
    await _tasksCollection.doc(task.id).set(task.toFirestore());
  }

  // Obtener stream de tareas
  Stream<List<Task>> getTasksStream() {
    return _tasksCollection
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromFirestore(doc))
            .toList());
  }

  // Actualizar tarea
  Future<void> updateTask(Task task) async {
    await _tasksCollection.doc(task.id).update(task.toFirestore());
  }

  // Eliminar tarea
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }
}