import 'package:flutter_tts/flutter_tts.dart';

/// الراوي الصوتي يعمل بمحرك النطق الموجود في الجهاز، دون إنترنت.
/// يُستخدم للتعليمات والقصص والأذكار فقط.
/// لا يقرأ آيات القرآن أبدًا؛ التلاوة تُضاف بتسجيلات قارئ مرخّصة.
class Voice {
  Voice._();
  static final Voice instance = Voice._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool enabled = true;

  Future<void> _init() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('ar-SA');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(false);
    } catch (_) {}
    _ready = true;
  }

  Future<void> say(String text) async {
    if (!enabled || text.trim().isEmpty) return;
    await _init();
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
