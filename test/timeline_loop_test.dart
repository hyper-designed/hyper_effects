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

const key = Key('box');

Widget host({
  Object? trigger = #immediate,
  int repeat = 0,
  VoidCallback? onEnd,
}) =>
    MaterialApp(
      home: Center(
        child: const SizedBox.square(dimension: 50, key: key)
            .scale(0)
            .step(
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear,
            )
            .scale(1)
            .timeline(
              trigger: trigger,
              repeat: repeat,
              onEnd: onEnd,
            ),
      ),
    );

void main() {
  testWidgets('#immediate plays on mount without any trigger change',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 150));
    expect(compositeScaleOf(tester, key), closeTo(0.5, 1e-6),
        reason: 'the timeline must be mid-flight on its own');
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(1.0, 1e-9));
  });

  testWidgets('repeat -1 loops forever', (tester) async {
    await tester.pumpWidget(host(repeat: -1));
    await tester.pump(const Duration(milliseconds: 150));
    expect(compositeScaleOf(tester, key), closeTo(0.5, 1e-6));
    // One full cycle later: mid-flight again, not resting.
    await tester.pump(const Duration(milliseconds: 300));
    expect(compositeScaleOf(tester, key), closeTo(0.5, 1e-6),
        reason: 'cycle 2 must replay, not rest');
    await tester.pump(const Duration(milliseconds: 300));
    expect(compositeScaleOf(tester, key), closeTo(0.5, 1e-6),
        reason: 'cycle 3 must replay, not rest');
  });

  testWidgets('finite repeat plays N+1 cycles then rests; onEnd fires once',
      (tester) async {
    var ends = 0;
    await tester.pumpWidget(host(
        repeat: 2,
        onEnd: () {
          ends++;
        }));
    // A cycle completes on the first tick strictly past its duration, and
    // the next cycle's clock starts at that boundary-crossing frame.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 150));
    expect(compositeScaleOf(tester, key), closeTo(0.5, 1e-6),
        reason: 'cycle 2 must be playing');
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 150));
    expect(compositeScaleOf(tester, key), closeTo(0.5, 1e-6),
        reason: 'cycle 3 must be playing');
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(1.0, 1e-9),
        reason: 'after the final cycle the timeline rests at its end');
    expect(ends, 1, reason: 'onEnd fires once, at the true end');
  });

  testWidgets('a trigger change restores the full repeat budget',
      (tester) async {
    await tester.pumpWidget(host(trigger: 0, repeat: 1));
    await tester.pump();

    await tester.pumpWidget(host(trigger: 1, repeat: 1));
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(1.0, 1e-9));

    // Re-trigger: both cycles must play again.
    await tester.pumpWidget(host(trigger: 2, repeat: 1));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 150));
    expect(compositeScaleOf(tester, key), closeTo(0.5, 1e-6),
        reason: 'cycle 2 of the re-triggered run must be playing');
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(1.0, 1e-9));
  });
}
