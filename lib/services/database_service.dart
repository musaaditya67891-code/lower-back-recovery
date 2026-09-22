import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/recovery_models.dart';

class DatabaseService {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'lower_back_recovery.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date_key TEXT NOT NULL,
            session_type TEXT NOT NULL,
            scheduled_time TEXT,
            started_at TEXT,
            completed_at TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            pain_before INTEGER,
            pain_after INTEGER,
            leg_symptom TEXT,
            breathing_completed INTEGER NOT NULL DEFAULT 0,
            breathing_duration INTEGER NOT NULL DEFAULT 0,
            extension_completed INTEGER NOT NULL DEFAULT 0,
            extension_level TEXT,
            extension_reps INTEGER NOT NULL DEFAULT 0,
            leg_lift_completed INTEGER NOT NULL DEFAULT 0,
            left_reps INTEGER NOT NULL DEFAULT 0,
            right_reps INTEGER NOT NULL DEFAULT 0,
            UNIQUE(date_key, session_type)
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> ensureSession({
    required String dateKey,
    required SessionType type,
    required String scheduledTime,
    required String status,
  }) async {
    final db = await database;
    await db.insert(
      'sessions',
      {
        'date_key': dateKey,
        'session_type': type.key,
        'scheduled_time': scheduledTime,
        'status': status,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<SessionRecord?> getSession(String dateKey, SessionType type) async {
    final db = await database;
    final rows = await db.query(
      'sessions',
      where: 'date_key = ? AND session_type = ?',
      whereArgs: [dateKey, type.key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SessionRecord.fromMap(rows.first);
  }

  Future<void> updateSession(
    String dateKey,
    SessionType type,
    Map<String, Object?> values,
  ) async {
    final db = await database;
    await db.update(
      'sessions',
      values,
      where: 'date_key = ? AND session_type = ?',
      whereArgs: [dateKey, type.key],
    );
  }

  Future<List<SessionRecord>> recentSessions({int limit = 60}) async {
    final db = await database;
    final rows = await db.query(
      'sessions',
      orderBy: 'date_key DESC, session_type ASC',
      limit: limit,
    );
    return rows.map(SessionRecord.fromMap).toList();
  }

  Future<List<SessionRecord>> sessionsBetween(
    String startKey,
    String endKey,
  ) async {
    final db = await database;
    final rows = await db.query(
      'sessions',
      where: 'date_key >= ? AND date_key <= ?',
      whereArgs: [startKey, endKey],
      orderBy: 'date_key ASC, session_type ASC',
    );
    return rows.map(SessionRecord.fromMap).toList();
  }

  Future<Set<String>> completedSessionKeys(
    String startKey,
    String endKey,
  ) async {
    final db = await database;
    final rows = await db.query(
      'sessions',
      columns: ['date_key', 'session_type'],
      where: 'date_key >= ? AND date_key <= ? AND status = ?',
      whereArgs: [startKey, endKey, 'completed'],
    );
    return rows
        .map((e) => '${e['date_key']}|${e['session_type']}')
        .toSet();
  }
}
