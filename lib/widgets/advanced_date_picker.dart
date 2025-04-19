import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
// this took me all day to do.... 
class AdvancedDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final TaskRepetition initialRepetition;
  final ValueChanged<DateTime>? onDateSelected;
  final ValueChanged<TimeOfDay>? onTimeSelected;
  final ValueChanged<TaskRepetition>? onRepetitionChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const AdvancedDatePicker({
    super.key,
    this.initialDate,
    this.initialTime,
    this.initialRepetition = TaskRepetition.never,
    this.onDateSelected,
    this.onTimeSelected,
    this.onRepetitionChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<AdvancedDatePicker> createState() => _AdvancedDatePickerState();
}

class _AdvancedDatePickerState extends State<AdvancedDatePicker> {
  late DateTime _selectedDate;
  late TimeOfDay? _selectedTime;
  late TaskRepetition _selectedRepetition;
  bool _showDurationView = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedTime = widget.initialTime;
    _selectedRepetition = widget.initialRepetition;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9, // 90% of screen height
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header (10% of container height)
          SizedBox(
            height: screenHeight * 0.9 * 0.1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed:
                          () => setState(() => _showDurationView = false),
                      child: Text(
                        'Date',
                        style: TextStyle(
                          fontWeight:
                              _showDurationView
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                          color:
                              _showDurationView
                                  ? Colors.grey
                                  : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _showDurationView = true),
                      child: Text(
                        'Duration',
                        style: TextStyle(
                          fontWeight:
                              _showDurationView
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              _showDurationView
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: widget.onSave,
                ),
              ],
            ),
          ),
          if (_showDurationView)
            const Center(child: Text('Hello')) // Duration view placeholder
          else
            Column(
              children: [
                SizedBox(
                  height: screenHeight * 0.9 * 0.1,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        _buildQuickOption(
                          Icons.today,
                          'Today',
                          () => _selectDate(DateTime.now()),
                        ),
                        const SizedBox(width: 16),
                        _buildQuickOption(
                          Icons.event_available,
                          'Tomorrow',
                          () => _selectDate(
                            DateTime.now().add(const Duration(days: 1)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildQuickOption(
                          Icons.calendar_view_week,
                          'Next Monday',
                          () => _selectNextWeekday(DateTime.monday),
                        ),
                        const SizedBox(width: 16),
                        _buildQuickOption(
                          Icons.wb_sunny,
                          'Afternoon',
                          () => _selectTime(TimeOfDay(hour: 17, minute: 0)),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          // Calendar with fixed height
          SizedBox(
            height: screenHeight * 0.9 * 0.5,
            child: TableCalendar(
              shouldFillViewport:
                  true, // IF I DONT PUT THIS, MAKES 'OVERFLOW' THANK YOU stackoverflow
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
                leftChevronMargin: EdgeInsets.zero,
                rightChevronMargin: EdgeInsets.zero,
              ),
            ),
          ),

          // Time selection options
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTimeOption(context),
                  const SizedBox(height: 1),
                  _buildReminderOption(context),
                  const SizedBox(height: 1),
                  _buildRepetitionOption(context),
                  const SizedBox(height: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTimeOption(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: const Text('Hour', style: TextStyle(fontWeight: FontWeight.bold)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selectedTime != null ? _selectedTime!.format(context) : 'None',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          if (_selectedTime != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => _selectTime(null),
              padding: EdgeInsets.zero,
            )
          else
            const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: () => _showTimePicker(context),
    );
  }

  Widget _buildReminderOption(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.notifications),
      title: const Text(
        'Reminder',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('None', style: TextStyle(color: Colors.grey)),
          Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: () {
        // TODO: Implement reminder functionality
      },
    );
  }

  Widget _buildRepetitionOption(BuildContext context) {
    final hasRepetition = _selectedRepetition != TaskRepetition.never;

    return ListTile(
      leading: const Icon(Icons.repeat),
      title: const Text(
        'Repetition',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getRepetitionText(_selectedRepetition),
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          if (hasRepetition)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => _selectRepetition(TaskRepetition.never),
              padding: EdgeInsets.zero,
            )
          else
            const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: () => _showRepetitionPicker(context),
    );
  }

  String _getRepetitionText(TaskRepetition repeat) {
    switch (repeat) {
      case TaskRepetition.daily:
        return 'Daily';
      case TaskRepetition.weekly:
        return 'Weekly';
      case TaskRepetition.monthly:
        return 'Monthly';
      case TaskRepetition.yearly:
        return 'Yearly';
      case TaskRepetition.weekends:
        return 'Weekends';
      case TaskRepetition.weekdays:
        return 'Weekdays';
      case TaskRepetition.never:
        return 'Never';
    }
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

  void _selectTime(TimeOfDay? time) {
    setState(() => _selectedTime = time);
    if (time != null) {
      widget.onTimeSelected?.call(time);
    }
  }

  void _selectRepetition(TaskRepetition repetition) {
    setState(() => _selectedRepetition = repetition);
    widget.onRepetitionChanged?.call(repetition);
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final initialTime =
        _selectedTime ?? TimeOfDay.now(); // Providing a default
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      _selectTime(picked);
    }
  }

  Future<void> _showRepetitionPicker(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Repetition',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskRepetition>(
                  value: _selectedRepetition,
                  items:
                      TaskRepetition.values.map((repeat) {
                        return DropdownMenuItem(
                          value: repeat,
                          child: Text(_getRepetitionText(repeat)),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _selectRepetition(value);
                      Navigator.pop(context);
                    }
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Repeat',
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
