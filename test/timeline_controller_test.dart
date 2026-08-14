import 'dart:async';

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

Widget host(TimelineController controller) => MaterialApp(
      home: Center(
        child: const SizedBox.square(dimension: 50, key: key)
            .scale(0)
            .step(duration: const Duration(milliseconds: 200))
            .scale(2)
            .step(
              duration: const Duration(milliseconds: 200),
              delay: const Duration(milliseconds: 100),
            )
            .scale(1)
            .timeline(controller: controller),
      ),
    );

void main() {
  testWidgets('seek renders the scrubbed position without animating',
      (tester) async {
    final controller = TimelineController();
    await tester.pumpWidget(host(controller));

    // 250ms of 500ms total = inside segment 2's delay: holds scale 2.
    controller.seek(0.5);
    await tester.pump();
    expect(compositeScaleOf(tester, key), closeTo(2, 1e-9));
    expect(controller.progress, 0.5);

    controller.seek(0);
    await tester.pump();
    expect(compositeScaleOf(tester, key), closeTo(0, 1e-9));
  });

  testWidgets('play, pause mid-flight, resume to completion', (tester) async {
    final controller = TimelineController();
    await tester.pumpWidget(host(controller));

    expect(controller.isAttached, isTrue);
    unawaited(controller.play());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    controller.pause();
    final held = controller.progress;
    expect(held, closeTo(0.2, 1e-6)); // 100ms of 500ms
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.progress, held, reason: 'paused timeline must hold');

    unawaited(controller.play());
    await tester.pumpAndSettle();
    expect(controller.progress, 1);
    expect(compositeScaleOf(tester, key), closeTo(1, 1e-9));

    unawaited(controller.reverse());
    await tester.pumpAndSettle();
    expect(controller.progress, 0);
  });

  testWidgets('notifies listeners as progress changes', (tester) async {
    final controller = TimelineController();
    await tester.pumpWidget(host(controller));

    var notifications = 0;
    controller.addListener(() => notifications++);
    unawaited(controller.play());
    await tester.pumpAndSettle();
    expect(notifications, greaterThan(5));
  });

  testWidgets('driving a detached controller throws loudly', (tester) async {
    final controller = TimelineController();
    await tester.pumpWidget(host(controller));
    expect(controller.isAttached, isTrue);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(controller.isAttached, isFalse);
    expect(() => controller.play(), throwsStateError);
    expect(() => controller.seek(0.5), throwsStateError);
  });
}
