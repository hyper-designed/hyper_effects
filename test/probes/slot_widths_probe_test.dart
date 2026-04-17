// Diagnostic probe: print per-slot cluster widths for length-mismatched
// transitions and compare them against the cluster widths from a plain
// `ShapedText.build(oldText)` paragraph.
//
// Hypothesis: at progress=0.0 the shaped roll renders "Marhaaba"
// instead of "Marhaba" — the per-slot first-frame cluster bounds for
// some position is reporting a width that includes a NEIGHBOUR cluster
// (probably caused by Skia's `getGlyphInfoAt` returning the *line*
// box of the cluster's run, not just the cluster, when the substituted
// paragraph has a ZWS/missing-cluster gap).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/effects/roll/shaped/shaped_rolling_text_controller.dart';
import 'package:hyper_effects/src/effects/roll/symbol_tape_strategy.dart';
import 'package:hyper_effects/src/effects/roll/tape_shaping_context.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  const style = TextStyle(fontFamily: 'TestLatin', fontSize: 48);

  test('Marhaba(7) → Hola(4): per-slot first-frame width vs reference',
      () {
    final c = ShapedRollingTextController(
      oldText: 'Marhaba',
      newText: 'Hola',
      tapeStrategy: const ConsistentSymbolTapeStrategy(0),
      style: style,
      tapeShapingContext: TapeShapingContext.endpointsCorrect,
    );

    // Reference: shape "Marhaba" once and pull each cluster's width.
    final ref = ShapedText.build(text: 'Marhaba', style: style);
    final refByLogical = {
      for (final cl in ref.clusters) cl.logicalIndex: cl,
    };

    // ignore: avoid_print
    print('positionCount=${c.positionCount}');
    double rolledTotal = 0;
    for (int p = 0; p < c.positionCount; p++) {
      final firstFrame = c.frameAt(position: p, step: 0);
      final tapeLen = c.tapeLength(position: p);
      final lastFrame = c.frameAt(position: p, step: tapeLen - 1);
      final refCluster = refByLogical[p];
      // ignore: avoid_print
      print('pos=$p '
          'firstW=${firstFrame.clusterBounds.width.toStringAsFixed(2)} '
          'firstL=${firstFrame.clusterBounds.left.toStringAsFixed(2)} '
          'firstR=${firstFrame.clusterBounds.right.toStringAsFixed(2)} '
          'lastW=${lastFrame.clusterBounds.width.toStringAsFixed(2)} '
          'lastL=${lastFrame.clusterBounds.left.toStringAsFixed(2)} '
          'lastR=${lastFrame.clusterBounds.right.toStringAsFixed(2)} '
          'refW=${refCluster?.bounds.width.toStringAsFixed(2)} '
          'refL=${refCluster?.bounds.left.toStringAsFixed(2)} '
          'firstSubstituted="${firstFrame.substitutedText.codeUnits}" '
          'lastSubstituted="${lastFrame.substitutedText.codeUnits}"');
      rolledTotal += firstFrame.clusterBounds.width;
    }
    final refTotal = ref.clusters
        .fold<double>(0.0, (a, cl) => a + cl.bounds.width);
    // ignore: avoid_print
    print('rolledFirstFrameTotal=${rolledTotal.toStringAsFixed(2)}');
    // ignore: avoid_print
    print('refTotal=${refTotal.toStringAsFixed(2)}');
    expect(
      rolledTotal,
      closeTo(refTotal, 0.5),
      reason: 'Sum of per-slot first-frame cluster widths must equal the '
          'sum of cluster widths from a plain ShapedText("Marhaba"). If '
          'they differ, slots are reserving space for content that '
          'isn\'t in oldText.',
    );

    // Per-slot equality: each slot\'s firstFrame.clusterBounds.width
    // must equal the matching cluster width from plain "Marhaba".
    for (int p = 0; p < c.positionCount; p++) {
      final firstFrame = c.frameAt(position: p, step: 0);
      final refCluster = refByLogical[p];
      expect(
        firstFrame.clusterBounds.width,
        closeTo(refCluster!.bounds.width, 0.5),
        reason: 'Slot $p first-frame cluster width '
            '(${firstFrame.clusterBounds.width}) must match the '
            'corresponding cluster in plain "Marhaba" '
            '(${refCluster.bounds.width}).',
      );
    }
  });

  test('Hola(4) → Marhaba(7): per-slot last-frame width vs reference',
      () {
    final c = ShapedRollingTextController(
      oldText: 'Hola',
      newText: 'Marhaba',
      tapeStrategy: const ConsistentSymbolTapeStrategy(0),
      style: style,
      tapeShapingContext: TapeShapingContext.endpointsCorrect,
    );
    final ref = ShapedText.build(text: 'Marhaba', style: style);
    final refByLogical = {
      for (final cl in ref.clusters) cl.logicalIndex: cl,
    };
    for (int p = 0; p < c.positionCount; p++) {
      final tapeLen = c.tapeLength(position: p);
      final lastFrame = c.frameAt(position: p, step: tapeLen - 1);
      final refCluster = refByLogical[p]!;
      // ignore: avoid_print
      print('pos=$p '
          'lastW=${lastFrame.clusterBounds.width.toStringAsFixed(2)} '
          'refW=${refCluster.bounds.width.toStringAsFixed(2)} '
          'substituted="${lastFrame.substitutedText.codeUnits}"');
      expect(
        lastFrame.clusterBounds.width,
        closeTo(refCluster.bounds.width, 0.5),
        reason: 'Slot $p last-frame cluster width '
            '(${lastFrame.clusterBounds.width}) must match cluster '
            'in plain "Marhaba" (${refCluster.bounds.width}). '
            'substituted=${lastFrame.substitutedText.codeUnits}',
      );
    }
  });
}
