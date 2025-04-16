import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:habit_tracker/models/task.dart'; // You'll need to create this model

class TaskListView extends StatefulWidget {
  const TaskListView({super.key});

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  final List<Task> _tasks = [
    Task(id: '1', title: 'Complete project proposal', category: 'Work', isCompleted: false),
    Task(id: '2', title: 'Buy groceries', category: 'Shopping', isCompleted: true),
    Task(id: '3', title: 'Study Flutter', category: 'Study', isCompleted: false),
  ];

  String _currentCategory = 'All';
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _currentCategory == 'All'
        ? _tasks
        : _tasks.where((task) => task.category == _currentCategory).toList();

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
      drawer: _buildDrawer(),
      body: filteredTasks.isEmpty
          ? const Center(child: Text('No tasks found'))
          : ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return _buildTaskTile(task);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer() {
    final categories = ['All', 'Work', 'Study', 'Shopping'];
    
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
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
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
              onPressed: () => _showAddCategoryDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => _deleteTask(task.id),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: CheckboxListTile(
          value: task.isCompleted,
          onChanged: (value) => _toggleTaskCompletion(task.id),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          secondary: _getCategoryIcon(task.category),
        ),
      ),
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

  void _toggleTaskCompletion(String taskId) {
    setState(() {
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex].isCompleted = !_tasks[taskIndex].isCompleted;
      }
    });
  }

  void _deleteTask(String taskId) {
    setState(() {
      _tasks.removeWhere((task) => task.id == taskId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task deleted')),
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _taskController,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currentCategory == 'All' ? 'Work' : _currentCategory,
              items: ['Work', 'Study', 'Shopping']
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) => _currentCategory = value ?? 'Work',
              decoration: const InputDecoration(labelText: 'Category'),
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
              if (_taskController.text.isNotEmpty) {
                setState(() {
                  _tasks.add(Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: _taskController.text,
                    category: _currentCategory,
                    isCompleted: false,
                  ));
                  _taskController.clear();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
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
                // In a real app, you would add this to your categories list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_categoryController.text} category added')),
                );
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