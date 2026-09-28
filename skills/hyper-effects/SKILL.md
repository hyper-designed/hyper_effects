---
name: hyper-effects
description: Use when building or troubleshooting Flutter UI with package:hyper_effects, including state-driven animation, mount entrances, springs, rolling text, layout size, hover/press feedback, scroll transitions, timelines, TimelineController, keyframe sequencing, loops, or migration to version 0.4.0.
---

# Hyper Effects

For Hyper Effects **0.4.0**. Check the consuming app's resolved version before applying this reference; older releases have different APIs.

## Choose the driver

| Intent | API |
| --- | --- |
| Static appearance | Effect extensions without a driver |
| React to state or replay an event | `.animate(trigger: value)` |
| Entrance once per mounted State | `.immediate()` |
| Entrance and later trigger changes | `.animate(trigger: value, startState: AnimationStartState.eager)` |
| Sequential absolute keyframes | `.step(...).timeline(...)` |
| Pointer or scroll response | `.pointerTransition(...)` / `.scrollTransition(...)` |

Effects wrap widgets. An animation drives its descendant effect scope; nested drivers create independent scopes, not a sequence. Keep widget identity stable across state changes.

Use widget classes for reusable UI, not widget-returning helper functions. The short example below belongs inside `build`, with Flutter material and Hyper Effects imported.

```dart
return Text('$count')
    .roll(widthCurve: Curves.easeOut)
    .animate(trigger: count, duration: const Duration(milliseconds: 250));
```

`Text.roll()` reads the receiver's current text and retains its previous value. It takes **named options only**, not a replacement string. Call it before other extensions erase the receiver's `Text` type. For arbitrary widgets, use `Widget.roll()` with distinct child keys; its options are `slideInDirection`, `slideOutDirection`, `multiplier`, and `useSnapshots`.

## Contracts to preserve

- `trigger` changes use equality comparison. Use an incrementing integer for repeated events; repeatedly assigning `true` is not a new event.
- Default `lazy` mounts at starting values and waits. `eager` plays on mount and keeps the trigger live. `#immediate` occupies the trigger slot; ordinary rebuilds do not replay it, but a new State does.
- Use explicit `from:` for deliberate entrances/replays. For ordinary retargeting, preserve effect identity and derive the destination and trigger from state; do not blindly add a fixed origin.
- Choose `motion:` **or** `duration:`/`curve:`, never both. Cupertino spring duration is perceptual, not exact settling time.
- True vector springs support translation, scale, rotation, opacity, padding, alignment and size. Blur, clipping and other non-vector effects use a normalized interpolation fallback: no guaranteed physical overshoot or velocity handoff. Prefer curved motion when that distinction matters.
- `playIf: false` does not drive to the destination. `skipIf: true` jumps there without playback **or `onEnd`**. Reduced-motion entrances generally need the latter; completion-dependent UI needs an explicit skipped path.
- Layout: `.widthTo()`, `.heightTo()`, `.sizeTo()`, `.sizeOf()` change layout; `.scale()` changes paint. Null size axes/factors represent layout modes, not zero-sized endpoints.
- Translation hit tests move by default, but ancestor bounds still constrain hit testing. Hidden controls need an interaction policy such as `IgnorePointer`.

Read [recipes and pitfalls](references/recipes.md) for effects and interaction. For sequencing, loops, scrubbing, or migration from animateAfter, read [timelines](references/timelines.md). Verify snippets with `flutter analyze` and widget tests in the consuming package. Test mount, retrigger, interruption, reduced motion and actual tap positions where relevant. Use finite pumps for infinite loops.
