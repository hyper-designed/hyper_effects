import 'package:flutter/widgets.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// Provides a extension method to apply an [ClipEffect] to a [Widget].
extension ClipEffectExtension on Widget {
  /// Applies an [ClipEffect] to a [Widget] with the given [clip] and [radius].
  Widget clip([
    double radius = 16,
    Clip? clip,
  ]) {
    return EffectWidget(
      end: ClipEffect(
        clip: clip ?? Clip.antiAlias,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: this,
    );
  }

  /// Applies an [ClipEffect] to a [Widget] with the given [clip] and a
  /// [corners].
  Widget clipCorners([
    List<double> corners = const [16, 16, 16, 16],
    Clip? clip,
  ]) {
    final length = corners.length;

    assert(length != 3 && length <= 4, 'Corners must have 1, 2 or 4 values');

    final BorderRadius borderRadius = switch (corners) {
      [num all] => BorderRadius.circular(all.toDouble()),
      [num horizontal, num vertical] => BorderRadius.only(
          topLeft: Radius.circular(horizontal.toDouble()),
          topRight: Radius.circular(horizontal.toDouble()),
          bottomRight: Radius.circular(vertical.toDouble()),
          bottomLeft: Radius.circular(vertical.toDouble()),
        ),
      [num topLeft, num topRight, num bottomRight, num bottomLeft] =>
        BorderRadius.only(
          topLeft: Radius.circular(topLeft.toDouble()),
          topRight: Radius.circular(topRight.toDouble()),
          bottomRight: Radius.circular(bottomRight.toDouble()),
          bottomLeft: Radius.circular(bottomLeft.toDouble()),
        ),
      _ => BorderRadius.zero
    };

    return EffectWidget(
      end: ClipEffect(
        clip: clip ?? Clip.antiAlias,
        borderRadius: borderRadius,
      ),
      child: this,
    );
  }

  /// Applies an [ClipEffect] to a [Widget] with the given [clip] and a
  /// [borderRadius].
  Widget clipRRect([
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    Clip? clip,
  ]) {
    return EffectWidget(
      end: ClipEffect(
        clip: clip ?? Clip.antiAlias,
        borderRadius: borderRadius,
      ),
      child: this,
    );
  }
}

/// An [Effect] that applies an clip to a [Widget].
class ClipEffect extends Effect {
  /// The clip to apply to the [Widget]. Defaults to [Clip.antiAlias].
  final Clip clip;

  /// The border radius to apply to the [Widget]. Defaults to [0].
  final BorderRadius borderRadius;

  /// Creates an [ClipEffect].
  ClipEffect({
    required this.clip,
    required this.borderRadius,
  });

  @override
  ClipEffect lerp(covariant ClipEffect other, double value) {
    return ClipEffect(
      clip: other.clip,
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, value)!,
    );
  }

  @override
  Widget apply(BuildContext context, Widget child) {
    if (clip == Clip.none) return child;
    if (borderRadius == BorderRadius.zero) {
      return ClipRect(
        clipBehavior: clip,
        child: child,
      );
    }
    return ClipRRect(
      clipBehavior: clip,
      borderRadius: borderRadius,
      child: child,
    );
  }

  @override
  List<Object?> get props => [clip, borderRadius];
}
