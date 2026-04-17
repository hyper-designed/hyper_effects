// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(() {
    HyperEffects.defaultTextRenderMode = null;
  });

  group('HyperEffects global defaults', () {
    test('defaultTextRenderMode starts null', () {
      expect(HyperEffects.defaultTextRenderMode, isNull);
    });

    test('can set and read defaultTextRenderMode', () {
      HyperEffects.defaultTextRenderMode =
          TextRenderMode.contextualCharacters;
      expect(HyperEffects.defaultTextRenderMode,
          TextRenderMode.contextualCharacters);
    });
  });

  group('HyperEffectsScope', () {
    testWidgets('maybeOf returns null when no ancestor', (tester) async {
      HyperEffectsScope? found;
      await tester.pumpWidget(
        wrapInTestApp(
          Builder(builder: (context) {
            found = HyperEffectsScope.maybeOf(context);
            return const SizedBox();
          }),
        ),
      );
      expect(found, isNull);
    });

    testWidgets('maybeOf returns nearest scope when present',
        (tester) async {
      HyperEffectsScope? found;
      await tester.pumpWidget(
        wrapInTestApp(
          HyperEffectsScope(
            renderMode: TextRenderMode.contextualCharacters,
            child: Builder(builder: (context) {
              found = HyperEffectsScope.maybeOf(context);
              return const SizedBox();
            }),
          ),
        ),
      );
      expect(found, isNotNull);
      expect(found!.renderMode, TextRenderMode.contextualCharacters);
    });
  });

  group('resolveTextRenderMode resolution order', () {
    testWidgets('1. explicit override wins', (tester) async {
      HyperEffects.defaultTextRenderMode =
          TextRenderMode.contextualCharacters;
      TextRenderMode? resolved;
      await tester.pumpWidget(
        wrapInTestApp(
          HyperEffectsScope(
            renderMode: TextRenderMode.contextualCharacters,
            child: Builder(builder: (context) {
              resolved = resolveTextRenderMode(
                context,
                override: TextRenderMode.independentCharacters,
              );
              return const SizedBox();
            }),
          ),
        ),
      );
      expect(resolved, TextRenderMode.independentCharacters);
    });

    testWidgets('2. scope wins over global', (tester) async {
      HyperEffects.defaultTextRenderMode =
          TextRenderMode.independentCharacters;
      TextRenderMode? resolved;
      await tester.pumpWidget(
        wrapInTestApp(
          HyperEffectsScope(
            renderMode: TextRenderMode.contextualCharacters,
            child: Builder(builder: (context) {
              resolved = resolveTextRenderMode(context);
              return const SizedBox();
            }),
          ),
        ),
      );
      expect(resolved, TextRenderMode.contextualCharacters);
    });

    testWidgets('3. global wins when no scope / override', (tester) async {
      HyperEffects.defaultTextRenderMode =
          TextRenderMode.contextualCharacters;
      TextRenderMode? resolved;
      await tester.pumpWidget(
        wrapInTestApp(
          Builder(builder: (context) {
            resolved = resolveTextRenderMode(context);
            return const SizedBox();
          }),
        ),
      );
      expect(resolved, TextRenderMode.contextualCharacters);
    });

    testWidgets('4. fallback is contextualCharacters (v0.4.0 default flip)',
        (tester) async {
      TextRenderMode? resolved;
      await tester.pumpWidget(
        wrapInTestApp(
          Builder(builder: (context) {
            resolved = resolveTextRenderMode(context);
            return const SizedBox();
          }),
        ),
      );
      expect(resolved, TextRenderMode.contextualCharacters);
    });
  });
}
