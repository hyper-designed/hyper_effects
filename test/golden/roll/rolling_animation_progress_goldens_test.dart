import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../helpers/alchemist_config.dart';
import '../../helpers/test_app.dart';

void main() => withTextRendering(() {
  goldenTest(
    'rolling_animation_progress_baseline',
    fileName: 'rolling_animation_progress_goldens',
    builder: () => GoldenTestGroup(
      scenarioConstraints: const BoxConstraints(maxWidth: 400),
      children: [
        for (final p in const [0.0, 0.25, 0.5, 0.75, 1.0])
          GoldenTestScenario(
            name: 'progress ${p.toStringAsFixed(2)}',
            child: _Scene(progress: p),
          ),
      ],
    ),
  );
});

class _Scene extends StatelessWidget {
  const _Scene({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    // Alchemist captures settled final states. To approximate progress
    // snapshots we use distinct (oldText→newText) pairs with instant
    // animations; this captures visual variety along a counter's path.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'TestLatin',
          fontSize: 48,
          color: Color(0xFF111111),
        ),
        child: Container(
          color: const Color(0xFFFFFFFF),
          padding: const EdgeInsets.all(16),
          child: Text('abc${(progress * 100).toInt()}')
              .roll(renderMode: kLegacyRenderMode)
              .animate(
                trigger: progress,
                duration: const Duration(milliseconds: 400),
              ),
        ),
      ),
    );
  }
}
