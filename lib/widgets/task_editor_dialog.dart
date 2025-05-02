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
  DateTime? _dueDate; // Keep this as it maps to Task.dueDate
  TimeOfDay? _startTime; // This maps to Task.dueTime
  TimeOfDay? _endTime; // For duration calculation
  late TaskRepetition _repetition;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _category = task?.category ?? widget.initialCategory;
    _priority = task?.priority ?? TaskPriority.none;
    _repetition = task?.repetition ?? TaskRepetition.never;

    // Initialize date and time from existing task
    _dueDate = task?.dueDate;
    _startTime = task?.startTime;

    // Initialize duration if exists
    if (task?.duration != null && task?.startTime != null) {
      final fakeDate = DateTime(2023, 1, 1); // Arbitrary date for calculation
      final start = DateTime(
        fakeDate.year,
        fakeDate.month,
        fakeDate.day,
        task!.startTime!.hour,
        task.startTime!.minute,
      );
      final end = start.add(task.duration!);
      _endTime = TimeOfDay.fromDateTime(end);
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

    final fakeDate = DateTime(2023, 1, 1); // Use arbitrary date for calculation
    final start = DateTime(
      fakeDate.year,
      fakeDate.month,
      fakeDate.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    final end = DateTime(
      fakeDate.year,
      fakeDate.month,
      fakeDate.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    return end.difference(start);
  }

  void _showAdvancedDatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => AdvancedDatePicker(
            initialDate: _dueDate,
            initialTime: _startTime,
            initialRepetition: _repetition,
            onDateSelected:
                (date) => setState(() {
                  _dueDate = date;
                  // Clear times if date changes
                  if (_startTime != null && _dueDate == null) {
                    _startTime = null;
                    _endTime = null;
                  }
                }),
            onTimeSelected: (time) => setState(() => _startTime = time),
            onRepetitionChanged:
                (repeat) => setState(() => _repetition = repeat),
            onSave: () => Navigator.pop(context),
            onCancel: () {
              if (widget.initialTask == null) {
                setState(() {
                  _dueDate = null;
                  _startTime = null;
                  _endTime = null;
                });
              }
              Navigator.pop(context);
            },
          ),
    );
  }

  void _showPriorityPicker(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset buttonPosition = button.localToGlobal(Offset.zero);
    final buttonSize = button.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx + 65,
        buttonPosition.dy - 100,
        buttonPosition.dx + buttonSize.width,
        buttonPosition.dy + buttonSize.height,
      ),
      items: [
        PopupMenuItem(
          onTap: () => setState(() => _priority = TaskPriority.high),
          child: Row(
            children: [
              Icon(Icons.flag, color: Colors.red),
              SizedBox(width: 8),
              Text('High'),
              if (_priority == TaskPriority.high) ...[
                Spacer(),
                Icon(Icons.check, color: Theme.of(context).primaryColor),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => setState(() => _priority = TaskPriority.medium),
          child: Row(
            children: [
              Icon(Icons.flag, color: Colors.orange),
              SizedBox(width: 8),
              Text('Medium'),
              if (_priority == TaskPriority.medium) ...[
                Spacer(),
                Icon(Icons.check, color: Theme.of(context).primaryColor),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => setState(() => _priority = TaskPriority.low),
          child: Row(
            children: [
              Icon(Icons.flag, color: Colors.blue),
              SizedBox(width: 8),
              Text('Low'),
              if (_priority == TaskPriority.low) ...[
                Spacer(),
                Icon(Icons.check, color: Theme.of(context).primaryColor),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => setState(() => _priority = TaskPriority.none),
          child: Row(
            children: [
              Icon(Icons.flag, color: Colors.grey),
              SizedBox(width: 8),
              Text('None'),
              if (_priority == TaskPriority.none) ...[
                Spacer(),
                Icon(Icons.check, color: Theme.of(context).primaryColor),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showCategoryPicker(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset buttonPosition = button.localToGlobal(Offset.zero);
    final buttonSize = button.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx + 125,
        buttonPosition.dy - 50,
        buttonPosition.dx + buttonSize.width,
        buttonPosition.dy + buttonSize.height,
      ),
      items:
          widget.categories
              .where((c) => c != 'All')
              .map(
                (category) => PopupMenuItem(
                  onTap: () => setState(() => _category = category),
                  child: Row(
                    children: [
                      Text(category),
                      if (_category == category) ...[
                        Spacer(),
                        Icon(
                          Icons.check,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  void _saveTask() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    try {
      Navigator.pop(context, _buildTask());
    } on ArgumentError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Invalid time range')),
      );
    }
  }

  Task _buildTask() {
    DateTime? dueTime;

    if (_dueDate != null && _startTime != null) {
      // Only combine if both exist
      dueTime = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

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
      dueDate: _dueDate,
      startTime: _startTime,
      duration: _duration,
      repetition: _repetition,
    );
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'What do you need to do?',
              hintStyle: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            style: Theme.of(context).textTheme.titleMedium, //Fontsize
            autofocus: true,
          ),

          // Description
          Expanded(
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
          ),

          // Bottom action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.calendar_today, size: 24),
                    onPressed: () => _showAdvancedDatePicker(context),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.flag,
                      size: 24,
                      color: _getPriorityColor(_priority),
                    ),
                    onPressed: () => _showPriorityPicker(context),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward, size: 24),
                    onPressed: () => _showCategoryPicker(context),
                  ),
                ],
              ),

              // Send button
              FloatingActionButton(
                mini: true,
                elevation: 0,
                backgroundColor: Theme.of(context).primaryColor,
                onPressed: _saveTask,
                child: Icon(Icons.send, color: Colors.white),
              ),
            ],
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
