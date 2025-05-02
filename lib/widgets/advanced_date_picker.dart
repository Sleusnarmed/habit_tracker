import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

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
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedTime = widget.initialTime;
    _selectedRepetition = widget.initialRepetition;
    final now = TimeOfDay.now();
    _startTime = now;
    _endTime = TimeOfDay(hour: now.hour + 1, minute: now.minute);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header (fixed height)
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

          // Main content area (flexible)
          Expanded(
            child: _showDurationView ? _buildDurationView() : _buildDateView(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateView() {
    return Column(
      children: [
        // Quick options row
        SizedBox(
          height: 60,
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
                  () =>
                      _selectDate(DateTime.now().add(const Duration(days: 1))),
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

        // Calendar with fixed height
        SizedBox(
          height: 300,
          child: TableCalendar(
            shouldFillViewport: true,
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: DateTime(2025, 5, 2),
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

        // Time selection options (flexible)
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
    );
  }

  Widget _buildDurationView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              // Date card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE, MMM d').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('y').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Duration card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hour',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showDurationPicker(context),
                        child: Text(
                          '${_startTime.format(context)} - ${_endTime.format(context)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _calculateDurationText(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildReminderOption(context),
          const SizedBox(height: 1),
          _buildRepetitionOption(context),
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

  String _calculateDurationText() {
    final start = DateTime(2023, 1, 1, _startTime.hour, _startTime.minute);
    final end = DateTime(2023, 1, 1, _endTime.hour, _endTime.minute);
    final difference = end.difference(start);

    if (difference.inMinutes == 0) return 'Duration: 0 minutes';

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours == 0) {
      return 'Duration: $minutes minutes';
    } else if (minutes == 0) {
      return 'Duration: $hours ${hours == 1 ? 'hour' : 'hours'}';
    } else {
      return 'Duration: $hours ${hours == 1 ? 'hour' : 'hours'} $minutes minutes';
    }
  }

  Future<void> _showDurationPicker(BuildContext context) async {
    final initialStartTime = _startTime;
    final initialEndTime = _endTime;

    final pickedTimes = await showDialog<List<TimeOfDay>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Duration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Start Time'),
                trailing: Text(initialStartTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: initialStartTime,
                  );
                  if (picked != null && mounted) {
                    Navigator.pop(context, [picked, initialEndTime]);
                  }
                },
              ),
              ListTile(
                title: const Text('End Time'),
                trailing: Text(initialEndTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: initialEndTime,
                  );
                  if (picked != null && mounted) {
                    Navigator.pop(context, [initialStartTime, picked]);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed:
                  () => Navigator.pop(context, [
                    initialStartTime,
                    initialEndTime,
                  ]),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (pickedTimes != null && pickedTimes.length == 2) {
      setState(() {
        _startTime = pickedTimes[0];
        _endTime = pickedTimes[1];
      });
    }
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
    final initialTime = _selectedTime ?? TimeOfDay.now();
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
