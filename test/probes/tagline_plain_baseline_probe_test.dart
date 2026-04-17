// Probe: control test. Mount the same fonts at the same sizes in
// the same Row(crossAxisAlignment.baseline) but use PLAIN Text
// widgets (no .roll(), no ShaderMask, no .animate()). If plain
// text alignment ALSO shows the same vertical offset, the issue
// is intrinsic to the fonts themselves — RenderShapedRolledRow's
// baseline reporting is correct. If plain text aligns but rolled
// doesn't, the rolled widget has a baseline bug.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  testWidgets('plain Text baseline alignment with real fonts',
      (tester) async {
    final png = await _capture(tester);
    File('/tmp/probe_tagline_plain_real_fonts.png').writeAsBytesSync(png);
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
                child: const ColoredBox(
                  color: Color(0xFF111111),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'We help you',
                          style: TextStyle(
                            fontFamily: 'TestRobotoMono',
                            color: Colors.white,
                            fontSize: 48,
                          ),
                        ),
                        Text(
                          'Learn',
                          style: TextStyle(
                            fontFamily: 'TestGloriaHallelujah',
                            color: Color(0xFF6FD6FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 56,
                          ),
                        ),
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
