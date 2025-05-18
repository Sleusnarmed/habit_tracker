import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import 'advanced_date_picker.dart';

class TaskDetailSheet extends StatefulWidget {
  final Task task;
  final List<String> categories;
  final Function(Task) onSave;
  final Function() onDelete;

  const TaskDetailSheet({
    super.key,
    required this.task,
    required this.categories,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  late Task _editedTask;
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  final _dateFormat = DateFormat('MMM d');
  final _timeFormat = DateFormat.jm();

  @override
  void initState() {
    super.initState();
    _editedTask = widget.task;
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showAdvancedDatePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => AdvancedDatePicker(
            initialDate: _editedTask.dueDate,
            initialStartTime: _editedTask.startTime,
            initialEndTime: _editedTask.endTime,
            initialRepetition: _editedTask.repetition,
            onDateSelected: (date) {
              setState(() {
                _editedTask = _editedTask.copyWith(dueDate: date);
              });
            },
            onStartTimeSelected: (time) {
              setState(() {
                _editedTask = _editedTask.copyWith(startTime: time);
              });
            },
            onEndTimeSelected: (time) {
              setState(() {
                _editedTask = _editedTask.copyWith(endTime: time);
              });
            },
            onRepetitionChanged: (repetition) {
              setState(() {
                _editedTask = _editedTask.copyWith(repetition: repetition);
              });
            },
            onSave: () => Navigator.pop(context),
            onCancel: () => Navigator.pop(context),
          ),
    );
  }

  void _saveChanges() {
    // Validate time range if both times are set
    if (_editedTask.startTime != null && _editedTask.endTime != null) {
      final startMinutes =
          _editedTask.startTime!.hour * 60 + _editedTask.startTime!.minute;
      final endMinutes =
          _editedTask.endTime!.hour * 60 + _editedTask.endTime!.minute;

      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }
    }

    widget.onSave(_editedTask);
    Navigator.pop(context);
  }

  void _deleteTask() {
    widget.onDelete();
    Navigator.pop(context);
  }

  Color _getPriorityColor(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => Colors.red,
      TaskPriority.medium => Colors.orange,
      TaskPriority.low => Colors.blue,
      TaskPriority.none => Colors.grey,
    };
  }

  String _getPriorityText(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => 'High',
      TaskPriority.medium => 'Medium',
      TaskPriority.low => 'Low',
      TaskPriority.none => 'None',
    };
  }

  String _formatTimeRange() {
    if (_editedTask.startTime == null) return '';
    if (_editedTask.endTime == null) {
      return _timeFormat.format(
        DateTime(
          2023,
          1,
          1,
          _editedTask.startTime!.hour,
          _editedTask.startTime!.minute,
        ),
      );
    }
    return '${_timeFormat.format(DateTime(2023, 1, 1, _editedTask.startTime!.hour, _editedTask.startTime!.minute))} - ${_timeFormat.format(DateTime(2023, 1, 1, _editedTask.endTime!.hour, _editedTask.endTime!.minute))}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeaderRow(),
          _buildDateTimeAndPriorityRow(),
          _buildTitleField(),
          _buildDescriptionField(),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        _buildCategoryDropdown(),
        IconButton(icon: const Icon(Icons.delete), onPressed: _deleteTask),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButton<String>(
      value: _editedTask.category,
      items:
          widget.categories
              .where((c) => c != 'All')
              .map(
                (category) =>
                    DropdownMenuItem(value: category, child: Text(category)),
              )
              .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _editedTask = _editedTask.copyWith(category: value));
        }
      },
      underline: const SizedBox(),
    );
  }

  Widget _buildDateTimeAndPriorityRow() {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(
              _editedTask.dueDate != null
                  ? '${_dateFormat.format(_editedTask.dueDate!)}${_editedTask.startTime != null ? ', ${_formatTimeRange()}' : ''}'
                  : 'No date/time set',
            ),
            onTap: _showAdvancedDatePicker,
          ),
        ),
        PopupMenuButton<TaskPriority>(
          icon: Icon(
            Icons.flag,
            color: _getPriorityColor(_editedTask.priority),
          ),
          onSelected: (priority) {
            setState(() {
              _editedTask = _editedTask.copyWith(priority: priority);
            });
          },
          itemBuilder:
              (context) =>
                  TaskPriority.values.map((priority) {
                    return PopupMenuItem<TaskPriority>(
                      value: priority,
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: _getPriorityColor(priority)),
                          const SizedBox(width: 8),
                          Text(_getPriorityText(priority)),
                        ],
                      ),
                    );
                  }).toList(),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: 'Task title',
      ),
      style: Theme.of(context).textTheme.titleMedium,
      onChanged:
          (value) =>
              setState(() => _editedTask = _editedTask.copyWith(title: value)),
    );
  }

  Widget _buildDescriptionField() {
    return Expanded(
      child: TextField(
        controller: _descController,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Add description...',
        ),
        maxLines: null,
        onChanged:
            (value) => setState(
              () => _editedTask = _editedTask.copyWith(description: value),
            ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveChanges,
      child: const Text('Save Changes'),
    );
  }
}
