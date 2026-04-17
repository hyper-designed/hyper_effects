// Probe: render LikeButton-style and EmojiLine-style scenarios at
// settled state and compare rolled vs plain-Text-as-control. If
// the rolled box visually drifts from a plain-Text replacement,
// it's a real bug in the render object. If they look identical,
// the user is reading something else as "baseline broken".

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

  testWidgets('LikeButton-style: rolled vs plain text side-by-side',
      (tester) async {
    final png = await _capture(tester, useRolled: true);
    File('/tmp/probe_lb_rolled.png').writeAsBytesSync(png);
    final png2 = await _capture(tester, useRolled: false);
    File('/tmp/probe_lb_plain.png').writeAsBytesSync(png2);
  });

  testWidgets('EmojiLine-style: rolled vs plain text', (tester) async {
    final png = await _captureEmoji(tester, useRolled: true);
    File('/tmp/probe_el_rolled.png').writeAsBytesSync(png);
    final png2 = await _captureEmoji(tester, useRolled: false);
    File('/tmp/probe_el_plain.png').writeAsBytesSync(png2);
  });
}

Future<Uint8List> _capture(
  WidgetTester tester, {
  required bool useRolled,
}) async {
  final key = GlobalKey();
  const t = Text(
    '19K',
    style: TextStyle(
      fontFamily: 'TestLatin',
      color: Colors.white,
      fontSize: 16,
    ),
  );
  final Widget text =
      useRolled ? t.roll(symbolDistanceMultiplier: 2) : t;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.noScaling),
          child: Scaffold(
            backgroundColor: const Color(0xFF111111),
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: Material(
                  clipBehavior: Clip.hardEdge,
                  borderRadius: BorderRadius.circular(32),
                  color: const Color(0xFF272727),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.thumb_up_sharp,
                            size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        text,
                        const VerticalDivider(
                          color: Colors.white54,
                          indent: 4,
                          endIndent: 4,
                        ),
                        const Icon(Icons.thumb_down_sharp,
                            size: 18, color: Colors.white),
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
    final image = await boundary.toImage(pixelRatio: 4.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData!.buffer.asUint8List();
  }).then((value) => value!);
}

Future<Uint8List> _captureEmoji(
  WidgetTester tester, {
  required bool useRolled,
}) async {
  final key = GlobalKey();
  const t = Text(
    'Hello',
    style: TextStyle(
      fontFamily: 'TestLatin',
      color: Color(0xFF111111),
      fontSize: 28,
    ),
  );
  final Widget text =
      useRolled ? t.roll(symbolDistanceMultiplier: 2) : t;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.noScaling),
          child: Scaffold(
            backgroundColor: const Color(0xFF111111),
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7F50),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: text,
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
    final image = await boundary.toImage(pixelRatio: 4.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData!.buffer.asUint8List();
  }).then((value) => value!);
}
