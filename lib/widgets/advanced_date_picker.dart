import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class AdvancedDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final TaskRepetition initialRepetition;
  final ValueChanged<DateTime>? onDateSelected;
  final ValueChanged<TimeOfDay>? onStartTimeSelected;
  final ValueChanged<TimeOfDay>? onEndTimeSelected;
  final ValueChanged<TaskRepetition>? onRepetitionChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const AdvancedDatePicker({
    super.key,
    this.initialDate,
    this.initialStartTime,
    this.initialEndTime,
    this.initialRepetition = TaskRepetition.never,
    this.onDateSelected,
    this.onStartTimeSelected,
    this.onEndTimeSelected,
    this.onRepetitionChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<AdvancedDatePicker> createState() => _AdvancedDatePickerState();
}

class _AdvancedDatePickerState extends State<AdvancedDatePicker> {
  late DateTime _selectedDate;
  late DateTime _focusedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late TaskRepetition _selectedRepetition;
  bool _showDurationView = false;
  late List<_QuickOption> _quickOptions;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = widget.initialDate ?? now;
    _focusedDay = _selectedDate;
    _selectedRepetition = widget.initialRepetition;
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;

    _quickOptions = [
      _QuickOption<DateTime>(
        icon: Icons.today,
        label: 'Today',
        value: DateTime.now(),
        onSelected: _selectDate,
      ),
      _QuickOption<DateTime>(
        icon: Icons.event_available,
        label: 'Tomorrow',
        value: DateTime.now().add(const Duration(days: 1)),
        onSelected: _selectDate,
      ),
      _QuickOption<DateTime>(
        icon: Icons.calendar_view_week,
        label: 'Next Monday',
        value: _calculateNextWeekday(DateTime.monday),
        onSelected: _selectDate,
      ),
      _QuickOption<TimeOfDay>(
        icon: Icons.wb_sunny,
        label: 'Afternoon',
        value: const TimeOfDay(hour: 17, minute: 0),
        onSelected: (time) {
          _selectTime(time);
          _selectEndTime(TimeOfDay(hour: time.hour + 1, minute: time.minute));
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: constraints.maxHeight * 0.9,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              _buildHeader(constraints.maxHeight),
              Expanded(
                child:
                    _showDurationView ? _buildDurationView() : _buildDateView(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(double maxHeight) {
    return SizedBox(
      height: maxHeight * 0.9 * 0.1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.close), onPressed: widget.onCancel),
          Row(
            children: [
              _buildViewToggleButton(
                label: 'Date',
                isActive: !_showDurationView,
                onPressed: () => setState(() => _showDurationView = false),
              ),
              const SizedBox(width: 16),
              _buildViewToggleButton(
                label: 'Duration',
                isActive: _showDurationView,
                onPressed: () => setState(() => _showDurationView = true),
              ),
            ],
          ),
          IconButton(icon: const Icon(Icons.check), onPressed: _handleSave),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Theme.of(context).primaryColor : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDateView() {
    return Column(
      children: [
        _buildQuickOptionsRow(),
        const SizedBox(height: 16),
        _buildCalendar(),
        Expanded(child: _buildOptionsList()),
      ],
    );
  }

  Widget _buildQuickOptionsRow() {
    return SizedBox(
      height: 60,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 8),
            ..._quickOptions
                .map((option) {
                  return Row(
                    children: [
                      _buildQuickOption(option.icon, option.label, () {
                        if (option.value is DateTime) {
                          final date = option.value as DateTime;
                          _selectDate(date);
                          setState(() => _focusedDay = date);
                        } else if (option.value is TimeOfDay) {
                          _selectTime(option.value as TimeOfDay);
                        }
                      }),
                      const SizedBox(width: 16),
                    ],
                  );
                })
                .expand((widget) => widget.children)
                .toList()
              ..removeLast(),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return SizedBox(
      height: 300,
      child: TableCalendar(
        shouldFillViewport: true,
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 365 * 10)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDate = selectedDay;
            _focusedDay = selectedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            if (!isSameDay(_focusedDay, focusedDay)) {
              _focusedDay = focusedDay;
            }
          });
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronMargin: EdgeInsets.zero,
          rightChevronMargin: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildOptionsList() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTimeOption(),
          _buildReminderOption(),
          _buildRepetitionOption(),
        ],
      ),
    );
  }

  Widget _buildDurationView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildDateTimeCards(),
          const SizedBox(height: 16),
          _buildTimeRangePicker(),
          const SizedBox(height: 16),
          _buildReminderOption(),
          _buildRepetitionOption(),
        ],
      ),
    );
  }

  Widget _buildDateTimeCards() {
    return Row(
      children: [
        _buildInfoCard(
          title: 'Date',
          mainText: DateFormat('EEEE, MMM d').format(_selectedDate),
          secondaryText: DateFormat('y').format(_selectedDate),
        ),
        const SizedBox(width: 16),
        _buildInfoCard(
          title: 'Time',
          mainText:
              _startTime != null
                  ? _endTime != null
                      ? '${_startTime!.format(context)} - ${_endTime!.format(context)}'
                      : _startTime!.format(context)
                  : 'None',
          secondaryText:
              _startTime != null && _endTime != null
                  ? _calculateDurationText()
                  : 'No duration',
          onTap: () {
            if (_startTime == null) {
              _showTimePicker(isStartTime: true);
            } else {
              _showDurationPicker(context);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTimeRangePicker() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.access_time),
          title: const Text('Start Time'),
          trailing: Text(
            _startTime?.format(context) ?? 'Not set',
            style: TextStyle(
              color:
                  _startTime == null
                      ? Colors.grey
                      : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          onTap: () => _showTimePicker(isStartTime: true),
        ),
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: const Text('End Time'),
          trailing: Text(
            _endTime?.format(context) ?? 'Not set',
            style: TextStyle(
              color:
                  _endTime == null
                      ? Colors.grey
                      : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          onTap: () {
            if (_startTime == null) {
              _showTimePicker(isStartTime: true);
            } else {
              _showTimePicker(isStartTime: false);
            }
          },
        ),
        if (_startTime != null && _endTime != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Duration: ${_calculateDurationText()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String mainText,
    required String secondaryText,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mainText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                secondaryText,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildTimeOption() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.access_time),
          title: const Text('Start Time'),
          trailing: Text(
            _startTime?.format(context) ?? 'Not set',
            style: TextStyle(
              color:
                  _startTime == null
                      ? Colors.grey
                      : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          onTap: () => _showTimePicker(isStartTime: true),
        ),
        if (_startTime != null)
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('End Time'),
            trailing: Text(
              _endTime?.format(context) ?? 'Not set',
              style: TextStyle(
                color:
                    _endTime == null
                        ? Colors.grey
                        : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            onTap: () => _showTimePicker(isStartTime: false),
          ),
        if (_startTime != null && _endTime != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Duration: ${_calculateDurationText()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }

  Widget _buildReminderOption() {
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
      onTap: () {}, // TODO: Implement reminder functionality
    );
  }

  Widget _buildRepetitionOption() {
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
      onTap: _showRepetitionPicker,
    );
  }

  // Helper methods
  DateTime _calculateNextWeekday(int weekday) {
    final today = DateTime.now();
    var daysToAdd = (weekday - today.weekday) % 7;
    if (daysToAdd <= 0) daysToAdd += 7;
    return today.add(Duration(days: daysToAdd));
  }

  String _calculateDurationText() {
    if (_startTime == null || _endTime == null) return 'No duration';

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    int totalMinutes;

    if (endMinutes > startMinutes) {
      totalMinutes = endMinutes - startMinutes;
    } else {
      // Handle overnight duration (crossing midnight)
      totalMinutes = (24 * 60 - startMinutes) + endMinutes;
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) return '$minutes minutes';
    if (minutes == 0) return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    return '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes minutes';
  }

  bool _isTimeAfter(TimeOfDay a, TimeOfDay b) {
    return a.hour > b.hour || (a.hour == b.hour && a.minute > b.minute);
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

  // Action methods
  void _selectDate(DateTime date) => setState(() => _selectedDate = date);

  void _selectTime(TimeOfDay? time) {
    setState(() => _startTime = time);
    if (time != null && widget.onStartTimeSelected != null) {
      widget.onStartTimeSelected!(time);
    }
  }

  void _selectEndTime(TimeOfDay? time) {
    setState(() => _endTime = time);
    if (time != null && widget.onEndTimeSelected != null) {
      widget.onEndTimeSelected!(time);
    }
  }

  void _selectRepetition(TaskRepetition repetition) =>
      setState(() => _selectedRepetition = repetition);

  void _handleSave() {
    widget.onDateSelected?.call(_selectedDate);
    if (_startTime != null) {
      widget.onStartTimeSelected?.call(_startTime!);
    }
    if (_endTime != null) {
      widget.onEndTimeSelected?.call(_endTime!);
    }
    widget.onRepetitionChanged?.call(_selectedRepetition);
    widget.onSave();
  }

  Future<void> _showTimePicker({required bool isStartTime}) async {
    final now = TimeOfDay.now();
    TimeOfDay initialTime;

    if (isStartTime) {
      initialTime = _startTime ?? now;
    } else {
      initialTime =
          _endTime ??
          (_startTime != null
              ? TimeOfDay(
                hour: _startTime!.hour + 1,
                minute: _startTime!.minute,
              )
              : now);
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      if (isStartTime) {
        _selectTime(picked);
        if (_endTime == null || !_isTimeAfter(picked, _endTime!)) {
          _selectEndTime(
            TimeOfDay(hour: picked.hour + 1, minute: picked.minute),
          );
        }
      } else {
        _selectEndTime(picked);
        if (_startTime == null) {
          _selectTime(
            TimeOfDay(
              hour: picked.hour > 0 ? picked.hour - 1 : 0,
              minute: picked.minute,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDurationPicker(BuildContext context) async {
    if (_startTime == null) {
      await _showTimePicker(isStartTime: true);
      return;
    }

    final result = await showDialog<List<TimeOfDay>>(
      context: context,
      builder:
          (context) => DurationPickerDialog(
            initialStartTime: _startTime!,
            initialEndTime:
                _endTime ??
                TimeOfDay(
                  hour: _startTime!.hour + 1,
                  minute: _startTime!.minute,
                ),
          ),
    );

    if (result != null && result.length == 2) {
      setState(() {
        _startTime = result[0];
        _endTime = result[1];
      });
    }
  }

  Future<void> _showRepetitionPicker() async {
    await showModalBottomSheet(
      context: context,
      builder:
          (context) => RepetitionPicker(
            selectedRepetition: _selectedRepetition,
            onChanged: (value) => _selectRepetition(value),
          ),
    );
  }
}

class _QuickOption<T> {
  final IconData icon;
  final String label;
  final T value;
  final void Function(T) onSelected;

  const _QuickOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.onSelected,
  });
}

class DurationPickerDialog extends StatelessWidget {
  final TimeOfDay initialStartTime;
  final TimeOfDay initialEndTime;

  const DurationPickerDialog({
    super.key,
    required this.initialStartTime,
    required this.initialEndTime,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Duration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TimePickerTile(
            label: 'Start Time',
            time: initialStartTime,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: initialStartTime,
              );
              if (picked != null) {
                Navigator.pop(context, [picked, initialEndTime]);
              }
            },
          ),
          _TimePickerTile(
            label: 'End Time',
            time: initialEndTime,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: initialEndTime,
              );
              if (picked != null) {
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
              () => Navigator.pop(context, [initialStartTime, initialEndTime]),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text(time.format(context)),
      onTap: onTap,
    );
  }
}

class RepetitionPicker extends StatelessWidget {
  final TaskRepetition selectedRepetition;
  final ValueChanged<TaskRepetition> onChanged;

  const RepetitionPicker({
    super.key,
    required this.selectedRepetition,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            value: selectedRepetition,
            items:
                TaskRepetition.values.map((repeat) {
                  return DropdownMenuItem(
                    value: repeat,
                    child: Text(_getRepetitionText(repeat)),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
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
}
