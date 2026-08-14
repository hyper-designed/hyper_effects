import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects_demo/stories/timeline_notification_bell.dart';
import 'package:hyper_effects_demo/stories/timeline_pulse_button.dart';
import 'package:hyper_effects_demo/stories/timeline_rocket_launch.dart';
import 'package:hyper_effects_demo/stories/timeline_toast.dart';

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

double compositeRotationOf(WidgetTester tester, Finder target) {
  final transforms = tester.widgetList<Transform>(
    find.ancestor(of: target, matching: find.byType(Transform)),
  );
  var rotation = 0.0;
  for (final t in transforms) {
    final m = t.transform;
    rotation += atan2(m.entry(1, 0), m.entry(0, 0));
  }
  return rotation;
}

double compositeOpacityOf(WidgetTester tester, Finder target) {
  final opacities = tester.widgetList<Opacity>(
    find.ancestor(of: target, matching: find.byType(Opacity)),
  );
  var opacity = 1.0;
  for (final o in opacities) {
    opacity *= o.opacity;
  }
  return opacity;
}

Widget host(Widget story) => MaterialApp(home: Scaffold(body: story));

void main() {
  testWidgets('pulse button dips below 1, overshoots, and rests at 1',
      (tester) async {
    await tester.pumpWidget(host(const TimelinePulseButton()));
    final button = find.byType(FilledButton);

    await tester.tap(button);
    await tester.pump();
    // Mid first segment: the dip toward 0.9 must be visible.
    await tester.pump(const Duration(milliseconds: 45));
    expect(compositeScaleOf(tester, button), lessThan(0.97));

    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, button), closeTo(1.0, 1e-6));

    // A second tap restarts and behaves the same.
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 45));
    expect(compositeScaleOf(tester, button), lessThan(0.97));
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, button), closeTo(1.0, 1e-6));
  });

  testWidgets('bell swings on notify and settles level', (tester) async {
    await tester.pumpWidget(host(const TimelineNotificationBell()));
    final bell = find.byIcon(Icons.notifications);

    expect(compositeRotationOf(tester, bell), closeTo(0, 1e-9));

    await tester.tap(find.text('Notify'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(compositeRotationOf(tester, bell).abs(), greaterThan(0.05),
        reason: 'the bell must visibly swing mid-flight');

    await tester.pumpAndSettle();
    expect(compositeRotationOf(tester, bell), closeTo(0, 1e-6),
        reason: 'the bell must settle level');
    expect(find.text('1'), findsOneWidget, reason: 'badge counts');
  });

  testWidgets('toast shows on play and dismisses in reverse', (tester) async {
    await tester.pumpWidget(host(const TimelineToast()));
    final toast = find.text('Changes saved');

    // Hidden at rest: the first keyframe declares opacity 0.
    expect(compositeOpacityOf(tester, toast), closeTo(0, 1e-9));

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(compositeOpacityOf(tester, toast), closeTo(1, 1e-6));

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(compositeOpacityOf(tester, toast), closeTo(0, 1e-6),
        reason: 'dismiss reverses the same timeline back to hidden');
  });

  testWidgets('rocket transport: play advances, pause holds, scrub seeks',
      (tester) async {
    await tester.pumpWidget(host(const TimelineRocketLaunch()));
    double sliderValue() => tester.widget<Slider>(find.byType(Slider)).value;

    expect(sliderValue(), 0);

    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final advanced = sliderValue();
    expect(advanced, greaterThan(0), reason: 'play must advance progress');

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    final held = sliderValue();
    await tester.pump(const Duration(milliseconds: 300));
    expect(sliderValue(), held, reason: 'pause must hold progress');

    // Scrub to the end: the rocket has burned out (faded away).
    final rocket = find.byIcon(Icons.rocket);
    await tester.drag(find.byType(Slider), const Offset(400, 0));
    await tester.pump();
    expect(sliderValue(), closeTo(1, 0.01));
    expect(compositeOpacityOf(tester, rocket), lessThan(0.05),
        reason: 'the end of the timeline is a burned-out rocket');

    // Restart rewinds and plays again from the beginning.
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(sliderValue(), lessThan(0.05));
    await tester.pumpAndSettle();
    expect(sliderValue(), closeTo(1, 1e-6));
  });
}
