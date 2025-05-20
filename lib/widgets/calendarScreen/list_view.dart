import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';

class TaskListView extends StatefulWidget {
  final CalendarController calendarController;
  final Box<Task> tasksBox;
  final DateTime selectedDate;

  const TaskListView({
    Key? key,
    required this.calendarController,
    required this.tasksBox,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _TaskListViewState createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  late ScrollController _scrollController;
  bool _showCalendar = true;
  late DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _currentWeekStart = _getWeekStart(widget.selectedDate);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.offset > 100 && _showCalendar) {
      setState(() => _showCalendar = false);
    } else if (_scrollController.offset <= 100 && !_showCalendar) {
      setState(() => _showCalendar = true);
    }
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }

  List<DateTime> _getWeekDays() {
    return List.generate(7, (index) => _currentWeekStart.add(Duration(days: index)));
  }

  List<Task> _getTasksForDay(DateTime day) {
    return widget.tasksBox.values
        .where((task) => 
            task.dueDate != null &&
            task.dueDate!.year == day.year &&
            task.dueDate!.month == day.month &&
            task.dueDate!.day == day.day)
        .toList();
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await widget.tasksBox.put(task.id, updatedTask);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tasksForSelectedDay = _getTasksForDay(widget.selectedDate);
    
    // Separate and sort tasks
    final timedTasks = tasksForSelectedDay.where((t) => t.startTime != null).toList()
      ..sort((a, b) => (a.startTime!.hour * 60 + a.startTime!.minute)
          .compareTo(b.startTime!.hour * 60 + b.startTime!.minute));
    
    final untimedTasks = tasksForSelectedDay.where((t) => t.startTime == null).toList();

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showCalendar ? _buildCalendar() : _buildWeekHeader(),
        ),
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ...untimedTasks.map((task) => _buildUntimedTaskItem(task)),
              ...timedTasks.map((task) => _buildTimedTaskItem(task)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      height: 300,
      margin: const EdgeInsets.only(bottom: 8),
      child: CalendarDatePicker(
        initialDate: widget.selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        onDateChanged: (date) {
          widget.calendarController.displayDate = date;
          setState(() {
            _currentWeekStart = _getWeekStart(date);
          });
        },
      ),
    );
  }

  Widget _buildWeekHeader() {
    final weekDays = _getWeekDays();
    
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: weekDays.map((day) {
          final isSelected = day.day == widget.selectedDate.day;
          return Container(
            width: 50,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () {
                widget.calendarController.displayDate = day;
                setState(() {});
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUntimedTaskItem(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          SizedBox(
            width: 80,
            child: Text(
              DateFormat('MMM d').format(task.dueDate!),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // Checkbox
          InkWell(
            onTap: () => _toggleTaskCompletion(task),
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted ? Colors.green : Colors.grey,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          // Task box
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: task.isCompleted 
                      ? TextDecoration.lineThrough 
                      : TextDecoration.none,
                  color: task.isCompleted ? Colors.grey : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimedTaskItem(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('h:mma').format(DateTime(
                    0, 0, 0, 
                    task.startTime!.hour, 
                    task.startTime!.minute
                  )).toLowerCase(),
                  style: const TextStyle(fontSize: 14),
                ),
                if (task.endTime != null)
                  Text(
                    '- ${DateFormat('h:mma').format(DateTime(
                      0, 0, 0, 
                      task.endTime!.hour, 
                      task.endTime!.minute
                    )).toLowerCase()}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          // Checkbox
          InkWell(
            onTap: () => _toggleTaskCompletion(task),
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted ? Colors.green : Colors.grey,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          // Task box
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: task.isCompleted 
                      ? TextDecoration.lineThrough 
                      : TextDecoration.none,
                  color: task.isCompleted ? Colors.grey : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}