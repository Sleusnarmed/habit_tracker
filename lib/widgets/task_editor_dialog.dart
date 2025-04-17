// widgets/task_editor_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskEditorDialog extends StatefulWidget {
  final Task? initialTask;
  final String initialCategory;
  final List<String> categories;

  const TaskEditorDialog({
    super.key,
    this.initialTask,
    required this.initialCategory,
    required this.categories,
  });

  @override
  State<TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<TaskEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late String _category;
  late TaskPriority _priority;
  DateTime? _dueDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late TaskRepetition _repetition;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _category = task?.category ?? widget.initialCategory;
    _priority = task?.priority ?? TaskPriority.none;
    _dueDate = task?.dueTime;
    _repetition = task?.repetition ?? TaskRepetition.never;

    // Initialize time range from existing task
    if (task?.dueTime != null) {
      _startTime = TimeOfDay.fromDateTime(task!.dueTime!);
      if (task.duration != null) {
        final endTime = task.dueTime!.add(task.duration!);
        _endTime = TimeOfDay.fromDateTime(endTime);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Duration? get _duration {
    if (_startTime == null || _endTime == null) return null;

    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    final endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    return endDateTime.difference(startDateTime);
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // Reset end time if it's now before start time
        if (_endTime != null && _isTimeBefore(_endTime!, picked)) {
          _endTime = null;
        }
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start time first')),
      );
      return;
    }

    // Calculate initial end time safely
    TimeOfDay initialEndTime;
    try {
      initialEndTime =
          _endTime ??
          _startTime!.replacing(
            minute: (_startTime!.minute + 30) % 60,
            hour: _startTime!.hour + ((_startTime!.minute + 30) ~/ 60),
          );
    } catch (e) {
      initialEndTime = _startTime!.replacing(hour: _startTime!.hour + 1);
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialEndTime,
    );

    if (picked != null) {
      if (_isTimeBefore(picked, _startTime!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }

      setState(() => _endTime = picked);
    }
  }

  bool _isTimeBefore(TimeOfDay a, TimeOfDay b) {
    return a.hour < b.hour || (a.hour == b.hour && a.minute < b.minute);
  }

  Task _buildTask() {
    DateTime? dueTime;
    if (_dueDate != null && _startTime != null) {
      dueTime = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      // Validate duration doesn't cross midnight
      if (_endTime != null) {
        final endDateTime = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );

        if (endDateTime.day != dueTime.day) {
          throw ArgumentError('Duration cannot cross midnight');
        }
      }
    }

    return Task(
      id:
          widget.initialTask?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      category: _category,
      description: _descController.text,
      priority: _priority,
      dueTime: dueTime,
      duration: _duration,
      repetition: _repetition,
    );
  }

  Widget _buildTimeRangeSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _selectStartTime(context),
                child: Text(
                  _startTime == null
                      ? 'Select Start Time'
                      : _startTime!.format(context),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _selectEndTime(context),
                child: Text(
                  _endTime == null
                      ? 'Select End Time'
                      : _endTime!.format(context),
                ),
              ),
            ),
          ],
        ),
        if (_startTime != null && _endTime != null) ...[
          const SizedBox(height: 8),
          Text(
            'Time Range: ${_startTime!.format(context)} - ${_endTime!.format(context)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTask == null ? 'Add New Task' : 'Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title*'),
              autofocus: true,
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              items:
                  widget.categories
                      .where((c) => c != 'All')
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _category = value!),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              items:
                  TaskPriority.values
                      .map(
                        (priority) => DropdownMenuItem(
                          value: priority,
                          child: Row(
                            children: [
                              Icon(
                                Icons.flag,
                                color: _getPriorityColor(priority),
                              ),
                              const SizedBox(width: 8),
                              Text(_getPriorityText(priority)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _priority = value!),
              decoration: const InputDecoration(labelText: 'Priority'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(context),
                    child: Text(
                      _dueDate == null
                          ? 'Select Date'
                          : DateFormat.yMMMd().format(_dueDate!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimeRangeSection(),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskRepetition>(
              value: _repetition,
              items:
                  TaskRepetition.values
                      .map(
                        (repeat) => DropdownMenuItem(
                          value: repeat,
                          child: Text(_getRepetitionText(repeat)),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _repetition = value!),
              decoration: const InputDecoration(labelText: 'Repeat'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Title is required')),
              );
              return;
            }
            try {
              Navigator.pop(context, _buildTask());
            } on ArgumentError catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.message ?? 'Invalid time range')),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.blue;
      case TaskPriority.none:
        return Colors.grey;
    }
  }

  String _getPriorityText(TaskPriority priority) {
    return priority.toString().split('.').last.capitalize();
  }

  String _getRepetitionText(TaskRepetition repeat) {
    return repeat.toString().split('.').last.capitalize();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
