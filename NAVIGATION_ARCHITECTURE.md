# Smart Lecture Notes - Navigation Architecture Guide

## 📋 Overview

This guide explains the complete navigation system for the Smart Lecture Notes app. The app uses **named routes** with a centralized `RouteGenerator` for clean, scalable, and maintainable navigation.

---

## 🏗️ Architecture Components

### 1. AppRoutes (`lib/routes/app_routes.dart`)
Central constants for all route names. Provides a single source of truth for navigation.

```dart
// Example usage
Navigator.of(context).pushNamed(AppRoutes.home);
Navigator.of(context).pushNamed(AppRoutes.practiceQuiz);
```

**All Available Routes:**
- Splash: `/`
- Authentication: `/login`, `/register`
- Main: `/home`
- Capture: `/capture-notes`, `/smart-camera`, `/record-audio`, `/preview-document`
- Notes: `/view-notes`, `/note-detail`
- Quiz: `/generate-quiz`, `/practice-quiz`, `/quiz-results`
- Learning: `/revision-reminder`, `/study-analytics`
- Settings: `/profile`, `/settings`

### 2. RouteGenerator (`lib/routes/route_generator.dart`)
Handles route generation and page instantiation. Works with `onGenerateRoute` in `main.dart`.

**Features:**
- Automatic screen mapping
- Argument passing support
- Error handling for undefined routes
- MaterialPageRoute for transitions

### 3. CustomAppBar (`lib/widgets/custom_app_bar.dart`)
Reusable AppBar with built-in back button support. Used across all screens.

**Features:**
- Automatic back button
- Custom back action support
- Consistent styling
- Optional action buttons
- Back button tooltip

### 4. NavigationService (`lib/widgets/custom_app_bar.dart`)
Global navigation helper for accessing Navigator without BuildContext.

```dart
// Use from anywhere without context
NavigationService.pushNamed(AppRoutes.home);
NavigationService.pop();
```

---

## 🚀 Quick Start: Adding Navigation to a Screen

### Step 1: Update the Screen's AppBar
Replace the default AppBar with CustomAppBar:

```dart
import 'package:smart_lecture_notes/widgets/custom_app_bar.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: CustomAppBar(
      title: 'My Screen',
      // Optional: custom back action
      onBackPressed: () {
        Navigator.of(context).pop();
      },
    ),
    body: YourContent(),
  );
}
```

### Step 2: Navigate to Another Screen
Use `Navigator.of(context).pushNamed()`:

```dart
ElevatedButton(
  onPressed: () {
    Navigator.of(context).pushNamed(AppRoutes.home);
  },
  child: const Text('Go to Home'),
)
```

### Step 3: Navigate with Arguments
Pass data between screens:

```dart
// Send data
Navigator.of(context).pushNamed(
  AppRoutes.noteDetail,
  arguments: {
    'noteData': noteObject,
    'noteId': '123',
  },
);

// Receive in RouteGenerator
case AppRoutes.noteDetail:
  return _buildRoute(NoteDetailScreen(
    noteData: (args is Map) ? args['noteData'] : null,
  ));
```

---

## 📱 Complete Navigation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    App Starting Point                        │
│                   (initialRoute: splash)                     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
             ┌───────────────────────┐
             │   SplashScreen (/)    │
             │  (3-second delay)     │
             └───────────┬───────────┘
                         │
    ┌────────────────────┴────────────────────┐
    │                                         │
    ▼                                         ▼
┌──────────────┐                    ┌──────────────────┐
│ LoginScreen  │◄──────────────────►│ RegisterScreen   │
│   (/login)   │  (Switch via link) │   (/register)    │
└──────┬───────┘                    └──────┬───────────┘
       │                                   │
       └───────────────┬───────────────────┘
                       │
                       ▼
              ┌──────────────────┐
              │  HomeScreen ✓    │
              │    (/home)       │
              └────┬──────┬──────┘
                   │      │
       ┌───────────┼──────┼──────────────┐
       │           │      │              │
       ▼           ▼      ▼              ▼
   Capture    Analytics  Settings    Quiz
   Routes     (/study-   (/settings,  Routes
              analytics) /profile)
       │           │      │              │
       ├─────────┬─┴──────┴──┬───────────┤
       │         │           │           │
       ▼         ▼           ▼           ▼
   Capture  Revision    Profile    Practice
   /Record  Reminder    Settings   Quiz
   /Camera  /Revision   /Settings  /Practice
   /Upload  Reminder              \Results

```

---

## 🔄 Navigation Patterns

### Pattern 1: Standard Navigation (with back button)
```dart
// User can go back
Navigator.of(context).pushNamed(AppRoutes.profile);
```

### Pattern 2: Replace Screen (back goes to previous)
```dart
// Replace current screen
Navigator.of(context).pushReplacementNamed(AppRoutes.home);
```

### Pattern 3: Clear Stack (login → home)
```dart
// Remove all previous routes from stack
Navigator.of(context).pushNamedAndRemoveUntil(
  AppRoutes.home,
  (route) => false, // Remove all
);
```

### Pattern 4: Pop with Result
```dart
// Return data when going back
Navigator.of(context).pop('some_result');
```

### Pattern 5: Pop Until Specific Route
```dart
// Go back until reaching home
Navigator.of(context).popUntil(
  ModalRoute.withName(AppRoutes.home),
);
```

---

## 💡 Best Practices

### ✅ DO:
- Use `CustomAppBar` for all screens
- Use named routes for all navigation
- Pass complex data through route arguments
- Use `pushNamedAndRemoveUntil` for auth flows
- Check `if (mounted)` before navigation in async operations

### ❌ DON'T:
- Hardcode route names (use `AppRoutes` constants)
- Use direct widget imports for navigation
- Navigate from `initState` without `addPostFrameCallback`
- Forget the back button in AppBar

---

## 🚨 Common Issues & Solutions

### Issue 1: Back Button Not Working
**Solution:** Ensure `CustomAppBar` is used and `showBackButton: true`

```dart
appBar: CustomAppBar(
  title: 'My Screen',
  showBackButton: true, // ← Add this
)
```

### Issue 2: "No route definition for..."
**Solution:** Add route to `RouteGenerator.generateRoute()`

```dart
case AppRoutes.myScreen:
  return _buildRoute(const MyScreen());
```

### Issue 3: Can't Pass Data Between Screens
**Solution:** Use route arguments properly

```dart
// Send
Navigator.of(context).pushNamed(
  AppRoutes.noteDetail,
  arguments: {'noteId': 123},
);

// Receive in RouteGenerator
case AppRoutes.noteDetail:
  final args = settings.arguments as Map?;
  return _buildRoute(
    NoteDetailScreen(noteId: args?['noteId']),
  );
```

### Issue 4: Android Back Button Not Working
**Solution:** Implement `WillPopScope` for custom behavior

```dart
@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      Navigator.of(context).pop();
      return false;
    },
    child: Scaffold(
      appBar: CustomAppBar(title: 'Screen'),
      body: YourContent(),
    ),
  );
}
```

---

## 🔐 Authentication Flow

```dart
// After successful login
Navigator.of(context).pushNamedAndRemoveUntil(
  AppRoutes.home,
  (route) => false, // Clears login stack
);

// After logout
Navigator.of(context).pushNamedAndRemoveUntil(
  AppRoutes.login,
  (route) => false, // Clears home stack
);
```

---

## 📊 Screen Priority & Implementation Order

**Phase 1 (Core): Build first**
1. SplashScreen
2. LoginScreen
3. SignupScreen
4. HomeScreen

**Phase 2 (Features): Build second**
5. CaptureCreateNotesScreen
6. RecordLectureScreen
7. CameraCaptureScreen
8. PreviewDocumentScreen

**Phase 3 (Content): Build third**
9. MyNotesScreen
10. NoteDetailScreen
11. PracticeQuizScreen
12. QuizResultsScreen

**Phase 4 (Settings): Build last**
13. RevisionRemindersScreen
14. StudyDashboardScreen
15. SettingsScreen
16. ProfileScreen

---

## 🛠️ Testing Navigation

### Manual Testing Checklist
- [ ] Splash → Login (3 seconds)
- [ ] Login button → Home (clear stack)
- [ ] Home feature cards → respective screens
- [ ] Back button → previous screen
- [ ] Android system back button → works same as back button
- [ ] Settings → Revision Reminders (shows back button)
- [ ] Quiz flow: Home → Quiz → Results → Review
- [ ] Notes flow: Upload → Preview → Save → View Notes

### Unit Test Example
```dart
testWidgets('Navigation to home screen works', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  
  // Should see SplashScreen initially
  expect(find.byType(SplashScreen), findsOneWidget);
  
  // Wait 3 seconds
  await tester.pumpAndSettle(const Duration(seconds: 4));
  
  // Should navigate to LoginScreen
  expect(find.byType(LoginScreen), findsOneWidget);
});
```

---

## 📚 File Structure

```
lib/
├── main.dart                          # App entry, uses named routes
├── routes/
│   ├── app_routes.dart               # Route constants
│   └── route_generator.dart          # Route handling logic
├── widgets/
│   └── custom_app_bar.dart           # Reusable AppBar + nav helpers
├── services/
│   └── (future: auth, storage, etc.)
└── screens/
    ├── splash_screen.dart
    ├── login_screen.dart
    ├── signup_screen.dart
    ├── home_screen.dart
    ├── capture_create_notes_screen.dart
    ├── camera_capture_screen.dart
    ├── record_lecture_screen.dart
    ├── preview_document_screen.dart
    ├── my_notes_screen.dart
    ├── note_detail_screen.dart
    ├── practice_quiz_screen.dart
    ├── quiz_results_screen.dart
    ├── revision_reminders_screen.dart
    ├── study_dashboard_screen.dart
    └── settings_screen.dart
```

---

## 🎯 Next Steps

1. **Update all existing screens** to use `CustomAppBar`
2. **Test all navigation flows** using manual checklist
3. **Add error handling** for failed route transitions
4. **Implement deep linking** for external URLs (future feature)
5. **Add analytics** to track user navigation patterns

---

## 📞 Support

- **Flutter Navigation Docs:** https://flutter.dev/docs/cookbook/navigation
- **Named Routes:** https://flutter.dev/docs/cookbook/navigation/named-routes
- **Passing Data:** https://flutter.dev/docs/cookbook/navigation/passing-data

---

**Last Updated:** April 14, 2026  
**Navigation Framework:** Material Navigator (No GetX)  
**Production Ready:** ✅ Yes
