import '../models/recovery_models.dart';
import 'database_service.dart';
import 'settings_service.dart';

class RecoveryRepository {
  RecoveryRepository(this.db, this.settingsService);

  final DatabaseService db;
  final SettingsService settingsService;

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime parseDateKey(String key) {
    final p = key.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  Future<void> reconcileHistory(AppSettings settings) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstKey = await settingsService.firstUseDate(dateKey(today));
    var cursor = parseDateKey(firstKey);

    final earliest = today.subtract(const Duration(days: 3650));
    if (cursor.isBefore(earliest)) cursor = earliest;

    while (!cursor.isAfter(today)) {
      final key = dateKey(cursor);
      final isPast = cursor.isBefore(today);
      for (final type in SessionType.values) {
        await db.ensureSession(
          dateKey: key,
          type: type,
          scheduledTime: settings.formatTime(type),
          status: isPast ? 'missed' : 'pending',
        );
      }
      cursor = cursor.add(const Duration(days: 1));
    }
  }

  Future<SessionRecord> getToday(SessionType type) async {
    final key = dateKey(DateTime.now());
    final record = await db.getSession(key, type);
    if (record == null) {
      throw StateError('Today session was not initialized.');
    }
    return record;
  }

  Future<void> startSession(
    SessionType type, {
    required int painBefore,
  }) async {
    final key = dateKey(DateTime.now());
    await db.updateSession(key, type, {
      'started_at': DateTime.now().toIso8601String(),
      'pain_before': painBefore,
      'status': 'pending',
    });
  }

  Future<void> completeSession({
    required SessionType type,
    required int painBefore,
    required int painAfter,
    required String legSymptom,
    required int breathingDuration,
    required String extensionLevel,
    required int extensionReps,
    required int leftReps,
    required int rightReps,
  }) async {
    final key = dateKey(DateTime.now());
    await db.updateSession(key, type, {
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
      'pain_before': painBefore,
      'pain_after': painAfter,
      'leg_symptom': legSymptom,
      'breathing_completed': 1,
      'breathing_duration': breathingDuration,
      'extension_completed': 1,
      'extension_level': extensionLevel,
      'extension_reps': extensionReps,
      'leg_lift_completed': 1,
      'left_reps': leftReps,
      'right_reps': rightReps,
    });
  }
}
