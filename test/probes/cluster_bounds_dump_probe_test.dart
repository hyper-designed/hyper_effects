// Probe: dump every cluster's bounds + paragraph-level metrics for
// the strut-leading-1 paragraph used by .roll() with various
// fonts. The paint code does
// `offsetY = baselineYInRow - lineAscent - rect.top`, so any
// asymmetry between `paragraph.alphabeticBaseline`,
// `lineMetrics[0].ascent`, and `cluster.bounds.top` will translate
// directly into a visual baseline offset.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  for (final font in const [
    'TestRobotoMono',
    'TestGloriaHallelujah',
    'TestSacramento',
    'TestLatin',
  ]) {
    test('dump cluster + line metrics for $font 56pt strut.leading=1',
        () async {
      final shaped = ShapedText.build(
        text: 'AbpgQ',
        style: TextStyle(fontFamily: font, fontSize: 56),
        strutStyle: const StrutStyle(
          fontSize: 56,
          height: 1,
          forceStrutHeight: true,
          leading: 1,
        ),
      );
      final paragraph = shaped.paragraph;
      // ignore: avoid_print
      print('\n=== $font 56pt strut.leading=1 ===');
      // ignore: avoid_print
      print('  paragraph.height=${paragraph.height}');
      // ignore: avoid_print
      print('  paragraph.alphabeticBaseline=${paragraph.alphabeticBaseline}');
      // ignore: avoid_print
      print('  shaped.size=${shaped.size}');
      for (final lm in shaped.lines) {
        // ignore: avoid_print
        print('  line[${lm.lineNumber}]: ascent=${lm.ascent} '
            'descent=${lm.descent} height=${lm.height} '
            'baseline=${lm.baseline}');
      }
      for (final c in shaped.clusters) {
        // ignore: avoid_print
        print('  cluster[${c.logicalIndex}] "${c.text}": '
            'top=${c.bounds.top} bottom=${c.bounds.bottom} '
            'left=${c.bounds.left} right=${c.bounds.right}');
      }

      // Same paragraph but WITHOUT strut leading.
      final shapedNoStrut = ShapedText.build(
        text: 'AbpgQ',
        style: TextStyle(fontFamily: font, fontSize: 56),
      );
      // ignore: avoid_print
      print('  -- no strut: '
          'paragraph.height=${shapedNoStrut.paragraph.height} '
          'baseline=${shapedNoStrut.paragraph.alphabeticBaseline}');
      for (final c in shapedNoStrut.clusters) {
        // ignore: avoid_print
        print('  no-strut cluster[${c.logicalIndex}] "${c.text}": '
            'top=${c.bounds.top} bottom=${c.bounds.bottom}');
      }
    });
  }
}
