import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:smart_lecture_notes/services/lecture_ai_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

enum _FileType { pdf, image, text }

class DocumentProcessingService {
  static Future<Map<String, dynamic>> processFile(
    String path, {
    bool isExtract = true,
    bool isSummarize = true,
    bool isKeyword = true,
  }) async {
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

    final cleanedText = cleanText(extractedText);
    final normalizedLines = cleanedText.split('\n');
    final normalizedText = cleanedText;
    final title = _extractTitle(normalizedLines);
    final authors = _extractAuthors(normalizedLines, title: title);
    final doi = _extractDoi(normalizedText);
    final abstractText = _extractAbstract(normalizedLines);
    final journalInfo = _extractJournalInfo(normalizedLines);
    final isResearchPaper =
        abstractText.isNotEmpty || doi.isNotEmpty || journalInfo.isNotEmpty;
    
    // Conditionally extract detail lines (keywords) if enabled
    final detailLines = isKeyword ? _extractDetailLines(
      normalizedLines,
      title: title,
      isResearchPaper: isResearchPaper,
      abstractText: abstractText,
      doi: doi,
      journalInfo: journalInfo,
    ) : [];
    
    // Conditionally generate summary if enabled
    final summary = isSummarize ? await _generateDocumentSummary(normalizedText) : '';

    debugPrint(
      'DocumentProcessingService: textLength=${normalizedText.length} summary=${_truncateForLog(summary)} extract=$isExtract summarize=$isSummarize keyword=$isKeyword',
    );

    return {
      'text': isExtract ? normalizedText : '',
      'summary': summary,
      'title': title,
      'authors': authors,
      'doi': doi,
      'abstractText': abstractText,
      'journalInfo': journalInfo,
      'isResearchPaper': isResearchPaper,
      'detailLines': detailLines,
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

  static String cleanText(String rawText) {
    var cleaned = rawText.replaceAll('\r', '\n');
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    final normalizedLines = _normalizeLines(cleaned);
    return normalizedLines.join('\n').trim();
  }

  static List<String> _normalizeLines(String text) {
    final rawLines = text.split('\n');
    final normalized = <String>[];

    for (final rawLine in rawLines) {
      var line = rawLine.trim().replaceAll(RegExp(r'[ \t]{2,}'), ' ');
      if (line.isEmpty) {
        if (normalized.isNotEmpty && normalized.last.isNotEmpty) {
          normalized.add('');
        }
        continue;
      }

      line = _fixMergedWords(line);

      if (_isNoiseLine(line) || _isTableOfContentsLine(line)) {
        continue;
      }

      if (normalized.isEmpty || normalized.last.isEmpty) {
        normalized.add(line);
        continue;
      }

      final previous = normalized.last;
      if (_shouldJoinLines(previous, line)) {
        normalized[normalized.length - 1] = _joinLines(previous, line);
      } else {
        normalized.add(line);
      }
    }

    return _dedupeLines(normalized);
  }

  static bool _shouldJoinLines(String previous, String current) {
    if (previous.endsWith('-')) {
      return true;
    }
    if (_looksLikeHeader(current)) {
      return false;
    }

    final prevEndsWithPunct = RegExp(r'[.!?:\)"]$').hasMatch(previous);
    final currentStartsLower = RegExp(r'^[a-z]').hasMatch(current);
    return !prevEndsWithPunct && currentStartsLower;
  }

  static String _joinLines(String previous, String current) {
    if (previous.endsWith('-')) {
      return '${previous.substring(0, previous.length - 1)}$current';
    }
    return '$previous $current';
  }

  static String _fixMergedWords(String line) {
    var updated = line;
    updated = updated.replaceAllMapped(
      RegExp(r'([A-Za-z]{3,})(of|and|the|for|to|in|on|with)([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)} ${match.group(3)}',
    );
    updated = updated.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    updated = updated.replaceAllMapped(
      RegExp(r'([A-Za-z])([0-9])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    updated = updated.replaceAllMapped(
      RegExp(r'([0-9])([A-Za-z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    updated = updated.replaceAllMapped(
      RegExp(r'([,;:])([A-Za-z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    updated = updated.replaceAllMapped(
      RegExp(r'([.!?])([A-Za-z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    return updated.replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();
  }

  static bool _isTableOfContentsLine(String line) {
    final trimmed = line.trim();
    final lower = trimmed.toLowerCase();

    if (RegExp(r'^[\.\s]{4,}$').hasMatch(trimmed)) {
      return true;
    }

    if (RegExp(r'\.{2,}').hasMatch(trimmed) && RegExp(r'\d+$').hasMatch(trimmed)) {
      return true;
    }

    if (RegExp(r'^\d+(\.\d+)*\s+.+\s+\d+$').hasMatch(trimmed) &&
        RegExp(r'\.{2,}').hasMatch(trimmed)) {
      return true;
    }

    if (RegExp(r'^(figure|fig\.?|table)\s*\d+[a-z]?$').hasMatch(lower)) {
      return true;
    }

    return false;
  }

  static bool _looksLikeHeader(String line) {
    final lower = line.toLowerCase();
    if (lower == 'abstract' || lower.startsWith('abstract')) {
      return true;
    }
    if (lower.startsWith('keywords') || lower.startsWith('index terms')) {
      return true;
    }

    final letters = line.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.isNotEmpty && letters == letters.toUpperCase() && line.length <= 40) {
      return true;
    }

    return false;
  }

  static List<String> _dedupeLines(List<String> lines) {
    final seen = <String>{};
    final result = <String>[];
    for (final line in lines) {
      if (line.isEmpty) {
        if (result.isNotEmpty && result.last.isNotEmpty) {
          result.add('');
        }
        continue;
      }

      final key = line
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
          .trim();
      if (key.isEmpty || seen.contains(key)) {
        continue;
      }
      seen.add(key);
      result.add(line);
    }
    return result;
  }

  static bool _isNoiseLine(String line) {
    if (line.length <= 4 && RegExp(r'^\d+$').hasMatch(line)) {
      return true;
    }
    final lower = line.toLowerCase();
    if (RegExp(r'^page\s+\d+(\s+of\s+\d+)?$').hasMatch(lower)) {
      return true;
    }
    return false;
  }

  static String _extractTitle(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || _isSkippableTitleLine(line)) {
        continue;
      }

      var title = line;
      if (i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim();
        if (_shouldMergeTitleLine(line, nextLine)) {
          title = '$line $nextLine';
        }
      }
      return title;
    }
    return '';
  }

  static String _extractAuthors(List<String> lines, {required String title}) {
    final titleIndex = title.isEmpty
        ? -1
        : lines.indexWhere((line) => line.trim() == title);
    final startIndex = titleIndex == -1 ? 0 : titleIndex + 1;
    final endIndex = (startIndex + 6).clamp(0, lines.length);

    for (var i = startIndex; i < endIndex; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        continue;
      }
      if (_isSkippableTitleLine(line) || _looksLikeHeader(line)) {
        continue;
      }
      if (line.toLowerCase().startsWith('abstract') || _doiRegex.hasMatch(line)) {
        continue;
      }
      if (_looksLikeJournalLine(line)) {
        continue;
      }
      if (_looksLikeAuthorLine(line)) {
        return _normalizeAuthors(line);
      }
    }

    return '';
  }

  static bool _looksLikeAuthorLine(String line) {
    if (line.length > 140) {
      return false;
    }
    final lower = line.toLowerCase();
    if (lower.contains('@') || lower.contains('http')) {
      return false;
    }
    if (RegExp(r'\d').hasMatch(line)) {
      return false;
    }

    final tokens = line
        .split(RegExp(r'[\s,;]+'))
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.length < 2 || tokens.length > 12) {
      return false;
    }

    final capitalizedCount = tokens.where((token) {
      return RegExp(r"^[A-Z][a-zA-Z\-']+$").hasMatch(token) ||
          RegExp(r'^[A-Z]\.$').hasMatch(token);
    }).length;

    return capitalizedCount >= 2;
  }

  static String _normalizeAuthors(String line) {
    return line.replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();
  }

  static bool _isSkippableTitleLine(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('doi') || _doiRegex.hasMatch(line)) {
      return true;
    }
    if (RegExp(r'\b(issn|journal|proceedings|conference|vol\.|volume|issue)\b')
        .hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'^(19|20)\d{2}$').hasMatch(line)) {
      return true;
    }
    return false;
  }

  static bool _shouldMergeTitleLine(String line, String nextLine) {
    if (nextLine.isEmpty || _looksLikeHeader(nextLine)) {
      return false;
    }
    if (_isSkippableTitleLine(nextLine)) {
      return false;
    }
    if (RegExp(r'[.!?:]$').hasMatch(line)) {
      return false;
    }
    return line.length < 80 && nextLine.length < 80;
  }

  static final RegExp _doiRegex = RegExp(
    r'\b10\.\d{4,9}/[-._;()/:A-Z0-9]+\b',
    caseSensitive: false,
  );

  static String _extractDoi(String text) {
    final match = _doiRegex.firstMatch(text);
    if (match == null) {
      return '';
    }

    var doi = match.group(0) ?? '';
    doi = doi.replaceAll(RegExp(r'[.,;:)]+$'), '');
    return doi;
  }

  static String _extractAbstract(List<String> lines) {
    final startIndex = lines.indexWhere(
      (line) => line.toLowerCase().contains('abstract'),
    );
    if (startIndex == -1) {
      return '';
    }

    final buffer = StringBuffer();
    final startLine = lines[startIndex];
    final inline = _extractAbstractFromLine(startLine);
    if (inline.isNotEmpty) {
      buffer.write(inline);
    }

    for (var i = startIndex + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        if (buffer.isNotEmpty) {
          break;
        }
        continue;
      }
      if (_isAbstractStopLine(line)) {
        break;
      }
      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      buffer.write(line);
    }

    return buffer
        .toString()
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .trim();
  }

  static String _extractAbstractFromLine(String line) {
    final lower = line.toLowerCase();
    final index = lower.indexOf('abstract');
    if (index == -1) {
      return '';
    }
    var rest = line.substring(index + 'abstract'.length).trim();
    rest = rest.replaceFirst(RegExp(r'^[:\-\s]+'), '').trim();
    return rest;
  }

  static bool _isAbstractStopLine(String line) {
    final lower = line.toLowerCase();
    if (lower.startsWith('keywords') ||
        lower.startsWith('index terms') ||
        lower.startsWith('introduction')) {
      return true;
    }
    if (RegExp(r'^[0-9]+\.?\s').hasMatch(lower)) {
      return true;
    }
    if (_looksLikeHeader(line) && !lower.startsWith('abstract')) {
      return true;
    }
    return false;
  }

  static String _extractJournalInfo(List<String> lines) {
    for (var i = 0; i < lines.length && i < 40; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || _doiRegex.hasMatch(line)) {
        continue;
      }
      final combined = _combineJournalAbbreviations(lines, i);
      if (combined.isNotEmpty) {
        return combined;
      }
      if (_looksLikeJournalLine(line)) {
        return line;
      }
    }
    return '';
  }

  static String _combineJournalAbbreviations(List<String> lines, int startIndex) {
    final buffer = <String>[];
    for (var i = startIndex; i < lines.length && buffer.length < 3; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        break;
      }
      if (!_isShortJournalFragment(line)) {
        break;
      }
      buffer.add(line);
    }

    if (buffer.length >= 2) {
      return buffer.join(' ');
    }
    return '';
  }

  static bool _isShortJournalFragment(String line) {
    if (line.length > 10) {
      return false;
    }
    if (!line.endsWith('.')) {
      return false;
    }
    return RegExp(r'[A-Za-z]').hasMatch(line);
  }

  static bool _looksLikeJournalLine(String line) {
    if (!RegExp(r'[A-Za-z]').hasMatch(line)) {
      return false;
    }
    final lower = line.toLowerCase();
    if (RegExp(r'\b(journal|proceedings|conference|vol\.|volume|issue|issn)\b')
        .hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'\b(publisher|elsevier|springer|ieee|acm|wiley|taylor|sage)\b')
        .hasMatch(lower)) {
      return true;
    }

    final numbers = RegExp(r'\b\d+\b')
        .allMatches(line)
        .map((match) => int.tryParse(match.group(0) ?? '') ?? 0)
        .toList();
    final hasYear = numbers.any((value) => value >= 1900 && value <= 2099);
    return hasYear && numbers.length >= 3 && line.length <= 120;
  }

  static List<String> _extractDetailLines(
    List<String> lines, {
    required String title,
    required bool isResearchPaper,
    required String abstractText,
    required String doi,
    required String journalInfo,
  }) {
    final details = <String>[];
    final seen = <String>{};
    final abstractLower = abstractText.toLowerCase();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (trimmed == title || _isNoiseLine(trimmed)) {
        continue;
      }

      final lower = trimmed.toLowerCase();
      if (lower.startsWith('abstract')) {
        continue;
      }
      if (doi.isNotEmpty && trimmed.contains(doi)) {
        continue;
      }
      if (journalInfo.isNotEmpty && trimmed == journalInfo) {
        continue;
      }
      if (abstractLower.isNotEmpty && abstractLower.contains(lower)) {
        continue;
      }
      if (trimmed.length < 4) {
        continue;
      }

      final key = lower.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
      if (key.isEmpty || seen.contains(key)) {
        continue;
      }
      seen.add(key);
      details.add(trimmed);

      final limit = isResearchPaper ? 8 : 12;
      if (details.length >= limit) {
        break;
      }
    }

    return details;
  }

  static Future<String> _generateDocumentSummary(String text) async {
    if (text.trim().isEmpty) {
      return 'No text extracted from document.';
    }

    final summarySource = text.length > 8000 ? text.substring(0, 8000) : text;

    try {
      final summary = await LectureAiService().generateDocumentSummary(summarySource);
      final normalized = _normalizeSummary(summary, summarySource);
      if (normalized.isNotEmpty) {
        return normalized;
      }
    } catch (e) {
      debugPrint('DocumentProcessingService: summary error=$e');
    }

    return _fallbackSummary(text);
  }

  static String _normalizeSummary(String summary, String sourceText) {
    final cleaned = summary.replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();
    final lines = cleaned
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    var normalizedLines = lines.isEmpty
        ? <String>[]
        : _splitIntoSentences(lines.join(' '));
    if (normalizedLines.length < 3) {
      normalizedLines = _splitIntoSentences(sourceText);
    }

    final deduped = <String>[];
    final seen = <String>{};
    for (final line in normalizedLines) {
      final key = line.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
      if (key.isEmpty || seen.contains(key)) {
        continue;
      }
      seen.add(key);
      deduped.add(line);
      if (deduped.length >= 5) {
        break;
      }
    }

    return deduped.take(5).join('\n');
  }

  static String _fallbackSummary(String text) {
    final sentences = _splitIntoSentences(text);
    if (sentences.isEmpty) {
      return 'Summary unavailable.';
    }

    final targetCount = sentences.length >= 5
        ? 5
        : sentences.length >= 3
            ? 3
            : sentences.length;

    return sentences.take(targetCount).join('\n');
  }

  static List<String> _splitIntoSentences(String text) {
    final normalized = text
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .trim();
    final matches = RegExp(r'[^.!?]+[.!?]?').allMatches(normalized);
    return matches
        .map((match) => match.group(0)?.trim() ?? '')
        .where((sentence) => sentence.isNotEmpty)
        .toList();
  }

  static String _truncateForLog(String value, {int max = 500}) {
    if (value.length <= max) {
      return value;
    }
    return '${value.substring(0, max)}...';
  }
}
