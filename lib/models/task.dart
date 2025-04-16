import 'package:flutter/material.dart';

class Task {
  final String id;
  final String title;
  final String category;
  bool isCompleted;
  DateTime? dueDate; // Add this field
  TimeOfDay? dueTime; // Add this field

  Task({
    required this.id,
    required this.title,
    required this.category,
    this.isCompleted = false,
    this.dueDate,
    this.dueTime,
  });
}