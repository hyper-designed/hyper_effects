import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

double compositeScaleOf(WidgetTester tester, Key key) {
  final transforms = tester.widgetList<Transform>(
    find.ancestor(of: find.byKey(key), matching: find.byType(Transform)),
  );
  var scale = 1.0;
  for (final t in transforms) {
    final m = t.transform;
    scale *= Offset(m.entry(0, 0), m.entry(1, 0)).distance;
  }
  return scale;
}

const key = Key('icon');

Widget stampChain() => const SizedBox.square(dimension: 74, key: key)
    .scale(0)
    .rotate(0)
    .step(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutQuart,
    )
    .scale(1.5)
    .rotate(15 * pi / 180)
    .step(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      delay: const Duration(milliseconds: 150),
    )
    .scale(1)
    .rotate(0);

void main() {
  testWidgets('replays via trigger are frame-for-frame identical',
      (tester) async {
    Widget host(int trigger) => MaterialApp(
          home: Center(child: stampChain().timeline(trigger: trigger)),
        );

    Future<List<double>> trace(int trigger) async {
      await tester.pumpWidget(host(trigger));
      final samples = <double>[];
      for (var t = 50; t <= 850; t += 50) {
        await tester.pump(const Duration(milliseconds: 50));
        samples.add(compositeScaleOf(tester, key));
      }
      await tester.pumpAndSettle();
      samples.add(compositeScaleOf(tester, key));
      return samples;
    }

    await tester.pumpWidget(host(0));
    await tester.pump();

    final play1 = await trace(1);
    final play2 = await trace(2);

    expect(play2, play1, reason: 'every run must be identical');
    expect(play1.reduce(max), closeTo(1.5, 1e-6),
        reason: 'the stamp must overshoot on every run');
  });

  testWidgets(
      'controller-driven press/release: press 2 identical to press 1, '
      'reverse returns to true rest', (tester) async {
    final controller = TimelineController();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: stampChain().timeline(controller: controller)),
      ),
    );
    await tester.pump();

    Future<List<double>> trace(Future<void> Function() drive) async {
      unawaited(drive());
      final samples = <double>[];
      for (var t = 50; t <= 850; t += 50) {
        await tester.pump(const Duration(milliseconds: 50));
        samples.add(compositeScaleOf(tester, key));
      }
      await tester.pumpAndSettle();
      samples.add(compositeScaleOf(tester, key));
      return samples;
    }

    final press1 = await trace(controller.play);
    final release = await trace(controller.reverse);
    final press2 = await trace(controller.play);

    expect(release.last, closeTo(0, 1e-9),
        reason: 'reverse must return to the true resting state');
    expect(press2, press1, reason: 'press 2 must trace identically');
    expect(press1.reduce(max), closeTo(1.5, 1e-6));
    expect(press2.reduce(max), closeTo(1.5, 1e-6));
  });

  testWidgets('controller interrupts mid-flight never snap', (tester) async {
    final controller = TimelineController();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: stampChain().timeline(controller: controller)),
      ),
    );
    await tester.pump();

    unawaited(controller.play());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Reverse mid-settle, then play again mid-reverse.
    unawaited(controller.reverse());
    final samples = <double>[compositeScaleOf(tester, key)];
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      samples.add(compositeScaleOf(tester, key));
    }
    unawaited(controller.play());
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      samples.add(compositeScaleOf(tester, key));
    }

    var maxJump = 0.0;
    for (var i = 1; i < samples.length; i++) {
      maxJump = max(maxJump, (samples[i] - samples[i - 1]).abs());
    }
    // At 16ms frames the steepest legitimate slope of this timeline moves
    // well under 0.2 per frame; a controller snap moves 0.5+ in one frame.
    expect(maxJump, lessThan(0.2));

    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(1.0, 1e-9));
  });
}
