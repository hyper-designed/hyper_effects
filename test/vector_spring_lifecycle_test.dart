import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/motion/vector_spring.dart';

import 'support/geometry.dart';

const _boxKey = Key('box');

void main() {
  testWidgets('reverse spring is a fresh forward-time solve', (tester) async {
    final animationKey = GlobalKey<AnimatedEffectState>();
    const motion = SpringMotion(
      SpringDescription(mass: 1, stiffness: 100, damping: 10),
    );
    var trigger = 0;

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.square(dimension: 20, key: _boxKey)
              .translateX(120, from: -120)
              .animate(
                key: animationKey,
                trigger: trigger,
                motion: motion,
                repeat: 1,
                reverse: true,
              ),
        );

    await tester.pumpWidget(host());
    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pump(motion.effectiveDuration);
    await tester.pump();

    expect(translationXOf(tester, _boxKey), closeTo(120, 1e-6));

    await tester.pump(const Duration(milliseconds: 1));
    expect(
        animationKey.currentState!.controller.status, AnimationStatus.forward,
        reason: 'a reverse spring advances fresh physical time forward');
    await tester.pump(Duration(
      microseconds: motion.effectiveDuration.inMicroseconds ~/ 4,
    ));
    final controllerValue = animationKey.currentState!.controller.value;
    final rendered = translationXOf(tester, _boxKey);
    final reverseTime = controllerValue;
    final seconds = motion.effectiveDuration.inMicroseconds /
        Duration.microsecondsPerSecond;
    final fresh = springCoefficients(
      motion.description,
      reverseTime * seconds,
    );
    final backward = springCoefficients(
      motion.description,
      (1 - controllerValue) * seconds,
    );
    final expectedFresh = -120 + (120 - -120) * fresh.a;
    final expectedBackward = 120 + (-120 - 120) * backward.a;

    expect((expectedFresh - expectedBackward).abs(), greaterThan(10),
        reason: 'the sample must discriminate the two equations');
    expect(rendered, closeTo(expectedFresh, 1e-3));
  });

  testWidgets('completed reverse spring rests exactly at its start value',
      (tester) async {
    final animationKey = GlobalKey<AnimatedEffectState>();
    const motion = SpringMotion(
      SpringDescription(mass: 1, stiffness: 100, damping: 10),
    );
    var trigger = 0;

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.square(dimension: 20, key: _boxKey)
              .translateX(120, from: -120)
              .animate(
                key: animationKey,
                trigger: trigger,
                motion: motion,
                repeat: 1,
                reverse: true,
              ),
        );

    await tester.pumpWidget(host());
    trigger = 1;
    await tester.pumpWidget(host());

    // Forward leg completes at the end value. The simulation's isDone is
    // strictly greater-than its duration, so one extra millisecond is
    // needed to finish each leg and hand off to the next.
    await tester.pump(motion.effectiveDuration);
    await tester.pump(const Duration(milliseconds: 1));
    expect(translationXOf(tester, _boxKey), closeTo(120, 1e-6));

    // Reverse leg completes: the run rests at its START, with no snap
    // to the end value at the final frame.
    await tester.pump(motion.effectiveDuration);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(translationXOf(tester, _boxKey), closeTo(-120, 1e-6),
        reason: 'the reverse leg solves end-to-start, so its resting '
            'endpoint is the start value');

    // The resting frame must be stable across later idle pumps.
    await tester.pump(const Duration(seconds: 1));
    expect(translationXOf(tester, _boxKey), closeTo(-120, 1e-6));
  });

  testWidgets('vector springs honor implicit idle start', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox.square(dimension: 20, key: _boxKey)
            .padAll(120)
            .animate(
              trigger: #immediate,
              motion: const SpringMotion(
                SpringDescription(mass: 1, stiffness: 100, damping: 10),
              ),
              resetValues: true,
            ),
      ),
    );

    double padding() => tester
        .widget<Padding>(find.byType(Padding))
        .padding
        .resolve(TextDirection.ltr)
        .left;

    expect(padding(), 0,
        reason: 'implicit PaddingEffect start is its numeric zero idle');
    await tester.pump(const Duration(milliseconds: 100));
    expect(padding(), greaterThan(0));
    await tester.pumpAndSettle();
    expect(padding(), closeTo(120, 1e-6));
  });

  testWidgets('completed spring replay starts from rest', (tester) async {
    final animationKey = GlobalKey<AnimatedEffectState>();
    const motion = SpringMotion(
      SpringDescription(mass: 1, stiffness: 100, damping: 10),
    );
    var trigger = 0;
    var target = -120.0;

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.square(dimension: 20, key: _boxKey)
              .translateX(target, from: -120)
              .animate(
                key: animationKey,
                trigger: trigger,
                motion: motion,
              ),
        );

    await tester.pumpWidget(host());
    target = 120;
    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 100));

    target = -120;
    trigger = 2;
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(translationXOf(tester, _boxKey), closeTo(-120, 1e-6));

    trigger = 3;
    await tester.pumpWidget(host());
    final replayStart = translationXOf(tester, _boxKey);
    await tester.pump(const Duration(milliseconds: 32));

    final t = animationKey.currentState!.controller.value;
    final seconds = motion.effectiveDuration.inMicroseconds /
        Duration.microsecondsPerSecond;
    final c = springCoefficients(motion.description, t * seconds);
    final expectedFromRest = -120 + (replayStart - -120) * c.a;

    expect(translationXOf(tester, _boxKey), closeTo(expectedFromRest, 1e-3),
        reason: 'a completed prior run must not inject retarget velocity into '
            'a later trigger-only replay');
  });

  testWidgets('retarget after completion captures exact endpoint',
      (tester) async {
    const motion = SpringMotion(
      SpringDescription(mass: 1, stiffness: 100, damping: 10),
    );
    var trigger = 0;
    var target = -1000000000.0;

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.square(dimension: 20, key: _boxKey)
              .translateX(target, from: -1000000000)
              .animate(trigger: trigger, motion: motion),
        );

    await tester.pumpWidget(host());
    target = 1000000000;
    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final completed = translationXOf(tester, _boxKey);
    expect(completed, 1000000000);

    target = -1000000000;
    trigger = 2;
    await tester.pumpWidget(host());

    expect(translationXOf(tester, _boxKey), completed,
        reason: 'retarget capture must start at the exact endpoint painted '
            'by the completed frame, not the finite-bound spring residual');
  });

  testWidgets('simultaneous target and motion update samples outgoing motion',
      (tester) async {
    const motionA = SpringMotion(
      SpringDescription(mass: 1, stiffness: 80, damping: 8),
    );
    const motionB = SpringMotion(
      SpringDescription(mass: 1, stiffness: 800, damping: 55),
    );
    var trigger = 0;
    var target = -120.0;
    SpringMotion motion = motionA;

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.square(dimension: 20, key: _boxKey)
              .translateX(target, from: -120)
              .animate(trigger: trigger, motion: motion),
        );

    await tester.pumpWidget(host());
    target = 120;
    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 120));

    final outgoingRendered = translationXOf(tester, _boxKey);
    final state =
        tester.state<AnimatedEffectState>(find.byType(AnimatedEffect));
    final oldT = state.controller.value;
    final bSeconds = motionB.effectiveDuration.inMicroseconds /
        Duration.microsecondsPerSecond;
    final b = springCoefficients(motionB.description, oldT * bSeconds);
    final incomingMotionPrediction = 120 + (-120 - 120) * b.a;
    expect((incomingMotionPrediction - outgoingRendered).abs(), greaterThan(10),
        reason: 'the two motions must predict visibly different captures');

    target = -120;
    motion = motionB;
    trigger = 2;
    await tester.pumpWidget(host());

    expect(translationXOf(tester, _boxKey), closeTo(outgoingRendered, 1e-3),
        reason: 'retarget capture must use the outgoing motion that painted '
            'the prior frame');
  });

  testWidgets('reset during reverse spring renders original start',
      (tester) async {
    final animationKey = GlobalKey<AnimatedEffectState>();
    const motion = SpringMotion(
      SpringDescription(mass: 1, stiffness: 100, damping: 10),
    );
    var trigger = 0;

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.square(dimension: 20, key: _boxKey)
              .translateX(120, from: -120)
              .animate(
                key: animationKey,
                trigger: trigger,
                motion: motion,
                repeat: 1,
                reverse: true,
              ),
        );

    await tester.pumpWidget(host());
    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pump(motion.effectiveDuration);
    await tester.pump(const Duration(milliseconds: 1));
    expect(
        animationKey.currentState!.controller.status, AnimationStatus.forward,
        reason: 'spring reverse uses fresh forward physical time');

    animationKey.currentState!.reset();
    await tester.pump();

    expect(animationKey.currentState!.controller.value, 0);
    expect(translationXOf(tester, _boxKey), -120,
        reason: 'reset clears reverse-leg publication and renders start');
  });
}
