import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../hyper_effects.dart';

/// A utility class for internal use.
abstract class Utils {
  /// Resolves the duration/curve sugar and the explicit [motion] channel into
  /// one [Motion], refusing ambiguous calls loudly.
  static Motion resolveMotion(
    Motion? motion,
    Duration? duration,
    Curve? curve,
  ) {
    if (motion != null) {
      if (duration != null || curve != null) {
        throw FlutterError(
          'Provide either a motion OR duration/curve, not both. The '
          'duration/curve parameters are sugar for '
          'CurvedMotion(duration, curve).',
        );
      }
      return motion;
    }
    return CurvedMotion(
      duration ?? const Duration(milliseconds: 350),
      curve ?? appleEaseInOut,
    );
  }
}
