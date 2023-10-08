import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../effect_builder.dart';
import 'effect.dart';

extension BlurEffectExt on Widget {
  Widget blur(double? blur) {
    return AnimatableEffect(
      effect: BlurEffect(blur: blur),
      child: this,
    );
  }

  Widget blurX(double? blurX) {
    return AnimatableEffect(
      effect: BlurEffect(blurX: blurX),
      child: this,
    );
  }

  Widget blurY(double? blurY) {
    return AnimatableEffect(
      effect: BlurEffect(blurY: blurY),
      child: this,
    );
  }

  Widget blurXY(double? blurX, double? blurY) {
    return AnimatableEffect(
      effect: BlurEffect(blurX: blurX, blurY: blurY),
      child: this,
    );
  }
}

class BlurEffect extends Effect {
  final double? blur;
  final double? blurX;
  final double? blurY;

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
        tileMode: TileMode.decal
      ),
      child: child,
    );
  }
}
