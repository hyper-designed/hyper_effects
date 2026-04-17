// RED: Failing tests that capture the visual bug at the very start of a
// roll between length-mismatched words. The user reports that at the
// first few frames of transitions like Marhaba→Hola or Hola→Marhaba (and
// also same-length cursive transitions), extra strokes / extra letter-
// like glyphs appear that shouldn't be there.
//
// The strict invariant we assert here: at progress=0.0 (very first
// frame), the shaped roll widget must occupy the same horizontal space
// as a plain `Text(oldText)` rendered with the same style. Likewise at
// progress=1.0 it must match `Text(newText)`. Any divergence is a
// visible artifact (extra ink past the natural word's box).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  // Style mirrors the example app's Translation widget — same fontSize as
  // Sacramento at 56pt, but rendered with TestLatin so the test is
  // hermetic. The user-reported bug is hypothesised to be cursive-
  // specific, but the controller geometry under test is font-agnostic;
  // any width discrepancy at a settled endpoint is a controller bug.
  const style = TextStyle(
    fontFamily: 'TestLatin',
    fontSize: 48,
    color: Color(0xFF111111),
  );

  // Pairs taken from the example app's Translation widget cycle. Picks
  // every length-mismatched neighbour-pair so the controller's
  // length-mismatch handling is exercised in both directions.
  const pairs = <(String, String)>[
    ('Marhaba', 'Hola'),       // 7 → 4 shrink
    ('Hola', 'Marhaba'),       // 4 → 7 grow
    ('Hej', 'Namaste'),        // 3 → 7 grow
    ('Namaste', 'Salaam'),     // 7 → 6 shrink
    ('Saluton', 'Konnichiwa'), // 7 → 10 grow
    ('Konnichiwa', 'Annyeong'),// 10 → 8 shrink
    ('Ni Hao', 'Namaste'),     // 6 → 7 grow
    ('Hello', 'Bonjour'),      // 5 → 7 grow
  ];

  group('shaped roll start frame matches plain Text(oldText) width', () {
    for (final pair in pairs) {
      final (from, to) = pair;
      testWidgets('$from(${from.characters.length}) → '
          '$to(${to.characters.length}) at progress=0.0', (tester) async {
        // Reference: plain Text(oldText) — what the rolling widget is
        // SUPPOSED to look like at the very first frame, before any
        // animation has progressed.
        await tester.pumpWidget(
          wrapInTestApp(
            Text(from, style: style),
          ),
        );
        final referenceWidth = tester.getSize(find.text(from)).width;

        // Subject: shaped roll mid-transition pinned at progress=0.0.
        // Mounts with `from`, flips to `to` on the next frame, then
        // EffectQuery pins curvedValue to 0.0 — so the controller has
        // already initialised for the from→to transition but no
        // animation has progressed.
        await tester.pumpWidget(
          wrapInTestApp(
            _PinnedRollHarness(
              from: from,
              to: to,
              progress: 0.0,
              style: style,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final rolledWidth =
            tester.getSize(find.byType(_PinnedRollHarness)).width;

        // Tolerance: 1px. Sub-pixel rounding between TextPainter and
        // CustomPaint slot layout is acceptable; anything larger means
        // the row is reserving space for letters that aren't in
        // oldText (extra clusters from newText leaking through, slot
        // padding misapplied, etc.).
        expect(
          rolledWidth,
          closeTo(referenceWidth, 1.0),
          reason:
              'At progress=0.0 the shaped roll for "$from" → "$to" should '
              'occupy the same horizontal space as plain Text("$from"). '
              'Reference width=$referenceWidth, rolled width=$rolledWidth. '
              'A wider rolled width means extra ink (cluster overshoot, '
              'newText leak, padding miscount) is reserved before any '
              'animation has progressed.',
        );
      });
    }
  });

  group('shaped roll end frame matches plain Text(newText) width', () {
    for (final pair in pairs) {
      final (from, to) = pair;
      testWidgets('$from(${from.characters.length}) → '
          '$to(${to.characters.length}) at progress=1.0', (tester) async {
        await tester.pumpWidget(
          wrapInTestApp(
            Text(to, style: style),
          ),
        );
        final referenceWidth = tester.getSize(find.text(to)).width;

        await tester.pumpWidget(
          wrapInTestApp(
            _PinnedRollHarness(
              from: from,
              to: to,
              progress: 1.0,
              style: style,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final rolledWidth =
            tester.getSize(find.byType(_PinnedRollHarness)).width;

        expect(
          rolledWidth,
          closeTo(referenceWidth, 1.0),
          reason:
              'At progress=1.0 the shaped roll for "$from" → "$to" should '
              'occupy the same horizontal space as plain Text("$to"). '
              'Reference width=$referenceWidth, rolled width=$rolledWidth.',
        );
      });
    }
  });
}

/// Renders a shaped roll mid-transition, pinned at a specific [progress]
/// via an explicit `EffectQuery` — bypasses `AnimatedEffect` so the
/// snapshot is deterministic regardless of ticker timing.
class _PinnedRollHarness extends StatefulWidget {
  const _PinnedRollHarness({
    required this.from,
    required this.to,
    required this.progress,
    required this.style,
  });

  final String from;
  final String to;
  final double progress;
  final TextStyle style;

  @override
  State<_PinnedRollHarness> createState() => _PinnedRollHarnessState();
}

class _PinnedRollHarnessState extends State<_PinnedRollHarness> {
  late String _text = widget.from;

  @override
  void initState() {
    super.initState();
    // Schedule a text flip on the next frame so the inner ShapedRollingText
    // sees a (from → to) transition via didUpdateWidget.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _text = widget.to);
    });
  }

  @override
  Widget build(BuildContext context) {
    return EffectQuery(
      linearValue: widget.progress,
      curvedValue: widget.progress,
      isTransition: false,
      child: Text(_text, style: widget.style).roll(
        renderMode: TextRenderMode.contextualCharacters,
      ),
    );
  }
}
