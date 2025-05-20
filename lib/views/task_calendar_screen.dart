import 'package:flutter/material.dart';
import 'package:habit_tracker/services/calendar_preferences.dart';
import 'package:hive/hive.dart';
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
  late Box<Task> _tasksBox;
  bool _isLoading = true;
  bool _showQuickOptions = false;
  String _currentView = CalendarPreferences.currentView;

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    _tasksBox = await Hive.openBox<Task>('tasks');
    setState(() => _isLoading = false);
  }

  Future<void> _updateTask(Task updatedTask) async {
    await _tasksBox.put(updatedTask.id, updatedTask);
    setState(() {});
  }

  Future<void> _deleteTask(Task task) async {
    await _tasksBox.delete(task.id);
    setState(() {});
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
              DateFormat(
                'MMMM yyyy',
              ).format(_calendarController.displayDate ?? DateTime.now()),
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  if (_showQuickOptions)
                    Container(
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
                    ),
                  Expanded(child: _buildCurrentView()),
                ],
              ),
    );
  }

  Widget _buildViewOption(String viewName) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentView = viewName;
          CalendarPreferences.currentView = viewName; // Persist the change
          _showQuickOptions = false;
          if (viewName != 'List') {
            _calendarController.view = _getCalendarView(viewName);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              _currentView == viewName
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

  Widget _buildCurrentView() {
    final appointments = _getAppointments();
    final currentDate = _calendarController.displayDate ?? DateTime.now();

    switch (_currentView) {
      case 'List':
        return TaskListView(
          calendarController: _calendarController,
          tasksBox: _tasksBox,
          selectedDate: currentDate,
          categories: widget.categories,
          onTaskUpdated: _updateTask,
          onTaskDeleted: _deleteTask,
        );
      case 'Month':
        return MonthView(
          calendarController: _calendarController,
          tasks: appointments,
          key: ValueKey('MonthView-$currentDate'),
        );
      case 'Day':
        return DayView(
          calendarController: _calendarController,
          appointments: appointments, 
          onTaskTap: (task) {
          },
          key: ValueKey('DayView-$currentDate'),
        );
      case '3 Days':
        return ThreeDayView(
          calendarController: _calendarController,
          tasks: appointments,
          key: ValueKey('ThreeDayView-$currentDate'),
        );
      case 'Weekly':
        return WeeklyView(
          calendarController: _calendarController,
          appointments: appointments,
          onTaskTap: (task) {
          },
          key: ValueKey('WeeklyView-$currentDate'),
        );
      default:
        return TaskListView(
          calendarController: _calendarController,
          tasksBox: _tasksBox,
          selectedDate: currentDate,
          categories: widget.categories,
          onTaskUpdated: _updateTask,
          onTaskDeleted: _deleteTask,
        );
    }
  }

  List<Task> _getAppointments() {
    return _tasksBox.values.where((task) => task.dueDate != null).toList();
  }
}
