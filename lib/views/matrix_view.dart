import 'package:flutter/material.dart';
import 'package:habit_tracker/models/task.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/providers/task_provider.dart';

class MatrixView extends StatelessWidget {
  const MatrixView({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;

    // Categorize tasks into quadrants based on priority and urgency
    final doFirst =
        tasks.where((task) => task.priority == TaskPriority.high).toList();

    final schedule =
        tasks.where((task) => task.priority == TaskPriority.medium).toList();

    final automate =
        tasks.where((task) => task.priority == TaskPriority.low).toList();

    final eliminate =
        tasks.where((task) => task.priority == TaskPriority.none).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Eisenhower Matrix")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: const [
                Expanded(
                  child: Center(
                    child: Text(
                      "IMPORTANT",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "NOT IMPORTANT",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuadrant(
                      context,
                      "DO FIRST",
                      doFirst,
                      Colors.green,
                      Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuadrant(
                      context,
                      "AUTOMATE",
                      automate,
                      Colors.blue,
                      Icons.assignment_ind,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuadrant(
                      context,
                      "SCHEDULE",
                      schedule,
                      Colors.amber,
                      Icons.schedule,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuadrant(
                      context,
                      "ELIMINATE",
                      eliminate,
                      Colors.red,
                      Icons.delete_outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuadrant(
    BuildContext context,
    String title,
    List<Task> tasks,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text('${tasks.length}'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                tasks.isEmpty
                    ? const Center(child: Text("No tasks"))
                    : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: task.isCompleted,
                                onChanged: (value) {
                                  Provider.of<TaskProvider>(
                                    context,
                                    listen: false,
                                  ).updateTask(
                                    task.copyWith(isCompleted: value ?? false),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        decoration:
                                            task.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                      ),
                                    ),
                                    if (task.dueDate != null)
                                      Text(
                                        'Due: ${DateFormat('MMM d').format(task.dueDate!)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
