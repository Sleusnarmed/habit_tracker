// widgets/task_detail_sheet.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

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

  String _getDueDateText() {
    if (_editedTask.dueTime == null) return 'Add due date';
    final now = DateTime.now();
    final due = _editedTask.dueTime!;
    
    final daysDiff = due.difference(now).inDays;
    String daysText = '';
    if (daysDiff > 0) {
      daysText = '$daysDiff ${daysDiff == 1 ? 'day' : 'days'} later, ';
    } else if (daysDiff < 0) {
      daysText = '${-daysDiff} ${daysDiff == -1 ? 'day' : 'days'} ago, ';
    }
    
    return '$daysText${DateFormat('MMM d').format(due)}${_editedTask.dueTime != null ? ', ${DateFormat('jm').format(due)}' : ''}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _editedTask.dueTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _editedTask = _editedTask.copyWith(
          dueTime: DateTime(
            picked.year,
            picked.month,
            picked.day,
            _editedTask.dueTime?.hour ?? 0,
            _editedTask.dueTime?.minute ?? 0,
          ),
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _editedTask.dueTime != null
          ? TimeOfDay.fromDateTime(_editedTask.dueTime!)
          : TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _editedTask = _editedTask.copyWith(
          dueTime: DateTime(
            _editedTask.dueTime?.year ?? DateTime.now().year,
            _editedTask.dueTime?.month ?? DateTime.now().month,
            _editedTask.dueTime?.day ?? DateTime.now().day,
            picked.hour,
            picked.minute,
          ),
        );
      });
    }
  }

  void _changePriority() {
    final priorities = TaskPriority.values;
    final currentIndex = priorities.indexOf(_editedTask.priority);
    final nextIndex = (currentIndex + 1) % priorities.length;
    setState(() {
      _editedTask = _editedTask.copyWith(priority: priorities[nextIndex]);
    });
  }

  void _changeRepetition() {
    final repetitions = TaskRepetition.values;
    final currentIndex = repetitions.indexOf(_editedTask.repetition);
    final nextIndex = (currentIndex + 1) % repetitions.length;
    setState(() {
      _editedTask = _editedTask.copyWith(repetition: repetitions[nextIndex]);
    });
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              DropdownButton<String>(
                value: _editedTask.category,
                items: widget.categories
                    .where((c) => c != 'All')
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _editedTask = _editedTask.copyWith(category: value);
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  widget.onDelete();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const Divider(),
          ListTile(
            title: Text(_getDueDateText()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.repeat,
                    color: _editedTask.repetition != TaskRepetition.never
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  onPressed: _changeRepetition,
                ),
                IconButton(
                  icon: Icon(
                    Icons.flag,
                    color: _getPriorityColor(_editedTask.priority),
                  ),
                  onPressed: _changePriority,
                ),
              ],
            ),
            onTap: _selectDate,
          ),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Task title',
            ),
            style: Theme.of(context).textTheme.titleMedium,
            onChanged: (value) {
              setState(() {
                _editedTask = _editedTask.copyWith(title: value);
              });
            },
          ),
          Expanded(
            child: TextField(
              controller: _descController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Add description...',
              ),
              maxLines: null,
              onChanged: (value) {
                setState(() {
                  _editedTask = _editedTask.copyWith(description: value);
                });
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onSave(_editedTask);
              Navigator.pop(context);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
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
}