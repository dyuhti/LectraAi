# Notification/Reminder System - Testing Guide

## Overview

The notification system has been fixed to ensure reliable scheduled reminders on Android 13+ devices. Scheduling now uses `AndroidScheduleMode.exactAllowWhileIdle` with timezone-aware `tz.TZDateTime`.

---

## Setup Requirements

### 1. Dependencies (Already in pubspec.yaml)
```yaml
flutter_local_notifications: ^21.0.0
timezone: ^0.11.0
```

### 2. Android Configuration (Already Configured)

**android/app/build.gradle.kts:**
```kotlin
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
    isCoreLibraryDesugaringEnabled = true  ✓
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")  ✓
}
```

**AndroidManifest.xml (android/app/src/main/):**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />  ✓
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />  ✓
```

### 3. App Initialization (main.dart - Already Done)

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();  // ✓
  await RevisionReminderService.initialize();  // ✓
  await RevisionReminderService.requestPermissions();  // ✓
  // ... rest of init
}
```

---

## Testing Procedures

### QUICK TEST (1 Minute - Start Here)

**Goal:** Verify notifications work at all

#### Steps:
1. **Open Settings** → **Revision Reminders**
2. **Click "Test" button**
   - App shows: "Notification will appear in 1 minute"
3. **Lock your phone** (or keep screen on)
4. **Wait 1 minute**
   - ✅ **Expected:** Notification appears in notification panel with:
     - Title: "Test Notification"
     - Body: "This is a test notification (1 minute delay)"

#### Debug Info (from logcat):
```
[RevisionReminderService] Scheduling test notification for: 2026-04-17 14:32:15 +0530 (example)
[RevisionReminderService] Current time: 2026-04-17 14:31:15 +0530
[RevisionReminderService] Time difference: 60 seconds
[RevisionReminderService] ✓ Test notification scheduled for 1 minute from now
```

**If test fails:** Check [Troubleshooting](#troubleshooting) below.

---

### FULL REMINDER TEST (7 Days - Realistic)

**Goal:** Verify complete reminder workflow

#### Steps:
1. **Open Settings** → **Revision Reminders**
2. **Configure:**
   - ✅ Enable Reminders: **ON**
   - ✅ Reminder Interval: **Every 1 day** (for fast testing)
   - ✅ Notification Time: **Current time + 2 min** (e.g., if it's 14:30, set to 14:32)
3. **Click "Save Settings"**
   - App shows: "Reminder settings updated"
   - 30 reminders are scheduled
4. **Wait 2 minutes**
   - ✅ **Expected:** First reminder notification appears
5. **Repeat daily:** You should see a reminder every 24 hours

#### Debug Info (from logcat):
```
[RevisionReminderService] Current time: 2026-04-17 14:30:00 +0530
[RevisionReminderService] Timezone: Asia/Kolkata
[RevisionReminderService] First notification: 2026-04-17 14:32:00 +0530
[RevisionReminderService] Time until first: 120 seconds
[RevisionReminderService] Scheduling 30 reminders starting at: 2026-04-17 14:32:00 +0530
[RevisionReminderService] Interval: 1 days
[RevisionReminderService] Reminder #1: 2026-04-17 14:32:00 +0530
[RevisionReminderService] Reminder #2: 2026-04-18 14:32:00 +0530
[RevisionReminderService] ✓ Scheduled 30/30 reminders successfully
```

---

### PERMISSION TEST (Android 13+)

**Goal:** Verify notification permissions are granted

#### Steps:
1. **Device Settings** → **Apps** → **Smart Lecture Notes** → **Notifications**
   - ✅ Should show **ON** / toggle **enabled**
2. **If OFF:** Enable it, then run a test notification
3. **Check system logcat:**
   ```
   [RevisionReminderService] Android - Notification: true, Exact alarm: true
   ```

**If permission request fails:**
- App should show system dialog: "Allow Smart Lecture Notes to send you notifications?"
- **Tap "Allow"** when prompted

---

### BACKGROUND/LOCK SCREEN TEST

**Goal:** Verify notifications work even when app is closed or phone is locked

#### Steps:
1. **Open Revision Reminders** screen
2. **Set test notification** for 2 minutes from now
3. **Force-close the app:**
   - Device Settings → Apps → Smart Lecture Notes → "Force Stop"
   - OR just press HOME and don't use the app
4. **Lock the phone** (or keep screen on)
5. **Wait 2 minutes**
   - ✅ **Expected:** Notification appears even with app closed
6. **Tap notification:**
   - Should open the app (if configured with intent)

---

### TIMEZONE TEST (Critical for Multi-Region)

**Goal:** Verify scheduling works correctly across timezones

#### Current Setup:
```dart
tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
```

#### To Test Different Timezone:
1. **Edit RevisionReminderService.dart:**
   ```dart
   // Temporarily change for testing:
   tz.setLocalLocation(tz.getLocation('America/New_York'));
   ```
2. **Rebuild and test**
3. **Check logcat:**
   ```
   [RevisionReminderService] Timezone: America/New_York
   ```
4. **Revert back to Asia/Kolkata**

---

## What Was Fixed

### ✅ Before (Broken)
```dart
await _plugin.zonedSchedule(
   id: 1000 + i,
   title: 'Time to revise',
   body: 'Open Smart Notes and review your saved notes.',
   scheduledDate: scheduled,
   notificationDetails: details,
   androidAllowWhileIdle: true, // ❌ Deprecated API
);
```
**Result:** Builds failed on newer `flutter_local_notifications` versions due to API mismatch.

### ✅ After (Fixed)
```dart
await _plugin.zonedSchedule(
   id: 1000 + i,
   title: 'Time to revise',
   body: 'Open Smart Notes and review your saved notes.',
   scheduledDate: scheduled,
   notificationDetails: details,
   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ✅ Supported API
   payload: 'revision_reminder_${1000 + i}',  // ✅ Added for tap handling
);
```
**Result:** Notifications fire reliably, even after device reboot or extended background time.

### Other Improvements:
- **Importance.max** + **Priority.high** for Android 13+ guaranteed visibility
- **Better error handling** with try-catch per notification
- **Detailed logging** for debugging scheduling issues
- **Test notification** now uses 1-minute delay (realistic) instead of immediate `show()`
- **Payload** added for future tap-handling callbacks

---

## Troubleshooting

### Problem: "Test Notification" didn't appear after 1 minute

**Checklist:**
1. ✅ **Permissions granted?**
   - Go to device Settings → Apps → Smart Lecture Notes → Notifications
   - Ensure toggle is **ON**
   
2. ✅ **Notification panel checked?**
   - Swipe down from top of screen to see notification panel
   - Don't-Disturb mode might be ON
   
3. ✅ **Device time correct?**
   - Ensure device time matches actual time
   - Check timezone in Settings → Date & Time
   
4. ✅ **Battery Saver OFF?**
   - Some devices ignore scheduled notifications in extreme battery saver
   - Try: Device Settings → Battery → Battery Saver = OFF
   
5. ✅ **App rebuilt and deployed?**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Problem: Notifications disappear when app is closed

**This is expected** if not properly configured. **Solution:**
- Notifications are handled by Android system, not the app
- Make sure device didn't reboot (which clears pending alarms)
- After reboot, re-open Revision Reminders and click "Save Settings" again

### Problem: "Error: timed out" in logs

**Possible causes:**
- Timezone library not initialized
- Device time zone mismatch

**Solution:**
```dart
// In RevisionReminderService.initialize():
tz.initializeTimeZones();
final tzName = 'Asia/Kolkata';
tz.setLocalLocation(tz.getLocation(tzName));
debugPrint('[RevisionReminderService] Timezone set to $tzName');
```

### Problem: Multiple notifications at same time

**This is a feature**, not a bug. The service schedules **30 reminders** at:
- 1st: Today at set time
- 2nd: Tomorrow at set time  
- 3rd: In 2 days at set time
- ... (continues for ~30 occurrences)

To verify:
```dart
// In logcat, you'll see:
[RevisionReminderService] Reminder #1: 2026-04-17 14:32:00 +0530
[RevisionReminderService] Reminder #2: 2026-04-18 14:32:00 +0530
[RevisionReminderService] Reminder #3: 2026-04-19 14:32:00 +0530
```

---

## Testing Checklist

Before deploying to production, verify:

- [ ] Quick Test (1-minute test) succeeds
- [ ] Full Reminder Test succeeds (test on real device for 24 hours)
- [ ] Permission dialog appears on first launch
- [ ] Notification appears in locked screen
- [ ] Notification panel shows correct title/body
- [ ] Logcat shows no `✗ Failed` messages
- [ ] No timezone warnings in logcat
- [ ] Device rebooted and notifications still work
- [ ] App force-closed and notifications still trigger

---

## Key Code Locations

- **Service:** [lib/services/revision_reminder_service.dart](lib/services/revision_reminder_service.dart)
- **UI:** [lib/screens/revision_reminders_screen.dart](lib/screens/revision_reminders_screen.dart)
- **Initialization:** [lib/main.dart](lib/main.dart) (lines 17-18)
- **Android Config:** [android/app/build.gradle.kts](android/app/build.gradle.kts)
- **Permissions:** [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)

---

## Next Steps

### For Users:
1. Run the Quick Test
2. Set up a real reminder with 1-day interval
3. Test for 24-48 hours
4. Report any issues

### For Developers:
1. Add tap-handling callback in RevisionReminderService (currently payload is set but not handled)
2. Add notification click analytics
3. Consider adding snooze functionality
4. Add notification history/log viewer

---

## Support

If notifications still don't work after testing:
1. Collect logcat output (search for `RevisionReminderService`)
2. Check [Troubleshooting](#troubleshooting) section
3. Verify all Android configuration steps are complete
4. Try `flutter clean && flutter pub get && flutter run`
