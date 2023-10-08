import 'package:flutter/animation.dart';

/// A cubic Bézier curve that replicates Apple's easeIn curve.
/// Ref: https://developer.apple.com/documentation/quartzcore/camediatimingfunctionname/1521971-easein
const Cubic appleEaseIn = Cubic(0.42, 0.0, 1.0, 1.0);

/// A cubic Bézier curve that replicates Apple's easeOut curve.
/// Ref: https://developer.apple.com/documentation/quartzcore/camediatimingfunctionname/1522178-easeout
const Cubic appleEaseOut = Cubic(0.0, 0.0, 0.58, 1.0);

/// A cubic Bézier curve that replicates Apple's easeInOut curve.
/// Ref: https://developer.apple.com/documentation/quartzcore/camediatimingfunctionname/1522173-easeineaseout
const Cubic appleEaseInOut = Cubic(0.42, 0.0, 0.58, 1.0);
