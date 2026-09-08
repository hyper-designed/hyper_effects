import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:material_ui/material_ui.dart';

class _UnclampedEffect extends Effect {
  const _UnclampedEffect(this.value);

  final double value;

  static double largestInterpolationValue = double.negativeInfinity;

  static void resetObservations() {
    largestInterpolationValue = double.negativeInfinity;
  }

  @override
  _UnclampedEffect lerp(
    covariant _UnclampedEffect other,
    double interpolationValue,
  ) {
    if (interpolationValue > largestInterpolationValue) {
      largestInterpolationValue = interpolationValue;
    }
    return _UnclampedEffect(
      value + (other.value - value) * interpolationValue,
    );
  }

  @override
  Widget apply(BuildContext context, Widget? child) =>
      child ?? const SizedBox.shrink();
}

class _DebugPrintCapture {
  static Future<List<String>> run(
      Future<void> Function(List<String>) body) async {
    final DebugPrintCallback originalDebugPrint = debugPrint;
    final List<String> messages = <String>[];
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) messages.add(message);
    };
    try {
      await body(messages);
      return messages;
    } finally {
      debugPrint = originalDebugPrint;
    }
  }
}

/// Covers the debug-only diagnostic in `effect_widget.dart` that fires when
/// a [SpringMotion] drives an effect that doesn't mix in [VectorEffect] and
/// has therefore silently fallen back to a normalized lerp instead of real
/// spring physics. See `_EffectWidgetState._warnSpringDowngrade` for the
/// full rationale.
///
/// [BlurEffect] is the ordinary non-vector fixture. The first test instead
/// uses [_UnclampedEffect], whose `lerp` records and extrapolates its input, to
/// prove that the fallback MAY preserve scalar overshoot. What it cannot
/// preserve is closed-form vector spring state or velocity handoff.
/// [TranslateEffect] (via `.translateX`) is the vector control.
///
/// The diagnostic uses [debugPrint] instead of [FlutterError.reportError] so
/// developer guidance never enters application crash-reporting pipelines and
/// never becomes a framework exception. Each test captures the global callback
/// inside a `try`/`finally` scope and restores it before Flutter verifies its
/// test invariants.
void main() {
  setUp(() {
    EffectWidget.resetSpringDowngradeWarningsForTesting();
    _UnclampedEffect.resetObservations();
  });
  tearDown(EffectWidget.resetSpringDowngradeWarningsForTesting);

  Widget unclampedNonVectorHost(bool trigger) => MaterialApp(
        home: Center(
          child: const EffectWidget(
            start: _UnclampedEffect(0),
            end: _UnclampedEffect(1),
            child: SizedBox.square(dimension: 50),
          ).animate(
            trigger: trigger,
            motion: const CupertinoMotion.bouncy(),
          ),
        ),
      );

  Widget nonVectorHost(bool trigger) => MaterialApp(
        home: Center(
          child: const SizedBox.square(dimension: 50)
              .blur(trigger ? 10 : 0)
              .animate(
                trigger: trigger,
                motion: const CupertinoMotion.bouncy(),
              ),
        ),
      );

  Widget vectorHost(bool trigger) => MaterialApp(
        home: Center(
          child: const SizedBox.square(dimension: 50)
              .translateX(trigger ? 120 : -120)
              .animate(
                trigger: trigger,
                motion: const CupertinoMotion.bouncy(),
              ),
        ),
      );

  Widget nonVectorCurvedHost(bool trigger) => MaterialApp(
        home: Center(
          child: const SizedBox.square(dimension: 50)
              .blur(trigger ? 10 : 0)
              .animate(
                trigger: trigger,
                motion: const CurvedMotion(Duration(milliseconds: 200)),
              ),
        ),
      );

  testWidgets(
      'an unclamped non-VectorEffect warns while preserving scalar overshoot',
      (tester) async {
    final List<String> printedMessages = await _DebugPrintCapture.run(
      (printedMessages) async {
        await tester.pumpWidget(unclampedNonVectorHost(false));
        await tester.pump();

        await tester.pumpWidget(unclampedNonVectorHost(true));
        for (var i = 0; i < 80; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      },
    );

    expect(printedMessages, hasLength(1));
    final String message = printedMessages.single;
    expect(message, contains('_UnclampedEffect'));
    expect(message, contains('VectorEffect'));
    expect(message, contains('may still exceed 1'));
    expect(message, contains('clamping lerp flattens'));
    expect(message, contains('always lose velocity handoff'));
    expect(message, contains('CurvedMotion'));
    expect(_UnclampedEffect.largestInterpolationValue, greaterThan(1));
  });

  testWidgets(
      'the warning fires once total, not once per frame, across many pumps',
      (tester) async {
    final List<String> printedMessages = await _DebugPrintCapture.run(
      (printedMessages) async {
        await tester.pumpWidget(nonVectorHost(false));
        await tester.pump();

        await tester.pumpWidget(nonVectorHost(true));
        await tester.pump();

        // The first frame discovers the downgrade exactly once.
        expect(printedMessages, hasLength(1));

        // Later frames re-evaluate the pair without printing again.
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      },
    );

    expect(printedMessages, hasLength(1));
  });

  testWidgets(
      'a VectorEffect (TranslateEffect via translateX) driven by a '
      'SpringMotion emits no warning', (tester) async {
    final List<String> printedMessages = await _DebugPrintCapture.run(
      (_) async {
        await tester.pumpWidget(vectorHost(false));
        await tester.pump();

        await tester.pumpWidget(vectorHost(true));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      },
    );

    expect(printedMessages, isEmpty);
  });

  testWidgets(
      'a non-VectorEffect driven by a CurvedMotion (not a spring) emits no '
      'warning', (tester) async {
    final List<String> printedMessages = await _DebugPrintCapture.run(
      (_) async {
        await tester.pumpWidget(nonVectorCurvedHost(false));
        await tester.pump();

        await tester.pumpWidget(nonVectorCurvedHost(true));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      },
    );

    expect(printedMessages, isEmpty);
  });
}
