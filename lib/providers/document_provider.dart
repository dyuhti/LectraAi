import 'package:flutter/foundation.dart';
import 'package:smart_lecture_notes/services/document_processing_service.dart';
import 'dart:typed_data';

class DocumentProvider extends ChangeNotifier {
  String extractedText = '';
  String summary = '';
  String title = '';
  String authors = '';
  String doi = '';
  String abstractText = '';
  String journalInfo = '';
  bool isResearchPaper = false;
  List<String> detailLines = [];
  bool isLoading = false;
  String errorMessage = '';

  Future<void> processFile(
    String path, {
    Uint8List? fileBytes,
    String? fileName,
    bool isExtract = true,
    bool isSummarize = true,
    bool isKeyword = true,
  }) async {
    isLoading = true;
    extractedText = '';
    summary = '';
    errorMessage = '';
    notifyListeners();

    try {
      final result = await DocumentProcessingService.processFile(
        path,
        fileBytes: fileBytes,
        fileName: fileName,
        isExtract: isExtract,
        isSummarize: isSummarize,
        isKeyword: isKeyword,
      );
      extractedText = result['text']?.toString() ?? '';
      summary = result['summary']?.toString() ?? '';
      title = result['title']?.toString() ?? '';
      authors = result['authors']?.toString() ?? '';
      doi = result['doi']?.toString() ?? '';
      abstractText = result['abstractText']?.toString() ?? '';
      journalInfo = result['journalInfo']?.toString() ?? '';
      isResearchPaper = result['isResearchPaper'] == true;
      final details = result['detailLines'];
      detailLines = details is List
          ? details.map((line) => line.toString()).toList()
          : [];
    } catch (e) {
      extractedText = 'Failed to extract text.';
      summary = 'Error generating summary.';
      title = '';
      authors = '';
      doi = '';
      abstractText = '';
      journalInfo = '';
      isResearchPaper = false;
      detailLines = [];
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> processFileBytes(
    Uint8List bytes, {
    required String fileName,
    bool isExtract = true,
    bool isSummarize = true,
    bool isKeyword = true,
  }) async {
    isLoading = true;
    extractedText = '';
    summary = '';
    errorMessage = '';
    notifyListeners();

    try {
      final result = await DocumentProcessingService.processFile(
        '',
        fileBytes: bytes,
        fileName: fileName,
        isExtract: isExtract,
        isSummarize: isSummarize,
        isKeyword: isKeyword,
      );
      extractedText = result['text']?.toString() ?? '';
      summary = result['summary']?.toString() ?? '';
      title = result['title']?.toString() ?? '';
      authors = result['authors']?.toString() ?? '';
      doi = result['doi']?.toString() ?? '';
      abstractText = result['abstractText']?.toString() ?? '';
      journalInfo = result['journalInfo']?.toString() ?? '';
      isResearchPaper = result['isResearchPaper'] == true;
      final details = result['detailLines'];
      detailLines = details is List
          ? details.map((line) => line.toString()).toList()
          : [];
    } catch (e) {
      extractedText = 'Failed to extract text.';
      summary = 'Error generating summary.';
      title = '';
      authors = '';
      doi = '';
      abstractText = '';
      journalInfo = '';
      isResearchPaper = false;
      detailLines = [];
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    extractedText = '';
    summary = '';
    title = '';
    authors = '';
    doi = '';
    abstractText = '';
    journalInfo = '';
    isResearchPaper = false;
    detailLines = [];
    errorMessage = '';
    isLoading = false;
    notifyListeners();
  }

  void setError(String message) {
    extractedText = 'Failed to extract text.';
    summary = message;
    title = '';
    authors = '';
    doi = '';
    abstractText = '';
    journalInfo = '';
    isResearchPaper = false;
    detailLines = [];
    errorMessage = message;
    isLoading = false;
    notifyListeners();
  }
}
