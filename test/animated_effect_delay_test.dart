import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:material_ui/material_ui.dart';

const key = Key('box');
const delay = Duration(milliseconds: 130);
const duration = Duration(milliseconds: 300);
const frame = Duration(milliseconds: 16);

/// The opacity actually painted above the keyed box. Multiplying every
/// [Opacity] ancestor keeps the reading correct if the host ever wraps the
/// subject in a second, incidental one.
double opacityOf(WidgetTester tester) {
  final layers = tester.widgetList<Opacity>(
    find.ancestor(of: find.byKey(key), matching: find.byType(Opacity)),
  );
  return layers.fold<double>(1, (product, layer) => product * layer.opacity);
}

/// The horizontal translation actually painted above the keyed box.
double translationXOf(WidgetTester tester) {
  final transforms = tester.widgetList<Transform>(
    find.ancestor(of: find.byKey(key), matching: find.byType(Transform)),
  );
  var dx = 0.0;
  for (final transform in transforms) {
    dx += transform.transform.entry(0, 3);
  }
  return dx;
}

Widget fadeHost(bool active, {Duration hostDelay = delay}) => MaterialApp(
      home: Center(
        child: const SizedBox.square(dimension: 50, key: key)
            .fade(active ? 1 : 0)
            .animate(
              trigger: active,
              duration: duration,
              curve: Curves.linear,
              delay: hostDelay,
            ),
      ),
    );

Widget slideHost(bool right) => MaterialApp(
      home: Center(
        child: const SizedBox.square(dimension: 50, key: key)
            .translateX(right ? 120 : -120)
            .animate(
              trigger: right,
              duration: duration,
              curve: Curves.linear,
              delay: delay,
            ),
      ),
    );

/// Runs a delayed animation all the way out. [WidgetTester.pumpAndSettle]
/// alone would stop short: nothing is scheduled while the delay timer is
/// pending, so the clock has to be walked past it first.
Future<void> runOut(WidgetTester tester) async {
  await tester.pump(delay + frame);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a delayed re-trigger holds the STARTING value through the delay',
      (tester) async {
    // A round trip first. The very first run of any effect looks correct even
    // when broken, because a controller that has never run already rests at 0.
    // The bug only surfaces from the second run onward, when the controller
    // still carries the value the previous run left it at.
    await tester.pumpWidget(fadeHost(false));
    await tester.pump();
    expect(opacityOf(tester), closeTo(0, 1e-6));

    await tester.pumpWidget(fadeHost(true));
    await runOut(tester);
    expect(opacityOf(tester), closeTo(1, 1e-6));

    await tester.pumpWidget(fadeHost(false));
    await runOut(tester);
    expect(opacityOf(tester), closeTo(0, 1e-6),
        reason: 'precondition: the round trip must land back at 0');

    // Third trigger: 0 -> 1, sampled per frame across the delay window.
    await tester.pumpWidget(fadeHost(true));
    final samples = <double>[opacityOf(tester)];
    for (var elapsed = Duration.zero; elapsed < delay; elapsed += frame) {
      await tester.pump(frame);
      samples.add(opacityOf(tester));
    }

    expect(
      samples.reduce((a, b) => a > b ? a : b),
      closeTo(0, 1e-6),
      reason: 'the delay must hold the START value, never flash the target. '
          'samples: $samples',
    );

    // ...and once the delay is over, it really does animate.
    await tester.pump(frame);
    await tester.pump(const Duration(milliseconds: 120));
    final midway = opacityOf(tester);
    expect(midway, greaterThan(0.05));
    expect(midway, lessThan(0.95));

    await tester.pumpAndSettle();
    expect(opacityOf(tester), closeTo(1, 1e-6));
  });

  testWidgets('only the newest interruptable delay may start the controller',
      (tester) async {
    var onEndCalls = 0;

    Widget host(int trigger) => MaterialApp(
          home: Center(
            child: const SizedBox.square(dimension: 50, key: key)
                .fade(1, from: 0)
                .animate(
                  trigger: trigger,
                  duration: duration,
                  curve: Curves.linear,
                  delay: delay,
                  onEnd: () => onEndCalls++,
                ),
          ),
        );

    await tester.pumpWidget(host(0));
    await tester.pump();
    final state = tester.state<AnimatedEffectState>(
      find.byType(AnimatedEffect),
    );

    // Start A, then supersede it twice while each run is still delayed. The
    // timers cannot be cancelled, so all three callbacks will eventually wake;
    // only C owns the controller by then.
    await tester.pumpWidget(host(1)); // A: due at 130ms.
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpWidget(host(2)); // B: due at 170ms.
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpWidget(host(3)); // C: due at 210ms.

    // Cross A's and B's old deadlines. Neither stale callback may drive.
    await tester.pump(const Duration(milliseconds: 66));
    await tester.pump(frame);
    expect(state.controller.value, 0,
        reason: 'A must retire when its obsolete delay wakes');
    await tester.pump(const Duration(milliseconds: 24));
    await tester.pump(frame);
    expect(state.controller.value, 0,
        reason: 'B must retire when its obsolete delay wakes');

    // C reaches its own deadline and is the only run allowed to move.
    await tester.pump(const Duration(milliseconds: 24));
    await tester.pump(const Duration(milliseconds: 120));
    expect(state.controller.value, greaterThan(0));
    expect(state.controller.value, lessThan(1));

    await tester.pumpAndSettle();
    expect(state.controller.value, 1);
    expect(onEndCalls, 1,
        reason: 'superseded delayed runs must not complete or call onEnd');
  });

  testWidgets('non-interruptable delayed triggers stay serialized',
      (tester) async {
    var onEndCalls = 0;

    Widget host(int trigger) => MaterialApp(
          home: Center(
            child: const SizedBox.square(dimension: 50, key: key)
                .fade(1, from: 0)
                .animate(
                  trigger: trigger,
                  duration: duration,
                  curve: Curves.linear,
                  delay: delay,
                  interruptable: false,
                  onEnd: () => onEndCalls++,
                ),
          ),
        );

    await tester.pumpWidget(host(0));
    await tester.pump();
    final state = tester.state<AnimatedEffectState>(
      find.byType(AnimatedEffect),
    );

    await tester.pumpWidget(host(1)); // A starts waiting.
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpWidget(host(2)); // B queues behind all of A.

    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(frame);
    expect(state.controller.value, greaterThan(0),
        reason: 'A must be the run in flight');

    // Finish A. B must only now begin its own delay, parked at its start.
    await tester.pump(const Duration(milliseconds: 300));
    expect(onEndCalls, 1);
    expect(state.controller.value, 0,
        reason: 'B must wait through a fresh delay after A completes');

    await tester.pump(delay + frame);
    await tester.pump(const Duration(milliseconds: 150));
    expect(state.controller.value, greaterThan(0));
    expect(state.controller.value, lessThan(1));

    await tester.pumpAndSettle();
    expect(state.controller.value, 1);
    expect(onEndCalls, 2);
  });

  testWidgets('a delayed reverse leg holds at the END value, not the start',
      (tester) async {
    // `repeat`/`reverse` drives a second leg from `onAnimationStatusChanged`,
    // and that leg starts at 1, not 0. The parked value must branch the same
    // way the controller call below it does, otherwise the pulse snaps back
    // to its start before the reverse leg even begins.
    Widget pulse(int trigger) => MaterialApp(
          home: Center(
            child: const SizedBox.square(dimension: 50, key: key)
                .fade(1, from: 0)
                .animate(
                  trigger: trigger,
                  duration: duration,
                  curve: Curves.linear,
                  delay: delay,
                  repeat: 1,
                  reverse: true,
                ),
          ),
        );

    await tester.pumpWidget(pulse(0));
    await tester.pump();

    await tester.pumpWidget(pulse(1));
    // Walk past the delay and through the whole forward leg.
    await tester.pump(delay + frame);
    await tester.pump(duration + frame);
    expect(opacityOf(tester), closeTo(1, 1e-6),
        reason: 'precondition: the forward leg must land at 1');

    // The reverse leg is now waiting out its own delay. It must hold at 1.
    final samples = <double>[opacityOf(tester)];
    for (var elapsed = Duration.zero; elapsed < delay; elapsed += frame) {
      await tester.pump(frame);
      samples.add(opacityOf(tester));
    }
    expect(
      samples.reduce((a, b) => a < b ? a : b),
      closeTo(1, 1e-6),
      reason: 'the inter-leg delay must hold at 1. samples: $samples',
    );

    await tester.pump(frame);
    await tester.pumpAndSettle();
    expect(opacityOf(tester), closeTo(0, 1e-6),
        reason: 'the reverse leg must still run all the way back');
  });

  testWidgets('a delayed retarget holds at the INTERRUPTED position',
      (tester) async {
    // Guards the retarget/momentum capture: `EffectWidget` folds the in-flight
    // run into its `start` using a one-frame-stale `previousAnimationValue`
    // snapshot that is only refreshed in `didChangeDependencies`. Parking the
    // controller synchronously in the ancestor's `didUpdateWidget` must not
    // disturb that, so the render has to freeze exactly where it was
    // interrupted and then continue from there.
    await tester.pumpWidget(slideHost(false));
    await tester.pump();

    await tester.pumpWidget(slideHost(true));
    await tester.pump(delay + frame);
    await tester.pump(const Duration(milliseconds: 150));

    final interrupted = translationXOf(tester);
    expect(interrupted, greaterThan(-100));
    expect(interrupted, lessThan(100),
        reason: 'precondition: the box must be caught mid-flight');

    await tester.pumpWidget(slideHost(false));
    var maxDrift = (translationXOf(tester) - interrupted).abs();
    for (var elapsed = Duration.zero; elapsed < delay; elapsed += frame) {
      await tester.pump(frame);
      final drift = (translationXOf(tester) - interrupted).abs();
      if (drift > maxDrift) maxDrift = drift;
    }
    expect(maxDrift, lessThan(1),
        reason: 'the delay must freeze the render at the interrupted '
            'position, not jump');

    await tester.pump(frame);
    await tester.pumpAndSettle();
    expect(translationXOf(tester), closeTo(-120, 1e-6));
  });

  testWidgets('zero delay is unchanged: the run starts on the same frame',
      (tester) async {
    const none = Duration.zero;

    await tester.pumpWidget(fadeHost(false, hostDelay: none));
    await tester.pump();

    await tester.pumpWidget(fadeHost(true, hostDelay: none));
    await tester.pumpAndSettle();
    expect(opacityOf(tester), closeTo(1, 1e-6));

    await tester.pumpWidget(fadeHost(false, hostDelay: none));
    await tester.pumpAndSettle();
    expect(opacityOf(tester), closeTo(0, 1e-6));

    // Third trigger, with no delay to wait out: the value must leave the
    // start immediately rather than sitting still for a frame.
    await tester.pumpWidget(fadeHost(true, hostDelay: none));
    expect(opacityOf(tester), closeTo(0, 1e-6));

    await tester.pump(const Duration(milliseconds: 150));
    expect(opacityOf(tester), closeTo(0.5, 0.05));

    await tester.pump(const Duration(milliseconds: 160));
    expect(opacityOf(tester), closeTo(1, 1e-6),
        reason: 'no delay means the run finishes within its own duration');
  });

  testWidgets('same-target delayed retrigger freezes at interrupted position',
      (tester) async {
    var trigger = 0;

    Widget host() => MaterialApp(
          home: Center(
            child: const SizedBox.square(dimension: 50, key: key)
                .translateX(120, from: -120)
                .animate(
                  trigger: trigger,
                  duration: duration,
                  curve: Curves.linear,
                  delay: delay,
                ),
          ),
        );

    await tester.pumpWidget(host());
    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pump(delay + frame);
    await tester.pump(const Duration(milliseconds: 120));

    final interrupted = translationXOf(tester);
    expect(interrupted, greaterThan(-100));
    expect(interrupted, lessThan(100));

    trigger = 2;
    await tester.pumpWidget(host());
    var maxDrift = (translationXOf(tester) - interrupted).abs();
    for (var elapsed = Duration.zero; elapsed < delay; elapsed += frame) {
      await tester.pump(frame);
      final drift = (translationXOf(tester) - interrupted).abs();
      if (drift > maxDrift) maxDrift = drift;
    }

    expect(maxDrift, lessThan(1),
        reason: 'a trigger-only retrigger must hold the interrupted render, '
            'not snap to the original from value');
  });
}
