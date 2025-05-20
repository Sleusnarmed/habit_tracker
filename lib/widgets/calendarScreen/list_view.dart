import 'package:flutter/material.dart';
import 'package:habit_tracker/widgets/task_detail_sheet.dart';
import 'package:hive/hive.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';

class TaskListView extends StatefulWidget {
  final CalendarController calendarController;
  final Box<Task> tasksBox;
  final DateTime selectedDate;
  final List<String> categories;
  final Function(Task) onTaskUpdated;
  final Function(Task) onTaskDeleted;

  const TaskListView({
    Key? key,
    required this.calendarController,
    required this.tasksBox,
    required this.selectedDate,
    required this.categories,
    required this.onTaskUpdated,
    required this.onTaskDeleted,
  }) : super(key: key);

  @override
  _TaskListViewState createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  late ScrollController _scrollController;
  bool _showCalendar = true;
  late DateTime _currentWeekStart;
  DateTime? _displayDate;
  double _lastScrollPosition = 0;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _displayDate = widget.selectedDate;
    _currentWeekStart = _getWeekStart(widget.selectedDate);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant TaskListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _displayDate = widget.selectedDate;
      _currentWeekStart = _getWeekStart(widget.selectedDate);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final currentPosition = _scrollController.position.pixels;
    final scrollDirection = currentPosition > _lastScrollPosition ? 'down' : 'up';
    _lastScrollPosition = currentPosition;

    if (scrollDirection == 'down' && _showCalendar) {
      setState(() => _showCalendar = false);
    } else if (scrollDirection == 'up' && !_showCalendar) {
      setState(() => _showCalendar = true);
    }
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }

  List<DateTime> _getWeekDays(DateTime startDate) {
    return List.generate(7, (index) => startDate.add(Duration(days: index)));
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
    widget.onTaskUpdated(updatedTask);
    setState(() {});
  }

  void _handleDateChange(DateTime date) {
    widget.calendarController.displayDate = date;
    setState(() {
      _displayDate = date;
      _currentWeekStart = _getWeekStart(date);
    });
  }

  void _showTaskDetails(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TaskDetailSheet(
        task: task,
        categories: widget.categories,
        onSave: (updatedTask) async {
          await widget.tasksBox.put(updatedTask.id, updatedTask);
          widget.onTaskUpdated(updatedTask);
          setState(() {});
        },
        onDelete: () async {
          await widget.tasksBox.delete(task.id);
          widget.onTaskDeleted(task);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildCalendar() {
    return SizedBox(
      height: 300,
      child: TableCalendar(
        shouldFillViewport: true,
        firstDay: DateTime(2020),
        lastDay: DateTime.now().add(const Duration(days: 365 * 10)),
        focusedDay: _displayDate ?? widget.selectedDate,
        selectedDayPredicate: (day) => isSameDay(day, _displayDate ?? widget.selectedDate),
        onDaySelected: (selectedDay, focusedDay) {
          _handleDateChange(selectedDay);
        },
        onPageChanged: (focusedDay) {
          if (!isSameDay(_displayDate, focusedDay)) {
            setState(() {
              _displayDate = focusedDay;
              _currentWeekStart = _getWeekStart(focusedDay);
            });
          }
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange),
          ),
          todayTextStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronMargin: EdgeInsets.zero,
          rightChevronMargin: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildWeekHeader() {
    return SizedBox(
      height: 60,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          final newWeekStart = _currentWeekStart.add(Duration(days: (index - 1) * 7));
          setState(() {
            _currentWeekStart = newWeekStart;
          });
        },
        itemBuilder: (context, pageIndex) {
          final weekStart = _currentWeekStart.add(Duration(days: (pageIndex - 1) * 7));
          final weekDays = _getWeekDays(weekStart);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: weekDays.map((day) {
                final isSelected = day.day == (_displayDate ?? widget.selectedDate).day;
                return Container(
                  width: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () => _handleDateChange(day),
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
        },
      ),
    );
  }

  Widget _buildUntimedTaskItem(Task task) {
    return GestureDetector(
      onTap: () => _showTaskDetails(task),
      child: Container(
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
                  color: task.isCompleted ? Colors.grey[100] : Colors.transparent,
                  border: Border.all(
                    color: task.isCompleted ? Colors.grey : Colors.grey,
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
      ),
    );
  }

  Widget _buildTimedTaskItem(Task task) {
    return GestureDetector(
      onTap: () => _showTaskDetails(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time (only start time)
            SizedBox(
              width: 80,
              child: Text(
                DateFormat('h:mma').format(DateTime(
                  0, 0, 0, 
                  task.startTime!.hour, 
                  task.startTime!.minute
                )).toLowerCase(),
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
                  color: task.isCompleted ? Colors.grey[200] : Colors.transparent,
                  border: Border.all(
                    color: task.isCompleted ? Colors.grey : Colors.grey,
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
                  color: Colors.orange[100],
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
                    color: task.isCompleted ? Colors.orange[100] : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = _displayDate ?? widget.selectedDate;
    final tasksForSelectedDay = _getTasksForDay(displayDate);
    
    // Separate and sort tasks
    final timedTasks = tasksForSelectedDay.where((t) => t.startTime != null).toList()
      ..sort((a, b) => (a.startTime!.hour * 60 + a.startTime!.minute)
          .compareTo(b.startTime!.hour * 60 + b.startTime!.minute));
    
    final untimedTasks = tasksForSelectedDay.where((t) => t.startTime == null).toList();

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _showCalendar 
              ? _buildCalendar() 
              : _buildWeekHeader(),
        ),
        Expanded(
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta! > 5 && !_showCalendar) {
                setState(() => _showCalendar = true);
              } else if (details.primaryDelta! < -5 && _showCalendar) {
                setState(() => _showCalendar = false);
              }
            },
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (tasksForSelectedDay.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'No tasks for this day',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else ...[
                  ...untimedTasks.map((task) => _buildUntimedTaskItem(task)),
                  ...timedTasks.map((task) => _buildTimedTaskItem(task)),
                ],
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}