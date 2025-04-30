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
  final _dateFormat = DateFormat('MMM d');
 

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


  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _editedTask.dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _editedTask = _editedTask.copyWith(dueDate: picked);
    });
  }

  Future<void> _selectTime() async {
    final initialTime = _editedTask.dueTime ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) return;

    setState(() {
      _editedTask = _editedTask.copyWith(dueTime: picked);
    });
  }

  void _cycleEnum<T>(List<T> values, T current, Function(T) update) {
    final currentIndex = values.indexOf(current);
    final nextIndex = (currentIndex + 1) % values.length;
    update(values[nextIndex]);
  }

  void _saveChanges() {
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
          const Divider(),
          _buildDateAndTimeRow(),
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
      items: widget.categories
          .where((c) => c != 'All')
          .map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _editedTask = _editedTask.copyWith(category: value));
        }
      },
    );
  }

  Widget _buildDateAndTimeRow() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(_editedTask.dueDate != null
              ? _dateFormat.format(_editedTask.dueDate!)
              : 'No date set'),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _selectDate,
          ),
          onTap: _selectDate,
        ),
        if (_editedTask.dueDate != null)
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(_editedTask.dueTime != null
                ? _editedTask.dueTime!.format(context)
                : 'No time set'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _selectTime,
            ),
            onTap: _selectTime,
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                Icons.repeat,
                color: _editedTask.repetition != TaskRepetition.never
                    ? Colors.blue
                    : Colors.grey,
              ),
              onPressed: () => _cycleEnum(
                TaskRepetition.values,
                _editedTask.repetition,
                (value) => setState(
                  () => _editedTask = _editedTask.copyWith(repetition: value),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.flag,
                color: _getPriorityColor(_editedTask.priority),
              ),
              onPressed: () => _cycleEnum(
                TaskPriority.values,
                _editedTask.priority,
                (value) => setState(
                  () => _editedTask = _editedTask.copyWith(priority: value),
                ),
              ),
            ),
          ],
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
      onChanged: (value) =>
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
        onChanged: (value) =>
            setState(() => _editedTask = _editedTask.copyWith(description: value)),
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