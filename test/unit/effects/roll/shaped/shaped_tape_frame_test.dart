import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/effects/roll/shaped/shaped_tape_frame.dart';

void main() {
  group('TapeFrame', () {
    test('stores every field', () {
      const rect = Rect.fromLTWH(10, 20, 30, 40);
      const frame = TapeFrame(
        substitutedText: 'A',
        clusterBounds: rect,
        tapeStep: 3,
        lineAscent: 32,
        lineDescent: 8,
        slideHeight: 80,
        clusterIsParagraphLeftEdge: true,
        clusterIsParagraphRightEdge: false,
      );
      expect(frame.substitutedText, 'A');
      expect(frame.clusterBounds, rect);
      expect(frame.tapeStep, 3);
      expect(frame.lineAscent, 32);
      expect(frame.lineDescent, 8);
      expect(frame.lineHeight, 40);
      expect(frame.clusterIsParagraphLeftEdge, isTrue);
      expect(frame.clusterIsParagraphRightEdge, isFalse);
    });

    test('equality is structural', () {
      const rect = Rect.fromLTWH(0, 0, 10, 10);
      const a = TapeFrame(
        substitutedText: 'a',
        clusterBounds: rect,
        tapeStep: 0,
        lineAscent: 8,
        lineDescent: 2,
        slideHeight: 20,
        clusterIsParagraphLeftEdge: true,
        clusterIsParagraphRightEdge: true,
      );
      const b = TapeFrame(
        substitutedText: 'a',
        clusterBounds: rect,
        tapeStep: 0,
        lineAscent: 8,
        lineDescent: 2,
        slideHeight: 20,
        clusterIsParagraphLeftEdge: true,
        clusterIsParagraphRightEdge: true,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
