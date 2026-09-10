import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  testWidgets('interrupted drive future settles', (tester) async {
    final animationKey = GlobalKey<AnimatedEffectState>();
    var onEndCalls = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox.shrink().fade(1, from: 0).animate(
              key: animationKey,
              trigger: 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear,
              onEnd: () => onEndCalls++,
            ),
      ),
    );

    var firstSettled = false;
    final first = animationKey.currentState!.drive();
    first.then((_) => firstSettled = true);
    await tester.pump(const Duration(milliseconds: 50));

    var secondSettled = false;
    animationKey.currentState!.drive().then((_) => secondSettled = true);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(firstSettled, isTrue,
        reason: 'a canceled ticker must settle its public drive future');
    expect(secondSettled, isTrue,
        reason: 'the replacement drive must also settle after its ticker');
    expect(onEndCalls, 1);
  });

  testWidgets('queued runs keep independent repeat budgets', (tester) async {
    final animationKey = GlobalKey<AnimatedEffectState>();
    var trigger = 0;
    var repeat = 1;
    var onEndCalls = 0;

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.shrink().fade(1, from: 0).animate(
                key: animationKey,
                trigger: trigger,
                duration: const Duration(milliseconds: 100),
                curve: Curves.linear,
                repeat: repeat,
                interruptable: false,
                onEnd: () => onEndCalls++,
              ),
        );

    await tester.pumpWidget(host());
    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 40));

    repeat = 0;
    trigger = 2;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 65));
    await tester.pump();

    expect(onEndCalls, 0,
        reason: 'A must begin its own repeated leg before any logical run '
            "completes; queuing B cannot replace A's repeat budget");
  });

  testWidgets('queued run cannot reset active reverse phase', (tester) async {
    final animationKey = GlobalKey<AnimatedEffectState>();
    var trigger = 0;

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.shrink().fade(1, from: 0).animate(
                key: animationKey,
                trigger: trigger,
                duration: const Duration(milliseconds: 100),
                curve: Curves.linear,
                repeat: 1,
                reverse: true,
                interruptable: false,
              ),
        );

    await tester.pumpWidget(host());
    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 40));

    trigger = 2;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 65));
    await tester.pump();

    expect(animationKey.currentState!.controller.value, greaterThan(0.8),
        reason: 'A must begin its reverse leg at the completed endpoint; '
            'queuing B cannot reset A to a new forward leg');
  });

  testWidgets('queued runs retain their own onEnd callback', (tester) async {
    final animationKey = GlobalKey<AnimatedEffectState>();
    var trigger = 0;
    var callbackLabel = 'A';
    final callbacks = <String>[];

    Widget host() {
      final label = callbackLabel;
      return Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox.shrink().fade(1, from: 0).animate(
              key: animationKey,
              trigger: trigger,
              duration: const Duration(milliseconds: 100),
              curve: Curves.linear,
              interruptable: false,
              onEnd: () => callbacks.add(label),
            ),
      );
    }

    await tester.pumpWidget(host());
    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 40));

    callbackLabel = 'B';
    trigger = 2;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 65));
    await tester.pump();

    expect(callbacks, ['A'],
        reason: 'completion belongs to the run that started, not the latest '
            'widget configuration');
  });

  testWidgets('queued run retains its own motion duration', (tester) async {
    final animationKey = GlobalKey<AnimatedEffectState>();
    var trigger = 0;
    var duration = const Duration(milliseconds: 100);
    var callbackLabel = 'A';
    final callbacks = <String>[];

    Widget host() {
      final label = callbackLabel;
      return Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox.shrink().fade(1, from: 0).animate(
              key: animationKey,
              trigger: trigger,
              duration: duration,
              curve: Curves.linear,
              repeat: 1,
              interruptable: false,
              onEnd: () => callbacks.add(label),
            ),
      );
    }

    await tester.pumpWidget(host());
    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 40));

    callbackLabel = 'B';
    duration = const Duration(milliseconds: 300);
    trigger = 2;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 65));
    await tester.pump();
    expect(callbacks, isEmpty,
        reason: 'A must begin its repeated leg before completing');

    await tester.pump(const Duration(milliseconds: 105));
    await tester.pump();

    expect(callbacks, ['A'],
        reason: 'A must finish on its captured 100ms motion even though B '
            'was queued with a 300ms motion');
  });

  testWidgets('reset cancels delayed non-interruptible run', (tester) async {
    final animationKey = GlobalKey<AnimatedEffectState>();
    var onEndCalls = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox.shrink().fade(1, from: 0).animate(
              key: animationKey,
              trigger: 0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.linear,
              delay: const Duration(milliseconds: 100),
              interruptable: false,
              onEnd: () => onEndCalls++,
            ),
      ),
    );

    var settled = false;
    animationKey.currentState!.drive().then((_) => settled = true);
    await tester.pump(const Duration(milliseconds: 50));
    animationKey.currentState!.reset();
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(animationKey.currentState!.controller.value, 0,
        reason: 'reset must prevent the delayed run from restarting');
    expect(onEndCalls, 0);
    expect(settled, isTrue,
        reason: 'canceling the delayed run must settle its public future');
  });

  testWidgets('interruptible trigger supersedes old non-interruptible delay',
      (tester) async {
    final animationKey = GlobalKey<AnimatedEffectState>();
    var trigger = 0;
    var interruptable = false;
    var callbackLabel = 'A';
    final callbacks = <String>[];

    Widget host() {
      final label = callbackLabel;
      return Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox.shrink().fade(1, from: 0).animate(
              key: animationKey,
              trigger: trigger,
              duration: const Duration(milliseconds: 100),
              curve: Curves.linear,
              delay: const Duration(milliseconds: 100),
              interruptable: interruptable,
              onEnd: () => callbacks.add(label),
            ),
      );
    }

    await tester.pumpWidget(host());
    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 40));

    callbackLabel = 'B';
    interruptable = true;
    trigger = 2;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 70));
    await tester.pump(const Duration(milliseconds: 16));
    expect(animationKey.currentState!.controller.value, 0,
        reason: 'A must remain canceled after its old delay expires and '
            'before B reaches its own deadline');

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(callbacks, ['B'],
        reason: 'the interruptible run supersedes delayed non-interruptible '
            'work; A must never resume or complete');

    await tester.pump(const Duration(milliseconds: 200));
    expect(callbacks, ['B'],
        reason: 'A must remain canceled past its deadline');
  });

  testWidgets('delayed run evaluates predicates once', (tester) async {
    var trigger = 0;
    var playCalls = 0;
    var skipCalls = 0;

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.shrink().fade(1, from: 0).animate(
                trigger: trigger,
                duration: const Duration(milliseconds: 100),
                curve: Curves.linear,
                delay: const Duration(milliseconds: 100),
                playIf: () {
                  playCalls++;
                  return true;
                },
                skipIf: () {
                  skipCalls++;
                  return false;
                },
              ),
        );

    await tester.pumpWidget(host());
    playCalls = 0;
    skipCalls = 0;

    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();

    expect(playCalls, 1,
        reason: 'playIf is a decision for one logical run, not each phase');
    expect(skipCalls, 1,
        reason: 'skipIf is a decision for one logical run, not each phase');
  });

  testWidgets('drive after disposal is a settled no-op', (tester) async {
    final animationKey = GlobalKey<AnimatedEffectState>();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox.shrink().fade(1, from: 0).animate(
              key: animationKey,
              trigger: 0,
              duration: const Duration(milliseconds: 100),
              delay: const Duration(milliseconds: 100),
            ),
      ),
    );
    final state = animationKey.currentState!;

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    var settled = false;
    state.drive().then((_) => settled = true);
    await tester.pump();

    expect(settled, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('queued run is not published before it starts', (tester) async {
    var trigger = 0;
    const childKey = Key('queued-publication-child');

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.shrink(key: childKey).fade(1, from: 0).animate(
                trigger: trigger,
                duration: const Duration(milliseconds: 200),
                curve: Curves.linear,
                interruptable: false,
              ),
        );

    double opacity() => tester
        .widgetList<Opacity>(find.ancestor(
          of: find.byKey(childKey),
          matching: find.byType(Opacity),
        ))
        .fold<double>(1, (value, widget) => value * widget.opacity);

    await tester.pumpWidget(host());
    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 80));
    final beforeEnqueue = opacity();

    trigger = 2;
    await tester.pumpWidget(host());

    expect(opacity(), closeTo(beforeEnqueue, 1e-6),
        reason: 'enqueueing B must be visually inert while A owns the '
            'controller');
  });

  testWidgets('rejected interrupting run stops superseded ticker',
      (tester) async {
    var trigger = 0;
    var allowPlay = true;
    const childKey = Key('rejected-interrupt-child');

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.shrink(key: childKey).fade(1, from: 0).animate(
                trigger: trigger,
                duration: const Duration(milliseconds: 300),
                curve: Curves.linear,
                playIf: () => allowPlay,
              ),
        );

    double opacity() => tester
        .widgetList<Opacity>(find.ancestor(
          of: find.byKey(childKey),
          matching: find.byType(Opacity),
        ))
        .fold<double>(1, (value, widget) => value * widget.opacity);

    await tester.pumpWidget(host());
    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 100));

    allowPlay = false;
    trigger = 2;
    await tester.pumpWidget(host());
    final rejectedAt = opacity();
    await tester.pump(const Duration(milliseconds: 100));

    expect(opacity(), closeTo(rejectedAt, 1e-6),
        reason: 'superseded motion must stop even when the replacement run '
            'is rejected by playIf');
  });

  testWidgets('lazy mount does not evaluate run predicates', (tester) async {
    var playCalls = 0;
    var skipCalls = 0;
    const childKey = Key('lazy-predicate-child');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox.shrink(key: childKey).fade(1, from: 0).animate(
              trigger: 0,
              duration: const Duration(milliseconds: 100),
              playIf: () {
                playCalls++;
                return false;
              },
              skipIf: () {
                skipCalls++;
                return true;
              },
            ),
      ),
    );

    final opacity = tester
        .widgetList<Opacity>(find.ancestor(
          of: find.byKey(childKey),
          matching: find.byType(Opacity),
        ))
        .fold<double>(1, (value, widget) => value * widget.opacity);
    expect(opacity, 0);
    expect(playCalls, 0);
    expect(skipCalls, 0);
  });

  testWidgets('null widget receiver renders an empty child', (tester) async {
    const Widget? child = null;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: child.animate(
          trigger: 0,
          duration: const Duration(milliseconds: 100),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('playIf false leaves a nonzero controller untouched',
      (tester) async {
    final key = GlobalKey<AnimatedEffectState>();
    var allowPlay = true;
    var onEndCalls = 0;

    Widget host(int trigger) => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.shrink().fade(1, from: 0).animate(
                key: key,
                trigger: trigger,
                duration: const Duration(milliseconds: 100),
                playIf: () => allowPlay,
                onEnd: () => onEndCalls++,
              ),
        );

    await tester.pumpWidget(host(0));
    await tester.pumpWidget(host(1));
    await tester.pumpAndSettle();
    expect(key.currentState!.controller.value, 1);
    expect(onEndCalls, 1);

    allowPlay = false;
    await tester.pumpWidget(host(2));
    await tester.pump();

    expect(key.currentState!.controller.value, 1);
    expect(onEndCalls, 1);
  });

  testWidgets('skipIf true jumps to end without repeat or onEnd',
      (tester) async {
    final key = GlobalKey<AnimatedEffectState>();
    var onEndCalls = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox.shrink().fade(1, from: 0).animate(
              key: key,
              trigger: 0,
              duration: const Duration(milliseconds: 100),
              repeat: 2,
              skipIf: () => true,
              onEnd: () => onEndCalls++,
            ),
      ),
    );
    key.currentState!.drive();
    await tester.pump();

    expect(key.currentState!.controller.value, 1);
    expect(onEndCalls, 0);
  });

  testWidgets('infinite repeat remains active until reset', (tester) async {
    final key = GlobalKey<AnimatedEffectState>();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox.shrink().fade(1, from: 0).animate(
              key: key,
              trigger: 0,
              duration: const Duration(milliseconds: 20),
              repeat: -1,
            ),
      ),
    );

    var settled = false;
    key.currentState!.drive().then((_) => settled = true);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 25));
      await tester.pump();
    }
    expect(settled, isFalse);

    key.currentState!.reset();
    await tester.pump();
    expect(settled, isTrue);
  });

  testWidgets('zero-delay drive settles after its controller leg',
      (tester) async {
    final key = GlobalKey<AnimatedEffectState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox.shrink().fade(1, from: 0).animate(
              key: key,
              trigger: 0,
              duration: const Duration(milliseconds: 20),
            ),
      ),
    );

    var settled = false;
    key.currentState!.drive().then((_) => settled = true);
    expect(settled, isFalse);
    await tester.pump(const Duration(milliseconds: 25));
    await tester.pumpAndSettle();
    expect(settled, isTrue);
  });
}
