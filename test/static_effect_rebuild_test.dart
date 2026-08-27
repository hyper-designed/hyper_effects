import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:material_ui/material_ui.dart';

/// Static effects — an effect chain with NO `.animate()`, scroll transition,
/// or pointer transition above it — must track their widget configuration
/// across rebuilds. This is what makes hot reload of an effect parameter
/// (e.g. changing the angle of a bare `.rotate()`) take effect without a
/// hot restart.
///
/// The guard tests at the bottom pin the behaviors that must NOT change:
/// transition-driven and animation-driven [EffectWidget]s keep their
/// interrupted-animation continuation semantics. The TODO in
/// `effect_widget.dart` records that a previous fix for this bug broke
/// scroll transitions; those guards exist so this fix cannot repeat that.
const Key boxKey = Key('box');

const Widget box = SizedBox.square(dimension: 50, key: boxKey);

Widget host(Widget child) => MaterialApp(home: Center(child: child));

/// The nearest [Transform] ancestor of the keyed box.
Transform nearestTransform(WidgetTester tester) => tester.widget<Transform>(
      find
          .ancestor(of: find.byKey(boxKey), matching: find.byType(Transform))
          .first,
    );

double rotationAngle(WidgetTester tester) {
  final m = nearestTransform(tester).transform;
  return atan2(m.entry(1, 0), m.entry(0, 0));
}

double scaleFactor(WidgetTester tester) {
  final m = nearestTransform(tester).transform;
  return Offset(m.entry(0, 0), m.entry(1, 0)).distance;
}

Offset translationOffset(WidgetTester tester) {
  final m = nearestTransform(tester).transform;
  return Offset(m.entry(0, 3), m.entry(1, 3));
}

double opacityValue(WidgetTester tester) => tester
    .widget<Opacity>(
      find
          .ancestor(of: find.byKey(boxKey), matching: find.byType(Opacity))
          .first,
    )
    .opacity;

void main() {
  group('static effects track widget configuration across rebuilds', () {
    testWidgets('rotate picks up a new angle', (tester) async {
      await tester.pumpWidget(host(box.rotate(0.5)));
      expect(rotationAngle(tester), closeTo(0.5, 1e-9));

      await tester.pumpWidget(host(box.rotate(1.2)));
      expect(rotationAngle(tester), closeTo(1.2, 1e-9),
          reason: 'a rebuilt static rotate must render the new angle');
    });

    testWidgets('scale picks up a new scale', (tester) async {
      await tester.pumpWidget(host(box.scale(2)));
      expect(scaleFactor(tester), closeTo(2, 1e-9));

      await tester.pumpWidget(host(box.scale(3)));
      expect(scaleFactor(tester), closeTo(3, 1e-9),
          reason: 'a rebuilt static scale must render the new scale');
    });

    testWidgets('opacity picks up a new opacity', (tester) async {
      await tester.pumpWidget(host(box.opacity(0.5)));
      expect(opacityValue(tester), closeTo(0.5, 1e-9));

      await tester.pumpWidget(host(box.opacity(0.25)));
      expect(opacityValue(tester), closeTo(0.25, 1e-9),
          reason: 'a rebuilt static opacity must render the new opacity');
    });

    testWidgets('translate picks up a new offset', (tester) async {
      await tester.pumpWidget(host(box.translate(const Offset(10, 20))));
      expect(translationOffset(tester), const Offset(10, 20));

      await tester.pumpWidget(host(box.translate(const Offset(-4, 8))));
      expect(translationOffset(tester), const Offset(-4, 8),
          reason: 'a rebuilt static translate must render the new offset');
    });

    testWidgets('rotate with from: picks up a new from value', (tester) async {
      // A static effect with an explicit start renders that start value.
      await tester.pumpWidget(host(box.rotate(2, from: 1)));
      expect(rotationAngle(tester), closeTo(1, 1e-9));

      await tester.pumpWidget(host(box.rotate(2, from: 0.4)));
      expect(rotationAngle(tester), closeTo(0.4, 1e-9),
          reason: 'a rebuilt static rotate must render the new from value');
    });

    testWidgets('swapping the effect type applies the new effect',
        (tester) async {
      await tester.pumpWidget(host(box.rotate(1)));
      expect(rotationAngle(tester), closeTo(1, 1e-9));

      // Same element slot, different Effect type — the hot reload case of
      // replacing `.rotate(...)` with `.scale(...)` in source.
      await tester.pumpWidget(host(box.scale(3)));
      expect(scaleFactor(tester), closeTo(3, 1e-9),
          reason: 'a rebuilt static effect of a new type must render it');
      expect(rotationAngle(tester), closeTo(0, 1e-9),
          reason: 'the old rotation must be gone after the type swap');
    });
  });

  group('guards: driven effects keep their existing semantics', () {
    testWidgets(
        'transition query: rebuilding with a new end must NOT reset start',
        (tester) async {
      // Pins the scroll/pointer transition contract that the reverted fix
      // (see TODO in effect_widget.dart didUpdateWidget) broke: under a
      // transition, `start` stays where initState put it while `end`
      // follows the widget.
      Widget transitionHost(double endAngle) => host(
            EffectQuery(
              linearValue: 0.5,
              curvedValue: 0.5,
              isTransition: true,
              child: EffectWidget(
                end: RotationEffect(angle: endAngle),
                child: box,
              ),
            ),
          );

      await tester.pumpWidget(transitionHost(1));
      // start == end == 1, lerped at 0.5 -> 1.
      expect(rotationAngle(tester), closeTo(1, 1e-9));

      await tester.pumpWidget(transitionHost(2));
      // start must remain 1 (from initState); end follows to 2.
      // lerp(1, 2, 0.5) -> 1.5. If start were reset to the new widget
      // values, this would render 2.
      expect(rotationAngle(tester), closeTo(1.5, 1e-9),
          reason: 'transitions lerp from the original start, never reset');
    });

    testWidgets('lerpValues: false query renders end directly and follows it',
        (tester) async {
      // Pins the pointer transition contract (isTransition + lerpValues
      // false): the end effect is applied as-is and rebuilds update it.
      Widget pointerHost(double endAngle) => host(
            EffectQuery(
              linearValue: 0.3,
              curvedValue: 0.3,
              isTransition: true,
              lerpValues: false,
              child: EffectWidget(
                end: RotationEffect(angle: endAngle),
                child: box,
              ),
            ),
          );

      await tester.pumpWidget(pointerHost(1));
      expect(rotationAngle(tester), closeTo(1, 1e-9));

      await tester.pumpWidget(pointerHost(2));
      expect(rotationAngle(tester), closeTo(2, 1e-9));
    });

    testWidgets(
        'animation query: rebuilding with a new end continues from the '
        'in-flight value', (tester) async {
      // Pins the interrupted-animation continuation: under a non-transition
      // query mid-animation, a new end re-bases start onto the currently
      // rendered value.
      Widget animationHost(double endAngle) => host(
            EffectQuery(
              linearValue: 0.5,
              curvedValue: 0.5,
              isTransition: false,
              child: EffectWidget(
                start: const RotationEffect(angle: 0),
                end: RotationEffect(angle: endAngle),
                child: box,
              ),
            ),
          );

      await tester.pumpWidget(animationHost(2));
      // lerp(0, 2, 0.5) -> 1.
      expect(rotationAngle(tester), closeTo(1, 1e-9));

      await tester.pumpWidget(animationHost(4));
      // start re-based to the in-flight value 1; lerp(1, 4, 0.5) -> 2.5.
      expect(rotationAngle(tester), closeTo(2.5, 1e-9),
          reason: 'retargeting continues from the in-flight value');
    });
  });
}
