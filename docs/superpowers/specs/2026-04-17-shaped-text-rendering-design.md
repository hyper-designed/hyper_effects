# Shaped Text Rendering — Design Spec

**Status:** Draft → Approved pending user review
**Date:** 2026-04-17
**Author:** Saad Ardati (with Claude)
**Scope:** v0.3.x → v0.5.0 migration of text-effect rendering path

## Problem

`hyper_effects` today splits animated text into one `TextPainter` per character, rendered as siblings in a `Row`. This breaks cursive and complex scripts:

- **Arabic** letters render in their isolated form because each character is shaped alone. Cursive connection and ligatures (e.g. lam-alef `لا → ﻻ`) never form.
- **Devanagari / Thai / Myanmar** shaping fails for the same reason — contextual substitution requires neighbors.
- **ZWJ emoji sequences** work only because the `characters` package already groups them into one grapheme cluster before the per-char loop.
- **Mixed-script / bidi** text renders in logical (not visual) order.

Grapheme-cluster-aware splitting is necessary but not sufficient. The fix must happen downstream of segmentation, at the shaping layer. The existing test suite is empty, so there is no regression tripwire for the refactor.

This spec also lays foundation for per-character effects beyond rolling — starting with `BlurReveal`, with `shimmerPerChar`, `wave`, `decrypt`, etc. sitting on the same primitive.

## Prior art survey

Conducted 2026-04-17. No Flutter package, gist, blog post, issue comment, or commercial UIKit solves per-cluster animation with correct Arabic shaping via `getBoxesForRange` / `GlyphInfo`. Closest conceptual prior art is a Python/Pango project (`saqib-ahmed/arabic-text-animator`). Rive proves the approach works but runs its own HarfBuzz stack outside Flutter's paragraph pipeline. This design is a net-new contribution.

## Architecture

### The primitive: `ShapedText`

One paragraph, shaped once with full context, queryable by cluster.

```dart
class ShapedText {
  factory ShapedText.build({
    required String text,
    required TextStyle style,
    TextDirection? textDirection,
    TextAlign textAlign,
    TextScaler textScaler,
    TextHeightBehavior? textHeightBehavior,
    StrutStyle? strutStyle,
    Locale? locale,
    double? maxWidth,
    ui.BoxHeightStyle boxHeightStyle,  // default: tight
    ui.BoxWidthStyle boxWidthStyle,    // default: tight
  });

  static Future<void> prewarm({/* same params */});

  ui.Paragraph get paragraph;
  Size get size;
  List<ui.LineMetrics> get lines;

  /// Clusters in visual order (RTL clusters appear in right-to-left
  /// iteration order). Each cluster carries logicalIndex for consumers
  /// that need source-string ordering.
  List<ShapedCluster> get clusters;

  void paint(Canvas canvas, Offset offset);
}

class ShapedCluster {
  final int logicalIndex;
  final int visualIndex;
  final TextRange codeUnitRange;
  final Rect bounds;
  final TextDirection direction;
  final String text;
  final int lineIndex;
}
```

Construction:
1. Single `TextPainter.layout()` pass with user's style.
2. Enumerate grapheme clusters via `text.characters` to compute each cluster's starting code unit offset.
3. **Per cluster: `paragraph.getGlyphInfoAt(clusterStart)`** — returns a `GlyphInfo` whose `graphemeClusterLayoutBounds` is the ligature-safe rect and whose `graphemeClusterCodeUnitRange` confirms the cluster boundaries. This is the primary primitive because Skia's `getBoxesForRange` snaps to grapheme boundaries and returns an empty list for partial-cluster ranges (verified against Skia `ParagraphImpl.cpp`). `getGlyphInfoAt` auto-expands to the full cluster and returns a rect + `writingDirection` for any valid offset.
4. Use `getBoxesForRange(clusterStart, clusterEnd)` only when a cluster straddles a soft line wrap (multi-line single cluster is rare but possible for very narrow containers).
5. Rects are already bidi-reordered and ligature-spanning — that's what makes this correct.

**Multiline**: `maxWidth` enables wrapping. `lines: List<LineMetrics>` is populated; clusters carry `lineIndex`. The `no \n` assertion in `text_extensions.dart:100` is removed.

### Cache

Module-level `LruCache<ShapedTextKey, ShapedText>` keyed on `(text, style-hash, direction, textScaler, maxWidth, boxHeightStyle, boxWidthStyle)`, bounded to 128 entries. `ui.Paragraph` holds native memory; the cache calls `dispose()` on eviction. Consumers hold `ShapedText` by value and re-request after disposal.

### Rendering helper: `ClusterPainter` + `ClusterEffect`

```dart
class ClusterEffect {
  final Matrix4? transform;     // applied around cluster.bounds center
  final double opacity;         // 1.0 = fully visible
  final double blurSigma;       // 0 = no blur
  final ColorFilter? colorFilter;
  final bool visible;
}

class ClusterPainter {
  static void paintWithClusters(
    Canvas canvas,
    ShapedText text,
    Offset offset,
    ClusterEffect Function(ShapedCluster) decorator,
  );
}
```

Paint strategy: for each cluster with non-identity effect, `canvas.saveLayer(cluster.bounds.shift(offset), paint)` + `canvas.clipRect(cluster.bounds.shift(offset))` + apply transform + `paragraph.paint(canvas, offset - cluster.bounds.topLeft + effectTranslation)` — draw the whole paragraph shifted so that cluster's position lands in the clipped region. Identity-effect clusters batch into one `paragraph.paint` call.

### Rolling in the new path

Each rolling position *i* maintains a lazy list of `TapeFrame` objects. A `TapeFrame` is:

```dart
class TapeFrame {
  final ShapedText shapedText;  // the full word with tape char at position i
  final Rect clusterBounds;     // position i's cluster bounds within shapedText
  final int tapeStep;
}
```

Frame generation:
1. Controller resolves the tape character for position *i* at step *t* from `tapeStrategy`.
2. Builds `substituted = context[0..i] + tape[t] + context[i+1..]`, where `context` is governed by the `TapeShapingContext` knob.
3. `ShapedText.build(substituted, style, ...)` — goes through the same global cache.
4. Extracts position *i*'s `ShapedCluster` → stores `(shapedText, clusterBounds, tapeStep)`.

Context knob, exposed as a parameter on `RollingTextEffect`:

```dart
enum TapeShapingContext { oldWord, newWord, endpointsCorrect }

RollingTextEffect({
  // ... existing params
  TapeShapingContext tapeShapingContext = TapeShapingContext.endpointsCorrect,
});
```

`endpointsCorrect` — tape frame 0 uses old-word shaping, frame T-1 uses new-word shaping, intermediates use new-word. Both endpoints render correctly. Small imperceptible "snap" at frame 0→1 coincident with character change. Default because it's the only option where what the eye lands on is correct. Only applies when `renderMode == contextualCharacters`; ignored under `independentCharacters`.

Lazy frame building: only frames near the current scroll position exist at any moment (~3-5 per position). Frames scrolling out of view are disposed via `ShapedText.paragraph.dispose()`. Prewarming is user-controlled:

```dart
RollingTextEffect.prewarm({
  required String oldText,
  required String newText,
  required TextStyle style,
  required TapeStrategy tapeStrategy,
  TextDirection? textDirection,
  TextScaler? textScaler,
});
```

Slot width per position = `max(frame.clusterBounds.width for frame in frames)`. Each frame is centered within the slot.

### `BlurRevealEffect`

Reference implementation of a pure decorator-based effect — mirrors the TS `BlurReveal` shared by the user.

```dart
class BlurRevealEffect extends Effect {
  final Duration delay;
  final double speedReveal;   // overall reveal speed multiplier
  final double speedSegment;  // per-cluster reveal duration
  final double blurSigma;     // starting blur, default 10
  final Offset? riseFrom;     // optional translate-from, default Offset(0, 12)
  final Curve curve;          // default Curves.easeOutCubic
}
```

Per-cluster decorator: staggers by `visualIndex` so Arabic reveals right-to-left correctly. Opacity animates linearly with eased curve; blur = `blurSigma * (1 - eased)`; optional translate = `riseFrom * (1 - eased)`.

Extension:

```dart
Text('Hello, World!').blurReveal(delay: 0.1.seconds, riseFrom: Offset(0, 16))
    .animate(trigger: isVisible);
```

No `inView` parameter — scroll-triggered reveal composes with existing scroll effects.

### Future effects (out of scope for v1, in scope for API design)

- `ShimmerPerCharEffect` — decorator returns `colorFilter: gradient mask across clusters`.
- `WaveEffect` — decorator returns `transform: translation(0, sin(progress * 2π + cluster.visualIndex * 0.3) * 8)`.
- `ShuffleEffect` — single-substitution tape, reuses rolling's `TapeFrame` infrastructure.
- `DecryptEffect` — per-cluster progress reveals real vs random, decorator only.

All ~50 LOC once the primitive and `ClusterPainter` exist.

## The flag: `TextRenderMode`

```dart
enum TextRenderMode {
  /// Each character is shaped in isolation. Does not support Arabic,
  /// Hebrew, Devanagari, Thai, or other scripts requiring contextual
  /// shaping. Retained for backward compatibility.
  independentCharacters,

  /// Text is shaped as a single paragraph with full context, then split
  /// into per-cluster rects for animation. Supports all scripts correctly.
  contextualCharacters,
}
```

### Resolution order

At paint time, each effect resolves its active mode:

1. Explicit `renderMode` parameter on the effect constructor.
2. `HyperEffectsScope.maybeOf(context)?.renderMode`.
3. `HyperEffects.defaultTextRenderMode`.
4. Fallback: `TextRenderMode.independentCharacters`.

### Control surface

Per-call:
```dart
Text('Hello').roll(renderMode: TextRenderMode.contextualCharacters).animate(...);
```

Global:
```dart
HyperEffects.defaultTextRenderMode = TextRenderMode.contextualCharacters;
```

Scoped (`HyperEffectsScope` — retained for v1 since more features will feed into it):
```dart
HyperEffectsScope(
  renderMode: TextRenderMode.contextualCharacters,
  child: MyApp(),
);
```

`BlurRevealEffect` does not expose `renderMode` — it's new and only shipped on the contextual path.

### Deprecation timeline

- **v0.3.x (this release)**: `independentCharacters` is default. `contextualCharacters` opt-in.
- **v0.4.0**: default flips to `contextualCharacters`. `independentCharacters` marked `@Deprecated`.
- **v0.5.0**: `independentCharacters` removed. Legacy code deleted from `lib/src/effects/roll/legacy/`.

## Code organization

```
lib/src/effects/roll/
  rolling_text_effect.dart            # public API, routes by renderMode
  rolling_text_controller.dart        # thin switch → legacy or shaped subcontroller
  legacy/
    legacy_rolling_text_controller.dart    # today's impl, moved here verbatim
    legacy_symbol_tape_painter.dart
  shaped/
    shaped_rolling_text_controller.dart    # new path
    shaped_tape_frame.dart
    shaped_rolling_painter.dart
lib/src/text/
  shaped_text.dart
  shaped_cluster.dart
  cluster_painter.dart
  cluster_effect.dart
  shaped_text_cache.dart
lib/src/effects/blur_reveal/
  blur_reveal_effect.dart
  blur_reveal_extensions.dart
lib/src/hyper_effects_scope.dart     # InheritedWidget; renderMode + future config
```

## Test suite (ships first, as PR #1)

```
test/
  unit/
    effects/roll/
      symbol_tape_strategy_test.dart
      character_tape_builder_test.dart
      rolling_text_controller_test.dart
    effects/
      effect_lerp_test.dart
    animated_effect_test.dart
    effect_query_test.dart
  widget/
    roll/
      rolling_text_widget_test.dart
      rolling_text_configuration_test.dart
      rolling_text_multiline_assertion_test.dart
      rolling_text_rtl_current_behavior_test.dart
    effect_widget_test.dart
  golden/
    roll/
      rolling_latin_ascii_baseline.png
      rolling_number_counter_baseline.png
      rolling_emoji_standalone_baseline.png
      rolling_emoji_zwj_sequence_baseline.png
      rolling_combining_marks_baseline.png
      rolling_stagger_up_baseline.png
      rolling_stagger_alternating_baseline.png
      rolling_arabic_baseline.png         # snapshot of current bug
      rolling_hebrew_baseline.png         # snapshot of current bug
      rolling_devanagari_baseline.png     # snapshot of current bug
      rolling_mixed_bidi_baseline.png
      rolling_with_padding_baseline.png
      rolling_clip_none_baseline.png
      rolling_custom_tape_strategy_baseline.png
      rolling_symbol_distance_multiplier_baseline.png
  integration/
    example_stories_smoke_test.dart
  benchmarks/
    rolling_frame_budget_bench.dart
    shaped_text_layout_bench.dart
  helpers/
    test_font_loader.dart
    alchemist_config.dart
tool/
  download_test_fonts.dart
test/fonts/.cache/                    # gitignored
```

### Decisions codified

- **No bundled fonts.** `tool/download_test_fonts.dart` fetches Noto Sans, Noto Naskh Arabic, Noto Sans Devanagari, Noto Color Emoji into `test/fonts/.cache/` (gitignored). CI runs it before `flutter test`. `setUp` fails with a friendly message if cache is missing.
- **Cross-platform normalization via `alchemist`** (`golden_toolkit` is deprecated as of 2024). Added to `dev_dependencies`.
- **"Baseline" naming** for goldens that capture the current buggy behavior. Files are replaced (not renamed) when the new render path ships.

### What each tier proves

- **Unit tests** pin pure-logic primitives (tape building, character classification, strategy branches, stagger math). No widget rebuild.
- **Widget tests** pin tree shape and rebuild semantics. `tester.pumpFrames` drives animation to checkpoints (0.0, 0.25, 0.5, 0.75, 1.0) asserting per-frame invariants.
- **Golden tests** pin pixel output via `matchesGoldenFile` + Alchemist normalization. Uses downloaded Noto fonts.
- **Integration** walks example stories, no exceptions, no dropped-frame threshold violations.
- **Benchmarks** off-CI, record baseline timings for post-migration comparison.

### Coverage targets

- Unit: ≥95% line coverage on `lib/src/effects/roll/*` and `lib/src/animated_effect.dart`.
- Widget: every public parameter of `RollingTextEffect` and `.roll()` exercised ≥1x.
- Golden: every `TapeStrategy` subclass × ≥2 text categories.
- Smoke: every story in `example/lib/stories/text_animation.dart` pumps to completion.

### Determinism controls

- `debugDisableShadows = true` in test setUp.
- `textScaleFactorTestValue = 1.0`.
- `FontLoader`-loaded Noto fonts only; system fonts suppressed via `FontFamily` overrides.
- `FakeAsync` only for loop/reverse controller-reset tests; everything else uses real `pumpAndSettle`.

## Rollout (phases, not PRs)

Work is squashed at the end; these are sequencing checkpoints, not commit boundaries.

1. **Phase 1 — Test suite.** The entire suite above, against current behavior. All passes. Establishes baseline goldens for current (buggy) behavior. Target: v0.3.1.
2. **Phase 2 — `ShapedText` primitive + `ClusterPainter`.** No effects yet. Unit-tested standalone. No user-facing changes. Target: v0.3.2.
3. **Phase 3 — `BlurRevealEffect` on the primitive.** Validates the decorator pattern end-to-end. Only ships on `contextualCharacters` — no `renderMode` param. Golden tests for Latin, Arabic, Hebrew, emoji. Target: v0.3.3.
4. **Phase 4 — `contextualCharacters` rolling path + `TextRenderMode` flag + `HyperEffectsScope`.** Legacy path moves to `legacy/`. New path default-off. Goldens for all scripts pass on new path. Target: v0.4.0-dev.
5. **Phase 5 — Default flip.** `HyperEffects.defaultTextRenderMode = contextualCharacters`. `independentCharacters` marked `@Deprecated`. Migration doc published. Target: v0.4.0.
6. **Phase 6 — Legacy removal.** `independentCharacters` and `legacy/` directory deleted. Target: v0.5.0.

## Migration doc

Lands at `docs/migration/v0.3-to-v0.4.md` with:
- What changed and why.
- Breaking-change surface (default flip in v0.4.0).
- Early opt-in via `HyperEffects.defaultTextRenderMode`.
- Pinning to legacy via param / scope.
- Known visual differences (cluster rects use consistent `BoxHeightStyle`; widths may shift ≤1px in some fonts).

## Out of scope

- Custom shaper plug-in (blocked by Flutter `#96617`).
- Direct glyph-ID access (blocked by absence of `drawGlyphRun`).
- Lottie / Rive-style pre-baked text export.
- Per-character animation of user-provided `TextSpan` trees with mixed styles within one effect. (v1 targets a single `TextStyle` per `ShapedText`; mixed-style support is a follow-up once the primitive is battle-tested.)
- Telemetry. The package emits no analytics; only `kDebugMode` logs when falling back to legacy.

## Open questions

None at spec-approval time. All decisions are locked. Implementation-time questions (e.g. exact blur-filter compositing strategy for nested saveLayers) are deferred to implementation plan PRs.
