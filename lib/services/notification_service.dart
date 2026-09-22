import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/recovery_models.dart';
import 'database_service.dart';
import 'recovery_repository.dart';

class NotificationService {
  NotificationService(this.db);

  final DatabaseService db;
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  final ValueNotifier<SessionType?> tappedSession = ValueNotifier(null);

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'recovery_reminders',
      'Recovery reminders',
      channelDescription: 'Pengingat sesi lower-back recovery',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      icon: 'ic_stat_recovery',
    ),
  );

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

    const init = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_recovery'),
    );
    await plugin.initialize(
      settings: init,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == 'morning') tappedSession.value = SessionType.morning;
        if (payload == 'night') tappedSession.value = SessionType.night;
      },
    );

    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      final payload = launch?.notificationResponse?.payload;
      if (payload == 'morning') tappedSession.value = SessionType.morning;
      if (payload == 'night') tappedSession.value = SessionType.night;
    }
  }

  Future<void> requestPermissions() async {
    if (!Platform.isAndroid) return;
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  int _baseId(DateTime date, SessionType type) {
    final dayIndex = DateTime(date.year, date.month, date.day)
        .difference(DateTime(2020, 1, 1))
        .inDays;
    return dayIndex * 1000 + (type == SessionType.morning ? 0 : 200);
  }

  Future<void> cancelForDate(DateTime date, SessionType type) async {
    final base = _baseId(date, type);
    for (var i = 0; i < 100; i++) {
      await plugin.cancel(id: base + i);
    }
  }

  Future<void> scheduleRollingWindow(
    AppSettings settings, {
    int days = 14,
  }) async {
    await plugin.cancelAll();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(Duration(days: days - 1));
    final completed = await db.completedSessionKeys(
      RecoveryRepository.dateKey(start),
      RecoveryRepository.dateKey(end),
    );

    for (var day = 0; day < days; day++) {
      final date = start.add(Duration(days: day));
      final dateKey = RecoveryRepository.dateKey(date);
      for (final type in SessionType.values) {
        if (completed.contains('$dateKey|${type.key}')) continue;
        await _scheduleSession(date, type, settings);
      }
    }
  }

  Future<void> _scheduleSession(
    DateTime date,
    SessionType type,
    AppSettings settings,
  ) async {
    final hour = type == SessionType.morning
        ? settings.morningHour
        : settings.nightHour;
    final minute = type == SessionType.morning
        ? settings.morningMinute
        : settings.nightMinute;
    final interval = settings.reminderIntervalMinutes.clamp(15, 240).toInt();

    var when = tz.TZDateTime(tz.local, date.year, date.month, date.day, hour, minute);
    final endOfDay = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      23,
      59,
    );
    final now = tz.TZDateTime.now(tz.local);
    var slot = 0;

    while (!when.isAfter(endOfDay) && slot < 100) {
      if (when.isAfter(now)) {
        final id = _baseId(date, type) + slot;
        try {
          await plugin.zonedSchedule(
            id: id,
            title: '${type.label} belum selesai',
            body: 'Buka tutorial dan selesaikan sesi recovery hari ini.',
            scheduledDate: when,
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: type.key,
          );
        } catch (_) {
          await plugin.zonedSchedule(
            id: id,
            title: '${type.label} belum selesai',
            body: 'Buka tutorial dan selesaikan sesi recovery hari ini.',
            scheduledDate: when,
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: type.key,
          );
        }
      }
      when = when.add(Duration(minutes: interval));
      slot++;
    }
  }
}
