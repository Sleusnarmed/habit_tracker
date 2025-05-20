import 'package:flutter/material.dart';
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
  const TaskCalendarScreen({Key? key}) : super(key: key);

  @override
  _TaskCalendarScreenState createState() => _TaskCalendarScreenState();
}

class _TaskCalendarScreenState extends State<TaskCalendarScreen> {
  late CalendarController _calendarController;
  late Box<Task> _tasksBox;
  bool _isLoading = true;
  bool _showQuickOptions = false;
  String _currentView = 'List';

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
              icon: const Text(":", style: TextStyle(fontSize: 24)),
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
          _showQuickOptions = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            color: _currentView == viewName ? Colors.orange : Colors.black,
            fontWeight:
                _currentView == viewName ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'List':
        return TaskListView(
          calendarController: _calendarController,
          tasksBox: _tasksBox,
          selectedDate: _calendarController.displayDate ?? DateTime.now(),
        );
      case 'Month':
        return MonthView(
          calendarController: _calendarController,
          tasks: _getAppointments(),
        );
      case 'Day':
        return DayView(
          calendarController: _calendarController,
          tasks: _getAppointments(),
        );
      case '3 Days':
        return ThreeDayView(
          calendarController: _calendarController,
          tasks: _getAppointments(),
        );
      case 'Weekly':
        return WeeklyView(
          calendarController: _calendarController,
          appointments: _getAppointments(),
          onTaskTap: (task) {
            print('Task tapped: ${task.title}');
          },
        );
      default:
        return TaskListView(
          calendarController: _calendarController,
          tasksBox: _tasksBox,
          selectedDate: _calendarController.displayDate ?? DateTime.now(),
        );
    }
  }

  List<Task> _getAppointments() {
    return _tasksBox.values.where((task) => task.dueDate != null).toList();
  }
}
