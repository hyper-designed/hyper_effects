// Probe: replicate TagLine's exact font + strut configuration to
// diagnose why baseline alignment is failing when the sibling Text
// has a different `style.fontSize` than its `strutStyle.fontSize`.

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

  testWidgets('TagLine-style: 48pt sibling with 56pt strut + 56pt rolled',
      (tester) async {
    // Replicates TagLine: sibling Text at 48pt with a strut forcing
    // 56pt line metrics, rolled at 56pt.
    final png = await _captureRow(
      tester,
      siblingFontSize: 48,
      strutFontSize: 56,
      rolledFontSize: 56,
      siblingFont: 'TestLatin', // proxy for robotoMono
      rolledFont: 'TestSacramento', // proxy for Gloria Hallelujah
    );
    File('/tmp/probe_tagline_baseline.png').writeAsBytesSync(png);
  });

  testWidgets('TagLine-style: matched 56pt fontSize on both',
      (tester) async {
    // Control: same fontSize across sibling and rolled. If this
    // aligns but the mismatched version doesn't, the issue is the
    // strut / style.fontSize divergence.
    final png = await _captureRow(
      tester,
      siblingFontSize: 56,
      strutFontSize: 56,
      rolledFontSize: 56,
      siblingFont: 'TestLatin',
      rolledFont: 'TestSacramento',
    );
    File('/tmp/probe_tagline_baseline_matched.png').writeAsBytesSync(png);
  });

  testWidgets('TagLine-style: WITH ShaderMask + AnimatedEffect',
      (tester) async {
    // Full TagLine widget tree: ShaderMask × 2 + .animate() + the
    // mismatched sibling fontSize. If this misaligns where the
    // simpler probe didn't, the issue is in the wrapper chain
    // (ShaderMask not forwarding, or animate() introducing a
    // RenderObject that drops the baseline forward).
    final png = await _captureFullTagLineShape(tester);
    File('/tmp/probe_tagline_baseline_full.png').writeAsBytesSync(png);
  });

  testWidgets('Print baseline values (rolled vs sibling)', (tester) async {
    // Mount both widgets in a Column and walk the render tree to
    // dump each one's reported alphabetic baseline.
    final rolledKey = GlobalKey();
    final siblingKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.noScaling),
            child: Scaffold(
              body: Column(
                children: [
                  _RolledHarness(key: rolledKey, fontSize: 56),
                  Text(
                    'We help you',
                    key: siblingKey,
                    style: const TextStyle(
                      fontFamily: 'TestLatin',
                      fontSize: 48,
                    ),
                    strutStyle: const StrutStyle(
                      fontSize: 56,
                      height: 1,
                      forceStrutHeight: true,
                      leading: 1,
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

    final rolledRb =
        rolledKey.currentContext!.findRenderObject() as RenderBox;
    final siblingRb =
        siblingKey.currentContext!.findRenderObject() as RenderBox;

    final rolledBaseline = rolledRb.getDryBaseline(
        rolledRb.constraints, TextBaseline.alphabetic);
    final siblingBaseline = siblingRb.getDryBaseline(
        siblingRb.constraints, TextBaseline.alphabetic);

    // ignore: avoid_print
    print('rolled  size=${rolledRb.size} baseline=$rolledBaseline');
    // ignore: avoid_print
    print('sibling size=${siblingRb.size} baseline=$siblingBaseline');
  });
}

Future<Uint8List> _captureRow(
  WidgetTester tester, {
  required double siblingFontSize,
  required double strutFontSize,
  required double rolledFontSize,
  required String siblingFont,
  required String rolledFont,
}) async {
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
                        Text(
                          'We help you',
                          style: TextStyle(
                            fontFamily: siblingFont,
                            color: Colors.white,
                            fontSize: siblingFontSize,
                          ),
                          strutStyle: StrutStyle(
                            fontSize: strutFontSize,
                            height: 1,
                            forceStrutHeight: true,
                            leading: 1,
                          ),
                        ),
                        _RolledHarness(fontSize: rolledFontSize),
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

class _RolledHarness extends StatefulWidget {
  const _RolledHarness({super.key, required this.fontSize});
  final double fontSize;
  @override
  State<_RolledHarness> createState() => _RolledHarnessState();
}

class _RolledHarnessState extends State<_RolledHarness> {
  final String _text = 'Develop';

  @override
  Widget build(BuildContext context) {
    return Text(
      _text,
      style: TextStyle(
        fontFamily: 'TestSacramento',
        color: Colors.white,
        fontSize: widget.fontSize,
      ),
    ).roll(
      symbolDistanceMultiplier: 2,
      tapeCurve: Curves.easeInOutCubic,
      widthCurve: Curves.easeOutCubic,
    );
  }
}

Future<Uint8List> _captureFullTagLineShape(WidgetTester tester) async {
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
                            fontFamily: 'TestLatin',
                            color: Colors.white,
                            fontSize: 48,
                          ),
                          strutStyle: StrutStyle(
                            fontSize: 56,
                            height: 1,
                            forceStrutHeight: true,
                            leading: 1,
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
                              'Develop',
                              style: TextStyle(
                                fontFamily: 'TestSacramento',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 56,
                              ),
                            )
                                .roll(
                                  symbolDistanceMultiplier: 2,
                                  tapeSlideDirection: TextTapeSlideDirection.down,
                                  tapeCurve: Curves.easeInOutCubic,
                                  widthCurve: Curves.easeOutCubic,
                                )
                                .animate(
                                  trigger: 0,
                                  duration: const Duration(milliseconds: 1000),
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
