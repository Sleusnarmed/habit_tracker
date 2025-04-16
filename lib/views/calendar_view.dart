import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:habit_tracker/models/task.dart'; // Reuse your Task model

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> with TickerProviderStateMixin {
  late TabController _tabController;
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<DateTime, List<Task>> _events;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _events = {
      DateTime.now(): [
        Task(id: '1', title: 'Team Meeting', category: 'Work', isCompleted: false),
        Task(id: '2', title: 'Dentist Appointment', category: 'Personal', isCompleted: false),
      ],
      DateTime.now().add(const Duration(days: 1)): [
        Task(id: '3', title: 'Flutter Study Session', category: 'Study', isCompleted: false),
      ],
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Day'),
            Tab(text: 'Week'),
            Tab(text: 'Month'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDayView(),
          _buildWeekView(),
          _buildMonthView(),
        ],
      ),
    );
  }

  Widget _buildMonthView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          onPageChanged: (focusedDay) => _focusedDay = focusedDay,
          eventLoader: (day) => _events[day] ?? [],
          calendarStyle: CalendarStyle(
            markersAlignment: Alignment.bottomCenter,
            markerDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            markerMargin: const EdgeInsets.symmetric(horizontal: 1),
            outsideDaysVisible: false,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildEventList()),
      ],
    );
  }

  Widget _buildWeekView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.week,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) => _events[day] ?? [],
          calendarStyle: CalendarStyle(
            markersAlignment: Alignment.bottomCenter,
            markerDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildEventList()),
      ],
    );
  }

  Widget _buildDayView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.week,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) => _events[day] ?? [],
          calendarStyle: CalendarStyle(
            markersAlignment: Alignment.bottomCenter,
            markerDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: 24, // Hours in day
            itemBuilder: (context, index) {
              final hour = index;
              final hourTasks = _getTasksForHour(hour);
              
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (hourTasks.isNotEmpty)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: hourTasks.map((task) => _buildHourTask(task)).toList(),
                        ),
                      )
                    else
                      const Expanded(
                        child: Text(
                          'No tasks',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHourTask(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            _getCategoryIcon(task.category),
            color: Theme.of(context).primaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(task.title)),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final events = _events[_selectedDay] ?? [];

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final task = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(_getCategoryIcon(task.category)),
            title: Text(task.title),
            subtitle: Text(_formatTime(DateTime.now())), // Replace with actual task time
            trailing: Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                setState(() => task.isCompleted = value ?? false);
              },
            ),
          ),
        );
      },
    );
  }

  List<Task> _getTasksForHour(int hour) {
    // In a real app, filter tasks by hour
    return _events[_selectedDay]
            ?.where((task) => task.dueTime?.hour == hour)
            .toList() ??
        [];
  }

  IconData _getCategoryIcon(String category) {
  switch (category) {
    case 'Work':
      return Icons.work;
    case 'Study':
      return Icons.school;
    case 'Shopping':
      return Icons.shopping_cart;
    case 'Personal':
      return Icons.person;
    default:
      return Icons.event;
  }
}
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}