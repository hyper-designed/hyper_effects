// Probe: print the RUNTIME positions of plain Text and rolled
// widget after Row layout to find where they actually sit. Also
// captures the visual to compare with the numeric data.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  testWidgets('actual positions of plain vs rolled in baseline Row',
      (tester) async {
    final plainKey = GlobalKey();
    final rolledKey = GlobalKey();
    final siblingKey = GlobalKey();
    final rowKey = GlobalKey();
    final captureKey = GlobalKey();

    final row = Row(
      key: rowKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        KeyedSubtree(
          key: siblingKey,
          child: const Text(
            'We help you',
            style: TextStyle(
              fontFamily: 'TestRobotoMono',
              color: Colors.white,
              fontSize: 48,
            ),
          ),
        ),
        KeyedSubtree(
          key: plainKey,
          child: const Text(
            'Plain',
            style: TextStyle(
              fontFamily: 'TestGloriaHallelujah',
              color: Color(0xFF6FD6FF),
              fontSize: 56,
            ),
          ),
        ),
        KeyedSubtree(
          key: rolledKey,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(colors: [
              Color(0xFFBFF098),
              Color(0xFF6FD6FF),
            ]).createShader(rect),
            child: const Text(
              'Rolled',
              style: TextStyle(
                fontFamily: 'TestGloriaHallelujah',
                color: Colors.white,
                fontSize: 56,
              ),
            )
                .roll(
                  symbolDistanceMultiplier: 2,
                  padding: const EdgeInsets.only(left: 16),
                )
                .animate(
                  trigger: 0,
                  duration: const Duration(milliseconds: 1000),
                ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.noScaling),
            child: Scaffold(
              backgroundColor: const Color(0xFF111111),
              body: Center(
                child: RepaintBoundary(
                  key: captureKey,
                  child: ColoredBox(
                    color: const Color(0xFF111111),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: row,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      File('/tmp/probe_actual_position.png')
          .writeAsBytesSync(byteData!.buffer.asUint8List());
    });

    final rowRb = rowKey.currentContext!.findRenderObject() as RenderBox;
    for (final entry in [
      ('sibling', siblingKey),
      ('plain  ', plainKey),
      ('rolled ', rolledKey),
    ]) {
      final rb = entry.$2.currentContext!.findRenderObject() as RenderBox;
      final localTopLeft =
          rb.localToGlobal(Offset.zero, ancestor: rowRb);
      final baseline =
          rb.getDryBaseline(rb.constraints, TextBaseline.alphabetic);
      // ignore: avoid_print
      print('${entry.$1}: top=${localTopLeft.dy.toStringAsFixed(2)}  '
          'size=${rb.size}  '
          'baseline_dist=${baseline?.toStringAsFixed(2)}  '
          'baseline_y_in_row=${baseline == null ? "null" : (localTopLeft.dy + baseline).toStringAsFixed(2)}');
    }
  });
}
