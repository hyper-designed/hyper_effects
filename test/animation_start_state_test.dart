import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// Pins the contract of [AnimationStartState] after the eager/lazy rework:
/// `eager` inserts the widget with its effects already at their END values
/// without playing; `lazy` (the default) inserts at start values and stays
/// inert until the first trigger change.
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

Widget host(AnimationStartState startState, {int trigger = 0}) => MaterialApp(
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
    );

void main() {
  testWidgets('eager inserts at end values without playing', (tester) async {
    await tester.pumpWidget(host(AnimationStartState.eager));
    await tester.pump();
    expect(compositeScaleOf(tester, key), closeTo(2.0, 1e-9),
        reason: 'eager renders the end values on the very first frame');
    // And it is NOT animating — nothing changes over time.
    await tester.pump(const Duration(milliseconds: 150));
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
