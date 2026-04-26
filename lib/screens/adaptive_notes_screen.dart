import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/providers/accessibility_provider.dart';
import 'package:smart_lecture_notes/models/note.dart';
import 'package:smart_lecture_notes/providers/note_provider.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/services/ai_service.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';
import 'package:smart_lecture_notes/utils/tts_text_builder.dart';

class AdaptiveNotesScreen extends StatefulWidget {
  const AdaptiveNotesScreen({Key? key}) : super(key: key);

  @override
  State<AdaptiveNotesScreen> createState() => _AdaptiveNotesScreenState();
}

class _AdaptiveNotesScreenState extends State<AdaptiveNotesScreen> {
  final AiService _aiService = AiService();

  static const TextStyle _bodyTextStyle = TextStyle(
    fontSize: 16,
    height: 1.55,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle _inlineBoldStyle = TextStyle(
    fontSize: 16,
    height: 1.55,
    color: AppColors.primaryDark,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle _sideHeadingStyle = TextStyle(
    fontSize: 16,
    height: 1.55,
    color: AppColors.primaryDark,
    fontWeight: FontWeight.w800,
  );

  String _selectedMode = 'exam';
  String? selectedNoteId;
  Note? selectedNote;

  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> loadAdaptiveNotes(Note? note) async {
    if (note == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _aiService.generateNotes(note.content, _selectedMode);
      if (!mounted) return;

      setState(() {
        _result = {
          'title': result['title']?.toString() ?? note.title,
          'content': result['content']?.toString() ?? '',
          'key_points': List<String>.from(result['key_points'] ?? const <String>[]),
        };
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate adaptive notes: $error')),
      );
    }
  }

  String _buildTtsText() {
    final result = _result;
    if (result == null) {
      return '';
    }

    final title = result['title']?.toString().trim() ?? '';
    final content = result['content']?.toString().trim() ?? '';
    final keyPoints = List<String>.from(result['key_points'] ?? const <String>[])
        .map((point) => point.trim())
        .where((point) => point.isNotEmpty)
        .toList();

    final buffer = StringBuffer();
    if (title.isNotEmpty) {
      buffer.write('Title. $title. ');
    }
    if (content.isNotEmpty) {
      buffer.write('Explanation. $content. ');
    }
    for (var index = 0; index < keyPoints.length; index++) {
      buffer.write('Point ${index + 1}. ${keyPoints[index]}. ');
    }

    return buffer.toString().trim();
  }

  String _getScreenText(List<Note> notes) {
    if (notes.isEmpty) {
      return buildStructuredText(
        title: 'Adaptive Learning',
        content: 'No saved notes available yet.',
        keyPoints: const [],
      );
    }

    if (selectedNote == null) {
      return buildStructuredText(
        title: 'Adaptive Learning',
        content: 'Please select a note to begin.',
        keyPoints: const [],
      );
    }

    final ttsText = _buildTtsText();
    if (ttsText.isNotEmpty) {
      return ttsText;
    }

    return buildStructuredText(
      title: 'Adaptive Learning',
      content: 'Select a mode to generate adaptive notes.',
      keyPoints: const ['Beginner mode', 'Exam mode', 'Panic mode'],
    );
  }

  void _publishScreenText(String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccessibilityProvider>().setScreenTextIfCurrent(
            context,
            text,
            priority: 2,
          );
    });
  }

  void _selectMode(String mode) {
    setState(() {
      _selectedMode = mode;
    });

    if (selectedNote != null) {
      loadAdaptiveNotes(selectedNote);
    }
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

  bool _isSideHeading(String line) {
    if (line.isEmpty) {
      return false;
    }
    if (line.endsWith(':')) {
      return true;
    }
    return RegExp(r'^[A-Z][A-Za-z0-9\s\-/()]{2,}$').hasMatch(line) && line.length <= 60;
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

    final textWidget = RichText(
      text: TextSpan(
        children: _buildInlineSpans(line, style),
      ),
    );

    if (!hasBullet) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: textWidget,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7, right: 8),
            child: Icon(Icons.circle, size: 7, color: AppColors.primary),
          ),
          Expanded(child: textWidget),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String rawText) {
    final sanitized = _sanitizeStructuredText(rawText);
    if (sanitized.isEmpty) {
      return const Text(
        'No content available.',
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

  Widget _buildModeChip({
    required String mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == mode;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => _selectMode(mode),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.primaryDark,
        fontWeight: FontWeight.w700,
      ),
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : AppColors.primary,
      ),
      label: Text(label),
    );
  }

  Widget _buildRevisionReminderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enable Revision Reminder',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set spaced-repetition notifications for this note.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary.withOpacity(0.9),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRoutes.revisionReminder,
                    ),
                    icon: const Icon(Icons.schedule_rounded, size: 16),
                    label: const Text('Configure'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateContent({
    required String message,
    required bool needsBottomClearance,
    bool isLoading = false,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        needsBottomClearance ? 140 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          _buildRevisionReminderCard(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NoteProvider>().notes;
    _publishScreenText(_getScreenText(notes));

    final needsBottomClearance = context.watch<AccessibilityProvider>().isEnabled;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Adaptive Learning',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: AppColors.primary.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                icon: const Icon(Icons.settings_outlined),
                color: AppColors.primaryDark,
                tooltip: 'Settings',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              color: Colors.white,
              child: DropdownButton<String>(
                value: selectedNoteId,
                hint: const Text('Select Note'),
                isExpanded: true,
                items: notes.map((note) {
                  return DropdownMenuItem<String>(
                    value: note.id,
                    child: Text(
                      note.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  final matchedNotes = notes.where((n) => n.id == value).toList();
                  final note = matchedNotes.isNotEmpty ? matchedNotes.first : null;

                  setState(() {
                    selectedNoteId = value;
                    selectedNote = note;
                    _result = null;
                  });

                  loadAdaptiveNotes(selectedNote);
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              color: Colors.white,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildModeChip(
                    mode: 'beginner',
                    label: 'Beginner',
                    icon: Icons.child_care_rounded,
                  ),
                  _buildModeChip(
                    mode: 'exam',
                    label: 'Exam',
                    icon: Icons.school_rounded,
                  ),
                  _buildModeChip(
                    mode: 'panic',
                    label: 'Panic',
                    icon: Icons.timer_rounded,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (notes.isEmpty) {
                    return _buildStateContent(
                      message: 'No saved notes available yet',
                      needsBottomClearance: needsBottomClearance,
                    );
                  }

                  if (selectedNote == null) {
                    return _buildStateContent(
                      message: 'Please select a note to begin',
                      needsBottomClearance: needsBottomClearance,
                    );
                  }

                  if (_isLoading) {
                    return _buildStateContent(
                      message: 'Generating adaptive notes...',
                      needsBottomClearance: needsBottomClearance,
                      isLoading: true,
                    );
                  }

                  if (_result == null) {
                    return _buildStateContent(
                      message: 'Select a mode to generate adaptive notes',
                      needsBottomClearance: needsBottomClearance,
                    );
                  }

                  final title = _result?['title']?.toString() ?? '';
                  final content = _result?['content']?.toString() ?? '';
                  final keyPoints = List<String>.from(
                    _result?['key_points'] ?? const <String>[],
                  );

                  final adaptiveCard = Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.95),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Adaptive Notes',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primaryDark,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Smart learning customized for you',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary.withOpacity(0.8),
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildFormattedContent(content),
                          const SizedBox(height: 14),
                          if (keyPoints.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Key Takeaways',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green.shade700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: keyPoints
                                        .map<Widget>((p) => Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                      top: 3,
                                                      right: 8,
                                                    ),
                                                    child: Icon(
                                                      Icons.check_circle_rounded,
                                                      size: 16,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      _sanitizeStructuredText(p),
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w500,
                                                        color: AppColors.textPrimary,
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          _buildRevisionReminderCard(),
                        ],
                      ),
                    ),
                  );

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: needsBottomClearance ? 140 : 28,
                    ),
                    child: adaptiveCard,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
