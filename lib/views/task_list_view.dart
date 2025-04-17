import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_editor_dialog.dart';
import '../widgets/task_detail_sheet.dart';

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
            onPressed: _showSearchDialog,
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
                  return TaskTile(
                    task: task,
                    taskProvider: taskProvider,
                    currentCategory: _currentCategory,
                  );
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
                return CategoryListItem(
                  category: category,
                  isSelected: _currentCategory == category,
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
          (context) => AddCategoryDialog(
            controller: _categoryController,
            onAdd: () {
              if (_categoryController.text.isNotEmpty) {
                taskProvider.addCategory(_categoryController.text);
                _categoryController.clear();
                Navigator.pop(context);
              }
            },
          ),
    );
  }

  void _showSearchDialog() {
    showDialog(context: context, builder: (context) => const SearchDialog());
  }
}

// Extracted Widgets

class TaskTile extends StatelessWidget {
  final Task task;
  final TaskProvider taskProvider;
  final String currentCategory;

  const TaskTile({
    super.key,
    required this.task,
    required this.taskProvider,
    required this.currentCategory,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(task.priority);
    final isCompleted = task.isCompleted;

    return GestureDetector(
      onTap: () => _showTaskDetails(context),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: isCompleted ? Colors.grey[200] : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              TaskCheckbox(
                isCompleted: isCompleted,
                priorityColor: priorityColor,
                onChanged: () => taskProvider.toggleTaskCompletion(task),
              ),
              const SizedBox(width: 12),
              Expanded(child: TaskInfo(task: task, flexRatio: 3)),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context) {
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

class TaskCheckbox extends StatelessWidget {
  final bool isCompleted;
  final Color priorityColor;
  final VoidCallback onChanged;

  const TaskCheckbox({
    super.key,
    required this.isCompleted,
    required this.priorityColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        onPressed: onChanged,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}

class TaskInfo extends StatelessWidget {
  final Task task;
  final int flexRatio;

  const TaskInfo({super.key, required this.task, this.flexRatio = 3});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: flexRatio,
          child: Text(
            task.title,
            style: TextStyle(
              fontSize: 16,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : null,
            ),
          ),
        ),
        if (task.dueTime != null || task.repetition != TaskRepetition.never)
          Expanded(flex: 1, child: TaskMetaInfo(task: task)),
      ],
    );
  }
}

class TaskMetaInfo extends StatelessWidget {
  final Task task;

  const TaskMetaInfo({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (task.dueTime != null)
          Text(
            _getRelativeDate(task.dueTime!),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (task.dueTime != null)
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
            if (task.repetition != TaskRepetition.never)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.repeat, size: 14, color: Colors.grey[600]),
              ),
          ],
        ),
      ],
    );
  }

  String _getRelativeDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDay == today) return 'Today';
    if (dueDay == tomorrow) return 'Tomorrow';
    return DateFormat('MMM d').format(dueDate);
  }
}

class CategoryListItem extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryListItem({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _getCategoryIcon(category),
      title: Text(category),
      selected: isSelected,
      onTap: onTap,
    );
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
}

class AddCategoryDialog extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const AddCategoryDialog({
    super.key,
    required this.controller,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Category'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Category Name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: onAdd, child: const Text('Add')),
      ],
    );
  }
}

class SearchDialog extends StatelessWidget {
  const SearchDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Tasks'),
      content: const TextField(
        decoration: InputDecoration(hintText: 'Enter task name...'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
