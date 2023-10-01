import 'package:flutter/widgets.dart';

import '../effect_builder.dart';
import 'effect.dart';

extension TranslateEffectExt on Widget {
  Widget translate(
    Offset offset,
  ) {
    return AnimatableEffect(
      effect: TranslateEffect(
        offset: offset,
      ),
      child: this,
    );
  }

  Widget translateX(
    double x,
  ) {
    return AnimatableEffect(
      effect: TranslateEffect(
        offset: Offset(x, 0),
      ),
      child: this,
    );
  }

  Widget translateY(
    double y,
  ) {
    return AnimatableEffect(
      effect: TranslateEffect(
        offset: Offset(0, y),
      ),
      child: this,
    );
  }

  Widget translateXY(
    double x,
    double y,
  ) {
    return AnimatableEffect(
      effect: TranslateEffect(
        offset: Offset(x, y),
      ),
      child: this,
    );
  }
}

class TranslateEffect extends Effect {
  final Offset offset;

  TranslateEffect({
    this.offset = Offset.zero,
  });

  @override
  Widget apply(BuildContext context, Widget child) {
    return Transform.translate(
      offset: offset,
      child: child,
    );
  }

  @override
  TranslateEffect lerp(covariant TranslateEffect other, double value) {
    return TranslateEffect(
      offset: Offset.lerp(offset, other.offset, value) ??
          Offset.zero,
    );
  }
}
