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

Widget host({int repeat = 0}) => MaterialApp(
      home: Center(
        child: const SizedBox.square(dimension: 50, key: key)
            .scale(0)
            .step(
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear,
            )
            .scale(1)
            .timeline(trigger: #immediate, repeat: repeat),
      ),
    );

void main() {
  testWidgets('trigger: #immediate plays the timeline on mount',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 150));
    expect(compositeScaleOf(tester, key), closeTo(0.5, 1e-6),
        reason: '#immediate must play without any trigger change');
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(1.0, 1e-9));
  });

  testWidgets('rebuilding with #immediate does not replay', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(1.0, 1e-9));

    // Rebuild: the sentinel is unchanged, so nothing restarts.
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 150));
    expect(compositeScaleOf(tester, key), closeTo(1.0, 1e-9),
        reason: 'a rebuild is not a trigger change');
  });

  testWidgets('#immediate honors the repeat budget', (tester) async {
    await tester.pumpWidget(host(repeat: 1));
    // Cross the cycle-1 boundary, then sample cycle 2 mid-flight.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 150));
    expect(compositeScaleOf(tester, key), closeTo(0.5, 1e-6),
        reason: 'cycle 2 must play');
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(1.0, 1e-9));
  });
}
