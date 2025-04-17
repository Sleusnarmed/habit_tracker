import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_editor_dialog.dart';
import '../widgets/task_detail_sheet.dart';
import 'package:intl/intl.dart';

class TaskListView extends StatefulWidget {
  const TaskListView({super.key});

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  String _currentCategory = 'All';
  final TextEditingController _categoryController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final filteredTasks = taskProvider.getTasksByCategory(_currentCategory);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCategory == 'All' ? 'All Tasks' : _currentCategory),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      drawer: _buildDrawer(taskProvider),
      body:
          filteredTasks.isEmpty
              ? const Center(child: Text('No tasks found'))
              : ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return _buildTaskTile(taskProvider, task);
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(taskProvider),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer(TaskProvider taskProvider) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Center(
              child: Text(
                'Task Categories',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: taskProvider.categories.length,
              itemBuilder: (context, index) {
                final category = taskProvider.categories[index];
                return ListTile(
                  leading: _getCategoryIcon(category),
                  title: Text(category),
                  selected: _currentCategory == category,
                  onTap: () {
                    setState(() => _currentCategory = category);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add New List'),
              onPressed: () => _showAddCategoryDialog(taskProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(TaskProvider taskProvider, Task task) {
    final priorityColor = _getPriorityColor(task.priority);
    final isCompleted = task.isCompleted;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder:
              (context) => TaskDetailSheet(
                task: task,
                categories:
                    taskProvider.categories.where((c) => c != 'All').toList(),
                onSave: (updatedTask) => taskProvider.updateTask(updatedTask),
                onDelete: () => taskProvider.deleteTask(task.id),
              ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: isCompleted ? Colors.grey[200] : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Square Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isCompleted ? Colors.grey : priorityColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                  icon: Icon(
                    isCompleted ? Icons.check : null,
                    color: isCompleted ? Colors.grey : priorityColor,
                    size: 16,
                  ),
                  onPressed: () => taskProvider.toggleTaskCompletion(task),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 12),
              // Task Information
              Expanded(
                child: Row(
                  children: [
                    // Title (takes 3/4 of available space)
                    Expanded(
                      flex: 3,
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey : null,
                        ),
                      ),
                    ),
                    // Date/Time Info (takes 1/4 of available space)
                    if (task.dueTime != null ||
                        task.repetition != TaskRepetition.never)
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (task.dueTime != null)
                              Text(
                                DateFormat('MMM d').format(task.dueTime!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (task.dueTime != null)
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                if (task.repetition != TaskRepetition.never)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.repeat,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeDisplayText(Task task) {
    if (task.dueTime == null) return '';

    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat('h:mm a');

    if (task.duration != null) {
      final endTime = task.dueTime!.add(task.duration!);
      return '${dateFormat.format(task.dueTime!)} • ${timeFormat.format(task.dueTime!)} - ${timeFormat.format(endTime)}';
    } else {
      return '${dateFormat.format(task.dueTime!)} • ${timeFormat.format(task.dueTime!)}';
    }
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
      default:
        return '';
    }
  }

  Icon _getCategoryIcon(String category) {
    switch (category) {
      case 'Work':
        return const Icon(Icons.work);
      case 'Study':
        return const Icon(Icons.school);
      case 'Shopping':
        return const Icon(Icons.shopping_cart);
      default:
        return const Icon(Icons.list);
    }
  }

  Future<void> _showAddTaskDialog(TaskProvider taskProvider) async {
    final task = await showDialog<Task>(
      context: context,
      builder:
          (context) => TaskEditorDialog(
            initialCategory:
                _currentCategory == 'All' ? 'Work' : _currentCategory,
            categories:
                taskProvider.categories.where((c) => c != 'All').toList(),
          ),
    );

    if (task != null) {
      await taskProvider.addTask(task);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added successfully')),
        );
      }
    }
  }

  void _showAddCategoryDialog(TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Category'),
            content: TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_categoryController.text.isNotEmpty) {
                    taskProvider.addCategory(_categoryController.text);
                    _categoryController.clear();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Search Tasks'),
            content: TextField(
              decoration: const InputDecoration(hintText: 'Enter task name...'),
              onChanged: (query) {
                // Implement search functionality
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
