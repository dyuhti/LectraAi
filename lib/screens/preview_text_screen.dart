import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';
import 'package:smart_lecture_notes/services/ai_service.dart';
import 'package:smart_lecture_notes/providers/accessibility_provider.dart';
import 'package:smart_lecture_notes/utils/tts_text_builder.dart';

class PreviewTextScreen extends StatefulWidget {
  final String originalText;
  final String title;
  final String content;
  final List<String> keyPoints;

  const PreviewTextScreen({
    Key? key,
    required this.originalText,
    required this.title,
    required this.content,
    required this.keyPoints,
  }) : super(key: key);

  @override
  State<PreviewTextScreen> createState() => _PreviewTextScreenState();
}

class _PreviewTextScreenState extends State<PreviewTextScreen> {
  static const TextStyle _bodyTextStyle = TextStyle(
    fontSize: 15,
    height: 1.6,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle _inlineBoldStyle = TextStyle(
    fontSize: 15,
    height: 1.6,
    color: AppColors.primaryDark,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle _sideHeadingStyle = TextStyle(
    fontSize: 15,
    height: 1.6,
    color: AppColors.primaryDark,
    fontWeight: FontWeight.w800,
  );

  late String _title;
  late String _content;
  late List<String> _keyPoints;
  
  String _selectedMode = 'exam';
  bool _isLoading = false;
  
  final AiService _aiService = AiService();

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _content = widget.content;
    _keyPoints = widget.keyPoints;

    // IMPORTANT: Apply mode when screen loads
    Future.microtask(() => _applyMode());
  }

  // Build the text string for TTS
  String get _ttsText => buildStructuredText(
        title: _title,
        content: _content,
        keyPoints: _keyPoints,
      );

  // Fetches notes using the current selected mode.
  Future<void> _applyMode() async {
    if (_isLoading) return;

    final modeToUse = _selectedMode;
    debugPrint('[PreviewTextScreen] MODE USED: $modeToUse');

    setState(() => _isLoading = true);

    try {
      final response = await _aiService.generateNotes(widget.originalText, modeToUse);

      if (!mounted) return;

      setState(() {
        _title = response['title']?.toString() ?? 'Notes';
        _content = response['content']?.toString() ?? '';
        _keyPoints = List<String>.from(response['key_points'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load notes ($modeToUse mode): $e')),
      );
    }
  }

  Widget _buildModeButton(String mode, String label, IconData icon) {
    final isActive = _selectedMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedMode = mode);
          _applyMode();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.primary.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Column(
            children: [
              Icon(
                icon, 
                color: isActive ? Colors.white : AppColors.primary,
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, dynamic content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildContent(content),
        ],
      ),
    );
  }

  String _sanitizeStructuredText(String input) {
    return input
        .replaceAll('\\n', '\n')
        .replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</\s*(p|div|h1|h2|h3|h4|h5|h6|li|ul|ol)\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<\s*li\s*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  bool _isSideHeading(String line) {
    if (line.isEmpty) {
      return false;
    }
    if (line.endsWith(':')) {
      return true;
    }
    return RegExp(r'^[A-Z][A-Za-z0-9\s\-/()]{2,}$').hasMatch(line) && line.length <= 60;
  }

  List<InlineSpan> _buildInlineSpans(String text, TextStyle style) {
    final spans = <InlineSpan>[];
    final matcher = RegExp(r'\*\*(.+?)\*\*').allMatches(text);
    var cursor = 0;

    for (final match in matcher) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start), style: style));
      }

      final boldText = match.group(1) ?? '';
      spans.add(TextSpan(text: boldText, style: _inlineBoldStyle));
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: style));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: style));
    }

    return spans;
  }

  Widget _buildFormattedLine(String rawLine) {
    final trimmed = rawLine.trim();
    if (trimmed.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasBullet = RegExp(r'^([\-*]|•)\s+').hasMatch(trimmed);
    var line = trimmed.replaceFirst(RegExp(r'^([\-*]|•)\s+'), '');
    line = line.replaceFirst(RegExp(r'^#+\s*'), '');

    final singleStarMatch = RegExp(r'^\*(.+)\*$').firstMatch(line);
    if (singleStarMatch != null) {
      line = singleStarMatch.group(1)?.trim() ?? line;
    }

    final sideHeading = _isSideHeading(line);
    final style = sideHeading ? _sideHeadingStyle : _bodyTextStyle;
    final richText = RichText(
      text: TextSpan(children: _buildInlineSpans(line, style)),
    );

    if (!hasBullet) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: richText,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 12),
            child: Icon(Icons.circle, size: 7, color: AppColors.primary),
          ),
          Expanded(child: richText),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String rawText) {
    final sanitized = _sanitizeStructuredText(rawText);
    if (sanitized.isEmpty) {
      return const Text(
        'No data available.',
        style: _bodyTextStyle,
      );
    }

    final lines = sanitized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map(_buildFormattedLine).toList(),
    );
  }

  Widget _buildContent(dynamic content) {
    if (content is String) {
      return _buildFormattedContent(content);
    } else if (content is List<String>) {
      if (content.isEmpty) {
        return const Text(
          'No points available.',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content.map((point) {
          return _buildFormattedLine('• ${_sanitizeStructuredText(point)}');
        }).toList(),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isAccessibilityEnabled = context.watch<AccessibilityProvider>().isEnabled;
    _publishScreenText(getScreenText());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Adaptive Notes',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        centerTitle: true,
        actions: [
          Row(
            children: [
              Icon(
                Icons.accessibility_new,
                size: 20,
                color: isAccessibilityEnabled ? AppColors.primary : Colors.grey,
              ),
              Switch(
                value: isAccessibilityEnabled,
                onChanged: (val) => context.read<AccessibilityProvider>().toggle(val),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mode Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildModeButton('beginner', 'Beginner', Icons.child_care_rounded),
                  _buildModeButton('exam', 'Exam', Icons.school_rounded),
                  _buildModeButton('panic', 'Panic', Icons.timer_rounded),
                  _buildModeButton('accessible', 'Accessible', Icons.accessibility_new_rounded),
                ],
              ),
            ),
            
            // Content Area
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Adapting for $_selectedMode mode...',
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionCard('Title', _title, Icons.title_rounded),
                          const SizedBox(height: 20),
                          _buildSectionCard('Main Concept', _content, Icons.summarize_rounded),
                          const SizedBox(height: 20),
                          _buildSectionCard('Key Points', _keyPoints, Icons.lightbulb_outline_rounded),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String getScreenText() {
    return buildStructuredText(
      title: _title,
      content: _content,
      keyPoints: _keyPoints,
    );
  }

  void _publishScreenText(String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccessibilityProvider>().setScreenTextIfCurrent(context, text);
    });
  }
}
