import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/effects/roll/legacy/legacy_rolling_text_controller.dart';

const style = TextStyle(
  fontFamily: 'TestLatin',
  fontSize: 32,
  color: Color(0xFF111111),
);

LegacyRollingTextController _makeController({
  required String oldText,
  required String newText,
}) => LegacyRollingTextController(
      oldText: oldText,
      newText: newText,
      tapeStrategy: const ConsistentSymbolTapeStrategy(0),
      tapeSlideDirection: TextTapeSlideDirection.up,
      style: style,
    );

void main() {

  group('RollingTextController', () {
    // NOTE: buildTapes() returns a new List and does NOT populate the instance
    // `tapes` field — that only happens via layout(). Tests below check the
    // returned list length directly.

    test('buildTapes produces one tape per max(oldText, newText) character', () {
      final controller = _makeController(oldText: 'abc', newText: 'xyzw');
      final tapes = controller.buildTapes();
      // Longest is 4 (newText), so 4 tapes.
      expect(tapes.length, 4);
    });

    test('buildTapes with equal-length strings yields one tape per character',
        () {
      final controller = _makeController(oldText: 'abc', newText: 'xyz');
      final tapes = controller.buildTapes();
      expect(tapes.length, 3);
    });

    test('buildTapes handles empty old text (e.g. initial state)', () {
      final controller = _makeController(oldText: '', newText: 'hello');
      final tapes = controller.buildTapes();
      expect(tapes.length, 5);
    });

    test('buildTapes with identical texts still produces one tape per char', () {
      final controller = _makeController(oldText: 'abc', newText: 'abc');
      final tapes = controller.buildTapes();
      expect(tapes.length, 3);
    });

    test('buildTapePainters matches tape count', () {
      final controller = _makeController(oldText: 'abc', newText: 'xyz');
      // buildTapePainters(tapes) requires the tapes list as input.
      final tapes = controller.buildTapes();
      final painters = controller.buildTapePainters(tapes);
      expect(painters.length, 3);
    });

    test('calculateTapeHeights produces one height entry per tape', () {
      final controller = _makeController(oldText: 'abc', newText: 'xyz');
      // layout() populates the instance tapes, tapePainters (laid out), and
      // tapeHeights fields together. calculateTapeHeights() alone requires
      // tapePainters to already be laid out, so use layout() here.
      controller.layout();
      expect(controller.tapeHeights.length, 3);
      for (final h in controller.tapeHeights.values) {
        expect(h, greaterThanOrEqualTo(0));
      }
    });
  });
}
