import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'storyboard_harness.dart';

void main() {
  // Note: a 0ms gap (two taps in one frame) is deliberately absent — two
  // setStates in the same frame coalesce into a single rebuild and therefore
  // a single trigger change; only the last-pressed run exists. That is
  // correct Flutter semantics, not a queueing bug.
  for (final gapMs in [30, 120, 350, 600, 1000]) {
    testWidgets('queued runs pressed ${gapMs}ms apart all complete',
        (tester) async {
      await pumpStoryboard(tester);
      await openStory(tester, 'Queued Run Isolation');

      await tester.tap(find.text('Quick · once'));
      await tester.pump(Duration(milliseconds: gapMs));
      await tester.tap(find.text('Bounce · reverse'));

      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.pump();

      expect(find.text('1 · Quick'), findsOneWidget,
          reason: 'gap=$gapMs: Quick must complete');
      expect(find.text('2 · Bounce'), findsOneWidget,
          reason: 'gap=$gapMs: Bounce must complete after Quick');

      await tester.tap(find.text('Quick · once'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.pump();
      expect(find.text('3 · Quick'), findsOneWidget,
          reason: 'gap=$gapMs: the queue must not deadlock');
    });
  }

  testWidgets('queued handoff repaints from its explicit start',
      (tester) async {
    // Real frames practically never land on a run's exact final value: the
    // simulation completes between frames and the next queued run begins in
    // the same frame's microtasks. Misaligned pump steps reproduce that.
    await pumpStoryboard(tester);
    await openStory(tester, 'Queued Run Isolation');

    final marker = find.byKey(const Key('queue-marker'));
    final restingX = tester.getCenter(marker).dx;
    double x() => tester.getCenter(marker).dx;

    await tester.tap(find.text('Quick · once'));
    await tester.pump(const Duration(milliseconds: 400)); // late in Quick
    await tester.tap(find.text('Bounce · reverse'));

    // Sample through Bounce (starts ~450ms, fwd 700ms, rev 700ms) on steps
    // that never align with a leg boundary.
    var minX = double.infinity;
    var maxX = -double.infinity;
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 97));
      final v = x();
      if (v < minX) minX = v;
      if (v > maxX) maxX = v;
    }

    expect(minX, lessThan(restingX + 60),
        reason: 'Bounce restarts from its explicit `from: 0`, so the marker '
            'must return near the left edge (resting=$restingX min=$minX)');
    expect(maxX - minX, greaterThan(200),
        reason: 'Bounce must visibly traverse the lane, not hover near the '
            'end (range=${maxX - minX})');

    // The next press must also repaint from the start.
    await tester.tap(find.text('Quick · once'));
    await tester.pump(const Duration(milliseconds: 30));
    var min2 = double.infinity;
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 61));
      if (x() < min2) min2 = x();
    }
    expect(min2, lessThan(restingX + 60),
        reason: 'later queued runs must keep repainting from the start');
  });

  testWidgets('queued runs pressed during each Bounce leg all complete',
      (tester) async {
    await pumpStoryboard(tester);
    await openStory(tester, 'Queued Run Isolation');

    await tester.tap(find.text('Bounce · reverse'));
    await tester.pump(const Duration(milliseconds: 300)); // mid forward leg
    await tester.tap(find.text('Quick · once'));
    await tester.pump(const Duration(milliseconds: 500)); // mid reverse leg
    await tester.tap(find.text('Slow · repeat'));

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump();

    expect(find.text('1 · Bounce'), findsOneWidget);
    expect(find.text('2 · Quick'), findsOneWidget);
    expect(find.text('3 · Slow'), findsOneWidget);
  });

  testWidgets('spring lifecycle play+reverse rests at start', (tester) async {
    await pumpStoryboard(tester);
    await openStory(tester, 'Spring Lifecycle');

    final marker = find.byKey(const Key('spring-lifecycle-marker'));
    final restingX = tester.getCenter(marker).dx;

    await tester.tap(find.text('Play + reverse'));
    await tester.pump();

    double x() => tester.getCenter(marker).dx;

    var maxX = restingX;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (x() > maxX) maxX = x();
    }
    expect(maxX, greaterThan(restingX + 200),
        reason: 'forward leg must travel toward the right');

    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();

    expect((x() - restingX).abs(), lessThan(1),
        reason: 'after play+reverse the marker must rest at the start, '
            'not jump to the end. resting=$restingX final=${x()}');
  });

  testWidgets('layout safety lanes are VISIBLY animated and survive re-presses',
      (tester) async {
    await pumpStoryboard(tester);
    await openStory(tester, 'Layout Spring Safety');

    final sizeBox = find.byKey(const Key('safety-size-box'));
    // The lanes must paint their changing geometry: transparent padding
    // around a centered box and a bare Align factor are invisible. Each
    // lane exposes a keyed, decorated frame whose size IS the animated
    // geometry.
    final padFrame = find.byKey(const Key('safety-padding-frame'));
    final alignFrame = find.byKey(const Key('safety-align-frame'));

    expect(padFrame, findsOneWidget,
        reason: 'the padding lane needs a visible frame painting the insets');
    expect(alignFrame, findsOneWidget,
        reason: 'the align lane needs a visible frame painting the factor');

    double sizeW() => tester.getSize(sizeBox).width;
    double padW() => tester.getSize(padFrame).width;
    double alignW() => tester.getSize(alignFrame).width;

    final padW0 = padW();
    final alignW0 = alignW();

    await tester.tap(find.text('Overshoot outward'));
    await tester.pump();

    var sizeMoved = false;
    var padMoved = false;
    var alignMoved = false;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final w = sizeW();
      if (w > 5 && w < 149) sizeMoved = true;
      if ((padW() - padW0).abs() > 2) padMoved = true;
      if ((alignW() - alignW0).abs() > 2) alignMoved = true;
    }

    expect(sizeMoved, isTrue, reason: 'SIZE lane must animate visibly');
    expect(padMoved, isTrue, reason: 'PADDING lane must animate visibly');
    expect(alignMoved, isTrue, reason: 'ALIGN lane must animate visibly');
    expect(padW(), moreOrLessEquals(42 + 48, epsilon: 1),
        reason: 'padding must settle at 24 per side around the 42px box');

    // Alternating and repeated presses must keep animating (no deadlock).
    await tester.tap(find.text('Shrink through floor'));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.text('Overshoot outward'));
    await tester.pump();
    var movedAgain = false;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final w = sizeW();
      if (w > 5 && w < 149) movedAgain = true;
    }
    expect(movedAgain, isTrue,
        reason: 'SIZE lane must animate on the third press');
    expect(sizeW(), moreOrLessEquals(150, epsilon: 1));

    // Double-press the same button, then alternate again.
    await tester.tap(find.text('Overshoot outward'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Overshoot outward'));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.text('Shrink through floor'));
    await tester.pump();
    var shrinkMoved = false;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final w = sizeW();
      if (w > 5 && w < 149) shrinkMoved = true;
    }
    expect(shrinkMoved, isTrue,
        reason: 'SIZE lane must animate after double-press of same button');
    expect(sizeW(), lessThan(5),
        reason: 'SIZE lane must settle at 0 after shrink');
  });

  testWidgets('layout safety survives Overshoot spam on misaligned frames',
      (tester) async {
    await pumpStoryboard(tester);
    await openStory(tester, 'Layout Spring Safety');

    final sizeBox = find.byKey(const Key('safety-size-box'));
    final padFrame = find.byKey(const Key('safety-padding-frame'));
    double sizeW() => tester.getSize(sizeBox).width;
    double padW() => tester.getSize(padFrame).width;

    // Spam the same button with presses landing mid-flight, on pump steps
    // that never align with the spring's settling boundary. A zero-delay
    // same-target retrigger REPLAYS from its pair start, so every press
    // must deterministically restart the lanes — never silently hold.
    for (var press = 0; press < 5; press++) {
      await tester.tap(find.text('Overshoot outward'));
      await tester.pump(const Duration(milliseconds: 16));
      expect(sizeW(), lessThan(40),
          reason: 'press ${press + 1} mid-spam must restart the SIZE lane '
              'from its explicit from: 0 (got ${sizeW()})');
      expect(padW(), lessThan(55),
          reason: 'press ${press + 1} mid-spam must restart the PADDING '
              'lane from its pair start (got ${padW()})');
      await tester.pump(const Duration(milliseconds: 137));
    }
    // Settle fully.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 97));
    }
    expect(sizeW(), moreOrLessEquals(150, epsilon: 1));
    expect(padW(), moreOrLessEquals(42 + 48, epsilon: 1));

    // The implicit-from PADDING lane must also still replay from rest —
    // it has no explicit `from` to reseed, so its pair start must survive
    // the spam untouched.
    await tester.tap(find.text('Overshoot outward'));
    var minPadW = double.infinity;
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (padW() < minPadW) minPadW = padW();
    }
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 97));
      if (padW() < minPadW) minPadW = padW();
    }
    expect(minPadW, lessThan(55),
        reason: 'PADDING must replay from its pair start after spam, not '
            'stay stuck at the folded end (min=$minPadW)');
    expect(padW(), moreOrLessEquals(42 + 48, epsilon: 1));

    // A press from rest must still visibly replay across its full range.
    // Sample the first frames tightly: a fast spring leaves the origin
    // quickly, and a stale folded start would never get near it at all.
    await tester.tap(find.text('Overshoot outward'));
    var minW = double.infinity;
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (sizeW() < minW) minW = sizeW();
    }
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 97));
      if (sizeW() < minW) minW = sizeW();
    }
    expect(minW, lessThan(30),
        reason: 'after spam, a fresh press must replay from its explicit '
            'from: 0, not hover at the folded end (min=$minW)');
    expect(sizeW(), moreOrLessEquals(150, epsilon: 1));
  });

  testWidgets('spring lifecycle survives Play+reverse spam', (tester) async {
    await pumpStoryboard(tester);
    await openStory(tester, 'Spring Lifecycle');

    final marker = find.byKey(const Key('spring-lifecycle-marker'));
    final restingX = tester.getCenter(marker).dx;
    double x() => tester.getCenter(marker).dx;

    for (var press = 0; press < 4; press++) {
      await tester.tap(find.text('Play + reverse'));
      await tester.pump(const Duration(milliseconds: 173));
    }
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 97));
    }

    // A fresh press from rest must still traverse the lane and rest at start.
    await tester.tap(find.text('Play + reverse'));
    await tester.pump(const Duration(milliseconds: 30));
    var maxX = -double.infinity;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 97));
      if (x() > maxX) maxX = x();
    }
    expect(maxX, greaterThan(restingX + 200),
        reason: 'after spam, Play + reverse must still travel right '
            '(resting=$restingX max=$maxX)');
    expect((x() - restingX).abs(), lessThan(1),
        reason: 'and rest back at the start (final=${x()})');
  });
}
