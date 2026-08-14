import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/motion/vector_spring.dart';

/// Pins the closed-form coefficient solver against Flutter's own
/// [SpringSimulation] across all three damping regimes, positions and
/// velocities alike.
void main() {
  const springs = <String, SpringDescription>{
    'underdamped': SpringDescription(mass: 1, stiffness: 100, damping: 10),
    'critical': SpringDescription(mass: 1, stiffness: 100, damping: 20),
    'overdamped': SpringDescription(mass: 1, stiffness: 100, damping: 25),
  };

  for (final MapEntry(key: name, value: spring) in springs.entries) {
    group(name, () {
      test('t=0 is exact', () {
        final c = springCoefficients(spring, 0);
        expect(c.a, closeTo(1, 1e-12));
        expect(c.b, closeTo(0, 1e-12));
        expect(c.da, closeTo(0, 1e-12));
        expect(c.db, closeTo(1, 1e-12));
      });

      test('matches SpringSimulation.x and .dx', () {
        for (final v0 in [0.0, 3.0, -2.0]) {
          final reference = SpringSimulation(spring, 0, 1, v0);
          for (var i = 1; i <= 20; i++) {
            final t = i * 0.05;
            final c = springCoefficients(spring, t);
            // x0 = 0, target = 1 => d0 = -1.
            final x = 1 + -1 * c.a + v0 * c.b;
            final dx = -1 * c.da + v0 * c.db;
            expect(x, closeTo(reference.x(t), 1e-6),
                reason: '$name x(t=$t, v0=$v0)');
            expect(dx, closeTo(reference.dx(t), 1e-6),
                reason: '$name dx(t=$t, v0=$v0)');
          }
        }
      });
    });
  }
}
