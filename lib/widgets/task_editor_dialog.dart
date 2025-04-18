// widgets/task_editor_dialog.dart
import 'package:flutter/material.dart';
import 'package:habit_tracker/widgets/advanced_date_picker.dart';
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

  void _showAdvancedDatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => AdvancedDatePicker(
            initialDate: _dueDate,
            initialStartTime: _startTime,
            initialEndTime: _endTime,
            onDateSelected: (date) => setState(() => _dueDate = date),
            onStartTimeSelected: (time) => setState(() => _startTime = time),
            onEndTimeSelected: (time) => setState(() => _endTime = time),
            onSave: () => Navigator.pop(context),
          ),
    );
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
            // Changed from 'child' to 'children'
            OutlinedButton(
              onPressed: () => _showAdvancedDatePicker(context),
              child: Text(_getDateAndTimeText()),
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

  String _getDateAndTimeText() {
    if (_dueDate == null) return 'Select Date & Time';
    final dateText = DateFormat('MMM d').format(_dueDate!);
    if (_startTime == null) return dateText;
    return '$dateText, ${_startTime!.format(context)} - ${_endTime?.format(context)}';
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
