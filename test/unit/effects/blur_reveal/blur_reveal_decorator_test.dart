import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Internal import — test-only access to the decorator function.
import 'package:hyper_effects/src/effects/blur_reveal/blur_reveal_effect.dart';

void main() {
  const style = TextStyle(fontFamily: 'TestLatin', fontSize: 32);
  const effect = BlurRevealEffect(text: 'Hello', style: style);
  const total = 5; // 'Hello' — 5 clusters.

  group('computeBlurRevealClusterEffect math', () {
    test('at progress 0: all clusters invisible', () {
      for (int i = 0; i < total; i++) {
        final d = computeBlurRevealClusterEffect(
          effect: effect,
          visualIndex: i,
          totalClusters: total,
          progress: 0.0,
        );
        expect(d.opacity, 0.0, reason: 'cluster $i at p=0');
        expect(d.blurSigma, effect.blurSigma);
      }
    });

    test('at progress 1: all clusters fully visible, zero blur', () {
      for (int i = 0; i < total; i++) {
        final d = computeBlurRevealClusterEffect(
          effect: effect,
          visualIndex: i,
          totalClusters: total,
          progress: 1.0,
        );
        expect(d.opacity, closeTo(1.0, 1e-6),
            reason: 'cluster $i at p=1');
        expect(d.blurSigma, closeTo(0.0, 1e-6));
      }
    });

    test('first cluster starts revealing before later ones (stagger)', () {
      // At some low progress, the first cluster should have higher opacity
      // than the last cluster.
      final first = computeBlurRevealClusterEffect(
        effect: effect,
        visualIndex: 0,
        totalClusters: total,
        progress: 0.2,
      );
      final last = computeBlurRevealClusterEffect(
        effect: effect,
        visualIndex: total - 1,
        totalClusters: total,
        progress: 0.2,
      );
      expect(first.opacity, greaterThan(last.opacity),
          reason: 'early progress reveals first cluster ahead of last');
    });

    test('riseFrom: Offset.zero produces no transform', () {
      const noRise = BlurRevealEffect(
        text: 'Hi',
        style: style,
        riseFrom: Offset.zero,
      );
      final d = computeBlurRevealClusterEffect(
        effect: noRise,
        visualIndex: 0,
        totalClusters: 2,
        progress: 0.5,
      );
      expect(d.transform, isNull);
    });

    test('riseFrom != zero produces a transform at partial progress', () {
      // With new math (speedReveal=1.0, speedSegment=0.5, total=5):
      // cluster 0 window: start=0, end=0.5. At progress=0.25, eased is ~0.5
      // (mid-reveal), so transform is non-null.
      final d = computeBlurRevealClusterEffect(
        effect: effect,
        visualIndex: 0,
        totalClusters: total,
        progress: 0.25,
      );
      expect(d.transform, isNotNull);
    });

    test('riseFrom != zero produces null transform at full progress',
        () {
      // When a cluster is fully revealed (eased = 1.0), rise translate
      // becomes Offset(0, 0). Either null or identity Matrix4 is acceptable
      // — the implementation returns null for identity case.
      final d = computeBlurRevealClusterEffect(
        effect: effect,
        visualIndex: 0,
        totalClusters: total,
        progress: 1.0,
      );
      // At eased=1, transform could be null (no-op) or an identity matrix.
      // Our implementation returns null when translation would be zero.
      expect(d.transform, isNull);
    });
  });
}
