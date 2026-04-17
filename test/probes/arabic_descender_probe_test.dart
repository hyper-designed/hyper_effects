// Probe: render Arabic in the rolled widget to reproduce the
// descender-clipping bug. The user's screenshot shows the 'ر' tail
// being cut off at the rolled box's bottom. With my latest fix,
// box height = paragraph.height — but if the cluster's actual ink
// extends below paragraph.height (Arabic descenders past the line
// box), the slot's vertical clip cuts it off.

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

  test('arabic paragraph metrics dump', () async {
    final shaped = ShapedText.build(
      text: 'شكرا',
      style: const TextStyle(fontFamily: 'TestArabic', fontSize: 48),
      strutStyle: const StrutStyle(
        fontSize: 48,
        height: 1,
        forceStrutHeight: true,
        leading: 0,
      ),
    );
    // ignore: avoid_print
    print('=== Arabic 48pt strut.leading=0 ===');
    // ignore: avoid_print
    print('  paragraph.height=${shaped.paragraph.height}');
    // ignore: avoid_print
    print('  paragraph.alphabeticBaseline=${shaped.paragraph.alphabeticBaseline}');
    for (final lm in shaped.lines) {
      // ignore: avoid_print
      print('  line[0]: ascent=${lm.ascent} descent=${lm.descent} '
          'height=${lm.height}');
    }
    for (final c in shaped.clusters) {
      // ignore: avoid_print
      print('  cluster[${c.logicalIndex}] "${c.text}": '
          'top=${c.bounds.top} bottom=${c.bounds.bottom}');
    }
  });

  testWidgets('arabic rolled widget capture', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: const Color(0xFF111111),
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: Container(
                color: const Color(0xFF000000),
                padding: const EdgeInsets.all(16),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: ColoredBox(
                    color: const Color(0x33FFFF00),
                    child: const Text(
                      'شكرا',
                      style: TextStyle(
                        fontFamily: 'TestArabic',
                        color: Colors.white,
                        fontSize: 48,
                      ),
                    ).roll(),
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
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 4.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      File('/tmp/probe_arabic_descender.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
