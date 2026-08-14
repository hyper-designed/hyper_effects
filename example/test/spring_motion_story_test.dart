import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects_demo/stories/spring_motion.dart';

double compositeTranslationXOf(WidgetTester tester, Finder target) {
  final transforms = tester.widgetList<Transform>(
    find.ancestor(of: target, matching: find.byType(Transform)),
  );
  var dx = 0.0;
  for (final t in transforms) {
    dx += t.transform.entry(0, 3);
  }
  return dx;
}

double compositeScaleOf(WidgetTester tester, Finder target) {
  final transforms = tester.widgetList<Transform>(
    find.ancestor(of: target, matching: find.byType(Transform)),
  );
  var scale = 1.0;
  for (final t in transforms) {
    final m = t.transform;
    scale *= Offset(m.entry(0, 0), m.entry(1, 0)).distance;
  }
  return scale;
}

void main() {
  testWidgets('the toggle slides with a spring: overshoots, settles exactly',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SpringMotionStory())),
    );
    final avatar = find.byType(CircleAvatar);
    final restLeft = compositeTranslationXOf(tester, avatar);

    await tester.tap(find.text('Toggle'));
    await tester.pump();
    var peak = restLeft;
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      peak = max(peak, compositeTranslationXOf(tester, avatar));
    }
    await tester.pumpAndSettle();
    final restRight = compositeTranslationXOf(tester, avatar);

    expect(restRight, greaterThan(restLeft + 100),
        reason: 'the avatar must travel to the right anchor');
    expect(peak, greaterThan(restRight + 1),
        reason: 'a bouncy spring must overshoot its anchor');
  });

  testWidgets('the badge pops on a spring-driven timeline step',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SpringMotionStory())),
    );
    final badge = find.byIcon(Icons.celebration);

    await tester.tap(find.text('Pop'));
    await tester.pump();
    var peak = 0.0;
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      peak = max(peak, compositeScaleOf(tester, badge));
    }
    expect(peak, greaterThan(1.001),
        reason: 'the spring pop must overshoot full size');
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, badge), closeTo(1.0, 1e-9),
        reason: 'the pop must rest at exactly full size');
  });
}
