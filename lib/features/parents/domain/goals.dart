import 'package:rawdah/core/state/app_state.dart';

/// أهداف يضعها ولي الأمر للطفل، تُقاس من العدادات التراكمية.
class GoalKind {
  final String id; // اسم العداد التراكمي بعد total_
  final String label;
  final List<int> targets;
  const GoalKind(this.id, this.label, this.targets);
}

const kGoalKinds = <GoalKind>[
  GoalKind('correct', 'إجابات صحيحة', [20, 50, 100]),
  GoalKind('tower', 'ألغاز محلولة', [10, 25, 50]),
  GoalKind('activity', 'أنشطة منجزة', [5, 10, 20]),
  GoalKind('review', 'مراجعات للمحفوظ', [3, 7, 14]),
];

GoalKind? goalKindById(String id) {
  for (final k in kGoalKinds) {
    if (k.id == id) return k;
  }
  return null;
}

/// الهدف الحالي للطفل كما خُزن في عداداته.
class ChildGoal {
  final GoalKind kind;
  final int target;
  final int base;
  final int reward;
  const ChildGoal(this.kind, this.target, this.base, this.reward);

  int progress(ChildProfile c) => ((c.counters['total_${kind.id}'] ?? 0) - base).clamp(0, target);
  bool done(ChildProfile c) => progress(c) >= target;
  String get text => '${kind.label}: $target';
}

const _kKinds = ['correct', 'tower', 'activity', 'review'];

ChildGoal? goalOf(ChildProfile c) {
  final k = c.counters['goal_kind'];
  if (k == null || k < 0 || k >= _kKinds.length) return null;
  final kind = goalKindById(_kKinds[k]);
  if (kind == null) return null;
  return ChildGoal(kind, c.counters['goal_target'] ?? 1, c.counters['goal_base'] ?? 0, c.counters['goal_reward'] ?? 10);
}

void setGoal(ChildProfile c, GoalKind kind, int target, int reward) {
  c.counters['goal_kind'] = _kKinds.indexOf(kind.id);
  c.counters['goal_target'] = target;
  c.counters['goal_base'] = c.counters['total_${kind.id}'] ?? 0;
  c.counters['goal_reward'] = reward;
}

void clearGoal(ChildProfile c) {
  for (final k in ['goal_kind', 'goal_target', 'goal_base', 'goal_reward']) {
    c.counters.remove(k);
  }
}

/// نشاط آخر سبعة أيام لتقرير الوالدين: (مفتاح اليوم، إجابات صحيحة، ألغاز، أنشطة).
List<(String, int, int, int)> weekActivity(ChildProfile c, DateTime now) => [
      for (var i = 6; i >= 0; i--)
        () {
          final key = todayKey(now.subtract(Duration(days: i)));
          int v(String kind) => c.counters['dq_${key}_$kind'] ?? 0;
          return (key, v('correct'), v('tower'), v('activity'));
        }(),
    ];
