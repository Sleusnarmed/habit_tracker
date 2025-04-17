import 'package:hive/hive.dart';

part 'task.g.dart'; // Generated file

@HiveType(typeId: 0)
class Task {
  @HiveField(0) final String id;
  @HiveField(1) final String title;
  @HiveField(2) final String category;
  @HiveField(3) bool isCompleted;
  
  Task({required this.id, required this.title, required this.category, this.isCompleted = false});
  
  Task copyWith({bool? isCompleted}) {
    return Task(
      id: id,
      title: title,
      category: category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}