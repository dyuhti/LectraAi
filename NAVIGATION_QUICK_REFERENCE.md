# Navigation - Quick Reference Card

## 🚀 TL;DR - Just Show Me The Code

### 1️⃣ Import These in Every Screen
```dart
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/widgets/custom_app_bar.dart';
```

### 2️⃣ Use This AppBar
```dart
appBar: CustomAppBar(
  title: 'Screen Title',
)
```
✨ Back button automatically included!

### 3️⃣ Navigate Like This
```dart
ElevatedButton(
  onPressed: () {
    Navigator.of(context).pushNamed(AppRoutes.home);
  },
  child: const Text('Go to Next Screen'),
)
```

### 4️⃣ Go Back Like This
```dart
ElevatedButton(
  onPressed: () => Navigator.of(context).pop(),
  child: const Text('Go Back'),
)
```

### 5️⃣ Auth Flow Like This
```dart
Navigator.of(context).pushNamedAndRemoveUntil(
  AppRoutes.home,
  (route) => false,
);
```

---

## 🎯 All 16 Routes (Copy-Paste Ready)

```dart
// Authentication
AppRoutes.splash          // SplashScreen
AppRoutes.login           // LoginScreen  
AppRoutes.register        // SignupScreen

// Main
AppRoutes.home            // HomeScreen

// Capture
AppRoutes.captureNotes    // CaptureCreateNotesScreen
AppRoutes.smartCamera     // CameraCaptureScreen
AppRoutes.recordAudio     // RecordLectureScreen
AppRoutes.previewDocument // PreviewDocumentScreen

// Notes
AppRoutes.viewNotes       // MyNotesScreen
AppRoutes.noteDetail      // NoteDetailScreen

// Quiz
AppRoutes.generateQuiz    // PracticeQuizScreen
AppRoutes.practiceQuiz    // PracticeQuizScreen
AppRoutes.quizResults     // QuizResultsScreen

// Learning
AppRoutes.revisionReminder    // RevisionRemindersScreen
AppRoutes.studyAnalytics      // StudyDashboardScreen

// Settings
AppRoutes.settings        // SettingsScreen
```

---

## ❌ Don't Use Anymore

```dart
// ❌ OLD (GetX)
import 'package:get/get.dart';
Get.to(() => const HomeScreen());
Get.off(() => const LoginScreen());
Get.back();

// ✅ NEW (Navigator)
import 'package:smart_lecture_notes/routes/app_routes.dart';
Navigator.of(context).pushNamed(AppRoutes.home);
Navigator.of(context).pushReplacementNamed(AppRoutes.login);
Navigator.of(context).pop();
```

---

## 🔄 5-Minute Screen Update

### Before
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Screen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ElevatedButton(
        onPressed: () => Get.to(() => const OtherScreen()),
        child: const Text('Go'),
      ),
    );
  }
}
```

### After
```dart
import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/widgets/custom_app_bar.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'My Screen'),
      body: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.otherScreen);
        },
        child: const Text('Go'),
      ),
    );
  }
}
```

---

## 🎯 Common Patterns

### Navigate & Clear Stack (Logout)
```dart
Navigator.of(context).pushNamedAndRemoveUntil(
  AppRoutes.login,
  (route) => false,
);
```

### Navigate with Data
```dart
// Send
Navigator.of(context).pushNamed(
  AppRoutes.noteDetail,
  arguments: {'noteTitle': 'My Title'},
);

// Receive in RouteGenerator
case AppRoutes.noteDetail:
  final title = (args is Map) ? args['noteTitle'] : null;
  return _buildRoute(NoteDetailScreen(noteTitle: title));
```

### Show Snackbar
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Success!')),
);
```

---

## 📊 Screens Checklist

Track your progress:

- [ ] SplashScreen ✅ (already done)
- [ ] LoginScreen
- [ ] SignupScreen
- [ ] HomeScreen
- [ ] CaptureCreateNotesScreen
- [ ] CameraCaptureScreen
- [ ] RecordLectureScreen
- [ ] PreviewDocumentScreen
- [ ] MyNotesScreen
- [ ] NoteDetailScreen
- [ ] PracticeQuizScreen
- [ ] QuizResultsScreen
- [ ] RevisionRemindersScreen
- [ ] StudyDashboardScreen
- [ ] SettingsScreen

(Total: 14 screens remaining, 1 done ✅)

---

## 🐛 If Something Breaks

### Error: "No route defined for..."
**Fix:** Add to RouteGenerator.generateRoute()
```dart
case AppRoutes.myScreen:
  return _buildRoute(const MyScreen());
```

### Error: "Navigator.of() - not found"
**Fix:** Make sure you're calling from a widget (not top-level)

### Error: "iconThemeData not found" in AppBar
**Fix:** Use CustomAppBar instead
```dart
appBar: CustomAppBar(title: 'Title'), // ✅ Not AppBar
```

### Back button not showing
**Fix:** Make sure you're using CustomAppBar
```dart
appBar: CustomAppBar(title: 'Title'), // ✅ Custom

appBar: AppBar(title: const Text('Title')), // ❌ Default
```

---

## 📚 Full Guides

Read these when you have more time:
- `NAVIGATION_ARCHITECTURE.md` - Full system explanation
- `NAVIGATION_IMPLEMENTATION_GUIDE.md` - Step-by-step how-to
- `NAVIGATION_SETUP_COMPLETE.md` - Verification & next steps
- `NAVIGATION_FINAL_STATUS.md` - Complete status report

---

## ⚡ Commands

```bash
# Check for errors
flutter analyze

# Build APK
flutter build apk --release

# Run on device/emulator
flutter run

# Get dependencies
flutter pub get

# Update packages
flutter pub upgrade
```

---

## ✨ You're All Set!

1. ✅ Copy one of the navigation patterns above
2. ✅ Apply to each screen
3. ✅ Run `flutter analyze` to verify
4. ✅ Test by clicking buttons
5. ✅ Repeat for all 14 screens
6. ✅ Deploy! 🚀

---

**Save this file for quick reference!**

Generated: April 14, 2026
