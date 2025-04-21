import 'package:flutter/material.dart';
import 'package:habit_tracker/app/navigation/main_nav.dart';
import 'package:habit_tracker/models/task.dart';
import 'package:habit_tracker/providers/task_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Task.registerAdapters();

  final tasksBox = await Hive.openBox<Task>('tasks');
  await Hive.openBox<List<String>>('categories_box');

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
