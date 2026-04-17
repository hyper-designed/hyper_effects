// Project-wide alchemist config.
// - CI goldens are the single source of truth (machine-independent rendering).
// - Platform goldens are disabled because they differ per OS/GPU and would
//   churn unnecessarily on dev machines.

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';

AlchemistConfig get projectAlchemistConfig => AlchemistConfig(
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        textTheme: const TextTheme().apply(
          bodyColor: const Color(0xFF111111),
          displayColor: const Color(0xFF111111),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      ),
      platformGoldensConfig: const PlatformGoldensConfig(enabled: false),
      ciGoldensConfig: const CiGoldensConfig(
        enabled: true,
        renderShadows: false,
        diffThreshold: 0.005,
      ),
    );

/// Wraps [run] in an alchemist config that renders real text in CI goldens
/// instead of obscuring paragraphs to black rectangles. Required for any
/// golden whose purpose is to capture glyph shapes (e.g., complex-script
/// baselines). Flakiness is controlled by pinning fonts (see
/// test/fonts/.cache/ + test_font_loader.dart).
T withTextRendering<T>(T Function() run) {
  final parent = AlchemistConfig.current();
  return AlchemistConfig.runWithConfig(
    config: parent.copyWith(
      ciGoldensConfig: parent.ciGoldensConfig.copyWith(
        obscureText: false,
        diffThreshold: 0.005,
      ),
    ),
    run: run,
  );
}
