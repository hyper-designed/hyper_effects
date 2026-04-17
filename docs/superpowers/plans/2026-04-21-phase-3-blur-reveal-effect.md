# Phase 3 — BlurRevealEffect Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship `BlurRevealEffect` — the first user-facing effect built on the Phase 2 `ShapedText` primitive. Reveals text per grapheme cluster with staggered blur + opacity + optional rise-from translate. Correctly handles Arabic, Devanagari, ZWJ emoji, and RTL by virtue of the primitive.

**Architecture:** `BlurRevealEffect` extends `Effect` like every other effect in the package. Its `.apply(context, child)` returns an internal `_BlurRevealWidget` that reads animation progress from `EffectQuery`, sizes itself via `LayoutBuilder` + `ShapedText.build`, and paints via a `CustomPainter` that calls `ClusterPainter.paintWithClusters` with a per-cluster decorator computing `(opacity, blurSigma, transform)` from the progress and cluster's `visualIndex`. The painter re-calls `ShapedText.build` each frame (cache makes this cheap) to avoid retaining paragraph references across frames — the Phase 2 deferred lifetime concern.

**Tech stack:** Phase 2 primitives (`ShapedText`, `ShapedCluster`, `ClusterEffect`, `ClusterPainter`), existing `Effect` / `EffectWidget` / `EffectQuery` / `AnimatedEffect` infrastructure, `alchemist` for goldens, example app storyboard.

---

## Scope

Phase 3 only. Corresponds to "Rollout → Phase 3" of `docs/superpowers/specs/2026-04-17-shaped-text-rendering-design.md`. Target version: v0.3.3.

**What's in Phase 3:**

- `BlurRevealEffect` class (exported from `hyper_effects.dart` via `effects.dart`).
- `.blurReveal()` extension on `Text`.
- Internal `_BlurRevealWidget` + `_BlurRevealPainter`.
- Unit + widget tests.
- Goldens across progress values + scripts (Latin, Arabic, multiline).
- Storyboard entry in the example app.
- CHANGELOG bump.

**What's NOT in Phase 3:**

- No `TextRenderMode` flag (Phase 4).
- No `HyperEffectsScope` (Phase 4).
- No changes to `RollingTextEffect` or its render path (Phase 4).
- No `inView` parameter on `BlurReveal` — user confirmed trigger-based API with scroll-effect composition instead.
- No prewarm helper yet (cache populates on build).
- No fixes for the four known source bugs in `docs/known-bugs.md`.

## Conventions

- **TDD cycle per task**: write failing test → run, confirm failure → implement → run, confirm pass → commit.
- **Commit messages**: `:sparkles:` for new features, `:white_check_mark:` for tests, `:camera_flash:` for goldens, `:memo:` for docs, `:wrench:` for fixups.
- **Use `git add <path>`** with specific paths (never `-A`) to avoid sweeping the pre-existing uncommitted change to `example/macos/Flutter/GeneratedPluginRegistrant.swift`.
- **Golden tests** use `withTextRendering` + `CI=true` prefix for alchemist.
- **No retaining `ShapedText` across frames** — always call `ShapedText.build(...)` from `paint()` or `build()` each time.

## File Structure

### Created

```
lib/src/effects/blur_reveal/
  blur_reveal_effect.dart          # BlurRevealEffect (public), _BlurRevealWidget, _BlurRevealPainter (private)
  blur_reveal_extensions.dart      # Text.blurReveal() extension; exports blur_reveal_effect.dart
test/unit/effects/blur_reveal/
  blur_reveal_effect_test.dart     # class-level tests (equality, lerp, decorator math)
test/widget/effects/blur_reveal/
  blur_reveal_widget_test.dart     # widget-tier tests (tree shape, progress plumbing)
test/golden/effects/blur_reveal/
  blur_reveal_goldens_test.dart    # goldens (progress snapshots, Arabic, multiline)
example/lib/stories/
  blur_reveal_animation.dart       # storyboard entry
```

### Modified

- `lib/src/effects/effects.dart` — add `export 'blur_reveal/blur_reveal_extensions.dart';`.
- `example/lib/main.dart` — register the new story.
- `CHANGELOG.md` — Unreleased section.

### Not touched

- All Phase 1 + Phase 2 code.
- `RollingTextEffect` and its rendering path.
- Other existing effects.

---

## Task 1: `BlurRevealEffect` class — fields, equality, lerp

Create the immutable effect class with the API surface from the design spec. Include every parameter `ShapedText.build` accepts so the effect can pass them through. `lerp` snaps to `other` (the effect doesn't interpolate itself — its internal widget reads progress from `EffectQuery` and computes per-cluster values during paint).

**Files:**
- Create: `lib/src/effects/blur_reveal/blur_reveal_effect.dart`
- Create: `test/unit/effects/blur_reveal/blur_reveal_effect_test.dart`

- [ ] **Step 1.1: Write failing tests**

Create `test/unit/effects/blur_reveal/blur_reveal_effect_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  const style = TextStyle(fontFamily: 'TestLatin', fontSize: 32);

  group('BlurRevealEffect', () {
    test('has sensible defaults from the design spec', () {
      const effect = BlurRevealEffect(text: 'hello', style: style);
      expect(effect.text, 'hello');
      expect(effect.style, style);
      expect(effect.delay, Duration.zero);
      expect(effect.speedReveal, 1.5);
      expect(effect.speedSegment, 0.5);
      expect(effect.blurSigma, 10.0);
      expect(effect.riseFrom, const Offset(0, 12));
      expect(effect.curve, Curves.easeOutCubic);
      expect(effect.textDirection, isNull);
      expect(effect.textAlign, isNull);
      expect(effect.textScaler, isNull);
      expect(effect.strutStyle, isNull);
      expect(effect.textHeightBehavior, isNull);
      expect(effect.locale, isNull);
      expect(effect.maxWidth, isNull);
    });

    test('equality is structural via EquatableMixin', () {
      const a = BlurRevealEffect(text: 'hi', style: style, speedReveal: 2.0);
      const b = BlurRevealEffect(text: 'hi', style: style, speedReveal: 2.0);
      const c = BlurRevealEffect(text: 'hi', style: style, speedReveal: 3.0);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('lerp snaps to `other` at any value (decorator runs in paint)', () {
      const a = BlurRevealEffect(text: 'old', style: style);
      const b = BlurRevealEffect(text: 'new', style: style);
      for (final v in const [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final result = a.lerp(b, v);
        expect(result, isA<BlurRevealEffect>());
        expect((result as BlurRevealEffect).text, 'new',
            reason: 'at v=$v, lerp should snap to other');
      }
    });

    test('riseFrom can be set to Offset.zero to disable rise', () {
      const effect = BlurRevealEffect(
        text: 'hi',
        style: style,
        riseFrom: Offset.zero,
      );
      expect(effect.riseFrom, Offset.zero);
    });
  });
}
```

- [ ] **Step 1.2: Run, expect compile failure**

Run: `flutter test test/unit/effects/blur_reveal/blur_reveal_effect_test.dart --reporter expanded`
Expected: compile error — class doesn't exist.

- [ ] **Step 1.3: Implement the class**

Create `lib/src/effects/blur_reveal/blur_reveal_effect.dart`:

```dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../effect.dart';

/// An effect that reveals a [Text] one grapheme cluster at a time with a
/// staggered blur → opacity → (optional) rise-from transform.
///
/// The effect is ligature-safe and RTL-aware by construction (it uses the
/// shaped-text primitive under the hood), so Arabic `لا` reveals as a single
/// cluster and Hebrew reveals right-to-left.
///
/// Invoke via the [Text.blurReveal] extension:
///
/// ```dart
/// Text('Hello').blurReveal().animate(trigger: revealed);
/// ```
class BlurRevealEffect extends Effect {
  /// The text to reveal. Required; normally populated by the `.blurReveal()`
  /// extension from `Text.data`.
  final String text;

  /// The resolved text style. Required; the extension derives this from the
  /// enclosing `DefaultTextStyle` merged with the `Text`'s own style.
  final TextStyle style;

  // --- ShapedText passthrough parameters ---

  /// Text direction override. Defaults to ambient `Directionality` when null.
  final TextDirection? textDirection;

  /// Text alignment. Pass-through to `ShapedText.build`.
  final TextAlign? textAlign;

  /// Text scaler. Defaults to `TextScaler.noScaling` when null.
  final TextScaler? textScaler;

  /// Strut style. Pass-through.
  final StrutStyle? strutStyle;

  /// Text height behavior. Pass-through.
  final ui.TextHeightBehavior? textHeightBehavior;

  /// Locale hint for shaping. Pass-through.
  final Locale? locale;

  /// Max layout width. When null, the enclosing constraints are used.
  final double? maxWidth;

  // --- BlurReveal-specific parameters ---

  /// Delay before the reveal starts. Applied by composing with
  /// `.animate(delay: ...)`. Retained on the effect for future use.
  final Duration delay;

  /// Overall reveal speed multiplier. Higher values reveal faster. Mirrors
  /// the TypeScript `speedReveal` parameter of the source design. Default 1.5.
  final double speedReveal;

  /// Per-cluster reveal duration as a fraction of the total timeline.
  /// Higher values give each cluster a longer reveal window (more overlap
  /// between neighbors). Default 0.5.
  final double speedSegment;

  /// Starting blur sigma. Fades to 0 as each cluster completes. Default 10.
  final double blurSigma;

  /// Translate offset each cluster rises FROM. `Offset.zero` disables the
  /// rise effect entirely. Default `Offset(0, 12)` (rise from 12px below).
  final Offset riseFrom;

  /// Per-cluster easing curve. Default `Curves.easeOutCubic`.
  final Curve curve;

  /// Creates a [BlurRevealEffect].
  const BlurRevealEffect({
    required this.text,
    required this.style,
    this.textDirection,
    this.textAlign,
    this.textScaler,
    this.strutStyle,
    this.textHeightBehavior,
    this.locale,
    this.maxWidth,
    this.delay = Duration.zero,
    this.speedReveal = 1.5,
    this.speedSegment = 0.5,
    this.blurSigma = 10.0,
    this.riseFrom = const Offset(0, 12),
    this.curve = Curves.easeOutCubic,
  });

  @override
  BlurRevealEffect lerp(covariant BlurRevealEffect other, double value) =>
      other;

  @override
  Widget apply(BuildContext context, Widget? child) =>
      _BlurRevealWidget(effect: this);

  @override
  List<Object?> get props => [
        text,
        style,
        textDirection,
        textAlign,
        textScaler,
        strutStyle,
        textHeightBehavior,
        locale,
        maxWidth,
        delay,
        speedReveal,
        speedSegment,
        blurSigma,
        riseFrom,
        curve,
      ];
}

// Placeholder for Task 2. Keeps this file compiling until the widget lands.
class _BlurRevealWidget extends StatelessWidget {
  const _BlurRevealWidget({required this.effect});

  final BlurRevealEffect effect;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

- [ ] **Step 1.4: Run, expect pass**

Run: `flutter test test/unit/effects/blur_reveal/blur_reveal_effect_test.dart --reporter expanded`
Expected: 4 tests pass.

- [ ] **Step 1.5: Commit**

```bash
git add lib/src/effects/blur_reveal/blur_reveal_effect.dart \
        test/unit/effects/blur_reveal/blur_reveal_effect_test.dart
git commit -m ":sparkles: Add BlurRevealEffect class (no widget yet)"
```

---

## Task 2: `_BlurRevealPainter` + decorator math

Wire the CustomPainter that reads animation progress and applies per-cluster blur/opacity/transform via `ClusterPainter.paintWithClusters`. The decorator function implements the spec's math: stagger each cluster by `visualIndex`, compute a local 0..1 sub-progress, ease it, then map to `(opacity, blurSigma, translate)`.

**Files:**
- Modify: `lib/src/effects/blur_reveal/blur_reveal_effect.dart`
- Create: `test/unit/effects/blur_reveal/blur_reveal_decorator_test.dart`

- [ ] **Step 2.1: Write failing decorator tests**

Create `test/unit/effects/blur_reveal/blur_reveal_decorator_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Internal import — test-only access to the decorator function.
import 'package:hyper_effects/src/effects/blur_reveal/blur_reveal_effect.dart';

void main() {
  const style = TextStyle(fontFamily: 'TestLatin', fontSize: 32);
  const effect = BlurRevealEffect(text: 'Hello', style: style);
  const total = 5; // 'Hello' — 5 clusters.

  group('blurRevealDecorator math', () {
    test('at progress 0: all clusters invisible', () {
      for (int i = 0; i < total; i++) {
        final d = debugBlurRevealDecorator(
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
        final d = debugBlurRevealDecorator(
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
      final first = debugBlurRevealDecorator(
        effect: effect,
        visualIndex: 0,
        totalClusters: total,
        progress: 0.2,
      );
      final last = debugBlurRevealDecorator(
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
      final d = debugBlurRevealDecorator(
        effect: noRise,
        visualIndex: 0,
        totalClusters: 2,
        progress: 0.5,
      );
      expect(d.transform, isNull);
    });

    test('riseFrom != zero produces a transform at partial progress', () {
      final d = debugBlurRevealDecorator(
        effect: effect,
        visualIndex: 0,
        totalClusters: total,
        progress: 0.1,
      );
      expect(d.transform, isNotNull);
    });

    test('riseFrom != zero produces null transform at full progress',
        () {
      // When a cluster is fully revealed (eased = 1.0), rise translate
      // becomes Offset(0, 0). Either null or identity Matrix4 is acceptable
      // — the implementation returns null for identity case.
      final d = debugBlurRevealDecorator(
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
```

The test imports the internal helper `debugBlurRevealDecorator` that we'll add as a `@visibleForTesting` export from the effect file. This keeps the decorator testable without exposing it to public API.

- [ ] **Step 2.2: Run, expect compile failure**

Run: `flutter test test/unit/effects/blur_reveal/blur_reveal_decorator_test.dart --reporter expanded`
Expected: compile error — `debugBlurRevealDecorator` not found.

- [ ] **Step 2.3: Implement decorator + widget + painter**

Replace `lib/src/effects/blur_reveal/blur_reveal_effect.dart` with:

```dart
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../effect_query.dart';
import '../../text/cluster_effect.dart';
import '../../text/cluster_painter.dart';
import '../../text/shaped_cluster.dart';
import '../../text/shaped_text.dart';
import '../effect.dart';

/// An effect that reveals a [Text] one grapheme cluster at a time with a
/// staggered blur → opacity → (optional) rise-from transform.
///
/// Ligature-safe and RTL-aware by construction. Invoke via the
/// `Text.blurReveal()` extension:
///
/// ```dart
/// Text('Hello').blurReveal().animate(trigger: revealed);
/// ```
class BlurRevealEffect extends Effect {
  /// The text to reveal.
  final String text;

  /// The resolved text style.
  final TextStyle style;

  /// Text direction override. Defaults to ambient `Directionality` when null.
  final TextDirection? textDirection;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Text scaler.
  final TextScaler? textScaler;

  /// Strut style.
  final StrutStyle? strutStyle;

  /// Text height behavior.
  final ui.TextHeightBehavior? textHeightBehavior;

  /// Locale hint for shaping.
  final Locale? locale;

  /// Max layout width. When null, the enclosing constraints are used.
  final double? maxWidth;

  /// Delay before the reveal starts.
  final Duration delay;

  /// Overall reveal speed multiplier. Higher = faster. Default 1.5.
  final double speedReveal;

  /// Per-cluster reveal duration as a fraction of the total timeline.
  /// Default 0.5.
  final double speedSegment;

  /// Starting blur sigma. Default 10.
  final double blurSigma;

  /// Translate offset each cluster rises FROM. `Offset.zero` disables rise.
  /// Default `Offset(0, 12)`.
  final Offset riseFrom;

  /// Per-cluster easing curve. Default `Curves.easeOutCubic`.
  final Curve curve;

  /// Creates a [BlurRevealEffect].
  const BlurRevealEffect({
    required this.text,
    required this.style,
    this.textDirection,
    this.textAlign,
    this.textScaler,
    this.strutStyle,
    this.textHeightBehavior,
    this.locale,
    this.maxWidth,
    this.delay = Duration.zero,
    this.speedReveal = 1.5,
    this.speedSegment = 0.5,
    this.blurSigma = 10.0,
    this.riseFrom = const Offset(0, 12),
    this.curve = Curves.easeOutCubic,
  });

  @override
  BlurRevealEffect lerp(covariant BlurRevealEffect other, double value) =>
      other;

  @override
  Widget apply(BuildContext context, Widget? child) =>
      _BlurRevealWidget(effect: this);

  @override
  List<Object?> get props => [
        text,
        style,
        textDirection,
        textAlign,
        textScaler,
        strutStyle,
        textHeightBehavior,
        locale,
        maxWidth,
        delay,
        speedReveal,
        speedSegment,
        blurSigma,
        riseFrom,
        curve,
      ];
}

/// Computes the per-cluster [ClusterEffect] for a [BlurRevealEffect] at the
/// given animation [progress] (0..1). Exposed for unit-testing.
@visibleForTesting
ClusterEffect debugBlurRevealDecorator({
  required BlurRevealEffect effect,
  required int visualIndex,
  required int totalClusters,
  required double progress,
}) =>
    _computeClusterEffect(
      effect: effect,
      visualIndex: visualIndex,
      totalClusters: totalClusters,
      progress: progress,
    );

ClusterEffect _computeClusterEffect({
  required BlurRevealEffect effect,
  required int visualIndex,
  required int totalClusters,
  required double progress,
}) {
  if (totalClusters <= 0) return ClusterEffect.identity;
  // Each cluster occupies a slice of the timeline; slices are offset by
  // visualIndex so earlier clusters start revealing before later ones.
  final slice = 1.0 / (totalClusters + effect.speedSegment * totalClusters);
  final start = visualIndex * slice * (1.0 / effect.speedReveal);
  final end = start + slice * effect.speedSegment;
  final denom = end - start;
  final local = denom <= 0
      ? (progress >= start ? 1.0 : 0.0)
      : ((progress - start) / denom).clamp(0.0, 1.0);
  final eased = effect.curve.transform(local);

  final rise = (effect.riseFrom == Offset.zero || eased >= 1.0)
      ? null
      : Matrix4.translationValues(
          effect.riseFrom.dx * (1.0 - eased),
          effect.riseFrom.dy * (1.0 - eased),
          0,
        );

  return ClusterEffect(
    opacity: eased,
    blurSigma: effect.blurSigma * (1.0 - eased),
    transform: rise,
  );
}

class _BlurRevealWidget extends StatelessWidget {
  const _BlurRevealWidget({required this.effect});

  final BlurRevealEffect effect;

  @override
  Widget build(BuildContext context) {
    final query = EffectQuery.maybeOf(context);
    final progress = query?.curvedValue ?? 1.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sizing pass: returns the cached ShapedText.
        final shaped = ShapedText.build(
          text: effect.text,
          style: effect.style,
          textDirection: effect.textDirection,
          textAlign: effect.textAlign,
          textScaler: effect.textScaler,
          strutStyle: effect.strutStyle,
          textHeightBehavior: effect.textHeightBehavior,
          locale: effect.locale,
          maxWidth: effect.maxWidth ?? constraints.maxWidth,
        );
        return RepaintBoundary(
          child: CustomPaint(
            size: shaped.size,
            painter: _BlurRevealPainter(effect: effect, progress: progress),
          ),
        );
      },
    );
  }
}

class _BlurRevealPainter extends CustomPainter {
  _BlurRevealPainter({required this.effect, required this.progress});

  final BlurRevealEffect effect;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Re-resolve the ShapedText each frame — the cache returns the same
    // instance for identical args, so this is cheap. Holding a ShapedText
    // reference across frames is unsafe (paragraphs may be disposed on
    // cache eviction).
    final shaped = ShapedText.build(
      text: effect.text,
      style: effect.style,
      textDirection: effect.textDirection,
      textAlign: effect.textAlign,
      textScaler: effect.textScaler,
      strutStyle: effect.strutStyle,
      textHeightBehavior: effect.textHeightBehavior,
      locale: effect.locale,
      maxWidth: effect.maxWidth ?? size.width,
    );
    final total = shaped.clusters.length;
    ClusterPainter.paintWithClusters(
      canvas,
      shaped,
      Offset.zero,
      (ShapedCluster c) => _computeClusterEffect(
        effect: effect,
        visualIndex: c.visualIndex,
        totalClusters: total,
        progress: progress,
      ),
    );
  }

  @override
  bool shouldRepaint(_BlurRevealPainter old) =>
      old.effect != effect || old.progress != progress;
}
```

- [ ] **Step 2.4: Run decorator tests, expect pass**

Run: `flutter test test/unit/effects/blur_reveal/blur_reveal_decorator_test.dart --reporter expanded`
Expected: 6 tests pass.

If any test fails, inspect the actual computed values with a temporary `print(d)` and adjust either the math or the test expectation with a comment explaining the observed behavior. Do NOT change source code to make the test pass in a way that breaks the visual intent — the stagger-reveal shape is the whole point.

- [ ] **Step 2.5: Commit**

```bash
git add lib/src/effects/blur_reveal/blur_reveal_effect.dart \
        test/unit/effects/blur_reveal/blur_reveal_decorator_test.dart
git commit -m ":sparkles: BlurReveal decorator math + internal widget/painter"
```

---

## Task 3: `.blurReveal()` extension on `Text`

Extract the effective `TextStyle` from the enclosing `DefaultTextStyle` (merged with the `Text`'s own style), then wrap in an `EffectWidget` whose `end` is a `BlurRevealEffect`. Mirrors the pattern in `lib/src/effects/roll/text_extensions.dart`.

**Files:**
- Create: `lib/src/effects/blur_reveal/blur_reveal_extensions.dart`

- [ ] **Step 3.1: Write the extension**

Create `lib/src/effects/blur_reveal/blur_reveal_extensions.dart`:

```dart
import 'package:flutter/material.dart';

import '../../effect_widget.dart';
import 'blur_reveal_effect.dart';

export 'blur_reveal_effect.dart';

/// Adds a [Text.blurReveal] extension that applies a [BlurRevealEffect].
extension BlurRevealTextExt on Text {
  /// Reveals this text one grapheme cluster at a time with a staggered
  /// blur + opacity + (optional) rise-from translate.
  ///
  /// Compose with [Widget.animate] to drive the reveal:
  ///
  /// ```dart
  /// Text('Hello, World!').blurReveal().animate(trigger: visible);
  /// ```
  ///
  /// The effect is ligature-safe and RTL-aware — Arabic renders with correct
  /// cursive connection, Hebrew reveals right-to-left.
  ///
  /// [speedReveal] is the overall reveal-speed multiplier (default 1.5).
  /// [speedSegment] is the per-cluster reveal window as a fraction of the
  /// total timeline (default 0.5). [blurSigma] is the starting blur radius
  /// in logical pixels (default 10). [riseFrom] is the translate each
  /// cluster animates from (default `Offset(0, 12)`; pass `Offset.zero`
  /// to disable rise). [curve] defaults to `Curves.easeOutCubic`.
  Widget blurReveal({
    Duration delay = Duration.zero,
    double speedReveal = 1.5,
    double speedSegment = 0.5,
    double blurSigma = 10.0,
    Offset riseFrom = const Offset(0, 12),
    Curve curve = Curves.easeOutCubic,
    double? maxWidth,
  }) {
    return Builder(
      builder: (context) {
        final defaultStyle =
            DefaultTextStyle.of(context).style.copyWith(inherit: true);
        final effectiveStyle =
            style != null ? defaultStyle.merge(style) : defaultStyle;
        return EffectWidget(
          end: BlurRevealEffect(
            text: data ?? '',
            style: effectiveStyle,
            textDirection: textDirection,
            textAlign: textAlign,
            textScaler: textScaler,
            strutStyle: strutStyle,
            textHeightBehavior: textHeightBehavior,
            locale: locale,
            maxWidth: maxWidth,
            delay: delay,
            speedReveal: speedReveal,
            speedSegment: speedSegment,
            blurSigma: blurSigma,
            riseFrom: riseFrom,
            curve: curve,
          ),
          child: this,
        );
      },
    );
  }
}
```

- [ ] **Step 3.2: Export from effects.dart**

Read `lib/src/effects/effects.dart`. Add a new export line alongside the existing `roll/text_extensions.dart` export:

```dart
export 'blur_reveal/blur_reveal_extensions.dart';
```

Keep the existing exports intact. Alphabetical ordering matters for grep-ability — insert after `blur_effect.dart`.

- [ ] **Step 3.3: Write widget test proving the extension chains correctly**

Create `test/widget/effects/blur_reveal/blur_reveal_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  group('Text.blurReveal() extension', () {
    testWidgets('builds without error using all defaults', (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('Hello').blurReveal().animate(trigger: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(EffectWidget), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('accepts every parameter without crashing', (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('Hello')
              .blurReveal(
                delay: Duration(milliseconds: 100),
                speedReveal: 2.0,
                speedSegment: 0.75,
                blurSigma: 6.0,
                riseFrom: Offset(0, 20),
                curve: Curves.easeInOut,
                maxWidth: 200,
              )
              .animate(trigger: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty text renders without crashing', (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('').blurReveal().animate(trigger: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('arabic text renders without crashing', (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('مرحبا').blurReveal().animate(trigger: 0),
          defaultStyle: const TextStyle(
            fontFamily: 'TestArabic',
            fontSize: 32,
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('trigger change advances animation', (tester) async {
      int trigger = 0;
      late StateSetter setTriggerFn;

      await tester.pumpWidget(
        wrapInTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              setTriggerFn = setState;
              return const Text('Hello').blurReveal().animate(
                    trigger: trigger,
                    duration: const Duration(milliseconds: 200),
                    startState: AnimationStartState.playImmediately,
                  );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      setTriggerFn(() => trigger = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
```

- [ ] **Step 3.4: Run widget tests**

Run: `flutter test test/widget/effects/blur_reveal/blur_reveal_widget_test.dart --reporter expanded`
Expected: 5 tests pass.

If the Arabic test requires additional wrapping (e.g. the `wrapInTestApp` helper needs a new parameter for `textDirection` or the test needs to provide `textDirection: TextDirection.rtl` explicitly), check `test/helpers/test_app.dart` — the helper already supports `textDirection`.

- [ ] **Step 3.5: Commit**

```bash
git add lib/src/effects/blur_reveal/blur_reveal_extensions.dart \
        lib/src/effects/effects.dart \
        test/widget/effects/blur_reveal/blur_reveal_widget_test.dart
git commit -m ":sparkles: Text.blurReveal() extension + export"
```

---

## Task 4: Progress goldens — Latin at multiple reveal states

Capture the visual output of `BlurRevealEffect` at 5 progress values (0.0, 0.25, 0.5, 0.75, 1.0). Drive each scenario by wrapping the widget in an `EffectQuery` with the desired `curvedValue` — this bypasses `AnimatedEffect` and gives us deterministic snapshots.

**Files:**
- Create: `test/golden/effects/blur_reveal/blur_reveal_goldens_test.dart`
- Generated: `test/golden/effects/blur_reveal/goldens/ci/blur_reveal_progress_goldens.png`

- [ ] **Step 4.1: Write the progress goldens**

Create `test/golden/effects/blur_reveal/blur_reveal_goldens_test.dart`:

```dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../../helpers/alchemist_config.dart';

void main() => withTextRendering(() {
      goldenTest(
        'blur_reveal — Latin progress snapshots',
        fileName: 'blur_reveal_progress_goldens',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 500),
          children: [
            for (final p in const [0.0, 0.25, 0.5, 0.75, 1.0])
              GoldenTestScenario(
                name: 'progress ${p.toStringAsFixed(2)}',
                child: _ProgressScene(progress: p, text: 'Hello, World!'),
              ),
          ],
        ),
      );
    });

class _ProgressScene extends StatelessWidget {
  const _ProgressScene({required this.progress, required this.text});

  final double progress;
  final String text;

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
          padding: const EdgeInsets.all(24),
          child: EffectQuery(
            linearValue: progress,
            curvedValue: progress,
            isTransition: false,
            child: Text(text).blurReveal(),
          ),
        ),
      ),
    );
  }
}
```

Note: we pass the widget subtree directly under an `EffectQuery` (not via `.animate()`) to control progress exactly. The widget reads `EffectQuery.maybeOf(context)?.curvedValue` for progress.

- [ ] **Step 4.2: Generate and verify**

Run: `CI=true flutter test --update-goldens test/golden/effects/blur_reveal/blur_reveal_goldens_test.dart`
Expected: golden PNG created at `test/golden/effects/blur_reveal/goldens/ci/blur_reveal_progress_goldens.png`.

Run: `CI=true flutter test test/golden/effects/blur_reveal/blur_reveal_goldens_test.dart`
Expected: pass.

**Visual verification** (use `Read` tool on the PNG):
- progress 0.00: text is (nearly) invisible or heavily blurred, shifted down by ~12px per cluster.
- progress 0.25: first 1-2 letters starting to emerge; rest blurred.
- progress 0.50: middle of the reveal — gradient of blur-to-sharp visible across letters.
- progress 0.75: most letters sharp; last 1-2 still catching up.
- progress 1.00: crisp "Hello, World!" with no blur.

If the visual doesn't match, the decorator math is wrong somewhere — stop and debug. Expected-but-acceptable drift: exact opacity/blur values may differ by small amounts due to curve easing; what matters is monotonic progression left-to-right.

- [ ] **Step 4.3: Commit**

```bash
git add test/golden/effects/blur_reveal/blur_reveal_goldens_test.dart \
        test/golden/effects/blur_reveal/goldens/ci/blur_reveal_progress_goldens.png
git commit -m ":camera_flash: BlurReveal Latin progress goldens"
```

---

## Task 5: Script + speed variation goldens

Add goldens demonstrating the effect on Arabic (RTL, correct cursive shaping), Devanagari (conjuncts), and different speed settings. This is the user-facing proof that Phase 2's primitive pays off for complex scripts.

**Files:**
- Modify: `test/golden/effects/blur_reveal/blur_reveal_goldens_test.dart`
- Generated: `test/golden/effects/blur_reveal/goldens/ci/blur_reveal_scripts_goldens.png`

- [ ] **Step 5.1: Add a second goldenTest**

Append a second `withTextRendering { goldenTest(...) }` block in the same file (inside a second `main()` call — Dart allows multiple `goldenTest` calls in one `main`; share the top-level `withTextRendering`). Actually the cleanest pattern is ONE `main()` that runs both goldens inside `withTextRendering`:

Replace the existing `main()` in `test/golden/effects/blur_reveal/blur_reveal_goldens_test.dart` with:

```dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../../helpers/alchemist_config.dart';

void main() => withTextRendering(() {
      goldenTest(
        'blur_reveal — Latin progress snapshots',
        fileName: 'blur_reveal_progress_goldens',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 500),
          children: [
            for (final p in const [0.0, 0.25, 0.5, 0.75, 1.0])
              GoldenTestScenario(
                name: 'progress ${p.toStringAsFixed(2)}',
                child: _ProgressScene(
                  progress: p,
                  text: 'Hello, World!',
                  fontFamily: 'TestLatin',
                  direction: TextDirection.ltr,
                ),
              ),
          ],
        ),
      );

      goldenTest(
        'blur_reveal — scripts & speeds',
        fileName: 'blur_reveal_scripts_goldens',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 500),
          children: [
            GoldenTestScenario(
              name: 'arabic mid-reveal',
              child: _ProgressScene(
                progress: 0.5,
                text: 'مرحبا',
                fontFamily: 'TestArabic',
                direction: TextDirection.rtl,
              ),
            ),
            GoldenTestScenario(
              name: 'arabic settled',
              child: _ProgressScene(
                progress: 1.0,
                text: 'مرحبا',
                fontFamily: 'TestArabic',
                direction: TextDirection.rtl,
              ),
            ),
            GoldenTestScenario(
              name: 'devanagari mid-reveal',
              child: _ProgressScene(
                progress: 0.5,
                text: 'नमस्ते',
                fontFamily: 'TestDevanagari',
                direction: TextDirection.ltr,
              ),
            ),
            GoldenTestScenario(
              name: 'fast speedReveal = 3.0 at mid-progress',
              child: _ProgressScene(
                progress: 0.4,
                text: 'Hello',
                fontFamily: 'TestLatin',
                direction: TextDirection.ltr,
                speedReveal: 3.0,
              ),
            ),
            GoldenTestScenario(
              name: 'slow speedReveal = 0.75 at mid-progress',
              child: _ProgressScene(
                progress: 0.4,
                text: 'Hello',
                fontFamily: 'TestLatin',
                direction: TextDirection.ltr,
                speedReveal: 0.75,
              ),
            ),
            GoldenTestScenario(
              name: 'no rise — riseFrom Offset.zero at mid-progress',
              child: _ProgressScene(
                progress: 0.5,
                text: 'Hello',
                fontFamily: 'TestLatin',
                direction: TextDirection.ltr,
                riseFrom: Offset.zero,
              ),
            ),
          ],
        ),
      );
    });

class _ProgressScene extends StatelessWidget {
  const _ProgressScene({
    required this.progress,
    required this.text,
    required this.fontFamily,
    required this.direction,
    this.speedReveal = 1.5,
    this.riseFrom = const Offset(0, 12),
  });

  final double progress;
  final String text;
  final String fontFamily;
  final TextDirection direction;
  final double speedReveal;
  final Offset riseFrom;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: direction,
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 48,
          color: const Color(0xFF111111),
        ),
        child: Container(
          color: const Color(0xFFFFFFFF),
          padding: const EdgeInsets.all(24),
          child: EffectQuery(
            linearValue: progress,
            curvedValue: progress,
            isTransition: false,
            child: Text(text).blurReveal(
              speedReveal: speedReveal,
              riseFrom: riseFrom,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5.2: Regenerate both goldens**

Run: `CI=true flutter test --update-goldens test/golden/effects/blur_reveal/blur_reveal_goldens_test.dart`
Expected: two PNGs written.

Run: `CI=true flutter test test/golden/effects/blur_reveal/blur_reveal_goldens_test.dart`
Expected: 2 golden tests pass.

**Visual verification** (use `Read` tool):
- `arabic mid-reveal`: Arabic letters rendered in correct cursive shape, partially visible/blurred right-to-left stagger.
- `arabic settled`: "مرحبا" fully rendered with joining.
- `devanagari mid-reveal`: "नमस्ते" partially revealed, conjunct forms correct where settled.
- `fast/slow speedReveal`: different letter positions through the reveal at the same progress value.
- `no rise`: letters don't translate; blur + opacity only.

- [ ] **Step 5.3: Commit**

```bash
git add test/golden/effects/blur_reveal/blur_reveal_goldens_test.dart \
        test/golden/effects/blur_reveal/goldens/ci/blur_reveal_scripts_goldens.png
git commit -m ":camera_flash: BlurReveal scripts and speed variation goldens"
```

---

## Task 6: Storyboard entry in the example app

Add a new story that demonstrates `BlurReveal` with a re-triggerable animation and a couple of parameter variations. Register it in `example/lib/main.dart`.

**Files:**
- Create: `example/lib/stories/blur_reveal_animation.dart`
- Modify: `example/lib/main.dart`

- [ ] **Step 6.1: Create the story**

Create `example/lib/stories/blur_reveal_animation.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../story.dart';

class BlurRevealStory extends StatefulWidget {
  const BlurRevealStory({super.key});

  @override
  State<BlurRevealStory> createState() => _BlurRevealStoryState();
}

class _BlurRevealStoryState extends State<BlurRevealStory> {
  int _trigger = 0;

  void _replay() => setState(() => _trigger++);

  @override
  Widget build(BuildContext context) {
    return Story(
      title: 'Blur Reveal',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _Label('Default'),
            Text(
              'Hello, World!',
              style: GoogleFonts.inter(fontSize: 48),
            )
                .blurReveal()
                .animate(
                  trigger: _trigger,
                  duration: const Duration(milliseconds: 900),
                  startState: AnimationStartState.playImmediately,
                ),
            const SizedBox(height: 40),
            const _Label('Fast reveal, no rise'),
            Text(
              'Welcome back',
              style: GoogleFonts.inter(fontSize: 40),
            )
                .blurReveal(
                  speedReveal: 2.5,
                  riseFrom: Offset.zero,
                )
                .animate(
                  trigger: _trigger,
                  duration: const Duration(milliseconds: 900),
                  startState: AnimationStartState.playImmediately,
                ),
            const SizedBox(height: 40),
            const _Label('Slow reveal, deeper blur'),
            Text(
              'ease into it',
              style: GoogleFonts.inter(fontSize: 36),
            )
                .blurReveal(
                  speedReveal: 0.75,
                  blurSigma: 16,
                )
                .animate(
                  trigger: _trigger,
                  duration: const Duration(milliseconds: 1400),
                  startState: AnimationStartState.playImmediately,
                ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _replay,
              child: const Text('Replay'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            letterSpacing: 1.2,
          ),
        ),
      );
}
```

Note: `Story` is the existing wrapper widget used by other story files. Check `example/lib/story.dart` first — if the signature is `Story({required String title, required Widget child})` the above works. If it's different (e.g. `Story({required String name, ...})`), adjust. The existing stories (e.g. `counter_app.dart`) give you the exact pattern.

If `google_fonts` isn't available in example/'s dependencies (check `example/pubspec.yaml`), fall back to the default `TextStyle(fontSize: 48)` without `GoogleFonts.inter(...)`.

- [ ] **Step 6.2: Register the story in `example/lib/main.dart`**

Read `example/lib/main.dart`. Locate the import list and the story registration (a list or map of stories). Add an import:

```dart
import 'package:hyper_effects_demo/stories/blur_reveal_animation.dart';
```

And register the story alongside the others. The exact call pattern depends on the existing structure — it may be a `MapEntry`, a route entry, or a list element. Look at how `text_animation.dart`'s `TextAnimationStory` is registered and mirror that. Place the entry in an appropriately alphabetical position.

- [ ] **Step 6.3: Verify the example app compiles**

Run: `cd example && flutter analyze lib 2>&1 | head -20`
Expected: no new errors.

- [ ] **Step 6.4: Commit**

```bash
git add example/lib/stories/blur_reveal_animation.dart example/lib/main.dart
git commit -m ":sparkles: Storyboard: Blur Reveal demo"
```

---

## Task 7: CHANGELOG + Phase 3 full-suite verification

Record the new effect in CHANGELOG and confirm the whole suite (Phase 1 + 2 + 3) passes.

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 7.1: Run full suite**

Run: `CI=true flutter test --reporter expanded 2>&1 | tail -5`
Expected: all pass. Count should be approximately 124 (Phase 2 end) + 4 class + 6 decorator + 5 widget + 2 goldens = **~141**.

- [ ] **Step 7.2: Run analyzer**

Run: `flutter analyze lib test 2>&1 | grep -v deprecated_member_use | head -20`
Expected: no new issues in Phase 3 files.

- [ ] **Step 7.3: Update CHANGELOG**

Read `CHANGELOG.md`. Under the existing `## Unreleased` section (which has Phase 1 + 2 entries), prepend three new bullets for Phase 3:

```markdown
- Added `BlurRevealEffect` + `Text.blurReveal()` extension. Reveals text one grapheme cluster at a time with staggered blur + opacity + optional rise-from translate. Ligature-safe and RTL-aware via the `ShapedText` primitive: Arabic renders with correct cursive joining, Hebrew reveals right-to-left, ZWJ emoji stay intact.
- Added 2 new goldens verifying blur-reveal progression across Latin, Arabic, Devanagari, and per-speed variations.
- Added a storyboard entry in the example app demonstrating three `BlurReveal` presets.
```

- [ ] **Step 7.4: Commit**

```bash
git add CHANGELOG.md
git commit -m ":memo: CHANGELOG: Phase 3 BlurRevealEffect"
```

---

## Self-review

Spec coverage against `docs/superpowers/specs/2026-04-17-shaped-text-rendering-design.md` Section "BlurRevealEffect (reference implementation)":

- `BlurRevealEffect` with `delay`, `speedReveal`, `speedSegment`, `blurSigma`, `riseFrom`, `curve`: **Task 1**.
- Decorator staggers by `visualIndex` (correct RTL right-to-left reveal automatically): **Task 2**.
- Extension entry point `Text('...').blurReveal(...)`: **Task 3**.
- No `inView` parameter (per user clarification): **enforced by Task 3's signature**.
- Export from `hyper_effects.dart` via `effects.dart`: **Task 3, Step 3.2**.
- Visual verification via goldens: **Tasks 4, 5**.
- Storyboard entry: **Task 6**.
- CHANGELOG bump: **Task 7**.

Omitted from Phase 3 per spec scope:
- `TextRenderMode` flag — Phase 4.
- `HyperEffectsScope` — Phase 4.
- Rolling migration — Phase 4.
- Prewarm helper — YAGNI for Phase 3.

Placeholder scan: no TBD/TODO markers, no "similar to Task N" back-references, all code blocks complete, all commands have expected output.

Type consistency:
- `BlurRevealEffect` constructor signature stable across Task 1 → Task 2 → Task 3 (Task 2 doesn't modify the public API; only adds internal widget/painter).
- `debugBlurRevealDecorator` signature defined in Task 2 is the same the tests call.
- `_computeClusterEffect` is internal; called from both the debug wrapper and `_BlurRevealPainter.paint`.
- `EffectQuery` field access uses `curvedValue` (confirmed via `lib/src/effect_query.dart:16`).
- `EffectQuery` constructor parameters: `linearValue`, `curvedValue`, `isTransition`, optional `lerpValues`/`resetValues`/`duration`/`curve` (confirmed via `lib/src/effect_query.dart:43-53`).
- `.animate(trigger: ...)` accepts `Object?` for trigger (confirmed via `lib/src/animated_effect.dart:67`).

All other spec items covered.
