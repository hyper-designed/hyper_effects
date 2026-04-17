// Probe: print the resolved DefaultTextStyle inside a typical
// MaterialApp/Scaffold widget tree. The mystery: a plain Text
// widget with TextStyle(fontFamily: 'TestGloriaHallelujah',
// fontSize: 56) reports baseline=63.23 size=80, but a manual
// ShapedText.build with the SAME style + same strut reports
// baseline=78.70 size=111. The merge with DefaultTextStyle (which
// adds Material's default height value) is the suspected cause.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
  });

  testWidgets('print DefaultTextStyle inside MaterialApp/Scaffold',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final ds = DefaultTextStyle.of(context).style;
              // ignore: avoid_print
              print('DefaultTextStyle.style:');
              // ignore: avoid_print
              print('  fontFamily=${ds.fontFamily}');
              // ignore: avoid_print
              print('  fontSize=${ds.fontSize}');
              // ignore: avoid_print
              print('  height=${ds.height}');
              // ignore: avoid_print
              print('  fontWeight=${ds.fontWeight}');
              // ignore: avoid_print
              print('  textBaseline=${ds.textBaseline}');
              // ignore: avoid_print
              print('  leadingDistribution=${ds.leadingDistribution}');

              const userStyle = TextStyle(
                fontFamily: 'TestGloriaHallelujah',
                fontSize: 56,
              );
              final merged = ds.copyWith(inherit: true).merge(userStyle);
              // ignore: avoid_print
              print('Merged style (.merge(userStyle)):');
              // ignore: avoid_print
              print('  fontFamily=${merged.fontFamily}');
              // ignore: avoid_print
              print('  fontSize=${merged.fontSize}');
              // ignore: avoid_print
              print('  height=${merged.height}');
              // ignore: avoid_print
              print('  leadingDistribution=${merged.leadingDistribution}');
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  });
}
