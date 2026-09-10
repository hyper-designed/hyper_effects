import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

import 'support/geometry.dart';

const _boxKey = Key('box');

void main() {
  testWidgets('queued handoff paints the new run from its explicit start',
      (tester) async {
    var trigger = 0;

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.square(dimension: 20, key: _boxKey)
              .translateX(320, from: 0)
              .animate(
                trigger: trigger,
                duration: const Duration(milliseconds: 450),
                curve: Curves.linear,
                interruptable: false,
              ),
        );

    await tester.pumpWidget(host());

    trigger = 1;
    await tester.pumpWidget(host());
    // Build a frame late in run 1 so its rendered value is close to the end.
    await tester.pump(const Duration(milliseconds: 400));
    expect(translationXOf(tester, _boxKey), closeTo(320 * 400 / 450, 1));

    // Queue run 2 while run 1 is mid-flight.
    trigger = 2;
    await tester.pumpWidget(host());

    // This frame lands past run 1's completion: the completed run's final
    // value never builds, run 2 starts within the same frame's microtasks.
    // Run 1 COMPLETED — it was not interrupted — so run 2 must repaint from
    // its explicit `from: 0`, not from run 1's last-built frame.
    await tester.pump(const Duration(milliseconds: 100));
    expect(translationXOf(tester, _boxKey), closeTo(0, 1),
        reason: 'a queued run follows a COMPLETED run; it must start '
            'painting at its explicit start');

    // And it must traverse the full distance.
    await tester.pump(const Duration(milliseconds: 225));
    expect(translationXOf(tester, _boxKey), closeTo(320 * 225 / 450, 1),
        reason: 'the queued run must animate across its full range');

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 1));
    expect(translationXOf(tester, _boxKey), closeTo(320, 1e-6));
  });

  testWidgets('a run from rest reseeds its explicit start after an interrupt',
      (tester) async {
    var trigger = 0;

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.square(dimension: 20, key: _boxKey)
              .translateX(320, from: 0)
              .animate(
                trigger: trigger,
                duration: const Duration(milliseconds: 450),
                curve: Curves.linear,
              ),
        );

    await tester.pumpWidget(host());

    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 200));

    // A zero-delay same-target retrigger is a REPLAY: deterministic under
    // spam. Only a DELAYED retrigger holds the interrupted position
    // (spec regression 8).
    trigger = 2;
    await tester.pumpWidget(host());
    await tester.pump();
    expect(translationXOf(tester, _boxKey), closeTo(0, 1),
        reason: 'a zero-delay retrigger replays from its explicit start');

    // Let the interrupting run finish completely.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 1));
    expect(translationXOf(tester, _boxKey), closeTo(320, 1e-6));

    // A fresh run from REST also repaints from the author's explicit start.
    trigger = 3;
    await tester.pumpWidget(host());
    await tester.pump();
    expect(translationXOf(tester, _boxKey), closeTo(0, 1),
        reason: 'a fresh run from rest must reseed its explicit start');

    await tester.pump(const Duration(milliseconds: 225));
    expect(translationXOf(tester, _boxKey), closeTo(320 * 225 / 450, 1),
        reason: 'the fresh run must traverse its full range');
  });

  testWidgets(
      'zero-delay same-target retriggers replay an implicit-start effect '
      'from its pair start', (tester) async {
    var trigger = 0;
    var end = 0.0;

    // No `from:` — the pair start is captured when the end retargets, and
    // it must SURVIVE same-target retriggers: it is the only record of
    // where this pair began.
    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.square(dimension: 20, key: _boxKey)
              .translateX(end)
              .animate(
                trigger: trigger,
                duration: const Duration(milliseconds: 450),
                curve: Curves.linear,
              ),
        );

    await tester.pumpWidget(host());

    end = 320;
    trigger = 1;
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 200));
    expect(translationXOf(tester, _boxKey), closeTo(320 * 200 / 450, 1));

    // Mid-flight same-target retrigger: replay from the pair start (0).
    trigger = 2;
    await tester.pumpWidget(host());
    await tester.pump();
    expect(translationXOf(tester, _boxKey), closeTo(0, 1),
        reason: 'the retrigger must replay from the pair start, not '
            'continue-and-corrupt it');

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 1));
    expect(translationXOf(tester, _boxKey), closeTo(320, 1e-6));

    // From rest, the pair start must still be intact: replay covers the
    // full range instead of hovering at a folded leftover.
    trigger = 3;
    await tester.pumpWidget(host());
    await tester.pump();
    expect(translationXOf(tester, _boxKey), closeTo(0, 1),
        reason: 'the pair start must survive spam; an implicit-start '
            'effect has no explicit from to recover with');

    await tester.pump(const Duration(milliseconds: 225));
    expect(translationXOf(tester, _boxKey), closeTo(320 * 225 / 450, 1));
  });
}
