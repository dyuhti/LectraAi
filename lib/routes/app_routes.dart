/// App Routes Configuration
/// Central management of all named routes and navigation constants

class AppRoutes {
  // Splash & Authentication
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Home & Main Navigation
  static const String home = '/home';

  // Note Capture & Processing
  static const String captureNotes = '/capture-notes';
  static const String smartCamera = '/smart-camera';
  static const String fileUpload = '/file-upload';
  static const String recordAudio = '/record-audio';
  static const String previewDocument = '/preview-document';

  // Note Management
  static const String notes = '/notes';
  static const String viewNotes = '/view-notes';
  static const String noteDetail = '/note-detail';

  // Quiz System
  static const String generateQuiz = '/generate-quiz';
  static const String practiceQuiz = '/practice-quiz';
  static const String quizResults = '/quiz-results';
  static const String reviewAnswers = '/review-answers';

  // Learning Features
  static const String adaptiveLearning = '/adaptive-learning';
  static const String revisionReminder = '/revision-reminder';
  static const String studyAnalytics = '/study-analytics';

  // User Settings
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String helpCenter = '/help-center';
  static const String appGuide = '/app-guide';
  static const String tutorial = '/tutorial';

  /// Get route name for display/debugging
  static String getRouteName(String route) {
    final routeNames = {
      splash: 'Splash Screen',
      login: 'Login',
      register: 'Register',
      home: 'Home',
      captureNotes: 'Capture Notes',
      smartCamera: 'Smart Camera',
      fileUpload: 'File Upload',
      recordAudio: 'Record Audio',
      previewDocument: 'Preview Document',
      notes: 'Notes',
      viewNotes: 'View Notes',
      noteDetail: 'Note Detail',
      generateQuiz: 'Generate Quiz',
      practiceQuiz: 'Practice Quiz',
      quizResults: 'Quiz Results',
      reviewAnswers: 'Review Answers',
      adaptiveLearning: 'Adaptive Learning',
      revisionReminder: 'Revision Reminder',
      studyAnalytics: 'Study Analytics',
      profile: 'Profile',
      settings: 'Settings',
      helpCenter: 'Help Center',
      appGuide: 'App Guide',
      tutorial: 'App Guide',
    };
    return routeNames[route] ?? 'Unknown Route';
  }

  /// Check if route requires authentication
  static bool requiresAuth(String route) {
    final publicRoutes = {splash, login, register};
    return !publicRoutes.contains(route);
  }

  /// Home screen for authenticated users
  static String get homeRoute => home;

  /// Initial route based on auth status
  static String getInitialRoute(bool isAuthenticated) {
    return isAuthenticated ? home : login;
  }
}
