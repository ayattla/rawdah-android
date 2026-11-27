import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/content/quran_data.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/family/family_league.dart';
import 'package:rawdah/features/quizzes/data/generated_questions.dart';

void main() {
  test('بنك الأسئلة المولد صحيح ومعرفاته فريدة', () {
    final ids = kQuestions.map((q) => q.id).toSet();
    for (final q in kGeneratedQuestions) {
      expect(ids.add(q.id), true, reason: q.id);
      expect(q.answer, inInclusiveRange(0, q.options.length - 1), reason: q.id);
      expect(q.options.toSet().length, q.options.length, reason: q.id);
    }
    final fil = kGeneratedQuestions.firstWhere((q) => q.id == 'gen_ayat_105');
    expect(fil.options[fil.answer], '${kSurahs.firstWhere((s) => s.number == 105).ayat.length}');
    final ba = kGeneratedQuestions.firstWhere((q) => q.id == 'gen_dots_ث');
    expect(ba.options[ba.answer], 'ثلاث نقاط');
    expect(kGeneratedQuestions.length, greaterThan(150));
    final nx = kGeneratedQuestions.firstWhere((q) => q.id == 'gen_next_113');
    expect(nx.options[nx.answer], 'الناس');
  });

  test('ترتيب دوري العائلة', () {
    final a = ChildProfile.fromJson(const {'id': 'a', 'name': 'سارة'});
    final b = ChildProfile.fromJson(const {'id': 'b', 'name': 'عمر'});
    a.counters['mp_2026-11'] = 10;
    b.counters['mp_2026-11'] = 25;
    final r = familyRanking([a, b], '2026-11');
    expect(r.first.$1.name, 'عمر');
    expect(familyRanking([a, b], '2026-12').every((x) => x.$2 == 0), true);
    expect(monthKey(DateTime(2026, 3, 5)), '2026-03');
  });
}
