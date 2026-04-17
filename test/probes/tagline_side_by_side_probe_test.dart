// Probe: render the sibling RobotoMono + a PLAIN GloriaHallelujah
// + a ROLLED GloriaHallelujah all in the same Row(baseline). If
// plain and rolled "Learn" land at different y positions in the
// same row, the rolled widget's reported baseline disagrees with
// where it actually paints.

import 'dart:io';
import 'dart:typed_data';
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

  testWidgets('plain vs rolled Learn next to each other', (tester) async {
    final png = await _capture(tester);
    File('/tmp/probe_tagline_side_by_side.png').writeAsBytesSync(png);
  });
}

Future<Uint8List> _capture(WidgetTester tester) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.noScaling),
          child: Scaffold(
            backgroundColor: const Color(0xFF111111),
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: const Color(0xFF111111),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          'We help you ',
                          style: TextStyle(
                            fontFamily: 'TestRobotoMono',
                            color: Colors.white,
                            fontSize: 48,
                          ),
                        ),
                        const Text(
                          'Plain',
                          style: TextStyle(
                            fontFamily: 'TestGloriaHallelujah',
                            color: Color(0xFF6FD6FF),
                            fontSize: 56,
                          ),
                        ),
                        const SizedBox(width: 24),
                        const Text(
                          'Rolled',
                          style: TextStyle(
                            fontFamily: 'TestGloriaHallelujah',
                            color: Color(0xFFBFF098),
                            fontSize: 56,
                          ),
                        ).roll(symbolDistanceMultiplier: 2),
                      ],
                    ),
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
  return tester.runAsync<Uint8List>(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData!.buffer.asUint8List();
  }).then((value) => value!);
}
