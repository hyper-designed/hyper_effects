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
