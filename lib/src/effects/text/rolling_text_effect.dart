import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../rolling_text_controller.dart';

export 'symbol_tape_strategy.dart';

/// An [Effect] that applies a Text to a [Widget].
class RollingTextEffect extends Effect {
  /// The text to display interpolating away from.
  final String oldText;

  /// The text to display interpolating to.
  final String newText;

  /// The strategy to use to create the tape of characters to interpolate to.
  final SymbolTapeStrategy tapeStrategy;

  final Curve? tapeCurve;

  final bool staggerTapes;

  final Clip clipBehavior;

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
    required this.tapeCurve,
    required this.staggerTapes,
    required this.tapeStrategy,
    this.clipBehavior = Clip.hardEdge,
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
  RollingTextEffect lerp(covariant RollingTextEffect other, double value) {
    return other;
  }

  @override
  Widget apply(BuildContext context, Widget child) {
    return RollingText(
      newText: newText,
      oldText: oldText,
      rollStrategy: tapeStrategy,
      tapeCurve: tapeCurve,
      staggerTapes: staggerTapes,
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
        tapeCurve,
        staggerTapes,
        tapeStrategy,
        clipBehavior,
        style,
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

class RollingText extends StatefulWidget {
  final String oldText;
  final String newText;
  final SymbolTapeStrategy rollStrategy;

  final Curve? tapeCurve;

  final bool staggerTapes;

  final Clip clipBehavior;

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

  const RollingText({
    super.key,
    required this.oldText,
    required this.newText,
    required this.rollStrategy,
    required this.tapeCurve,
    required this.staggerTapes,
    this.clipBehavior = Clip.hardEdge,
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
  late RollingTextController rollingTextPainter = RollingTextController(
    oldText: widget.oldText,
    newText: widget.newText,
    rollStrategy: widget.rollStrategy,
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
    selectionColor: widget.selectionColor,
  )..layout();

  @override
  void didUpdateWidget(covariant RollingText oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Account for all parameters except for value.
    if (oldWidget.oldText == widget.oldText &&
        oldWidget.newText == widget.newText &&
        oldWidget.rollStrategy == widget.rollStrategy &&
        oldWidget.staggerTapes == widget.staggerTapes &&
        oldWidget.tapeCurve == widget.tapeCurve &&
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

    rollingTextPainter = RollingTextController(
      oldText: widget.oldText,
      newText: widget.newText,
      rollStrategy: widget.rollStrategy,
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
      selectionColor: widget.selectionColor,
    )..layout();
  }

  @override
  void dispose() {
    rollingTextPainter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final before = widget.oldText;
    final after = widget.newText;
    final beforeL = before.length;
    final afterL = after.length;
    final longest = max(beforeL, afterL);

    final EffectAnimationValue? effectAnimationValue =
        EffectAnimationValue.maybeOf(context);
    final double timeValue = effectAnimationValue?.linearValue ?? 1;
    final Curve curve =
        widget.tapeCurve ?? effectAnimationValue?.curve ?? Curves.linear;

    Widget result = ClipRect(
      clipBehavior: widget.clipBehavior,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int charIndex = 0; charIndex < longest; charIndex++)
            Builder(builder: (context) {
              final double charPercent = (charIndex + 1) / (longest + 1);
              final double scaledVal = timeValue / charPercent;
              final double effectiveVal =
                  curve.transform(scaledVal.clamp(0, 1));

              final dist = rollingTextPainter.charKitHeight(charIndex);
              final transformedValue = effectiveVal * -1 * dist;

              return Transform.translate(
                offset: Offset(0, transformedValue),
                child: rollingTextPainter.paintIndex(
                  charIndex,
                  effectiveVal,
                  // fixedWidth: 25,
                ),
              );
            }),
        ],
      ),
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
