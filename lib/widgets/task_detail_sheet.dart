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
  final _timeFormat = DateFormat('jm');

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

  String get _dueDateText {
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

    return '$daysText${_dateFormat.format(due)}, ${_timeFormat.format(due)}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _editedTask.dueTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

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

  Future<void> _selectTime() async {
    final initialTime =
        _editedTask.dueTime != null
            ? TimeOfDay.fromDateTime(_editedTask.dueTime!)
            : TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) return;

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
          _buildDateAndPriorityRow(),
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
    );
  }

  Widget _buildDateAndPriorityRow() {
    return ListTile(
      title: Text(_dueDateText),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.repeat,
              color:
                  _editedTask.repetition != TaskRepetition.never
                      ? Colors.blue
                      : Colors.grey,
            ),
            onPressed:
                () => _cycleEnum(
                  TaskRepetition.values,
                  _editedTask.repetition,
                  (value) => setState(
                    () => _editedTask = _editedTask.copyWith(repetition: value),
                  ),
                ), // Added missing parenthesis here
          ),
          IconButton(
            icon: Icon(
              Icons.flag,
              color: _getPriorityColor(_editedTask.priority),
            ),
            onPressed:
                () => _cycleEnum(
                  TaskPriority.values,
                  _editedTask.priority,
                  (value) => setState(
                    () => _editedTask = _editedTask.copyWith(priority: value),
                  ),
                ), // Added missing parenthesis here
          ),
        ],
      ),
      onTap: _selectDate,
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
