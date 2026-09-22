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
    settings = await settingsService.load();
    await repository.reconcileHistory(settings);
    await notifications.initialize();
    await notifications.requestPermissions();
    await notifications.scheduleRollingWindow(settings);
    initialized = true;
    notifyListeners();
  }

  Future<void> requestNotificationPermissions() =>
      notifications.requestPermissions();

  Future<void> updateSettings(AppSettings value) async {
    settings = value;
    await settingsService.save(value);
    await repository.reconcileHistory(value);
    await notifications.scheduleRollingWindow(value);
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
    await notifications.cancelForDate(DateTime.now(), type);
    notifyListeners();
  }
}
