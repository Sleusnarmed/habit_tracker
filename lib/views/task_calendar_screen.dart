import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
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
        title: const Text('Task Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              _calendarController.displayDate = DateTime.now();
            },
          ),
          PopupMenuButton<CalendarView>(
            icon: const Icon(Icons.calendar_view_day),
            onSelected: (view) {
              _calendarController.view = view;
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: CalendarView.day,
                    child: Text('Day View'),
                  ),
                  const PopupMenuItem(
                    value: CalendarView.week,
                    child: Text('Week View'),
                  ),
                  const PopupMenuItem(
                    value: CalendarView.month,
                    child: Text('Month View'),
                  ),
                  const PopupMenuItem(
                    value: CalendarView.workWeek,
                    child: Text('Work Week'),
                  ),
                ],
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SfCalendar(
                controller: _calendarController,
                view: CalendarView.day,
                timeSlotViewSettings: const TimeSlotViewSettings(
                  timeInterval: Duration(minutes: 60),
                  timeFormat: 'h a',
                  timeRulerSize: 60,
                  timeTextStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                dataSource: TaskDataSource(_getAppointments()),
                monthViewSettings: const MonthViewSettings(
                  appointmentDisplayMode:
                      MonthAppointmentDisplayMode.appointment,
                  showAgenda: true,
                ),
                appointmentBuilder: _appointmentBuilder,
                onTap: (CalendarTapDetails details) {
                  if (details.appointments != null &&
                      details.appointments!.isNotEmpty) {
                    _showTaskDetails(details.appointments!.first as Task);
                  }
                },
              ),
    );
  }

  List<Task> _getAppointments() {
    return _tasksBox.values.where((task) => task.dueDate != null).toList();
  }

  Widget _appointmentBuilder(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final Task task = details.appointments.first as Task;
    return Container(
      decoration: BoxDecoration(
        color: _getPriorityColor(task.priority).withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          task.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.none:
        return Colors.blue;
    }
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(task.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(task.description),
                  ),
                if (task.startTime != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      'Time: ${task.formattedTimeRange}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                Text(
                  'Category: ${task.category}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Priority: ${task.priority.toString().split('.').last}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (task.repetition != TaskRepetition.never)
                  Text(
                    'Repeats: ${task.repetition.toString().split('.').last}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}

class TaskDataSource extends CalendarDataSource {
  TaskDataSource(List<Task> tasks) {
    appointments = tasks;
  }

  @override
  DateTime getStartTime(int index) {
    return _getTask(index).startDateTime!;
  }

  @override
  DateTime getEndTime(int index) {
    return _getTask(index).endDateTime ??
        _getTask(index).startDateTime!.add(const Duration(hours: 1));
  }

  @override
  String getSubject(int index) {
    return _getTask(index).title;
  }

  @override
  Color getColor(int index) {
    return _getPriorityColor(_getTask(index).priority);
  }

  Task _getTask(int index) {
    return appointments![index] as Task;
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.none:
        return Colors.blue;
    }
  }
}
