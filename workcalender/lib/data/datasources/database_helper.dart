import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tasks table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableTasks} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        date INTEGER NOT NULL,
        startTime INTEGER,
        endTime INTEGER,
        durationMinutes INTEGER DEFAULT 30,
        priority INTEGER DEFAULT 2,
        status TEXT DEFAULT 'pending',
        categoryId TEXT,
        notes TEXT,
        repeat TEXT DEFAULT 'none',
        createdAt INTEGER NOT NULL,
        completedAt INTEGER,
        isAllDay INTEGER DEFAULT 0,
        tags TEXT DEFAULT '',
        estimatedValue REAL DEFAULT 1.0
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCategories} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        icon TEXT DEFAULT 'grid',
        isDefault INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Analytics table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableAnalytics} (
        id TEXT PRIMARY KEY,
        date INTEGER NOT NULL UNIQUE,
        tasksCompleted INTEGER DEFAULT 0,
        tasksMissed INTEGER DEFAULT 0,
        tasksTotal INTEGER DEFAULT 0,
        productivityScore REAL DEFAULT 0.0,
        totalMinutesWorked INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Activity logs
    await db.execute('''
      CREATE TABLE ${AppConstants.tableLogs} (
        id TEXT PRIMARY KEY,
        taskId TEXT,
        action TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        metadata TEXT
      )
    ''');

    // Indexes
    await db.execute(
        'CREATE INDEX idx_tasks_date ON ${AppConstants.tableTasks}(date)');
    await db.execute(
        'CREATE INDEX idx_tasks_status ON ${AppConstants.tableTasks}(status)');
    await db.execute(
        'CREATE INDEX idx_analytics_date ON ${AppConstants.tableAnalytics}(date)');

    // Insert default categories
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final cat in AppConstants.defaultCategories) {
      await db.insert(AppConstants.tableCategories, {
        'id': cat['name'].toString().toLowerCase().replaceAll(' ', '_'),
        'name': cat['name'],
        'colorValue': cat['color'],
        'icon': cat['icon'],
        'isDefault': 1,
        'createdAt': now,
      });
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here
  }

  // ─── Tasks CRUD ─────────────────────────────────────────────────────────────

  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert(AppConstants.tableTasks, task,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.update(
      AppConstants.tableTasks,
      task,
      where: 'id = ?',
      whereArgs: [task['id']],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableTasks,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final db = await database;
    return await db.query(AppConstants.tableTasks, orderBy: 'date ASC, priority DESC');
  }

  Future<List<Map<String, dynamic>>> getTasksByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;
    return await db.query(
      AppConstants.tableTasks,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'priority DESC, startTime ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getTasksByStatus(String status) async {
    final db = await database;
    return await db.query(
      AppConstants.tableTasks,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'date ASC, priority DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getMissedTasks() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.rawQuery('''
      SELECT * FROM ${AppConstants.tableTasks}
      WHERE status IN ('pending', 'in_progress')
      AND (endTime < ? OR (endTime IS NULL AND date < ?))
      ORDER BY priority DESC
    ''', [now, DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch]);
  }

  Future<List<Map<String, dynamic>>> getTasksInRange(DateTime start, DateTime end) async {
    final db = await database;
    return await db.query(
      AppConstants.tableTasks,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date ASC, priority DESC',
    );
  }

  Future<Map<String, dynamic>?> getTaskById(String id) async {
    final db = await database;
    final results = await db.query(
      AppConstants.tableTasks,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  // ─── Categories CRUD ─────────────────────────────────────────────────────────

  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert(AppConstants.tableCategories, category,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query(AppConstants.tableCategories, orderBy: 'isDefault DESC, name ASC');
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableCategories,
      where: 'id = ? AND isDefault = 0',
      whereArgs: [id],
    );
  }

  // ─── Analytics CRUD ──────────────────────────────────────────────────────────

  Future<int> upsertAnalytics(Map<String, dynamic> analytics) async {
    final db = await database;
    return await db.insert(AppConstants.tableAnalytics, analytics,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAnalyticsInRange(DateTime start, DateTime end) async {
    final db = await database;
    return await db.query(
      AppConstants.tableAnalytics,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date ASC',
    );
  }

  Future<Map<String, dynamic>?> getAnalyticsForDate(DateTime date) async {
    final db = await database;
    final dayStart = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;
    final results = await db.query(
      AppConstants.tableAnalytics,
      where: 'date >= ? AND date <= ?',
      whereArgs: [dayStart, dayEnd],
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  // ─── Logs ─────────────────────────────────────────────────────────────────

  Future<int> insertLog(Map<String, dynamic> log) async {
    final db = await database;
    return await db.insert(AppConstants.tableLogs, log);
  }

  // ─── Stats ────────────────────────────────────────────────────────────────

  Future<Map<String, int>> getTaskStatsForDate(DateTime date) async {
    final tasks = await getTasksByDate(date);
    int completed = 0, pending = 0, missed = 0, total = tasks.length;
    for (final t in tasks) {
      switch (t['status']) {
        case AppConstants.statusCompleted: completed++; break;
        case AppConstants.statusMissed: missed++; break;
        default: pending++;
      }
    }
    return {
      'total': total, 'completed': completed,
      'pending': pending, 'missed': missed,
    };
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
