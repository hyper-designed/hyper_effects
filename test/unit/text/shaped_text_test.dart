import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../../helpers/test_font_loader.dart';

void main() {
  setUp(loadTestFonts);

  const style = TextStyle(fontFamily: 'TestLatin', fontSize: 32);

  group('ShapedText.build — clusters', () {
    test('Latin "abc" returns 3 clusters in logical order', () {
      final shaped = ShapedText.build(text: 'abc', style: style);
      expect(shaped.clusters, hasLength(3));
      expect(shaped.clusters[0].text, 'a');
      expect(shaped.clusters[1].text, 'b');
      expect(shaped.clusters[2].text, 'c');
      for (int i = 0; i < 3; i++) {
        expect(shaped.clusters[i].logicalIndex, i);
      }
    });

    test('clusters have non-zero bounds', () {
      final shaped = ShapedText.build(text: 'abc', style: style);
      for (final c in shaped.clusters) {
        expect(c.bounds.width, greaterThan(0));
        expect(c.bounds.height, greaterThan(0));
      }
    });

    test('clusters have LTR direction for Latin text', () {
      final shaped = ShapedText.build(text: 'abc', style: style);
      for (final c in shaped.clusters) {
        expect(c.direction, TextDirection.ltr);
      }
    });

    test('empty string returns empty clusters list', () {
      final shaped = ShapedText.build(text: '', style: style);
      expect(shaped.clusters, isEmpty);
    });

    test('Arabic lam-alef "لا" is 2 grapheme clusters (one per base letter)', () {
      const arabicStyle =
          TextStyle(fontFamily: 'TestArabic', fontSize: 32);
      final shaped = ShapedText.build(
        text: 'لا',
        style: arabicStyle,
        textDirection: TextDirection.rtl,
      );
      expect(shaped.clusters, hasLength(2),
          reason: 'lam-alef is 2 grapheme clusters in Unicode '
              '(U+0644 U+0627); the ligature is a shaping concern, '
              'not a clustering concern. Each letter is its own cluster.');
    });

    test('ZWJ family emoji "👨‍👩‍👧‍👦" is a SINGLE cluster', () {
      const emojiStyle = TextStyle(
        fontFamilyFallback: ['TestLatin', 'TestEmoji'],
        fontSize: 32,
      );
      final shaped = ShapedText.build(
        text: '👨‍👩‍👧‍👦',
        style: emojiStyle,
      );
      expect(shaped.clusters, hasLength(1),
          reason: 'ZWJ family is ONE grapheme cluster per UAX #29');
      expect(shaped.clusters.single.text, '👨‍👩‍👧‍👦');
      expect(shaped.clusters.single.codeUnitRange.end -
          shaped.clusters.single.codeUnitRange.start,
          greaterThan(1),
          reason: 'Range spans multiple code units');
    });

    test('combining mark "é" (NFD: e + U+0301) is one cluster', () {
      final shaped = ShapedText.build(text: 'e\u0301', style: style);
      expect(shaped.clusters, hasLength(1));
      expect(shaped.clusters.single.text, 'e\u0301');
    });
  });

  group('ShapedText.build — single line', () {
    test('builds a paragraph for an ASCII string', () {
      final shaped = ShapedText.build(text: 'Hello', style: style);
      expect(shaped.paragraph, isA<ui.Paragraph>());
      expect(shaped.size.width, greaterThan(0));
      expect(shaped.size.height, greaterThan(0));
      expect(shaped.lines, hasLength(1));
    });

    test('empty string has zero width and zero lines', () {
      // ADJUSTED: plan expected hasLength(1) but Skia returns [] for empty
      // strings — computeLineMetrics() produces no LineMetrics when there is
      // no text to lay out. Adjusted to match actual engine behavior.
      final shaped = ShapedText.build(text: '', style: style);
      expect(shaped.size.width, 0);
      expect(shaped.lines, isEmpty);
    });

    test('size reflects the longest line', () {
      final short = ShapedText.build(text: 'hi', style: style);
      final longer = ShapedText.build(text: 'hello world', style: style);
      expect(longer.size.width, greaterThan(short.size.width));
    });
  });

  group('ShapedText.build — multiline', () {
    test('wraps text when maxWidth is tight', () {
      // 'hello world' at fontSize 32 in TestLatin is ~180-200px; force
      // it to wrap by setting a narrow maxWidth.
      final shaped = ShapedText.build(
        text: 'hello world',
        style: style,
        maxWidth: 100,
      );
      expect(shaped.lines.length, greaterThanOrEqualTo(2),
          reason: 'narrow maxWidth must produce at least 2 lines');
    });

    test('clusters carry correct lineIndex after wrap', () {
      final shaped = ShapedText.build(
        text: 'hello world',
        style: style,
        maxWidth: 100,
      );
      final lineIndices = shaped.clusters.map((c) => c.lineIndex).toSet();
      expect(lineIndices.length, greaterThanOrEqualTo(2));
      // lineIndex values are 0-based and contiguous.
      for (int i = 0; i < shaped.lines.length; i++) {
        expect(lineIndices, contains(i));
      }
    });

    test('explicit \\n creates multiple lines even without maxWidth', () {
      final shaped = ShapedText.build(text: 'a\nb', style: style);
      expect(shaped.lines.length, 2);
      // OBSERVED: grapheme iteration yields ['a', '\n', 'b'] (3 entries)
      // but getGlyphInfoAt on the '\n' offset returns null in Skia — the
      // newline character has no visible glyph. So we get 2 clusters total.
      expect(shaped.clusters, hasLength(2));
      expect(shaped.clusters[0].lineIndex, 0);
      expect(shaped.clusters[1].lineIndex, 1);
    });

    test('visual order groups by line first (explicit \n)', () {
      final shaped = ShapedText.build(text: 'ab\ncd', style: style);
      // Within each line, LTR left-to-right; across lines, line 0 then 1.
      expect(shaped.clusters.map((c) => c.visualIndex),
          orderedEquals([0, 1, 2, 3]));
      expect(shaped.clusters[0].lineIndex, 0);
      expect(shaped.clusters[1].lineIndex, 0);
      expect(shaped.clusters[2].lineIndex, 1);
      expect(shaped.clusters[3].lineIndex, 1);
    });
  });

  group('ShapedText.build — visual order', () {
    test('LTR text has visualIndex == logicalIndex', () {
      final shaped = ShapedText.build(text: 'abc', style: style);
      for (final c in shaped.clusters) {
        expect(c.visualIndex, c.logicalIndex);
      }
    });

    test('RTL Arabic text has clusters in visual (LTR pixel) order', () {
      const arabicStyle = TextStyle(fontFamily: 'TestArabic', fontSize: 32);
      final shaped = ShapedText.build(
        text: 'مرحبا',
        style: arabicStyle,
        textDirection: TextDirection.rtl,
      );
      // In visual order (left to right on screen), RTL text appears
      // with its LAST source character on the LEFT and its FIRST
      // source character on the RIGHT. So cluster with logicalIndex=0
      // should have the largest visualIndex.
      expect(shaped.clusters, hasLength(5));
      // Clusters are emitted in visual order by our iteration, so
      // clusters[0] is the visually leftmost.
      expect(shaped.clusters[0].bounds.left,
          lessThan(shaped.clusters[4].bounds.left));
      // And the leftmost visual cluster should be the LAST logical
      // character (for pure RTL text).
      expect(shaped.clusters[0].logicalIndex, 4);
      expect(shaped.clusters[4].logicalIndex, 0);
    });

    test('clusters are sorted by bounds.left within a line', () {
      final shaped = ShapedText.build(text: 'abc', style: style);
      for (int i = 1; i < shaped.clusters.length; i++) {
        expect(shaped.clusters[i].bounds.left,
            greaterThanOrEqualTo(shaped.clusters[i - 1].bounds.left));
      }
    });
  });
}
