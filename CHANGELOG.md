# Changelog

All notable changes to the Hyper Effects package are documented in this file.

## [0.4.0] - Aug 26, 2026

### Breaking
- **`AlignEffect` factors now default to null** — `widthFactor` and
  `heightFactor` on `AlignEffect` and `.align()` are now `double?`
  defaulting to null, matching Flutter's `Align`: null expands to fill the
  incoming constraints instead of shrink-wrapping to the child. Previously
  the hardcoded default of `1` forced every `.align()`, `.alignX()`,
  `.alignY()`, and `.alignXY()` to shrink-wrap, which made the alignment a
  visual no-op under loose constraints. Pass `widthFactor: 1` /
  `heightFactor: 1` explicitly to restore the old shrink-wrap behavior.
  Mixed null/non-null factor endpoints snap to the target value rather
  than interpolating (there is no numeric interpolation between "fill
  constraints" and a size factor).

### Added
- **Velocity handoff for springs** — retargeting a spring-driven
  `.animate()` mid-flight (changing the effect's target while it moves)
  now carries momentum: the new spring starts from the captured position
  AND the captured velocity, so rapid re-targets whip naturally instead of
  deadening. Built on the new `VectorEffect` mixin — SwiftUI-style vector
  arithmetic (`+`, `-`, `*`, `magnitudeSquared`) implemented by
  `TranslateEffect`, `ScaleEffect`, `RotationEffect`, and `OpacityEffect` —
  and a closed-form spring solver verified against Flutter's own
  `SpringSimulation`. Effects without the mixin (and all curved motions)
  keep the existing behavior.
- **Motion API** — timing is now a first-class object. Every `duration:` +
  `curve:` pair on `.animate()`, `.immediate()`, and `.step()` is sugar for
  `motion: CurvedMotion(duration, curve)`, and the new `motion:` parameter
  accepts spring physics: `CupertinoMotion.bouncy()` / `.smooth()` /
  `.snappy()` / `.interactive()`, the Material 3 `MaterialSpringMotion`
  tokens, or a custom `SpringMotion(SpringDescription)`. Springs have no
  fixed duration — the segment's length is a computed physical settling
  bound (`Motion.effectiveDuration`), overshoot renders truly past the
  target, and keyframe handoffs stay exact. Passing both `motion:` and
  `duration:`/`curve:` throws.
- **Timeline API** — a single-controller orchestration tier. Declare absolute
  keyframes with `.step()` boundaries and drive them with `.timeline()`:
  ```dart
  icon
      .scale(0).rotate(0)
      .step(duration: const Duration(milliseconds: 350), curve: Curves.easeOutQuart)
      .scale(1.5).rotate(15 * pi / 180)
      .step(duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack, delay: const Duration(milliseconds: 150))
      .scale(1).rotate(0)
      .timeline(trigger: isCompleted);
  ```
  Keyframe values are absolute and hand off between steps — they never stack.
  A `trigger` is a pure identity signal: any change restarts the timeline
  forward. Effect types absent from a keyframe carry their previous value
  forward; declaring the same effect type twice in one keyframe throws.
- `TimelineController` — imperative `play` / `reverse` / `pause` / `seek` /
  `progress`, attachable via `.timeline(controller:)`, ownable outside the
  widget tree (a State, cubit, or service), with listener notifications.
- The `#immediate` trigger sentinel — pass `trigger: #immediate` to
  `.timeline()` OR `.animate()` to play on mount, once per State lifetime.
  Rebuilds do not replay it. One channel now answers "when does this play"
  for both tiers.
- `.immediate()` on the animate extension — a shorthand that constructs
  `trigger: #immediate`, taking every `animate` parameter except `trigger`
  and `startState`.
- `repeat:` on `.timeline()` — loop with `repeat: -1` (forever) or
  `repeat: n` (n extra cycles, resting at the final keyframe; `onEnd` fires
  once at the true end).
- `key:` on `.animate()` — enables `AnimatedEffectStateRetainer` usage
  directly from the standard animate entry point.
- `AnimationStartState` overhauled to `{eager, lazy}`, with start state and
  play-on-mount now cleanly separated concerns. Neither value plays an
  animation on mount:
  - `eager` inserts the widget with its effects already applied at their
    ENDING values (the controller starts at 1). The next trigger
    interpolates from there.
  - `lazy` (the default) inserts the widget inert, with its effects held at
    their STARTING values, until it is triggered at least once.

  Play-on-mount is now expressed exclusively by `trigger: #immediate`.

### Fixed
- `PointerTransition` no longer keeps stale hover/bounds state when its target
  moves beneath a stationary mouse while using the default global pointer
  router.
- `PointerTransition` now clears hover state when a pointer device is removed,
  fixing indirect-pointer taps in the iOS Simulator that otherwise remained
  at their hover value after release.
- `.animate()` re-triggers now restore the `repeat`/`reverse` budget — pulse
  animations no longer play once and rest stuck at their peak value.
- Fresh triggers reset the reverse-leg state machine — re-triggering
  mid-flight plays a complete new run.
- `onEnd` fires exactly once per logical run instead of once per
  repeat/reverse leg.
- Resetting an `interruptable: false` animation mid-flight no longer bricks
  it permanently (stale canceled ticker futures are cleared).
- Completed play-on-mount (`#immediate`) animations no longer replay when an
  inherited dependency (e.g. `HyperEffectsAnimationConfig`) changes.
- Migrated deprecated `EquatableMixin` and `Matrix4.translate`/`scale`
  usages to their replacements.

### Removed (BREAKING)
These were removed outright, with no deprecation window. The timeline API
replaces all of them.

- The `equatable` dependency. Effects and `TimelineSegment` now implement
  `==`, `hashCode`, and `toString` directly, with identical semantics
  (including deep list comparison for `ColorFilterEffect.matrix`). Only
  affects consumers who relied on hyper_effects to transitively provide
  `equatable`.
- The unused `collection` dependency (its only consumer was the removed
  `AnimatedGroup`).

- `AnimatedGroup` / `AnimatedChild` (experimental) — removed after review
  found removed children were never disposed (subtrees kept ticking
  indefinitely), removal re-ran `initState` on exiting children, slots only
  ever grew, and reordering was not actually animated. Use
  `AnimatedSwitcher`/`AnimatedSize` with `.roll()` for the same effects.
- `AnimatedEffectStateRetainer` (experimental) — removed after review found
  it recorded "was mounted" as "has played", fabricating end states for
  never-played keyed animations on any dependency change, freezing looping
  animations on remount, and never evicting recycled keys. Track played
  items yourself with `skipIf: () => !played.add(index)`.

- `.animateAfter()` and the entire `AnimationTriggerType` enum (including
  `AnimationTriggerType.afterLast`) — chained segments composed as stacked
  transforms, could not rest at their declared values, replayed
  inconsistently, and severed on `skipIf`/`playIf`.

  **Migration:** declare the sequence as timeline keyframes. Before:
  ```dart
  icon
      .scale(1.5).animate(trigger: done, duration: const Duration(milliseconds: 350))
      .scale(1 / 1.5) // reciprocal needed to undo the first segment
      .animateAfter(duration: const Duration(milliseconds: 300))
      .resetAll();
  ```
  After:
  ```dart
  icon
      .scale(0)
      .step(duration: const Duration(milliseconds: 350))
      .scale(1.5)
      .step(duration: const Duration(milliseconds: 300))
      .scale(1) // absolute — no reciprocals
      .timeline(trigger: done);
  ```
  Replace `resetAll` looping with `.timeline(trigger: #immediate, repeat: -1)`,
  and reverse-on-dismiss patterns with `TimelineController.reverse()`.

- `.oneShot()` — replaced by `.immediate()`, which has the same
  play-once-on-mount semantics.

  **Migration:** `.oneShot(...)` → `.immediate(...)`, or
  `.animate(trigger: #immediate, ...)`.

- `AnimationStartState.playImmediately`, `.useCurrentValues` and `.idle` —
  the enum is now `{eager, lazy}`, and start state no longer doubles as a
  play-on-mount switch.

  **Migration:**
  - `startState: AnimationStartState.playImmediately` →
    `trigger: #immediate` (or `.immediate()`), dropping `startState`.
  - `startState: AnimationStartState.useCurrentValues` →
    `startState: AnimationStartState.eager`.
  - `startState: AnimationStartState.idle` →
    `startState: AnimationStartState.lazy` (also the new default, so it can
    simply be dropped).

### Deprecated
- `.resetAll()`, `ResetAllAnimationsEffect` and
  `ResetAllAnimationsEffectState` — auto-resetting chains fire on every
  completion and cross-talk between unrelated animations. Loop with
  `.timeline(repeat: -1)` or rewind with `TimelineController.seek(0)`
  instead. They will be removed in 0.5.0.

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
