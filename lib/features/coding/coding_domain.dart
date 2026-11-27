import 'dart:math';

/// المبرمج الصغير: يكتب الطفل أوامر توصل الصاروخ إلى الراية.
enum Cmd { forward, left, right }

class Pos {
  final int x, y;
  const Pos(this.x, this.y);
  @override
  bool operator ==(Object o) => o is Pos && o.x == x && o.y == y;
  @override
  int get hashCode => x * 31 + y;
}

const _dx = [0, 1, 0, -1], _dy = [-1, 0, 1, 0]; // 0 أعلى، 1 يمين، 2 أسفل، 3 يسار

class CodeLevel {
  final int size;
  final Pos start;
  final int dir;
  final Pos target;
  final Set<Pos> rocks;
  final List<Cmd> solution;
  const CodeLevel(this.size, this.start, this.dir, this.target, this.rocks, this.solution);
  int get maxCmds => solution.length + 2;
}

class RunResult {
  final List<(Pos, int)> trail; // الموقع والاتجاه بعد كل أمر
  final bool reached;
  final bool crashed;
  const RunResult(this.trail, this.reached, this.crashed);
}

RunResult runProgram(CodeLevel l, List<Cmd> prog) {
  var p = l.start, d = l.dir;
  final trail = <(Pos, int)>[];
  for (final c in prog) {
    if (c == Cmd.left) d = (d + 3) % 4;
    if (c == Cmd.right) d = (d + 1) % 4;
    if (c == Cmd.forward) {
      final n = Pos(p.x + _dx[d], p.y + _dy[d]);
      if (n.x < 0 || n.y < 0 || n.x >= l.size || n.y >= l.size || l.rocks.contains(n)) {
        trail.add((p, d));
        return RunResult(trail, false, true);
      }
      p = n;
    }
    trail.add((p, d));
    if (p == l.target) return RunResult(trail, true, false);
  }
  return RunResult(trail, p == l.target, false);
}

CodeLevel makeLevel(int level, Random r) {
  final size = min(7, 4 + level ~/ 4);
  final moves = min(3 + level, 14);
  while (true) {
    final start = Pos(r.nextInt(size), r.nextInt(size));
    var p = start, d = r.nextInt(4);
    final startDir = d;
    final seen = {start};
    final sol = <Cmd>[];
    var forwards = 0, guard = 0;
    while (forwards < moves && guard++ < 60) {
      // أحيانا نلف قبل التقدم، والمستويات العليا تلف أكثر
      if (r.nextInt(10) < min(2 + level ~/ 3, 5)) {
        final turn = r.nextBool() ? Cmd.left : Cmd.right;
        final nd = turn == Cmd.left ? (d + 3) % 4 : (d + 1) % 4;
        final n = Pos(p.x + _dx[nd], p.y + _dy[nd]);
        if (n.x >= 0 && n.y >= 0 && n.x < size && n.y < size && !seen.contains(n)) {
          sol.add(turn);
          d = nd;
        }
      }
      final n = Pos(p.x + _dx[d], p.y + _dy[d]);
      if (n.x < 0 || n.y < 0 || n.x >= size || n.y >= size || seen.contains(n)) continue;
      sol.add(Cmd.forward);
      p = n;
      seen.add(n);
      forwards++;
    }
    if (forwards < min(2, moves) || p == start) continue;
    final rocks = <Pos>{};
    final want = min(level ~/ 2, size * size ~/ 4);
    var tries = 0;
    while (rocks.length < want && tries++ < 200) {
      final q = Pos(r.nextInt(size), r.nextInt(size));
      if (!seen.contains(q)) rocks.add(q);
    }
    return CodeLevel(size, start, startDir, p, rocks, sol);
  }
}
