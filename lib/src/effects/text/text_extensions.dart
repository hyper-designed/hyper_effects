import 'package:flutter/material.dart';

import '../../../hyper_effects.dart';

export 'rolling_text_effect.dart';

/// Provides a extension method to apply a [RollingTextEffect] to a [Widget].
extension TextEffectExt on Text {

  /// Rolls each character individually to form the [newText].
  ///
  /// The [padding] is the internal padding to apply between the row of symbol
  /// tapes and the clipping mask.
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
  /// The [staggerSoftness] parameter is used to determine how harsh the stagger
  /// effect is. The higher the number, the more the stagger effect is softened,
  /// and the interpolation between each tape will more similar to each other.
  ///
  /// A value of 1 will result in the animation timeline being evenly split
  /// from the starting tape to the end tape, so the first tape will have the
  /// shortest duration of sliding time, and the last tape will have the longest
  /// duration of sliding time.
  ///
  /// A value of 10 will result in the animation timeline being split into
  /// (text's length + 10) equal parts, so the first tape will have a duration
  /// of sliding time that is very similar to the last tape.
  ///
  /// The [clipBehavior] parameter is used to determine how the text should be
  /// clipped. The rendered text is going to be a fixed-height box based on the
  /// font size. If you want to clip the text on your own terms, set this
  /// parameter to [Clip.none].
  ///
  /// The [symbolDistanceMultiplier] parameter is used to determine the height of
  /// each symbol in each tape relative to the font size. If the font size is 32,
  /// the final height of the entire widget is fontSize * lineHeightMultiplier.
  /// The default multiplier is 1.
  ///
  /// The [interpolateWidthPerSymbol] parameter is used to determine whether
  /// the width of each tape should be interpolated between the width of the
  /// old and new text as the symbols roll or if the width should interpolate
  /// directly between the starting and ending texts.
  ///
  /// The [fixedTapeWidth] parameter can be optionally used to set a fixed width
  /// for each tape.
  /// If null, the width of each tape will be the width of the active character
  /// in the tape.
  /// If not null, the width of each tape will be the fixed width provided.
  /// Note that this will allow the text's characters to potentially overlap
  /// each other.
  ///
  /// The [widthDuration] parameter is used to determine the duration of the
  /// width animation of each tape.
  /// If null, the same duration is used as the one provided to the [animate]
  /// function.
  ///
  /// The [widthCurve] parameter is used to determine the curve of the
  /// width animation of each tape.
  /// If null, the same curve is used as the one provided to the [animate]
  /// function.
  Widget roll(
    String newText, {
    EdgeInsets padding = EdgeInsets.zero,
    SymbolTapeStrategy tapeStrategy = const ConsistentSymbolTapeStrategy(0),
    Curve? tapeCurve,
    bool staggerTapes = true,
    int staggerSoftness = 10,
    Clip clipBehavior = Clip.hardEdge,
    double symbolDistanceMultiplier = 1,
    double? fixedTapeWidth,
    Duration? widthDuration,
    Curve? widthCurve,
  }) {
    assert(
      symbolDistanceMultiplier > 0,
      'lineHeightMultiplier must be greater than 0.',
    );
    assert(
      staggerSoftness > 0,
      'staggerSoftness must be greater than 0.',
    );
    assert(
      !(data ?? '').contains('\n') && !newText.contains('\n'),
      'Rolling text effect does not support multiline text.',
    );

    return Builder(builder: (context) {
      final TextStyle defaultStyle =
          DefaultTextStyle.of(context).style.copyWith(inherit: true);
      final TextStyle effectiveStyle =
          style != null ? defaultStyle.merge(style) : defaultStyle;

      return AnimatableEffect(
        end: RollingTextEffect(
          oldText: data ?? '',
          newText: newText,
          padding: padding,
          tapeStrategy: tapeStrategy,
          tapeCurve: tapeCurve,
          staggerTapes: staggerTapes,
          staggerSoftness: staggerSoftness,
          clipBehavior: clipBehavior,
          style: effectiveStyle,
          fixedTapeWidth: fixedTapeWidth,
          widthDuration: widthDuration,
          widthCurve: widthCurve,
          strutStyle: StrutStyle(
            fontSize: effectiveStyle.fontSize,
            height: 1,
            forceStrutHeight: true,
            leading: symbolDistanceMultiplier - 1,
          ),
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
    });
  }
}
