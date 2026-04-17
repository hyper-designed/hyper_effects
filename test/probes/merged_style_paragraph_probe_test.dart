// Probe: build a paragraph with the EXACT same style merging as
// the rolled widget receives inside Material. Print all metrics
// to find where the visual misalignment comes from.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  testWidgets('paragraph metrics with Material-merged style',
      (tester) async {
    late TextStyle mergedStyle;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final ds = DefaultTextStyle.of(context).style.copyWith(inherit: true);
              const userStyle = TextStyle(
                fontFamily: 'TestGloriaHallelujah',
                fontSize: 56,
              );
              mergedStyle = ds.merge(userStyle);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    // Build paragraph WITH the merged style + roll's strut config.
    final shaped = ShapedText.build(
      text: 'AbpgQ',
      style: mergedStyle,
      strutStyle: const StrutStyle(
        fontSize: 56,
        height: 1,
        forceStrutHeight: true,
        leading: 1,
      ),
    );
    // ignore: avoid_print
    print('=== merged style + strut.leading=1 forceStrutHeight=true ===');
    // ignore: avoid_print
    print('  paragraph.height=${shaped.paragraph.height}');
    // ignore: avoid_print
    print('  paragraph.alphabeticBaseline=${shaped.paragraph.alphabeticBaseline}');
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
          'top=${c.bounds.top} bottom=${c.bounds.bottom}');
    }

    // Same merged style WITHOUT strut.
    final shapedNoStrut = ShapedText.build(
      text: 'AbpgQ',
      style: mergedStyle,
    );
    // ignore: avoid_print
    print('=== merged style, no strut ===');
    // ignore: avoid_print
    print('  paragraph.height=${shapedNoStrut.paragraph.height}');
    // ignore: avoid_print
    print('  paragraph.alphabeticBaseline=${shapedNoStrut.paragraph.alphabeticBaseline}');
    for (final lm in shapedNoStrut.lines) {
      // ignore: avoid_print
      print('  line[${lm.lineNumber}]: ascent=${lm.ascent} '
          'descent=${lm.descent}');
    }
    for (final c in shapedNoStrut.clusters) {
      // ignore: avoid_print
      print('  cluster[${c.logicalIndex}] "${c.text}": '
          'top=${c.bounds.top} bottom=${c.bounds.bottom}');
    }
  });
}
