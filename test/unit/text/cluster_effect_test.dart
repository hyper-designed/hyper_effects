import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/text/cluster_effect.dart';

void main() {
  group('ClusterEffect', () {
    test('identity() is the no-op default', () {
      const effect = ClusterEffect.identity;
      expect(effect.isIdentity, isTrue);
      expect(effect.opacity, 1.0);
      expect(effect.blurSigma, 0.0);
      expect(effect.transform, isNull);
      expect(effect.colorFilter, isNull);
      expect(effect.visible, isTrue);
    });

    test('non-identity when opacity < 1', () {
      const effect = ClusterEffect(opacity: 0.5);
      expect(effect.isIdentity, isFalse);
    });

    test('non-identity when blurSigma > 0', () {
      const effect = ClusterEffect(blurSigma: 5);
      expect(effect.isIdentity, isFalse);
    });

    test('non-identity when transform is not null', () {
      final effect = ClusterEffect(transform: Matrix4.identity());
      expect(effect.isIdentity, isFalse,
          reason: 'any transform object, even identity matrix, '
              'counts as non-identity because the paint path differs');
    });

    test('non-identity when visible = false', () {
      const effect = ClusterEffect(visible: false);
      expect(effect.isIdentity, isFalse);
    });

    test('equality is structural', () {
      const a = ClusterEffect(opacity: 0.5, blurSigma: 2);
      const b = ClusterEffect(opacity: 0.5, blurSigma: 2);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
