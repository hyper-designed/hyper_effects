import 'package:flutter/widgets.dart';

/// Extension methods for [BuildContext].
extension BuildContextExtension on BuildContext {
  /// Returns the paint bounds of the widget in global coordinates.
  Rect? get globalPaintBounds {
    final renderObject = findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      return renderObject!.paintBounds.shift(
        Offset(translation.x, translation.y),
      );
    } else {
      return null;
    }
  }
}

/// Extension methods for [ScrollPosition].
extension ScrollPositionExt on ScrollPosition {
  /// Returns true if the scroll position is at the start of the scroll view.
  bool get atStart => pixels == minScrollExtent;

  /// Returns true if the scroll position is at the end of the scroll view.
  bool get atEnd => pixels == maxScrollExtent;
}

extension DoubleHelper on double? {
  double get clampUnderZero => this == null ? 0 : this! < 0 ? 0 : this!;

  bool get zeroIsFalse => this == null ? false : this! <= 0;

  bool get oneIsTrue => this == null ? true : this! >= 1;

  bool get middlePointBool => this == null ? false : this! >= 0.5;

  double get magnetize => this == null
      ? 0
      : this! < 0.5
          ? 0
          : 1;

  double get magnetizeReverse => this == null
      ? 1
      : this! < 0.5
          ? 1
          : 0;

  bool get isZero => this == null ? false : this! == 0;

  bool get isOne => this == null ? false : this! == 1;

  bool get isMiddlePoint => this == null ? false : this! == 0.5;
}
