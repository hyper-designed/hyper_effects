import 'package:flutter_test/flutter_test.dart';

import 'storyboard_harness.dart';

void main() {
  testWidgets('edge-case stories live in their own section, listed last',
      (tester) async {
    await pumpStoryboard(tester);

    // The showcase sections render first; the Edge Cases section starts
    // below the fold of the drawer list.
    expect(find.text('Animations'), findsOneWidget);
    expect(find.text('Edge Cases'), findsNothing,
        reason: 'low-priority edge cases must come after every showcase '
            'section, below the initial fold');

    await revealInDrawer(tester, 'Edge Cases');
    for (final story in [
      'Interrupted Delay Hold',
      'Queued Run Isolation',
      'Spring Lifecycle',
      'Layout Spring Safety',
    ]) {
      await revealInDrawer(tester, story);
    }
  });

  for (final (title, controls) in [
    (
      'Interrupted Delay Hold',
      ['Retrigger same target', 'Retarget opposite side', 'READY'],
    ),
    (
      'Queued Run Isolation',
      ['Quick · once', 'Bounce · reverse', 'Slow · repeat'],
    ),
    (
      'Spring Lifecycle',
      ['Play + reverse', 'Retarget now', 'Reset mid-reverse'],
    ),
    (
      'Layout Spring Safety',
      ['SIZE', 'PADDING', 'ALIGN FACTOR', 'Overshoot outward'],
    ),
  ]) {
    testWidgets('$title story is registered and interactive', (tester) async {
      await pumpStoryboard(tester);
      await openStory(tester, title);
      for (final control in controls) {
        expect(find.text(control), findsOneWidget);
      }
    });
  }
}
