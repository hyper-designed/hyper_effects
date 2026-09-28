import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({super.key});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return IconButton(
      tooltip: selected ? 'Remove favorite' : 'Add favorite',
      onPressed: () => setState(() => selected = !selected),
      icon: Icon(selected ? Icons.favorite : Icons.favorite_border)
          .scale(selected ? 1.2 : 1)
          .animate(
            trigger: selected,
            motion: const CupertinoMotion.snappy(),
            skipIf: () => reduceMotion,
          ),
    );
  }
}

Widget staticEffect(Widget child) => child.opacity(0.5).translateY(8);

Widget selectedItem(Widget child, bool selected) => child
    .scale(selected ? 1.08 : 1)
    .translateY(selected ? -4 : 0)
    .animate(trigger: selected, motion: const CupertinoMotion.snappy());

Widget curved(Widget child, Object trigger) =>
    child.opacity(1, from: 0).animate(
          trigger: trigger,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );

Widget entrance(Widget child, int index, bool reduceMotion) =>
    child.opacity(1, from: 0).translateY(0, from: 24).immediate(
          motion: const CupertinoMotion.smooth(),
          delay: Duration(milliseconds: 60 * index),
          skipIf: () => reduceMotion,
        );

Widget celebration(Object trigger) => const Icon(Icons.check, size: 64)
    .scale(0)
    .opacity(0)
    .step(duration: const Duration(milliseconds: 250), curve: Curves.easeOut)
    .scale(1.2)
    .opacity(1)
    .step(duration: const Duration(milliseconds: 180), curve: Curves.easeOut)
    .scale(1)
    .timeline(trigger: trigger);

Widget pulse(Widget child) => child
    .scale(1)
    .step(duration: const Duration(milliseconds: 300))
    .scale(1.1)
    .step(duration: const Duration(milliseconds: 300))
    .scale(1)
    .timeline(trigger: #immediate, repeat: -1);

Widget reveal(Widget child, TimelineController controller) => child
    .opacity(0)
    .translateY(24)
    .step(duration: const Duration(milliseconds: 250))
    .opacity(1)
    .translateY(0)
    .timeline(controller: controller);

Widget invalidInput(Widget child, int attempt) => child
    .shake()
    .animate(trigger: attempt, duration: const Duration(milliseconds: 350));

Widget pointerFeedback(Widget button) => button.pointerTransition(
      (context, child, event) {
        final target = event.isPressed ? 0.96 : (event.isHovering ? 1.03 : 1.0);
        return child.scale(target).animate(
              trigger: target,
              motion: const CupertinoMotion.interactive(),
            );
      },
    );

Widget expanding(Widget child, bool expanded) => child
    .widthTo(expanded ? 240 : 120)
    .animate(trigger: expanded, motion: const CupertinoMotion.bouncy());

Widget counter(int count) => Text('$count')
    .roll(widthCurve: Curves.easeOut)
    .animate(trigger: count, duration: const Duration(milliseconds: 250));

Widget status(bool done) => KeyedSubtree(
      key: ValueKey(done),
      child: Icon(done ? Icons.check : Icons.hourglass_empty),
    ).roll(slideInDirection: AxisDirection.up).animate(trigger: done);

Widget scrollItem(Widget child) => child.scrollTransition(
      (context, widget, event) => widget
          .opacity(event.phase == ScrollPhase.identity ? 1 : 0.3)
          .scale(event.phase == ScrollPhase.identity ? 1 : 0.9),
    );

void main() {
  testWidgets('README favorite responds to selection', (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: FavoriteButton())));
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    final transform = tester.widget<Transform>(find
        .descendant(
            of: find.byType(IconButton), matching: find.byType(Transform))
        .first);
    expect(transform.transform.storage[0], closeTo(1.2, 0.001));
  });
  testWidgets('README layout recipe changes actual width', (tester) async {
    Widget host(bool expanded) => MaterialApp(
        home: Center(child: expanding(const SizedBox(height: 40), expanded)));
    await tester.pumpWidget(host(false));
    await tester.pumpWidget(host(true));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(EffectWidget).first).width,
        closeTo(240, 0.01));
  });
  testWidgets('README timeline ends at absolute scale one', (tester) async {
    await tester.pumpWidget(MaterialApp(home: celebration(0)));
    await tester.pumpWidget(MaterialApp(home: celebration(1)));
    await tester.pumpAndSettle();
    expect(
        tester.widget<Transform>(find.byType(Transform)).transform.storage[0],
        closeTo(1, 0.001));
  });
  testWidgets('README rolling recipes survive content changes', (tester) async {
    Widget host(int count) => MaterialApp(
        home: Column(children: [counter(count), status(count > 0)]));
    await tester.pumpWidget(host(0));
    await tester.pumpWidget(host(1));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
