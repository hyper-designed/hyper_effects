import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../helpers/alchemist_config.dart';
import '../../helpers/test_app.dart';

void main() => withTextRendering(() {
  goldenTest(
    'rolling_tape_strategies_baseline',
    fileName: 'rolling_tape_strategies_goldens',
    builder: () => GoldenTestGroup(
      scenarioConstraints: const BoxConstraints(maxWidth: 400),
      children: [
        GoldenTestScenario(
          name: 'ConsistentSymbolTapeStrategy distance 0 (default)',
          child: const _Scene(strategy: ConsistentSymbolTapeStrategy(0)),
        ),
        GoldenTestScenario(
          name: 'ConsistentSymbolTapeStrategy distance 4',
          child: const _Scene(strategy: ConsistentSymbolTapeStrategy(4)),
        ),
        GoldenTestScenario(
          name: 'AllSymbolsTapeStrategy',
          child: const _Scene(strategy: AllSymbolsTapeStrategy()),
        ),
        GoldenTestScenario(
          name: 'AllSymbolsTapeStrategy no-repeat',
          child: const _Scene(
            strategy: AllSymbolsTapeStrategy(repeatCharacters: false),
          ),
        ),
      ],
    ),
  );
});

class _Scene extends StatelessWidget {
  const _Scene({required this.strategy});
  final SymbolTapeStrategy strategy;

  @override
  Widget build(BuildContext context) {
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
          child: const Text('xyz')
              .roll(
                renderMode: kLegacyRenderMode,
                tapeStrategy: strategy,
              )
              .animate(
                trigger: 1,
                duration: const Duration(milliseconds: 400),
              ),
        ),
      ),
    );
  }
}
