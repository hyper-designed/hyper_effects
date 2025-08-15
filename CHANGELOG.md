# Changelog

All notable changes to the Hyper Effects package are documented in this file.

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
