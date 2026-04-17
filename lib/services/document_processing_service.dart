import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:smart_lecture_notes/services/lecture_ai_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

enum _FileType { pdf, image, text }

class DocumentProcessingService {
  static Future<Map<String, String>> processFile(String path) async {
    final fileType = _detectFileType(path);
    debugPrint('DocumentProcessingService: path=$path type=$fileType');

    String extractedText;
    switch (fileType) {
      case _FileType.pdf:
        extractedText = await _extractTextFromPdf(path);
        break;
      case _FileType.image:
        extractedText = await _extractTextFromImage(path);
        break;
      case _FileType.text:
        extractedText = await _extractTextFromPlainFile(path);
        break;
    }

    final cleanedText = _cleanText(extractedText);
    final summary = await _generateSummary(cleanedText);

    debugPrint(
      'DocumentProcessingService: textLength=${cleanedText.length} summary=${_truncateForLog(summary)}',
    );

    return {
      'text': cleanedText,
      'summary': summary,
    };
  }

  static _FileType _detectFileType(String path) {
    final ext = p.extension(path).toLowerCase();
    if (ext == '.pdf') {
      return _FileType.pdf;
    }

    if (['.png', '.jpg', '.jpeg', '.webp', '.bmp', '.heic'].contains(ext)) {
      return _FileType.image;
    }

    return _FileType.text;
  }

  static Future<String> _extractTextFromPdf(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File not found: $path');
    }

    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final text = extractor.extractText();
    document.dispose();
    return text;
  }

  static Future<String> _extractTextFromImage(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final recognizer = TextRecognizer();
    try {
      final recognizedText = await recognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      await recognizer.close();
    }
  }

  static Future<String> _extractTextFromPlainFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File not found: $path');
    }

    return file.readAsString();
  }

  static String _cleanText(String text) {
    var cleaned = text.replaceAll('\r', '\n');
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return cleaned.trim();
  }

  static Future<String> _generateSummary(String text) async {
    if (text.trim().isEmpty) {
      return 'No text extracted from document.';
    }

    try {
      final result = await LectureAiService().generateLectureSummary(text);
      final summary = result['summary']?.toString().trim() ?? '';
      if (summary.isNotEmpty) {
        return summary;
      }
    } catch (e) {
      debugPrint('DocumentProcessingService: summary error=$e');
    }

    return _fallbackSummary(text);
  }

  static String _fallbackSummary(String text) {
    final sentences = text
        .split(RegExp(r'[.!?]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (sentences.isEmpty) {
      return 'Summary unavailable.';
    }

    if (sentences.length == 1) {
      return sentences.first;
    }

    return '${sentences[0]}. ${sentences[1]}.';
  }

  static String _truncateForLog(String value, {int max = 500}) {
    if (value.length <= max) {
      return value;
    }
    return '${value.substring(0, max)}...';
  }
}
