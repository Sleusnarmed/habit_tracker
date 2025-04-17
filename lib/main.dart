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
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(TaskRepetitionAdapter());
   Hive.registerAdapter(DurationAdapter()); 

  // Open boxes 
  final Box<Task> tasksBox = await Hive.openBox<Task>('tasks'); // For tasks
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
      debugShowCheckedModeBanner: false,
      home: const MainNavigationWrapper(),
    );
  }
}

