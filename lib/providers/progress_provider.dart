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
      _history = await _apiService.fetchHistory();
    } catch (e) {
      debugPrint('[ProgressProvider] Error refreshing progress: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
  }

  Future<void> incrementAudio() async {
    await _apiService.updateAudioProgress();
    await refreshProgress();
  }

  Future<void> incrementQuiz() async {
    await _apiService.updateQuizProgress();
    await refreshProgress();
  }
}
