import 'effect.dart';

/// Vector arithmetic over an effect's animatable values, in the style of
/// SwiftUI's `VectorArithmetic`.
///
/// This is exactly the algebraic structure physics-based animation needs —
/// and nothing more. The closed-form spring solution is a combination of
/// scalar coefficients applied to vector quantities:
///
///     x(t) = target + (x0 - target) * A(t) + v0 * B(t)
///
/// so an effect that can add, subtract, and scale itself can be driven by
/// real spring physics, carry typed velocities (`(current - previous) *
/// (1 / dt)` is an effect-shaped "units per second"), and hand momentum
/// across retargets — without ever exposing its fields as raw numbers.
///
/// Only an effect's ANIMATABLE values participate in the algebra.
/// Configuration fields (alignments, origins, flags) ride along unchanged
/// from the LEFT operand.
///
/// Effects that don't mix this in simply keep the normalized lerp path;
/// physics features degrade gracefully.
mixin VectorEffect<T extends Effect> on Effect {
  /// Field-wise sum of animatable values.
  T operator +(T other);

  /// Field-wise difference of animatable values.
  T operator -(T other);

  /// Scales every animatable value by [factor].
  T operator *(double factor);

  /// The squared Euclidean magnitude of the animatable values, used for
  /// settle detection.
  double get magnitudeSquared;
}
