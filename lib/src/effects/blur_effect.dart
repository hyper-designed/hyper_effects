import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../effect_builder.dart';
import 'effect.dart';

/// Provides extension methods for [Widget] to apply blur effects.
extension BlurEffectExt on Widget {
  /// Applies a [BlurEffect] to this widget with given [blur] value.
  Widget blur(double? blur) {
    return AnimatableEffect(
      end: BlurEffect(blur: blur),
      child: this,
    );
  }

  /// Applies a [BlurEffect] to only the horizontal axis of this widget with
  /// given [blurX] value.
  Widget blurX(double? blurX) {
    return AnimatableEffect(
      end: BlurEffect(blurX: blurX),
      child: this,
    );
  }

  /// Applies a [BlurEffect] to only the vertical axis of this widget with
  /// given [blurY] value.
  Widget blurY(double? blurY) {
    return AnimatableEffect(
      end: BlurEffect(blurY: blurY),
      child: this,
    );
  }

  /// Applies a [BlurEffect] to this widget with given [blurX] and [blurY]
  /// values.
  Widget blurXY(double? blurX, double? blurY) {
    return AnimatableEffect(
      end: BlurEffect(blurX: blurX, blurY: blurY),
      child: this,
    );
  }

  /// Applies a [BlurEffect] to this widget with a default blur in animation.
  Widget blurIn({double blur = 10}) {
    return AnimatableEffect(
      start: BlurEffect(blur: blur),
      end: BlurEffect(blur: 0),
      child: this,
    );
  }

  /// Applies a [BlurEffect] to this widget with a default blur out animation.
  Widget blurOut({double blur = 10}) {
    return AnimatableEffect(
      start: BlurEffect(blur: 0),
      end: BlurEffect(blur: blur),
      child: this,
    );
  }
}

/// An effect that applies a blur effect to its child.
class BlurEffect extends Effect {
  /// The blur value to apply to the child. This must be null if [blurX] or
  /// [blurY] is provided.
  final double? blur;

  /// The blur value to apply to the horizontal axis of the child. This must be
  /// null if [blur] is provided.
  final double? blurX;

  /// The blur value to apply to the vertical axis of the child. This must be
  /// null if [blur] is provided.
  final double? blurY;

  /// Creates a [BlurEffect].
  BlurEffect({
    this.blur,
    this.blurX,
    this.blurY,
  }) : assert(blur != null || blurX != null || blurY != null,
            'At least one of blur, blurX, or blurY must be non-null');

  @override
  BlurEffect lerp(covariant BlurEffect other, double value) {
    final effect = BlurEffect(
      blur: blur != null ? (lerpDouble(blur, other.blur, value) ?? 1) : null,
      blurX: blur == null ? (lerpDouble(blurX, other.blurX, value) ?? 1) : null,
      blurY: blur == null ? (lerpDouble(blurY, other.blurY, value) ?? 1) : null,
    );
    return effect;
  }

  @override
  Widget apply(BuildContext context, Widget child) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: blurX ?? blur ?? 0,
        sigmaY: blurY ?? blur ?? 0,
        tileMode: TileMode.decal,
      ),
      child: child,
    );
  }

  @override
  List<Object?> get props => [blur, blurX, blurY];
}
