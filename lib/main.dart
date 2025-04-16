import 'package:flutter/material.dart';
import 'package:habit_tracker/app/navigation/main_nav.dart';
import 'package:habit_tracker/views/task_list_view.dart';
import 'package:habit_tracker/views/calendar_view.dart';
import 'package:habit_tracker/views/matrix_view.dart';
import 'package:habit_tracker/views/habits_view.dart';


void main() {
  runApp(const MyApp());
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

