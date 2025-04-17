import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_editor_dialog.dart';

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
      body: filteredTasks.isEmpty
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => taskProvider.deleteTask(task.id),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (value) => taskProvider.toggleTaskCompletion(task),
          ),
          title: Row(
            children: [
              if (task.priority != TaskPriority.none)
                Icon(
                  Icons.flag,
                  color: _getPriorityColor(task.priority),
                  size: 18,
                ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: task.isCompleted ? Colors.grey : null,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty) Text(task.description),
              if (task.dueTime != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      task.duration != null
                          ? task.formattedDuration!
                          : task.formattedTime!,
                      style: TextStyle(
                        color: task.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    if (task.repetition != TaskRepetition.never) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.repeat,
                        size: 14,
                        color: task.isCompleted ? Colors.grey : Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getRepetitionText(task.repetition),
                        style: TextStyle(
                          color: task.isCompleted ? Colors.grey : Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
          trailing: _getCategoryIcon(task.category),
        ),
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
      builder: (context) => TaskEditorDialog(
        initialCategory: _currentCategory == 'All' ? 'Work' : _currentCategory,
        categories: taskProvider.categories.where((c) => c != 'All').toList(),
      ),
    );

    if (task != null) {
      await taskProvider.addTask(task);
    }
  }

  void _showAddCategoryDialog(TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
      builder: (context) => AlertDialog(
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