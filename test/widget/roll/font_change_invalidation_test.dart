// Regression coverage for Issue #4 (font-load race).
//
// When an async font loader (google_fonts, etc.) resolves after first
// paint, the platform fires a `fontsChange` notification via
// PaintingBinding.instance.systemFonts. ShapedText's module cache
// auto-clears on that signal — but ShapedRollingTextController also
// memoises per-position tape frames, slot widths, and row height. Those
// caches survive the module-level clear, so the widget would keep
// rendering fallback-shaped frames forever unless the state listens to
// the same notification and forces a controller rebuild.
//
// This test asserts the full pipeline: systemFonts fires → module cache
// clears → widget detects → controller rebuilds → next paint re-shapes.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  testWidgets(
    'ShapedRollingText re-shapes after systemFonts change',
    (tester) async {
      const style = TextStyle(fontFamily: 'TestLatin', fontSize: 32);

      await tester.pumpWidget(
        wrapInTestApp(
          const Text('Hello', style: style).roll().animate(
                trigger: 'Hello',
                duration: const Duration(milliseconds: 50),
              ),
        ),
      );
      await tester.pumpAndSettle();

      // Prime: from this point, any uncached ShapedText.build means the
      // widget actually re-shaped rather than reusing its cached
      // controller caches. Reset the counter *after* the widget has
      // fully settled so the pre-font-change builds aren't counted.
      ShapedText.debugResetBuildCount();
      final before = ShapedText.debugUncachedBuildCount;

      // Fire the platform fonts-change signal. ShapedText's module cache
      // auto-clears; ShapedRollingText's state listener must also
      // setState + rebuild its controller so the next paint re-shapes.
      await ShapedText.debugTriggerFontsChanged();

      // One pump advances the setState triggered by the state listener.
      // After that pump the widget should have rebuilt its controller
      // and re-painted — which forces uncached ShapedText.build calls
      // because we just cleared the cache.
      await tester.pump();

      expect(ShapedText.debugUncachedBuildCount, greaterThan(before),
          reason: 'Widget should have re-shaped after systemFonts change. '
              'If this fails, the state listener did not trigger a '
              'controller rebuild (or the rebuild reused stale frame '
              'caches from the old controller).');
    },
  );

  testWidgets(
    'rebuild is deferred past a mid-animation fontsChange to avoid flash',
    (tester) async {
      // User-reported: "the first roll always flashes a frame". Root
      // cause is GoogleFonts finishing its async load mid-animation,
      // firing systemFonts, and my state listener swapping the
      // controller on the very next paint. Old-font geometry ↦
      // new-font geometry on adjacent frames = visible flash. Fix is
      // to defer the swap until progress is back at a settled value
      // (0 or 1). This test pins that behaviour.
      const style = TextStyle(fontFamily: 'TestLatin', fontSize: 32);
      String text = 'Hello';
      late StateSetter setter;

      await tester.pumpWidget(
        wrapInTestApp(
          StatefulBuilder(builder: (context, setState) {
            setter = setState;
            return Text(text, style: style).roll().animate(
                  trigger: text,
                  duration: const Duration(milliseconds: 400),
                  startState: AnimationStartState.playImmediately,
                );
          }),
        ),
      );
      await tester.pumpAndSettle();

      // Kick off a roll and advance to ~mid-animation (progress ≈ 0.5).
      setter(() => text = 'World');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // From this point, any uncached ShapedText.build means the
      // controller has been rebuilt and re-shaped.
      ShapedText.debugResetBuildCount();
      final before = ShapedText.debugUncachedBuildCount;

      // Fire fontsChange mid-animation.
      await ShapedText.debugTriggerFontsChanged();
      await tester.pump();

      final midAnimationBuilds =
          ShapedText.debugUncachedBuildCount - before;
      expect(midAnimationBuilds, 0,
          reason: 'Controller must NOT rebuild while a roll is in '
              'flight — that produces the one-frame geometry flash '
              'user reported. midAnimationBuilds=$midAnimationBuilds');

      // Let the animation settle. After settling, the deferred rebuild
      // should fire on the next paint, forcing uncached shapes.
      await tester.pumpAndSettle();

      expect(ShapedText.debugUncachedBuildCount, greaterThan(before),
          reason: 'Once the animation is back at a settled endpoint, '
              'the deferred fontsChange must be consumed so subsequent '
              'paints use the real font.');
    },
  );

  testWidgets(
    'listener is removed on dispose (no post-dispose setState)',
    (tester) async {
      const style = TextStyle(fontFamily: 'TestLatin', fontSize: 32);

      await tester.pumpWidget(
        wrapInTestApp(
          const Text('Hello', style: style).roll().animate(trigger: 'Hello'),
        ),
      );
      await tester.pumpAndSettle();

      // Unmount the widget.
      await tester.pumpWidget(wrapInTestApp(const SizedBox.shrink()));
      await tester.pumpAndSettle();

      // Firing after dispose must not cause the framework to surface an
      // exception. A leaked listener would call setState on a disposed
      // State, which Flutter reports via TestWidgetsFlutterBinding's
      // error channel (not as a sync throw) — so we have to await the
      // async dispatch and then inspect the binding's exception queue.
      await ShapedText.debugTriggerFontsChanged();
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: 'Post-dispose fontsChange must not raise a framework '
              'exception. If this fails, the state listener was not '
              'removed in dispose and setState ran on an unmounted state.');
    },
  );
}
