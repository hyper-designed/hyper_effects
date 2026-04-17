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

  ShapedRollingTextController makeController({
    String oldText = 'abc',
    String newText = 'xyz',
    SymbolTapeStrategy tapeStrategy = const ConsistentSymbolTapeStrategy(0),
    TapeShapingContext context =
        TapeShapingContext.endpointsCorrect,
  }) =>
      ShapedRollingTextController(
        oldText: oldText,
        newText: newText,
        tapeStrategy: tapeStrategy,
        style: style,
        tapeShapingContext: context,
      );

  group('ShapedRollingTextController position count', () {
    test('matches max grapheme-cluster length', () {
      final c = makeController(oldText: 'abc', newText: 'xyzw');
      expect(c.positionCount, 4);
    });

    test('handles empty old text', () {
      final c = makeController(oldText: '', newText: 'hello');
      expect(c.positionCount, 5);
    });
  });

  group('ShapedRollingTextController tape frame building', () {
    test('frameAt returns consistent frames for same position', () {
      final c = makeController();
      final f1 = c.frameAt(position: 0, step: 0);
      final f2 = c.frameAt(position: 0, step: 0);
      expect(f1, equals(f2));
    });

    test('frameAt at step 0 uses the old-word tape character', () {
      final c = makeController(oldText: 'abc', newText: 'xyz');
      final f = c.frameAt(position: 0, step: 0);
      // Step 0 is the start of the roll; by convention the tape reveals
      // a character from the old word's position (or the space-shortcut
      // tape for special cases). The substitutedText at step 0 must
      // contain 'a' at position 0 somewhere.
      expect(f.substitutedText, contains('a'));
    });

    test('slot width is the max cluster width across all frames', () {
      final c = makeController(oldText: 'ab', newText: 'yz');
      final widths = <double>[];
      for (int step = 0; step < c.tapeLength(position: 0); step++) {
        widths.add(c.frameAt(position: 0, step: step).clusterBounds.width);
      }
      final maxWidth = widths.reduce((a, b) => a > b ? a : b);
      expect(c.slotWidth(position: 0), closeTo(maxWidth, 0.5));
    });
  });

  group('ShapedRollingTextController context fallback', () {
    test('empty oldText uses newText context at step 0 (endpointsCorrect)',
        () {
      final c = ShapedRollingTextController(
        oldText: '',
        newText: 'hello',
        tapeStrategy: const ConsistentSymbolTapeStrategy(0),
        style: style,
      );
      final f = c.frameAt(position: 0, step: 0);
      // substitutedText should contain the full newText-shaped context
      // with tapeChar at position 0, i.e. length 5 not 1.
      expect(f.substitutedText.length, greaterThanOrEqualTo(5),
          reason: 'Empty oldText must degrade to newText context so the '
              'substituted string shapes in context, not in isolation.');
    });

    test('position beyond oldText length uses newText context', () {
      final c = ShapedRollingTextController(
        oldText: 'ab',
        newText: 'hello',
        tapeStrategy: const ConsistentSymbolTapeStrategy(0),
        tapeShapingContext: TapeShapingContext.oldWord,
        style: style,
      );
      // Position 4 only exists in newText. With oldWord context, we should
      // fall back to newText rather than producing a too-short substitution.
      final f = c.frameAt(position: 4, step: 0);
      expect(f.substitutedText.length, greaterThanOrEqualTo(5));
    });
  });

  group('ShapedRollingTextController frame-height invariants', () {
    // Slot height is no longer a controller-computed scalar — it's
    // lerped from `firstFrameHeight` to `lastFrameHeight` per
    // position by `_Slot.build`, matching the width-lerp semantics.
    // The guarantees we still care about are the endpoints themselves.

    test('firstFrameHeight matches first-step cluster bounds', () {
      final c = makeController(oldText: 'Hello', newText: 'World');
      for (int p = 0; p < c.positionCount; p++) {
        final first = c.frameAt(position: p, step: 0);
        expect(c.firstFrameHeight(position: p),
            closeTo(first.clusterBounds.height, 0.001),
            reason: 'position $p firstFrameHeight should match the first '
                'tape frame\'s cluster bounds exactly.');
      }
    });

    test('lastFrameHeight matches last-step cluster bounds', () {
      final c = makeController(oldText: 'Hello', newText: 'World');
      for (int p = 0; p < c.positionCount; p++) {
        final len = c.tapeLength(position: p);
        final last = c.frameAt(position: p, step: len - 1);
        expect(c.lastFrameHeight(position: p),
            closeTo(last.clusterBounds.height, 0.001),
            reason: 'position $p lastFrameHeight should match the last '
                'tape frame\'s cluster bounds exactly.');
      }
    });

    test('lastFrameHeight is oldText-independent', () {
      // Two controllers with the same newText should report the same
      // lastFrameHeight per position, regardless of oldText. That's the
      // round-trip invariant: A→B→A returns to A's initial row height
      // because the new controller's lastFrameHeight depends only on A.
      final a = makeController(oldText: 'Hello', newText: 'World');
      final b = makeController(oldText: 'Hi 😀', newText: 'World');
      for (int p = 0; p < a.positionCount && p < b.positionCount; p++) {
        expect(a.lastFrameHeight(position: p),
            closeTo(b.lastFrameHeight(position: p), 0.5),
            reason: 'position $p lastFrameHeight must depend only on '
                'newText + style, not on oldText.');
      }
    });
  });
}
