// Regression: the shaped rolling controller must collapse slots beyond
// the new text's length to zero width, so shorter targets don't leave
// stale letters behind. Mirrors the TagLine demo in the example app,
// which cycles `'Innovate' → 'Create' → 'Develop' → 'Grow' → ...` and
// was seen rendering "Createte", "CreateC", "GrowGG" artifacts.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/effects/roll/shaped/shaped_rolling_text_controller.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../../../../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  const style = TextStyle(fontFamily: 'TestLatin', fontSize: 32);

  ShapedRollingTextController make({
    required String oldText,
    required String newText,
  }) =>
      ShapedRollingTextController(
        oldText: oldText,
        newText: newText,
        tapeStrategy: const ConsistentSymbolTapeStrategy(0),
        style: style,
      );

  group('positions beyond newText length must collapse at settled', () {
    test('Innovate(8) → Create(6): positions 6,7 end with zero-width cluster',
        () {
      final c = make(oldText: 'Innovate', newText: 'Create');
      expect(c.positionCount, 8);
      for (final position in const [6, 7]) {
        final tapeLen = c.tapeLength(position: position);
        final lastStep = tapeLen - 1;
        final lastFrame = c.frameAt(position: position, step: lastStep);
        expect(
          lastFrame.clusterBounds.width,
          0,
          reason: 'Position $position (beyond newText.length=6) must have '
              'zero-width final cluster. Tape length: $tapeLen. '
              'Substituted text: ${lastFrame.substitutedText.codeUnits}. '
              'Cluster bounds: ${lastFrame.clusterBounds}.',
        );
      }
    });

    test('Develop(7) → Grow(4): positions 4,5,6 end with zero-width cluster',
        () {
      final c = make(oldText: 'Develop', newText: 'Grow');
      expect(c.positionCount, 7);
      for (final position in const [4, 5, 6]) {
        final tapeLen = c.tapeLength(position: position);
        final lastStep = tapeLen - 1;
        final lastFrame = c.frameAt(position: position, step: lastStep);
        expect(
          lastFrame.clusterBounds.width,
          0,
          reason: 'Position $position (beyond newText.length=4) must have '
              'zero-width final cluster. Tape length: $tapeLen. '
              'Substituted text: ${lastFrame.substitutedText.codeUnits}. '
              'Cluster bounds: ${lastFrame.clusterBounds}.',
        );
      }
    });

    test('Grow(4) → Learn(5): position 4 grows IN from zero-width', () {
      // When newText is LONGER than oldText, position 4 exists only in
      // newText. Tape step 0 (start of animation) should be zero-width
      // (invisible) so the letter fades IN rather than jumping from some
      // stale value.
      final c = make(oldText: 'Grow', newText: 'Learn');
      expect(c.positionCount, 5);
      final firstFrame = c.frameAt(position: 4, step: 0);
      expect(
        firstFrame.clusterBounds.width,
        0,
        reason: 'Position 4 (not in oldText) must start with zero-width '
            'cluster at step 0. Substituted text: '
            '${firstFrame.substitutedText.codeUnits}. '
            'Cluster bounds: ${firstFrame.clusterBounds}.',
      );
    });
  });

  group('sum of final cluster widths equals newText width (no trailing mass)',
      () {
    // A stricter invariant: after a transition, the total horizontal mass
    // across all slots at rest should equal the shaped newText's width.
    // If positions beyond newText.length have non-zero cluster width, the
    // total exceeds newText's width and we'd see stale letters.
    test('Innovate → Create: settled slot widths sum to ≈ newText width', () {
      final c = make(oldText: 'Innovate', newText: 'Create');
      double totalSlotMass = 0;
      for (int p = 0; p < c.positionCount; p++) {
        final tapeLen = c.tapeLength(position: p);
        final lastFrame = c.frameAt(position: p, step: tapeLen - 1);
        totalSlotMass += lastFrame.clusterBounds.width;
      }
      final target = ShapedText.build(text: 'Create', style: style);
      final targetWidth =
          target.clusters.fold<double>(0, (a, c) => a + c.bounds.width);
      expect(
        totalSlotMass,
        closeTo(targetWidth, 0.5),
        reason: 'Total width of all settled slots should equal the shaped '
            '"Create" width. Excess means stale letters leak through from '
            'positions beyond newText. Got totalSlotMass=$totalSlotMass, '
            'targetWidth=$targetWidth.',
      );
    });

    test('Develop → Grow: settled slot widths sum to ≈ newText width', () {
      final c = make(oldText: 'Develop', newText: 'Grow');
      double totalSlotMass = 0;
      for (int p = 0; p < c.positionCount; p++) {
        final tapeLen = c.tapeLength(position: p);
        final lastFrame = c.frameAt(position: p, step: tapeLen - 1);
        totalSlotMass += lastFrame.clusterBounds.width;
      }
      final target = ShapedText.build(text: 'Grow', style: style);
      final targetWidth =
          target.clusters.fold<double>(0, (a, c) => a + c.bounds.width);
      expect(
        totalSlotMass,
        closeTo(targetWidth, 0.5),
        reason: 'Total width of all settled slots should equal the shaped '
            '"Grow" width. Got totalSlotMass=$totalSlotMass, '
            'targetWidth=$targetWidth.',
      );
    });

    test('RTL Arabic مرحبا(5) → شكرا(4): position 4 collapses', () {
      const arabicStyle = TextStyle(fontFamily: 'TestArabic', fontSize: 32);
      final c = ShapedRollingTextController(
        oldText: 'مرحبا',
        newText: 'شكرا',
        tapeStrategy: const ConsistentSymbolTapeStrategy(0),
        style: arabicStyle,
        textDirection: TextDirection.rtl,
      );
      expect(c.positionCount, 5);
      final tapeLen = c.tapeLength(position: 4);
      final lastFrame = c.frameAt(position: 4, step: tapeLen - 1);
      expect(
        lastFrame.clusterBounds.width,
        0,
        reason: 'Position 4 (beyond newText.length=4) must collapse even in '
            'RTL. Tape length: $tapeLen. Substituted text code units: '
            '${lastFrame.substitutedText.codeUnits}. '
            'Cluster bounds: ${lastFrame.clusterBounds}.',
      );
    });
  });

  group('rendered width matches reference Text', () {
    // The strictest invariant: after a roll settles, the shaped rolling
    // widget's actual rendered width should equal the width of a plain
    // Text widget showing the same final string. Sum-of-slot-widths (above)
    // is a necessary but not sufficient proxy; this is the integration
    // check.
    testWidgets('mid-roll width does not overshoot settled width + slack',
        (tester) async {
      // Gap bug: during rolling between frames of different widths, each
      // slot reserves max(frameA.width, frameB.width). Narrower frames
      // show as slot with trailing gap. Lerped slot width eliminates this.
      const style = TextStyle(fontFamily: 'TestLatin', fontSize: 48);

      // Reference: plain Text at final text.
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: style,
              child: Center(child: Text('Create')),
            ),
          ),
        ),
      );
      final referenceWidth = tester.getSize(find.text('Create')).width;

      // Rolling Innovate → Create at mid-progress. Many slot pairs have
      // width mismatches (Innovate uses 'n','o','v' = narrow/medium; Create
      // has 'C','r','e','a','t','e'). Under the buggy max() formula, the
      // Row total width at progress=0.5 is substantially larger than the
      // settled width because each slot reserves the WIDEST of its pair.
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: style,
              child: Center(
                child: _MidRollHarness(
                  from: 'Innovate',
                  to: 'Create',
                  style: style,
                  progress: 0.5,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final midRollWidth =
          tester.getSize(find.byType(_MidRollHarness)).width;

      // Mid-roll should be within a reasonable slack of the final text's
      // width. The bug produces widths 30-60% larger. Slack: we allow up
      // to referenceWidth + 30% for character width variance but reject
      // the buggy ~60%+.
      expect(
        midRollWidth,
        lessThan(referenceWidth * 1.30),
        reason: 'Mid-roll total width is ${midRollWidth}px vs reference '
            '${referenceWidth}px (${(midRollWidth / referenceWidth * 100).toStringAsFixed(1)}%). '
            'If > 130% of reference, slots are using max(frameA.width, '
            'frameB.width) producing gaps between letters.',
      );
    });

    testWidgets('Innovate → Create settled width matches reference Text',
        (tester) async {
      const style = TextStyle(fontFamily: 'TestLatin', fontSize: 32);

      // Reference: plain Text with the final string.
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: style,
              child: Center(child: Text('Create')),
            ),
          ),
        ),
      );
      final referenceSize = tester.getSize(find.text('Create'));

      // Rolled: the ShapedRollingText widget after settling from
      // "Innovate" → "Create".
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: style,
              child: Center(
                child: _RollingHarness(
                  from: 'Innovate',
                  to: 'Create',
                  style: style,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rolledSize = tester.getSize(find.byType(_RollingHarness));

      expect(
        rolledSize.width,
        closeTo(referenceSize.width, 2.0),
        reason: 'Settled shaped rolling widget should be as wide as a plain '
            'Text("Create"). Stale trailing letters from "Innovate" would '
            'make the rolled widget wider. reference=${referenceSize.width}, '
            'rolled=${rolledSize.width}.',
      );
    });
  });
}

/// Minimal harness that drives a shaped roll from [from] to [to] under an
/// `EffectQuery(curvedValue: 1.0)`, so the widget settles on the target.
class _RollingHarness extends StatefulWidget {
  const _RollingHarness({
    required this.from,
    required this.to,
    required this.style,
  });

  final String from;
  final String to;
  final TextStyle style;

  @override
  State<_RollingHarness> createState() => _RollingHarnessState();
}

class _RollingHarnessState extends State<_RollingHarness> {
  late String _text = widget.from;

  @override
  void initState() {
    super.initState();
    // Schedule a text flip on the next frame so didUpdateWidget triggers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _text = widget.to);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(_text, style: widget.style).roll().animate(
          trigger: _text,
          duration: const Duration(milliseconds: 50),
          startState: AnimationStartState.playImmediately,
        );
  }
}

/// Renders a shaped roll pinned at a specific [progress] via an explicit
/// `EffectQuery`, bypassing `AnimatedEffect` — so mid-animation snapshots
/// are deterministic regardless of ticker timing.
class _MidRollHarness extends StatefulWidget {
  const _MidRollHarness({
    required this.from,
    required this.to,
    required this.style,
    required this.progress,
  });

  final String from;
  final String to;
  final TextStyle style;
  final double progress;

  @override
  State<_MidRollHarness> createState() => _MidRollHarnessState();
}

class _MidRollHarnessState extends State<_MidRollHarness> {
  late String _text = widget.from;

  @override
  void initState() {
    super.initState();
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
      child: Text(_text, style: widget.style).roll(),
    );
  }
}
