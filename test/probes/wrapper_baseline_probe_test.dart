// Probe: read getDistanceToActualBaseline from the OUTER wrapper
// chain (ShaderMask × 2 + .animate()) vs the bare rolled widget.
// If the wrapper drops the baseline on the floor,
// `Row(crossAxisAlignment: baseline)` falls back to the box-bottom
// (because Row uses computeDistanceToActualBaseline = null →
// "place against the bottom of the box").

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  testWidgets('baseline forwarding through wrapper chain', (tester) async {
    final bareKey = GlobalKey();
    final shaderMaskKey = GlobalKey();
    final doubleMaskKey = GlobalKey();
    final fullChainKey = GlobalKey();

    Widget makeText() => const Text(
          'Develop',
          style: TextStyle(
            fontFamily: 'TestSacramento',
            fontSize: 56,
            color: Colors.white,
          ),
        ).roll(symbolDistanceMultiplier: 2);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.noScaling),
            child: Scaffold(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KeyedSubtree(key: bareKey, child: makeText()),
                  KeyedSubtree(
                    key: shaderMaskKey,
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        colors: [Colors.red, Colors.blue],
                      ).createShader(rect),
                      child: makeText(),
                    ),
                  ),
                  KeyedSubtree(
                    key: doubleMaskKey,
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        colors: [Colors.red, Colors.blue],
                      ).createShader(rect),
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [Colors.green, Colors.yellow],
                        ).createShader(rect),
                        child: makeText(),
                      ),
                    ),
                  ),
                  KeyedSubtree(
                    key: fullChainKey,
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        colors: [Colors.red, Colors.blue],
                      ).createShader(rect),
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [Colors.green, Colors.yellow],
                        ).createShader(rect),
                        child: makeText().animate(
                          trigger: 0,
                          duration: const Duration(milliseconds: 1000),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final entry in [
      ('bare', bareKey),
      ('ShaderMask', shaderMaskKey),
      ('ShaderMask×2', doubleMaskKey),
      ('full chain (×2 + animate)', fullChainKey),
    ]) {
      final rb = entry.$2.currentContext!.findRenderObject() as RenderBox;
      // ignore: avoid_print
      print('${entry.$1}: size=${rb.size}  '
          'baseline=${rb.getDryBaseline(rb.constraints, TextBaseline.alphabetic)}');
    }
  });
}
