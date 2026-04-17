// This file pins the LEGACY (TextRenderMode.independentCharacters) path's
// RTL/complex-script behavior. "Current behavior" in the group name refers
// to the legacy path; the v0.4 default (contextualCharacters) renders
// correctly and is pinned by the Phase 4 shaped-rolling goldens.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../helpers/test_app.dart';

void main() {
  group('RollingText — current RTL/complex-script behavior (baseline)', () {
    testWidgets('Arabic: one Row child per grapheme cluster, logical order',
        (tester) async {
      const arabic = 'مرحبا'; // 5 grapheme clusters
      await tester.pumpWidget(
        wrapInTestApp(
          const Text(arabic).roll(renderMode: kLegacyRenderMode).animate(trigger: 0),
          defaultStyle: const TextStyle(
            fontFamily: 'TestArabic',
            fontSize: 32,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(arabic.characters.length, 5);
      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.children.length, greaterThanOrEqualTo(5),
          reason: 'Logical iteration; one widget per grapheme cluster.');
    });

    testWidgets('Japanese: one widget per grapheme cluster', (tester) async {
      const japanese = 'さよなら'; // 4 grapheme clusters (hiragana)
      await tester.pumpWidget(
        wrapInTestApp(
          const Text(japanese).roll(renderMode: kLegacyRenderMode).animate(trigger: 0),
          defaultStyle: const TextStyle(
            fontFamily: 'TestJapanese',
            fontSize: 32,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(japanese.characters.length, 4);
      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.children.length, greaterThanOrEqualTo(4));
    });

    testWidgets('rtl textDirection ambient is accepted (threads through)',
        (tester) async {
      // .roll() is a Text-specific extension, so we use wrapInTestApp's
      // textDirection parameter to inject RTL, then roll the Text child.
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('مرحبا').roll(renderMode: kLegacyRenderMode).animate(trigger: 0),
          textDirection: TextDirection.rtl,
          defaultStyle: const TextStyle(fontFamily: 'TestArabic', fontSize: 32),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
