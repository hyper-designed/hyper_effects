// Probe: confirm the rolled row's intrinsic height + reported
// baseline DRIFT during animation (progress 0.0 → 1.0). If the
// box height/baseline changes mid-roll, parent widgets that lay
// out by box bounds (Row(crossAxisAlignment: center) — i.e. the
// LikeButton story) shift the rolled text vertically per frame.
//
// The drift is caused by `_resolveRowGeometry` taking
// `maxAscent = max(perSlot lineAscent)` where each slot's
// `lineAscent`/`lineDescent` is LERPED by progress (and per-slot
// stagger). For a roll that goes between glyphs with different
// metrics (most obviously emoji ↔ letter), the row height moves
// even though endpoints are baseline-parity with a plain Text.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  testWidgets('rolled row height/baseline drifts through progress',
      (tester) async {
    // Sweep progress 0.0 → 1.0 in 11 stops, capture rolled
    // size+baseline at each.
    final results = <(double, Size, double?)>[];
    for (final p in List.generate(11, (i) => i / 10.0)) {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.noScaling),
              child: Scaffold(
                body: Center(
                  child: EffectQuery(
                    linearValue: p,
                    curvedValue: p,
                    isTransition: false,
                    child: KeyedSubtree(
                      key: key,
                      child: const Text(
                        'Share',
                        style: TextStyle(
                          fontFamily: 'TestLatin',
                          fontSize: 16,
                        ),
                      ).roll(symbolDistanceMultiplier: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // post-frame swap to drive the animation target.
      await tester.pumpAndSettle();
      final rb = key.currentContext!.findRenderObject() as RenderBox;
      final baseline = rb.getDryBaseline(rb.constraints, TextBaseline.alphabetic);
      results.add((p, rb.size, baseline));
    }
    // ignore: avoid_print
    print('=== Static rolled (no transition) progress sweep ===');
    for (final r in results) {
      // ignore: avoid_print
      print('  p=${r.$1.toStringAsFixed(2)}  size=${r.$2}  baseline=${r.$3}');
    }
  });

  testWidgets('Share→Thanks! mid-transition height drift', (tester) async {
    // This actually triggers a transition: mount with 'Share',
    // then change to 'Thanks!' via setState on the next frame and
    // capture at intermediate progress values.
    for (final p in const [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.noScaling),
              child: Scaffold(
                body: Center(
                  child: _PinnedRollHarness(
                    key: key,
                    from: 'Share',
                    to: 'Thanks!',
                    progress: p,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rb = key.currentContext!.findRenderObject() as RenderBox;
      final baseline =
          rb.getDryBaseline(rb.constraints, TextBaseline.alphabetic);
      // ignore: avoid_print
      print('Share→Thanks! p=${p.toStringAsFixed(2)}  '
          'size=${rb.size}  baseline=$baseline');
    }
  });
}

class _PinnedRollHarness extends StatefulWidget {
  const _PinnedRollHarness({
    super.key,
    required this.from,
    required this.to,
    required this.progress,
  });
  final String from;
  final String to;
  final double progress;
  @override
  State<_PinnedRollHarness> createState() => _PinnedRollHarnessState();
}

class _PinnedRollHarnessState extends State<_PinnedRollHarness> {
  late String _text = widget.from;

  @override
  void initState() {
    super.initState();
    if (widget.from != widget.to) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _text = widget.to);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return EffectQuery(
      linearValue: widget.progress,
      curvedValue: widget.progress,
      isTransition: false,
      child: Text(
        _text,
        style: const TextStyle(
          fontFamily: 'TestLatin',
          fontSize: 16,
        ),
      ).roll(symbolDistanceMultiplier: 2),
    );
  }
}
