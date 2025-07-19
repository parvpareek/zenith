import 'package:sqflite/sqflite.dart';
import '../models/chat_message.dart';
import 'database_helper.dart';

class ChatMessageDAO {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<int> insert(ChatMessage message) async {
    final db = await _databaseHelper.database;
    return await db.insert('chat_messages', message.toMap());
  }

  Future<ChatMessage?> getById(int id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'chat_messages',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ChatMessage.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ChatMessage>> getAllMessages() async {
    final db = await _databaseHelper.database;
    final maps = await db.query('chat_messages', orderBy: 'timestamp ASC');
    return maps.map((map) => ChatMessage.fromMap(map)).toList();
  }

  Future<List<ChatMessage>> getRecentMessages(int limit) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'chat_messages',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    // Reverse to get chronological order (oldest first)
    return maps.reversed.map((map) => ChatMessage.fromMap(map)).toList();
  }

  Future<List<ChatMessage>> getMessagesByDate(DateTime date) async {
    final db = await _databaseHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'chat_messages',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => ChatMessage.fromMap(map)).toList();
  }

  Future<List<ChatMessage>> getMessagesInDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'chat_messages',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => ChatMessage.fromMap(map)).toList();
  }

  Future<int> update(ChatMessage message) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'chat_messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'chat_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllMessages() async {
    final db = await _databaseHelper.database;
    return await db.delete('chat_messages');
  }

  Future<int> deleteMessagesOlderThan(DateTime date) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'chat_messages',
      where: 'timestamp < ?',
      whereArgs: [date.millisecondsSinceEpoch],
    );
  }

  Future<int> getMessageCount() async {
    final db = await _databaseHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM chat_messages'),
    );
    return count ?? 0;
  }
} 