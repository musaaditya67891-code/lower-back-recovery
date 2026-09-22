import 'package:shared_preferences/shared_preferences.dart';

import '../models/recovery_models.dart';

class SettingsService {
  static const _morningHour = 'morning_hour';
  static const _morningMinute = 'morning_minute';
  static const _nightHour = 'night_hour';
  static const _nightMinute = 'night_minute';
  static const _interval = 'reminder_interval';
  static const _firstUseDate = 'first_use_date';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      morningHour: prefs.getInt(_morningHour) ?? 8,
      morningMinute: prefs.getInt(_morningMinute) ?? 0,
      nightHour: prefs.getInt(_nightHour) ?? 21,
      nightMinute: prefs.getInt(_nightMinute) ?? 0,
      reminderIntervalMinutes: prefs.getInt(_interval) ?? 30,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_morningHour, settings.morningHour),
      prefs.setInt(_morningMinute, settings.morningMinute),
      prefs.setInt(_nightHour, settings.nightHour),
      prefs.setInt(_nightMinute, settings.nightMinute),
      prefs.setInt(_interval, settings.reminderIntervalMinutes),
    ]);
  }

  Future<String> firstUseDate(String todayKey) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_firstUseDate);
    if (existing != null) return existing;
    await prefs.setString(_firstUseDate, todayKey);
    return todayKey;
  }
}
