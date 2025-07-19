import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/task.dart';
import '../../viewmodels/task_viewmodel.dart';

class ActionBoardScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ActionBoardScreen> createState() => _ActionBoardScreenState();
}

class _ActionBoardScreenState extends ConsumerState<ActionBoardScreen> {
  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskProvider);
    final showHistory = ref.watch(showHistoryProvider);
    final historicalTasksAsync = ref.watch(historicalTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
              child: Row(
                children: [
                  Text(
                    'Board',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
            ),
                  const Spacer(),
                  // History toggle button
                  IconButton(
              onPressed: () {
                      ref.read(showHistoryProvider.notifier).state = !showHistory;
                    },
                    icon: Icon(
                      showHistory ? Icons.today : Icons.history,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: showHistory 
                ? _buildHistoryView(historicalTasksAsync)
                : _buildTodayView(tasksAsync),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: AppColors.accentBlack,
        foregroundColor: AppColors.textPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodayView(AsyncValue<List<Task>> tasksAsync) {
    return tasksAsync.when(
      data: (tasks) {
        final todoTasks = tasks.where((task) => !task.isCompleted).toList();
        final completedTasks = tasks.where((task) => task.isCompleted).toList();
        
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // Today's summary
            _buildDaySummary(
              'Today',
              DateTime.now(),
              tasks,
              isToday: true,
            ),
            
            // To-Do Section
            if (todoTasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'To-Do',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
              const SizedBox(height: 8),
              ...todoTasks.map((task) => _buildTaskItem(task)),
            ],
            
            // Completed Section
            if (completedTasks.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Completed',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...completedTasks.map((task) => _buildTaskItem(task)),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          'Error: $error',
          style: const TextStyle(color: AppColors.textPrimary),
          ),
      ),
    );
  }

  Widget _buildHistoryView(AsyncValue<List<DailyTaskSummary>> historicalTasksAsync) {
    return historicalTasksAsync.when(
      data: (summaries) {
        if (summaries.isEmpty) {
          return const Center(
            child: Text(
              'No task history found',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: summaries.length,
          itemBuilder: (context, index) {
            final summary = summaries[index];
            final isToday = _isToday(summary.date);
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // Date header with summary
                _buildDaySummary(
                  isToday ? 'Today' : null,
                  summary.date,
                  summary.tasks,
                  isToday: isToday,
                ),
                
                // Tasks for this date
                if (summary.tasks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...summary.tasks.map((task) => _buildTaskItem(task, showDate: false)),
                ],
                
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
                loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          'Error: $error',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildDaySummary(String? label, DateTime date, List<Task> tasks, {bool isToday = false}) {
    final completedCount = tasks.where((task) => task.isCompleted).length;
    final totalCount = tasks.length;
    final pendingCount = totalCount - completedCount;
    
    final dateFormat = DateFormat('d-MMMM(E)');
    final displayDate = label ?? dateFormat.format(date);
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayDate,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (totalCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                // Completed tasks
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
                    mainAxisSize: MainAxisSize.min,
        children: [
                      const Icon(Icons.check, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$completedCount',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
              ),
                      ),
                    ],
            ),
          ),
          const SizedBox(width: 12),
                // Pending tasks
          Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.close, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
            ),
              ],
          ),
          ],
        ],
      ),
    );
  }

    Widget _buildTaskItem(Task task, {bool showDate = true}) {
    return Dismissible(
      key: Key('task_${task.id}'),
      background: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(0),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        ref.read(taskProvider.notifier).deleteTask(task);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.description}" deleted'),
            backgroundColor: AppColors.darkSurface,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(0),
      ),
        child: Row(
          children: [
            Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                    task.description,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
                  if (task.hours > 0) ...[
                    const SizedBox(height: 4),
              Text(
                      '${task.hours.toString().replaceAll('.0', '')} hours',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                ),
              ),
            ],
                ],
              ),
          ),
            const SizedBox(width: 16),
            SizedBox(
              width: 28,
              height: 28,
              child: Checkbox(
                value: task.isCompleted,
                onChanged: (bool? value) {
                  if (value != null) {
                    ref.read(taskProvider.notifier).toggleTaskCompletion(task);
                  }
                },
                activeColor: AppColors.accentBlack,
                checkColor: AppColors.textPrimary,
                side: const BorderSide(
                  color: AppColors.textSecondary,
                  width: 2,
                ),
                ),
              ),
            ],
          ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _showAddTaskDialog(BuildContext context) {
    final taskController = TextEditingController();
    final hoursController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          'Add New Task',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: taskController,
              decoration: const InputDecoration(
                hintText: 'Task description',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accentBlack),
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hoursController,
              decoration: const InputDecoration(
                hintText: 'Estimated hours (optional)',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accentBlack),
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              if (taskController.text.trim().isNotEmpty) {
                final hours = double.tryParse(hoursController.text.trim()) ?? 0.0;
                ref.read(taskProvider.notifier).addTask(
                  taskController.text.trim(),
                  hours,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text(
              'Add Task',
              style: TextStyle(color: AppColors.accentBlack),
                ),
              ),
            ],
      ),
    );
  }
} 