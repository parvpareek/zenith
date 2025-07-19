import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../database/task_dao.dart';
import 'providers.dart';

// State notifier for task list
class TaskNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final TaskDAO _taskDAO;

  TaskNotifier(this._taskDAO) : super(const AsyncValue.loading()) {
    loadTodaysTasks();
  }

  Future<void> loadTodaysTasks() async {
    try {
      state = const AsyncValue.loading();
      final tasks = await _taskDAO.getTodaysTasks();
      state = AsyncValue.data(tasks);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addTask(String description, double hours) async {
    if (description.trim().isEmpty) return;

    try {
      final task = Task(
        description: description.trim(),
        isCompleted: false,
        date: DateTime.now(),
        hours: hours,
      );
      
      await _taskDAO.insert(task);
      await loadTodaysTasks(); // Reload to get updated list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleTaskCompletion(Task task) async {
    try {
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await _taskDAO.update(updatedTask);
      await loadTodaysTasks(); // Reload to get updated list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateTask(Task task, String newDescription, double newHours) async {
    if (newDescription.trim().isEmpty) return;

    try {
      final updatedTask = task.copyWith(
        description: newDescription.trim(),
        hours: newHours,
      );
      await _taskDAO.update(updatedTask);
      await loadTodaysTasks(); // Reload to get updated list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateTaskHours(Task task, double newHours) async {
    try {
      final updatedTask = task.copyWith(hours: newHours);
      await _taskDAO.update(updatedTask);
      await loadTodaysTasks(); // Reload to get updated list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteTask(Task task) async {
    try {
      if (task.id != null) {
        await _taskDAO.delete(task.id!);
        await loadTodaysTasks(); // Reload to get updated list
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Get completed and pending tasks separately
  List<Task> get completedTasks {
    return state.when(
      data: (tasks) => tasks.where((task) => task.isCompleted).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  List<Task> get pendingTasks {
    return state.when(
      data: (tasks) => tasks.where((task) => !task.isCompleted).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  int get completedCount => completedTasks.length;
  int get totalCount => state.when(
    data: (tasks) => tasks.length,
    loading: () => 0,
    error: (_, __) => 0,
  );

  double get completionPercentage {
    final total = totalCount;
    if (total == 0) return 0.0;
    return completedCount / total;
  }
}

// Provider for task state
final taskProvider = StateNotifierProvider<TaskNotifier, AsyncValue<List<Task>>>((ref) {
  final taskDAO = ref.watch(taskDAOProvider);
  return TaskNotifier(taskDAO);
});

// Provider for getting yesterday's tasks (for AI Coach context)
final yesterdaysTasksProvider = FutureProvider<List<Task>>((ref) async {
  final taskDAO = ref.watch(taskDAOProvider);
  return await taskDAO.getYesterdaysTasks();
});

// Provider for getting tasks in a date range (for AI Coach context)
final tasksInRangeProvider = FutureProvider.family<List<Task>, DateRange>((ref, dateRange) async {
  final taskDAO = ref.watch(taskDAOProvider);
  return await taskDAO.getTasksInDateRange(dateRange.start, dateRange.end);
});

class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

// Daily task summary for history view
class DailyTaskSummary {
  final DateTime date;
  final List<Task> tasks;
  
  DailyTaskSummary({required this.date, required this.tasks});
  
  int get completedCount => tasks.where((task) => task.isCompleted).length;
  int get totalCount => tasks.length;
  int get pendingCount => totalCount - completedCount;
  
  List<Task> get completedTasks => tasks.where((task) => task.isCompleted).toList();
  List<Task> get pendingTasks => tasks.where((task) => !task.isCompleted).toList();
}

// Provider for historical tasks (last 30 days)
final historicalTasksProvider = FutureProvider<List<DailyTaskSummary>>((ref) async {
  final taskDAO = ref.watch(taskDAOProvider);
  final endDate = DateTime.now();
  final startDate = endDate.subtract(const Duration(days: 30));
  
  final allTasks = await taskDAO.getTasksInDateRange(startDate, endDate);
  
  // Group tasks by date
  final groupedTasks = <DateTime, List<Task>>{};
  for (final task in allTasks) {
    final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
    if (!groupedTasks.containsKey(taskDate)) {
      groupedTasks[taskDate] = [];
    }
    groupedTasks[taskDate]!.add(task);
  }
  
  // Convert to DailyTaskSummary objects and sort by date descending
  final summaries = groupedTasks.entries
      .map((entry) => DailyTaskSummary(date: entry.key, tasks: entry.value))
      .toList();
  
  summaries.sort((a, b) => b.date.compareTo(a.date));
  
  return summaries;
});

// Provider for showing history state
final showHistoryProvider = StateProvider<bool>((ref) => false); 