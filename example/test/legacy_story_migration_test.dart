import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects_demo/stories/shake_and_spring_animation.dart';
import 'package:hyper_effects_demo/stories/timeline_journey.dart';

/// Composite translation of every Transform wrapping [target].
Offset compositeTranslationOf(WidgetTester tester, Finder target) {
  final transforms = tester.widgetList<Transform>(
    find.ancestor(of: target, matching: find.byType(Transform)),
  );
  var dx = 0.0;
  var dy = 0.0;
  for (final t in transforms) {
    dx += t.transform.entry(0, 3);
    dy += t.transform.entry(1, 3);
  }
  return Offset(dx, dy);
}

void main() {
  testWidgets('journey story loops on a timeline, no reset machinery',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TimelineJourney())),
    );

    // ignore: deprecated_member_use
    expect(find.byType(ResetAllAnimationsEffect), findsNothing,
        reason: 'the deprecated reset-loop machinery must be gone');
    expect(find.byType(TimelineEffect), findsOneWidget);

    final image = find.byType(Image);
    // Auto-plays: position changes over time.
    await tester.pump(const Duration(milliseconds: 175));
    final early = compositeTranslationOf(tester, image);
    await tester.pump(const Duration(milliseconds: 350));
    final later = compositeTranslationOf(tester, image);
    expect((later - early).distance, greaterThan(10),
        reason: 'the journey must be in motion on its own');

    // Still in motion a full circuit later: it loops.
    await tester.pump(const Duration(milliseconds: 1400));
    final loop = compositeTranslationOf(tester, image);
    await tester.pump(const Duration(milliseconds: 350));
    final loopLater = compositeTranslationOf(tester, image);
    expect((loopLater - loop).distance, greaterThan(10),
        reason: 'the journey must keep looping');
  });

  testWidgets('spring story drops and springs back on a timeline',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SpringAnimation())),
    );

    // ignore: deprecated_member_use
    expect(find.byType(ResetAllAnimationsEffect), findsNothing,
        reason: 'the deprecated reset-loop machinery must be gone');
    expect(find.byType(TimelineEffect), findsOneWidget);

    final image = find.byType(Image);
    expect(compositeTranslationOf(tester, image).dy, closeTo(0, 1),
        reason: 'at rest the ball sits at its origin');

    await tester.tap(find.byType(GestureDetector).first, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(compositeTranslationOf(tester, image).dy, greaterThan(50),
        reason: 'the ball must be falling');

    // Fall (2000ms) + spring (450ms) + slack, in frame-sized steps because
    // the idle shake loop never settles.
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(compositeTranslationOf(tester, image).dy.abs(), lessThan(1),
        reason: 'the ball must spring back to its origin');

    // The idle shake's .animate(delay:) schedules a Future.delayed per loop
    // cycle; unmount and advance the clock so no timer outlives the test.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
