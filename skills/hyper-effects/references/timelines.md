# Hyper Effects Timelines

For **0.4.0**. Verify the resolved package version. A timeline compiles absolute effect keyframes onto one controller; nested `.animate()` calls are independent scopes, not a sequence.

```dart
// Inside build, with Flutter material and Hyper Effects imported.
return const Icon(Icons.check)
    .scale(0)
    .step(duration: const Duration(milliseconds: 250))
    .scale(1.2)
    .step(duration: const Duration(milliseconds: 180))
    .scale(1)
    .timeline(trigger: trigger);
```

## Keyframe rules

- Effects before the first `.step()` define the initial keyframe. Each step specifies travel to the next keyframe. Its `delay` holds the preceding frame.
- Values are absolute; do not use reciprocal scales to undo prior keyframes.
- Omitted effect types carry forward. Each type may appear once per keyframe. `.translateX()` and `.translateY()` are both TranslateEffect: combine them with `.translateXY()`. Likewise combine size axes with `.sizeTo()` or `.sizeOf()`.
- Use step `motion:` OR `duration:`/`curve:`, not both. Spring steps have computed settling duration; do not promise animate-style velocity handoff between timeline segments.
- A changed trigger restarts forward regardless of its value. `false` does not mean reverse. `#immediate` starts once per mounted State.

## Playback reference

| Intent | Operation |
| --- | --- |
| Three total trigger-driven cycles | `.timeline(trigger: value, repeat: 2)` |
| Infinite auto-play | `.timeline(trigger: #immediate, repeat: -1)` |
| Forward from current position | `controller.play()` |
| Restart imperatively | `controller.seek(0); controller.play();` |
| Reverse from current position | `controller.reverse()` |
| Freeze / scrub | `controller.pause()` / `controller.seek(0.5)` |

`repeat` counts additional **full forward cycles** on trigger-driven runs, not imperative `play()`. Finite cycles rest at the final frame; `onEnd` fires at the true end, not each cycle. A repeating sequence needs nonzero duration. Match first/last keyframes for a seamless loop.

## Ownership and mistakes

Create the controller once in its owner, pass it to `.timeline(controller:)`, and dispose it with the owner. No caller ticker provider is needed. `isAttached` is safe before mount; `progress` and driving methods require attachment and throw StateError otherwise. Treat one handle as controlling one mounted timeline.

For directional state changes use explicit play/reverse calls after attachment, not a boolean trigger expecting automatic reversal. Preserve widget identity. Infinite loops cannot use `pumpAndSettle`; advance finite durations in tests.

The controller and migration recipes below provide a complete example. Validate keyframe endpoints, delay holds, retriggers and reversal with widget tests rather than assuming a compiling chain is correct.

## Recipes

## Owned controller

```dart
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class RevealDemo extends StatefulWidget {
  const RevealDemo({super.key});

  @override
  State<RevealDemo> createState() => _RevealDemoState();
}

class _RevealDemoState extends State<RevealDemo> {
  final controller = TimelineController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Saved')
              .opacity(0)
              .translateY(24)
              .step(duration: const Duration(milliseconds: 250))
              .opacity(1)
              .translateY(0)
              .timeline(controller: controller),
          FilledButton(
            onPressed: () {
              if (!controller.isAttached) return;
              controller.play();
            },
            child: const Text('Show'),
          ),
          OutlinedButton(
            onPressed: () {
              if (!controller.isAttached) return;
              controller.reverse();
            },
            child: const Text('Hide'),
          ),
        ],
      );
}
```

Play resumes forward; if already at the end it is not a restart. Call `seek(0)` first when restart is intended. Keep the controller outside `build`, and do not share one controller between simultaneously mounted timelines.

This snippet illustrates manual playback, not a reduced-motion policy. A timeline does not accept animate's `skipIf` or `playIf`. For an explicit no-motion path, render the appropriate final/static state instead of constructing an auto-looping timeline, or seek an attached controller to the desired endpoint. Preserve required semantic actions independently of animation callbacks.

## Multi-track keyframes

```dart
return child
    .translateXY(0, 40)
    .opacity(0)
    .step(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      delay: const Duration(milliseconds: 100),
    )
    .translateXY(0, 0)
    .opacity(1)
    .step(duration: const Duration(milliseconds: 150))
    .translateXY(8, 0)
    .timeline(trigger: trigger);
```

The initial frame holds for 100 ms, then translation and opacity travel together. Opacity remains 1 in the last frame because it was omitted there. `.translateX().translateY()` in one frame is a duplicate type, not two tracks.

## Loop

```dart
return child
    .scale(1)
    .step(duration: const Duration(milliseconds: 300))
    .scale(1.1)
    .step(duration: const Duration(milliseconds: 300))
    .scale(1)
    .timeline(trigger: #immediate, repeat: -1);
```

`repeat: 2` would run three complete cycles and stop at scale 1. Do not await settlement in tests of the infinite form. Verify progress with bounded pumps, then unmount to stop it.

## Migration

Replace old `.animateAfter()` chains with explicit starting/ending keyframes separated by `.step()`. Replace reciprocal values such as scale `1 / 1.5` with the intended absolute value `1`. Replace `.resetAll()` looping with `repeat:`; use `seek(0)` for an explicit rewind.

Do not translate a chain of independent hover/visibility `.animate()` groups into a timeline merely because it has more than one driver. A timeline is for ordered steps; independent reactions should remain independent.

## Verification checklist

- Initial values appear before the trigger changes.
- A changed trigger replays forward, including true-to-false changes.
- Delay holds the preceding keyframe.
- Missing tracks carry forward and duplicate types are rejected.
- Finite repeat finishes at the last frame; imperative play starts at current progress.
- Reverse is driven explicitly, and detached access is guarded.
- Infinite animation is bypassed under the app's explicit reduced-motion policy.

## References

- [Timeline source](https://github.com/hyper-designed/hyper_effects/tree/main/lib/src/timeline)
- [Release migration notes](https://github.com/hyper-designed/hyper_effects/blob/main/CHANGELOG.md)
- [Agent Skills specification](https://agentskills.io/specification)

Verify against the installed package when the repository's main branch differs from the consumer's resolved version.
