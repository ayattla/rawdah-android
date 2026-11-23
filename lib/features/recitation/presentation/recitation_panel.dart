import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/design_system/quran_text.dart';
import 'package:rawdah/features/recitation/domain/recitation_plan.dart';
import 'package:rawdah/features/recitation/presentation/recitation_controller.dart';

/// لوحة التلاوة أسفل صفحة السورة: تشغيل بصوت الشيخ، تكرار، «ردّد بعدي»، نطاق آيات، وتنزيل.
class RecitationPanel extends ConsumerWidget {
  final RecitationArgs args;
  const RecitationPanel({super.key, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(recitationControllerProvider(args));
    final c = ref.read(recitationControllerProvider(args).notifier);
    final o = s.options;
    final active = s.isActive;

    return Container(
      padding: const EdgeInsets.fromLTRB(RS.lg, RS.md, RS.lg, RS.lg),
      decoration: BoxDecoration(
        color: RC.paper,
        borderRadius: BorderRadius.circular(RS.radiusLg),
        border: Border.all(color: RC.sandDark, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          _PlayButton(
            playing: active,
            busy: s.status == RecitationStatus.preparing,
            onTap: active ? c.pause : c.play,
          ),
          const SizedBox(width: RS.md),
          Expanded(child: _StatusText(state: s)),
          if (active || s.status == RecitationStatus.paused)
            IconButton(
              tooltip: 'إيقاف التلاوة',
              iconSize: 30,
              constraints: const BoxConstraints(minWidth: RS.minTouch, minHeight: RS.minTouch),
              color: RC.inkSoft,
              onPressed: c.stop,
              icon: const Icon(Icons.stop_circle_rounded),
            ),
        ]),
        const SizedBox(height: RS.md),
        _Label('طريقة الاستماع'),
        Wrap(spacing: RS.sm, runSpacing: RS.sm, children: [
          FilterChip(
            selected: o.echo,
            showCheckmark: false,
            avatar: Icon(Icons.record_voice_over_rounded, size: 20, color: o.echo ? RC.paper : RC.green),
            label: const Text('ردّد بعدي'),
            selectedColor: RC.green,
            labelStyle: TextStyle(color: o.echo ? RC.paper : RC.ink, fontWeight: FontWeight.w700),
            onSelected: (v) => c.setOptions(echo: v),
          ),
          for (final n in const [1, 3, 5])
            ChoiceChip(
              selected: o.repeatEach == n,
              showCheckmark: false,
              label: Text(n == 1 ? 'مرة واحدة' : 'كل آية ${arabicNumber(n)} مرات'),
              selectedColor: RC.sea,
              labelStyle: TextStyle(color: o.repeatEach == n ? RC.paper : RC.ink, fontWeight: FontWeight.w700),
              onSelected: (_) => c.setOptions(repeatEach: n),
            ),
        ]),
        const SizedBox(height: RS.md),
        _Label('الآيات'),
        Row(children: [
          const Text('من', style: TextStyle(fontSize: 17, color: RC.ink)),
          const SizedBox(width: RS.sm),
          _AyahPicker(
            value: o.from,
            max: args.ayahCount,
            semantics: 'من الآية',
            onChanged: (v) => c.setOptions(from: v, to: o.to < v ? v : null),
          ),
          const SizedBox(width: RS.md),
          const Text('إلى', style: TextStyle(fontSize: 17, color: RC.ink)),
          const SizedBox(width: RS.sm),
          _AyahPicker(
            value: o.to,
            min: o.from,
            max: args.ayahCount,
            semantics: 'إلى الآية',
            onChanged: (v) => c.setOptions(to: v),
          ),
          const Spacer(),
          if (o.from != 1 || o.to != args.ayahCount)
            TextButton(
              onPressed: () => c.setOptions(from: 1, to: args.ayahCount),
              child: const Text('السورة كلها'),
            ),
        ]),
        const SizedBox(height: RS.md),
        _Label('القارئ'),
        SegmentedButton<Reciter>(
          showSelectedIcon: false,
          segments: [for (final r in Reciter.values) ButtonSegment(value: r, label: Text(r.label))],
          selected: {s.reciter},
          onSelectionChanged: (v) => c.setReciter(v.first),
        ),
        const SizedBox(height: RS.md),
        _OfflineRow(state: s, onDownload: c.download),
        if (s.error != null) ...[
          const SizedBox(height: RS.sm),
          Text(s.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: RC.coral, fontWeight: FontWeight.w700)),
        ],
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: RS.xs),
        child: Text(text, style: const TextStyle(fontSize: 15, color: RC.inkSoft, fontWeight: FontWeight.w700)),
      );
}

class _PlayButton extends StatelessWidget {
  final bool playing;
  final bool busy;
  final VoidCallback onTap;
  const _PlayButton({required this.playing, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playing ? 'إيقاف مؤقت للتلاوة' : 'استمع للتلاوة',
      excludeSemantics: true,
      child: Material(
        color: RC.green,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 68,
            height: 68,
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(strokeWidth: 3, color: RC.paper),
                  )
                : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 42, color: RC.paper),
          ),
        ),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  final RecitationState state;
  const _StatusText({required this.state});

  @override
  Widget build(BuildContext context) {
    final a = state.highlight;
    final rep = state.options.repeatEach;
    final count = rep > 1 ? 'المرة ${arabicNumber(state.repeatIndex + 1)} من ${arabicNumber(rep)}' : null;
    final (String title, String? sub) = switch (state.status) {
      RecitationStatus.preparing => ('نجهّز التلاوة…', null),
      RecitationStatus.playing => (a == null ? 'بسم الله الرحمن الرحيم' : 'الشيخ يقرأ الآية ${arabicNumber(a)}', count),
      RecitationStatus.echo => ('دورك! ردّد الآية ${arabicNumber(a ?? 1)}', 'اقرأها بصوتك كما سمعتها'),
      RecitationStatus.paused => ('التلاوة متوقفة', 'اضغط للمتابعة'),
      RecitationStatus.error => ('لم تعمل التلاوة', null),
      RecitationStatus.idle => (
          state.finishedRuns > 0 ? 'أحسنت! انتهت التلاوة' : 'استمع للسورة بصوت الشيخ الحصري',
          'المس أي آية لتبدأ منها',
        ),
    };
    return Semantics(
      liveRegion: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: RC.ink)),
        if (sub != null) Text(sub, style: const TextStyle(fontSize: 14, color: RC.inkSoft)),
      ]),
    );
  }
}

class _AyahPicker extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final String semantics;
  final ValueChanged<int> onChanged;
  const _AyahPicker({required this.value, required this.max, required this.onChanged, required this.semantics, this.min = 1});

  @override
  Widget build(BuildContext context) {
    final lo = min.clamp(1, max);
    return Semantics(
      label: semantics,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: RS.sm),
        decoration: BoxDecoration(color: RC.sand, borderRadius: BorderRadius.circular(RS.radiusSm)),
        child: DropdownButton<int>(
          value: value.clamp(lo, max),
          underline: const SizedBox.shrink(),
          borderRadius: BorderRadius.circular(RS.radiusSm),
          style: const TextStyle(fontSize: 18, color: RC.ink, fontWeight: FontWeight.w700, fontFamily: 'Baloo'),
          items: [
            for (var i = lo; i <= max; i++) DropdownMenuItem(value: i, child: Text(arabicNumber(i))),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _OfflineRow extends StatelessWidget {
  final RecitationState state;
  final Future<bool> Function() onDownload;
  const _OfflineRow({required this.state, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final p = state.downloadProgress;
    if (p != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('ننزّل التلاوة… ${arabicNumber((p * 100).round())}٪',
            style: const TextStyle(fontSize: 15, color: RC.inkSoft)),
        const SizedBox(height: RS.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: p, minHeight: 10, color: RC.green, backgroundColor: RC.sand),
        ),
      ]);
    }
    if (state.offlineReady == true) {
      return const Row(children: [
        Icon(Icons.offline_pin_rounded, color: RC.garden),
        SizedBox(width: RS.sm),
        Expanded(child: Text('محفوظة على الجهاز، تعمل بلا إنترنت', style: TextStyle(fontSize: 15, color: RC.garden))),
      ]);
    }
    if (state.offlineReady == false) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(RS.minTouch)),
        onPressed: onDownload,
        icon: const Icon(Icons.download_rounded),
        label: const Text('احفظها على الجهاز لتعمل بلا إنترنت'),
      );
    }
    return const SizedBox.shrink();
  }
}
