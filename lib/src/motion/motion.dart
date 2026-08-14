import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'simulation/curve_simulation.dart';
import 'simulation/no_simulation.dart';

/// How an animation moves: the single timing object behind `animate`,
/// `immediate`, and timeline `step`s.
///
/// Every `duration:` + `curve:` pair in this package is sugar for a
/// [CurvedMotion]; passing a [Motion] directly via `motion:` unlocks the
/// rest of the family — most importantly spring physics, which has no
/// fixed duration and no curve at all.
///
/// The contract every motion answers:
///
/// * [effectiveDuration] — how long the animation runs. Real for
///   deterministic motions; a computed physical settling bound for springs.
/// * [transform] — normalized time (0..1 across [effectiveDuration]) to
///   progress. Exact 0 at the start and exact 1 at the end so keyframe
///   handoffs stay precise; free to overshoot past 1 in between.
/// * [createSimulation] — the raw [Simulation], for physics-aware callers
///   that need positions and velocities in value space.
@immutable
abstract class Motion {
  /// Creates a motion with the given settle [tolerance].
  const Motion({
    this.tolerance = Tolerance.defaultTolerance,
  });

  /// A deterministic motion: [duration] long, eased by [curve].
  const factory Motion.curved(Duration duration, [Curve curve]) = CurvedMotion;

  /// Creates a linear motion with a fixed duration.
  const factory Motion.linear(Duration duration) = LinearMotion;

  /// A motion that holds still; see [NoMotion].
  const factory Motion.none([Duration duration]) = NoMotion;

  /// A spring with custom physics; see [SpringMotion].
  const factory Motion.customSpring(SpringDescription spring) = SpringMotion;

  /// An iOS-feel spring described by perceptual duration and bounce.
  const factory Motion.cupertino({
    Duration duration,
    double bounce,
    bool snapToEnd,
  }) = CupertinoMotion;

  /// Shorthand for [CupertinoMotion.bouncy].
  const factory Motion.bouncySpring({
    Duration duration,
    double extraBounce,
    bool snapToEnd,
  }) = CupertinoMotion.bouncy;

  /// Shorthand for [CupertinoMotion.snappy].
  const factory Motion.snappySpring({
    Duration duration,
    double extraBounce,
    bool snapToEnd,
  }) = CupertinoMotion.snappy;

  /// Shorthand for [CupertinoMotion.smooth].
  const factory Motion.smoothSpring({
    Duration duration,
    double extraBounce,
    bool snapToEnd,
  }) = CupertinoMotion.smooth;

  /// Shorthand for [CupertinoMotion.interactive].
  const factory Motion.interactiveSpring({
    Duration duration,
    double extraBounce,
    bool snapToEnd,
  }) = CupertinoMotion.interactive;

  /// The tolerance for this motion.
  ///
  /// Default is [Tolerance.defaultTolerance].
  final Tolerance tolerance;

  /// Whether this motion needs to settle.
  ///
  /// If this is true, the motion will continue to animate until the velocity
  /// is less than the [tolerance], whenever it is supposed to be stopped.
  bool get needsSettle;

  /// Whether this motion will settle without bounds.
  ///
  /// If this is false, this motion will never terminate without bounds.
  bool get unboundedWillSettle;

  /// The effective duration of this motion.
  ///
  /// For deterministic motions this is the real duration. For physics-based
  /// motions it is a computed settling bound: the time after which the
  /// motion's distance from its target stays below [tolerance].
  Duration get effectiveDuration;

  /// Maps normalized time [t] — 0 at the start of [effectiveDuration], 1 at
  /// its end — to this motion's progress value.
  ///
  /// The value may exceed 1.0 mid-flight (spring overshoot); effect lerps
  /// extrapolate. Motions that reach their target return exactly 0 at t=0
  /// and exactly 1 at t=1 so keyframe handoffs stay precise.
  double transform(double t);

  /// Creates a simulation for this motion.
  ///
  /// This method creates a [Simulation] object that defines how the animation
  /// will progress over time based on the motion's characteristics.
  ///
  /// Parameters:
  ///   * [start] - The starting value for the simulation, defaults to 0.
  ///   * [end] - The ending value for the simulation, defaults to 1.
  ///   * [velocity] - The initial velocity for the simulation, defaults to 0.
  ///
  /// Returns a [Simulation] that can be used by an [AnimationController].
  Simulation createSimulation({
    double start = 0,
    double end = 1,
    double velocity = 0,
  });

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}

/// The classic deterministic motion: a fixed [duration] eased by a
/// [curve].
///
/// This is what every `duration:` + `curve:` sugar parameter in the
/// package compiles down to. It always completes on schedule and its
/// [transform] is simply the curve.
@immutable
class CurvedMotion extends Motion {
  /// Creates a motion with a fixed duration and curve.
  const CurvedMotion(
    this.duration, [
    this.curve = Curves.linear,
  ]) : super(tolerance: Tolerance.defaultTolerance);

  /// The total duration of the motion.
  final Duration duration;

  /// The curve that defines the rate of change of the motion over time.
  ///
  /// Defaults to [Curves.linear], which represents a constant rate of change.
  final Curve curve;

  @override
  Duration get effectiveDuration => duration;

  @override
  double transform(double t) => curve.transform(t.clamp(0.0, 1.0));

  /// Whether this motion needs to settle.
  ///
  /// Always returns false for [CurvedMotion] because it completes in a
  /// fixed duration.
  @override
  bool get needsSettle => false;

  /// Whether this motion will settle without bounds.
  ///
  /// Always returns true for [CurvedMotion] because it always terminates
  /// after the specified duration.
  @override
  bool get unboundedWillSettle => true;

  /// Creates a new [CurvedMotion] with the given parameters.
  CurvedMotion copyWith({
    Duration? duration,
    Curve? curve,
  }) =>
      CurvedMotion(duration ?? this.duration, curve ?? this.curve);

  /// Applies [curve] to the current [duration].
  CurvedMotion withCurve(Curve curve) => copyWith(curve: curve);

  @override
  Simulation createSimulation({
    double start = 0,
    double end = 1,
    double velocity = 0,
  }) {
    return CurveSimulation(
      duration: duration,
      curve: curve,
      start: start,
      end: end,
      tolerance: tolerance,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is CurvedMotion) {
      return duration == other.duration && curve == other.curve;
    }
    return false;
  }

  /// Returns a hash code for this object.
  @override
  int get hashCode => Object.hash(duration, curve);

  /// Returns a string representation of this object.
  @override
  String toString() => 'CurvedMotion($duration, curve: $curve)';
}

/// A convenience class for a [CurvedMotion] that uses a linear curve.
class LinearMotion extends CurvedMotion {
  /// Creates a linear motion with a fixed duration.
  const LinearMotion(Duration duration) : super(duration, Curves.linear);

  @override
  String toString() => 'LinearMotion($duration)';
}

/// A motion that never moves: it holds the starting value for [duration]
/// and never reaches its target. Useful as an explicit "do not animate"
/// placeholder.
class NoMotion extends Motion {
  /// Creates a motion that holds still for [duration] (zero by default).
  const NoMotion([this.duration = Duration.zero]);

  /// The duration that this motion holds its value.
  final Duration duration;

  @override
  String toString() => 'NoMotion($duration)';

  @override
  Duration get effectiveDuration => duration;

  @override
  double transform(double t) => 0;

  @override
  Simulation createSimulation({
    double start = 0,
    double end = 1,
    double velocity = 0,
  }) {
    return NoMotionSimulation(
      duration: duration,
      value: start,
      tolerance: tolerance,
    );
  }

  @override
  bool get needsSettle => false;

  @override
  bool get unboundedWillSettle => true;
}

/// A motion driven by damped spring physics.
///
/// Springs have no author-chosen duration: [effectiveDuration] is a
/// settling bound computed from the physics ([description]) and
/// [tolerance] — the time after which the spring's distance from its
/// target stays sub-perceptual. That bound is what lets springs slot into
/// the normalized-time machinery (timelines, seek, repeat) unchanged.
///
/// [transform] samples the real simulation, so underdamped springs
/// genuinely overshoot past 1 mid-flight while both endpoints stay exact.
/// When the animated effect is a [VectorEffect], the animator additionally
/// runs the closed-form solution in effect space, which is what makes
/// mid-flight retargeting carry velocity.
///
/// Equality compares the physics (mass, stiffness, damping), not the
/// preset identity that produced them.
@immutable
abstract class SpringMotion extends Motion {
  /// Creates a spring from a raw physical [description]
  /// (mass, stiffness, damping).
  const factory SpringMotion(
    SpringDescription description, {
    bool snapToEnd,
  }) = _DescriptionSpringMotion;

  /// Internal constructor;
  const SpringMotion._({
    this.snapToEnd = false,
  });

  /// The physical description of the spring.
  ///
  /// Contains parameters like mass, stiffness, and damping that define
  /// how the spring behaves.
  SpringDescription get description;

  /// Whether to snap to the end of the spring.
  ///
  /// If true, the spring will snap to the end of the motion when the simulation
  /// is done.
  /// This ensures that the simulation will settle exactly to the target value.
  final bool snapToEnd;

  static final Expando<SpringSimulation> _simulations = Expando();

  @override
  Duration get effectiveDuration {
    final double omega = math.sqrt(description.stiffness / description.mass);
    final double zeta = description.damping /
        (2 * math.sqrt(description.stiffness * description.mass));
    if (zeta <= 0 || !zeta.isFinite || omega <= 0 || !omega.isFinite) {
      throw StateError(
        'A spring with no damping never settles. Give $description a '
        'positive damping value.',
      );
    }
    final double epsilon = tolerance.distance;
    final double seconds;
    if (zeta < 1) {
      // Underdamped: bound by the oscillation envelope.
      final double envelope = 1 / math.sqrt(1 - zeta * zeta);
      seconds = math.log(envelope / epsilon) / (zeta * omega);
    } else {
      // Critically/overdamped: bound by the slow exponential pole, with
      // headroom for critical damping's polynomial factor.
      final double slowPole =
          omega * (zeta - math.sqrt(math.max(0, zeta * zeta - 1)));
      seconds = 1.25 * math.log(1 / epsilon) / slowPole;
    }
    return Duration(
      microseconds: (seconds * Duration.microsecondsPerSecond).round(),
    );
  }

  @override
  double transform(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    final SpringSimulation simulation = _simulations[this] ??=
        SpringSimulation(description, 0, 1, 0, tolerance: tolerance);
    final double seconds =
        effectiveDuration.inMicroseconds / Duration.microsecondsPerSecond;
    return simulation.x(t * seconds);
  }

  /// Whether this motion needs to settle.
  ///
  /// Always returns true for [SpringMotion] because spring physics requires
  /// the animation to continue until the spring naturally settles.
  @override
  bool get needsSettle => true;

  /// Whether this motion will settle without bounds.
  ///
  /// Returns false for [SpringMotion] because spring physics may not
  /// necessarily terminate without bounds in all configurations.
  @override
  bool get unboundedWillSettle => false;

  /// Creates a simulation for this motion.
  ///
  /// Returns a [SpringSimulation] that follows the physical behavior
  /// defined by the [description] description.
  ///
  /// Parameters:
  ///   * [start] - The starting value for the simulation, defaults to 0.
  ///   * [end] - The ending value (target position) for the simulation,
  ///     defaults to 1.
  ///   * [velocity] - The initial velocity of the spring, defaults to 0.
  @override
  Simulation createSimulation({
    double start = 0,
    double end = 1,
    double velocity = 0,
  }) =>
      SpringSimulation(
        description,
        start,
        end,
        velocity,
        tolerance: tolerance,
        snapToEnd: snapToEnd,
      );

  /// Equality operator for [SpringMotion].
  ///
  /// Two [SpringMotion] instances are considered equal if their [description]
  /// descriptions have the same damping, mass, and stiffness values.
  @override
  bool operator ==(Object other) {
    if (other is SpringMotion) {
      return description.damping == other.description.damping &&
          description.mass == other.description.mass &&
          description.stiffness == other.description.stiffness;
    }
    return false;
  }

  /// Returns a hash code for this object.
  @override
  int get hashCode =>
      Object.hash(description.damping, description.mass, description.stiffness);

  /// Returns a string representation of this object.
  @override
  String toString() => 'Spring(spring: $description)';

  /// Creates a new [SpringMotion] with the same properties as this one, but
  /// with the specified [description] and [snapToEnd].
  SpringMotion copyWith();
}

class _DescriptionSpringMotion extends SpringMotion {
  /// Creates a new [SpringMotion] with the specified [description].
  const _DescriptionSpringMotion(
    this.description, {
    super.snapToEnd,
  }) : super._();

  @override
  final SpringDescription description;

  @override
  String toString() => 'Spring(description: $description)';

  @override
  SpringMotion copyWith({
    SpringDescription? description,
    bool? snapToEnd,
  }) {
    return _DescriptionSpringMotion(
      description ?? this.description,
      snapToEnd: snapToEnd ?? this.snapToEnd,
    );
  }
}

/// Springs described the way iOS describes them: a perceptual [duration]
/// and a [bounce] amount, rather than raw mass/stiffness/damping.
///
/// The named presets mirror the feel of the SwiftUI catalog: [bouncy],
/// [snappy], [smooth], and [interactive].
class CupertinoMotion extends SpringMotion {
  /// Creates a spring from a perceptual [duration] and [bounce].
  ///
  /// The default is a smooth, no-bounce spring over 550ms.
  const CupertinoMotion({
    this.duration = const Duration(milliseconds: 550),
    this.bounce = 0,
    super.snapToEnd,
  }) : super._();

  /// A visibly bouncy spring: 500ms perceptual duration, 0.3 bounce
  /// (plus [extraBounce]).
  const CupertinoMotion.bouncy({
    Duration duration = const Duration(milliseconds: 500),
    double extraBounce = 0.0,
    bool snapToEnd = false,
  }) : this(
          duration: duration,
          bounce: 0.3 + extraBounce,
          snapToEnd: snapToEnd,
        );

  /// A quick spring with a small bounce: 500ms perceptual duration,
  /// 0.15 bounce (plus [extraBounce]).
  const CupertinoMotion.snappy({
    Duration duration = const Duration(milliseconds: 500),
    double extraBounce = 0.0,
    bool snapToEnd = false,
  }) : this(
          duration: duration,
          bounce: 0.15 + extraBounce,
          snapToEnd: snapToEnd,
        );

  /// A no-bounce spring: 500ms perceptual duration, critically smooth
  /// unless [extraBounce] is given.
  const CupertinoMotion.smooth({
    Duration duration = const Duration(milliseconds: 500),
    double extraBounce = 0.0,
    bool snapToEnd = false,
  }) : this(
          duration: duration,
          bounce: extraBounce,
          snapToEnd: snapToEnd,
        );

  /// A tight, fast spring for gesture-driven animation: 150ms perceptual
  /// duration, 0.14 bounce (plus [extraBounce]).
  const CupertinoMotion.interactive({
    Duration duration = const Duration(milliseconds: 150),
    double extraBounce = 0.0,
    bool snapToEnd = false,
  }) : this(
          duration: duration,
          bounce: 0.14 + extraBounce,
          snapToEnd: snapToEnd,
        );

  /// The perceptual duration of one spring period. Note this is NOT the
  /// settling time — see [effectiveDuration] for that.
  final Duration duration;

  /// How much the spring bounces: 0 is smooth, higher values overshoot
  /// more before settling.
  final double bounce;

  @override
  SpringDescription get description => SpringDescription.withDurationAndBounce(
        duration: duration,
        bounce: bounce,
      );

  /// Creates a new [CupertinoMotion] with the same properties as this one, but
  /// with the specified [bounce] and [duration].
  @override
  CupertinoMotion copyWith({
    Duration? duration,
    double? bounce,
    bool? snapToEnd,
  }) {
    return CupertinoMotion(
      duration: duration ?? description.duration,
      bounce: bounce ?? description.bounce,
      snapToEnd: snapToEnd ?? this.snapToEnd,
    );
  }
}

/// The Material Design 3 expressive spring tokens, as plain physics.
///
/// Two families — spatial (positions, sizes, layout) and effects
/// (opacity, color, non-spatial properties) — in standard and expressive
/// flavors, each with fast/default/slow variants. Effects tokens are
/// critically damped on purpose: visual properties should not visibly
/// oscillate.
class MaterialSpringMotion extends SpringMotion {
  /// Creates a new [MaterialSpringMotion] with the specified damping and
  /// stiffness.
  const MaterialSpringMotion._({
    required this.damping,
    required this.stiffness,
    super.snapToEnd,
  }) : super._();

  /// The standard spatial fast token.
  const MaterialSpringMotion.standardSpatialFast({
    bool snapToEnd = false,
  }) : this._(
          damping: 0.9,
          stiffness: 1400,
          snapToEnd: snapToEnd,
        );

  /// The standard spatial default token.
  const MaterialSpringMotion.standardSpatialDefault({
    bool snapToEnd = false,
  }) : this._(
          damping: 0.9,
          stiffness: 700,
          snapToEnd: snapToEnd,
        );

  /// The standard spatial slow token.
  const MaterialSpringMotion.standardSpatialSlow({
    bool snapToEnd = false,
  }) : this._(
          damping: 0.9,
          stiffness: 300,
          snapToEnd: snapToEnd,
        );

  /// The standard effects fast token.
  const MaterialSpringMotion.standardEffectsFast({
    bool snapToEnd = false,
  }) : this._(
          damping: 1,
          stiffness: 3800,
          snapToEnd: snapToEnd,
        );

  /// The standard effects default token.
  const MaterialSpringMotion.standardEffectsDefault({
    bool snapToEnd = false,
  }) : this._(
          damping: 1,
          stiffness: 1600,
          snapToEnd: snapToEnd,
        );

  /// The standard effects slow token.
  const MaterialSpringMotion.standardEffectsSlow({
    bool snapToEnd = false,
  }) : this._(
          damping: 1,
          stiffness: 800,
          snapToEnd: snapToEnd,
        );

  /// The expressive spatial fast token.
  const MaterialSpringMotion.expressiveSpatialFast({
    bool snapToEnd = false,
  }) : this._(
          damping: 0.6,
          stiffness: 800,
          snapToEnd: snapToEnd,
        );

  /// The expressive spatial default token.
  const MaterialSpringMotion.expressiveSpatialDefault({
    bool snapToEnd = false,
  }) : this._(
          damping: 0.8,
          stiffness: 380,
          snapToEnd: snapToEnd,
        );

  /// The expressive spatial slow token.
  const MaterialSpringMotion.expressiveSpatialSlow({
    bool snapToEnd = false,
  }) : this._(
          damping: 0.8,
          stiffness: 200,
          snapToEnd: snapToEnd,
        );

  /// The expressive effects fast token.
  const MaterialSpringMotion.expressiveEffectsFast({
    bool snapToEnd = false,
  }) : this._(
          damping: 1,
          stiffness: 3800,
          snapToEnd: snapToEnd,
        );

  /// The expressive effects default token.
  const MaterialSpringMotion.expressiveEffectsDefault({
    bool snapToEnd = false,
  }) : this._(
          damping: 1,
          stiffness: 1600,
          snapToEnd: snapToEnd,
        );

  /// The expressive effects slow token.
  const MaterialSpringMotion.expressiveEffectsSlow({
    bool snapToEnd = false,
  }) : this._(
          damping: 1,
          stiffness: 800,
          snapToEnd: snapToEnd,
        );

  /// The damping factor of the spring motion.
  ///
  /// Works exactly like the [SpringDescription.damping] property.
  final double damping;

  /// The stiffness factor of the spring motion.
  ///
  /// Works exactly like the [SpringDescription.stiffness] property.
  final double stiffness;

  @override
  SpringDescription get description => SpringDescription.withDampingRatio(
        ratio: damping,
        stiffness: stiffness,
        mass: 1,
      );

  @override
  MaterialSpringMotion copyWith({
    double? damping,
    double? stiffness,
    bool? snapToEnd,
  }) {
    return MaterialSpringMotion._(
      damping: damping ?? this.damping,
      stiffness: stiffness ?? this.stiffness,
      snapToEnd: snapToEnd ?? this.snapToEnd,
    );
  }
}

/// A window onto another motion: plays only the [fromStart]..(1 - [fromEnd])
/// portion of [parent]'s characteristic curve, renormalized to 0..1.
///
/// For deterministic parents the window is exact. For springs it is an
/// approximation — the parent simulation is stretched over a wider range
/// and mapped back — close in feel, not physics-exact at every instant.
///
/// Built via [MotionTrimming.trimmed], [MotionTrimming.sliced], or
/// [MotionTrimming.segment].
@immutable
class TrimmedMotion extends Motion {
  /// Creates a window onto [parent], trimming [fromStart] off the
  /// beginning and [fromEnd] off the end.

  const TrimmedMotion({
    required this.parent,
    required this.fromStart,
    required this.fromEnd,
  })  : assert(fromStart >= 0.0, 'fromStart must be non-negative'),
        assert(fromEnd >= 0.0, 'fromEnd must be non-negative'),
        assert(
          fromStart + fromEnd <= 1.0,
          'fromStart + fromEnd must be less than 1.0, '
          'but received $fromStart + $fromEnd',
        );

  /// The motion to trim.
  final Motion parent;

  /// Amount to trim from the start of the motion curve.
  final double fromStart;

  /// Amount to trim from the end of the motion curve.
  final double fromEnd;

  @override
  Duration get effectiveDuration {
    final double extent = 1.0 - fromStart - fromEnd;
    return Duration(
      microseconds: (parent.effectiveDuration.inMicroseconds * extent).round(),
    );
  }

  @override
  double transform(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    final double extent = 1.0 - fromStart - fromEnd;
    final double a = parent.transform(fromStart);
    final double b = parent.transform(1 - fromEnd);
    if (a == b) return 1;
    final double raw = parent.transform(fromStart + t * extent);
    return (raw - a) / (b - a);
  }

  @override
  bool get needsSettle => parent.needsSettle;

  @override
  bool get unboundedWillSettle => parent.unboundedWillSettle;

  @override
  Tolerance get tolerance => parent.tolerance;

  @override
  Simulation createSimulation({
    double start = 0,
    double end = 1,
    double velocity = 0,
  }) {
    final trimmedExtent = 1.0 - fromStart - fromEnd;

    // We simulate the parent over the extended range
    final parentStart = start - trimmedExtent * fromStart;
    final parentEnd = end + trimmedExtent * fromEnd;

    final scaledSim = parent.createSimulation(
      start: parentStart,
      end: parentEnd,
      velocity: velocity,
    );

    return _TrimmedSimulation(
      parent: scaledSim,
      startTrim: fromStart,
      endTrim: fromEnd,
      trimmedExtent: trimmedExtent,
      start: start,
      end: end,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is TrimmedMotion) {
      return parent == other.parent &&
          fromStart == other.fromStart &&
          fromEnd == other.fromEnd;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(parent, fromStart, fromEnd);

  @override
  String toString() =>
      'TrimmedMotion(parent: $parent, trim: $fromStart-$fromEnd)';
}

class _TrimmedSimulation extends Simulation {
  _TrimmedSimulation({
    required this.parent,
    required this.startTrim,
    required this.endTrim,
    required this.trimmedExtent,
    required this.start,
    required this.end,
  })  : _duration = _findParentDuration(parent) * trimmedExtent,
        super(tolerance: parent.tolerance);

  final Simulation parent;
  final double startTrim;
  final double endTrim;
  final double trimmedExtent;
  final double start;
  final double end;
  final double _duration;

  static double _findParentDuration(Simulation parent) {
    // For most simulations, check when isDone returns true
    for (var t = 0.01; t <= 10; t += 0.01) {
      if (parent.isDone(t)) {
        return t;
      }
    }
    return 1; // fallback
  }

  @override
  double x(double time) {
    if (time <= 0) return start;
    if (time >= _duration) return end;

    // Map our time to the parent's time range
    final parentDuration = _duration / trimmedExtent;
    final progressStart = startTrim;
    final progressEnd = 1.0 - endTrim;

    // Scale time to fit within trimmed range
    final normalizedTime = time / _duration;
    final parentTime = parentDuration *
        (progressStart + (progressEnd - progressStart) * normalizedTime);

    // Get parent's values to normalize
    final parentStartValue = parent.x(parentDuration * progressStart);
    final parentEndValue = parent.x(parentDuration * progressEnd);
    final parentCurrentValue = parent.x(parentTime);

    // Normalize and map to our range
    if ((parentEndValue - parentStartValue).abs() < 1e-10) {
      return start + (end - start) * normalizedTime;
    }

    final normalizedProgress = (parentCurrentValue - parentStartValue) /
        (parentEndValue - parentStartValue);
    return start + (end - start) * normalizedProgress;
  }

  @override
  double dx(double time) {
    if (time < 0 || time > _duration) return 0;

    // Use numerical differentiation
    const delta = 0.001;
    final x1 = x(time - delta);
    final x2 = x(time + delta);
    return (x2 - x1) / (2 * delta);
  }

  @override
  bool isDone(double time) => time >= _duration - tolerance.time;
}

/// Windowing helpers that carve a [TrimmedMotion] out of any motion.
extension MotionTrimming on Motion {
  /// Trims [fromStart] off the beginning and [fromEnd] off the end of this
  /// motion's curve; what remains plays as a full 0..1 motion.
  TrimmedMotion trimmed({
    double fromStart = 0.0,
    double fromEnd = 0.0,
  }) {
    return TrimmedMotion(
      parent: this,
      fromStart: fromStart,
      fromEnd: fromEnd,
    );
  }

  /// The [from]..[to] window of this motion's curve, as a full motion.
  TrimmedMotion sliced({
    double from = 0.0,
    double to = 1.0,
  }) {
    assert(from >= 0.0 && from <= 1.0, 'from must be between 0 and 1');
    assert(to >= 0.0 && to <= 1.0, 'to must be between 0 and 1');
    assert(from <= to, 'from cannot be greater than to');
    return TrimmedMotion(
      parent: this,
      fromStart: from,
      fromEnd: 1.0 - to,
    );
  }

  /// A window of this motion's curve described by [start] and [length].
  TrimmedMotion segment({
    required double length,
    double start = 0.0,
  }) {
    assert(start + length <= 1.0, 'start + length cannot be larger than 1');
    return TrimmedMotion(
      parent: this,
      fromStart: start,
      fromEnd: 1.0 - (start + length),
    );
  }
}
