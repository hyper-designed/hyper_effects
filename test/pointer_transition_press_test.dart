import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

double _scaleOf(WidgetTester tester, Key key) {
  final transforms = tester.widgetList<Transform>(
    find.ancestor(of: find.byKey(key), matching: find.byType(Transform)),
  );
  var scale = 1.0;
  for (final transform in transforms) {
    final matrix = transform.transform;
    scale *= Offset(matrix.entry(0, 0), matrix.entry(1, 0)).distance;
  }
  return scale;
}

void main() {
  testWidgets('isDown reflects pointer press and release in router mode',
      (tester) async {
    PointerTransitionEvent? lastEvent;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: const SizedBox(
            key: ValueKey('target'),
            width: 100,
            height: 100,
          ).pointerTransition(
            (context, child, event) {
              lastEvent = event;
              return child;
            },
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byKey(const ValueKey('target')));
    final gesture = await tester.startGesture(center);
    await tester.pump();
    expect(lastEvent!.isDown, isTrue);

    await gesture.up();
    await tester.pump();
    expect(lastEvent!.isDown, isFalse);
  });

  testWidgets('isPressed and isHovering combine down state with widget bounds',
      (tester) async {
    PointerTransitionEvent? lastEvent;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: const SizedBox(
            key: ValueKey('target'),
            width: 100,
            height: 100,
          ).pointerTransition(
            (context, child, event) {
              lastEvent = event;
              return child;
            },
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byKey(const ValueKey('target')));
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    await gesture.down(center);
    await tester.pump();
    expect(lastEvent!.isPressed, isTrue);
    expect(lastEvent!.isHovering, isFalse);

    // Drag off the widget while still holding down: no longer pressed,
    // but the pointer is still down.
    await gesture.moveTo(center + const Offset(200, 0));
    await tester.pump();
    expect(lastEvent!.isPressed, isFalse);
    expect(lastEvent!.isDown, isTrue);

    // Drag back inside and release: a mouse keeps hovering after release.
    await gesture.moveTo(center);
    await gesture.up();
    await tester.pump();
    expect(lastEvent!.isPressed, isFalse);
    expect(lastEvent!.isHovering, isTrue);
  });

  testWidgets('press and release are tracked in MouseRegion mode',
      (tester) async {
    PointerTransitionEvent? lastEvent;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: const SizedBox(
            key: ValueKey('target'),
            width: 100,
            height: 100,
          ).pointerTransition(
            (context, child, event) {
              lastEvent = event;
              return child;
            },
            usePointerRouter: false,
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byKey(const ValueKey('target')));
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(center);
    await tester.pump();
    expect(lastEvent!.isHovering, isTrue);
    expect(lastEvent!.isDown, isFalse);

    await gesture.down(center);
    await tester.pump();
    expect(lastEvent!.isPressed, isTrue);

    await gesture.up();
    await tester.pump();
    expect(lastEvent!.isDown, isFalse);
    expect(lastEvent!.isHovering, isTrue);
  });

  testWidgets('a cancelled touch is no longer down or hovering',
      (tester) async {
    PointerTransitionEvent? lastEvent;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: const SizedBox(
            key: ValueKey('target'),
            width: 100,
            height: 100,
          ).pointerTransition(
            (context, child, event) {
              lastEvent = event;
              return child;
            },
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byKey(const ValueKey('target')));
    final gesture = await tester.startGesture(center);
    await tester.pump();
    expect(lastEvent!.isPressed, isTrue);

    await gesture.cancel();
    await tester.pump();
    expect(lastEvent!.isDown, isFalse);
    // A cancelled touch contact no longer exists, so it cannot linger
    // inside the bounds of the widget the way a mouse cursor does.
    expect(lastEvent!.isHovering, isFalse);
  });

  testWidgets('a lifted touch is no longer hovering', (tester) async {
    PointerTransitionEvent? lastEvent;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: const SizedBox(
            key: ValueKey('target'),
            width: 100,
            height: 100,
          ).pointerTransition(
            (context, child, event) {
              lastEvent = event;
              return child;
            },
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byKey(const ValueKey('target')));
    final gesture = await tester.startGesture(center);
    await tester.pump();
    expect(lastEvent!.isPressed, isTrue);

    await gesture.up();
    await tester.pump();
    expect(lastEvent!.isDown, isFalse);
    // A lifted touch contact no longer exists; only hover-capable devices
    // like mice remain hovering after release.
    expect(lastEvent!.isHovering, isFalse);
  });

  testWidgets('a removed indirect mouse pointer is no longer hovering',
      (tester) async {
    const targetKey = ValueKey('indirect-pointer-target');
    PointerTransitionEvent? lastEvent;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: const SizedBox.square(
            key: targetKey,
            dimension: 100,
          ).pointerTransition((context, child, event) {
            lastEvent = event;
            final target = event.isPressed
                ? 0.9
                : event.isHovering
                    ? 1.1
                    : 1.0;
            return child
                .scale(target)
                .animate(trigger: target, curve: Curves.easeOutQuart);
          }),
        ),
      ),
    );

    final center = tester.getCenter(find.byKey(targetKey));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(center);
    await mouse.down(center);
    await tester.pumpAndSettle();
    expect(lastEvent!.isPressed, isTrue);
    expect(_scaleOf(tester, targetKey), closeTo(0.9, 1e-9));

    await mouse.up();
    await tester.pumpAndSettle();
    expect(lastEvent!.isHovering, isTrue);
    expect(_scaleOf(tester, targetKey), closeTo(1.1, 1e-9));

    // iOS sends PointerRemovedEvent immediately after PointerUpEvent for an
    // indirect pointer click, including clicks made in the Simulator.
    await mouse.removePointer();
    await tester.pumpAndSettle();
    expect(lastEvent!.isDown, isFalse);
    expect(lastEvent!.isHovering, isFalse);
    expect(_scaleOf(tester, targetKey), closeTo(1.0, 1e-9));
  });

  testWidgets('hover resets when the target moves away from a still mouse',
      (tester) async {
    const targetKey = ValueKey('moving-target');
    const transitionKey = ValueKey('moving-transition');
    PointerTransitionEvent? lastEvent;

    Widget host(Alignment alignment) => Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 200,
            child: Align(
              alignment: alignment,
              child: const SizedBox.square(
                key: targetKey,
                dimension: 100,
              ).pointerTransition(
                key: transitionKey,
                (context, child, event) {
                  lastEvent = event;
                  final target = event.isPressed
                      ? 0.9
                      : event.isHovering
                          ? 1.1
                          : 1.0;
                  return child
                      .scale(target)
                      .animate(trigger: target, curve: Curves.easeOutQuart);
                },
              ),
            ),
          ),
        );

    await tester.pumpWidget(host(Alignment.centerRight));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(targetKey)));
    await tester.pumpAndSettle();
    expect(lastEvent!.isHovering, isTrue);
    expect(_scaleOf(tester, targetKey), closeTo(1.1, 1e-9));

    await mouse.down(tester.getCenter(find.byKey(targetKey)));
    await tester.pumpAndSettle();
    expect(lastEvent!.isPressed, isTrue);
    expect(_scaleOf(tester, targetKey), closeTo(0.9, 1e-9));

    await mouse.up();
    await tester.pumpAndSettle();
    expect(lastEvent!.isHovering, isTrue);
    expect(_scaleOf(tester, targetKey), closeTo(1.1, 1e-9));

    await tester.pumpWidget(host(Alignment.centerLeft));
    await tester.pumpAndSettle();
    expect(lastEvent!.isHovering, isFalse);
    expect(_scaleOf(tester, targetKey), closeTo(1.0, 1e-9));

    await tester.pumpWidget(host(Alignment.centerRight));
    await tester.pumpAndSettle();
    expect(lastEvent!.isHovering, isTrue);
    expect(_scaleOf(tester, targetKey), closeTo(1.1, 1e-9));
  });

  testWidgets('global pointer bounds do not exit when the local target moves',
      (tester) async {
    tester.view.physicalSize = const Size(400, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const targetKey = ValueKey('global-target');
    const transitionKey = ValueKey('global-transition');
    PointerTransitionEvent? lastEvent;

    Widget host(Alignment alignment) => MediaQuery(
          data: const MediaQueryData(size: Size(400, 200)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 400,
              height: 200,
              child: Align(
                alignment: alignment,
                child: const SizedBox.square(
                  key: targetKey,
                  dimension: 100,
                ).pointerTransition(
                  key: transitionKey,
                  useGlobalPointer: true,
                  (context, child, event) {
                    lastEvent = event;
                    return child;
                  },
                ),
              ),
            ),
          ),
        );

    await tester.pumpWidget(host(Alignment.centerRight));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(targetKey)));
    await tester.pump();
    expect(lastEvent!.isInsideBounds, isTrue);

    await tester.pumpWidget(host(Alignment.centerLeft));
    await tester.pump();
    expect(lastEvent!.isInsideBounds, isTrue);
  });
}
