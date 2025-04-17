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
  Duration? _duration;
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
    _startTime = task?.dueTime != null 
        ? TimeOfDay.fromDateTime(task!.dueTime!) 
        : null;
    _duration = task?.duration;
    _repetition = task?.repetition ?? TaskRepetition.never;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
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

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
      // Clear duration if time changes
      if (_duration != null) {
        setState(() => _duration = null);
      }
    }
  }

  Future<void> _selectDuration(BuildContext context) async {
    final initialHours = _duration?.inHours ?? 1;
    final initialMinutes = _duration?.inMinutes.remainder(60) ?? 0;

    final result = await showDialog<Duration>(
      context: context,
      builder: (context) => DurationPickerDialog(
        initialHours: initialHours,
        initialMinutes: initialMinutes,
      ),
    );

    if (result != null) {
      // Validate duration doesn't cross midnight
      if (_startTime != null) {
        final startDateTime = DateTime(
          _dueDate?.year ?? DateTime.now().year,
          _dueDate?.month ?? DateTime.now().month,
          _dueDate?.day ?? DateTime.now().day,
          _startTime!.hour,
          _startTime!.minute,
        );
        final endDateTime = startDateTime.add(result);
        if (endDateTime.day != startDateTime.day) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Duration cannot cross midnight')),
          );
          return;
        }
      }
      setState(() => _duration = result);
    }
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
    }

    return Task(
      id: widget.initialTask?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      category: _category,
      description: _descController.text,
      priority: _priority,
      dueTime: dueTime,
      duration: _duration,
      repetition: _repetition,
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
              items: widget.categories
                  .where((c) => c != 'All')
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _category = value!),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              items: TaskPriority.values.map((priority) => DropdownMenuItem(
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
                  )).toList(),
              onChanged: (value) => setState(() => _priority = value!),
              decoration: const InputDecoration(labelText: 'Priority'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(context),
                    child: Text(_dueDate == null 
                        ? 'Select Date' 
                        : DateFormat.yMMMd().format(_dueDate!)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectTime(context),
                    child: Text(_startTime == null 
                        ? 'Select Time' 
                        : _startTime!.format(context)),
                  ),
                ),
              ],
            ),
            if (_startTime != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _selectDuration(context),
                child: Text(_duration == null 
                    ? 'Add Duration' 
                    : '${_duration!.inHours}h ${_duration!.inMinutes.remainder(60)}m'),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskRepetition>(
              value: _repetition,
              items: TaskRepetition.values.map((repeat) => DropdownMenuItem(
                    value: repeat,
                    child: Text(_getRepetitionText(repeat)),
                  )).toList(),
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
            Navigator.pop(context, _buildTask());
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

class DurationPickerDialog extends StatelessWidget {
  final int initialHours;
  final int initialMinutes;

  const DurationPickerDialog({
    super.key,
    required this.initialHours,
    required this.initialMinutes,
  });

  @override
  Widget build(BuildContext context) {
    int hours = initialHours;
    int minutes = initialMinutes;

    return AlertDialog(
      title: const Text('Select Duration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Hours:'),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: hours,
                items: List.generate(24, (i) => DropdownMenuItem(
                      value: i,
                      child: Text('$i'),
                    )),
                onChanged: (value) => hours = value!,
              ),
            ],
          ),
          Row(
            children: [
              const Text('Minutes:'),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: minutes,
                items: [0, 15, 30, 45].map((i) => DropdownMenuItem(
                      value: i,
                      child: Text('$i'),
                    )).toList(),
                onChanged: (value) => minutes = value!,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              Duration(hours: hours, minutes: minutes),
            );
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}