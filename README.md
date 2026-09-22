# Lower Back Recovery

Personal Android recovery companion built with Flutter.

## MVP behavior

- Two independent daily sessions: Morning and Night.
- User can change both start times.
- Reminder repeats at the chosen interval until that session is completed or the day ends.
- Tapping the notification opens the matching recovery session.
- Phase 1 tutorials:
  - 90-90 Breathing — 5 minute timer.
  - Prone Extension — elbow / hand press-up, self-paced reps and symptom response.
  - Bracing Leg Lift — 20 reps per side.
- Local history with completed / missed sessions.
- Pain-before / pain-after tracking.
- Progress screen with adherence, averages, pain trend, and symptom response.
- Everything is stored locally; no login, cloud, or server is required.

## Why the Android project is generated in CI

The repo intentionally keeps only the Flutter source plus a small Android patch script. GitHub Actions creates a fresh Android scaffold with the current stable Flutter template, patches the required scheduled-notification configuration, then builds the release APK. This avoids committing stale Gradle/Android template files.

## Build APK with GitHub Actions

1. Put this project in a GitHub repository.
2. Push to `main`, or run **Actions → Build Android APK → Run workflow**.
3. Open the completed workflow run.
4. Download the artifact named `lower-back-recovery-apk`.
5. Extract the ZIP; `app-release.apk` is inside.

## Local build

Requires Flutter + Android SDK.

```bash
flutter create --platforms=android --org com.musaaditya --project-name lower_back_recovery .
python3 tool/prepare_android.py
flutter pub get
flutter build apk --release
```

On Windows, run the patch script with `py tool/prepare_android.py`.

## Reminder permissions

On recent Android versions, the app requests notification permission and exact-alarm permission. If exact alarms are unavailable, scheduling falls back to an inexact alarm so reminders still work, though Android may delay them slightly.

## Recovery content source

The Phase 1 exercise content in this MVP follows the supplied RehabFix transcript and links back to the source video timestamps for each movement. This application tracks the routine; it does not diagnose structural healing.
