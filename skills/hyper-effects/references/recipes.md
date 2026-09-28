# Recipes and pitfalls for Hyper Effects 0.4.0

Import `package:flutter/material.dart` and `package:hyper_effects/hyper_effects.dart`. Place the short snippets directly inside `build`. Their inputs are widget fields or local state. Extract reusable UI into widget classes, not widget-returning helper functions.

## State versus event

```dart
return child
    .scale(selected ? 1.08 : 1)
    .animate(trigger: selected, motion: const CupertinoMotion.snappy());
```

For an event (invalid submission, notification), increment a counter each time:

```dart
return child
    .shake()
    .animate(trigger: attempt, duration: const Duration(milliseconds: 350));
```

Do not replace a stable widget key on each event: that recreates State rather than triggering the existing animation.

## Entrance and delayed stagger

```dart
return child
    .opacity(1, from: 0)
    .translateY(0, from: 24)
    .immediate(
      delay: Duration(milliseconds: 60 * index),
      motion: const CupertinoMotion.smooth(),
      skipIf: () => reduceMotion,
    );
```

This is several independent entrances, not a coordinated timeline. Remounting replays; retain a set of stable item IDs outside item State if entrances should happen once per item across remounts.

To play on mount and keep responding later:

```dart
return child
    .scale(expanded ? 1.15 : 1, from: 0.8)
    .animate(
      trigger: expanded,
      startState: AnimationStartState.eager,
      motion: const CupertinoMotion.snappy(),
    );
```

Here the fixed `from:` deliberately specifies the starting scale. Omit it when a fixed replay origin is not wanted. For state-mirroring first-frame behavior, choose initial values deliberately; do not assume `lazy` means “render the target.”

A delay holds the run's starting values until playback begins. An `Interval` inside a `CurvedMotion` instead allocates a quiet portion of an already progressing controller. They are not interchangeable.

## Pointer feedback

```dart
return button.pointerTransition(
      (context, child, event) {
        final target = event.isPressed ? 0.96 : (event.isHovering ? 1.03 : 1.0);
        return child.scale(target).animate(
              trigger: target,
              motion: const CupertinoMotion.interactive(),
            );
      },
    );
```

Keep the actual button's onPressed/disabled/keyboard/semantics behavior. For disabled buttons return a neutral target. This is a separate animation scope from an outer entrance or visibility animation.

## Rolling text and widgets

```dart
return Text('$count')
    .roll(
      tapeSlideDirection: TextTapeSlideDirection.up,
      staggerSoftness: 10,
      widthCurve: Curves.easeOut,
    )
    .animate(trigger: count, duration: const Duration(milliseconds: 250));

return KeyedSubtree(
      key: ValueKey(done),
      child: Icon(done ? Icons.check : Icons.hourglass_empty),
    ).roll(slideInDirection: AxisDirection.up).animate(trigger: done);
```

Text options belong to `Text.roll()`, including `widthCurve` and `widthDuration`; they are not animate parameters. `staggerSoftness` is a positive integer. Use short single-line plain text, not multiline text or rich text. Preserve a semantics label for important numbers. Generic widget rolling detects child **key changes**, not just new widget instances.

## Layout-driven size

```dart
return child
    .widthTo(expanded ? 240 : 120)
    .animate(trigger: expanded, motion: const CupertinoMotion.bouncy());
```

Incoming constraints still apply. Prefer finite numeric endpoints. Null means unconstrained and a null/numeric pair snaps rather than numerically interpolating. `.align()` now defaults width/height factors to null; pass `1` explicitly to shrink-wrap. Padding floors negative insets at rendering time but can overshoot upward.

## Completion and accessibility

Read reduced-motion preferences with `MediaQuery.disableAnimationsOf(context)` when an explicit no-motion policy is required. `skipIf` jumps to the final state and does not call `onEnd`; it is not interchangeable with `playIf` or zero duration.

An exit needs its child mounted and ticking until completion. If the app retains the child afterward, gate ticking only after the exit finishes. Bind cleanup to the visibility animation, reject stale callbacks after visibility changes, and handle disposal and skipped animation separately. This is application lifecycle policy, not a built-in exit-retention feature.

Transforms do not expand ancestor hit-test bounds. Check taps at the painted position, not only the original box. An opacity of zero alone does not disable interaction.

## Version migration

- `.oneShot()` → `.immediate()`.
- `AnimationStartState.playImmediately` → `.eager`; `.idle` → `.lazy`.
- `useCurrentValues` has no direct enum replacement: express the desired initial state through effect endpoints.
- `.animateAfter()` → absolute keyframes separated by `.step()`, driven by `.timeline()`.
- `.resetAll()` is deprecated: prefer timeline repetition or `TimelineController.seek(0)`.
- `AnimatedGroup` / `AnimatedChild` and state-retainer APIs were removed; do not invent replacements with those names.

## References

- [Package source](https://github.com/hyper-designed/hyper_effects/tree/main/lib/src)
- [Release and migration notes](https://github.com/hyper-designed/hyper_effects/blob/main/CHANGELOG.md)
- [Agent Skills format](https://agentskills.io/specification)

The installed package source is authoritative when the main branch and the consuming app resolve different versions.
