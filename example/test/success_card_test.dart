import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects_demo/stories/success_card_animation.dart';

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
  testWidgets('stamp card overshoots on every press, not just the first',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SuccessCardAnimation())),
    );
    await tester.pump();

    // The second card's icon is the stamp.
    final stampIcon = find.byIcon(Icons.check_circle).last;
    final card = find.byType(GestureDetector).last;

    Future<void> press() async {
      await tester.tap(card, warnIfMissed: false);
      // 175ms into the slam: the stamp must be mid-overshoot.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 175));
      expect(
        compositeScaleOf(tester, stampIcon),
        greaterThan(1.3),
        reason: 'the slam-in must overshoot past 1.3',
      );
      // 400ms: inside the hold — the full 1.5 overshoot is on screen.
      await tester.pump(const Duration(milliseconds: 225));
      expect(compositeScaleOf(tester, stampIcon), closeTo(1.5, 0.01),
          reason: 'the overshoot must hold before settling');
      await tester.pumpAndSettle();
      expect(compositeScaleOf(tester, stampIcon), closeTo(1.0, 0.01),
          reason: 'the stamp must settle at 1.0');
    }

    Future<void> release() async {
      await tester.tap(card, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    await press();
    await release();
    // The second press must behave exactly like the first.
    await press();
  });
}
