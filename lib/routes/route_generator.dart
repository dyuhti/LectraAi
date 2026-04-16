import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/screens/splash_screen.dart';
import 'package:smart_lecture_notes/screens/login_screen.dart';
import 'package:smart_lecture_notes/screens/signup_screen.dart';
import 'package:smart_lecture_notes/screens/forgot_password_screen.dart';
import 'package:smart_lecture_notes/screens/home_screen.dart';
import 'package:smart_lecture_notes/screens/capture_create_notes_screen.dart';
import 'package:smart_lecture_notes/screens/camera_capture_screen.dart';
import 'package:smart_lecture_notes/screens/file_upload_screen.dart';
import 'package:smart_lecture_notes/screens/record_lecture_screen.dart';
import 'package:smart_lecture_notes/screens/preview_document_screen.dart';
import 'package:smart_lecture_notes/screens/my_notes_screen.dart';
import 'package:smart_lecture_notes/screens/note_detail_screen.dart';
import 'package:smart_lecture_notes/screens/practice_quiz_screen.dart';
import 'package:smart_lecture_notes/screens/quiz_results_screen.dart';
import 'package:smart_lecture_notes/screens/revision_reminders_screen.dart';
import 'package:smart_lecture_notes/screens/study_dashboard_screen.dart';
import 'package:smart_lecture_notes/screens/settings_screen.dart';
import 'package:smart_lecture_notes/routes/page_transitions.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

/// Route Generator
/// Handles all named route navigation with optional arguments
class RouteGenerator {
  /// Generate routes based on route name
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // Splash & Authentication
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen());

      case AppRoutes.login:
        return _buildRoute(const LoginScreen());

      case AppRoutes.register:
        return _buildRoute(const SignupScreen());

      case AppRoutes.forgotPassword:
        return _buildRoute(const ForgotPasswordScreen());

      // Main Dashboard
      case AppRoutes.home:
        return _buildRoute(const HomeScreen());

      // Note Capture & Processing
      case AppRoutes.captureNotes:
        return _buildRoute(const CaptureCreateNotesScreen());

      case AppRoutes.smartCamera:
        return _buildRoute(const CameraCaptureScreen());

      case AppRoutes.fileUpload:
        return _buildRoute(const FileUploadScreen());

      case AppRoutes.recordAudio:
        return _buildRoute(const RecordLectureScreen());

      case AppRoutes.previewDocument:
        return _buildRoute(const PreviewDocumentScreen());

      // Note Management
      case AppRoutes.viewNotes:
        return _buildRoute(const MyNotesScreen());

      case AppRoutes.noteDetail:
        final noteTitle = (args is Map) ? args['noteTitle'] as String? : null;
        final categoryName = (args is Map) ? args['categoryName'] as String? : null;
        return _buildRoute(NoteDetailScreen(
          noteTitle: noteTitle,
          categoryName: categoryName,
        ));

      // Quiz System
      case AppRoutes.generateQuiz:
        return _buildRoute(const PracticeQuizScreen());

      case AppRoutes.practiceQuiz:
        return _buildRoute(const PracticeQuizScreen());

      case AppRoutes.quizResults:
        // QuizResultsScreen requires questions, correctCount, totalCount parameters
        // These should be passed as arguments from previous screen
        return _buildRoute(const QuizResultsScreen(
          questions: [],
          correctCount: 0,
          totalCount: 0,
        ));

      // Learning Features
      case AppRoutes.revisionReminder:
        return _buildRoute(const RevisionRemindersScreen());

      case AppRoutes.studyAnalytics:
        return _buildRoute(const StudyDashboardScreen());

      // User Settings
      case AppRoutes.profile:
        return _buildRoute(const SettingsScreen());

      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen());

      // Default fallback
      default:
        return _buildErrorRoute(
          'No route defined for ${settings.name}',
        );
    }
  }

  /// Build standard material page route with fade transition
  static Route<dynamic> _buildRoute(Widget page) {
    return AppPageTransitions.fadeSlide(
      page,
      settings: RouteSettings(name: page.runtimeType.toString()),
    );
  }

  /// Build error route for undefined navigation paths
  static MaterialPageRoute<dynamic> _buildErrorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Navigation Error'),
          backgroundColor: AppColors.primary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Navigation Error',
                style: Theme.of(_).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(_).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(_).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
