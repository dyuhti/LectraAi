# Navigation Implementation Pattern

## Quick Reference for Updating All Screens

### Pattern 1: Replace GetX Navigation with Navigator
**Before (GetX):**
```dart
import 'package:get/get.dart';

Get.to(() => const NextScreen());
Get.off(() => const NextScreen());
Get.back();
```

**After (Named Routes):**
```dart
import 'package:smart_lecture_notes/routes/app_routes.dart';

Navigator.of(context).pushNamed(AppRoutes.nextScreen);
Navigator.of(context).pushReplacementNamed(AppRoutes.nextScreen);
Navigator.of(context).pop();
```

---

## Implementation Checklist for Each Screen

### Step 1: Update Imports
```dart
// Remove these
import 'package:get/get.dart';
import 'package:smart_lecture_notes/screens/other_screen.dart';

// Add these
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/widgets/custom_app_bar.dart';
```

### Step 2: Replace AppBar
```dart
// Before
AppBar(
  title: const Text('Screen Title'),
  leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () => Get.back(),
  ),
)

// After
CustomAppBar(
  title: 'Screen Title',
  // Back button automatically included!
)
```

### Step 3: Replace All Navigation
```dart
// Before
ElevatedButton(
  onPressed: () => Get.to(() => const OtherScreen()),
  child: Text('Go'),
)

// After
ElevatedButton(
  onPressed: () {
    Navigator.of(context).pushNamed(AppRoutes.otherScreen);
  },
  child: Text('Go'),
)
```

### Step 4: Replace Navigation with Pop
```dart
// Before
FloatingActionButton(
  onPressed: () => Get.back(),
)

// After
FloatingActionButton(
  onPressed: () => Navigator.of(context).pop(),
)
```

### Step 5: Replace Navigation with Arguments
```dart
// Before
Get.to(
  () => NoteDetailScreen(noteId: '123'),
)

// After
Navigator.of(context).pushNamed(
  AppRoutes.noteDetail,
  arguments: {'noteId': '123'},
)

// And in RouteGenerator
case AppRoutes.noteDetail:
  final args = settings.arguments as Map?;
  return _buildRoute(
    NoteDetailScreen(
      noteId: args?['noteId']?.toString() ?? '',
    ),
  );
```

---

## Replace All GetX Get.snackbar with ScaffoldMessenger

```dart
// Before
Get.snackbar(
  'Title',
  'Message',
  backgroundColor: Colors.blue,
  colorText: Colors.white,
);

// After
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Message'),
    backgroundColor: Colors.blue,
    duration: Duration(seconds: 2),
  ),
);
```

---

## Replace All GetX Get.bottomSheet with showModalBottomSheet

```dart
// Before
Get.bottomSheet(
  Container(
    child: YourWidget(),
  ),
);

// After
showModalBottomSheet(
  context: context,
  builder: (context) => Container(
    child: YourWidget(),
  ),
);
```

---

## Template: Updated Screen Structure

```dart
import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/widgets/custom_app_bar.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Screen Title',
        // Back button works automatically!
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Content here'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.someScreen);
              },
              child: const Text('Navigate'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Complete Screen Update Example

### Before (GetX-based)
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_lecture_notes/screens/home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ElevatedButton(
        onPressed: () {
          Get.off(() => const HomeScreen());
        },
        child: const Text('Login'),
      ),
    );
  }
}
```

### After (Navigator-based)
```dart
import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/widgets/custom_app_bar.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Login',
        // Back button included automatically
      ),
      body: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.home,
            (route) => false,
          );
        },
        child: const Text('Login'),
      ),
    );
  }
}
```

---

## Async Navigation Pattern

When navigating from async operations:

```dart
// WRONG - may crash if widget disposed
async void _loadData() {
  await Future.delayed(Duration(seconds: 2));
  Navigator.of(context).pushNamed(AppRoutes.home);
}

// CORRECT - check if widget still mounted
void _loadData() async {
  await Future.delayed(const Duration(seconds: 2));
  if (mounted) {
    Navigator.of(context).pushNamed(AppRoutes.home);
  }
}
```

---

## Advanced: Using Arguments

### 1. Define in RouteGenerator
```dart
case AppRoutes.noteDetail:
  return _buildRoute(NoteDetailScreen(
    noteData: (args is Map) ? args['noteData'] : null,
  ));
```

### 2. Send with Arguments
```dart
Navigator.of(context).pushNamed(
  AppRoutes.noteDetail,
  arguments: {
    'noteData': myNoteObject,
  },
);
```

### 3. Receive in Screen
```dart
class NoteDetailScreen extends StatelessWidget {
  final dynamic noteData;

  const NoteDetailScreen({
    Key? key,
    this.noteData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Note Details'),
      body: Text('Note: ${noteData?.title ?? 'Unknown'}'),
    );
  }
}
```

---

## All Screens Conversion List

Priority order for updating to new navigation:

**CRITICAL (Update First):**
- [ ] LoginScreen - Uses Get.off() for auth
- [ ] SignupScreen - Uses Get.off() for auth
- [ ] SplashScreen - Uses Get.off() ✅ Already done

**HIGH (Update Second):**
- [ ] HomeScreen - Central routing hub
- [ ] NavigationExampleScreen - Reference implementation

**MEDIUM (Update Third):**
- [ ] CaptureCreateNotesScreen
- [ ] RecordLectureScreen
- [ ] CameraCaptureScreen
- [ ] PreviewDocumentScreen
- [ ] MyNotesScreen
- [ ] NoteDetailScreen

**LOW (Update Last):**
- [ ] PracticeQuizScreen
- [ ] QuizResultsScreen
- [ ] RevisionRemindersScreen
- [ ] StudyDashboardScreen
- [ ] SettingsScreen

---

## Testing Checklist

For each updated screen:

- [ ] App builds without errors
- [ ] Screen appears correctly
- [ ] Back button works (AppBar + Android system back)
- [ ] Navigation to next screen works
- [ ] Navigation back works
- [ ] Snackbars display correctly
- [ ] Arguments pass between screens
- [ ] No GetX imports remain
- [ ] No Get.to() calls remain
- [ ] CustomAppBar used instead of default AppBar

---

## Troubleshooting

**Error: "No route definition for..."**
- Solution: Add route to RouteGenerator.generateRoute()

**Error: "Navigator.of() not found"**
- Solution: Make sure you're in a widget (not top-level function)
- Use ScaffoldMessenger.of(context) for snackbars

**Back button not showing**
- Solution: Use CustomAppBar with showBackButton: true (default)

**Arguments not passing**
- Solution: Add to RouteGenerator and check argument types match

---

Generated: April 14, 2026
