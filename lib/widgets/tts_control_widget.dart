import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/services/accessibility_tts_service.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

/// Reusable TTS control widget. Drop into any screen with:
///   TtsControlWidget(text: "your content here")
class TtsControlWidget extends StatefulWidget {
  final String text;

  const TtsControlWidget({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  State<TtsControlWidget> createState() => _TtsControlWidgetState();
}

class _TtsControlWidgetState extends State<TtsControlWidget> {
  static const double _sheetViewportFactor = 0.65;
  static const double _sheetCollapsedSize = 0.08;
  static const double _sheetExpandedSize = 0.5;
  static const double _sheetCollapseThreshold = 0.1;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TtsService _tts = TtsService();
  double _speechRate = 0.5;
  bool _isPlaying = false;
  bool _isExpanded = false;
  double _lastExtent = _sheetCollapsedSize;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetSizeChanged);
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetSizeChanged);
    _sheetController.dispose();
    super.dispose();
  }

  void _onSheetSizeChanged() {
    if (!_sheetController.isAttached || !mounted) {
      return;
    }

    final extent = _sheetController.size;
    final isExpandedNow = extent > _sheetCollapseThreshold;

    if ((extent - _lastExtent).abs() < 0.01 && isExpandedNow == _isExpanded) {
      return;
    }

    setState(() {
      _lastExtent = extent;
      _isExpanded = isExpandedNow;
    });
  }

  Future<void> _toggleSheet() async {
    if (!_sheetController.isAttached) {
      return;
    }

    final target = _isExpanded ? _sheetCollapsedSize : _sheetExpandedSize;

    await _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onPlay() async {
    if (!mounted) return;
    setState(() => _isPlaying = true);
    await _tts.speak(widget.text);
  }

  Future<void> _onPause() async {
    await _tts.pause();
    if (!mounted) return;
    setState(() => _isPlaying = false);
  }

  Future<void> _onStop() async {
    await _tts.stop();
    if (!mounted) return;
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height * _sheetViewportFactor;
    return SizedBox(
      height: viewportHeight,
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          final isExpandedNow = notification.extent > _sheetCollapseThreshold;
          if (isExpandedNow != _isExpanded) {
            setState(() => _isExpanded = isExpandedNow);
          }
          if ((notification.extent - _lastExtent).abs() > 0.01) {
            _lastExtent = notification.extent;
          }
          return false;
        },
        child: DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: _sheetCollapsedSize,
          minChildSize: _sheetCollapsedSize,
          maxChildSize: _sheetExpandedSize,
          snap: true,
          snapAnimationDuration: const Duration(milliseconds: 250),
          snapSizes: const [_sheetCollapsedSize, _sheetExpandedSize],
          expand: false,
          builder: (context, scrollController) {
            return _buildSurface(
              child: ListView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: _buildSheetChildren(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleSheet,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurface({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x33234DB9),
            blurRadius: 36,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        elevation: 0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  List<Widget> _buildSheetChildren() {
    final children = <Widget>[_buildDragHandle()];
    if (!_isExpanded) {
      return children;
    }

    children.addAll([
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.volume_up_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Voice Controls',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const Divider(height: 1, color: AppColors.border),
      const SizedBox(height: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Playback Speed',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.primaryDark,
                  letterSpacing: 0.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_speechRate.toStringAsFixed(1)}x',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: const SliderThemeData(
              trackHeight: 6,
              thumbShape: RoundSliderThumbShape(
                elevation: 2,
                enabledThumbRadius: 8,
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: 14,
              ),
            ),
            child: Slider(
              value: _speechRate,
              min: 0.20,
              max: 2.0,
              divisions: 7,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.primary.withOpacity(0.2),
              onChanged: (val) {
                setState(() => _speechRate = val);
                _tts.setSpeechRate(val);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            Icons.stop_circle_rounded,
            AppColors.textSecondary,
            44,
            _onStop,
            tooltip: 'Stop',
          ),
          const SizedBox(width: 20),
          AnimatedScale(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            scale: _isPlaying ? 1.08 : 1,
            child: _buildControlButton(
              _isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              AppColors.primary,
              60,
              _isPlaying ? _onPause : _onPlay,
              tooltip: _isPlaying ? 'Pause' : 'Play',
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
    ]);

    return children;
  }

  Widget _buildControlButton(
    IconData icon,
    Color color,
    double size,
    VoidCallback onPressed, {
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              icon,
              color: color,
              size: size,
            ),
          ),
        ),
      ),
    );
  }

}
