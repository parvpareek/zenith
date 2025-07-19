import 'package:sqflite/sqflite.dart';
import '../models/log_entry.dart';
import 'database_helper.dart';

class LogEntryDAO {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<int> insert(LogEntry entry) async {
    final db = await _databaseHelper.database;
    return await db.insert('log_entries', entry.toMap());
  }

  Future<LogEntry?> getById(int id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'log_entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return LogEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<List<LogEntry>> getEntriesByDate(DateTime date) async {
    final db = await _databaseHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'log_entries',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => LogEntry.fromMap(map)).toList();
  }

  Future<List<LogEntry>> getEntriesByCategory(LogEntryCategory category) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'log_entries',
      where: 'category = ?',
      whereArgs: [category.value],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => LogEntry.fromMap(map)).toList();
  }

  Future<List<LogEntry>> getEntriesByDateAndCategory(DateTime date, LogEntryCategory category) async {
    final db = await _databaseHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'log_entries',
      where: 'timestamp >= ? AND timestamp < ? AND category = ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
        category.value,
      ],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => LogEntry.fromMap(map)).toList();
  }

  Future<List<LogEntry>> getTodaysEntries() async {
    return getEntriesByDate(DateTime.now());
  }

  Future<List<LogEntry>> getTodaysEntriesByCategory(LogEntryCategory category) async {
    return getEntriesByDateAndCategory(DateTime.now(), category);
  }

  Future<List<LogEntry>> getEntriesInDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'log_entries',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => LogEntry.fromMap(map)).toList();
  }

  Future<List<LogEntry>> getLastNDaysEntries(int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return getEntriesInDateRange(startDate, endDate);
  }

  Future<List<LogEntry>> searchEntries(String searchTerm) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'log_entries',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$searchTerm%', '%$searchTerm%'],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => LogEntry.fromMap(map)).toList();
  }

  Future<List<LogEntry>> searchEntriesByCategory(String searchTerm, LogEntryCategory category) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'log_entries',
      where: '(title LIKE ? OR content LIKE ?) AND category = ?',
      whereArgs: ['%$searchTerm%', '%$searchTerm%', category.value],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => LogEntry.fromMap(map)).toList();
  }

  Future<List<LogEntry>> getEntriesWithHashtag(String hashtag) async {
    final db = await _databaseHelper.database;
    // Remove # if it's included in the hashtag parameter
    final cleanHashtag = hashtag.startsWith('#') ? hashtag : '#$hashtag';
    
    final maps = await db.query(
      'log_entries',
      where: 'content LIKE ?',
      whereArgs: ['%$cleanHashtag%'],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => LogEntry.fromMap(map)).toList();
  }

  Future<List<LogEntry>> getAllEntries() async {
    final db = await _databaseHelper.database;
    final maps = await db.query('log_entries', orderBy: 'timestamp DESC');
    return maps.map((map) => LogEntry.fromMap(map)).toList();
  }

  Future<int> update(LogEntry entry) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'log_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'log_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getUniqueHashtags() async {
    final db = await _databaseHelper.database;
    final maps = await db.query('log_entries', columns: ['content']);
    
    final hashtags = <String>{};
    final regex = RegExp(r'#\w+');
    
    for (final map in maps) {
      final content = map['content'] as String;
      final matches = regex.allMatches(content);
      for (final match in matches) {
        hashtags.add(match.group(0)!);
      }
    }
    
    return hashtags.toList()..sort();
  }
} 