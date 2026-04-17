// Probe: instantiate the rolled widget INSIDE a MaterialApp so its
// .roll() extension merges DefaultTextStyle. Then read the
// underlying RenderShapedRolledRow's slot/frame data to see what
// actual lineAscent / cluster.bounds.top get used at paint time.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/effects/roll/shaped/shaped_rolling_text.dart'
    show RenderShapedRolledRow;
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  testWidgets('rolled widget inside Material — print render state',
      (tester) async {
    final rolledKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: KeyedSubtree(
              key: rolledKey,
              child: const Text(
                'Learn',
                style: TextStyle(
                  fontFamily: 'TestGloriaHallelujah',
                  fontSize: 56,
                ),
              ).roll(symbolDistanceMultiplier: 2),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rb = rolledKey.currentContext!.findRenderObject() as RenderBox;
    // ignore: avoid_print
    print('rolled box: size=${rb.size}  '
        'dryBaseline=${rb.getDryBaseline(rb.constraints, TextBaseline.alphabetic)}');

    // Walk down to find the RenderShapedRolledRow.
    final stack = <RenderObject>[];
    void visit(RenderObject node) {
      stack.add(node);
      if (node is RenderShapedRolledRow) return;
      node.visitChildren(visit);
    }
    visit(rb);
    final rsr = stack.firstWhere(
      (r) => r is RenderShapedRolledRow,
      orElse: () => rb,
    );
    if (rsr is RenderShapedRolledRow) {
      // ignore: avoid_print
      print('RenderShapedRolledRow found: size=${rsr.size}');
    }
  });
}
