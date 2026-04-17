// Diagnostic probe: pump "Ni Hao → Namaste" at progress=0.0 using
// the same Sacramento-styled config as the storyboard, then walk
// directly into the controller to dump every slot's frame data
// (substituted text, cluster bounds, edge flags) so we can see
// exactly what's being fed into the painter.

import 'dart:io';

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

  testWidgets('Dump slot/frame data: Ni Hao → Namaste with Sacramento',
      (tester) async {
    final controller = ShapedRollingTextController(
      oldText: 'Ni Hao',
      newText: 'Namaste',
      tapeStrategy: const ConsistentSymbolTapeStrategy(0),
      style: const TextStyle(
        fontFamily: 'TestSacramento',
        fontWeight: FontWeight.bold,
        fontSize: 56,
        color: Colors.white,
      ),
      tapeShapingContext: TapeShapingContext.endpointsCorrect,
      textDirection: TextDirection.ltr,
      strutStyle: const StrutStyle(
        fontSize: 56,
        height: 1,
        forceStrutHeight: true,
        leading: 1,
      ),
    );

    final out = StringBuffer();
    out.writeln('# Ni Hao(${'Ni Hao'.characters.length}) → '
        'Namaste(${'Namaste'.characters.length})');
    out.writeln('positionCount = ${controller.positionCount}');
    out.writeln('---');

    for (int p = 0; p < controller.positionCount; p++) {
      final tapeLen = controller.tapeLength(position: p);
      out.writeln('position $p: tapeLength=$tapeLen');
      for (int s = 0; s < tapeLen; s++) {
        final f = controller.frameAt(position: p, step: s);
        out.writeln('  step $s: '
            'sub=${_describe(f.substitutedText)} '
            'bounds=${f.clusterBounds} '
            'ascent=${f.lineAscent.toStringAsFixed(2)} '
            'descent=${f.lineDescent.toStringAsFixed(2)} '
            'leftEdge=${f.clusterIsParagraphLeftEdge} '
            'rightEdge=${f.clusterIsParagraphRightEdge}');
      }
    }

    File('/tmp/probe_dash_diag_nihao_namaste.txt')
        .writeAsStringSync(out.toString());

    // Print to stdout too so we see it during test runs.
    // ignore: avoid_print
    print(out.toString());
  });
}

String _describe(String s) {
  // Show codeunits so any sneaky ZWS / control chars in the
  // substituted text are visible.
  return '${s.codeUnits} ($s)';
}
