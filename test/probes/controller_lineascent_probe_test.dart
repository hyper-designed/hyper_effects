// Probe: directly run the controller for the rolled flow with
// GloriaHallelujah + strut.leading=1 and dump the actual TapeFrame
// metrics. Cross-check with my baseline_parity_probe to find the
// reality.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/effects/roll/shaped/shaped_rolling_text_controller.dart';
import 'package:hyper_effects/src/effects/roll/symbol_tape_strategy.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  test('controller frame metrics for GloriaHallelujah strut.leading=1',
      () async {
    final controller = ShapedRollingTextController(
      oldText: 'Hello',
      newText: 'Hello',
      tapeStrategy: const ConsistentSymbolTapeStrategy(0),
      style: const TextStyle(fontFamily: 'TestGloriaHallelujah', fontSize: 56),
      strutStyle: const StrutStyle(
        fontSize: 56,
        height: 1,
        forceStrutHeight: true,
        leading: 1,
      ),
    );
    for (int i = 0; i < controller.positionCount; i++) {
      final frame = controller.frameAt(position: i, step: 0);
      // ignore: avoid_print
      print('[$i] "${frame.substitutedText}" '
          'cluster=${frame.clusterBounds} '
          'asc=${frame.lineAscent} desc=${frame.lineDescent} '
          'slide=${frame.slideHeight}');
    }
  });
}
