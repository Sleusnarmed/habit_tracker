import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habit_tracker/services/calendar_preferences.dart';
import 'package:habit_tracker/widgets/calendarScreen/list_view.dart';
import 'package:habit_tracker/widgets/calendarScreen/month_view.dart';
import 'package:habit_tracker/widgets/calendarScreen/day_view.dart';
import 'package:habit_tracker/widgets/calendarScreen/three_day_view.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:habit_tracker/widgets/calendarScreen/weekly_view.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCalendarScreen extends StatefulWidget {
  final List<String> categories;

  const TaskCalendarScreen({super.key, this.categories = const []});

  @override
  State<TaskCalendarScreen> createState() => _TaskCalendarScreenState();
}

class _TaskCalendarScreenState extends State<TaskCalendarScreen> {
  late CalendarController _calendarController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _showQuickOptions = false;
  String _currentView = CalendarPreferences.currentView;
  double _dragDistance = 0;
  bool _showCalendar = true;

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    // No initialization needed for Firestore
  }

  Future<void> _updateTask(Task updatedTask) async {
    try {
      await _firestore.collection('tasks').doc(updatedTask.id).update(updatedTask.toFirestore());
      // No need for setState, StreamBuilder will handle updates
    } catch (e) {
      print('Error updating task: $e');
      // Handle error as needed
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).delete();
      // No need for setState, StreamBuilder will handle updates
    } catch (e) {
      print('Error deleting task: $e');
      // Handle error as needed
    }
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(
                  _calendarController.displayDate ?? DateTime.now()),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                setState(() {
                  _showQuickOptions = !_showQuickOptions;
                });
              },
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _currentView == 'List'
          ? GestureDetector(
              onVerticalDragStart: (_) => _dragDistance = 0,
              onVerticalDragUpdate: (details) {
                if (details.delta.dy.abs() > details.delta.dx.abs()) {
                  _dragDistance += details.delta.dy;
                }
              },
              onVerticalDragEnd: (_) {
                if (_dragDistance < -50 && _showCalendar) {
                  setState(() => _showCalendar = false);
                } else if (_dragDistance > 50 && !_showCalendar) {
                  setState(() => _showCalendar = true);
                }
                _dragDistance = 0;
              },
              child: Column(
                children: [
                  if (_showQuickOptions) _buildQuickOptionsContainer(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('tasks').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final tasks = snapshot.data!.docs
                            .map((doc) => Task.fromFirestore(doc))
                            .toList();

                        return TaskListView(
                          calendarController: _calendarController,
                          tasks: tasks,
                          selectedDate: _calendarController.displayDate ?? DateTime.now(),
                          categories: widget.categories,
                          onTaskUpdated: _updateTask,
                          onTaskDeleted: _deleteTask,
                          showCalendar: _showCalendar,
                          onCalendarVisibilityChanged: (visible) {
                            setState(() => _showCalendar = visible);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (_showQuickOptions) _buildQuickOptionsContainer(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('tasks').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final tasks = snapshot.data!.docs
                          .map((doc) => Task.fromFirestore(doc))
                          .where((task) => task.dueDate != null)
                          .toList();

                      return _buildCurrentView(tasks);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickOptionsContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildViewOption('List'),
          _buildViewOption('Month'),
          _buildViewOption('Day'),
          _buildViewOption('3 Days'),
          _buildViewOption('Weekly'),
        ],
      ),
    );
  }

  Widget _buildViewOption(String viewName) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentView = viewName;
          CalendarPreferences.currentView = viewName;
          _showQuickOptions = false;
          if (viewName != 'List') {
            _calendarController.view = _getCalendarView(viewName);
            _showCalendar = true;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _currentView == viewName
              ? Colors.orange.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          viewName,
          style: TextStyle(
            fontSize: 14,
            color: _currentView == viewName ? Colors.orange : Colors.black,
            fontWeight:
                _currentView == viewName ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  CalendarView _getCalendarView(String viewName) {
    switch (viewName) {
      case 'Month':
        return CalendarView.month;
      case 'Day':
        return CalendarView.day;
      case '3 Days':
      case 'Weekly':
        return CalendarView.week;
      default:
        return CalendarView.month;
    }
  }

  Widget _buildCurrentView(List<Task> tasks) {
    final currentDate = _calendarController.displayDate ?? DateTime.now();

    switch (_currentView) {
      case 'List':
        return TaskListView(
          calendarController: _calendarController,
          tasks: tasks,
          selectedDate: currentDate,
          categories: widget.categories,
          onTaskUpdated: _updateTask,
          onTaskDeleted: _deleteTask,
          showCalendar: _showCalendar,
          onCalendarVisibilityChanged: (visible) {
            setState(() => _showCalendar = visible);
          },
        );
      case 'Month':
        return MonthView(
          calendarController: _calendarController,
          tasks: tasks,
          key: ValueKey('MonthView-$currentDate'),
        );
      case 'Day':
        return DayView(
          calendarController: _calendarController,
          appointments: tasks,
          onTaskTap: (task) {},
          key: ValueKey('DayView-$currentDate'),
        );
      case '3 Days':
        return ThreeDayView(
          calendarController: _calendarController,
          tasks: tasks,
          key: ValueKey('ThreeDayView-$currentDate'),
        );
      case 'Weekly':
        return WeeklyView(
          calendarController: _calendarController,
          appointments: tasks,
          onTaskTap: (task) {},
          key: ValueKey('WeeklyView-$currentDate'),
        );
      default:
        return TaskListView(
          calendarController: _calendarController,
          tasks: tasks,
          selectedDate: currentDate,
          categories: widget.categories,
          onTaskUpdated: _updateTask,
          onTaskDeleted: _deleteTask,
          showCalendar: _showCalendar,
          onCalendarVisibilityChanged: (visible) {
            setState(() => _showCalendar = visible);
          },
        );
    }
  }
}