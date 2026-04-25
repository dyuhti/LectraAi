import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsVoice {
  const TtsVoice({
    required this.name,
    required this.locale,
  });

  final String name;
  final String locale;

  @override
  String toString() => '$name ($locale)';
}

class AccessibilityTtsService {
  final FlutterTts _tts = FlutterTts();

  Future<void> initialize({
    VoidCallback? onStart,
    VoidCallback? onComplete,
    VoidCallback? onPause,
    VoidCallback? onCancel,
  }) async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setVolume(1.0);

    _tts.setStartHandler(() {
      onStart?.call();
    });

    _tts.setCompletionHandler(() {
      onComplete?.call();
    });

    _tts.setPauseHandler(() {
      onPause?.call();
    });

    _tts.setCancelHandler(() {
      onCancel?.call();
    });
  }

  Future<List<String>> getLanguages() async {
    final dynamic languages = await _tts.getLanguages;
    if (languages is List) {
      return languages.map((dynamic item) => item.toString()).toList();
    }
    return <String>[];
  }

  Future<List<TtsVoice>> getVoices() async {
    final dynamic rawVoices = await _tts.getVoices;
    if (rawVoices is! List) {
      return <TtsVoice>[];
    }

    return rawVoices
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> voice) {
          final name = voice['name']?.toString() ?? 'Default Voice';
          final locale = voice['locale']?.toString() ?? 'unknown';
          return TtsVoice(name: name, locale: locale);
        })
        .toList();
  }

  Future<void> setLanguage(String language) async {
    await _tts.setLanguage(language);
  }

  Future<void> setVoice(TtsVoice voice) async {
    await _tts.setVoice(<String, String>{
      'name': voice.name,
      'locale': voice.locale,
    });
  }

  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(0.2, 1.0));
  }

  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch.clamp(0.5, 2.0));
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.speak(text);
  }

  Future<void> pause() async {
    try {
      await _tts.pause();
    } catch (_) {
      await _tts.stop();
    }
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
