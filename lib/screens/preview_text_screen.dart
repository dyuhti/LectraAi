import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';
import 'package:smart_lecture_notes/services/ai_service.dart';
import 'package:smart_lecture_notes/providers/accessibility_provider.dart';

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
  String get _ttsText => '$_title. $_content. ${_keyPoints.join('. ')}';

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

  Widget _buildContent(dynamic content) {
    if (content is String) {
      return Text(
        content.isEmpty ? 'No data available.' : content,
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (content is List<String>) {
      if (content.isEmpty) {
        return const Text(
          'No points available.',
          style: TextStyle(color: AppColors.textSecondary),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content.map((point) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6.0, right: 12.0),
                  child: Icon(Icons.circle, size: 8, color: AppColors.primary),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
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
    return '$_title $_content ${_keyPoints.join(' ')}';
  }

  void _publishScreenText(String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccessibilityProvider>().setScreenText(text);
    });
  }
}
