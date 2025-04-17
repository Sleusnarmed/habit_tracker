import 'package:flutter/material.dart';
import 'package:habit_tracker/app/navigation/main_nav.dart';
import 'package:habit_tracker/models/task.dart';
import 'package:habit_tracker/providers/task_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';


// sheeesh
import 'package:habit_tracker/views/task_list_view.dart';
import 'package:habit_tracker/views/calendar_view.dart';
import 'package:habit_tracker/views/matrix_view.dart';
import 'package:habit_tracker/views/habits_view.dart';


void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive with a valid directory
  await Hive.initFlutter();

  // Register adapters (generated in step 3)
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(TaskRepetitionAdapter());

  // Open boxes (like database tables)
  final Box<Task> tasksBox = await Hive.openBox<Task>('tasks');
  await Hive.openBox<List<String>>('categories_box'); // For Categories

  runApp(
    ChangeNotifierProvider(
      create: (context) => TaskProvider(tasksBox),
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'habit_tracker',
      theme: ThemeData.light(), // You'll replace with your app_theme.dart
      darkTheme: ThemeData.dark(),
      home: const MainNavigationWrapper(),
    );
  }
}

