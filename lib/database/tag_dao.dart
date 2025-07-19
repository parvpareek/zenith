import 'package:sqflite/sqflite.dart';
import '../models/tag.dart';
import 'database_helper.dart';

class TagDAO {
  static const String tableName = 'tags';
  static const String sessionTagsTable = 'session_tags';

  Future<Database> get database async {
    return await DatabaseHelper().database;
  }

  // Create a new tag
  Future<int> insert(Tag tag) async {
    final db = await database;
    return await db.insert(tableName, tag.toMap());
  }

  // Get all tags
  Future<List<Tag>> getAllTags() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'parent_id, name',
    );
    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  // Get hierarchical tags (root categories with their children)
  Future<List<Tag>> getHierarchicalTags() async {
    final db = await database;
    
    // Get all root categories (parent_id is null)
    final List<Map<String, dynamic>> rootMaps = await db.query(
      tableName,
      where: 'parent_id IS NULL',
      orderBy: 'name',
    );
    
    List<Tag> hierarchicalTags = [];
    
    for (final rootMap in rootMaps) {
      // Get children for this root category
      final List<Map<String, dynamic>> childMaps = await db.query(
        tableName,
        where: 'parent_id = ?',
        whereArgs: [rootMap['id']],
        orderBy: 'name',
      );
      
      final children = childMaps.map((map) => Tag.fromMap(map)).toList();
      final rootTag = Tag.fromMap(rootMap).copyWith(children: children);
      hierarchicalTags.add(rootTag);
    }
    
    return hierarchicalTags;
  }

  // Get root categories only
  Future<List<Tag>> getRootCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'parent_id IS NULL',
      orderBy: 'name',
    );
    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  // Get children of a specific tag
  Future<List<Tag>> getChildrenOfTag(int parentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'name',
    );
    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  // Search tags by name
  Future<List<Tag>> searchTags(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name',
    );
    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  // Update a tag
  Future<int> update(Tag tag) async {
    final db = await database;
    return await db.update(
      tableName,
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  // Delete a tag (and all its children)
  Future<int> delete(int id) async {
    final db = await database;
    
    // First delete all children
    await db.delete(
      tableName,
      where: 'parent_id = ?',
      whereArgs: [id],
    );
    
    // Then delete the tag itself
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get tag by ID
  Future<Tag?> getTagById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Tag.fromMap(maps.first);
    }
    return null;
  }

  // Session-Tag relationship methods
  
  // Add tags to a session
  Future<void> addTagsToSession(int sessionId, List<int> tagIds) async {
    final db = await database;
    final batch = db.batch();
    
    for (final tagId in tagIds) {
      batch.insert(sessionTagsTable, {
        'session_id': sessionId,
        'tag_id': tagId,
      });
    }
    
    await batch.commit();
  }

  // Remove all tags from a session
  Future<void> removeTagsFromSession(int sessionId) async {
    final db = await database;
    await db.delete(
      sessionTagsTable,
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // Get tags for a specific session
  Future<List<Tag>> getTagsForSession(int sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.* FROM $tableName t
      INNER JOIN $sessionTagsTable st ON t.id = st.tag_id
      WHERE st.session_id = ?
      ORDER BY t.name
    ''', [sessionId]);
    
    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  // Get sessions with a specific tag
  Future<List<int>> getSessionsWithTag(int tagId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      sessionTagsTable,
      columns: ['session_id'],
      where: 'tag_id = ?',
      whereArgs: [tagId],
    );
    
    return maps.map((map) => map['session_id'] as int).toList();
  }

  // Analytics methods
  
  // Get tag analytics for a specific date range
  Future<List<TagAnalytics>> getTagAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    
    String dateWhere = '';
    List<dynamic> dateArgs = [];
    
    if (startDate != null && endDate != null) {
      dateWhere = 'AND fs.timestamp BETWEEN ? AND ?';
      dateArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.id,
        t.name,
        t.parent_id,
        t.color,
        t.created_at,
        COUNT(fs.id) as total_sessions,
        COALESCE(SUM(fs.durationMinutes), 0) as total_minutes,
        COALESCE(SUM(fs.actualDurationMinutes), 0) as total_actual_minutes,
        COALESCE(AVG(fs.postFocusEnergy), 0) as average_energy,
        SUM(CASE WHEN fs.phase = 'completed' THEN 1 ELSE 0 END) as completed_sessions,
        SUM(CASE WHEN fs.phase = 'abandoned' THEN 1 ELSE 0 END) as abandoned_sessions
      FROM $tableName t
      LEFT JOIN $sessionTagsTable st ON t.id = st.tag_id
      LEFT JOIN focus_sessions fs ON st.session_id = fs.id
      WHERE 1=1 $dateWhere
      GROUP BY t.id, t.name, t.parent_id, t.color, t.created_at
      HAVING total_sessions > 0
      ORDER BY total_minutes DESC
    ''', dateArgs);
    
    List<TagAnalytics> analytics = [];
    
    for (final map in maps) {
      final tag = Tag.fromMap({
        'id': map['id'],
        'name': map['name'],
        'parent_id': map['parent_id'],
        'color': map['color'],
        'created_at': map['created_at'],
      });
      
      // Get common distractions for this tag
      final distractions = await getCommonDistractionsForTag(map['id']);
      
      analytics.add(TagAnalytics(
        tag: tag,
        totalSessions: map['total_sessions'] ?? 0,
        totalMinutes: map['total_minutes'] ?? 0,
        totalActualMinutes: map['total_actual_minutes'] ?? 0,
        averageEnergy: (map['average_energy'] ?? 0).toDouble(),
        completedSessions: map['completed_sessions'] ?? 0,
        abandonedSessions: map['abandoned_sessions'] ?? 0,
        commonDistractions: distractions,
      ));
    }
    
    return analytics;
  }

  // Get common distractions for a tag
  Future<List<String>> getCommonDistractionsForTag(int tagId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT fs.distractions
      FROM focus_sessions fs
      INNER JOIN $sessionTagsTable st ON fs.id = st.session_id
      WHERE st.tag_id = ? AND fs.distractions IS NOT NULL AND fs.distractions != ''
      ORDER BY fs.timestamp DESC
      LIMIT 50
    ''', [tagId]);
    
    List<String> allDistractions = [];
    for (final map in maps) {
      final distractionsJson = map['distractions'] as String?;
      if (distractionsJson != null && distractionsJson.isNotEmpty) {
        // Parse JSON array of distractions
        try {
          final List<dynamic> parsed = distractionsJson.split(',');
          allDistractions.addAll(parsed.map((e) => e.toString().trim()));
        } catch (e) {
          // If parsing fails, add as single distraction
          allDistractions.add(distractionsJson);
        }
      }
    }
    
    // Count occurrences and return top 5
    final Map<String, int> distractionCounts = {};
    for (final distraction in allDistractions) {
      distractionCounts[distraction] = (distractionCounts[distraction] ?? 0) + 1;
    }
    
    final sorted = distractionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(5).map((e) => e.key).toList();
  }

  // Initialize default tags
  Future<void> initializeDefaultTags() async {
    final existingTags = await getAllTags();
    if (existingTags.isNotEmpty) return; // Already initialized
    
    final db = await database;
    final batch = db.batch();
    
    for (final categoryData in CommonTags.defaultTags) {
      // Insert parent category
      final parentId = await db.insert(tableName, {
        'name': categoryData['name'],
        'parent_id': null,
        'color': categoryData['color'],
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Insert children
      final children = categoryData['children'] as List<Map<String, dynamic>>;
      for (final childData in children) {
        batch.insert(tableName, {
          'name': childData['name'],
          'parent_id': parentId,
          'color': childData['color'],
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
    
    await batch.commit();
  }

  // Get most used tags (for quick access)
  Future<List<Tag>> getMostUsedTags({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.*, COUNT(st.tag_id) as usage_count
      FROM $tableName t
      INNER JOIN $sessionTagsTable st ON t.id = st.tag_id
      GROUP BY t.id, t.name, t.parent_id, t.color, t.created_at
      ORDER BY usage_count DESC
      LIMIT ?
    ''', [limit]);
    
    return maps.map((map) => Tag.fromMap({
      'id': map['id'],
      'name': map['name'],
      'parent_id': map['parent_id'],
      'color': map['color'],
      'created_at': map['created_at'],
    })).toList();
  }
} 