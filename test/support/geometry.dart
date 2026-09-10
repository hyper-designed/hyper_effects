import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sums the x-translation of every [Transform] ancestor of [key] — the
/// composite translation the effect chain applies to that widget.
double translationXOf(WidgetTester tester, Key key) {
  final transforms = tester.widgetList<Transform>(
    find.ancestor(of: find.byKey(key), matching: find.byType(Transform)),
  );
  return transforms.fold<double>(
    0,
    (sum, transform) => sum + transform.transform.entry(0, 3),
  );
}
