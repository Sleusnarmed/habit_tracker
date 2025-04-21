import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_editor_dialog.dart';
import '../widgets/task_detail_sheet.dart';

enum GroupFilter { none, date, priority }
enum OrderFilter { date, title, priority }

class TaskListView extends StatefulWidget {
  const TaskListView({super.key});

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  String _currentCategory = 'All';
  final TextEditingController _categoryController = TextEditingController();
  GroupFilter _groupFilter = GroupFilter.none;
  OrderFilter _orderFilter = OrderFilter.date;
  bool _showCompletedTasks = true;

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final filteredTasks = _getFilteredAndOrderedTasks(taskProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCategory == 'All' ? 'All Tasks' : _currentCategory),
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'filter', child: Text('Filter')),
              PopupMenuItem(
                value: 'toggle_completed',
                child: Text(
                  _showCompletedTasks ? 'Hide Completed' : 'Show Completed',
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'filter') _showFilterDialog();
              if (value == 'toggle_completed') {
                setState(() => _showCompletedTasks = !_showCompletedTasks);
              }
            },
          ),
        ],
      ),
      drawer: _buildDrawer(taskProvider),
      body: filteredTasks.isEmpty
          ? const Center(child: Text('No tasks found'))
          : _buildTaskList(filteredTasks),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(taskProvider),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Task> _getFilteredAndOrderedTasks(TaskProvider taskProvider) {
    List<Task> tasks = taskProvider.getTasksByCategory(_currentCategory);

    if (!_showCompletedTasks) {
      tasks = tasks.where((task) => !task.isCompleted).toList();
    }

    tasks = _applyOrdering(tasks);
    return tasks;
  }

  List<Task> _applyOrdering(List<Task> tasks) {
    switch (_orderFilter) {
      case OrderFilter.date:
        tasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case OrderFilter.title:
        tasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case OrderFilter.priority:
        tasks.sort((a, b) {
          if (a.priority.index != b.priority.index) {
            return a.priority.index.compareTo(b.priority.index);
          }
          return a.title.compareTo(b.title);
        });
        break;
    }
    return tasks;
  }

  Widget _buildTaskList(List<Task> tasks) {
    switch (_groupFilter) {
      case GroupFilter.none:
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) => TaskTile(
            task: tasks[index],
            taskProvider: Provider.of<TaskProvider>(context),
            currentCategory: _currentCategory,
          ),
        );
      case GroupFilter.date:
        return _buildDateGroupedList(tasks);
      case GroupFilter.priority:
        return _buildPriorityGroupedList(tasks);
    }
  }

  Widget _buildDateGroupedList(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    final todayTasks = tasks.where((task) {
      if (task.dueDate == null) return false;
      final dueDay = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return dueDay == today;
    }).toList();

    final tomorrowTasks = tasks.where((task) {
      if (task.dueDate == null) return false;
      final dueDay = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return dueDay == tomorrow;
    }).toList();

    final thisWeekTasks = tasks.where((task) {
      if (task.dueDate == null) return false;
      final dueDay = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return dueDay.isAfter(tomorrow) && dueDay.isBefore(nextWeek);
    }).toList();

    final laterTasks = tasks.where((task) {
      if (task.dueDate == null) return true;
      final dueDay = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return dueDay.isAfter(nextWeek) || dueDay.isBefore(today);
    }).toList();

    return ListView(
      children: [
        if (todayTasks.isNotEmpty) _buildTaskGroup('Today', todayTasks),
        if (tomorrowTasks.isNotEmpty) _buildTaskGroup('Tomorrow', tomorrowTasks),
        if (thisWeekTasks.isNotEmpty) _buildTaskGroup('This Week', thisWeekTasks),
        if (laterTasks.isNotEmpty) _buildTaskGroup('Later', laterTasks),
      ],
    );
  }

  Widget _buildPriorityGroupedList(List<Task> tasks) {
    final highPriority = tasks.where((t) => t.priority == TaskPriority.high).toList();
    final mediumPriority = tasks.where((t) => t.priority == TaskPriority.medium).toList();
    final lowPriority = tasks.where((t) => t.priority == TaskPriority.low).toList();
    final noPriority = tasks.where((t) => t.priority == TaskPriority.none).toList();

    return ListView(
      children: [
        if (highPriority.isNotEmpty) _buildTaskGroup('High Priority', highPriority),
        if (mediumPriority.isNotEmpty) _buildTaskGroup('Medium Priority', mediumPriority),
        if (lowPriority.isNotEmpty) _buildTaskGroup('Low Priority', lowPriority),
        if (noPriority.isNotEmpty) _buildTaskGroup('No Priority', noPriority),
      ],
    );
  }

  Widget _buildTaskGroup(String title, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        ...tasks.map(
          (task) => TaskTile(
            task: task,
            taskProvider: Provider.of<TaskProvider>(context),
            currentCategory: _currentCategory,
          ),
        ),
      ],
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
    final task = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TaskEditorDialog(
        initialCategory: _currentCategory == 'All' ? 'Work' : _currentCategory,
        categories: taskProvider.categories.where((c) => c != 'All').toList(),
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
      builder: (context) => AddCategoryDialog(
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

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Tasks'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Group by:', style: TextStyle(fontWeight: FontWeight.bold)),
            Column(
              children: GroupFilter.values.map((filter) {
                return RadioListTile<GroupFilter>(
                  title: Text(_getGroupFilterText(filter)),
                  value: filter,
                  groupValue: _groupFilter,
                  onChanged: (value) {
                    setState(() => _groupFilter = value!);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Order by:', style: TextStyle(fontWeight: FontWeight.bold)),
            Column(
              children: OrderFilter.values.map((filter) {
                return RadioListTile<OrderFilter>(
                  title: Text(_getOrderFilterText(filter)),
                  value: filter,
                  groupValue: _orderFilter,
                  onChanged: (value) {
                    setState(() => _orderFilter = value!);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ],
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

  String _getGroupFilterText(GroupFilter filter) {
    switch (filter) {
      case GroupFilter.none: return 'None';
      case GroupFilter.date: return 'Date';
      case GroupFilter.priority: return 'Priority';
    }
  }

  String _getOrderFilterText(OrderFilter filter) {
    switch (filter) {
      case OrderFilter.date: return 'Date';
      case OrderFilter.title: return 'Title';
      case OrderFilter.priority: return 'Priority';
    }
  }
}

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
      builder: (context) => TaskDetailSheet(
        task: task,
        categories: taskProvider.categories.where((c) => c != 'All').toList(),
        onSave: (updatedTask) => taskProvider.updateTask(updatedTask),
        onDelete: () => taskProvider.deleteTask(task.id),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return Colors.red;
      case TaskPriority.medium: return Colors.orange;
      case TaskPriority.low: return Colors.blue;
      case TaskPriority.none: return Colors.grey;
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
        if (task.dueDate != null || task.repetition != TaskRepetition.never)
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
        if (task.dueDate != null)
          Text(
            _getRelativeDate(context, task),
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

  String _getRelativeDate(BuildContext context, Task task) {
    if (task.dueDate == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);

    String dateStr;
    if (dueDay == today) {
      dateStr = 'Today';
    } else if (dueDay == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = DateFormat('MMM d').format(task.dueDate!);
    }

    if (task.dueTime != null) {
      dateStr += ', ${task.dueTime!.format(context)}';
    }

    return dateStr;
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
      case 'Work': return const Icon(Icons.work);
      case 'Study': return const Icon(Icons.school);
      case 'Shopping': return const Icon(Icons.shopping_cart);
      default: return const Icon(Icons.list);
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