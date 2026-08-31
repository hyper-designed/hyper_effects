import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// Pins the contract of [AnimationStartState]: `eager` plays the animation
/// once on mount and then keeps following the trigger; `lazy` (the default)
/// inserts at start values and stays inert until the first trigger change.
/// Both insert the widget at its starting values.
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

const key = Key('box');

Widget host(
  AnimationStartState startState, {
  int trigger = 0,
  AnimationBehavior? behavior,
}) =>
    HyperEffectsAnimationConfig(
      animationBehavior: behavior,
      child: MaterialApp(
        home: Center(
          child: const SizedBox.square(dimension: 50, key: key)
              .scale(2, from: 1)
              .animate(
                trigger: trigger,
                startState: startState,
                duration: const Duration(milliseconds: 300),
                curve: Curves.linear,
              ),
        ),
      ),
    );

void main() {
  testWidgets('eager plays on mount, starting from the start values',
      (tester) async {
    await tester.pumpWidget(host(AnimationStartState.eager));
    expect(compositeScaleOf(tester, key), closeTo(1.0, 1e-9),
        reason: 'eager renders the START values on the very first frame');

    await tester.pump(const Duration(milliseconds: 150));
    expect(compositeScaleOf(tester, key), closeTo(1.5, 1e-6),
        reason: 'eager is mid-flight halfway through the duration');

    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(2.0, 1e-9),
        reason: 'eager rests at the end values');
  });

  testWidgets('eager plays only once on mount, not on every rebuild',
      (tester) async {
    await tester.pumpWidget(host(AnimationStartState.eager));
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(2.0, 1e-9));

    // A plain rebuild with an unchanged trigger must not replay.
    await tester.pumpWidget(host(AnimationStartState.eager));
    await tester.pump(const Duration(milliseconds: 150));
    expect(compositeScaleOf(tester, key), closeTo(2.0, 1e-9),
        reason: 'a rebuild with the same trigger must not replay eager');

    // Neither must a dependency change: HyperEffectsAnimationConfig is an
    // inherited dependency of the effect, so changing it re-runs
    // didChangeDependencies.
    await tester.pumpWidget(
      host(AnimationStartState.eager, behavior: AnimationBehavior.preserve),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(compositeScaleOf(tester, key), closeTo(2.0, 1e-9),
        reason: 'a dependency change must not replay eager');
  });

  testWidgets('eager keeps its trigger live after the mount play',
      (tester) async {
    await tester.pumpWidget(host(AnimationStartState.eager));
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(2.0, 1e-9));

    // Unlike `trigger: #immediate`, a trigger change still replays it.
    await tester.pumpWidget(host(AnimationStartState.eager, trigger: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(compositeScaleOf(tester, key), closeTo(1.5, 1e-6),
        reason: 'a trigger change replays eager from the start values');

    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(2.0, 1e-9));
  });

  testWidgets('lazy inserts at start values and stays inert until triggered',
      (tester) async {
    await tester.pumpWidget(host(AnimationStartState.lazy));
    await tester.pump();
    expect(compositeScaleOf(tester, key), closeTo(1.0, 1e-9),
        reason: 'lazy renders the start values on the very first frame');
    await tester.pump(const Duration(milliseconds: 150));
    expect(compositeScaleOf(tester, key), closeTo(1.0, 1e-9),
        reason: 'lazy stays inert without a trigger change');

    // First trigger change plays normally.
    await tester.pumpWidget(host(AnimationStartState.lazy, trigger: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(compositeScaleOf(tester, key), closeTo(1.5, 1e-6),
        reason: 'a trigger change animates from start to end');
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(2.0, 1e-9));
  });
}
