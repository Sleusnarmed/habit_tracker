import 'package:flutter/material.dart';
import 'package:habit_tracker/widgets/advanced_date_picker.dart';
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
    _initializeFromTask();
  }

  void _initializeFromTask() {
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _category = task?.category ?? widget.initialCategory;
    _priority = task?.priority ?? TaskPriority.none;
    _dueDate = task?.dueTime;
    _repetition = task?.repetition ?? TaskRepetition.never;
    _initializeTimeFields(task);
  }

  void _initializeTimeFields(Task? task) {
    if (task?.dueTime != null) {
      _startTime = TimeOfDay.fromDateTime(task!.dueTime!);
      if (task.duration != null) {
        final endTime = task.dueTime!.add(task.duration!);
        _endTime = TimeOfDay.fromDateTime(endTime);
      }
    } else {
      _startTime = null;
      _endTime = null;
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
            initialDate: _dueDate ?? DateTime.now(),
            initialTime: _startTime,
            initialRepetition: _repetition,
            onDateSelected: (date) {
              setState(() {
                _dueDate = date;
                // Update time from the full DateTime
                _startTime = TimeOfDay.fromDateTime(date);
              });
            },
            onTimeSelected: (time) {
              setState(() {
                _startTime = time;
                // Update date with the new time
                if (_dueDate != null) {
                  _dueDate = DateTime(
                    _dueDate!.year,
                    _dueDate!.month,
                    _dueDate!.day,
                    time.hour,
                    time.minute,
                  );
                } else {
                  // If no date selected yet, use today's date with the selected time
                  final now = DateTime.now();
                  _dueDate = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    time.hour,
                    time.minute,
                  );
                }
              });
            },
            onRepetitionChanged:
                (repeat) => setState(() => _repetition = repeat),
            onSave: () {
              if (_dueDate == null) {
                // If no date was selected, use today's date with current or default time
                final now = DateTime.now();
                final time = _startTime ?? const TimeOfDay(hour: 12, minute: 0);
                setState(() {
                  _dueDate = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    time.hour,
                    time.minute,
                  );
                  _startTime = time;
                });
              } else if (_startTime == null) {
                // If date exists but no time, don't save (show error)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a time'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              Navigator.pop(context);
            },
            onCancel: () {
              if (_dueDate == null && widget.initialTask == null) {
                setState(() => _dueDate = null);
              }
              Navigator.pop(context);
            },
          ),
    );
  }

  void _showPriorityPicker(BuildContext context) {
    final buttonContext = context.findRenderObject() as RenderBox;
    final buttonPosition = buttonContext.localToGlobal(Offset.zero);
    final buttonSize = buttonContext.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx + 65,
        buttonPosition.dy - 100,
        buttonPosition.dx + buttonSize.width,
        buttonPosition.dy + buttonSize.height,
      ),
      items: TaskPriority.values.map(_buildPriorityMenuItem).toList(),
    );
  }

  PopupMenuItem<TaskPriority> _buildPriorityMenuItem(TaskPriority priority) {
    final priorityData = _getPriorityData(priority);
    return PopupMenuItem(
      onTap: () => setState(() => _priority = priority),
      child: Row(
        children: [
          Icon(Icons.flag, color: priorityData.color),
          const SizedBox(width: 8),
          Text(priorityData.label),
          if (_priority == priority) ...[
            const Spacer(),
            Icon(Icons.check, color: Theme.of(context).primaryColor),
          ],
        ],
      ),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    final buttonContext = context.findRenderObject() as RenderBox;
    final buttonPosition = buttonContext.localToGlobal(Offset.zero);
    final buttonSize = buttonContext.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx + 125,
        buttonPosition.dy - 50,
        buttonPosition.dx + buttonSize.width,
        buttonPosition.dy + buttonSize.height,
      ),
      items: _buildCategoryMenuItems(),
    );
  }

  List<PopupMenuItem<String>> _buildCategoryMenuItems() {
    final theme = Theme.of(context);
    return widget.categories
        .where((c) => c != 'All')
        .map(
          (category) => PopupMenuItem<String>(
            value: category,
            onTap: () => setState(() => _category = category),
            child: Row(
              children: [
                Text(category),
                if (_category == category) ...[
                  const Spacer(),
                  Icon(Icons.check, color: theme.primaryColor),
                ],
              ],
            ),
          ),
        )
        .toList();
  }

  void _saveTask() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    try {
      // This will throw if date/time is invalid
      final task = _buildTask();
      Navigator.pop(context, task);
    } on ArgumentError catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Invalid date/time')));
    }
  }

  Task _buildTask() {
    // Ensure we have both date and time
    if (_dueDate == null || _startTime == null) {
      throw ArgumentError('Both date and time must be selected');
    }

    // Create the final dueTime with both components
    final dueTime = DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    _validateTimeRange(dueTime);

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

  DateTime? _calculateDueTime() {
    if (_dueDate == null || _startTime == null) return null;

    return DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
  }

  void _validateTimeRange(DateTime? dueTime) {
    if (dueTime != null && _endTime != null) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).dialogBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleField(),
          _buildDescriptionField(),
          _buildActionRow(),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: 'What do you need to do?',
        hintStyle: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
      ),
      style: Theme.of(context).textTheme.titleMedium,
      autofocus: true,
    );
  }

  Widget _buildDescriptionField() {
    return Expanded(
      child: TextField(
        controller: _descController,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Description...',
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        maxLines: null,
        keyboardType: TextInputType.multiline,
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [_buildActionButtons(), _buildSaveButton()],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _buildIconButton(
          icon: Icons.calendar_today,
          onPressed: () => _showAdvancedDatePicker(context),
        ),
        _buildIconButton(
          icon: Icons.flag,
          color: _getPriorityColor(_priority),
          onPressed: () => _showPriorityPicker(context),
        ),
        _buildIconButton(
          icon: Icons.arrow_forward,
          onPressed: () => _showCategoryPicker(context),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    Color? color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 24, color: color),
      onPressed: onPressed,
    );
  }

  Widget _buildSaveButton() {
    return FloatingActionButton(
      mini: true,
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.send, color: Colors.white),
      onPressed: _saveTask,
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    return _getPriorityData(priority).color;
  }

  _PriorityData _getPriorityData(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return _PriorityData(Colors.red, 'High');
      case TaskPriority.medium:
        return _PriorityData(Colors.orange, 'Medium');
      case TaskPriority.low:
        return _PriorityData(Colors.blue, 'Low');
      case TaskPriority.none:
        return _PriorityData(Colors.grey, 'None');
    }
  }
}

class _PriorityData {
  final Color color;
  final String label;

  _PriorityData(this.color, this.label);
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
