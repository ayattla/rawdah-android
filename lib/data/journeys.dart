import 'package:flutter/material.dart';

/// محطة في رحلة: نوعها ومعرّف النشاط الذي تفتحه.
/// الأنواع: story, lesson, surah, adhkar, game, quiz
class Station {
  final String type;
  final String ref; // معرّف القصة أو الدرس، أو رقم السورة، أو معرّف اللعبة
  final String title;
  final List<String> qids; // لمحطات الاختبار فقط
  const Station(this.type, this.ref, this.title, [this.qids = const []]);

  /// المعرّف الذي يُسجَّل في «completed» عند إنجاز المحطة.
  String doneId(String journeyId) {
    switch (type) {
      case 'surah':
        return 'surah_$ref';
      case 'adhkar':
        return 'adhkar';
      case 'quiz':
        return 'jq_${journeyId}_$ref';
      default:
        return ref;
    }
  }
}

class Journey {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Station> stations;
  const Journey(this.id, this.title, this.subtitle, this.icon, this.color, this.stations);
}

const List<Journey> kJourneys = [
  Journey('quran', 'رحلة القرآن', 'نحفظ قصار السور', Icons.menu_book_rounded, Color(0xFF2E7D5B), [
    Station('surah', '1', 'سورة الفاتحة'),
    Station('surah', '112', 'سورة الإخلاص'),
    Station('surah', '113', 'سورة الفلق'),
    Station('surah', '114', 'سورة الناس'),
    Station('quiz', '1', 'اختبار المحطة', ['q05', 'q06', 'q63', 'q72', 'q73']),
    Station('surah', '108', 'سورة الكوثر'),
    Station('surah', '103', 'سورة العصر'),
    Station('surah', '110', 'سورة النصر'),
    Station('surah', '106', 'سورة قريش'),
    Station('surah', '105', 'سورة الفيل'),
    Station('quiz', '2', 'الاختبار الكبير', ['q58', 'q64', 'q74', 'q25', 'q26']),
  ]),
  Journey('salah', 'رحلة الصلاة', 'من الوضوء إلى المسجد', Icons.mosque_rounded, Color(0xFF2F8FB5), [
    Station('lesson', 'lesson_wudu', 'خطوات الوضوء'),
    Station('game', 'game_wudu', 'رتّب الوضوء'),
    Station('lesson', 'lesson_salah', 'صلواتي الخمس'),
    Station('quiz', '1', 'اختبار الصلوات', ['q01', 'q27', 'q28', 'q35', 'q33']),
    Station('lesson', 'lesson_adab_masjid', 'آداب المسجد'),
    Station('game', 'game_mosque', 'ابنِ المسجد'),
    Station('quiz', '2', 'الاختبار الكبير', ['q60', 'q61', 'q62', 'q90', 'q16']),
  ]),
  Journey('seerah', 'رحلة القصص والسيرة', 'قصص من القرآن والسيرة', Icons.auto_stories_rounded, Color(0xFFE07856), [
    Station('story', 'story_fil', 'أصحاب الفيل'),
    Station('story', 'story_naml', 'النملة الحريصة'),
    Station('story', 'story_luqman', 'وصايا لقمان'),
    Station('story', 'story_yunus', 'يونس في بطن الحوت'),
    Station('story', 'story_hijra', 'في الغار'),
    Station('quiz', '1', 'اختبار السيرة', ['q23', 'q24', 'q30', 'q39', 'q70']),
  ]),
  Journey('adab', 'رحلة الأخلاق والآداب', 'نتعلم الخلق الحسن', Icons.favorite_rounded, Color(0xFF7A5BA6), [
    Station('lesson', 'lesson_adab_eat', 'آداب الطعام'),
    Station('story', 'story_tamr', 'التمرات الخمس'),
    Station('lesson', 'lesson_salam', 'السلام'),
    Station('story', 'story_amana', 'المحفظة الضائعة'),
    Station('lesson', 'lesson_birr', 'بر الوالدين'),
    Station('story', 'story_nazafa', 'يدان نظيفتان'),
    Station('adhkar', 'adhkar', 'أذكار اليوم'),
    Station('game', 'game_match', 'وصّل الذكر بوقته'),
    Station('quiz', '1', 'الاختبار الكبير', ['q02', 'q92', 'q93', 'q97', 'q18']),
  ]),
  Journey('bilad', 'رحلة بلادي', 'نتعرّف على المملكة', Icons.flag_rounded, Color(0xFF1F5A41), [
    Station('lesson', 'lesson_saudi', 'بلادي'),
    Station('lesson', 'lesson_islam', 'أركان الإسلام'),
    Station('game', 'game_memory', 'بطاقات الذاكرة'),
    Station('quiz', '1', 'اختبار بلادي', ['q29', 'q47', 'q87', 'q88', 'q09']),
  ]),
];
