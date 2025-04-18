import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AdvancedDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final ValueChanged<DateTime>? onDateSelected;
  final ValueChanged<TimeOfDay>? onStartTimeSelected;
  final ValueChanged<TimeOfDay>? onEndTimeSelected;
  final VoidCallback onSave;

  const AdvancedDatePicker({
    super.key,
    this.initialDate,
    this.initialStartTime,
    this.initialEndTime,
    this.onDateSelected,
    this.onStartTimeSelected,
    this.onEndTimeSelected,
    required this.onSave,
  });

  @override
  State<AdvancedDatePicker> createState() => _AdvancedDatePickerState();
}

class _AdvancedDatePickerState extends State<AdvancedDatePicker> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedStartTime;
  late TimeOfDay _selectedEndTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedStartTime = widget.initialStartTime ?? TimeOfDay.now();
    _selectedEndTime =
        widget.initialEndTime ??
        _selectedStartTime.replacing(hour: _selectedStartTime.hour + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header with title and save button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Date & Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: widget.onSave,
              ),
            ],
          ),
          const Divider(),

          // Quick selection buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Select',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickOption(
                      Icons.today,
                      'Today',
                      () => _selectDate(DateTime.now()),
                    ),
                    _buildQuickOption(
                      Icons.event_available,
                      'Tomorrow',
                      () => _selectDate(
                        DateTime.now().add(const Duration(days: 1)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickOption(
                      Icons.calendar_view_week,
                      'Next Monday',
                      () => _selectNextWeekday(DateTime.monday),
                    ),
                    _buildQuickOption(
                      Icons.wb_sunny,
                      'Afternoon',
                      () => _selectTimeRange(TimeOfDay(hour: 12, minute: 0)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // Calendar
          Expanded(
            child: SingleChildScrollView(
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() => _selectedDate = selectedDay);
                  widget.onDateSelected?.call(selectedDay);
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),
          ),

          // Time selection
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeButton(
                  'Start Time',
                  _selectedStartTime,
                  () => _selectTime(context, isStartTime: true),
                ),
                _buildTimeButton(
                  'End Time',
                  _selectedEndTime,
                  () => _selectTime(context, isStartTime: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildTimeButton(String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: [Text(label), Text(time.format(context))]),
      ),
    );
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
    widget.onDateSelected?.call(date);
  }

  void _selectNextWeekday(int weekday) {
    final today = DateTime.now();
    var daysToAdd = (weekday - today.weekday) % 7;
    if (daysToAdd <= 0) daysToAdd += 7;
    _selectDate(today.add(Duration(days: daysToAdd)));
  }

  void _selectTimeRange(TimeOfDay startTime) {
    setState(() {
      _selectedStartTime = startTime;
      _selectedEndTime = startTime.replacing(hour: startTime.hour + 1);
    });
    widget.onStartTimeSelected?.call(startTime);
    widget.onEndTimeSelected?.call(_selectedEndTime);
  }

  Future<void> _selectTime(
    BuildContext context, {
    required bool isStartTime,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _selectedStartTime : _selectedEndTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
          // Ensure end time is after start time
          if (_selectedEndTime.hour < picked.hour ||
              (_selectedEndTime.hour == picked.hour &&
                  _selectedEndTime.minute <= picked.minute)) {
            _selectedEndTime = picked.replacing(hour: picked.hour + 1);
          }
        } else {
          _selectedEndTime = picked;
        }
      });
      widget.onStartTimeSelected?.call(_selectedStartTime);
      widget.onEndTimeSelected?.call(_selectedEndTime);
    }
  }
}
