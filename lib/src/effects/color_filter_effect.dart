import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../hyper_effects.dart';

/// Provides a extension method to apply an [ColorFilterEffect] to a [Widget].
extension ColorFilterEffectExtension on Widget {
  /// Applies an [ColorFilterEffect] to a [Widget].
  Widget modulate({
    Color? color,
    BlendMode mode = BlendMode.overlay,
    List<double>? matrix,
    Color? colorFrom,
    List<double>? fromMatrix,
  }) =>
      this.color(
        color: color,
        mode: mode,
        matrix: matrix,
        colorFrom: colorFrom,
        fromMatrix: fromMatrix,
      );

  /// Applies an [ColorFilterEffect] to a [Widget].
  Widget color({
    Color? color,
    BlendMode mode = BlendMode.overlay,
    List<double>? matrix,
    Color? colorFrom,
    List<double>? fromMatrix,
  }) {
    return EffectWidget(
      start: colorFrom == null
          ? null
          : ColorFilterEffect(
              color: colorFrom,
              mode: mode,
              matrix: fromMatrix,
            ),
      end: ColorFilterEffect(
        color: color,
        mode: mode,
        matrix: matrix,
      ),
      child: this,
    );
  }
}

/// An [Effect] that applies an opacity to a [Widget].
class ColorFilterEffect extends Effect {
  /// The color to apply.
  final Color? color;

  /// The blend mode to apply.
  final BlendMode mode;

  /// The matrix to apply.
  final List<double>? matrix;

  /// Creates an [ColorFilterEffect].
  ColorFilterEffect({
    this.color,
    required this.mode,
    this.matrix,
  }) : assert(
          color != null || matrix != null,
          'Either color or matrix4 must be provided.',
        );

  @override
  ColorFilterEffect lerp(covariant ColorFilterEffect other, double value) {
    final List<double> lerped = [];
    for (final (index, item) in (matrix ?? []).indexed) {
      final double? val = lerpDouble(
        item,
        other.matrix?[index],
        value.clamp(0, 1),
      );
      lerped.add(val ?? 0);
    }
    return ColorFilterEffect(
      color: color != null
          ? Color.lerp(
              color,
              other.color,
              value.clamp(0, 1),
            )
          : null,
      matrix: lerped,
      mode: mode,
    );
  }

  @override
  Widget apply(BuildContext context, Widget? child) {
    return ColorFiltered(
      colorFilter: color != null
          ? ColorFilter.mode(color!, mode)
          : ColorFilter.matrix(matrix!),
      child: child,
    );
  }

  @override
  ColorFilterEffect idle() => ColorFilterEffect(mode: mode);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColorFilterEffect &&
        other.runtimeType == runtimeType &&
        other.color == color &&
        other.mode == mode &&
        listEquals(other.matrix, matrix);
  }

  @override
  int get hashCode => Object.hash(
        color,
        mode,
        matrix == null ? null : Object.hashAll(matrix!),
      );

  @override
  String toString() =>
      'ColorFilterEffect(color: $color, mode: $mode, matrix: $matrix)';
}

/// A set of predefined color filter matrices.
class ColorFilterMatrix {
  ColorFilterMatrix._();

  /// A matrix that inverts the colors.
  static const List<double> invert = <double>[
    -1,
    0,
    0,
    0,
    255,
    0,
    -1,
    0,
    0,
    255,
    0,
    0,
    -1,
    0,
    255,
    0,
    0,
    0,
    1,
    0,
  ];

  /// A matrix that turns the image into sepia-tone.
  static const List<double> sepia = <double>[
    0.393,
    0.769,
    0.189,
    0,
    0,
    0.349,
    0.686,
    0.168,
    0,
    0,
    0.272,
    0.534,
    0.131,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  /// A matrix that turns the image into greyscale.
  static const List<double> greyscale = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  /// A matrix that does nothing.
  static const List<double> identity = <double>[
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}
