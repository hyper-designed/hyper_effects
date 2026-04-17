// Probe: read a plain Text's paragraph metrics by accessing the
// RenderParagraph directly. There's a mystery: my parity probe
// shows plain Text(GloriaHallelujah, 56pt) reports baseline=63.23
// and size.height=80, but a manual ShapedText.build at the same
// style reports paragraph.alphabeticBaseline=78.70 and
// paragraph.height=111. Where's the divergence?

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

  testWidgets('compare plain Text widget to manual ShapedText.build',
      (tester) async {
    const font = 'TestGloriaHallelujah';
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.noScaling),
            child: Scaffold(
              body: Text(
                'AbpgQ',
                key: key,
                style: const TextStyle(fontFamily: font, fontSize: 56),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rb = key.currentContext!.findRenderObject() as RenderParagraph;
    // ignore: avoid_print
    print('=== RenderParagraph plain Text $font 56pt ===');
    // ignore: avoid_print
    print('  size=${rb.size}');
    // ignore: avoid_print
    print('  dryBaseline=${rb.getDryBaseline(rb.constraints, TextBaseline.alphabetic)}');

    final shaped = ShapedText.build(
      text: 'AbpgQ',
      style: const TextStyle(fontFamily: font, fontSize: 56),
    );
    // ignore: avoid_print
    print('=== ShapedText.build (manual, no strut) ===');
    // ignore: avoid_print
    print('  paragraph.height=${shaped.paragraph.height}');
    // ignore: avoid_print
    print('  paragraph.alphabeticBaseline=${shaped.paragraph.alphabeticBaseline}');
    // ignore: avoid_print
    print('  shaped.size=${shaped.size}');

    // What if we explicitly set height: 1.0?
    final shapedH1 = ShapedText.build(
      text: 'AbpgQ',
      style: const TextStyle(
          fontFamily: font, fontSize: 56, height: 1.0),
    );
    // ignore: avoid_print
    print('=== ShapedText.build (height: 1.0) ===');
    // ignore: avoid_print
    print('  paragraph.height=${shapedH1.paragraph.height}');
    // ignore: avoid_print
    print('  paragraph.alphabeticBaseline=${shapedH1.paragraph.alphabeticBaseline}');

    // What does TextPainter do?
    final tp = TextPainter(
      text: const TextSpan(
        text: 'AbpgQ',
        style: TextStyle(fontFamily: font, fontSize: 56),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    // ignore: avoid_print
    print('=== TextPainter ===');
    // ignore: avoid_print
    print('  size=${tp.size}');

    // Try TextPainter with the half-leading-stripping behavior
    // RenderParagraph might be applying.
    final tp2 = TextPainter(
      text: const TextSpan(
        text: 'AbpgQ',
        style: TextStyle(fontFamily: font, fontSize: 56),
      ),
      textDirection: TextDirection.ltr,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );
    tp2.layout();
    // ignore: avoid_print
    print('=== TextPainter (no leading on first/last) ===');
    // ignore: avoid_print
    print('  size=${tp2.size}');

    // ShapedText with the same TextHeightBehavior.
    final shapedTHB = ShapedText.build(
      text: 'AbpgQ',
      style: const TextStyle(fontFamily: font, fontSize: 56),
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );
    // ignore: avoid_print
    print('=== ShapedText.build (THB=false/false) ===');
    // ignore: avoid_print
    print('  paragraph.height=${shapedTHB.paragraph.height}');
    // ignore: avoid_print
    print('  paragraph.alphabeticBaseline=${shapedTHB.paragraph.alphabeticBaseline}');
    // ignore: avoid_print
    print('  shaped.size=${shapedTHB.size}');
  });
}
