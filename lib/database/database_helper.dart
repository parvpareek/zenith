import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'zenith.db');
    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        date INTEGER NOT NULL,
        hours REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // Focus sessions table
    await db.execute('''
      CREATE TABLE focus_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal TEXT NOT NULL,
        detailedPlan TEXT,
        summary TEXT,
        learningSummary TEXT,
        timestamp INTEGER NOT NULL,
        durationMinutes INTEGER NOT NULL DEFAULT 25,
        mode INTEGER NOT NULL DEFAULT 0,
        phase INTEGER NOT NULL DEFAULT 0,
        preFocusEnergy REAL,
        postFocusEnergy REAL,
        distractions TEXT,
        exitReason TEXT,
        actualDurationMinutes INTEGER,
        keyLearnings TEXT
      )
    ''');

    // Log entries table
    await db.execute('''
      CREATE TABLE log_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'daily_log',
        timestamp INTEGER NOT NULL
      )
    ''');

    // Chat messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        sender TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Tags table
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER,
        color TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    // Session tags junction table
    await db.execute('''
      CREATE TABLE session_tags (
        session_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (session_id, tag_id),
        FOREIGN KEY (session_id) REFERENCES focus_sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_tasks_date ON tasks(date)');
    await db.execute('CREATE INDEX idx_focus_sessions_timestamp ON focus_sessions(timestamp)');
    await db.execute('CREATE INDEX idx_log_entries_timestamp ON log_entries(timestamp)');
    await db.execute('CREATE INDEX idx_log_entries_category ON log_entries(category)');
    await db.execute('CREATE INDEX idx_chat_messages_timestamp ON chat_messages(timestamp)');
    await db.execute('CREATE INDEX idx_tags_parent_id ON tags(parent_id)');
    await db.execute('CREATE INDEX idx_tags_name ON tags(name)');
    await db.execute('CREATE INDEX idx_session_tags_session_id ON session_tags(session_id)');
    await db.execute('CREATE INDEX idx_session_tags_tag_id ON session_tags(tag_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add title and category columns to log_entries table
      await db.execute('ALTER TABLE log_entries ADD COLUMN title TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE log_entries ADD COLUMN category TEXT NOT NULL DEFAULT "daily_log"');
      await db.execute('CREATE INDEX idx_log_entries_category ON log_entries(category)');
    }
    
    if (oldVersion < 3) {
      // Add hours column to tasks table
      await db.execute('ALTER TABLE tasks ADD COLUMN hours REAL NOT NULL DEFAULT 0.0');
    }
    
    if (oldVersion < 4) {
      // Add enhanced focus session columns
      await db.execute('ALTER TABLE focus_sessions ADD COLUMN detailedPlan TEXT');
      await db.execute('ALTER TABLE focus_sessions ADD COLUMN mode INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE focus_sessions ADD COLUMN phase INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE focus_sessions ADD COLUMN preFocusEnergy REAL');
      await db.execute('ALTER TABLE focus_sessions ADD COLUMN postFocusEnergy REAL');
      await db.execute('ALTER TABLE focus_sessions ADD COLUMN distractions TEXT');
      await db.execute('ALTER TABLE focus_sessions ADD COLUMN exitReason TEXT');
      await db.execute('ALTER TABLE focus_sessions ADD COLUMN actualDurationMinutes INTEGER');
      await db.execute('ALTER TABLE focus_sessions ADD COLUMN keyLearnings TEXT');
    }
    
    if (oldVersion < 5) {
      // Add tags table
      await db.execute('''
        CREATE TABLE tags (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          parent_id INTEGER,
          color TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (parent_id) REFERENCES tags (id) ON DELETE CASCADE
        )
      ''');
      
      // Add session tags junction table
      await db.execute('''
        CREATE TABLE session_tags (
          session_id INTEGER NOT NULL,
          tag_id INTEGER NOT NULL,
          PRIMARY KEY (session_id, tag_id),
          FOREIGN KEY (session_id) REFERENCES focus_sessions (id) ON DELETE CASCADE,
          FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
        )
      ''');
      
      // Add indexes for tags tables
      await db.execute('CREATE INDEX idx_tags_parent_id ON tags(parent_id)');
      await db.execute('CREATE INDEX idx_tags_name ON tags(name)');
      await db.execute('CREATE INDEX idx_session_tags_session_id ON session_tags(session_id)');
      await db.execute('CREATE INDEX idx_session_tags_tag_id ON session_tags(tag_id)');
    }
    
    if (oldVersion < 6) {
      // Add learningSummary column to focus_sessions table
      await db.execute('ALTER TABLE focus_sessions ADD COLUMN learningSummary TEXT');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
  
  // Clear all data except tags
  Future<void> clearAllDataExceptTags() async {
    final db = await database;
    
    // Clear all tables except tags
    await db.delete('tasks');
    await db.delete('focus_sessions');
    await db.delete('log_entries');
    await db.delete('chat_messages');
    await db.delete('session_tags'); // Clear session-tag relationships
    
    print('All data cleared except tags');
  }
} 