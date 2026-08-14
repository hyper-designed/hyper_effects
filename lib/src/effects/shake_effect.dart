import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../hyper_effects.dart';

/// Provides a extension method to apply a [ShakeEffect] to a [Widget].
extension ShakeEffectExt on Widget {
  /// Applies a [ShakeEffect] to a [Widget].
  ///
  /// [frequency] is the frequency of the shake in hertz.
  ///
  /// [offset] is the offset of the shake.
  ///
  /// [rotation] is the rotation of the shake.
  Widget shake({
    double frequency = 8,
    Offset offset = const Offset(5, 0),
    double rotation = pi / 36,
  }) {
    return EffectWidget(
      end: ShakeEffect(
        frequency: frequency,
        offset: offset,
        rotation: rotation,
      ),
      child: this,
    );
  }
}

/// A [Effect] that applies a shaking motion to a [Widget].
class ShakeEffect extends Effect {
  /// The frequency of the shake in hertz. Defaults to 8.
  final double frequency;

  /// The offset of the shake. Defaults to 5, 0.
  final Offset offset;

  /// The rotation of the shake. Defaults to pi / 36.
  final double rotation;

  /// Creates a [ShakeEffect].
  const ShakeEffect({
    this.frequency = 8,
    this.offset = const Offset(5, 0),
    this.rotation = pi / 36,
  });

  @override
  ShakeEffect lerp(covariant ShakeEffect other, double value) {
    return ShakeEffect(
      frequency: lerpDouble(frequency, other.frequency, value) ?? 0,
      offset: Offset.lerp(offset, other.offset, value) ?? Offset.zero,
      rotation: lerpDouble(rotation, other.rotation, value) ?? 0,
    );
  }

  @override
  Widget apply(BuildContext context, Widget? child) {
    final effectQuery = EffectQuery.maybeOf(context);
    final value = effectQuery?.curvedValue ?? 1;
    final duration = effectQuery?.duration ?? Duration.zero;

    final int count = (duration.inMilliseconds / 1000 * frequency).round();
    final double effectiveValue = sin(value * count * pi * 2);

    return Transform(
      transform: Matrix4.identity()
        ..rotateZ(rotation * effectiveValue)
        ..translateByDouble(
            offset.dx * effectiveValue, offset.dy * effectiveValue, 0, 1),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  ShakeEffect idle() => const ShakeEffect();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShakeEffect &&
        other.runtimeType == runtimeType &&
        other.frequency == frequency &&
        other.offset == offset &&
        other.rotation == rotation;
  }

  @override
  int get hashCode => Object.hash(
        frequency,
        offset,
        rotation,
      );

  @override
  String toString() =>
      'ShakeEffect(frequency: $frequency, offset: $offset, rotation: $rotation)';
}
