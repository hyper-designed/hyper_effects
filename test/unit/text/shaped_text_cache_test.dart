import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  const style = TextStyle(fontFamily: 'TestLatin', fontSize: 32);

  test('identical build args return the same cached ShapedText', () {
    final a = ShapedText.build(text: 'hello', style: style);
    final b = ShapedText.build(text: 'hello', style: style);
    expect(identical(a, b), isTrue);
  });

  test('different text bypasses the cache', () {
    final a = ShapedText.build(text: 'hello', style: style);
    final b = ShapedText.build(text: 'world', style: style);
    expect(identical(a, b), isFalse);
  });

  test('different style bypasses the cache', () {
    const altStyle = TextStyle(fontFamily: 'TestLatin', fontSize: 24);
    final a = ShapedText.build(text: 'hello', style: style);
    final b = ShapedText.build(text: 'hello', style: altStyle);
    expect(identical(a, b), isFalse);
  });

  test('cache honors max size — evicts least-recently-used', () {
    // With max size 128, building 130 distinct entries forces eviction
    // of the 2 oldest. Verify that the first entry is gone (identity
    // no longer holds when rebuilt).
    final first = ShapedText.build(text: 'entry_0', style: style);
    for (int i = 1; i < 130; i++) {
      ShapedText.build(text: 'entry_$i', style: style);
    }
    final firstAgain = ShapedText.build(text: 'entry_0', style: style);
    expect(identical(first, firstAgain), isFalse,
        reason: 'first entry should have been evicted');
  });

  test('debugClearCache resets the cache', () {
    final a = ShapedText.build(text: 'hello', style: style);
    ShapedText.debugClearCache();
    final b = ShapedText.build(text: 'hello', style: style);
    expect(identical(a, b), isFalse);
  });

  group('public cache invalidation API', () {
    // Issue #4: GoogleFonts loads fonts asynchronously. The first
    // ShapedText.build for a given text+style caches a paragraph shaped
    // with whichever font was resolved at that moment — typically the
    // fallback, since the target font hasn't finished loading. Later
    // calls with the same args return that stale paragraph. These tests
    // guard the escape hatches: a public clearCache() method users can
    // call manually after ensuring fonts are loaded, and a façade on
    // HyperEffects for discoverability.

    test('ShapedText.clearCache is a public API that invalidates the cache',
        () {
      final a = ShapedText.build(text: 'hello', style: style);
      ShapedText.clearCache();
      final b = ShapedText.build(text: 'hello', style: style);
      expect(identical(a, b), isFalse,
          reason: 'ShapedText.clearCache must fully reset the module-level '
              'LRU so the next build re-shapes from scratch.');
    });

    test('HyperEffects.clearShapedTextCache dispatches a full invalidation',
        () async {
      // The façade goes through PaintingBinding.handleSystemMessage so
      // both the module LRU AND any mounted widget listeners see the
      // fontsChange. Clearing only the LRU would leave widgets holding
      // stale controller caches.
      final a = ShapedText.build(text: 'hello', style: style);
      await HyperEffects.clearShapedTextCache();
      final b = ShapedText.build(text: 'hello', style: style);
      expect(identical(a, b), isFalse,
          reason: 'HyperEffects.clearShapedTextCache is the discoverable '
              'entry point for consumers whose font loader doesn\'t emit '
              'a systemFonts notification.');
    });
  });

  group('automatic invalidation on system font change', () {
    // PaintingBinding.instance.systemFonts fires a "fontsChange"
    // notification when the OS swaps font files (GoogleFonts calls this
    // after downloading a font). ShapedText subscribes to this and
    // clears its cache automatically, so consumers don't have to wire
    // the escape hatch themselves.

    test('cache is cleared when systemFonts fires', () async {
      // Ensure the auto-listener has been installed. It's wired on first
      // build() call so that the cache is only live after first use.
      final a = ShapedText.build(text: 'hello', style: style);

      // Simulate a fonts-change notification from the platform channel.
      await ShapedText.debugTriggerFontsChanged();

      final b = ShapedText.build(text: 'hello', style: style);
      expect(identical(a, b), isFalse,
          reason: 'After a systemFonts change, cache must auto-clear so '
              'paragraphs re-shape against the newly-available font.');
    });
  });
}
