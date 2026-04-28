import 'package:workcalender/data/models/task_model.dart';
import 'package:workcalender/data/models/category_model.dart';
import 'package:workcalender/data/datasources/database_helper.dart';
import 'package:workcalender/core/constants/app_constants.dart';

class TaskRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Task>> getAllTasks() async {
    final maps = await _db.getAllTasks();
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    final maps = await _db.getTasksByDate(date);
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<List<Task>> getMissedTasks() async {
    final maps = await _db.getMissedTasks();
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<List<Task>> getTasksInRange(DateTime start, DateTime end) async {
    final maps = await _db.getTasksInRange(start, end);
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<Task?> getTaskById(String id) async {
    final map = await _db.getTaskById(id);
    return map != null ? Task.fromMap(map) : null;
  }

  Future<void> saveTask(Task task) async => await _db.insertTask(task.toMap());
  Future<void> updateTask(Task task) async => await _db.updateTask(task.toMap());
  Future<void> deleteTask(String id) async => await _db.deleteTask(id);

  Future<void> markComplete(String id) async {
    final task = await getTaskById(id);
    if (task != null) {
      await updateTask(task.copyWith(
        status: AppConstants.statusCompleted, completedAt: DateTime.now()));
    }
  }

  Future<void> markMissed(String id) async {
    final task = await getTaskById(id);
    if (task != null) await updateTask(task.copyWith(status: AppConstants.statusMissed));
  }

  Future<void> detectAndMarkMissedTasks() async {
    final maps = await _db.getMissedTasks();
    for (final map in maps) {
      await _db.updateTask({...map, 'status': AppConstants.statusMissed});
    }
  }

  Future<Map<String, int>> getStatsForDate(DateTime date) async {
    return await _db.getTaskStatsForDate(date);
  }
}

class CategoryRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Category>> getCategories() async {
    final maps = await _db.getCategories();
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<void> saveCategory(Category category) async =>
      await _db.insertCategory(category.toMap());

  Future<void> deleteCategory(String id) async => await _db.deleteCategory(id);
}

class AnalyticsRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<AnalyticsLog>> getLogsInRange(DateTime start, DateTime end) async {
    final maps = await _db.getAnalyticsInRange(start, end);
    return maps.map((m) => AnalyticsLog.fromMap(m)).toList();
  }

  Future<void> updateDailyAnalytics(DateTime date, List<Task> tasks) async {
    final completed = tasks.where((t) => t.isCompleted).length;
    final missed = tasks.where((t) => t.isMissed).length;
    final total = tasks.length;
    final completedHigh = tasks
        .where((t) => t.isCompleted && t.priority >= AppConstants.priorityHigh).length;
    final totalHigh = tasks.where((t) => t.priority >= AppConstants.priorityHigh).length;

    final completionScore =
        total == 0 ? 0.0 : (completed / total) * AppConstants.completionWeight;
    final priorityScore = totalHigh == 0
        ? AppConstants.priorityWeight
        : (completedHigh / totalHigh) * AppConstants.priorityWeight;
    final score = ((completionScore + priorityScore) * 100).clamp(0.0, 100.0);
    final totalWorked = tasks
        .where((t) => t.isCompleted)
        .fold<int>(0, (sum, t) => sum + t.durationMinutes);

    final log = AnalyticsLog(
      id: '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}',
      date: DateTime(date.year, date.month, date.day),
      tasksCompleted: completed,
      tasksMissed: missed,
      tasksTotal: total,
      productivityScore: score,
      totalMinutesWorked: totalWorked,
      createdAt: DateTime.now(),
    );
    await _db.upsertAnalytics(log.toMap());
  }
}
