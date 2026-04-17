import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../helpers/test_app.dart';

void main() {
  group('RollingText multiline assertion', () {
    test('multiline string triggers assertion', () {
      expect(
        () => const Text('line1\nline2').roll(renderMode: kLegacyRenderMode),
        throwsAssertionError,
      );
    });

    test('single-line string does not trigger assertion', () {
      expect(
        () => const Text('no newlines here').roll(renderMode: kLegacyRenderMode),
        returnsNormally,
      );
    });

    test('empty string does not trigger assertion', () {
      expect(() => const Text('').roll(renderMode: kLegacyRenderMode), returnsNormally);
    });
  });
}
