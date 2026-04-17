import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/text/shaped_cluster.dart';

void main() {
  group('ShapedCluster', () {
    test('stores every field exactly', () {
      const cluster = ShapedCluster(
        logicalIndex: 3,
        visualIndex: 1,
        codeUnitRange: TextRange(start: 2, end: 4),
        bounds: Rect.fromLTWH(10, 20, 30, 40),
        direction: TextDirection.rtl,
        text: 'ل',
        lineIndex: 0,
      );
      expect(cluster.logicalIndex, 3);
      expect(cluster.visualIndex, 1);
      expect(cluster.codeUnitRange, const TextRange(start: 2, end: 4));
      expect(cluster.bounds, const Rect.fromLTWH(10, 20, 30, 40));
      expect(cluster.direction, TextDirection.rtl);
      expect(cluster.text, 'ل');
      expect(cluster.lineIndex, 0);
    });

    test('equality is structural', () {
      const a = ShapedCluster(
        logicalIndex: 0,
        visualIndex: 0,
        codeUnitRange: TextRange(start: 0, end: 1),
        bounds: Rect.fromLTWH(0, 0, 10, 20),
        direction: TextDirection.ltr,
        text: 'a',
        lineIndex: 0,
      );
      const b = ShapedCluster(
        logicalIndex: 0,
        visualIndex: 0,
        codeUnitRange: TextRange(start: 0, end: 1),
        bounds: Rect.fromLTWH(0, 0, 10, 20),
        direction: TextDirection.ltr,
        text: 'a',
        lineIndex: 0,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString is informative', () {
      const cluster = ShapedCluster(
        logicalIndex: 0,
        visualIndex: 0,
        codeUnitRange: TextRange(start: 0, end: 1),
        bounds: Rect.fromLTWH(0, 0, 10, 20),
        direction: TextDirection.ltr,
        text: 'a',
        lineIndex: 0,
      );
      final s = cluster.toString();
      expect(s, contains('ShapedCluster'));
      expect(s, contains("'a'"));
      expect(s, contains('logical: 0'));
    });
  });
}
