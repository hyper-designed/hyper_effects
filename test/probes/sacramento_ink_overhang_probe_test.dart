// Probe: measure how far Sacramento's cursive flourishes (entry on
// the leading letter, exit on the trailing letter) extend BEYOND
// the advance bounds of those clusters. The current row painter
// clips slots to advance bounds + slotClipPadding (24 px); if the
// flourishes are larger than that pad, they're getting cut. We
// don't want to keep raising the pad — this measurement informs a
// root-cause discussion of how to fix the clipping architecturally.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  const style = TextStyle(
    fontFamily: 'TestSacramento',
    fontWeight: FontWeight.bold,
    fontSize: 56,
  );

  testWidgets('Sacramento flourish vs advance — Salaam, Namaste, Ni Hao',
      (tester) async {
    final out = StringBuffer();
    for (final word in const ['Salaam', 'Namaste', 'Ni Hao']) {
      out.writeln('=== $word ===');
      final shaped = ShapedText.build(text: word, style: style);

      // Per-cluster advance bounds.
      out.writeln('Per-cluster advance bounds (graphemeClusterLayoutBounds):');
      for (final c in shaped.clusters) {
        out.writeln('  [${c.logicalIndex}/${c.visualIndex}] '
            '"${c.text}" '
            'advance=${c.bounds}');
      }

      // Paragraph maxIntrinsicWidth and longestLine.
      out.writeln(
          'paragraph.longestLine=${shaped.paragraph.longestLine.toStringAsFixed(2)}');
      out.writeln('paragraph.size=${shaped.size}');

      // Picture-bounds: render the paragraph and read back the
      // cull rect after layout. PictureRecorder + drawParagraph
      // gives us a Picture whose `cullRect` reflects the actual
      // ink extents (including overhang past advance).
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawParagraph(shaped.paragraph, Offset.zero);
      final picture = recorder.endRecording();
      // dart:ui Picture has no public ink-bounds API, but the
      // approximation is to render to a bitmap larger than the
      // paragraph and find the non-transparent extent.
      final pad = 200.0;
      final w = (shaped.size.width + 2 * pad).ceil();
      final h = (shaped.size.height + 2 * pad).ceil();
      final image = await tester.runAsync<ui.Image>(() async {
        final r = ui.PictureRecorder();
        final c = Canvas(r);
        c.translate(pad, pad);
        c.drawParagraph(shaped.paragraph, Offset.zero);
        return r.endRecording().toImage(w, h);
      });
      picture.dispose();
      final bytes = await tester.runAsync(
        () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
      );
      image!.dispose();

      // Find min/max non-transparent pixels.
      int minX = w, maxX = -1, minY = h, maxY = -1;
      final pixels = bytes!.buffer.asUint8List();
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final i = (y * w + x) * 4;
          final a = pixels[i + 3];
          if (a > 8) {
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
      }
      // Subtract the pad to get coords relative to paragraph (0,0).
      final inkLeft = minX - pad;
      final inkRight = maxX - pad;
      final inkTop = minY - pad;
      final inkBottom = maxY - pad;
      out.writeln(
          'INK extent (paragraph-local): L=$inkLeft R=$inkRight T=$inkTop B=$inkBottom '
          'width=${(inkRight - inkLeft + 1).toStringAsFixed(1)} '
          'paragraph-width=${shaped.size.width.toStringAsFixed(2)}');
      // Overhang past first cluster's advance left, past last cluster's advance right.
      if (shaped.clusters.isNotEmpty) {
        final firstAdv = shaped.clusters.first.bounds.left;
        final lastAdv = shaped.clusters.last.bounds.right;
        out.writeln(
            'LEADING ink overshoot (firstClusterAdvanceLeft - inkLeft): '
            '${(firstAdv - inkLeft).toStringAsFixed(1)} px');
        out.writeln(
            'TRAILING ink overshoot (inkRight - lastClusterAdvanceRight): '
            '${(inkRight - lastAdv).toStringAsFixed(1)} px');
      }
      out.writeln();
    }

    File('/tmp/probe_sacramento_overhang.txt')
        .writeAsStringSync(out.toString());
    // ignore: avoid_print
    print(out.toString());
  });
}
