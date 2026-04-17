import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// The legacy render mode, pinned for Phase 1 tests that document the
/// pre-v0.4 rendering path. Referenced throughout `test/widget/roll/`,
/// `test/golden/roll/`, and `test/integration/package_smoke_test.dart`.
/// Removed in Phase 6 (v0.5.0) alongside the enum variant itself.
// ignore: deprecated_member_use
const TextRenderMode kLegacyRenderMode = TextRenderMode.independentCharacters;

Widget wrapInTestApp(
  Widget child, {
  TextDirection textDirection = TextDirection.ltr,
  TextStyle? defaultStyle,
  ThemeData? theme,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme ?? ThemeData(useMaterial3: true),
    home: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.noScaling),
        child: DefaultTextStyle(
          style: defaultStyle ??
              const TextStyle(
                fontFamily: 'TestLatin',
                fontSize: 32,
                color: Color(0xFF111111),
              ),
          child: Scaffold(
            backgroundColor: const Color(0xFFFFFFFF),
            body: Center(child: child),
          ),
        ),
      ),
    ),
  );
}
