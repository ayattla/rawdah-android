/// خطة التلاوة: قائمة خطوات صافية (بلا صوت ولا شبكة) يسهل اختبارها.
/// كل خطوة إما تشغيل آية من تسجيل القارئ، أو مهلة صامتة يردّد فيها الطفل بعد الشيخ.
library;

/// القرّاء المتاحون. التسجيلات آية آية من مصحف المدينة برواية حفص.
enum Reciter {
  /// الحصري مرتّلًا.
  husary('الحصري — مرتّل', 'Husary_128kbps', 'Husary'),

  /// الحصري المعلّم: أبطأ ويناسب الصغار.
  husaryMuallim('الحصري — المعلّم', 'Husary_Muallim_128kbps', null);

  final String label;

  /// مجلد everyayah.com.
  final String everyAyahFolder;

  /// مجلد احتياطي على خادم صوتيات Quran.com (إن وُجد).
  final String? quranComFolder;
  const Reciter(this.label, this.everyAyahFolder, this.quranComFolder);

  static Reciter byName(String? name) =>
      Reciter.values.firstWhere((r) => r.name == name, orElse: () => Reciter.husaryMuallim);
}

String _pad3(int n) => n.toString().padLeft(3, '0');

/// اسم ملف الآية بالصيغة المعتمدة: 001001.mp3
String ayahFileName(int surah, int ayah) => '${_pad3(surah)}${_pad3(ayah)}.mp3';

/// روابط التسجيل بالترتيب: الأساسي ثم الاحتياطي ثم الحصري المرتّل احتياطًا أخيرًا.
List<String> ayahUrls(Reciter r, int surah, int ayah) {
  final f = ayahFileName(surah, ayah);
  final urls = <String>['https://everyayah.com/data/${r.everyAyahFolder}/$f'];
  if (r.quranComFolder != null) urls.add('https://verses.quran.com/${r.quranComFolder}/mp3/$f');
  if (r != Reciter.husary) urls.addAll(ayahUrls(Reciter.husary, surah, ayah));
  return urls;
}

sealed class RecitationStep {
  const RecitationStep();
}

/// تشغيل آية. [surah]=1 و[ayah]=1 مع [isBasmala] تعني البسملة قبل السورة.
class PlayAyah extends RecitationStep {
  final int surah;
  final int ayah;

  /// رقم الآية داخل السورة المعروضة (للتظليل)، أو null للبسملة.
  final int? displayAyah;
  final int repeatIndex;
  const PlayAyah(this.surah, this.ayah, {this.displayAyah, this.repeatIndex = 0});

  bool get isBasmala => displayAyah == null;

  @override
  bool operator ==(Object o) =>
      o is PlayAyah && o.surah == surah && o.ayah == ayah && o.displayAyah == displayAyah && o.repeatIndex == repeatIndex;
  @override
  int get hashCode => Object.hash(surah, ayah, displayAyah, repeatIndex);
  @override
  String toString() => 'Play($surah:$ayah${isBasmala ? ' basmala' : ''} r$repeatIndex)';
}

/// مهلة صامتة بطول الآية السابقة مضروبًا في [factor] ليردّد الطفل.
class EchoGap extends RecitationStep {
  final int displayAyah;
  final double factor;
  const EchoGap(this.displayAyah, this.factor);

  @override
  bool operator ==(Object o) => o is EchoGap && o.displayAyah == displayAyah && o.factor == factor;
  @override
  int get hashCode => Object.hash(displayAyah, factor);
  @override
  String toString() => 'Gap($displayAyah x$factor)';
}

class RecitationOptions {
  final int surah;
  final int ayahCount;
  final int from;
  final int to;

  /// كم مرة تُعاد كل آية (١..١٠).
  final int repeatEach;

  /// «ردّد بعدي»: مهلة بعد كل تكرار.
  final bool echo;

  /// كم مرة يُعاد المقطع كاملًا (١..٥).
  final int rounds;
  final bool basmala;

  const RecitationOptions({
    required this.surah,
    required this.ayahCount,
    int? from,
    int? to,
    this.repeatEach = 1,
    this.echo = false,
    this.rounds = 1,
    this.basmala = true,
  })  : from = from ?? 1,
        to = to ?? ayahCount;

  RecitationOptions copyWith({int? from, int? to, int? repeatEach, bool? echo, int? rounds, bool? basmala}) =>
      RecitationOptions(
        surah: surah,
        ayahCount: ayahCount,
        from: from ?? this.from,
        to: to ?? this.to,
        repeatEach: repeatEach ?? this.repeatEach,
        echo: echo ?? this.echo,
        rounds: rounds ?? this.rounds,
        basmala: basmala ?? this.basmala,
      );
}

/// يبني الخطة مع تصحيح القيم الخارجة عن الحدود.
List<RecitationStep> buildPlan(RecitationOptions o) {
  if (o.ayahCount <= 0) return const [];
  final from = o.from.clamp(1, o.ayahCount);
  final to = o.to.clamp(from, o.ayahCount);
  final repeat = o.repeatEach.clamp(1, 10);
  final rounds = o.rounds.clamp(1, 5);
  final steps = <RecitationStep>[];
  // البسملة قبل أول السورة فقط، ولا بسملة في الفاتحة (هي آيتها الأولى) ولا في التوبة.
  final withBasmala = o.basmala && from == 1 && o.surah != 1 && o.surah != 9;
  for (var round = 0; round < rounds; round++) {
    if (withBasmala) steps.add(const PlayAyah(1, 1));
    for (var a = from; a <= to; a++) {
      for (var r = 0; r < repeat; r++) {
        steps.add(PlayAyah(o.surah, a, displayAyah: a, repeatIndex: r));
        if (o.echo) steps.add(EchoGap(a, 1.15));
      }
    }
  }
  return steps;
}

/// الملفات المطلوبة لتنزيل السورة كاملة للعمل بلا إنترنت (مع البسملة).
List<({int surah, int ayah})> filesForSurah(int surah, int ayahCount) => [
      if (surah != 1 && surah != 9) (surah: 1, ayah: 1),
      for (var a = 1; a <= ayahCount; a++) (surah: surah, ayah: a),
    ];
