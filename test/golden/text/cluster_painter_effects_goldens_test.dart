import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:hyper_effects/src/text/cluster_effect.dart';
import 'package:hyper_effects/src/text/cluster_painter.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../../helpers/alchemist_config.dart';

void main() => withTextRendering(() {
      goldenTest(
        'cluster_painter_effects',
        fileName: 'cluster_painter_effects_goldens',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 500),
          children: [
            GoldenTestScenario(
              name: 'identity (baseline)',
              child: _EffectsScene(effect: (_, __) => ClusterEffect.identity),
            ),
            GoldenTestScenario(
              name: 'per-cluster opacity ramp',
              child: _EffectsScene(
                effect: (i, total) =>
                    ClusterEffect(opacity: (i + 1) / total),
              ),
            ),
            GoldenTestScenario(
              name: 'per-cluster blur ramp',
              child: _EffectsScene(
                effect: (i, total) =>
                    ClusterEffect(blurSigma: (total - i - 1) * 2.0),
              ),
            ),
            GoldenTestScenario(
              name: 'per-cluster y-translate',
              child: _EffectsScene(
                effect: (i, total) => ClusterEffect(
                  transform: Matrix4.translationValues(0, i * 4.0, 0),
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'mixed — first half blurred, second half identity',
              child: _EffectsScene(
                effect: (i, total) => i < total ~/ 2
                    ? const ClusterEffect(blurSigma: 4)
                    : ClusterEffect.identity,
              ),
            ),
            GoldenTestScenario(
              name: 'mixed identity + invisible middle',
              child: _EffectsScene(
                effect: (i, total) => i == total ~/ 2
                    ? const ClusterEffect(visible: false)
                    : ClusterEffect.identity,
              ),
            ),
          ],
        ),
      );
    });

class _EffectsScene extends StatelessWidget {
  const _EffectsScene({required this.effect});
  final ClusterEffect Function(int visualIndex, int total) effect;

  @override
  Widget build(BuildContext context) {
    final shaped = ShapedText.build(
      text: 'Hello',
      style: const TextStyle(
        fontFamily: 'TestLatin',
        fontSize: 64,
        color: Color(0xFF111111),
      ),
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFFFFFFFF),
        padding: const EdgeInsets.all(16),
        child: CustomPaint(
          size: shaped.size,
          painter: _EffectsPainter(
            shaped: shaped,
            effect: effect,
          ),
        ),
      ),
    );
  }
}

class _EffectsPainter extends CustomPainter {
  _EffectsPainter({required this.shaped, required this.effect});
  final ShapedText shaped;
  final ClusterEffect Function(int visualIndex, int total) effect;

  @override
  void paint(Canvas canvas, Size size) {
    ClusterPainter.paintWithClusters(
      canvas,
      shaped,
      Offset.zero,
      (c) => effect(c.visualIndex, shaped.clusters.length),
    );
  }

  @override
  bool shouldRepaint(_EffectsPainter old) => old.shaped != shaped;
}
