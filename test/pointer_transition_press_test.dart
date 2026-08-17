import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

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

  testWidgets(
      'isPressed and isHovering combine down state with widget bounds',
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
}
