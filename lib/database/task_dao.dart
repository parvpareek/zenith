import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
import 'database_helper.dart';

class TaskDAO {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<int> insert(Task task) async {
    final db = await _databaseHelper.database;
    return await db.insert('tasks', task.toMap());
  }

  Future<Task?> getById(int id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    final db = await _databaseHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'tasks',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'id ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTodaysTasks() async {
    return getTasksByDate(DateTime.now());
  }

  Future<List<Task>> getYesterdaysTasks() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return getTasksByDate(yesterday);
  }

  Future<List<Task>> getTasksInDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC, id ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> update(Task task) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTasksOlderThan(DateTime date) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'tasks',
      where: 'date < ?',
      whereArgs: [date.millisecondsSinceEpoch],
    );
  }

  Future<List<Task>> getAllTasks() async {
    final db = await _databaseHelper.database;
    final maps = await db.query('tasks', orderBy: 'date DESC, id ASC');
    return maps.map((map) => Task.fromMap(map)).toList();
  }
} 