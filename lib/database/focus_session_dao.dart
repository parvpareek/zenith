import 'package:sqflite/sqflite.dart';
import '../models/focus_session.dart';
import '../models/tag.dart';
import 'database_helper.dart';
import 'tag_dao.dart';

class FocusSessionDAO {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TagDAO _tagDAO = TagDAO();

  Future<int> insert(FocusSession session, {List<int>? tagIds}) async {
    final db = await _databaseHelper.database;
    
    // Insert the session
    final sessionId = await db.insert('focus_sessions', session.toMap());
    
    // Insert tags if provided
    if (tagIds != null && tagIds.isNotEmpty) {
      await _tagDAO.addTagsToSession(sessionId, tagIds);
    }
    
    return sessionId;
  }

  Future<FocusSession?> getById(int id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'focus_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      // Load tags for this session
      final tags = await _tagDAO.getTagsForSession(id);
      return FocusSession.fromMap(maps.first, tags: tags);
    }
    return null;
  }

  Future<List<FocusSession>> getSessionsByDate(DateTime date) async {
    final db = await _databaseHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'focus_sessions',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
    );

    return await _loadSessionsWithTags(maps);
  }

  // Helper method to load sessions with their tags
  Future<List<FocusSession>> _loadSessionsWithTags(List<Map<String, dynamic>> maps) async {
    List<FocusSession> sessions = [];
    
    for (final map in maps) {
      final sessionId = map['id'];
      final tags = await _tagDAO.getTagsForSession(sessionId);
      sessions.add(FocusSession.fromMap(map, tags: tags));
    }
    
    return sessions;
  }

  Future<List<FocusSession>> getTodaysSessions() async {
    return getSessionsByDate(DateTime.now());
  }

  Future<List<FocusSession>> getSessionsInDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'focus_sessions',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
    );

    return await _loadSessionsWithTags(maps);
  }

  Future<List<FocusSession>> getLastNDaysSessions(int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return getSessionsInDateRange(startDate, endDate);
  }

  Future<int> update(FocusSession session, {List<int>? tagIds}) async {
    final db = await _databaseHelper.database;
    
    // Update the session
    final result = await db.update(
      'focus_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
    
    // Update tags if provided
    if (tagIds != null && session.id != null) {
      await _tagDAO.removeTagsFromSession(session.id!);
      if (tagIds.isNotEmpty) {
        await _tagDAO.addTagsToSession(session.id!, tagIds);
      }
    }
    
    return result;
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'focus_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<FocusSession>> getAllSessions() async {
    final db = await _databaseHelper.database;
    final maps = await db.query('focus_sessions', orderBy: 'timestamp DESC');
    return await _loadSessionsWithTags(maps);
  }

  Future<int> getTotalFocusTimeToday() async {
    final sessions = await getTodaysSessions();
    return sessions.fold<int>(0, (total, session) => total + session.durationMinutes);
  }

  Future<int> getTotalFocusTimeInDays(int days) async {
    final sessions = await getLastNDaysSessions(days);
    return sessions.fold<int>(0, (total, session) => total + session.durationMinutes);
  }
} 