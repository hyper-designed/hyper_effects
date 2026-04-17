// Measurement: does the 128-entry ShapedText LRU thrash under the
// demo's heaviest transition (EmojiLine-scale, ~17 slots × 4 tape
// frames per slot) — i.e. does the same paragraph get re-shaped more
// than once during a single animation run because earlier cache
// entries got evicted?
//
// The structural budget: each position has a tape of length N, and
// each frame needs exactly one shaped paragraph. Within one controller
// life the total number of *distinct* substituted paragraphs is
// positionCount × N. If the cache holds them all, total uncached
// builds during the animation == that exact number (each unique
// paragraph shaped once). If the cache evicts, the count climbs
// because the same paragraph is re-shaped after being evicted.

import 'package:flutter/material.dart';
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
    'EmojiLine-scale transition does not thrash the LRU',
    (tester) async {
      // Mirror the demo story's sizing: ~17 grapheme clusters per text,
      // tape depth 4. Keep content ASCII-only because the test env's
      // TestEmoji fallback changes metrics unpredictably; the cache
      // thrashing behaviour is strictly a function of the number of
      // unique substituted paragraphs, not the glyph class.
      const style = TextStyle(fontFamily: 'TestLatin', fontSize: 24);
      const oldText = 'The quick brown fox jumps over lazyDOG';
      const newText = 'A slow white wolf strolls under calm SKY';

      String text = oldText;
      late StateSetter setText;

      await tester.pumpWidget(
        wrapInTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              setText = setState;
              return Text(text, style: style)
                  .roll(tapeStrategy: const ConsistentSymbolTapeStrategy(4))
                  .animate(
                    trigger: text,
                    duration: const Duration(milliseconds: 500),
                    startState: AnimationStartState.playImmediately,
                  );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Zero the counter after mount+settle so we're only measuring
      // the forthcoming transition's builds.
      ShapedText.debugClearCache();
      ShapedText.debugResetBuildCount();

      setText(() => text = newText);
      // Drive the whole animation. pumpAndSettle runs as many frames
      // as needed to settle; each frame paints the slot stack which
      // issues ShapedText.build calls for the active tape frames.
      await tester.pumpAndSettle(const Duration(milliseconds: 16));

      final builds = ShapedText.debugUncachedBuildCount;

      // Upper bound reasoning:
      //   positionCount = max(oldLen, newLen) ≈ 40 clusters
      //   tapeLength ≈ 4 (ConsistentSymbolTapeStrategy(4))
      //   distinct substituted paragraphs ≈ 40 × 4 = 160
      // With a 128-entry LRU, 32 paragraphs would be evicted and
      // re-shaped, giving a *minimum* extra-build count of 32.
      // A thrashing run (each paragraph re-shaped multiple times per
      // paint) could push this into the thousands.
      //
      // The tight budget — "each paragraph shaped at most once, even
      // across evictions" — is 160. We allow modest slack for framework
      // re-paints. Anything north of ~500 means the LRU is thrashing
      // and the 128 cap is too small for this workload.
      // ignore: avoid_print
      print('Uncached ShapedText builds for full EmojiLine-scale '
          'transition: $builds (structural bound ≈ positions×tape = 160)');

      const int looseBudget = 500;
      expect(builds, lessThanOrEqualTo(looseBudget),
          reason: 'Cache is thrashing: $builds uncached builds far '
              'exceeds the structural bound. Either bump _kMaxCacheEntries '
              'or introduce per-controller retention.');
    },
  );

  testWidgets(
    'AllSymbolsTapeStrategy (deepest tapes) still fits the LRU',
    (tester) async {
      // AllSymbolsTapeStrategy builds tapes that walk through *every*
      // character between old and new, so per-position tape length can
      // be a double-digit number of frames. For a 15-cluster transition
      // with ~10-frame tapes this is positions×tape ≈ 150, already at
      // the LRU cap. Anything meaningfully longer will evict mid-paint.
      const style = TextStyle(fontFamily: 'TestLatin', fontSize: 24);
      const oldText = 'alphabetSoup12';
      const newText = 'ZEBRA_punk__9x';

      String text = oldText;
      late StateSetter setText;

      await tester.pumpWidget(
        wrapInTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              setText = setState;
              return Text(text, style: style)
                  .roll(tapeStrategy: const AllSymbolsTapeStrategy())
                  .animate(
                    trigger: text,
                    duration: const Duration(milliseconds: 500),
                    startState: AnimationStartState.playImmediately,
                  );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      ShapedText.debugClearCache();
      ShapedText.debugResetBuildCount();

      setText(() => text = newText);
      await tester.pumpAndSettle(const Duration(milliseconds: 16));

      final builds = ShapedText.debugUncachedBuildCount;
      // ignore: avoid_print
      print('AllSymbolsTapeStrategy transition uncached builds: $builds');

      // Structural bound for 14 positions with deep tapes: hard to
      // predict exactly without traversing the strategy, but each
      // unique paragraph should only be shaped once. Anything >> cap
      // would indicate re-eviction.
      const int looseBudget = 1500;
      expect(builds, lessThanOrEqualTo(looseBudget),
          reason: 'Heavy-tape strategy thrashing: $builds uncached '
              'builds. If this fails persistently in production workloads, '
              'raise _kMaxCacheEntries or retain per-controller paragraphs.');
    },
  );
}
