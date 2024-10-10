import 'package:flutter/widgets.dart';

import '../effect_widget.dart';
import 'effect.dart';

/// Provides a extension method to apply an [PaddingEffect] to a [Widget].
extension PaddingEffectExt on Widget {
  /// Applies an [PaddingEffect] to a [Widget] with the given [padding].
  Widget pad(
    EdgeInsets padding, {
    EdgeInsets? from,
  }) {
    return EffectWidget(
      start: from == null ? null : PaddingEffect(padding: from),
      end: PaddingEffect(padding: padding),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [padding].
  Widget padAll(
    double padding, {
    double? from,
  }) {
    return EffectWidget(
      start: from == null ? null : PaddingEffect(padding: EdgeInsets.all(from)),
      end: PaddingEffect(padding: EdgeInsets.all(padding)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [vertical]
  /// and [horizontal] padding.
  Widget padSymmetric(
      {double vertical = 0, double horizontal = 0, double? from}) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(
              padding: EdgeInsets.symmetric(vertical: from, horizontal: from)),
      end: PaddingEffect(
          padding:
              EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [horizontal]
  /// padding.
  Widget padHorizontal(
    double padding, {
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(padding: EdgeInsets.symmetric(horizontal: from)),
      end: PaddingEffect(padding: EdgeInsets.symmetric(horizontal: padding)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [vertical]
  /// padding.
  Widget padVertical(
    double padding, {
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(padding: EdgeInsets.symmetric(vertical: from)),
      end: PaddingEffect(padding: EdgeInsets.symmetric(vertical: padding)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [left], [right],
  /// [top], and [bottom] padding.
  Widget padOnly({
    double left = 0,
    double right = 0,
    double top = 0,
    double bottom = 0,
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(
              padding: EdgeInsets.only(
                  left: from, right: from, top: from, bottom: from)),
      end: PaddingEffect(
          padding: EdgeInsets.only(
              left: left, right: right, top: top, bottom: bottom)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [left] padding.
  Widget padLeft(
    double padding, {
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(padding: EdgeInsets.only(left: from)),
      end: PaddingEffect(padding: EdgeInsets.only(left: padding)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [right] padding.
  Widget padRight(
    double padding, {
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(padding: EdgeInsets.only(right: from)),
      end: PaddingEffect(padding: EdgeInsets.only(right: padding)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [top] padding.
  Widget padTop(
    double padding, {
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(padding: EdgeInsets.only(top: from)),
      end: PaddingEffect(padding: EdgeInsets.only(top: padding)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [bottom] padding.
  Widget padBottom(
    double padding, {
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(padding: EdgeInsets.only(bottom: from)),
      end: PaddingEffect(padding: EdgeInsets.only(bottom: padding)),
      child: this,
    );
  }
}

/// An effect that aligns a [Widget] by a given [padding].
class PaddingEffect extends Effect {
  /// The alignment by which the [Widget] is aligned.
  final EdgeInsets padding;

  /// Creates a [PaddingEffect] with the given [padding].
  PaddingEffect({
    this.padding = EdgeInsets.zero,
  });

  @override
  PaddingEffect lerp(covariant PaddingEffect other, double value) {
    return PaddingEffect(
      padding: EdgeInsets.lerp(padding, other.padding, value.clamp(0, 1)) ??
          EdgeInsets.zero,
    );
  }

  @override
  Widget apply(BuildContext context, Widget? child) {
    return Padding(
      padding: padding,
      child: child,
    );
  }

  @override
  PaddingEffect idle() => PaddingEffect();

  @override
  List<Object?> get props => [padding];
}
