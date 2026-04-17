import 'package:flutter/foundation.dart';
import 'package:smart_lecture_notes/services/document_processing_service.dart';

class DocumentProvider extends ChangeNotifier {
  String extractedText = '';
  String summary = '';
  bool isLoading = false;
  String errorMessage = '';

  Future<void> processFile(String path) async {
    isLoading = true;
    extractedText = '';
    summary = '';
    errorMessage = '';
    notifyListeners();

    try {
      final result = await DocumentProcessingService.processFile(path);
      extractedText = result['text'] ?? '';
      summary = result['summary'] ?? '';
    } catch (e) {
      extractedText = 'Failed to extract text.';
      summary = 'Error generating summary.';
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    extractedText = '';
    summary = '';
    errorMessage = '';
    isLoading = false;
    notifyListeners();
  }

  void setError(String message) {
    extractedText = 'Failed to extract text.';
    summary = message;
    errorMessage = message;
    isLoading = false;
    notifyListeners();
  }
}
