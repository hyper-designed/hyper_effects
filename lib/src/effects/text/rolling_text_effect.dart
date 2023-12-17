import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../rolling_text_controller.dart';

export 'symbol_tape_strategy.dart';

/// Rolls each character with a tape of characters individually
/// to form the [newText] from the [oldText].
class RollingTextEffect extends Effect {
  /// The text to display interpolating away from.
  final String oldText;

  /// The text to display interpolating to.
  final String newText;

  /// Internal padding to apply between the row of symbol tapes and
  /// the clipping mask.
  final EdgeInsets padding;

  /// Used to determine the string of characters to create and
  /// roll through for each character index between the old and
  /// new text.
  final SymbolTapeStrategy tapeStrategy;

  /// Used to determine the curve each roll of symbol tape uses to slide up
  /// and down through its characters. If null, the same curve is used as
  /// the one provided to the [animate] function.
  final Curve? tapeCurve;

  /// Determines whether the tapes should be staggered or not.
  /// If set to true, the starting tapes will move and end their sliding
  /// faster than the ending tapes.
  final bool staggerTapes;

  /// Determines how the text should be clipped. The rendered text is
  /// going to be a fixed-height box based on the font size.
  final Clip clipBehavior;

  /// Determines how harsh the stagger effect is. The higher the number,
  /// the more the stagger effect is softened,
  /// and the interpolation between each tape will more similar to each
  /// other.
  final int staggerSoftness;

  /// Determines whether the width of each tape should be interpolated
  /// between the width of the old and new text as the symbols roll
  /// or if the width should interpolate directly between the starting
  /// and ending texts.
  final bool interpolateWidthPerSymbol;

  /// Can be optionally used to set a fixed width for each tape.
  /// If null, the width of each tape will be the width of the active
  /// character in the tape.
  /// If not null, the width of each tape will be the fixed width provided.
  /// Note that this will allow the text's characters to potentially
  /// overlap each other.
  final double? fixedTapeWidth;

  /// The [widthDuration] parameter is used to determine the duration of the
  /// width animation of each tape.
  /// If null, the same duration is used as the one provided to the [animate]
  /// function.
  final Duration? widthDuration;

  /// The [widthCurve] parameter is used to determine the curve of the
  /// width animation of each tape.
  /// If null, the same curve is used as the one provided to the [animate]
  /// function.
  final Curve? widthCurve;

  /// The text to display as a [InlineSpan].
  ///
  /// This will be null if [data] is provided instead.
  final InlineSpan? textSpan;

  /// If non-null, the style to use for this text.
  ///
  /// If the style's "inherit" property is true, the style will be merged with
  /// the closest enclosing [DefaultTextStyle]. Otherwise, the style will
  /// replace the closest enclosing [DefaultTextStyle].
  final TextStyle? style;

  /// The strut style to use. Strut style defines the strut, which sets minimum
  /// vertical layout metrics.
  ///
  /// Omitting or providing null will disable strut.
  ///
  /// Omitting or providing null for any properties of [StrutStyle] will result in
  /// default values being used. It is highly recommended to at least specify a
  /// [StrutStyle.fontSize].
  ///
  /// See [StrutStyle] for details.
  final StrutStyle? strutStyle;

  /// How the text should be aligned horizontally.
  final TextAlign? textAlign;

  /// The directionality of the text.
  ///
  /// This decides how [textAlign] values like [TextAlign.start] and
  /// [TextAlign.end] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [data] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// Defaults to the ambient [Directionality], if any.
  final TextDirection? textDirection;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [RenderParagraph.locale] for more information.
  final Locale? locale;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool? softWrap;

  /// How visual overflow should be handled.
  ///
  /// If this is null [TextStyle.overflow] will be used, otherwise the value
  /// from the nearest [DefaultTextStyle] ancestor will be used.
  final TextOverflow? overflow;

  /// {@macro flutter.painting.textPainter.textScaler}
  final TextScaler? textScaler;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  ///
  /// If this is null, but there is an ambient [DefaultTextStyle] that specifies
  /// an explicit number for its [DefaultTextStyle.maxLines], then the
  /// [DefaultTextStyle] value will take precedence. You can use a [RichText]
  /// widget directly to entirely override the [DefaultTextStyle].
  final int? maxLines;

  /// {@template flutter.widgets.Text.semanticsLabel}
  /// An alternative semantics label for this text.
  ///
  /// If present, the semantics of this widget will contain this value instead
  /// of the actual text. This will overwrite any of the semantics labels applied
  /// directly to the [TextSpan]s.
  ///
  /// This is useful for replacing abbreviations or shorthands with the full
  /// text value:
  ///
  /// ```dart
  /// const Text(r'$$', semanticsLabel: 'Double dollars')
  /// ```
  /// {@endtemplate}
  final String? semanticsLabel;

  /// {@macro flutter.painting.textPainter.textWidthBasis}
  final TextWidthBasis? textWidthBasis;

  /// {@macro dart.ui.textHeightBehavior}
  final ui.TextHeightBehavior? textHeightBehavior;

  /// The color to use when painting the selection.
  ///
  /// This is ignored if [SelectionContainer.maybeOf] returns null
  /// in the [BuildContext] of the [Text] widget.
  ///
  /// If null, the ambient [DefaultSelectionStyle] is used (if any); failing
  /// that, the selection color defaults to [DefaultSelectionStyle.defaultColor]
  /// (semi-transparent grey).
  final Color? selectionColor;

  /// Creates a [RollingTextEffect].
  const RollingTextEffect({
    required this.oldText,
    required this.newText,
    this.padding = EdgeInsets.zero,
    this.tapeStrategy = const ConsistentSymbolTapeStrategy(0),
    this.clipBehavior = Clip.hardEdge,
    this.tapeCurve,
    this.staggerTapes = true,
    this.staggerSoftness = 1,
    this.interpolateWidthPerSymbol = false,
    this.fixedTapeWidth,
    this.widthDuration,
    this.widthCurve,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;

  @override
  RollingTextEffect lerp(covariant RollingTextEffect other, double value) =>
      other;

  @override
  Widget apply(BuildContext context, Widget child) {
    return RollingText(
      newText: newText,
      oldText: oldText,
      padding: padding,
      tapeStrategy: tapeStrategy,
      tapeCurve: tapeCurve,
      staggerTapes: staggerTapes,
      staggerSoftness: staggerSoftness,
      interpolateWidthPerSymbol: interpolateWidthPerSymbol,
      fixedTapeWidth: fixedTapeWidth,
      widthDuration: widthDuration,
      widthCurve: widthCurve,
      clipBehavior: clipBehavior,
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      selectionColor: selectionColor,
    );
  }

  @override
  List<Object?> get props => [
        oldText,
        newText,
        padding,
        tapeCurve,
        staggerTapes,
        staggerSoftness,
        tapeStrategy,
        interpolateWidthPerSymbol,
        fixedTapeWidth,
        widthDuration,
        widthCurve,
        clipBehavior,
        style,
        strutStyle,
        textSpan,
        textAlign,
        textDirection,
        locale,
        softWrap,
        overflow,
        textScaler,
        maxLines,
        semanticsLabel,
        textWidthBasis,
        textHeightBehavior,
        selectionColor,
      ];
}

/// A StatefulWidget that provides a rolling text effect.
///
/// This widget takes in an old text and a new text, and creates a rolling
/// animation from the old text to the new text. The rolling effect can be
/// customized with various parameters such as the curve of the roll, whether
/// the tapes should be staggered, the softness of the stagger, and more.
///
/// The text style, alignment, directionality, and other text properties can
/// also be customized.
class RollingText extends StatefulWidget {
  /// The text to display interpolating away from.
  final String oldText;

  /// The text to display interpolating to.
  final String newText;

  /// Internal padding to apply between the row of symbol tapes and
  /// the clipping mask.
  final EdgeInsets padding;

  /// Used to determine the string of characters to create and
  /// roll through for each character index between the old and
  /// new text.
  final SymbolTapeStrategy tapeStrategy;

  /// Used to determine the curve each roll of symbol tape uses to slide up
  /// and down through its characters. If null, the same curve is used as
  /// the one provided to the [animate] function.
  final Curve? tapeCurve;

  /// Determines whether the tapes should be staggered or not.
  /// If set to true, the starting tapes will move and end their sliding
  /// faster than the ending tapes.
  final bool staggerTapes;

  /// Determines how the text should be clipped. The rendered text is
  /// going to be a fixed-height box based on the font size.
  final Clip clipBehavior;

  /// Determines how harsh the stagger effect is. The higher the number,
  /// the more the stagger effect is softened,
  /// and the interpolation between each tape will more similar to each
  /// other.
  final int staggerSoftness;

  /// Determines whether the width of each tape should be interpolated
  /// between the width of the old and new text as the symbols roll
  /// or if the width should interpolate directly between the starting
  /// and ending texts.
  final bool interpolateWidthPerSymbol;

  /// Can be optionally used to set a fixed width for each tape.
  /// If null, the width of each tape will be the width of the active
  /// character in the tape.
  /// If not null, the width of each tape will be the fixed width provided.
  /// Note that this will allow the text's characters to potentially
  /// overlap each other.
  final double? fixedTapeWidth;

  /// The [widthDuration] parameter is used to determine the duration of the
  /// width animation of each tape.
  /// If null, the same duration is used as the one provided to the [animate]
  /// function.
  final Duration? widthDuration;

  /// The [widthCurve] parameter is used to determine the curve of the
  /// width animation of each tape.
  /// If null, the same curve is used as the one provided to the [animate]
  /// function.
  final Curve? widthCurve;

  /// If non-null, the style to use for this text.
  ///
  /// If the style's "inherit" property is true, the style will be merged with
  /// the closest enclosing [DefaultTextStyle]. Otherwise, the style will
  /// replace the closest enclosing [DefaultTextStyle].
  final TextStyle? style;

  /// {@macro flutter.painting.textPainter.strutStyle}
  final StrutStyle? strutStyle;

  /// How the text should be aligned horizontally.
  final TextAlign? textAlign;

  /// The directionality of the text.
  ///
  /// This decides how [textAlign] values like [TextAlign.start] and
  /// [TextAlign.end] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [data] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// Defaults to the ambient [Directionality], if any.
  final TextDirection? textDirection;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [RenderParagraph.locale] for more information.
  final Locale? locale;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool? softWrap;

  /// How visual overflow should be handled.
  ///
  /// If this is null [TextStyle.overflow] will be used, otherwise the value
  /// from the nearest [DefaultTextStyle] ancestor will be used.
  final TextOverflow? overflow;

  /// {@macro flutter.painting.textPainter.textScaler}
  final TextScaler? textScaler;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  ///
  /// If this is null, but there is an ambient [DefaultTextStyle] that specifies
  /// an explicit number for its [DefaultTextStyle.maxLines], then the
  /// [DefaultTextStyle] value will take precedence. You can use a [RichText]
  /// widget directly to entirely override the [DefaultTextStyle].
  final int? maxLines;

  /// {@template flutter.widgets.Text.semanticsLabel}
  /// An alternative semantics label for this text.
  ///
  /// If present, the semantics of this widget will contain this value instead
  /// of the actual text. This will overwrite any of the semantics labels applied
  /// directly to the [TextSpan]s.
  ///
  /// This is useful for replacing abbreviations or shorthands with the full
  /// text value:
  ///
  /// ```dart
  /// const Text(r'$$', semanticsLabel: 'Double dollars')
  /// ```
  /// {@endtemplate}
  final String? semanticsLabel;

  /// {@macro flutter.painting.textPainter.textWidthBasis}
  final TextWidthBasis? textWidthBasis;

  /// {@macro dart.ui.textHeightBehavior}
  final ui.TextHeightBehavior? textHeightBehavior;

  /// The color to use when painting the selection.
  ///
  /// This is ignored if [SelectionContainer.maybeOf] returns null
  /// in the [BuildContext] of the [Text] widget.
  ///
  /// If null, the ambient [DefaultSelectionStyle] is used (if any); failing
  /// that, the selection color defaults to [DefaultSelectionStyle.defaultColor]
  /// (semi-transparent grey).
  final Color? selectionColor;

  /// Creates a new [RollingText] with the given parameters.
  const RollingText({
    super.key,
    required this.oldText,
    required this.newText,
    this.padding = EdgeInsets.zero,
    this.tapeStrategy = const ConsistentSymbolTapeStrategy(0),
    this.tapeCurve,
    this.clipBehavior = Clip.hardEdge,
    this.staggerTapes = true,
    this.staggerSoftness = 1,
    this.interpolateWidthPerSymbol = false,
    this.fixedTapeWidth,
    this.widthDuration,
    this.widthCurve,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  @override
  State<RollingText> createState() => _RollingTextState();
}

class _RollingTextState extends State<RollingText> {
  late RollingTextController rollingTextPainter = createRollingTextPainter();

  @override
  void didUpdateWidget(covariant RollingText oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Account for all parameters except for value.
    if (oldWidget.oldText == widget.oldText &&
        oldWidget.newText == widget.newText &&
        oldWidget.padding == widget.padding &&
        oldWidget.tapeStrategy == widget.tapeStrategy &&
        oldWidget.staggerTapes == widget.staggerTapes &&
        oldWidget.tapeCurve == widget.tapeCurve &&
        oldWidget.staggerSoftness == widget.staggerSoftness &&
        oldWidget.interpolateWidthPerSymbol ==
            widget.interpolateWidthPerSymbol &&
        oldWidget.fixedTapeWidth == widget.fixedTapeWidth &&
        oldWidget.widthCurve == widget.widthCurve &&
        oldWidget.widthDuration == widget.widthDuration &&
        oldWidget.clipBehavior == widget.clipBehavior &&
        oldWidget.style == widget.style &&
        oldWidget.strutStyle == widget.strutStyle &&
        oldWidget.textAlign == widget.textAlign &&
        oldWidget.textDirection == widget.textDirection &&
        oldWidget.locale == widget.locale &&
        oldWidget.softWrap == widget.softWrap &&
        oldWidget.overflow == widget.overflow &&
        oldWidget.textScaler == widget.textScaler &&
        oldWidget.textWidthBasis == widget.textWidthBasis &&
        oldWidget.textHeightBehavior == widget.textHeightBehavior &&
        oldWidget.maxLines == widget.maxLines &&
        oldWidget.semanticsLabel == widget.semanticsLabel &&
        oldWidget.selectionColor == widget.selectionColor) return;

    rollingTextPainter.dispose();
    rollingTextPainter = createRollingTextPainter();
  }

  RollingTextController createRollingTextPainter() => RollingTextController(
        oldText: widget.oldText,
        newText: widget.newText,
        tapeStrategy: widget.tapeStrategy,
        style: widget.style,
        strutStyle: widget.strutStyle,
        textAlign: widget.textAlign,
        textDirection: widget.textDirection,
        locale: widget.locale,
        softWrap: widget.softWrap,
        overflow: widget.overflow,
        textScaler: widget.textScaler,
        textWidthBasis: widget.textWidthBasis,
        textHeightBehavior: widget.textHeightBehavior,
        maxLines: widget.maxLines,
        semanticsLabel: widget.semanticsLabel,
      )..layout();

  @override
  void dispose() {
    rollingTextPainter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int longest = max(widget.oldText.length, widget.newText.length);

    final effectAnimationValue = EffectAnimationValue.maybeOf(context);
    final timeValue = effectAnimationValue?.linearValue ?? 1;
    final curve =
        widget.tapeCurve ?? effectAnimationValue?.curve ?? Curves.linear;
    final widthCurve = widget.widthCurve ?? curve;
    final duration =
        widget.widthDuration ?? effectAnimationValue?.duration ?? Duration.zero;

    // Width curve cannot ease outside like ease Back, so we need to
    // account for that.
    assert(
      widthCurve != Curves.easeOutBack &&
          widthCurve != Curves.easeInBack &&
          widthCurve != Curves.easeInOutBack &&
          widthCurve != Curves.elasticIn &&
          widthCurve != Curves.elasticOut &&
          widthCurve != Curves.elasticInOut,
      'Width curve cannot be an ease out back, ease in back, ease in out back, elastic in, elastic out, or elastic in out curve.'
      'If you need those curves, specify the width curve explicitly using the widthCurve parameter.',
    );

    Widget result = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int charIndex = 0; charIndex < longest; charIndex++)
          Builder(builder: (context) {
            final double scaledVal;
            if (widget.staggerTapes) {
              final int softness = widget.staggerSoftness;
              final double charPercent =
                  (charIndex + softness) / (longest + softness);
              scaledVal = timeValue / charPercent;
            } else {
              scaledVal = timeValue;
            }
            final double effectiveVal = curve.transform(scaledVal.clamp(0, 1));

            final tapeHeight = rollingTextPainter.getTapeHeight(charIndex);
            final transformedValue = effectiveVal * -1 * tapeHeight;

            return Transform.translate(
              offset: Offset(0, transformedValue),
              child: rollingTextPainter.paintTape(
                charIndex,
                effectiveVal,
                fixedWidth: widget.fixedTapeWidth,
                interpolateWidthPerSymbol: widget.interpolateWidthPerSymbol,
                widthDuration: widget.widthDuration ?? duration,
                widthCurve: widthCurve,
              ),
            );
          }),
      ],
    );

    if (widget.padding != EdgeInsets.zero) {
      result = Padding(
        padding: widget.padding,
        child: result,
      );
    }

    result = ClipRect(
      clipBehavior: widget.clipBehavior,
      child: result,
    );

    // Retain semantics label if present.
    if (widget.semanticsLabel != null) {
      result = Semantics(
        textDirection: widget.textDirection,
        label: widget.semanticsLabel,
        child: ExcludeSemantics(
          child: result,
        ),
      );
    }

    return result;
  }
}
