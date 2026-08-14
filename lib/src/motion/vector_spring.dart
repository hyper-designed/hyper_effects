import 'dart:math' as math;

import 'package:flutter/physics.dart';

/// The scalar coefficients of the closed-form spring solution at time [t]:
///
///     x(t) = target + d0 * a + v0 * b
///     v(t) =          d0 * da + v0 * db
///
/// where `d0 = x0 - target` is the initial displacement and `v0` the
/// initial velocity — both of which may be VECTOR quantities (effects),
/// since the coefficients themselves are plain scalars.
class SpringCoefficients {
  /// Weight of the initial displacement in the position.
  final double a;

  /// Weight of the initial velocity in the position.
  final double b;

  /// Weight of the initial displacement in the velocity.
  final double da;

  /// Weight of the initial velocity in the velocity.
  final double db;

  /// Creates spring coefficients.
  const SpringCoefficients({
    required this.a,
    required this.b,
    required this.da,
    required this.db,
  });
}

/// Evaluates the closed-form solution of [spring] at time [t] seconds.
SpringCoefficients springCoefficients(SpringDescription spring, double t) {
  final double omega = math.sqrt(spring.stiffness / spring.mass);
  final double zeta = spring.damping /
      (2 * math.sqrt(spring.stiffness * spring.mass));

  if (zeta < 1 - 1e-9) {
    // Underdamped: decaying oscillation.
    final double omegaD = omega * math.sqrt(1 - zeta * zeta);
    final double envelope = math.exp(-zeta * omega * t);
    final double sin = math.sin(omegaD * t);
    final double cos = math.cos(omegaD * t);
    final double ratio = zeta * omega / omegaD;
    return SpringCoefficients(
      a: envelope * (cos + ratio * sin),
      b: envelope * sin / omegaD,
      da: -envelope * (omega * omega / omegaD) * sin,
      db: envelope * (cos - ratio * sin),
    );
  }

  if (zeta < 1 + 1e-9) {
    // Critically damped: fastest non-oscillating return.
    final double envelope = math.exp(-omega * t);
    return SpringCoefficients(
      a: envelope * (1 + omega * t),
      b: envelope * t,
      da: -envelope * omega * omega * t,
      db: envelope * (1 - omega * t),
    );
  }

  // Overdamped: two real exponential poles.
  final double root = math.sqrt(zeta * zeta - 1);
  final double r1 = omega * (-zeta + root);
  final double r2 = omega * (-zeta - root);
  final double denominator = r1 - r2;
  final double e1 = math.exp(r1 * t);
  final double e2 = math.exp(r2 * t);
  return SpringCoefficients(
    a: (r1 * e2 - r2 * e1) / denominator,
    b: (e1 - e2) / denominator,
    da: r1 * r2 * (e2 - e1) / denominator,
    db: (r1 * e1 - r2 * e2) / denominator,
  );
}
