import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects_demo/main.dart';

/// Mounts the storyboard at a fixed 1400x900 desktop viewport.
Future<void> pumpStoryboard(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MaterialApp(home: Storyboard()));
  await tester.pump();
}

/// The drawer's story list — the first scrollable in the storyboard row.
Finder drawerList() => find.byType(Scrollable).first;

/// Scrolls the drawer until [text] is fully visible and returns its finder.
Future<Finder> revealInDrawer(WidgetTester tester, String text) async {
  final finder = find.text(text);
  // scrollUntilVisible builds the lazy list far enough to attach the item;
  // ensureVisible then aligns it fully into the viewport so taps land.
  await tester.scrollUntilVisible(finder, 200, scrollable: drawerList());
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  return finder;
}

/// Opens the story titled [title], scrolling the drawer to it first.
Future<void> openStory(WidgetTester tester, String title) async {
  await tester.tap(await revealInDrawer(tester, title));
  await tester.pumpAndSettle();
}
