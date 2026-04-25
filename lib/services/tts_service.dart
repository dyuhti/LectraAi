import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reusable Text-to-Speech service.
/// Always uses en-US. Supports male/female voice switching.
class TtsService {
  final FlutterTts _tts = FlutterTts();

  bool isPlaying = false;
  double speechRate = 0.5;
  String voiceGender = 'female';

  VoidCallback? onPlayingChanged;

  Future<void> initialize({VoidCallback? onStateChanged}) async {
    onPlayingChanged = onStateChanged;

    _tts.setStartHandler(() {
      isPlaying = true;
      onPlayingChanged?.call();
    });

    _tts.setCompletionHandler(() {
      isPlaying = false;
      onPlayingChanged?.call();
    });

    _tts.setCancelHandler(() {
      isPlaying = false;
      onPlayingChanged?.call();
    });

    _tts.setPauseHandler(() {
      isPlaying = false;
      onPlayingChanged?.call();
    });

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(speechRate);
  }

  Future<void> _applyVoice() async {
    await _tts.setLanguage('en-US');
    try {
      final voices = await _tts.getVoices;
      if (voices == null) return;

      final voiceList = List<Map<Object?, Object?>>.from(voices);

      // Filter to en-US voices only
      final enVoices = voiceList.where((v) {
        final locale = v['locale']?.toString().toLowerCase() ?? '';
        return locale.contains('en') && locale.contains('us');
      }).toList();

      Map<Object?, Object?>? chosen;

      for (final v in enVoices) {
        final name = v['name']?.toString().toLowerCase() ?? '';
        if (voiceGender == 'male' &&
            (name.contains('male') || name.contains('guy') || name.contains('david'))) {
          chosen = v;
          break;
        }
        if (voiceGender == 'female' &&
            (name.contains('female') || name.contains('woman') ||
                name.contains('zira') || name.contains('samantha'))) {
          chosen = v;
          break;
        }
      }

      // Fallback: use first en-US voice
      chosen ??= enVoices.isNotEmpty ? enVoices.first : null;

      if (chosen != null) {
        await _tts.setVoice({
          'name': chosen['name']?.toString() ?? '',
          'locale': chosen['locale']?.toString() ?? 'en-US',
        });
      }
    } catch (e) {
      debugPrint('[TtsService] Voice selection failed, using default: $e');
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _applyVoice();
    await _tts.setSpeechRate(speechRate);
    await _tts.speak(text);
  }

  Future<void> pause() async {
    await _tts.pause();
    isPlaying = false;
    onPlayingChanged?.call();
  }

  Future<void> stop() async {
    await _tts.stop();
    isPlaying = false;
    onPlayingChanged?.call();
  }

  Future<void> setSpeechRate(double rate) async {
    speechRate = rate;
    await _tts.setSpeechRate(rate);
  }

  void setVoiceGender(String gender) {
    voiceGender = gender;
  }

  void dispose() {
    _tts.stop();
  }
}
