// Regression for a 1-frame flicker observed when a shaped rolling widget
// transitions between phrases. Initial suspicion was EffectQuery one-frame
// staleness (H1), but testing proved `controller.forward(from: 0)` resets
// synchronously within drive()'s sync body. The real cause:
//
// `_Slot.build` calls `_slotHeight()` which iterates every tape frame for
// every slot on every paint (line 224-234 in shaped_rolling_text.dart).
// Each `frameAt(position, step)` on a fresh controller forces a
// `ShapedText.build` for the substituted paragraph. For an 8-position
// transition with 16-char tapes per position, that's ~128 synchronous
// paragraph layouts in the first post-trigger-change paint — blows the
// 16ms frame budget, causing a dropped frame visible as a flicker.
//
// This test counts `ShapedText.build` cache misses during a single pump
// after a trigger change. Under the bug, count == ~tapeLen × positions.
// Under the fix, count should be bounded (ideally ≤ 2 × positions: just
// firstFrame and lastFrame per slot).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  testWidgets(
    'trigger change: single paint does not rebuild every tape frame',
    (tester) async {
      const style = TextStyle(fontFamily: 'TestLatin', fontSize: 48);
      String text = 'Innovate'; // 8 chars, TagLine-style starting phrase.
      late StateSetter setText;

      await tester.pumpWidget(
        wrapInTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              setText = setState;
              return Text(text, style: style).roll(
                // Use a tape-strategy that produces LONG tapes per position
                // (many uncached paragraph builds if iterated eagerly).
                tapeStrategy: const AllSymbolsTapeStrategy(),
              ).animate(
                trigger: text,
                duration: const Duration(milliseconds: 500),
                startState: AnimationStartState.playImmediately,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Reset: all builds from mount+settle are accounted for; we only
      // care about what happens on the NEXT trigger change.
      ShapedText.debugClearCache();
      ShapedText.debugResetBuildCount();

      // Change text — fresh controller with new old→new pair. First
      // post-setState frame paints against an empty cache, then the
      // state object's post-frame prewarm fires to eagerly shape all
      // remaining tape frames for later animation steps.
      setText(() => text = 'Create'); // 6 chars; positionCount = max(8,6)=8.
      await tester.pump(); // single frame.

      // `tester.pump()` includes the post-frame callbacks, so this
      // count captures BOTH paint-time builds AND prewarm builds. The
      // budget reflects both: ~8 paint-time builds (firstFrame per
      // slot, stepB skipped at t=0) + ~all remaining tape frames
      // shaped in the post-frame prewarm (≈ tape-length × positions).
      final buildsInOneFrame = ShapedText.debugUncachedBuildCount;
      const int maxAcceptableBuilds = 64;
      expect(
        buildsInOneFrame,
        lessThanOrEqualTo(maxAcceptableBuilds),
        reason: 'First pump after trigger change performed '
            '$buildsInOneFrame uncached ShapedText.build calls (paint '
            '+ prewarm). Budget: $maxAcceptableBuilds. If >> budget, '
            'the prewarm is iterating too much or some paint path is '
            'rebuilding on every frame; a prior regression had this '
            'path doing ~20 builds PER PAINT × 60 frames = 1200+ '
            'paragraph layouts per transition.',
      );

      // Also settle to confirm no exceptions propagate.
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'height is stable across transitions (mixed Latin + emoji metrics)',
    (tester) async {
      // Bug: user reports "widget height shifts and grows vertically when
      // the initial roll happens and gets stuck in that elongated height".
      // Root cause candidate: on initial mount, `_previousText ==
      // widget.text`, so every per-position tape frame substitutes the
      // SAME character — cluster heights at first/last frames are
      // identical. After the first text change, first (old letter) and
      // last (new letter) may differ (especially when mixing Latin with
      // emoji). `slotHeight` grows and stays elongated.
      //
      // This test exercises the EmojiLine-style case: text mixing Latin
      // + emoji. Emoji font metrics usually differ from Latin, so the
      // paragraph's line height = max of both. Per-cluster bounds may
      // reveal this divergence when only first/last are sampled.
      const style = TextStyle(
        fontFamilyFallback: ['TestLatin', 'TestEmoji'],
        fontSize: 48,
      );
      // Start Latin-only so initial-mount controller's substituted
      // paragraphs contain ONLY Latin → line height = Latin line height.
      String text = 'Hello';
      late StateSetter setText;

      // Anchor for size-measurement: a SizedBox.shrink-style key lives
      // OUTSIDE the rolled widget but inside the Align, so its
      // RenderBox sizes itself to its child — the rolled text. The
      // shaped renderer no longer uses a `Row` widget (it's a single
      // `RenderShapedRolledRow` render object), so finding by `Row`
      // would miss the new tree.
      final rollKey = GlobalKey();
      await tester.pumpWidget(
        wrapInTestApp(
          Align(
            alignment: Alignment.topLeft,
            child: StatefulBuilder(
              builder: (context, setState) {
                setText = setState;
                return SizedBox(
                  key: rollKey,
                  child: Text(text, style: style).roll().animate(
                        trigger: text,
                        duration: const Duration(milliseconds: 50),
                      ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      double measureHeight() => tester.getSize(find.byKey(rollKey)).height;

      final beforeHeight = measureHeight();

      // Roll to text with an emoji appended. Post-roll controller has
      // oldText='Hello' (Latin), newText='Hi 😀' (contains emoji). At
      // position 3 (l vs 😀), slot ascent/descent lerp toward emoji
      // metrics → row height GROWS while in transition.
      setText(() => text = 'Hi 😀');
      await tester.pumpAndSettle();
      final afterFirstRoll = measureHeight();

      // Roll back to Latin-only. The settled-state row height should
      // depend ONLY on newText's metrics, not on what we rolled
      // through, so we should be back at `beforeHeight`.
      setText(() => text = 'Hello');
      await tester.pumpAndSettle();
      final afterReturnHeight = measureHeight();

      expect(
        afterReturnHeight,
        closeTo(beforeHeight, 0.5),
        reason: 'Widget height should return to its initial value after '
            'a round-trip roll. Bug: stuck taller than initial on mixed '
            'Latin + emoji metrics. '
            'before=$beforeHeight, after_first_roll=$afterFirstRoll, '
            'after_return=$afterReturnHeight.',
      );
    },
  );

}
