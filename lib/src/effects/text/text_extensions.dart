import 'package:flutter/material.dart';

import '../../../hyper_effects.dart';

export 'rolling_text_effect.dart';

/// Provides a extension method to apply a [RollingTextEffect] to a [Widget].
extension TextEffectExt on Text {
  /// Rolls each character individually to form the [newText].
  ///
  /// The [tapeStrategy] parameter is used to determine the string of characters
  /// to create and roll through for each character index between the old and
  /// new text.
  ///
  /// The [tapeCurve] parameter is used to determine the curve each roll of
  /// symbol tape uses to slide up and down through its characters.
  /// If null, the same curve is used as the one provided to the [animate]
  /// function.
  ///
  /// The [staggerTapes] parameter is used to determine whether the tapes should
  /// be staggered or not. If set to true, the starting tapes will move and end
  /// their sliding faster than the ending tapes.
  ///
  /// The [clipBehavior] parameter is used to determine how the text should be
  /// clipped. The rendered text is going to be a fixed-height box based on the
  /// font size. If you want to clip the text on your own terms, set this
  /// parameter to [Clip.none].
  Widget roll(
    String newText, {
    SymbolTapeStrategy tapeStrategy = const ConsistentSymbolTapeStrategy(0),
    Curve? tapeCurve,
    bool staggerTapes = false,
    Clip clipBehavior = Clip.hardEdge,
  }) =>
      AnimatableEffect(
        end: RollingTextEffect(
          oldText: data ?? '',
          newText: newText,
          tapeStrategy: tapeStrategy,
          tapeCurve: tapeCurve,
          staggerTapes: staggerTapes,
          clipBehavior: clipBehavior,
          style: style,
          strutStyle: strutStyle,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          overflow: overflow,
          textScaler: textScaler,
          maxLines: maxLines,
          semanticsLabel: semanticsLabel,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
          selectionColor: selectionColor,
        ),
        child: this,
      );
}
