import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  group('shaped rolling widget', () {
    testWidgets('renders Latin text without exception', (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('Hello')
              .roll(renderMode: TextRenderMode.contextualCharacters)
              .animate(trigger: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Arabic text without exception', (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('مرحبا')
              .roll(renderMode: TextRenderMode.contextualCharacters)
              .animate(trigger: 0),
          defaultStyle:
              const TextStyle(fontFamily: 'TestArabic', fontSize: 32),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('trigger change drives scroll without exception',
        (tester) async {
      String t = 'World';
      late StateSetter setterFn;
      await tester.pumpWidget(
        wrapInTestApp(
          StatefulBuilder(builder: (context, setState) {
            setterFn = setState;
            return Text(t)
                .roll(renderMode: TextRenderMode.contextualCharacters)
                .animate(
                  trigger: t,
                  duration: const Duration(milliseconds: 300),
                );
          }),
        ),
      );
      await tester.pumpAndSettle();
      setterFn(() => t = 'Hola!');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
