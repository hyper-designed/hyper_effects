![Hyper Effects](https://raw.githubusercontent.com/hyper-designed/hyper_effects/main/.github/assets/banner.png)

# Hyper Effects

[![Pub Version](https://img.shields.io/pub/v/hyper_effects?label=Pub)](https://pub.dev/packages/hyper_effects)

**Composable effects, spring animations, and keyframe timelines for Flutter.**
Want a favorite button to bounce when tapped? A feed of cards to blur, tilt, and come into focus as you scroll? A card to slide into view? A checkmark to pop, overshoot, and settle? Start with your Flutter widget, add the effects you want after it, and tell them when to move. Hyper Effects takes inspiration from SwiftUI's modifier syntax, while keeping everything in Flutter's widget tree.

[Live demo](https://hyper-effects-demo.web.app/) · [API reference](https://pub.dev/documentation/hyper_effects/latest/) · [Examples](example/lib/stories) · [Migration notes](CHANGELOG.md)

## Quick start

Add this package to your dependencies in your pubspec.yaml file.

```yaml
dependencies:
  hyper_effects: <latest_version>
```

After publication, use `hyper_effects: ^0.4.0` instead. For reproducible development builds, pin a commit rather than a moving branch.

Let's start with a favorite button. When you tap it, the heart grows a little; tap it again, and it returns to its normal size. We don't need to manage an animation controller for this. Describe the two sizes and let a spring handle the journey.

```dart
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({super.key});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return IconButton(
      tooltip: selected ? 'Remove favorite' : 'Add favorite',
      onPressed: () => setState(() => selected = !selected),
      icon: Icon(selected ? Icons.favorite : Icons.favorite_border)
          .scale(selected ? 1.2 : 1)
          .animate(
            trigger: selected,
            motion: const CupertinoMotion.snappy(),
            skipIf: () => reduceMotion,
          ),
    );
  }
}
```

## Guide

- [Choose a driver](#choose-a-driver)
- [Scroll effects](#scroll-effects)
- [Effects, state, and triggers](#effects-state-and-triggers)
- [Motion with curves and springs](#motion-with-curves-and-springs)
- [Entrances and stagger](#entrances-and-stagger)
- [Timelines](#timelines)
- [Practical recipes](#practical-recipes)
- [Effect catalog](#effect-catalog)
- [Accessibility and lifecycle](#accessibility-and-lifecycle)
- [Agent skill](#agent-skill)

## Choose a driver

Most animations start with a simple question. **What should make this move?** A tap, a widget appearing, and a finger scrolling are different signals. You don't need to learn every API before starting. Pick the row that matches what you're building.

| I want to… | Use |
| --- | --- |
| Apply an effect without animation | `.opacity()`, `.scale()`, `.pad()`, etc. |
| Animate when state changes | `.animate(trigger: state)` |
| Replay an animation for each event | `.animate(trigger: eventCount)` |
| Play an entrance on mount | `.immediate()` |
| Play on mount and respond to later changes | `.animate(trigger: state, startState: AnimationStartState.eager)` |
| Sequence several keyframes | `.step(...).timeline(...)` |
| Reverse, pause, or scrub a sequence | `TimelineController` |
| Respond to hover, press, or scrolling | `.pointerTransition(...)` / `.scrollTransition(...)` |

## Scroll effects

Scrolling can do much more than move a list up and down. Imagine cards coming into focus as they enter the screen, drifting sideways as they leave, or tilting around a wheel as you browse. The movement follows your finger rather than a timer. Stop scrolling and it stops. Scroll back and it retraces your movement.

<table>
  <tr>
    <td align="center"><img src="https://raw.githubusercontent.com/hyper-designed/hyper_effects/main/.github/assets/scroll_transition.gif" width="200" alt="Cards changing appearance as they cross the viewport edges"><br>Make an entrance</td>
    <td align="center"><img src="https://raw.githubusercontent.com/hyper-designed/hyper_effects/main/.github/assets/scroll_blur.gif" width="200" alt="Scrolling cards blurring near the viewport edges"><br>Bring cards into focus</td>
    <td align="center"><img src="https://raw.githubusercontent.com/hyper-designed/hyper_effects/main/.github/assets/scroll_wheel.gif" width="200" alt="List items rotating through a three-dimensional wheel"><br>Give the list some depth</td>
  </tr>
</table>

[Try the scroll demos](https://hyper-effects-demo.web.app/) to feel how they respond to your movement.

### Start with a list that comes into focus

Suppose you're building a feed of cards. You want the card you're reading to look normal, while cards crossing the screen's edges become slightly smaller and softer. Add `.scrollTransition()` to each card inside the list, rather than to the list itself.

This complete widget can be used as a screen's body. It uses the same Flutter material and Hyper Effects imports as the quick start.

```dart
class ScrollingCards extends StatelessWidget {
  const ScrollingCards({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ListView.builder(
      itemCount: 30,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            height: 160,
            child: Center(child: Text('Card ${index + 1}')),
          ),
        ).scrollTransition((context, child, event) {
          if (reduceMotion) return child;
          return child
              .opacity(event.phase.isIdentity ? 1 : 0.4)
              .blur(event.phase.isIdentity ? 0 : 4)
              .scale(event.phase.isIdentity ? 1 : 0.92);
        });
      },
    );
  }
}
```

Notice what's missing. There's no animation controller, no trigger, and no `.animate()`. The transition finds the enclosing scrollable and supplies progress as the card crosses its viewport. Your builder gets the original child and an event describing where it is.

The values in that builder describe the appearance to move toward. They aren't an instruction to instantly blur the card the moment it touches an edge. The transition interpolates the effects according to how far the card crosses that edge, so a partially visible card can be partway through its fade, blur, and scale at the same time.

### Give entering and leaving cards different personalities

A card can be fully inside the viewport, crossing its top edge, or crossing its bottom edge. Those are the three scroll phases. In a horizontal list, the corresponding edges are left and right.

| Phase | Where the card is |
| --- | --- |
| `ScrollPhase.identity` | Fully inside the viewport |
| `ScrollPhase.topLeading` | Crossing the top or left edge |
| `ScrollPhase.bottomTrailing` | Crossing the bottom or right edge |

Imagine new cards arriving from the left at the bottom of a vertical feed, then slipping right as they leave the top. Instead of giving both edges the same appearance, choose a different horizontal offset for each phase. Use this on an item inside your scrollable, with `reduceMotion` read from `MediaQuery` as above.

```dart
return child.scrollTransition((context, child, event) {
  if (reduceMotion) return child;
  return child
      .translateX(switch (event.phase) {
        ScrollPhase.identity => 0,
        ScrollPhase.topLeading => 48,
        ScrollPhase.bottomTrailing => -48,
      })
      .scale(event.phase.isIdentity ? 1 : 0.95);
});
```

The phase describes the card's position, not which way your finger is moving. A card crossing the top edge stays in `topLeading` whether it's leaving the viewport or coming back into it. That's why the movement naturally reverses when you scroll back without needing a second animation.

At the scroll extent's start or end, the implementation suppresses the corresponding edge progress. This keeps boundary items from being forced into an edge effect when you can't scroll any farther to reveal them.

### Turn the list into a wheel

Edge effects are a good starting point, but sometimes you want an item to keep changing throughout its journey across the viewport. Think of a wheel picker. An item tilts one way near the bottom, faces you in the middle, and tilts the other way near the top.

`screenOffsetFraction` gives you a continuous position for that. It is zero when the item's center lines up with the viewport's center, positive toward the top or left, and negative toward the bottom or right. An item's center at a viewport edge corresponds to roughly 1 or -1. Cached items outside the viewport can go beyond that range, so clamp it when your effect needs bounded values.

Here we calculate the transform directly. Add `import 'dart:math' show pi;` alongside the usual imports, and use this in an item's `build` method under a scrollable.

```dart
return child.scrollTransition((context, child, event) {
  if (reduceMotion) return child;
  final position = event.screenOffsetFraction.clamp(-1.0, 1.0).toDouble();
  return TransformEffect(
    rotateX: -position * pi / 3,
    scaleX: 1 - position.abs() * 0.15,
    scaleY: 1 - position.abs() * 0.15,
    depth: 0.002,
  ).apply(context, child);
});
```

At the center, the item faces you at full size. Toward either edge, it becomes smaller and tilts away. The `depth` adds perspective so the rotation reads as a three-dimensional movement instead of a flat squash. For a horizontal wheel, you can use `rotateY` and experiment with the rotation's sign.

Why use `TransformEffect.apply()` here instead of the `.transform()` extension? We've already calculated the exact transform for this scroll position. Applying it directly uses those values as they are. An effect extension inside the transition would interpolate them again using edge progress, which isn't what this wheel needs.

That distinction is worth remembering. Use the extensions when you're describing a pose for each phase. Use an effect's `.apply(context, child)` when you've calculated the current appearance yourself from continuous event values.

### Know what the scroll event gives you

You don't need every field to get started. `phase` handles edge-based effects, and `screenOffsetFraction` handles movement across the whole viewport. The remaining fields let you explore more specific ideas without wiring up your own scroll listener.

| Field | What you can use it for |
| --- | --- |
| `phase` | Choose the appearance at each viewport edge |
| `phaseOffsetFraction` | Inspect the progress used for phase interpolation; fully visible items report 1, so this isn't a single start-to-finish journey value |
| `screenOffsetFraction` | Calculate continuous tilt, scale, or displacement relative to the viewport center |
| `scrollPixels`, `viewportSize` | Work with the scroll offset and viewport extent; both are nullable before their metrics are available |
| `scrollDelta` | Compare the current scroll offset with the previous update |
| `scrollDirection` | Read the scrollable's configured axis direction, not the user's current gesture direction |
| `pointerPosition`, `distanceFromPointer` | Incorporate the last tracked pointer position and its offset from the item's center |
| `visualIndex`, `reverseVisualIndex` | Explore position-based ordering effects; these are geometry-derived values, not stable item IDs |

### Keep the content comfortable to browse

Start small. A slight scale change or gentle fade often does enough without making a feed harder to read. Blur and perspective look striking in demos, but try them on a real device with the number of cards your screen actually shows.

Keep the transition on the item under the intended scrollable. It uses the nearest enclosing scrollable, so a card inside a horizontal carousel responds to that carousel rather than an outer vertical feed. Without an enclosing scrollable, it simply displays its child.

The examples return the unchanged child when reduced motion is requested. Scroll effects aren't timed entrances, so there isn't an `.immediate(skipIf:)` to lean on here. Make that choice in the builder, and keep controls usable while their appearance changes.

For more ideas, explore the demo's [directional slide](example/lib/stories/scroll_phase_slide.dart), [blur](example/lib/stories/scroll_phase_blur.dart), [3D wheel](example/lib/stories/scroll_wheel_transition.dart), and [color filter](example/lib/stories/color_filter_scroll_transition.dart) stories.

## Effects, state, and triggers

Think of effects as instructions about how a widget should look. You might want it a little transparent, a little bigger, or a few pixels lower. By themselves, they don't animate anything. This child is simply half-transparent and shifted down eight logical pixels.

```dart
return child.opacity(0.5).translateY(8);
```

Now imagine a selectable card. When selected, it should grow slightly and lift off the page. We describe the selected and unselected appearances, then add `.animate()` to move between them.

```dart
return child
    .scale(selected ? 1.08 : 1)
    .translateY(selected ? -4 : 0)
    .animate(trigger: selected, motion: const CupertinoMotion.snappy());
```

Notice that `selected` does two jobs. It chooses the card's destination, and it tells `.animate()` when something has changed. The trigger is a **change signal**, not an on/off switch. Selecting the card triggers a run, but so does deselecting it. Internally, the new trigger is compared with the previous one using equality.

An unrelated rebuild won't make the card bounce again if `selected` hasn't changed. That's useful for selection, but what about shaking a field on *every* invalid submission? A boolean that stays `true` won't do that. Use an event counter instead. We'll do exactly that in the [feedback recipe](#replay-feedback-on-every-event).

You'll also see `from:` in entrance examples. It gives the effect a deliberate starting point. For example, a card can arrive at zero after starting 24 pixels below. Use it when you want that origin, rather than adding it automatically to every state change. Keep widget keys stable while animating between states, too; changing the key can replace the State instead of updating it.

Finally, these chains are still nested Flutter widgets. An inner `.animate()` has its own effect scope, which is handy when a button needs hover feedback *and* an independent entrance. But adding a second `.animate()` doesn't mean “do this next.” For that, use a [timeline](#timelines).

### Mount behavior

Should the card wait until it's selected, or introduce itself as soon as it appears? That's the choice here. Use the default `lazy` behavior to wait for a trigger change, `eager` to play an entrance and keep listening, or `.immediate()` for a mount-only entrance.

| Configuration | On mount | Later trigger changes |
| --- | --- | --- |
| `lazy` (default) | Holds starting values | Plays |
| `eager` | Plays from starting values | Plays |
| `.immediate()` / `trigger: #immediate` | Plays | The sentinel stays unchanged |

One detail is easy to miss. Both `lazy` and `eager` mount at the **starting** values. If you give a fade an explicit `from: 0`, `lazy` leaves it transparent until the trigger changes. It doesn't silently jump to opacity 1. If the widget should already look settled on its first frame, choose its initial endpoints to represent that state.

Play-on-mount is once per **State lifetime**, not once per item forever. Imagine a card that slides into view as you scroll down a feed. Scroll far enough away, and Flutter may dispose of it to save resources. When you scroll back, Flutter creates a fresh widget State, and `.immediate()` plays its entrance again. The card effectively has amnesia. It doesn't know you've already seen it.

If that's the experience you want, you're done! But if each card should only introduce itself once, keep a set of already-seen card IDs in the feed's parent State, outside the individual cards. Use `skipIf` to skip the entrance for IDs in that set, and record each ID when its first entrance is accepted. Now the feed remembers which cards you've seen, even when the cards themselves don't. That memory lasts as long as the parent State does.

### Playback options

What happens if someone taps again before the animation finishes? By default, the new trigger interrupts the current run. That is usually what you want for responsive controls. Set `interruptable: false` when runs should wait their turn instead. Here are the other knobs you can reach for when you need them.

| Option | Meaning |
| --- | --- |
| `delay` | Holds the run's starting values before playback; repeated legs each wait again |
| `interruptable: true` | A new trigger interrupts the active run |
| `interruptable: false` | Runs wait their turn rather than interrupting |
| `resetValues: true` | Uses initial effect values instead of ordinary state-to-state progression |
| `playIf` returning false | Does not drive the animation to the target |
| `skipIf` returning true | Jumps to the ending values without playback or `onEnd` |
| `onEnd` | Called once at the end of a completed logical animate run, not every repeated leg |

Think of a pulsing button. It grows, then shrinks back. That's two legs, so use `repeat: 1, reverse: true`. You get one initial leg and one extra leg in the opposite direction. `reverse: true` alone doesn't add a return trip.

On `.animate()` / `.immediate()`, `repeat` always counts **additional legs**. `0` plays once, `1` plays twice, and `-1` keeps going indefinitely. With `reverse: true`, those legs alternate direction.

## Motion with curves and springs

So far we've decided *where* a widget goes and *when* it should move. Motion answers the next question. **How should the trip feel?**

For a fade that should take exactly a quarter of a second, a duration and curve are a good fit. The duration sets the clock; the curve decides how quickly the fade progresses along the way.

Choose **either** `motion:` **or** `duration:` / `curve:`. They are two ways to describe timing, not settings to combine; passing both throws.

```dart
return child
    .opacity(1, from: 0)
    .animate(
      trigger: trigger,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
```

The equivalent motion object is `CurvedMotion(duration, curve)`. With no overrides, the curved default is 350 ms with `appleEaseInOut`.

A spring feels different. Think of a selected tab sliding into place, passing its destination just a little, and settling back. Rather than prescribing every moment of that movement, you choose the spring's character. Start with a preset.

| Motion | Useful for |
| --- | --- |
| `CupertinoMotion.smooth()` | No-bounce settling |
| `CupertinoMotion.snappy()` | Quick response with a little bounce |
| `CupertinoMotion.bouncy()` | Visible overshoot |
| `CupertinoMotion.interactive()` | Tight interaction feedback |
| `MaterialSpringMotion.standardSpatialDefault()` | Material spatial motion |
| `MaterialSpringMotion.standardEffectsDefault()` | Critically damped visual-property motion |
| `SpringMotion(SpringDescription(...))` | Custom spring physics |

Want a little more personality? Cupertino presets accept `duration:` and `extraBounce:`. Just don't treat that duration as a stopwatch. It describes how the spring feels, **not the exact time until it settles**. If another piece of UI must start precisely 250 ms later, choose curved motion. `Motion.effectiveDuration` gives a spring's computed settling bound when you need it.

Imagine tapping between tabs before the selection indicator has finished moving. You don't want it to lose all its momentum each time you change your mind. Translation, scale, rotation, opacity, padding, alignment, and size implement `VectorEffect`, so spring-driven `.animate()` can carry that momentum into the new movement. Rendering still has limits. Opacity stays in range, and padding can't become negative.

Not every effect speaks that physics language. Blur and clipping, for example, use a normalized interpolation fallback. They can follow the spring's progress, but don't get the same guaranteed overshoot or velocity handoff. You'll see a debug diagnostic once per affected effect type. If that distinction matters for your animation, use curved motion. If you are building your own effect, you can implement `VectorEffect` instead.

## Entrances and stagger

Imagine opening a screen with a row of cards. Having every card appear at the same instant is fine, but letting them arrive one after another can make the screen easier to follow. Give each card the same entrance and a slightly larger delay.

Here, `index` is the card's position and `reduceMotion` comes from `MediaQuery.disableAnimationsOf(context)`. As with the earlier snippets, this goes directly in `build`.

```dart
return child
    .opacity(1, from: 0)
    .translateY(0, from: 24)
    .immediate(
      motion: const CupertinoMotion.smooth(),
      delay: Duration(milliseconds: 60 * index),
      skipIf: () => reduceMotion,
    );
```

The first card starts right away, the second waits 60 ms, the third waits 120 ms, and so on. Each fades in while moving up from 24 pixels below its destination. During its delay, it stays at its starting values. It doesn't flash into its final position while waiting.

These are independent entrances with different delays, not a group controller. If a card should introduce itself *and* react to later state changes, keep a real trigger and use `startState: AnimationStartState.eager` instead of `.immediate()`.

## Timelines

Sometimes “move from here to there” isn't enough. Picture a success checkmark. It starts invisible, pops up slightly too large, then settles to its normal size. Those are three distinct poses, in a deliberate order.

A timeline lets you describe those poses as **absolute keyframes**. Put `.step()` between them to say how to reach the next pose, then add `.timeline()` to drive the sequence.

```dart
return const Icon(Icons.check, size: 64)
    .scale(0)
    .opacity(0)
    .step(duration: const Duration(milliseconds: 250), curve: Curves.easeOut)
    .scale(1.2)
    .opacity(1)
    .step(duration: const Duration(milliseconds: 180), curve: Curves.easeOut)
    .scale(1)
    .timeline(trigger: trigger);
```

Read that chain as a little storyboard. Start at scale 0 and opacity 0. Take 250 ms to reach scale 1.2 and opacity 1, then take 180 ms to settle at scale 1. We didn't specify opacity again in the final pose, so it stays at 1.

The important word is *absolute*. The last `scale(1)` means “normal size,” not “multiply the previous size by 1.” You don't have to undo the overshoot with a reciprocal. Each `.step()` describes travel **to the next keyframe**; give it a delay if you want to hold the current pose first.

A few rules keep the storyboard unambiguous.

- Each keyframe can contain one effect of each type. To move diagonally, use `.translateXY()` rather than separate X/Y translations, which are both the same effect type.
- A trigger change always restarts **forward**. Setting a boolean to false doesn't tell the checkmark to un-pop; use a controller to reverse it.
- Timeline `repeat: n` means **n additional full cycles**, rather than animate's individual legs. `repeat: -1` loops forever and needs a nonzero-duration sequence.

For a gentle repeating pulse, grow the widget and bring it back to its original size. Matching the first and last poses avoids a jump when the next cycle starts.

```dart
return child
    .scale(1)
    .step(duration: const Duration(milliseconds: 300))
    .scale(1.1)
    .step(duration: const Duration(milliseconds: 300))
    .scale(1)
    .timeline(trigger: #immediate, repeat: -1);
```

### Imperative control

Now imagine a toast that slides up when you show it and slides back down when you dismiss it. You already have the entrance. Why describe the same movement backward by hand? Attach a `TimelineController` and play that sequence in either direction.

Create the controller once in your State, not in `build`, and dispose it when its owner is disposed. You don't need to supply a ticker provider. Pass that controller into the chain.

```dart
return child
    .opacity(0)
    .translateY(24)
    .step(duration: const Duration(milliseconds: 250))
    .opacity(1)
    .translateY(0)
    .timeline(controller: controller);
```

Call `play()` to show the toast and `reverse()` to send it back. Both start from wherever the timeline currently is, so reversing halfway through doesn't first jump to the end.

You can also `pause()`, `seek(0.5)` to jump halfway through, or read `progress`. Want a fresh replay rather than continuing from the current position? Call `seek(0)` before `play()`. The widget's `repeat:` setting belongs to trigger-driven runs; an imperative `play()` doesn't start that repeat schedule.

If the toast might not be mounted, check `isAttached` before driving the controller or reading `progress`. An unattached controller has no timeline to control and throws on those operations.

See the [self-contained controller recipe](skills/hyper-effects/references/timelines.md) for ownership and migration details.

## Practical recipes

### Replay feedback on every event

Someone submits an empty field. It shakes. They submit it again without changing anything. It should shake again, right? This is where an event counter works better than an `isInvalid` boolean.

```dart
return child
    .shake()
    .animate(trigger: attempt, duration: const Duration(milliseconds: 350));
```

Increment `attempt` on each invalid submission. The field can stay invalid the whole time, but `attempt` changes from 0 to 1 to 2, giving each submission its own trigger. Repeatedly assigning `isInvalid = true` would only give you the first change.

### Hover and press feedback

A button can feel more responsive with a small lift when you hover and a little compression when you press. The pointer event tells us which state we're in; we choose a scale and let a tight spring follow it.

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

This dresses up the button; it doesn't replace it. Keep the real button responsible for clicks, keyboard activation, semantics, and whether it's disabled. A disabled button should use a neutral scale rather than inviting a press it won't accept. This feedback can live in its own animation scope while an outer animation handles the button's entrance or visibility.

### Animate layout, not just pixels

Imagine a compact chip expanding to show a longer label. Scaling it would stretch the lettering. Its neighbors wouldn't make room either, because Flutter would still lay out the original-sized box. What you want here is a change in width.

```dart
return child
    .widthTo(expanded ? 240 : 120)
    .animate(trigger: expanded, motion: const CupertinoMotion.bouncy());
```

Now the chip's layout width changes from 120 to 240, so its siblings can move out of the way instead of being painted over. Use `.heightTo()` for height, `.sizeTo(Size(...))` for both dimensions, or `.sizeOf(width:, height:)` when you need to control each axis independently.

The parent still gets a say. These effects respect incoming constraints. Use finite numeric endpoints for animated dimensions. A null axis means “leave this unconstrained,” not “zero pixels,” so switching between null and a number snaps instead of animating an imaginary size in between.

### Rolling text and replacement widgets

Think of a score counter ticking upward, with the digits rolling into place instead of abruptly changing. Build the `Text` with the current count, then let `.roll()` handle the transition from the previous value.

```dart
return Text('$count')
    .roll(widthCurve: Curves.easeOut)
    .animate(trigger: count, duration: const Duration(milliseconds: 250));
```

You can roll whole widgets, too. Here an hourglass gives way to a checkmark. Give each piece of content a distinct key so the effect knows something was replaced.

```dart
return KeyedSubtree(
      key: ValueKey(done),
      child: Icon(done ? Icons.check : Icons.hourglass_empty),
    ).roll(slideInDirection: AxisDirection.up).animate(trigger: done);
```

You don't pass the old and new strings to `Text.roll()`. It reads the current `Text` and retains the previous value for you. Call it before other widget extensions, while the receiver is still typed as `Text`. This effect is meant for short, single-line labels and numbers. A paragraph rolling through a slot machine is probably not what you want. Multiline text isn't supported.

For more control, text rolling offers `tapeStrategy`, `TextTapeSlideDirection`, integer `staggerSoftness`, and `widthCurve`. That last one controls how character widths change, so it belongs on `.roll()`, not `.animate()`. Whole-widget rolling works differently. It watches child keys, which is why the hourglass and checkmark need different ones.

## Effect catalog

Once you know the pattern, changing the effect is the easy part. Here's a compact list to come back to when you know what you're trying to make.

| Purpose | Extensions |
| --- | --- |
| Visibility | `.opacity()`, `.fadeIn()`, `.fadeOut()` |
| Transform | `.scale()`, `.translate()`, `.translateX/Y/XY()`, `.rotate()`, `.rotateX/Y/Z()`, `.skewX/Y/XY()`, `.transform()` |
| Layout | `.pad()`, `.padAll()`, `.padOnly()`, `.align()`, `.alignX/Y/XY()`, `.widthTo()`, `.heightTo()`, `.sizeTo()`, `.sizeOf()` |
| Appearance | `.blur()`, `.colorFilter()`, `.clip()` |
| Feedback and content | `.shake()`, `Text.roll()`, `Widget.roll()` |

Rotation values are radians. Fractional translations multiply offsets by the child's size; non-fractional translations use logical pixels. `.align()` defaults to null width/height factors (fill available constraints); pass factors of `1` explicitly for shrink-wrapping.

You can also use effect classes directly with `.apply(context, child)`, or implement your own `Effect`. See [effect implementations](lib/src/effects) for the actual constructor signatures and vector arithmetic contract.

## Accessibility and lifecycle

### Let people skip the movement, not the content

If someone has requested reduced motion, a card should still appear. It just doesn't need to make an entrance. Read `MediaQuery.disableAnimationsOf(context)` and use `skipIf` when you want to jump straight to the ending values. `playIf: false` is different. It declines playback rather than moving the widget to its destination, which could leave an entrance hidden.

Skipping doesn't call `onEnd`, either. If that callback unlocks a control or performs cleanup, make sure your no-motion path handles that work too. Flutter's `animationBehavior` is also configurable, individually or through `HyperEffectsAnimationConfig`.

### A button should answer where you see it

Imagine translating a button upward but leaving its tappable area behind. That would be a pretty frustrating button! In 0.4.0, translation moves hit testing by default. Use `transformHitTests: false` only when you deliberately want paint-only movement.

There's still a boundary. Moving a child outside its parent's bounds doesn't expand where the parent accepts hits. Check taps at the button's *painted* position, especially when it overflows. And if you've faded a button out, remember that invisible doesn't mean untappable. Use `IgnorePointer` or another appropriate interaction policy.

### Give exits time to finish

A toast can't slide away after you've already removed it from the tree. Keep it mounted and ticking until its exit completes, then remove it or disable its background ticking. If someone shows it again halfway through dismissal, don't let an old completion callback hide the newly visible toast. Guard against stale callbacks and disposal, and handle skipped animations separately. The app owns this lifecycle; Hyper Effects doesn't automatically retain exiting children.

The same idea matters in tests. A pulse that loops forever will never settle. Advance it with bounded pumps rather than asking `pumpAndSettle` to wait for an ending that isn't coming.

## Agent skill

Working with a coding agent? Give it the same API knowledge you're learning here, rather than hoping it guesses the right version. The single **`hyper-effects`** skill covers effects, springs, entrances, interaction, scroll transitions, and timelines. Detailed recipes live inside the skill and load when needed, so there is no separate timeline skill to install.

### Claude Code

Install the skill as a Claude Code plugin from this repository. Run these commands inside Claude Code once the plugin files have been pushed to GitHub.

```text
/plugin marketplace add hyper-designed/hyper_effects
/plugin install hyper-effects@hyper-effects-marketplace
```

Choose user scope to make it available across your projects, or project scope to share the installation configuration with a team. In your consuming Flutter project, Claude can select the skill when it matches your request. You can also invoke it explicitly.

```text
/hyper-effects:hyper-effects
```

For a local checkout, start Claude Code with the repository as a local plugin directory. Replace the path with your checkout's location.

```sh
claude --plugin-dir /path/to/hyper_effects
```

The plugin uses the same `skills/hyper-effects/` files as other agents. There is no second copy to keep in sync. See the [Claude Code plugin documentation](https://code.claude.com/docs/en/plugins) for more about plugin installation.

### Other compatible agents

Install the same portable [Agent Skill](https://agentskills.io/specification) with the [Skills CLI](https://github.com/vercel-labs/skills).

```sh
npx skills add hyper-designed/hyper_effects --skill hyper-effects
```

For a local checkout, replace `hyper-designed/hyper_effects` with its local path. Alternatively copy `skills/hyper-effects/`, including its references, into your agent's skill directory. Choose the plugin or portable installation route for Claude Code, rather than installing both copies.

## Migrating from 0.3.x

Coming from 0.3.x? Some familiar patterns have changed, especially sequencing and mount behavior. The [0.4.0 changelog](CHANGELOG.md) includes migration guidance; these are the changes to check first.

- `.animateAfter()` is replaced by timeline keyframes; `.oneShot()` by `.immediate()`.
- Start states are now `lazy` and `eager`; both mount at starting values.
- `.resetAll()` is deprecated; use timeline repetition or controller seeking.
- Alignment defaults, translated hit testing, and spring-driven padding have changed.
- Experimental group/state-retainer APIs and the `equatable` / `collection` dependencies were removed.

## Contributing

You are welcome to contribute on this package.
See [CONTRIBUTING.md](https://github.com/hyper-designed/hyper_effects/blob/main/CONTRIBUTING.md) for details.

## Authors

<table>
  <tr>
    <td align="center"><a href="https://github.com/birjuvachhani"><img src="https://avatars.githubusercontent.com/u/20423471?s=100" width="100px;" alt=""/><br /><sub><b>Birju Vachhani</b></sub></a></td>
    <td align="center"><a href="https://github.com/SaadArdati"><img src="https://avatars.githubusercontent.com/u/7407478?v=4" width="100px;" alt=""/><br /><sub><b>Saad Ardati</b></sub></a></td>
  </tr>
</table>

Feel free to join our Discord server for any inquiries or support: https://discord.gg/yrahEhCqTJ

## License

```
BSD 3-Clause License

Copyright (c) 2023, Hyperdesigned

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

```
