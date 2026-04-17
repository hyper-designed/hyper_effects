// Probe: replicate TagLine using the REAL fonts the example app
// loads (GloriaHallelujah for the rolled tagline, RobotoMono for
// the sibling "We help you"). Tests with `TestSacramento` /
// `TestLatin` substitutes pass baseline parity, but the user's
// running app shows "Learn" sitting visibly low — meaning the
// real fonts' metrics diverge from our test substitutes.
//
// This probe captures the screenshot AND prints the actual
// `getDistanceToActualBaseline` of each child after layout, so we
// can confirm the divergence numerically.

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

  testWidgets('TagLine real fonts: visual capture', (tester) async {
    final png = await _captureRealTagLine(tester);
    File('/tmp/probe_tagline_real_fonts.png').writeAsBytesSync(png);
  });

  testWidgets('TagLine real fonts: print baselines', (tester) async {
    final siblingKey = GlobalKey();
    final rolledOuterKey = GlobalKey();
    final rolledBareKey = GlobalKey();

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
                  Text(
                    'We help you',
                    key: siblingKey,
                    style: const TextStyle(
                      fontFamily: 'TestRobotoMono',
                      fontSize: 48,
                    ),
                  ),
                  KeyedSubtree(
                    key: rolledBareKey,
                    child: const Text(
                      'Learn',
                      style: TextStyle(
                        fontFamily: 'TestGloriaHallelujah',
                        fontWeight: FontWeight.bold,
                        fontSize: 56,
                      ),
                    ).roll(symbolDistanceMultiplier: 2),
                  ),
                  KeyedSubtree(
                    key: rolledOuterKey,
                    child: ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white,
                          Colors.white,
                          Colors.white,
                          Colors.white,
                          Colors.white.withValues(alpha: 0),
                        ],
                      ).createShader(rect),
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [Color(0xFFBFF098), Color(0xFF6FD6FF)],
                        ).createShader(rect),
                        child: const Text(
                          'Learn',
                          style: TextStyle(
                            fontFamily: 'TestGloriaHallelujah',
                            fontWeight: FontWeight.bold,
                            fontSize: 56,
                          ),
                        )
                            .roll(symbolDistanceMultiplier: 2)
                            .animate(
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
      ('sibling RobotoMono 48pt', siblingKey),
      ('rolled bare GloriaHallelujah 56pt', rolledBareKey),
      ('rolled +ShaderMask×2 +animate', rolledOuterKey),
    ]) {
      final rb = entry.$2.currentContext!.findRenderObject() as RenderBox;
      final dryB =
          rb.getDryBaseline(rb.constraints, TextBaseline.alphabetic);
      // ignore: avoid_print
      print('${entry.$1}: size=${rb.size}  dryBaseline=$dryB');
    }
  });
}

Future<Uint8List> _captureRealTagLine(WidgetTester tester) async {
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          'We help you',
                          style: TextStyle(
                            fontFamily: 'TestRobotoMono',
                            color: Colors.white,
                            fontSize: 48,
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (rect) => LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white,
                              Colors.white,
                              Colors.white,
                              Colors.white,
                              Colors.white.withValues(alpha: 0),
                            ],
                          ).createShader(rect),
                          child: ShaderMask(
                            shaderCallback: (rect) => const LinearGradient(
                              colors: [
                                Color(0xFFBFF098),
                                Color(0xFF6FD6FF),
                              ],
                            ).createShader(rect),
                            child: const Text(
                              'Learn',
                              style: TextStyle(
                                fontFamily: 'TestGloriaHallelujah',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 56,
                              ),
                            )
                                .roll(
                                  symbolDistanceMultiplier: 2,
                                  tapeSlideDirection:
                                      TextTapeSlideDirection.down,
                                  tapeCurve: Curves.easeInOutCubic,
                                  widthCurve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.only(left: 16),
                                )
                                .animate(
                                  trigger: 0,
                                  duration:
                                      const Duration(milliseconds: 1000),
                                ),
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
