enum SessionType { morning, night }

extension SessionTypeX on SessionType {
  String get key => this == SessionType.morning ? 'morning' : 'night';
  String get label => this == SessionType.morning ? 'Morning Recovery' : 'Night Recovery';
  String get shortLabel => this == SessionType.morning ? 'Pagi' : 'Malam';

  static SessionType fromKey(String value) =>
      value == 'night' ? SessionType.night : SessionType.morning;
}

class SessionRecord {
  final int? id;
  final String dateKey;
  final SessionType type;
  final String status;
  final String? scheduledTime;
  final String? startedAt;
  final String? completedAt;
  final int? painBefore;
  final int? painAfter;
  final String? legSymptom;
  final bool breathingCompleted;
  final int breathingDuration;
  final bool extensionCompleted;
  final String? extensionLevel;
  final int extensionReps;
  final bool legLiftCompleted;
  final int leftReps;
  final int rightReps;

  const SessionRecord({
    this.id,
    required this.dateKey,
    required this.type,
    required this.status,
    this.scheduledTime,
    this.startedAt,
    this.completedAt,
    this.painBefore,
    this.painAfter,
    this.legSymptom,
    this.breathingCompleted = false,
    this.breathingDuration = 0,
    this.extensionCompleted = false,
    this.extensionLevel,
    this.extensionReps = 0,
    this.legLiftCompleted = false,
    this.leftReps = 0,
    this.rightReps = 0,
  });

  bool get isCompleted => status == 'completed';
  bool get isMissed => status == 'missed';

  factory SessionRecord.fromMap(Map<String, Object?> map) {
    return SessionRecord(
      id: map['id'] as int?,
      dateKey: map['date_key'] as String,
      type: SessionTypeX.fromKey(map['session_type'] as String),
      status: map['status'] as String? ?? 'pending',
      scheduledTime: map['scheduled_time'] as String?,
      startedAt: map['started_at'] as String?,
      completedAt: map['completed_at'] as String?,
      painBefore: map['pain_before'] as int?,
      painAfter: map['pain_after'] as int?,
      legSymptom: map['leg_symptom'] as String?,
      breathingCompleted: (map['breathing_completed'] as int? ?? 0) == 1,
      breathingDuration: map['breathing_duration'] as int? ?? 0,
      extensionCompleted: (map['extension_completed'] as int? ?? 0) == 1,
      extensionLevel: map['extension_level'] as String?,
      extensionReps: map['extension_reps'] as int? ?? 0,
      legLiftCompleted: (map['leg_lift_completed'] as int? ?? 0) == 1,
      leftReps: map['left_reps'] as int? ?? 0,
      rightReps: map['right_reps'] as int? ?? 0,
    );
  }
}

class AppSettings {
  final int morningHour;
  final int morningMinute;
  final int nightHour;
  final int nightMinute;
  final int reminderIntervalMinutes;

  const AppSettings({
    this.morningHour = 8,
    this.morningMinute = 0,
    this.nightHour = 21,
    this.nightMinute = 0,
    this.reminderIntervalMinutes = 30,
  });

  String formatTime(SessionType type) {
    final hour = type == SessionType.morning ? morningHour : nightHour;
    final minute = type == SessionType.morning ? morningMinute : nightMinute;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  AppSettings copyWith({
    int? morningHour,
    int? morningMinute,
    int? nightHour,
    int? nightMinute,
    int? reminderIntervalMinutes,
  }) {
    return AppSettings(
      morningHour: morningHour ?? this.morningHour,
      morningMinute: morningMinute ?? this.morningMinute,
      nightHour: nightHour ?? this.nightHour,
      nightMinute: nightMinute ?? this.nightMinute,
      reminderIntervalMinutes:
          reminderIntervalMinutes ?? this.reminderIntervalMinutes,
    );
  }
}
