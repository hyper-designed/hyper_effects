# Changelog

All notable changes to the Hyper Effects package are documented in this file.

## Unreleased

- **BREAKING**: The default `TextRenderMode` fallback is now `contextualCharacters` (was `independentCharacters`). For Latin text, visual output is pixel-stable; for RTL / complex scripts (Arabic, Hebrew, Devanagari, Thai), rolling text now renders correctly with proper shaping. See `docs/migration/v0.3-to-v0.4.md` for details and opt-out instructions.
- Deprecated `TextRenderMode.independentCharacters`. Will be removed in v0.5.0.
- Added `docs/migration/v0.3-to-v0.4.md` migration guide.
- Storyboard: default mode flipped to contextual; added a side-by-side legacy-vs-shaped Arabic comparison and Hebrew / Devanagari phrase-cycler demos.
- Added `TextRenderMode` enum (`independentCharacters` / `contextualCharacters`), `HyperEffectsScope` `InheritedWidget`, `HyperEffects.defaultTextRenderMode` global, and `resolveTextRenderMode` helper.
- Added the `contextualCharacters` render path for `RollingTextEffect`. Correctly renders Arabic / Hebrew / Devanagari / ZWJ emoji by pre-shaping each tape frame as a full-word paragraph and animating per-cluster rects. Opt-in via `.roll(renderMode: TextRenderMode.contextualCharacters)` or `HyperEffectsScope`.
- Added `TapeShapingContext` enum with three options: `oldWord`, `newWord`, and `endpointsCorrect` (default).
- Added `RollingTextEffect.prewarm(...)` static for pre-populating the shaped-text cache off the critical path.
- Relocated legacy rolling code to `lib/src/effects/roll/legacy/`. No behavior change to the legacy path.
- Added goldens under `test/golden/effects/roll/shaped/` proving correct shaping for Latin, Arabic, Hebrew, and Devanagari.
- Storyboard: added a `TextRenderMode` toggle to the rolling-text story.
- Added `BlurRevealEffect` + `Text.blurReveal()` extension. Reveals text one grapheme cluster at a time with staggered blur + opacity + optional rise-from translate. Ligature-safe and RTL-aware via the `ShapedText` primitive: Arabic renders with correct cursive joining, Hebrew reveals right-to-left, ZWJ emoji stay intact.
- Added 2 new goldens verifying blur-reveal progression across Latin, Arabic, Devanagari, and per-speed variations.
- Added a storyboard entry in the example app demonstrating three `BlurReveal` presets (default, fast/no-rise, slow/deep-blur).
- Added `ShapedText` primitive (`lib/src/text/shaped_text.dart`) — one-paragraph, ligature-safe per-cluster rect enumeration via `Paragraph.getGlyphInfoAt`. Module-level LRU cache with `paragraph.dispose()` on eviction. Not exported yet; will power `BlurRevealEffect` (Phase 3) and the new rolling render path (Phase 4).
- Added `ShapedCluster`, `ClusterEffect`, and `ClusterPainter` (also under `lib/src/text/`). `ClusterPainter.paintWithClusters` batches identity clusters into a single `drawParagraph` and applies per-cluster effects (transform / opacity / blur / color filter / visibility) via `saveLayer`.
- Added 2 new goldens verifying ligature-safety (`shaped_text_cluster_rects_goldens.png`) and per-cluster effect correctness (`cluster_painter_effects_goldens.png`).
- Added a comprehensive baseline test suite (unit, widget, and alchemist-normalized golden tiers with ~0.5% pixel tolerance for AA/hinting drift) pinning current behavior for `RollingTextEffect`. Goldens for Arabic, Hebrew, Devanagari, and mixed bidi text capture current (known-broken) shaping as baselines to replace in later phases.
- Added `tool/download_test_fonts.dart` for test font management (Noto Sans / Naskh Arabic / Hebrew / Devanagari / Color Emoji). Fonts are gitignored; run `dart run tool/download_test_fonts.dart` before `flutter test`.

## [0.3.0+1] - Aug 15, 2025

- Loosen dependency constraints for equatable to `>=2.0.5 <3.0.0`.

## [0.3.0] - Dec 15, 2024

### Added
- **New Effects**
  - Padding effect for dynamic padding adjustments.
  - Global roll effect for universal rolling animations.
  - Width & height factor support in align effect.
- **Scroll Transition Enhancements**
  - Additional event variables for finer control.
  - Improved transition state management.
- **Pointer Transition Features**
  - `usePointerRouter` option for flexible pointer event handling.
  - Enhanced pointer position tracking.
- **New AnimatedEffect Properties**
  - `resetValues` - Controls value reset behavior.
  - `interruptable` - Manages animation interruption.
  - `skipIf` - Conditional animation execution.
  - `startState` - Initial animation state control.
  - `transformHits` property for translate effect.
  - `rotateIn` and `rotateOut` methods for rotate effect.
- **Added New Examples**
  - group_animation.dart
  - rolling_app_bar_animation.dart
  - rolling_pictures_animation.dart
  - scroll_phase_slide.dart
  - scroll_phase_blur.dart
  - success_card_animation.dart

### Changed
- **Breaking Changes**
  - Effect apply function's child parameter is now nullable.
  - Text rolling API redesigned for consistency with other effects.
    - New unified interface matching other animation effects.
    - Previous text rolling methods have been deprecated.
  - `startImmediately` replaced with more flexible `startState`.
  - Removed unnecessary PostFrame callbacks from pointer transition logic.
- **Improvements**
  - Default blur effect state now starts un-blurred.
  - Added `characterTapeBuilders` to `SymbolTapeStrategy` for customization.
  - Fixed issues with scroll transitions to provide smoother and more consistent user experience.

## [0.2.3] - Feb 2, 2024

### Fixed
- Resolved Dart analysis issues for better code quality

## [0.2.2] - Feb 2, 2024

### Added
- New `startImmediately` boolean in .animate()
- Improved documentation for `AnimatedEffect`

### Fixed
- Value clamping for:
  - `OpacityEffect` (0.0 - 1.0)
  - `ClipEffect` (0.0 - 1.0)
  - `ColorFilterEffect` (0.0 - 1.0)
- Prevents exceptions with out-of-range curves

## [0.2.1] - Dec 28, 2023

### Fixed
- Animation controller state change exception handling

## [0.2.0] - Dec 24, 2023

### Added
- **New Effects**
  - Rolling Text effect for text animations
  - Shake effect for vibration animations
  - Align effect for alignment control
- **Animation Control**
  - `oneShot` function for immediate animations
  - `animateAfter` for sequential animations
  - `resetAll` for animation state reset
  - Repeat parameter for cyclic animations
  - Delay parameter for timed starts
  - `playIf` for conditional execution

### Changed
- **Breaking Changes**
  - Renamed:
    - `toggle` → `trigger` in .animate()
    - `AnimatedEffect` → `EffectWidget`
    - `EffectAnimationValue` → `EffectQuery`
    - `PostFrameWidget` → `PostFrame`
  - Enhanced `EffectQuery` with `linearValue` and `curvedValue`
- **Improvements**
  - Updated effect extensions with `from` state support
  - Added convenience methods (slideIn/Out, fadeIn/Out)

## [0.1.1] - Oct 26, 2023

### Changed
- Documentation improvements
- Added example GIFs in README

## [0.1.0] - Oct 25, 2023

### Added
- Initial release of Hyper Effects
- Core animation and effect system
- Basic effect implementations
- Documentation and examples
