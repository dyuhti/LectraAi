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
import 'package:smart_lecture_notes/screens/notes_screen.dart';
import 'package:smart_lecture_notes/screens/note_detail_screen.dart';
import 'package:smart_lecture_notes/screens/generate_quiz_screen.dart';
import 'package:smart_lecture_notes/screens/practice_quiz_screen.dart';
import 'package:smart_lecture_notes/screens/quiz_results_screen.dart';
import 'package:smart_lecture_notes/screens/review_answers_screen.dart';
import 'package:smart_lecture_notes/screens/revision_reminders_screen.dart';
import 'package:smart_lecture_notes/screens/study_dashboard_screen.dart';
import 'package:smart_lecture_notes/screens/settings_screen.dart';
import 'package:smart_lecture_notes/screens/help_center_screen.dart';
import 'package:smart_lecture_notes/screens/help_tutorial_screen.dart';
import 'package:smart_lecture_notes/screens/adaptive_notes_screen.dart';
import 'package:smart_lecture_notes/routes/page_transitions.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';
import 'package:smart_lecture_notes/providers/accessibility_provider.dart';
import 'package:smart_lecture_notes/widgets/tts_control_widget.dart';
import 'package:smart_lecture_notes/utils/tts_text_builder.dart';
import 'package:provider/provider.dart';

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
      case AppRoutes.notes:
      case AppRoutes.viewNotes:
        return _buildRoute(const NotesScreen());

      case AppRoutes.noteDetail:
        final noteTitle = (args is Map) ? args['noteTitle'] as String? : null;
        final categoryName = (args is Map) ? args['categoryName'] as String? : null;
        return _buildRoute(NoteDetailScreen(
          noteTitle: noteTitle,
          categoryName: categoryName,
        ));

      // Quiz System
      case AppRoutes.generateQuiz:
        return _buildRoute(const GenerateQuizScreen());

      case AppRoutes.practiceQuiz:
        return _buildRoute(const PracticeQuizScreen());

      case AppRoutes.quizResults:
        return _buildRoute(const QuizResultsScreen());

      case AppRoutes.reviewAnswers:
        return _buildRoute(const ReviewAnswersScreen());

      // Learning Features
      case AppRoutes.adaptiveLearning:
        return _buildRoute(const AdaptiveNotesScreen());

      case AppRoutes.revisionReminder:
        return _buildRoute(const RevisionRemindersScreen());

      case AppRoutes.studyAnalytics:
        return _buildRoute(const StudyDashboardScreen());

      // User Settings
      case AppRoutes.profile:
        return _buildRoute(const SettingsScreen());

      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen());

      case AppRoutes.helpCenter:
        return _buildRoute(const HelpCenterScreen());

      case AppRoutes.appGuide:
      case AppRoutes.tutorial:
        return _buildRoute(const HelpTutorialScreen());

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
      AccessibilityRouteHost(page: page),
      settings: RouteSettings(name: page.runtimeType.toString()),
    );
  }

  static String _screenTextForRoute(String? routeName, Widget page) {
    switch (routeName) {
      case 'HomeScreen':
      case AppRoutes.home:
        return 'Smart Notes home. Your AI-powered lecture companion. Capture and create notes. Quick capture. View notes. Today study progress includes notes, images, and quizzes.';
      case 'CaptureCreateNotesScreen':
      case AppRoutes.captureNotes:
        return 'Capture create notes screen. Choose how to capture content from camera, files, or audio.';
      case 'PreviewDocumentScreen':
      case AppRoutes.previewDocument:
        return 'Document preview screen. Review the detected content and continue processing.';
      case 'NotesScreen':
      case AppRoutes.notes:
      case AppRoutes.viewNotes:
        return 'Notes screen. Browse your saved notes and open a note to see summary, key points, formulas, and examples.';
      case 'StudyDashboardScreen':
      case AppRoutes.studyAnalytics:
        return 'Study analytics dashboard. Review your progress, performance, and learning trends.';
      case 'GenerateQuizScreen':
      case AppRoutes.generateQuiz:
        return 'Generate quiz screen. Create a practice quiz from your notes and study material.';
      case 'PracticeQuizScreen':
      case AppRoutes.practiceQuiz:
        return 'Practice quiz screen. Answer questions and check your understanding.';
      case 'QuizResultsScreen':
      case AppRoutes.quizResults:
        return 'Quiz results screen. Review your score and feedback after completing the quiz.';
      case 'RevisionRemindersScreen':
      case AppRoutes.revisionReminder:
        return 'Revision reminders screen. Manage scheduled study reminders.';
      case 'HelpCenterScreen':
      case AppRoutes.helpCenter:
        return 'Help center screen. Find support and answers to common questions.';
      case 'HelpTutorialScreen':
      case AppRoutes.appGuide:
      case AppRoutes.tutorial:
        return 'Tutorial screen. Learn how to use Smart Notes and its features.';
      case 'SettingsScreen':
      case AppRoutes.settings:
      case AppRoutes.profile:
        return 'Settings screen. Adjust app preferences and accessibility options.';
      case 'LoginScreen':
      case AppRoutes.login:
        return 'Login screen. Sign in to your Smart Notes account.';
      case 'SignupScreen':
      case AppRoutes.register:
        return 'Sign up screen. Create a new Smart Notes account.';
      case 'ForgotPasswordScreen':
      case AppRoutes.forgotPassword:
        return 'Forgot password screen. Recover access to your account.';
      case 'RecordLectureScreen':
      case AppRoutes.recordAudio:
        return 'Record lecture screen. Capture audio and generate notes from the recording.';
      case 'CameraCaptureScreen':
      case AppRoutes.smartCamera:
        return 'Camera capture screen. Take a photo to extract text and generate notes.';
      case 'FileUploadScreen':
      case AppRoutes.fileUpload:
        return 'File upload screen. Upload a document to generate notes.';
      case 'NoteDetailScreen':
      case AppRoutes.noteDetail:
        return 'Note detail screen. Read the selected note, summary, key points, formulas, and examples.';
      default:
        return page.runtimeType.toString();
    }
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

class AccessibilityRouteHost extends StatefulWidget {
  const AccessibilityRouteHost({super.key, required this.page});

  final Widget page;

  @override
  State<AccessibilityRouteHost> createState() => _AccessibilityRouteHostState();
}

class _AccessibilityRouteHostState extends State<AccessibilityRouteHost> {
  static const double _overlayPadding = 16;
  static const double _contentBottomInset = 100;

  @override
  Widget build(BuildContext context) {
    final isEnabled = context.watch<AccessibilityProvider>().isEnabled;
    final screenText = context.watch<AccessibilityProvider>().screenText;
    final showOverlay = isEnabled && screenText.isNotEmpty;

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: showOverlay ? _contentBottomInset : 0),
              child: _RouteTextCollector(
                child: widget.page,
                onTextExtracted: (text) {
                  if (!mounted || text.trim().isEmpty) return;
                  context.read<AccessibilityProvider>().setScreenTextIfCurrent(
                    context,
                    text,
                    priority: 1,
                  );
                },
              ),
            ),
          ),
        ),
        if (showOverlay)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(_overlayPadding),
              child: TtsControlWidget(text: screenText),
            ),
          ),
      ],
    );
  }
}

class _RouteTextCollector extends StatefulWidget {
  const _RouteTextCollector({
    required this.child,
    required this.onTextExtracted,
  });

  final Widget child;
  final ValueChanged<String> onTextExtracted;

  @override
  State<_RouteTextCollector> createState() => _RouteTextCollectorState();
}

class _RouteTextCollectorState extends State<_RouteTextCollector> {
  final GlobalKey _captureRootKey = GlobalKey();
  String _lastExtractedText = '';

  @override
  void initState() {
    super.initState();
    _scheduleExtraction();
  }

  @override
  void didUpdateWidget(covariant _RouteTextCollector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleExtraction();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleExtraction();
    return KeyedSubtree(
      key: _captureRootKey,
      child: widget.child,
    );
  }

  void _scheduleExtraction() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rootContext = _captureRootKey.currentContext;
      if (rootContext == null) return;

      final extracted = _extractStructuredText(rootContext);
      if (extracted.isEmpty || extracted == _lastExtractedText) {
        return;
      }

      _lastExtractedText = extracted;
      widget.onTextExtracted(extracted);
    });
  }

  String _extractStructuredText(BuildContext context) {
    final lines = <String>[];

    void collectFromSpan(InlineSpan? span) {
      if (span == null) return;
      final text = span.toPlainText().trim();
      if (text.isNotEmpty) {
        lines.addAll(_normalizeLines(text));
      }
    }

    void visit(Element element) {
      final widget = element.widget;

      if (widget is Text) {
        final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
        lines.addAll(_normalizeLines(text));
      } else if (widget is RichText) {
        collectFromSpan(widget.text);
      } else if (widget is SelectableText) {
        final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
        lines.addAll(_normalizeLines(text));
      } else if (widget is EditableText) {
        lines.addAll(_normalizeLines(widget.controller.text));
      }

      element.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);

    final uniqueLines = <String>[];
    final seen = <String>{};
    for (final line in lines) {
      if (seen.add(line)) {
        uniqueLines.add(line);
      }
    }

    if (uniqueLines.isEmpty) {
      return '';
    }

    final title = uniqueLines.first;
    final remaining = uniqueLines.length > 1 ? uniqueLines.sublist(1) : <String>[];

    return buildStructuredText(
      title: title,
      content: 'All visible content from this screen is listed point by point for guided reading.',
      keyPoints: remaining,
    );
  }

  List<String> _normalizeLines(String text) {
    return text
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) {
          if (line.isEmpty) return false;
          if (line.length == 1 && !RegExp(r'[A-Za-z0-9]').hasMatch(line)) {
            return false;
          }
          return true;
        })
        .toList();
  }
}
