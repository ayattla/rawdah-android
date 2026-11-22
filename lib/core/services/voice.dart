import 'package:flutter_tts/flutter_tts.dart';

/// الراوي الصوتي: يختار محرك قوقل للنطق إن وُجد، ثم أفضل صوت عربي في الجهاز.
/// السبب: بعض الجوالات تستخدم محركًا افتراضيًا بلا عربية فيقرأ النص بلغة غير مفهومة.
/// لا يقرأ آيات القرآن أبدًا؛ التلاوة تُضاف بتسجيلات قارئ مرخّصة.
class Voice {
  Voice._();
  static final Voice instance = Voice._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool enabled = true;

  /// هل يوجد صوت عربي صالح في الجهاز؟ null = لم يُفحص بعد.
  bool? arabicAvailable;
  String engineName = '';
  String voiceName = '';

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      final engines = (await _tts.getEngines as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
      if (engines.contains('com.google.android.tts')) {
        await _tts.setEngine('com.google.android.tts');
        engineName = 'Google';
      } else {
        engineName = engines.isEmpty ? '' : engines.first;
      }

      // نبحث عن صوت عربي مثبّت على الجهاز، ونفضّل السعودي ثم أي عربي.
      final voices = (await _tts.getVoices as List?) ?? const [];
      Map? best;
      var bestScore = -1;
      for (final v in voices) {
        if (v is! Map) continue;
        final locale = (v['locale'] ?? '').toString().toLowerCase();
        if (!locale.startsWith('ar')) continue;
        final name = (v['name'] ?? '').toString().toLowerCase();
        var score = 1;
        if (locale.contains('sa')) score += 3;
        if (!name.contains('network')) score += 2; // يعمل بلا إنترنت
        if (name.contains('local')) score += 1;
        if (score > bestScore) {
          bestScore = score;
          best = v;
        }
      }
      if (best != null) {
        await _tts.setVoice({'name': best['name'].toString(), 'locale': best['locale'].toString()});
        voiceName = best['name'].toString();
        arabicAvailable = true;
      } else {
        final ok = await _tts.isLanguageAvailable('ar');
        arabicAvailable = ok == true || ok == 1;
        if (arabicAvailable == true) await _tts.setLanguage('ar');
      }
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
    } catch (_) {
      arabicAvailable ??= false;
    }
  }

  Future<void> say(String text) async {
    if (!enabled || text.trim().isEmpty) return;
    await init();
    // إن لم يوجد صوت عربي لا ننطق شيئًا بدل نطق غير مفهوم.
    if (arabicAvailable == false) return;
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
