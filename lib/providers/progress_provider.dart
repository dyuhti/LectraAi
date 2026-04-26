import 'package:flutter/foundation.dart';
import 'package:smart_lecture_notes/models/progress.dart';
import 'package:smart_lecture_notes/services/progress_api_service.dart';

class ProgressProvider extends ChangeNotifier {
  ProgressProvider({ProgressApiService? apiService})
      : _apiService = apiService ?? ProgressApiService() {
    refreshProgress();
  }

  final ProgressApiService _apiService;
  DailyProgress _progress = DailyProgress.empty();
  List<DailyProgress> _history = [];
  bool _isLoading = false;

  DailyProgress get progress => _progress;
  List<DailyProgress> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;

  Future<void> refreshProgress() async {
    _isLoading = true;
    notifyListeners();

    try {
      _progress = await _apiService.fetchTodayProgress();
      _history = await _apiService.fetchWeeklyProgress();
      
      // Sync dashboard (backend will calculate scores from raw data)
      await syncDashboard();
      
      debugPrint('Updated progress: ${_progress.notesCreated}/${_progress.audioRecorded}/${_progress.quizzesGenerated}, Study Time: ${_progress.studyTime}');
    } catch (e) {
      debugPrint('[ProgressProvider] Error refreshing progress: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProgress(String type, {int? duration}) async {
    await _apiService.updateProgress(type, duration: duration);
    await refreshProgress();
    await syncDashboard();
  }

  Future<void> syncDashboard() async {
    await _apiService.syncDashboard();
    // After sync, fetch the fresh weekly data
    _history = await _apiService.fetchWeeklyProgress();
    notifyListeners();
  }

  Future<void> incrementAudio({int? duration}) async {
    await updateProgress('audio', duration: duration);
  }

  Future<void> incrementQuiz({int? duration}) async {
    await updateProgress('quiz', duration: duration);
  }

  Future<void> incrementNote({int? duration}) async {
    await updateProgress('note', duration: duration);
  }

  Future<void> addStudyTime(int duration) async {
    await updateProgress('timer', duration: duration);
  }

  Future<void> fetchWeeklyData() async {
    await refreshProgress();
    // Ensure dashboard is synced when dashboard is opened
    await syncDashboard();
  }
}
