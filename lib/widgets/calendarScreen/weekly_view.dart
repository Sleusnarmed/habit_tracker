import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../models/task.dart';

class WeeklyView extends StatelessWidget {
  final CalendarController calendarController;
  final List<Task> appointments;
  final void Function(Task) onTaskTap;

  const WeeklyView({
    super.key,
    required this.calendarController,
    required this.appointments,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return SfCalendar(
      controller: calendarController,
      view: CalendarView.week,
      firstDayOfWeek: 7, // Sunday first
      showDatePickerButton: false,
      showNavigationArrow: true,
      headerHeight: 0,
      timeSlotViewSettings: const TimeSlotViewSettings(
        timeFormat: 'h a',
        timeIntervalHeight: 75,
        startHour: 0,
        endHour: 24,
        timeRulerSize: 50,
      ),
      cellBorderColor: Colors.grey[300],
      dataSource: _TaskDataSource(appointments),
      appointmentBuilder: _appointmentBuilder,
      todayHighlightColor: Colors.orange,
      onTap: (CalendarTapDetails details) {
        if (details.appointments != null && details.appointments!.isNotEmpty) {
          onTaskTap(details.appointments!.first as Task);
        }
      },
    );
  }

  Widget _appointmentBuilder(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final task = details.appointments.first as Task;
    final hasTimeRange = task.hasTimeRange;

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.orange,
        border: Border.all(color: Colors.orange, width: 0.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              task.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (hasTimeRange) ...[
              const SizedBox(height: 2),
              Text(
                task.formattedTimeRange ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskDataSource extends CalendarDataSource {
  _TaskDataSource(List<Task> tasks) {
    appointments = tasks;
  }

  @override
  DateTime getStartTime(int index) {
    final task = _getTask(index);
    if (task.startTime != null) {
      // For tasks with specific time
      return DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
        task.startTime!.hour,
        task.startTime!.minute,
      );
    } else {
      // For all-day tasks, show at top of day
      return DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
    }
  }

  @override
  DateTime getEndTime(int index) {
    final task = _getTask(index);
    if (task.startTime != null && task.endTime != null) {
      // For tasks with both start and end time
      return DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
        task.endTime!.hour,
        task.endTime!.minute,
      );
    } else if (task.startTime != null) {
      // For tasks with only start time (default 1 hour duration)
      return DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
        task.startTime!.hour,
        task.startTime!.minute,
      ).add(const Duration(hours: 1));
    } else {
      // For all-day tasks
      return DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
        23,
        59,
      );
    }
  }

  @override
  String getSubject(int index) {
    return _getTask(index).title;
  }

  @override
  Color getColor(int index) {
    return Colors.orange;
  }

  Task _getTask(int index) {
    return appointments![index] as Task;
  }
}