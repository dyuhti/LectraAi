import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  double _speechRate = 0.5;
  String _voiceGender = 'female';

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.25, 2.0);
    await _tts.setSpeechRate(_speechRate);
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(_speechRate);
    await _applyVoiceGender();
    await _tts.speak(text);
  }

  Future<void> pause() async {
    await _tts.pause();
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> setVoiceGender(String gender) async {
    _voiceGender = gender.toLowerCase() == 'male' ? 'male' : 'female';
    await _applyVoiceGender();
  }

  Future<void> _applyVoiceGender() async {
    final dynamic voices = await _tts.getVoices;
    if (voices is! List) return;

    final voiceList = voices
        .whereType<Map<dynamic, dynamic>>()
        .map((voice) => Map<String, dynamic>.from(voice))
        .toList();

    final enVoices = voiceList.where((voice) {
      final locale = voice['locale']?.toString().toLowerCase() ?? '';
      return locale.contains('en') && locale.contains('us');
    }).toList();

    Map<String, dynamic>? chosenVoice;

    bool matchesMale(String name) {
      final normalizedName = name.toLowerCase();
      return normalizedName.contains('male') ||
          normalizedName.contains('david') ||
          normalizedName.contains('mark') ||
          normalizedName.contains('alex');
    }

    bool matchesFemale(String name) {
      final normalizedName = name.toLowerCase();
      return normalizedName.contains('female') ||
          normalizedName.contains('woman') ||
          normalizedName.contains('zira') ||
          normalizedName.contains('samantha');
    }

    for (final voice in enVoices) {
      final name = voice['name']?.toString() ?? '';
      if (_voiceGender == 'male' ? matchesMale(name) : matchesFemale(name)) {
        chosenVoice = voice;
        break;
      }
    }

    chosenVoice ??= enVoices.isNotEmpty ? enVoices.first : null;
    if (chosenVoice == null) return;

    await _tts.setVoice(<String, String>{
      'name': chosenVoice['name']?.toString() ?? '',
      'locale': chosenVoice['locale']?.toString() ?? 'en-US',
    });
  }
}
