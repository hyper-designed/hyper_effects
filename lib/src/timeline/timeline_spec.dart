import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../../hyper_effects.dart';

/// A marker widget that splits a timeline chain into segments.
///
/// Effects declared before a [TimelineStep] belong to the keyframe on its
/// inner side; effects declared after it belong to the next keyframe. The
/// step itself describes how the timeline animates from the former to the
/// latter: over [duration], along [curve], after waiting [delay].
///
/// This widget is consumed by the `.timeline()` extension and never renders
/// anything itself. If left uncompiled in a tree it renders its child
/// unchanged.
class TimelineStep extends StatelessWidget {
  /// How long the transition to the next keyframe takes.
  final Duration duration;

  /// The curve of the transition to the next keyframe.
  final Curve curve;

  /// A hold before this segment starts, during which the previous keyframe's
  /// values remain applied.
  final Duration delay;

  /// The widget below this step in the chain.
  final Widget child;

  /// Creates a [TimelineStep].
  const TimelineStep({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.curve = appleEaseInOut,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) => child;
}

/// Provides the chain methods that build up a timeline declaration.
extension TimelineChainExt on Widget {
  /// Marks the boundary between two keyframes of a timeline chain.
  ///
  /// Effects declared since the previous [step] (or since the start of the
  /// chain) form one keyframe; the effects declared after this call form the
  /// next. The transition between them runs for [duration] along [curve],
  /// starting after [delay] of holding the previous keyframe.
  Widget step({
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = appleEaseInOut,
    Duration delay = Duration.zero,
  }) =>
      TimelineStep(
        duration: duration,
        curve: curve,
        delay: delay,
        child: this,
      );
}

/// One segment of a compiled timeline: the transition between two adjacent
/// keyframes.
class TimelineSegment with Equatable {
  /// How long the transition takes.
  final Duration duration;

  /// The curve of the transition.
  final Curve curve;

  /// A hold before the transition starts.
  final Duration delay;

  /// Creates a [TimelineSegment].
  const TimelineSegment({
    required this.duration,
    required this.curve,
    required this.delay,
  });

  @override
  List<Object?> get props => [duration, curve, delay];
}

/// The keyframe values of a single effect type across an entire timeline.
class TimelineTrack {
  /// The runtime type of the [Effect] this track animates.
  final Type effectType;

  /// One value per keyframe; length is `segments.length + 1`.
  final List<Effect> keyframes;

  /// Creates a [TimelineTrack].
  const TimelineTrack({required this.effectType, required this.keyframes});
}

/// A compiled timeline: an ordered list of [TimelineSegment]s and the
/// per-effect-type [TimelineTrack]s that animate across them, all driven by
/// a single animation value.
class TimelineSpec {
  /// The transitions between adjacent keyframes, in play order.
  final List<TimelineSegment> segments;

  /// The per-effect-type keyframe tracks.
  final List<TimelineTrack> tracks;

  /// The content widget the effects apply to.
  final Widget child;

  /// Creates a [TimelineSpec].
  const TimelineSpec({
    required this.segments,
    required this.tracks,
    required this.child,
  });

  /// The total duration of the timeline: the sum of every segment's delay
  /// and duration.
  Duration get totalDuration => segments.fold(
        Duration.zero,
        (total, segment) => total + segment.delay + segment.duration,
      );

  /// Evaluates every track at linear time [t], where 0 is the start of the
  /// timeline and 1 is [totalDuration]. Values outside 0..1 clamp to the
  /// first/last keyframe. Returns one [Effect] per track, in track order.
  List<Effect> evaluate(double t) {
    final double clamped = t.clamp(0.0, 1.0);
    final int totalMicros = totalDuration.inMicroseconds;
    if (segments.isEmpty || totalMicros == 0) {
      return [for (final track in tracks) track.keyframes.last];
    }

    final double timeMicros = clamped * totalMicros;
    double cursor = 0;
    int index = segments.length - 1;
    double progress = 1;
    for (int i = 0; i < segments.length; i++) {
      final TimelineSegment segment = segments[i];
      final double delay = segment.delay.inMicroseconds.toDouble();
      final double duration = segment.duration.inMicroseconds.toDouble();
      final double end = cursor + delay + duration;
      if (timeMicros <= end || i == segments.length - 1) {
        index = i;
        if (timeMicros <= cursor + delay) {
          // Inside the delay window: hold the previous keyframe.
          progress = 0;
        } else if (duration == 0) {
          progress = 1;
        } else {
          progress = ((timeMicros - cursor - delay) / duration).clamp(0.0, 1.0);
        }
        break;
      }
      cursor = end;
    }

    final double curved = segments[index].curve.transform(progress);
    return [
      for (final track in tracks)
        track.keyframes[index].lerp(track.keyframes[index + 1], curved),
    ];
  }

  /// Compiles a declarative timeline chain into a [TimelineSpec].
  ///
  /// [root] is the outermost widget of the chain: the widget that
  /// `.timeline()` was called on. The chain is walked inward, collecting
  /// [EffectWidget]s into keyframes and splitting keyframes at every
  /// [TimelineStep], until the first widget that is neither — the content
  /// [child].
  static TimelineSpec compile(Widget root) {
    // Walk the chain from the outermost widget inward. The walk visits the
    // LAST keyframe first, and within a keyframe the LAST-declared effect
    // first, so both lists are reversed at the end.
    final List<Map<Type, Effect>> groups = [<Type, Effect>{}];
    final List<TimelineSegment> segments = [];
    Widget? current = root;
    while (true) {
      if (current is EffectWidget) {
        final Effect effect = current.end;
        final Map<Type, Effect> group = groups.last;
        if (group.containsKey(effect.runtimeType)) {
          throw FlutterError(
            'A timeline keyframe declared two ${effect.runtimeType}s. Each '
            'effect type may appear at most once per keyframe; separate them '
            'with a step() if you meant two keyframes.',
          );
        }
        group[effect.runtimeType] = effect;
        current = current.child;
      } else if (current is TimelineStep) {
        segments.add(TimelineSegment(
          duration: current.duration,
          curve: current.curve,
          delay: current.delay,
        ));
        groups.add(<Type, Effect>{});
        current = current.child;
      } else {
        break;
      }
    }
    final Widget child = current ?? const SizedBox.shrink();

    final List<Map<Type, Effect>> orderedGroups = groups.reversed.toList();
    final List<TimelineSegment> orderedSegments = segments.reversed.toList();

    // Track order: first appearance across keyframes, in declaration order
    // within a keyframe (the walk reversed it, so reverse back).
    final List<Type> types = [];
    for (final group in orderedGroups) {
      for (final type in group.keys.toList().reversed) {
        if (!types.contains(type)) types.add(type);
      }
    }

    final List<TimelineTrack> tracks = [];
    for (final type in types) {
      final List<Effect?> raw = [];
      Effect? last;
      for (final group in orderedGroups) {
        last = group[type] ?? last;
        raw.add(last);
      }
      // Keyframes before the type's first appearance idle at no-op values.
      final Effect idle = raw.firstWhere((effect) => effect != null)!.idle();
      tracks.add(TimelineTrack(
        effectType: type,
        keyframes: [for (final effect in raw) effect ?? idle],
      ));
    }

    return TimelineSpec(
      segments: orderedSegments,
      tracks: tracks,
      child: child,
    );
  }
}
