# Phase 4 — Rolling Migration: `TextRenderMode` flag + Shaped Rolling Path

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate `RollingTextEffect` onto the Phase 2 `ShapedText` primitive behind a `TextRenderMode` flag. Legacy "independent characters" path stays as the default; the new "contextual characters" path is opt-in. Phase 1 baseline goldens remain unchanged under the legacy path; a new set of goldens proves Arabic/Hebrew/Devanagari work correctly under the new path.

**Architecture:** Three layers land:

1. **Flag layer** — `TextRenderMode` enum, `HyperEffectsScope` `InheritedWidget`, `HyperEffects` global defaults, `resolveTextRenderMode(context, override)` helper. Per-effect `renderMode` parameter > scope > global > fallback.

2. **Legacy relocation** — today's `RollingTextController` + `RollingText` widget move to `lib/src/effects/roll/legacy/` unchanged. The `.roll()` extension splits into a thin router that branches on the resolved render mode.

3. **Shaped rolling path** — `ShapedRollingTextController` + `TapeFrame` + `_ShapedRollingWidget` + `_ShapedRollingPainter`. Each rolling slot pre-shapes N `ShapedText` frames (one per tape character, substituted into the full-word context per `TapeShapingContext` knob). Per-frame paint draws the active frame clipped and offset to produce the scrolling-reel effect. Lazy frame building; `RollingTextEffect.prewarm` pre-populates caches off the critical path.

**Tech stack:** Phase 2 primitives (`ShapedText`, `ClusterPainter`), existing rolling state-machine (`AnimatedEffect` / `EffectQuery`), alchemist goldens, storyboard.

---

## Scope

Phase 4 only. Corresponds to "Rollout → Phase 4" of `docs/superpowers/specs/2026-04-17-shaped-text-rendering-design.md`. Target version: v0.4.0-dev.

**What's in Phase 4:**

- `TextRenderMode { independentCharacters, contextualCharacters }` enum + resolution order.
- `HyperEffectsScope` `InheritedWidget`.
- `HyperEffects.defaultTextRenderMode` static.
- Existing rolling code relocated to `lib/src/effects/roll/legacy/` without behavior change.
- `ShapedRollingTextController` + `TapeFrame` + shaped render widget / painter.
- `TapeShapingContext { oldWord, newWord, endpointsCorrect }` enum with `endpointsCorrect` default.
- `RollingTextEffect.prewarm` static helper.
- `RollingTextEffect` routes to legacy or shaped path based on resolved mode.
- Goldens for shaped path: Latin, Arabic, Hebrew, Devanagari, number counter, emoji-ZWJ.
- Storyboard update: toggle render mode within the existing rolling story.
- CHANGELOG bump.

**What's NOT in Phase 4:**

- No default flip — the new path is opt-in. `v0.4.0` release (Phase 5) flips the default, removes the `independentCharacters` pin comments, and prints a deprecation warning.
- No removal of legacy code. That's Phase 6 (v0.5.0).
- No fix for the four known source bugs in `docs/known-bugs.md`. Phase 5 decides when to un-pin.
- No changes to `BlurRevealEffect` — it only ships on the shaped path and doesn't get a `renderMode` param.
- No tape-substitution for scripts where substitution makes no sense (emoji custom `CharacterTapeBuilder`). When a tape char isn't in the script of the surrounding word, we fall back to shaping the tape char standalone inside the slot — no forced substitution.

## Conventions

- **TDD** per task: failing test → implement → pass → commit.
- **`git add <path>`** with specific paths (never `-A`).
- **Legacy tests stay green** the entire time — existing Phase 1 suite is the regression tripwire.
- **New tests** live under `test/` mirroring the new file paths.
- Commit messages: `:sparkles:` new feature, `:truck:` move/relocate, `:wrench:` refactor, `:white_check_mark:` tests, `:camera_flash:` goldens, `:memo:` docs.
- **Opt-in mode** for goldens: always pass `renderMode: TextRenderMode.contextualCharacters` on the `.roll()` call (or wrap in `HyperEffectsScope`).

## File Structure

### Created

```
lib/src/text_render_mode.dart                 # enum only
lib/src/hyper_effects_scope.dart              # InheritedWidget + HyperEffects + resolveTextRenderMode
lib/src/effects/roll/tape_shaping_context.dart  # enum only
lib/src/effects/roll/legacy/                  # contains relocated files (moved, not new)
  legacy_rolling_text_controller.dart
  legacy_rolling_text_painter.dart            # if the painter is separate; otherwise absorb
  legacy_rolling_text.dart                    # the _RollingText widget
lib/src/effects/roll/shaped/
  shaped_rolling_text_controller.dart
  shaped_tape_frame.dart
  shaped_rolling_text.dart                    # widget + painter (~150 LOC)
test/unit/text_render_mode_test.dart
test/unit/hyper_effects_scope_test.dart
test/unit/effects/roll/shaped/
  shaped_rolling_controller_test.dart
  shaped_tape_frame_test.dart
test/widget/effects/roll/shaped/
  shaped_rolling_widget_test.dart
test/golden/effects/roll/shaped/
  shaped_rolling_goldens_test.dart            # one file, multiple goldenTest blocks
```

### Modified

- `lib/src/effects/roll/rolling_text_effect.dart` — route `apply()` based on resolved `TextRenderMode`; add `renderMode` optional param; add `tapeShapingContext` param; add `prewarm()` static.
- `lib/src/effects/roll/rolling_text_controller.dart` — becomes a thin re-export during transition or stays as the legacy type (plan Step T5 decides).
- `lib/src/effects/roll/text_extensions.dart` — add `renderMode` + `tapeShapingContext` to `.roll()` params; pass through.
- `lib/src/effects/effects.dart` — add exports for `text_render_mode.dart` and `hyper_effects_scope.dart`.
- `lib/hyper_effects.dart` — verify both new types surface via `effects/effects.dart` chain.
- `example/lib/stories/text_animation.dart` — add a mode toggle switch.
- `CHANGELOG.md` — Unreleased section.

### Not touched

- All non-rolling effects.
- `BlurRevealEffect`.
- Phase 1 baseline goldens (they stay pinned to legacy).
- `docs/known-bugs.md` entries.

---

## Task 1: `TextRenderMode` enum

**Files:**
- Create: `lib/src/text_render_mode.dart`
- Create: `test/unit/text_render_mode_test.dart`

- [ ] **Step 1.1: Write failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  test('TextRenderMode has exactly two values', () {
    expect(TextRenderMode.values.length, 2);
    expect(TextRenderMode.values, containsAll([
      TextRenderMode.independentCharacters,
      TextRenderMode.contextualCharacters,
    ]));
  });
}
```

- [ ] **Step 1.2: Run, expect compile failure**

Run: `flutter test test/unit/text_render_mode_test.dart --reporter expanded`
Expected: compile error — `TextRenderMode` not found.

- [ ] **Step 1.3: Implement**

Create `lib/src/text_render_mode.dart`:

```dart
/// Selects how per-character text effects (e.g. [RollingTextEffect],
/// [BlurRevealEffect]) lay out and paint their characters.
///
/// Per-effect resolution order:
///
/// 1. Explicit `renderMode` parameter on the effect.
/// 2. [HyperEffectsScope.renderMode] via an ancestor.
/// 3. [HyperEffects.defaultTextRenderMode] globally.
/// 4. Fallback: [TextRenderMode.independentCharacters].
enum TextRenderMode {
  /// Each character is shaped in isolation.
  ///
  /// Does **not** support Arabic, Hebrew, Devanagari, Thai, or any other
  /// script requiring contextual shaping. Retained for backward
  /// compatibility; will be removed in a future version.
  independentCharacters,

  /// Text is shaped as a single paragraph with full context, then split
  /// into per-cluster rects for animation.
  ///
  /// Supports all scripts correctly, including RTL, ligatures, and
  /// complex-script conjuncts.
  contextualCharacters,
}
```

Export via `lib/src/effects/effects.dart`. Open that file and add (alphabetical placement):

```dart
export '../text_render_mode.dart';
```

(This puts the symbol on the public surface via `hyper_effects.dart` → `effects/effects.dart` → `../text_render_mode.dart`.)

- [ ] **Step 1.4: Run, expect pass**

Run: `flutter test test/unit/text_render_mode_test.dart --reporter expanded`
Expected: 1 test passes.

- [ ] **Step 1.5: Commit**

```bash
git add lib/src/text_render_mode.dart \
        lib/src/effects/effects.dart \
        test/unit/text_render_mode_test.dart
git commit -m ":sparkles: TextRenderMode enum"
```

---

## Task 2: `HyperEffectsScope` + `HyperEffects` + `resolveTextRenderMode`

**Files:**
- Create: `lib/src/hyper_effects_scope.dart`
- Create: `test/unit/hyper_effects_scope_test.dart`

- [ ] **Step 2.1: Write failing test**

```dart
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

    testWidgets('4. fallback when nothing set', (tester) async {
      TextRenderMode? resolved;
      await tester.pumpWidget(
        wrapInTestApp(
          Builder(builder: (context) {
            resolved = resolveTextRenderMode(context);
            return const SizedBox();
          }),
        ),
      );
      expect(resolved, TextRenderMode.independentCharacters);
    });
  });
}
```

- [ ] **Step 2.2: Run, expect compile failure**

Run: `flutter test test/unit/hyper_effects_scope_test.dart --reporter expanded`
Expected: missing types.

- [ ] **Step 2.3: Implement**

Create `lib/src/hyper_effects_scope.dart`:

```dart
import 'package:flutter/widgets.dart';

import 'text_render_mode.dart';

/// An [InheritedWidget] that scopes package-wide configuration to a
/// subtree. Today it only carries [renderMode]; future additions will
/// land here as optional fields.
class HyperEffectsScope extends InheritedWidget {
  /// Creates a [HyperEffectsScope].
  const HyperEffectsScope({
    super.key,
    this.renderMode,
    required super.child,
  });

  /// The [TextRenderMode] to apply to descendant text effects.
  /// `null` means "inherit from [HyperEffects.defaultTextRenderMode] or
  /// fall back to [TextRenderMode.independentCharacters]."
  final TextRenderMode? renderMode;

  /// Returns the nearest [HyperEffectsScope] above [context], or null.
  static HyperEffectsScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HyperEffectsScope>();

  @override
  bool updateShouldNotify(covariant HyperEffectsScope oldWidget) =>
      oldWidget.renderMode != renderMode;
}

/// Package-wide global configuration. Most users should set defaults here
/// once at app start:
///
/// ```dart
/// void main() {
///   HyperEffects.defaultTextRenderMode = TextRenderMode.contextualCharacters;
///   runApp(const MyApp());
/// }
/// ```
class HyperEffects {
  HyperEffects._();

  /// Default [TextRenderMode] used when no [HyperEffectsScope] is present
  /// and no per-effect override was provided.
  ///
  /// When null, text effects fall back to
  /// [TextRenderMode.independentCharacters].
  static TextRenderMode? defaultTextRenderMode;
}

/// Resolves the effective [TextRenderMode] for an effect.
///
/// Precedence (first non-null wins):
///
/// 1. [override] — the per-effect explicit parameter.
/// 2. [HyperEffectsScope.renderMode] — nearest ancestor scope.
/// 3. [HyperEffects.defaultTextRenderMode] — app-wide global.
/// 4. [TextRenderMode.independentCharacters] — permanent fallback.
TextRenderMode resolveTextRenderMode(
  BuildContext context, {
  TextRenderMode? override,
}) {
  if (override != null) return override;
  final scope = HyperEffectsScope.maybeOf(context);
  if (scope?.renderMode != null) return scope!.renderMode!;
  return HyperEffects.defaultTextRenderMode ??
      TextRenderMode.independentCharacters;
}
```

Add to `lib/src/effects/effects.dart`:

```dart
export '../hyper_effects_scope.dart';
```

- [ ] **Step 2.4: Run, expect pass**

Run: `flutter test test/unit/hyper_effects_scope_test.dart --reporter expanded`
Expected: 7 tests pass.

- [ ] **Step 2.5: Commit**

```bash
git add lib/src/hyper_effects_scope.dart \
        lib/src/effects/effects.dart \
        test/unit/hyper_effects_scope_test.dart
git commit -m ":sparkles: HyperEffectsScope + HyperEffects + resolveTextRenderMode"
```

---

## Task 3: Relocate legacy rolling code

Move today's rolling implementation into `lib/src/effects/roll/legacy/` without modifying behavior. This gives us a clean fork point — Phase 1 goldens keep rendering identically through the legacy path.

**Files:**
- Move: `lib/src/effects/roll/rolling_text_controller.dart` → `lib/src/effects/roll/legacy/legacy_rolling_text_controller.dart`
- Update imports in: `lib/src/effects/roll/rolling_text_effect.dart`

Note: `rolling_text_effect.dart` contains both `RollingTextEffect` (Effect class) AND `RollingText` (State widget). The State widget is what uses the controller. We need to decide: move `RollingText` widget to legacy too, or keep it in place and just branch inside.

**Decision**: move `RollingText` widget (the rendering widget) to `lib/src/effects/roll/legacy/legacy_rolling_text.dart`. Keep `RollingTextEffect` class in place — it becomes the router. This minimizes churn in `rolling_text_effect.dart`.

- [ ] **Step 3.1: Map current code**

Run: `grep -n "^class " lib/src/effects/roll/rolling_text_effect.dart`

Expected: `class RollingTextEffect extends Effect`, `class RollingText extends StatefulWidget`, `class _RollingTextState extends State<RollingText>`. Confirm the exact class names.

- [ ] **Step 3.2: Create the legacy widget file**

Create `lib/src/effects/roll/legacy/legacy_rolling_text.dart` by extracting `class RollingText extends StatefulWidget` and `class _RollingTextState extends State<RollingText>` from `rolling_text_effect.dart` verbatim. Rename both:

- `RollingText` → `LegacyRollingText`
- `_RollingTextState` → `_LegacyRollingTextState`

Adjust imports so the moved classes can find their dependencies. The moved file needs to import `package:hyper_effects/src/effects/roll/rolling_text_controller.dart` (or the legacy copy if renamed — see Step 3.3), and `package:hyper_effects/src/effects/effect.dart`, plus Flutter material.

- [ ] **Step 3.3: Rename the controller file**

Move `lib/src/effects/roll/rolling_text_controller.dart` to `lib/src/effects/roll/legacy/legacy_rolling_text_controller.dart`:

```bash
git mv lib/src/effects/roll/rolling_text_controller.dart \
       lib/src/effects/roll/legacy/legacy_rolling_text_controller.dart
```

Rename the class: `RollingTextController` → `LegacyRollingTextController`. Update every usage site.

- [ ] **Step 3.4: Update `rolling_text_effect.dart` — delete the widget, update routing**

Remove the `class RollingText` and `_RollingTextState` definitions from `rolling_text_effect.dart`. In `RollingTextEffect.apply`, temporarily return the legacy widget directly (the shaped branch will land in Task 12):

```dart
@override
Widget apply(BuildContext context, Widget? child) {
  return LegacyRollingText(
    text: text,
    padding: padding,
    tapeStrategy: tapeStrategy,
    // ... all the other forwarded params
  );
}
```

Import at the top: `import 'legacy/legacy_rolling_text.dart';`.

- [ ] **Step 3.5: Update the existing controller-import test**

The Phase 1 test `test/unit/effects/roll/rolling_text_controller_test.dart` imports `package:hyper_effects/src/effects/roll/rolling_text_controller.dart`. Update to the new path and class name:

```dart
import 'package:hyper_effects/src/effects/roll/legacy/legacy_rolling_text_controller.dart';

// In the _makeController helper:
LegacyRollingTextController _makeController({...}) =>
    LegacyRollingTextController(...);
```

- [ ] **Step 3.6: Verify Phase 1 tests still pass**

Run: `CI=true flutter test --reporter expanded 2>&1 | tail -5`

Expected: 142/142 pass. The legacy move is purely mechanical — zero behavior change.

If any test fails, look for a stale import or a class-name reference that wasn't updated.

- [ ] **Step 3.7: Commit**

```bash
git add lib/src/effects/roll/ test/unit/effects/roll/rolling_text_controller_test.dart
git commit -m ":truck: Relocate legacy rolling code to roll/legacy/"
```

---

## Task 4: `TapeShapingContext` enum

**Files:**
- Create: `lib/src/effects/roll/tape_shaping_context.dart`

- [ ] **Step 4.1: Write the enum**

```dart
/// Controls which word's shaping context is used when building the
/// intermediate tape frames for rolling between two words (e.g. Arabic
/// `قطة` → `كلب`).
///
/// Only relevant under [TextRenderMode.contextualCharacters]; ignored under
/// [TextRenderMode.independentCharacters].
enum TapeShapingContext {
  /// Always substitute into the OLD word's context. Intermediates shape
  /// as if they were in `oldText`. The end-state renders correctly
  /// (shaped within `newText`'s context naturally) but earlier frames
  /// show the right letter in the WRONG word's shape.
  oldWord,

  /// Always substitute into the NEW word's context. Mirror of
  /// [oldWord] — the start frame looks wrong; the end frame is correct.
  newWord,

  /// Tape frame 0 (`oldText`'s actual letter) is shaped in the OLD
  /// word's context; tape frame T-1 (`newText`'s actual letter) is
  /// shaped in the NEW word's context; all intermediate frames use
  /// the NEW word's context. Both endpoints render correctly.
  /// A small imperceptible "snap" occurs at frame 0 → 1 coincident
  /// with a character change. This is the default.
  endpointsCorrect,
}
```

Export via `lib/src/effects/effects.dart` (add alongside the roll exports):

```dart
export 'roll/tape_shaping_context.dart';
```

- [ ] **Step 4.2: Commit**

```bash
git add lib/src/effects/roll/tape_shaping_context.dart lib/src/effects/effects.dart
git commit -m ":sparkles: TapeShapingContext enum"
```

No test file for this task — the enum's behavior is exercised by the shaped rolling controller in Tasks 5-7.

---

## Task 5: `TapeFrame` data class

**Files:**
- Create: `lib/src/effects/roll/shaped/shaped_tape_frame.dart`
- Create: `test/unit/effects/roll/shaped/shaped_tape_frame_test.dart`

- [ ] **Step 5.1: Write failing tests**

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/effects/roll/shaped/shaped_tape_frame.dart';

void main() {
  group('TapeFrame', () {
    test('stores every field', () {
      const rect = Rect.fromLTWH(10, 20, 30, 40);
      final frame = TapeFrame(
        substitutedText: 'A',
        clusterBounds: rect,
        tapeStep: 3,
      );
      expect(frame.substitutedText, 'A');
      expect(frame.clusterBounds, rect);
      expect(frame.tapeStep, 3);
    });

    test('equality is structural', () {
      const rect = Rect.fromLTWH(0, 0, 10, 10);
      final a = TapeFrame(
          substitutedText: 'a', clusterBounds: rect, tapeStep: 0);
      final b = TapeFrame(
          substitutedText: 'a', clusterBounds: rect, tapeStep: 0);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
```

- [ ] **Step 5.2: Run, expect compile failure**

- [ ] **Step 5.3: Implement**

Create `lib/src/effects/roll/shaped/shaped_tape_frame.dart`:

```dart
import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';

/// A single frame of a rolling tape for one character position.
///
/// Each frame holds the substituted string (the full word with the tape
/// character dropped into the animating position) and the bounds of the
/// animating position's cluster within the paragraph that string produces.
/// The corresponding [ShapedText] is owned by the module-level cache,
/// looked up by [substitutedText]+style at paint time.
@immutable
class TapeFrame {
  /// The full word with the tape character substituted at the animating
  /// position. Paragraphs are cached keyed on this string.
  final String substitutedText;

  /// The animating cluster's bounds within the paragraph for
  /// [substitutedText], as returned by `getGlyphInfoAt`.
  final Rect clusterBounds;

  /// This frame's ordinal position in the tape sequence (0 = start char
  /// from `oldText`, T-1 = end char from `newText`).
  final int tapeStep;

  const TapeFrame({
    required this.substitutedText,
    required this.clusterBounds,
    required this.tapeStep,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TapeFrame &&
          other.substitutedText == substitutedText &&
          other.clusterBounds == clusterBounds &&
          other.tapeStep == tapeStep;

  @override
  int get hashCode =>
      Object.hash(substitutedText, clusterBounds, tapeStep);

  @override
  String toString() =>
      'TapeFrame(step: $tapeStep, text: "$substitutedText", '
      'bounds: $clusterBounds)';
}
```

- [ ] **Step 5.4: Run, expect pass**

- [ ] **Step 5.5: Commit**

```bash
git add lib/src/effects/roll/shaped/shaped_tape_frame.dart \
        test/unit/effects/roll/shaped/shaped_tape_frame_test.dart
git commit -m ":sparkles: TapeFrame data class"
```

---

## Task 6: `ShapedRollingTextController` — frame building

The controller enumerates tape positions, builds lists of `TapeFrame`s per position (lazily), and computes the per-slot maximum width. This is the core of the shaped rolling path.

**Files:**
- Create: `lib/src/effects/roll/shaped/shaped_rolling_text_controller.dart`
- Create: `test/unit/effects/roll/shaped/shaped_rolling_controller_test.dart`

- [ ] **Step 6.1: Write failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/effects/roll/shaped/shaped_rolling_text_controller.dart';

import '../../../../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  const style = TextStyle(fontFamily: 'TestLatin', fontSize: 32);

  ShapedRollingTextController makeController({
    String oldText = 'abc',
    String newText = 'xyz',
    TapeStrategy tapeStrategy = const ConsistentSymbolTapeStrategy(0),
    TapeShapingContext context =
        TapeShapingContext.endpointsCorrect,
  }) =>
      ShapedRollingTextController(
        oldText: oldText,
        newText: newText,
        tapeStrategy: tapeStrategy,
        style: style,
        tapeShapingContext: context,
      );

  group('ShapedRollingTextController position count', () {
    test('matches max grapheme-cluster length', () {
      final c = makeController(oldText: 'abc', newText: 'xyzw');
      expect(c.positionCount, 4);
    });

    test('handles empty old text', () {
      final c = makeController(oldText: '', newText: 'hello');
      expect(c.positionCount, 5);
    });
  });

  group('ShapedRollingTextController tape frame building', () {
    test('frameAt returns consistent frames for same position', () {
      final c = makeController();
      final f1 = c.frameAt(position: 0, step: 0);
      final f2 = c.frameAt(position: 0, step: 0);
      expect(f1, equals(f2));
    });

    test('frameAt at step 0 uses the old-word tape character', () {
      final c = makeController(oldText: 'abc', newText: 'xyz');
      final f = c.frameAt(position: 0, step: 0);
      // Step 0 is the start of the roll; by convention the tape reveals
      // a character from the old word's position (or the space-shortcut
      // tape for special cases). The substitutedText at step 0 must
      // contain 'a' at position 0 somewhere.
      expect(f.substitutedText, contains('a'));
    });

    test('slot width is the max cluster width across all frames', () {
      final c = makeController(oldText: 'ab', newText: 'yz');
      final widths = <double>[];
      for (int step = 0; step < c.tapeLength(position: 0); step++) {
        widths.add(c.frameAt(position: 0, step: step).clusterBounds.width);
      }
      final maxWidth = widths.reduce((a, b) => a > b ? a : b);
      expect(c.slotWidth(position: 0), closeTo(maxWidth, 0.5));
    });
  });
}
```

- [ ] **Step 6.2: Run, expect compile failure**

- [ ] **Step 6.3: Implement the controller**

Create `lib/src/effects/roll/shaped/shaped_rolling_text_controller.dart`:

```dart
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';

import '../../../text/shaped_cluster.dart';
import '../../../text/shaped_text.dart';
import '../symbol_tape_strategy.dart';
import '../tape_shaping_context.dart';
import 'shaped_tape_frame.dart';

/// Drives per-position tape-frame shaping for [RollingTextEffect] under
/// [TextRenderMode.contextualCharacters].
///
/// Each rolling slot (character position) maintains a list of [TapeFrame]s
/// built lazily as the animation progresses. The controller owns per-slot
/// caches; the module-level [ShapedText] cache handles paragraph reuse.
class ShapedRollingTextController {
  ShapedRollingTextController({
    required this.oldText,
    required this.newText,
    required this.tapeStrategy,
    required this.style,
    this.tapeShapingContext = TapeShapingContext.endpointsCorrect,
    this.textDirection,
    this.textAlign,
    this.textScaler,
    this.strutStyle,
  });

  final String oldText;
  final String newText;
  final SymbolTapeStrategy tapeStrategy;
  final TextStyle style;
  final TapeShapingContext tapeShapingContext;
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  final TextScaler? textScaler;
  final StrutStyle? strutStyle;

  /// Grapheme-cluster count for each source string.
  late final int _oldLen = oldText.characters.length;
  late final int _newLen = newText.characters.length;

  /// Number of rolling slots (one per max-length position).
  int get positionCount => max(_oldLen, _newLen);

  /// Cached tape string per position (the tape character sequence).
  final Map<int, String> _tapePerPosition = {};

  /// Cached frames per position: `_frames[position][step]`.
  final Map<int, List<TapeFrame?>> _frames = {};

  /// Cached slot widths per position.
  final Map<int, double> _slotWidths = {};

  /// Returns the tape length (number of steps) for [position].
  int tapeLength({required int position}) {
    final tape = _tapeFor(position);
    return tape.characters.length;
  }

  /// Returns the [TapeFrame] at ([position], [step]), building it lazily.
  TapeFrame frameAt({required int position, required int step}) {
    final list = _frames.putIfAbsent(position, () {
      final len = tapeLength(position: position);
      return List<TapeFrame?>.filled(len, null, growable: false);
    });
    final cached = list[step];
    if (cached != null) return cached;
    final built = _buildFrame(position: position, step: step);
    list[step] = built;
    return built;
  }

  /// Returns the slot's fixed width = max cluster width across all frames.
  /// Forces all frames for the position to be built (this is acceptable
  /// because slot width must be stable for the whole animation; lazy
  /// building only helps for off-screen or far-future positions).
  double slotWidth({required int position}) {
    return _slotWidths.putIfAbsent(position, () {
      final len = tapeLength(position: position);
      double maxWidth = 0;
      for (int s = 0; s < len; s++) {
        final frame = frameAt(position: position, step: s);
        if (frame.clusterBounds.width > maxWidth) {
          maxWidth = frame.clusterBounds.width;
        }
      }
      return maxWidth;
    });
  }

  String _tapeFor(int position) => _tapePerPosition.putIfAbsent(position, () {
        final oldChar = position < _oldLen
            ? oldText.characters.elementAt(position)
            : ''; // padding: end-of-old
        final newChar = position < _newLen
            ? newText.characters.elementAt(position)
            : '';
        return tapeStrategy.build(oldChar, newChar);
      });

  TapeFrame _buildFrame({required int position, required int step}) {
    final tape = _tapeFor(position);
    final tapeChar = tape.characters.elementAt(step);
    final substituted = _substitute(position: position, step: step, tapeChar: tapeChar);
    final shaped = ShapedText.build(
      text: substituted,
      style: style,
      textDirection: textDirection,
      textAlign: textAlign,
      textScaler: textScaler,
      strutStyle: strutStyle,
    );
    // The cluster at `position` in the substituted string is the animating
    // slot. `ShapedText.clusters` is in visual order; we need logical order.
    // Look up by logicalIndex.
    final clusters = shaped.clusters;
    final cluster = clusters.firstWhere(
      (c) => c.logicalIndex == position,
      orElse: () => clusters.isNotEmpty
          ? clusters.first
          : const ShapedCluster(
              logicalIndex: 0,
              visualIndex: 0,
              codeUnitRange: TextRange(start: 0, end: 0),
              bounds: Rect.zero,
              direction: TextDirection.ltr,
              text: '',
              lineIndex: 0,
            ),
    );
    return TapeFrame(
      substitutedText: substituted,
      clusterBounds: cluster.bounds,
      tapeStep: step,
    );
  }

  String _substitute({
    required int position,
    required int step,
    required String tapeChar,
  }) {
    final tape = _tapeFor(position);
    final tapeLen = tape.characters.length;

    final useOld = switch (tapeShapingContext) {
      TapeShapingContext.oldWord => true,
      TapeShapingContext.newWord => false,
      TapeShapingContext.endpointsCorrect => step == 0,
    };

    final context = useOld ? oldText : newText;
    final buf = StringBuffer();
    final chars = context.characters;
    for (int i = 0; i < max(_oldLen, _newLen); i++) {
      if (i == position) {
        buf.write(tapeChar);
      } else if (i < chars.length) {
        buf.write(chars.elementAt(i));
      }
    }
    return buf.toString();
  }
}
```

- [ ] **Step 6.4: Run tests, expect pass**

Run: `flutter test test/unit/effects/roll/shaped/shaped_rolling_controller_test.dart --reporter expanded`
Expected: 5 tests pass.

If any fail, print the tape and frame data via a temporary `print` and adjust the test expectation to match observed behavior (e.g. `tapeStrategy.build('a', 'a')` returns `'aa'` per Phase 1's KNOWN BUG pin, so a degenerate position with identical chars may have tape length 2, not 1).

- [ ] **Step 6.5: Commit**

```bash
git add lib/src/effects/roll/shaped/shaped_rolling_text_controller.dart \
        test/unit/effects/roll/shaped/shaped_rolling_controller_test.dart
git commit -m ":sparkles: ShapedRollingTextController with lazy tape frames"
```

---

## Task 7: `_ShapedRollingWidget` + `_ShapedRollingPainter`

Renders the shaped rolling path: one CustomPaint per character position, each painting the active tape frame's paragraph clipped to the slot and translated vertically for the scroll animation.

**Files:**
- Create: `lib/src/effects/roll/shaped/shaped_rolling_text.dart`
- Create: `test/widget/effects/roll/shaped/shaped_rolling_widget_test.dart`

- [ ] **Step 7.1: Write failing widget tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  group('shaped rolling widget', () {
    testWidgets('renders Latin text without exception', (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('Hello')
              .roll(renderMode: TextRenderMode.contextualCharacters)
              .animate(trigger: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Arabic text without exception', (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('مرحبا')
              .roll(renderMode: TextRenderMode.contextualCharacters)
              .animate(trigger: 0),
          defaultStyle:
              const TextStyle(fontFamily: 'TestArabic', fontSize: 32),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('trigger change drives scroll without exception',
        (tester) async {
      String t = 'World';
      late StateSetter setterFn;
      await tester.pumpWidget(
        wrapInTestApp(
          StatefulBuilder(builder: (context, setState) {
            setterFn = setState;
            return Text(t)
                .roll(renderMode: TextRenderMode.contextualCharacters)
                .animate(
                  trigger: t,
                  duration: const Duration(milliseconds: 300),
                );
          }),
        ),
      );
      await tester.pumpAndSettle();
      setterFn(() => t = 'Hola!');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
```

- [ ] **Step 7.2: Run, expect failure**

At this point, `Text.roll(renderMode: ...)` doesn't exist yet. The test will fail with a missing argument. That's OK — the test is forcing us to define the downstream API in Task 8.

- [ ] **Step 7.3: Implement the widget + painter**

Create `lib/src/effects/roll/shaped/shaped_rolling_text.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../effect_query.dart';
import '../../../text/shaped_text.dart';
import '../slide_direction.dart';
import '../symbol_tape_strategy.dart';
import '../tape_shaping_context.dart';
import 'shaped_rolling_text_controller.dart';
import 'shaped_tape_frame.dart';

/// Internal widget that renders the shaped rolling path.
class ShapedRollingText extends StatefulWidget {
  const ShapedRollingText({
    super.key,
    required this.text,
    required this.previousText,
    required this.tapeStrategy,
    required this.style,
    this.tapeShapingContext = TapeShapingContext.endpointsCorrect,
    this.tapeSlideDirection = TextTapeSlideDirection.up,
    this.clipBehavior = Clip.hardEdge,
    this.padding = EdgeInsets.zero,
    this.textDirection,
    this.textAlign,
    this.textScaler,
    this.strutStyle,
  });

  final String text;
  final String previousText;
  final SymbolTapeStrategy tapeStrategy;
  final TextStyle style;
  final TapeShapingContext tapeShapingContext;
  final TextTapeSlideDirection tapeSlideDirection;
  final Clip clipBehavior;
  final EdgeInsets padding;
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  final TextScaler? textScaler;
  final StrutStyle? strutStyle;

  @override
  State<ShapedRollingText> createState() => _ShapedRollingTextState();
}

class _ShapedRollingTextState extends State<ShapedRollingText> {
  late ShapedRollingTextController _controller = _buildController();

  ShapedRollingTextController _buildController() =>
      ShapedRollingTextController(
        oldText: widget.previousText,
        newText: widget.text,
        tapeStrategy: widget.tapeStrategy,
        style: widget.style,
        tapeShapingContext: widget.tapeShapingContext,
        textDirection: widget.textDirection,
        textAlign: widget.textAlign,
        textScaler: widget.textScaler,
        strutStyle: widget.strutStyle,
      );

  @override
  void didUpdateWidget(covariant ShapedRollingText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text ||
        old.previousText != widget.previousText ||
        old.style != widget.style ||
        old.tapeStrategy != widget.tapeStrategy ||
        old.tapeShapingContext != widget.tapeShapingContext) {
      _controller = _buildController();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = EffectQuery.maybeOf(context);
    final progress = query?.curvedValue ?? 1.0;
    final slots = <Widget>[];
    for (int position = 0; position < _controller.positionCount; position++) {
      slots.add(_Slot(
        controller: _controller,
        position: position,
        progress: progress,
        clipBehavior: widget.clipBehavior,
        slideDirection: widget.tapeSlideDirection,
      ));
    }
    return Padding(
      padding: widget.padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: slots,
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.controller,
    required this.position,
    required this.progress,
    required this.clipBehavior,
    required this.slideDirection,
  });

  final ShapedRollingTextController controller;
  final int position;
  final double progress;
  final Clip clipBehavior;
  final TextTapeSlideDirection slideDirection;

  @override
  Widget build(BuildContext context) {
    final length = controller.tapeLength(position: position);
    final stepFractional = progress * (length - 1).clamp(1, 1 << 20);
    final slotWidth = controller.slotWidth(position: position);
    return ClipRect(
      clipBehavior: clipBehavior,
      child: CustomPaint(
        painter: _SlotPainter(
          controller: controller,
          position: position,
          stepFractional: stepFractional,
          slideDirection: slideDirection,
        ),
        size: Size(slotWidth, _slotHeight()),
      ),
    );
  }

  double _slotHeight() {
    // Use the first frame's bounds.height as the canonical slot height.
    // All frames for a position share the same line metrics by construction
    // (same style, same line).
    if (controller.tapeLength(position: position) == 0) return 0;
    return controller.frameAt(position: position, step: 0).clusterBounds.height;
  }
}

class _SlotPainter extends CustomPainter {
  _SlotPainter({
    required this.controller,
    required this.position,
    required this.stepFractional,
    required this.slideDirection,
  });

  final ShapedRollingTextController controller;
  final int position;
  final double stepFractional;
  final TextTapeSlideDirection slideDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final length = controller.tapeLength(position: position);
    if (length == 0) return;
    final int stepA = stepFractional.floor().clamp(0, length - 1);
    final int stepB = (stepA + 1).clamp(0, length - 1);
    final double t = stepFractional - stepA;
    final reversed = switch (slideDirection) {
      TextTapeSlideDirection.up => false,
      TextTapeSlideDirection.down => true,
      TextTapeSlideDirection.alternating => position.isEven,
      TextTapeSlideDirection.random => position.hashCode.isEven,
    };
    _paintFrame(canvas, size, stepA, 0.0, reversed);
    if (stepA != stepB) {
      _paintFrame(canvas, size, stepB, reversed ? 1 - t : t - 1, reversed);
    }
  }

  void _paintFrame(Canvas canvas, Size size, int step, double yFraction,
      bool reversed) {
    final frame = controller.frameAt(position: position, step: step);
    final shaped = _shapedForFrame(frame);
    final rect = frame.clusterBounds;
    final dy = size.height * yFraction * (reversed ? -1 : 1);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawParagraph(
      shaped.paragraph,
      Offset(-rect.left, -rect.top + dy),
    );
    canvas.restore();
  }

  ShapedText _shapedForFrame(TapeFrame frame) => ShapedText.build(
        text: frame.substitutedText,
        style: controller.style,
        textDirection: controller.textDirection,
        textAlign: controller.textAlign,
        textScaler: controller.textScaler,
        strutStyle: controller.strutStyle,
      );

  @override
  bool shouldRepaint(_SlotPainter old) =>
      old.stepFractional != stepFractional ||
      old.position != position ||
      old.slideDirection != slideDirection;
}
```

- [ ] **Step 7.4: Export nothing**

The widget is internal. Only `RollingTextEffect` uses it (via Task 8's routing). Do not add to `effects.dart`.

- [ ] **Step 7.5: Commit**

```bash
git add lib/src/effects/roll/shaped/shaped_rolling_text.dart \
        test/widget/effects/roll/shaped/shaped_rolling_widget_test.dart
git commit -m ":sparkles: Shaped rolling widget + per-slot painter"
```

The widget tests will still fail because `.roll(renderMode: ...)` doesn't exist — that's Task 8.

---

## Task 8: `.roll()` extension — add `renderMode` + `tapeShapingContext` params

**Files:**
- Modify: `lib/src/effects/roll/text_extensions.dart`

Add two parameters to `.roll()` that pass through to the effect:

- [ ] **Step 8.1: Update the extension**

Read `lib/src/effects/roll/text_extensions.dart`. Add to the `.roll()` method signature:

```dart
Widget roll({
  // ... existing params ...
  TextRenderMode? renderMode,
  TapeShapingContext tapeShapingContext = TapeShapingContext.endpointsCorrect,
}) {
  // ... existing body wrapping in EffectWidget, then:
  return EffectWidget(
    end: RollingTextEffect(
      // ... existing forwarded params ...
      renderMode: renderMode,
      tapeShapingContext: tapeShapingContext,
    ),
    child: this,
  );
}
```

Import `TextRenderMode` and `TapeShapingContext` at the top if not already via `../../../hyper_effects.dart`.

- [ ] **Step 8.2: Verify compiles**

Run: `flutter analyze lib | head -10`
Expected: `RollingTextEffect` constructor call will fail because it doesn't accept `renderMode` yet. That's Task 9.

- [ ] **Step 8.3: Commit**

```bash
git add lib/src/effects/roll/text_extensions.dart
git commit -m ":sparkles: .roll(renderMode:, tapeShapingContext:) parameters"
```

---

## Task 9: `RollingTextEffect` — add params, route in `apply()`

**Files:**
- Modify: `lib/src/effects/roll/rolling_text_effect.dart`

- [ ] **Step 9.1: Add params**

In `RollingTextEffect`, add two final fields and constructor params:

```dart
/// Optional override for the render path. Resolves via
/// [resolveTextRenderMode] when null.
final TextRenderMode? renderMode;

/// Shaping-context strategy under [TextRenderMode.contextualCharacters].
/// Ignored under independent mode.
final TapeShapingContext tapeShapingContext;
```

Add to the `const RollingTextEffect({...})` constructor, defaulted:

```dart
this.renderMode,
this.tapeShapingContext = TapeShapingContext.endpointsCorrect,
```

Add them to the `props` override (if `RollingTextEffect` uses `EquatableMixin` / `List<Object?> get props`) — check the current class. If not overridden, no action.

- [ ] **Step 9.2: Branch in `apply`**

Replace the body of `apply` to route based on resolved mode:

```dart
@override
Widget apply(BuildContext context, Widget? child) {
  final mode = resolveTextRenderMode(context, override: renderMode);
  switch (mode) {
    case TextRenderMode.independentCharacters:
      return LegacyRollingText(
        text: text,
        padding: padding,
        tapeStrategy: tapeStrategy,
        // ... forward all legacy params as before
      );
    case TextRenderMode.contextualCharacters:
      return ShapedRollingText(
        text: text,
        previousText: _previousText(context), // see note
        tapeStrategy: tapeStrategy,
        style: style ?? DefaultTextStyle.of(context).style,
        tapeShapingContext: tapeShapingContext,
        tapeSlideDirection: tapeSlideDirection,
        clipBehavior: clipBehavior,
        padding: padding,
        textDirection: textDirection,
        textAlign: textAlign,
        textScaler: textScaler,
        strutStyle: strutStyle,
      );
  }
}
```

The `previousText` for `ShapedRollingText` is "what the old text was before the most recent effect rebuild." In the legacy path, this is tracked via `_RollingTextState`'s `didUpdateWidget`. For the shaped path, the same state-tracking needs to happen — but `RollingTextEffect` is stateless (the State lives inside `ShapedRollingText` per Task 7).

Inspect Task 7's `ShapedRollingText`: the widget takes `text` and `previousText` both from its caller. The caller (RollingTextEffect.apply) doesn't easily know `previousText` — it's the PREVIOUS build's `text`. The legacy path uses `_RollingTextState.didUpdateWidget` to track this.

Fix: make `ShapedRollingText` track `previousText` itself. Change the widget's constructor to take only `text`, and add internal state:

Modify `ShapedRollingText` (Task 7's file):

```dart
class ShapedRollingText extends StatefulWidget {
  const ShapedRollingText({
    super.key,
    required this.text,
    // ... remove previousText from the constructor
    // ... other params
  });

  final String text;
  // ... other fields
}

class _ShapedRollingTextState extends State<ShapedRollingText> {
  String _previousText = '';
  late ShapedRollingTextController _controller = _buildController();

  ShapedRollingTextController _buildController() =>
      ShapedRollingTextController(
        oldText: _previousText,
        newText: widget.text,
        // ... forward
      );

  @override
  void didUpdateWidget(covariant ShapedRollingText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _previousText = old.text;
      _controller = _buildController();
    } else if (/* other relevant fields changed */) {
      _controller = _buildController();
    }
  }

  // ... rest unchanged
}
```

And in `apply`, just pass `text`:

```dart
return ShapedRollingText(
  text: text,
  tapeStrategy: tapeStrategy,
  // ...
);
```

Update Task 7's test file too — remove `previousText:` from the harness.

- [ ] **Step 9.3: Run Phase 1 + Phase 4 tests**

Run: `CI=true flutter test --reporter expanded 2>&1 | tail -5`
Expected: legacy path still passes. Shaped path widget tests now pass (since Task 7's tests depend on `.roll(renderMode:)` which now exists).

- [ ] **Step 9.4: Commit**

```bash
git add lib/src/effects/roll/rolling_text_effect.dart \
        lib/src/effects/roll/shaped/shaped_rolling_text.dart \
        test/widget/effects/roll/shaped/shaped_rolling_widget_test.dart
git commit -m ":sparkles: RollingTextEffect routes by TextRenderMode"
```

---

## Task 10: `RollingTextEffect.prewarm` static

**Files:**
- Modify: `lib/src/effects/roll/rolling_text_effect.dart`

- [ ] **Step 10.1: Add the static**

```dart
/// Pre-populates the shaped-text cache for a rolling transition from
/// [oldText] to [newText], so the first frame of the animation doesn't
/// pay the layout cost.
///
/// Safe to call at app startup or on widget init; no-op under
/// [TextRenderMode.independentCharacters].
static Future<void> prewarm({
  required String oldText,
  required String newText,
  required TextStyle style,
  required SymbolTapeStrategy tapeStrategy,
  TapeShapingContext tapeShapingContext =
      TapeShapingContext.endpointsCorrect,
  TextDirection? textDirection,
  TextScaler? textScaler,
  StrutStyle? strutStyle,
}) async {
  final controller = ShapedRollingTextController(
    oldText: oldText,
    newText: newText,
    tapeStrategy: tapeStrategy,
    style: style,
    tapeShapingContext: tapeShapingContext,
    textDirection: textDirection,
    textScaler: textScaler,
    strutStyle: strutStyle,
  );
  // Force all frames to be built (populates ShapedText cache).
  for (int p = 0; p < controller.positionCount; p++) {
    controller.slotWidth(position: p); // also builds all frames
  }
}
```

- [ ] **Step 10.2: Commit**

```bash
git add lib/src/effects/roll/rolling_text_effect.dart
git commit -m ":sparkles: RollingTextEffect.prewarm static"
```

---

## Task 11: Shaped rolling goldens

Capture visual output of the new render path across scripts.

**Files:**
- Create: `test/golden/effects/roll/shaped/shaped_rolling_goldens_test.dart`

- [ ] **Step 11.1: Write the golden test**

```dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../../../helpers/alchemist_config.dart';

void main() => withTextRendering(() {
      goldenTest(
        'shaped_rolling_latin',
        fileName: 'shaped_rolling_latin',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 500),
          children: [
            GoldenTestScenario(
              name: 'Hello — settled',
              child: _Scene(
                text: 'Hello',
                progress: 1.0,
                fontFamily: 'TestLatin',
                direction: TextDirection.ltr,
              ),
            ),
            GoldenTestScenario(
              name: 'Hello — mid-reveal',
              child: _Scene(
                text: 'Hello',
                progress: 0.5,
                fontFamily: 'TestLatin',
                direction: TextDirection.ltr,
              ),
            ),
            GoldenTestScenario(
              name: 'number counter — settled',
              child: _Scene(
                text: '1000',
                progress: 1.0,
                fontFamily: 'TestLatin',
                direction: TextDirection.ltr,
              ),
            ),
          ],
        ),
      );

      goldenTest(
        'shaped_rolling_complex_scripts',
        fileName: 'shaped_rolling_complex_scripts',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 500),
          children: [
            GoldenTestScenario(
              name: 'arabic مرحبا settled',
              child: _Scene(
                text: 'مرحبا',
                progress: 1.0,
                fontFamily: 'TestArabic',
                direction: TextDirection.rtl,
              ),
            ),
            GoldenTestScenario(
              name: 'arabic mid-reveal',
              child: _Scene(
                text: 'مرحبا',
                progress: 0.5,
                fontFamily: 'TestArabic',
                direction: TextDirection.rtl,
              ),
            ),
            GoldenTestScenario(
              name: 'hebrew שלום settled',
              child: _Scene(
                text: 'שלום',
                progress: 1.0,
                fontFamily: 'TestHebrew',
                direction: TextDirection.rtl,
              ),
            ),
            GoldenTestScenario(
              name: 'devanagari settled',
              child: _Scene(
                text: 'नमस्ते',
                progress: 1.0,
                fontFamily: 'TestDevanagari',
                direction: TextDirection.ltr,
              ),
            ),
          ],
        ),
      );
    });

class _Scene extends StatelessWidget {
  const _Scene({
    required this.text,
    required this.progress,
    required this.fontFamily,
    required this.direction,
  });

  final String text;
  final double progress;
  final String fontFamily;
  final TextDirection direction;

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
          padding: const EdgeInsets.all(16),
          child: EffectQuery(
            linearValue: progress,
            curvedValue: progress,
            isTransition: false,
            child: Text(text).roll(
              renderMode: TextRenderMode.contextualCharacters,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 11.2: Generate goldens**

```
CI=true flutter test --update-goldens test/golden/effects/roll/shaped/shaped_rolling_goldens_test.dart
CI=true flutter test test/golden/effects/roll/shaped/shaped_rolling_goldens_test.dart
```

Expected: 2 goldens pass.

Visually inspect both PNGs:
- Latin: crisp "Hello" at settled; mid-reveal shows some letters at their new positions and others mid-transition.
- Arabic: "مرحبا" in CORRECT cursive shape when settled — each letter connected. Contrast with the Phase 1 baseline goldens (independent path) which showed isolated forms.
- Hebrew: "שלום" readable.
- Devanagari: conjuncts correct.

If Arabic still shows isolated forms, the substitution or clustering logic is wrong. Debug by printing `shaped.clusters.map((c) => c.text).toList()` in the painter.

- [ ] **Step 11.3: Commit**

```bash
git add test/golden/effects/roll/shaped/shaped_rolling_goldens_test.dart \
        test/golden/effects/roll/shaped/goldens/ci/shaped_rolling_latin.png \
        test/golden/effects/roll/shaped/goldens/ci/shaped_rolling_complex_scripts.png
git commit -m ":camera_flash: Shaped rolling goldens (Latin + complex scripts)"
```

---

## Task 12: Storyboard — add render mode toggle to rolling story

**Files:**
- Modify: `example/lib/stories/text_animation.dart`

- [ ] **Step 12.1: Add a mode toggle**

Read the existing `text_animation.dart` story. Locate where it currently renders its rolling demos. Wrap them in a `StatefulBuilder` or promote the story to a `StatefulWidget` that tracks a `TextRenderMode` toggle:

```dart
TextRenderMode _mode = TextRenderMode.independentCharacters;

// In build:
Column(
  children: [
    SegmentedButton<TextRenderMode>(
      segments: const [
        ButtonSegment(
          value: TextRenderMode.independentCharacters,
          label: Text('Independent (legacy)'),
        ),
        ButtonSegment(
          value: TextRenderMode.contextualCharacters,
          label: Text('Contextual (shaped)'),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: (s) => setState(() => _mode = s.first),
    ),
    const SizedBox(height: 24),
    // Existing rolling demo widgets, passing renderMode: _mode.
  ],
);
```

Ensure every `.roll(...)` call in the story takes `renderMode: _mode` as a param.

Add an Arabic demo to showcase the contextual path's correctness:

```dart
Text(
  arabicPhrases[phraseIndex],
  textDirection: TextDirection.rtl,
  style: GoogleFonts.notoNaskhArabic(fontSize: 48),
).roll(renderMode: _mode).animate(trigger: phraseIndex);
```

- [ ] **Step 12.2: Verify example compiles**

Run: `cd example && flutter analyze lib 2>&1 | head -20`
Expected: no new errors.

- [ ] **Step 12.3: Commit**

```bash
git add example/lib/stories/text_animation.dart
git commit -m ":sparkles: Storyboard: TextRenderMode toggle in rolling demo"
```

---

## Task 13: CHANGELOG + Phase 4 full verification

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 13.1: Run full suite**

Run: `CI=true flutter test --reporter expanded 2>&1 | tail -5`
Expected: all pass. Count ≈ 142 (Phase 3 end) + ~20 (flag + shaped controller + widget + goldens) = ~162.

- [ ] **Step 13.2: Run analyzer**

Run: `flutter analyze lib test 2>&1 | grep -v deprecated_member_use | head`
Expected: no new issues in Phase 4 files.

- [ ] **Step 13.3: Update CHANGELOG**

Prepend to Unreleased:

```markdown
- Added `TextRenderMode` enum (`independentCharacters` / `contextualCharacters`), `HyperEffectsScope` `InheritedWidget`, `HyperEffects.defaultTextRenderMode` global, and `resolveTextRenderMode` helper.
- Added the `contextualCharacters` render path for `RollingTextEffect`. Correctly renders Arabic / Hebrew / Devanagari / ZWJ emoji by pre-shaping each tape frame as a full-word paragraph and animating per-cluster rects. Opt-in via `.roll(renderMode: TextRenderMode.contextualCharacters)` or `HyperEffectsScope`. Default is unchanged (legacy) for this version.
- Added `TapeShapingContext` enum with three options: `oldWord`, `newWord`, and `endpointsCorrect` (default).
- Added `RollingTextEffect.prewarm(...)` static for pre-populating the shaped-text cache off the critical path.
- Relocated legacy rolling code to `lib/src/effects/roll/legacy/`. No behavior change to the legacy path.
- Added goldens under `test/golden/effects/roll/shaped/` proving correct shaping for Latin, Arabic, Hebrew, and Devanagari.
- Storyboard: added a `TextRenderMode` toggle to the rolling-text story.
```

- [ ] **Step 13.4: Commit**

```bash
git add CHANGELOG.md
git commit -m ":memo: CHANGELOG: Phase 4 shaped rolling migration"
```

---

## Self-review

Spec coverage against `docs/superpowers/specs/2026-04-17-shaped-text-rendering-design.md` Section "The flag: TextRenderMode" + "Rolling in the new path":

- `TextRenderMode` enum + resolution order: **Tasks 1, 2**.
- `HyperEffectsScope` + `HyperEffects`: **Task 2**.
- Legacy relocation: **Task 3**.
- `TapeShapingContext` enum: **Task 4**.
- Pre-shape full-word substitution: **Task 6**.
- Lazy frame building: **Task 6**.
- Slot width = max cluster width: **Task 6**.
- `RollingTextEffect.prewarm`: **Task 10**.
- Route by render mode: **Tasks 8, 9**.
- Goldens for correctness proof: **Task 11**.
- Storyboard update: **Task 12**.
- CHANGELOG: **Task 13**.

Omitted from Phase 4 per spec scope:

- Default flip (Phase 5).
- Legacy removal (Phase 6).
- Fix of 4 known source bugs (deferred).

Placeholder scan: no TBD/TODO markers.

Type consistency:
- `ShapedRollingTextController` constructor args match the controller test harness.
- `TapeFrame(substitutedText, clusterBounds, tapeStep)` — signature stable across Task 5 → Task 6 → Task 7.
- `ShapedRollingText` constructor: after Task 9's refactor, only `text` is the source string (no `previousText` — internal state).
- `RollingTextEffect.prewarm` signature matches what Phase 5 consumers will call.
