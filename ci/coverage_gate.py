"""بوابة التغطية: تحسب نسبة الأسطر المختبَرة من coverage/lcov.info.

- «طبقة المنطق» (المجالات، البيانات، الحالة، القفل الأبوي): يجب ألا تقل عن الحد (80%).
- التطبيق كله: تُعرض للمتابعة فقط (الشاشات تُراجع بلقطات الشاشة الآلية).
"""
import os
import re
import sys

THRESHOLD = float(os.environ.get("COVERAGE_MIN", "80"))
LOGIC = [
    r"^lib/core/(data|parental|perf|state)/",
    r"^lib/core/content/names\.dart$",
    r"^lib/core/storage/",
    r"^lib/features/[^/]+/domain/",
    r"^lib/features/quizzes/data/",
    r"^lib/features/competition/data/cached_competition_repository\.dart$",
    r"^lib/features/quizzes/presentation/quiz_controller\.dart$",
    r"^lib/features/recitation/data/ayah_cache(_io)?\.dart$",
    r"^lib/features/recitation/presentation/recitation_controller\.dart$",
]
# مغلّفات لمكتبات النظام لا تعمل خارج الجهاز (تُختبر بالتجربة الفعلية)
EXCLUDE = [r"HiveLocalStore", r"JustAudioAyahPlayer"]

files = {}
cur = None
with open("coverage/lcov.info", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if line.startswith("SF:"):
            cur = os.path.relpath(line[3:]).replace("\\", "/")
            files.setdefault(cur, {})
        elif line.startswith("DA:") and cur:
            n, hits = line[3:].split(",")[:2]
            files[cur][int(n)] = files[cur].get(int(n), 0) + int(hits)


def excluded_lines(path):
    """أسطر الأصناف المستثناة داخل الملف."""
    out = set()
    try:
        src = open(path, encoding="utf-8").read().split("\n")
    except OSError:
        return out
    inside = False
    depth = 0
    for i, l in enumerate(src, 1):
        if not inside and any(re.search(r"class " + e + r"\b", l) for e in EXCLUDE):
            inside, depth = True, 0
        if inside:
            out.add(i)
            depth += l.count("{") - l.count("}")
            if depth <= 0 and "}" in l:
                inside = False
    return out


def pct(paths):
    hit = total = 0
    for p in paths:
        skip = excluded_lines(p)
        for n, h in files[p].items():
            if n in skip:
                continue
            total += 1
            hit += 1 if h > 0 else 0
    return (100.0 * hit / total if total else 100.0), hit, total


logic = [p for p in files if any(re.search(r, p) for r in LOGIC)]
everything = [p for p in files if p.startswith("lib/")]
lp, lh, lt = pct(logic)
ap, ah, at = pct(everything)

rows = ["| الطبقة | الأسطر المختبرة | النسبة |", "|---|---|---|",
        f"| المنطق (البوابة ≥ {THRESHOLD:.0f}%) | {lh}/{lt} | **{lp:.1f}%** |",
        f"| التطبيق كله (للمتابعة) | {ah}/{at} | {ap:.1f}% |", "", "| ملف المنطق | النسبة |", "|---|---|"]
for p in sorted(logic):
    fp, fh, ft = pct([p])
    rows.append(f"| `{p}` | {fp:.0f}% ({fh}/{ft}) |")
report = "\n".join(["### تغطية الاختبارات", ""] + rows) + "\n"
print(report)
summary = os.environ.get("GITHUB_STEP_SUMMARY")
if summary:
    with open(summary, "a", encoding="utf-8") as f:
        f.write(report)
if lp < THRESHOLD:
    print(f"::error::تغطية طبقة المنطق {lp:.1f}% أقل من {THRESHOLD:.0f}%")
    sys.exit(1)
