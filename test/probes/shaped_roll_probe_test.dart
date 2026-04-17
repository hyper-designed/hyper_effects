// Diagnostic probe for ShapedRollingText.
//
// Walks progress 0.00 → 0.30 in 0.01 steps, computes the same per-slot
// state the painter uses, and dumps a parseable text table to
// `/tmp/roll_probe.txt`. Replicates the math from `_Slot.build` and
// `_SlotPainter._paintFrame` in `shaped_rolling_text.dart`; the controller
// supplies cluster bounds.
//
// Run: flutter test test/probes/shaped_roll_probe_test.dart
// Output: /tmp/roll_probe.txt

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/effects/roll/shaped/shaped_rolling_text_controller.dart';
import 'package:hyper_effects/src/effects/roll/symbol_tape_strategy.dart';
import 'package:hyper_effects/src/effects/roll/tape_shaping_context.dart';

import '../helpers/test_font_loader.dart';

void main() {
  const oldText = 'Hola';
  const newText = 'Salaam';
  const style = TextStyle(
    fontFamily: 'TestLatin',
    fontSize: 48,
    color: Color(0xFFFFFFFF),
  );

  const Curve tapeCurve = Curves.easeInOutBack;
  const int staggerSoftness = 1;
  const bool staggerTapes = true;
  const bool reverseStaggerDirection = false;
  // slideDirection = up (default) → reversed = false.
  // topClipPadding = bottomClipPadding = 0 (no cursive padding in this probe).
  const double topPad = 0.0;
  const double botPad = 0.0;

  testWidgets('probe Hola -> Salaam, progress [0.00, 0.30] step 0.01',
      (tester) async {
    await loadTestFonts();

    final ctrl = ShapedRollingTextController(
      oldText: oldText,
      newText: newText,
      tapeStrategy: const ConsistentSymbolTapeStrategy(0),
      style: style,
      tapeShapingContext: TapeShapingContext.endpointsCorrect,
      textDirection: TextDirection.ltr,
    );

    final total = ctrl.positionCount; // max(oldLen, newLen)
    final out = StringBuffer();

    // Header.
    out.writeln('# shaped roll probe: "$oldText" -> "$newText"');
    out.writeln('# tapeCurve=Curves.easeInOutBack staggerTapes=$staggerTapes'
        ' staggerSoftness=$staggerSoftness positionCount=$total');
    out.writeln('# slideDirection=up (reversed=false)');
    out.writeln('# topClipPadding=$topPad bottomClipPadding=$botPad');
    out.writeln('# legend (per slot, per frame):');
    out.writeln(
        '#   cPct=charPercent scl=scaled cRaw=curvedRaw cur=curvedClamped');
    out.writeln(
        '#   stpA,stpB=tape steps t=fractional pntB=paintsStepB(bool)');
    out.writeln('#   slotW,slotH=lerped slot size paintH=slotH+pads');
    out.writeln('#   bnc=bounceOffset (outer Transform.translate on slot)');
    out.writeln('#   yA,yB=yFraction for A/B dA,dB=dy for A/B');
    out.writeln('#   rAt,rBt=clusterBounds.top for A/B (negative = glyph');
    out.writeln('#          extends above origin)');
    out.writeln('#   bLa,bLb=baselineY_local = topPad + (-rect.top) + dy');
    out.writeln('#   slotTopInRow=slot origin Y inside centered Row');
    out.writeln('');

    for (int i = 0; i <= 30; i++) {
      final double progress = (i * 0.01).clamp(0.0, 1.0);
      // First pass: compute slotH + paintH per slot so we can report
      // row-max paintH (Row height with CrossAxisAlignment.center puts
      // slots at (rowMaxH - slotPaintH) / 2 from the top).
      final slotStates = <_SlotState>[];
      for (int p = 0; p < total; p++) {
        slotStates.add(_compute(
          ctrl: ctrl,
          position: p,
          totalPositions: total,
          progress: progress,
          tapeCurve: tapeCurve,
          staggerTapes: staggerTapes,
          staggerSoftness: staggerSoftness,
          reverseStaggerDirection: reverseStaggerDirection,
          topPad: topPad,
          botPad: botPad,
        ));
      }
      double rowMaxPaintH = 0;
      for (final s in slotStates) {
        if (s.paintH > rowMaxPaintH) rowMaxPaintH = s.paintH;
      }

      out.writeln('== p=${progress.toStringAsFixed(2)}'
          ' rowMaxPaintH=${rowMaxPaintH.toStringAsFixed(2)} ==');
      for (final s in slotStates) {
        final slotTopInRow = (rowMaxPaintH - s.paintH) / 2.0;
        out.writeln(
          '  pos=${s.position}'
          ' cPct=${s.charPercent.toStringAsFixed(3)}'
          ' scl=${s.scaled.toStringAsFixed(3)}'
          ' cRaw=${s.curvedRaw.toStringAsFixed(3)}'
          ' cur=${s.curved.toStringAsFixed(3)}'
          ' stpA=${s.stepA} stpB=${s.stepB}'
          ' t=${s.t.toStringAsFixed(3)}'
          ' pntB=${s.paintsStepB ? "T" : "F"}'
          ' slotW=${s.slotW.toStringAsFixed(2)}'
          ' slotH=${s.slotH.toStringAsFixed(2)}'
          ' pH=${s.paintH.toStringAsFixed(2)}'
          ' bnc=${_signed(s.bounceOffset)}'
          ' yA=${s.yFractionA.toStringAsFixed(3)}'
          ' yB=${s.yFractionB.toStringAsFixed(3)}'
          ' dA=${s.dyA.toStringAsFixed(2)}'
          ' dB=${s.dyB.toStringAsFixed(2)}'
          ' rAt=${s.rectATop.toStringAsFixed(2)}'
          ' rBt=${s.rectBTop.toStringAsFixed(2)}'
          ' bLa=${s.baselineAlocal.toStringAsFixed(2)}'
          ' bLb=${s.baselineBlocal.toStringAsFixed(2)}'
          ' slotTop=${slotTopInRow.toStringAsFixed(2)}',
        );
      }
      out.writeln('');
    }

    final f = File('/tmp/roll_probe.txt');
    f.writeAsStringSync(out.toString());
    // Also confirm write via stdout so `flutter test` output has the path.
    // ignore: avoid_print
    print('roll probe written: ${f.path} (${f.lengthSync()} bytes)');
  });
}

class _SlotState {
  _SlotState({
    required this.position,
    required this.charPercent,
    required this.scaled,
    required this.curvedRaw,
    required this.curved,
    required this.slotW,
    required this.slotH,
    required this.paintH,
    required this.bounceOffset,
    required this.stepA,
    required this.stepB,
    required this.t,
    required this.paintsStepB,
    required this.yFractionA,
    required this.yFractionB,
    required this.dyA,
    required this.dyB,
    required this.rectATop,
    required this.rectBTop,
    required this.baselineAlocal,
    required this.baselineBlocal,
  });
  final int position;
  final double charPercent;
  final double scaled;
  final double curvedRaw;
  final double curved;
  final double slotW;
  final double slotH;
  final double paintH;
  final double bounceOffset;
  final int stepA;
  final int stepB;
  final double t;
  final bool paintsStepB;
  final double yFractionA;
  final double yFractionB;
  final double dyA;
  final double dyB;
  final double rectATop;
  final double rectBTop;
  final double baselineAlocal;
  final double baselineBlocal;
}

_SlotState _compute({
  required ShapedRollingTextController ctrl,
  required int position,
  required int totalPositions,
  required double progress,
  required Curve tapeCurve,
  required bool staggerTapes,
  required int staggerSoftness,
  required bool reverseStaggerDirection,
  required double topPad,
  required double botPad,
}) {
  double charPercent;
  if (!staggerTapes) {
    charPercent = 1.0;
  } else {
    charPercent = (position + staggerSoftness) /
        (totalPositions + staggerSoftness);
    if (reverseStaggerDirection) charPercent = 1 - charPercent;
  }

  final scaled = staggerTapes
      ? (progress / charPercent).clamp(0.0, 1.0).toDouble()
      : progress;
  final curvedRaw = tapeCurve.transform(scaled);
  final curved = curvedRaw.clamp(0.0, 1.0).toDouble();

  final length = ctrl.tapeLength(position: position);
  final firstFrame = ctrl.frameAt(position: position, step: 0);
  final lastFrame = ctrl.frameAt(position: position, step: length - 1);

  final slotW = firstFrame.clusterBounds.width * (1 - curved) +
      lastFrame.clusterBounds.width * curved;

  final firstH = firstFrame.clusterBounds.height;
  final lastH = lastFrame.clusterBounds.height;
  final slotH =
      curved <= 0 ? firstH : firstH * (1 - curved) + lastH * curved;

  final bounceOffset = (curvedRaw - curved) * slotH;

  final paintH = slotH + topPad + botPad;

  final stepFractional =
      length <= 1 ? 0.0 : curved * (length - 1);
  final stepA = stepFractional.floor();
  final stepB = min(stepA + 1, length - 1);
  final t = stepFractional - stepA;
  final paintsStepB = stepA != stepB && t > 0;

  // slideDirection = up → reversed = false.
  final yFractionA = -t;
  final yFractionB = 1 - t;

  // Painter: `dy = size.height * yFraction`; here size.height = paintH.
  final dyA = paintH * yFractionA;
  final dyB = paintH * yFractionB;

  final frameA = ctrl.frameAt(position: position, step: stepA);
  final frameB = ctrl.frameAt(position: position, step: stepB);
  final rectATop = frameA.clusterBounds.top;
  final rectBTop = frameB.clusterBounds.top;

  final baselineAlocal = topPad + (-rectATop) + dyA;
  final baselineBlocal = topPad + (-rectBTop) + dyB;

  return _SlotState(
    position: position,
    charPercent: charPercent,
    scaled: scaled,
    curvedRaw: curvedRaw,
    curved: curved,
    slotW: slotW,
    slotH: slotH,
    paintH: paintH,
    bounceOffset: bounceOffset,
    stepA: stepA,
    stepB: stepB,
    t: t,
    paintsStepB: paintsStepB,
    yFractionA: yFractionA,
    yFractionB: yFractionB,
    dyA: dyA,
    dyB: dyB,
    rectATop: rectATop,
    rectBTop: rectBTop,
    baselineAlocal: baselineAlocal,
    baselineBlocal: baselineBlocal,
  );
}

String _signed(double v) {
  if (v == 0) return '+0.00';
  return (v >= 0 ? '+' : '') + v.toStringAsFixed(2);
}
