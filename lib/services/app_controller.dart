import 'package:flutter/foundation.dart';

import '../models/recovery_models.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'recovery_repository.dart';
import 'settings_service.dart';

class AppController extends ChangeNotifier {
  AppController()
      : database = DatabaseService(),
        settingsService = SettingsService(),
        settings = const AppSettings() {
    repository = RecoveryRepository(database, settingsService);
    notifications = NotificationService(database);
  }

  final DatabaseService database;
  final SettingsService settingsService;
  late final RecoveryRepository repository;
  late final NotificationService notifications;

  AppSettings settings;
  bool initialized = false;

  Future<void> initialize() async {
    try {
      settings = await settingsService.load();
      await repository.reconcileHistory(settings);
    } catch (e, st) {
      debugPrint('Core initialization failed: $e\n$st');
      initialized = true;
      notifyListeners();
      return;
    }

    try {
      await notifications.initialize();
      await notifications.requestPermissions();
      await notifications.scheduleRollingWindow(settings);
    } catch (e, st) {
      debugPrint('Notification initialization failed: $e\n$st');
    }

    initialized = true;
    notifyListeners();

    if (notifications.tappedSession.value != null) {
      notifications.tappedSession.notifyListeners();
    }
  }

  Future<void> requestNotificationPermissions() =>
      notifications.requestPermissions();

  Future<void> updateSettings(AppSettings value) async {
    settings = value;
    await settingsService.save(value);
    await repository.reconcileHistory(value);
    try {
      await notifications.scheduleRollingWindow(value);
    } catch (e) {
      debugPrint('Reschedule failed: $e');
    }
    notifyListeners();
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
    await repository.completeSession(
      type: type,
      painBefore: painBefore,
      painAfter: painAfter,
      legSymptom: legSymptom,
      breathingDuration: breathingDuration,
      extensionLevel: extensionLevel,
      extensionReps: extensionReps,
      leftReps: leftReps,
      rightReps: rightReps,
    );
    try {
      await notifications.cancelForDate(DateTime.now(), type);
    } catch (e) {
      debugPrint('Cancel reminder failed: $e');
    }
    notifyListeners();
  }
}
