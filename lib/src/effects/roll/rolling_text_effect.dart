import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../hyper_effects.dart';
import 'legacy/legacy_rolling_text.dart';
import 'shaped/shaped_rolling_text.dart';
import 'shaped/shaped_rolling_text_controller.dart';

export 'slide_direction.dart';
export 'symbol_tape_strategy.dart';
export 'tape_shaping_context.dart';

/// Rolls each character with a tape of characters individually
/// to form the [newText] from the [oldText].
class RollingTextEffect extends Effect {
  /// The text to display interpolating to.
  final String text;

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

  /// Determines the direction in which each tape of characters will
  /// slide.
  final TextTapeSlideDirection tapeSlideDirection;

  /// Determines how the text should be clipped. The rendered text is
  /// going to be a fixed-height box based on the font size.
  final Clip clipBehavior;

  /// Determines whether the tapes should be staggered or not.
  /// If set to true, the starting tapes will move and end their sliding
  /// faster than the ending tapes.
  final bool staggerTapes;

  /// Determines how harsh the stagger effect is. The higher the number,
  /// the more the stagger effect is softened,
  /// and the interpolation between each tape will more similar to each
  /// other.
  final int staggerSoftness;

  /// Determines whether the stagger effect should be reversed.
  /// Normally, the staggering makes the beginning letters move fast
  /// and the ending letters move slow. If this is set to true, the
  /// staggering will be reversed, so the beginning letters will move
  /// slow and the ending letters will move fast.
  final bool reverseStaggerDirection;

  /// Can be optionally used to set a fixed width for each tape.
  /// If null, the width of each tape will be the width of the active
  /// character in the tape.
  /// If not null, the width of each tape will be the fixed width provided.
  /// Note that this will allow the text's characters to potentially
  /// overlap each other.
  final double? fixedTapeWidth;

  /// Per-edge overflow (in logical pixels) allowed around each slot
  /// of the shaped rolling tape so cursive swashes, italic
  /// overshoots, entry/exit strokes, and upper / lower loops that
  /// extend beyond the cluster's advance box stay visible. Cluster
  /// bounds are layout boxes from Skia, not ink boxes, so without
  /// padding this ink is cut at the slot clip. Defaults to
  /// `EdgeInsets.zero` (tight clip). Only applies under
  /// [TextRenderMode.contextualCharacters]. Left/right fires only on
  /// the outer edges of the row (interior slots are covered by the
  /// neighbouring slot's paint); top/bottom fires on every slot.
  final EdgeInsets slotClipPadding;

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
  /// example, if the [data] is an English phrase followed by an Arabic phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Arabic phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Arabic phrase on
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

  /// Optional override for the render path. When null, the mode is resolved
  /// via [resolveTextRenderMode] (scope → global → fallback).
  final TextRenderMode? renderMode;

  /// Shaping-context strategy used under
  /// [TextRenderMode.contextualCharacters]. Ignored under the legacy path.
  final TapeShapingContext tapeShapingContext;

  /// Creates a [RollingTextEffect].
  const RollingTextEffect({
    required this.text,
    this.padding = EdgeInsets.zero,
    this.tapeStrategy = const ConsistentSymbolTapeStrategy(0),
    this.clipBehavior = Clip.hardEdge,
    this.tapeCurve,
    this.tapeSlideDirection = TextTapeSlideDirection.up,
    this.staggerTapes = true,
    this.staggerSoftness = 1,
    this.reverseStaggerDirection = false,
    this.fixedTapeWidth,
    this.slotClipPadding = EdgeInsets.zero,
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
    this.renderMode,
    this.tapeShapingContext = TapeShapingContext.endpointsCorrect,
  }) : textSpan = null;

  /// Pre-populates the shaped-text cache for a rolling transition from
  /// [oldText] to [newText], so the first frame of the animation doesn't
  /// pay the paragraph layout cost.
  ///
  /// Safe to call at app startup or in [State.initState]; it is a no-op
  /// under [TextRenderMode.independentCharacters] (which uses a different
  /// layout path and has its own lazy initialisation).
  static Future<void> prewarm({
    required String oldText,
    required String newText,
    required TextStyle style,
    required SymbolTapeStrategy tapeStrategy,
    TapeShapingContext tapeShapingContext = TapeShapingContext.endpointsCorrect,
    TextDirection? textDirection,
    TextScaler? textScaler,
    StrutStyle? strutStyle,
  }) async {
    final controller = ShapedRollingTextController(
      oldText: oldText,
      newText: newText,
      tapeStrategy: tapeStrategy,
      style: style,
      tapeShapingContext: tapeShapingContext,
      textDirection: textDirection,
      textScaler: textScaler,
      strutStyle: strutStyle,
    );
    // Force all frames to be built (populates the ShapedText LRU cache).
    for (int p = 0; p < controller.positionCount; p++) {
      controller.slotWidth(position: p); // builds every frame for the slot
    }
  }

  @override
  RollingTextEffect lerp(covariant RollingTextEffect other, double value) =>
      other;

  @override
  Widget apply(BuildContext context, Widget? child) {
    final mode = resolveTextRenderMode(context, override: renderMode);
    switch (mode) {
      // ignore: deprecated_member_use_from_same_package
      case TextRenderMode.independentCharacters:
        return LegacyRollingText(
          text: text,
          padding: padding,
          tapeStrategy: tapeStrategy,
          tapeCurve: tapeCurve,
          tapeSlideDirection: tapeSlideDirection,
          staggerTapes: staggerTapes,
          staggerSoftness: staggerSoftness,
          reverseStaggerDirection: reverseStaggerDirection,
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
      case TextRenderMode.contextualCharacters:
        // The ShapedRollingTextController requires a non-null TextStyle.
        // Coerce: fall back to DefaultTextStyle if style is null.
        final effectiveStyle =
            style ?? DefaultTextStyle.of(context).style;
        return ShapedRollingText(
          text: text,
          tapeStrategy: tapeStrategy,
          style: effectiveStyle,
          tapeShapingContext: tapeShapingContext,
          tapeSlideDirection: tapeSlideDirection,
          clipBehavior: clipBehavior,
          padding: padding,
          textDirection: textDirection,
          textAlign: textAlign,
          textScaler: textScaler,
          strutStyle: strutStyle,
          staggerTapes: staggerTapes,
          staggerSoftness: staggerSoftness,
          reverseStaggerDirection: reverseStaggerDirection,
          tapeCurve: tapeCurve,
          fixedTapeWidth: fixedTapeWidth,
          slotClipPadding: slotClipPadding,
        );
    }
  }

  @override
  List<Object?> get props => [
        text,
        padding,
        tapeCurve,
        tapeSlideDirection,
        staggerTapes,
        staggerSoftness,
        reverseStaggerDirection,
        tapeStrategy,
        fixedTapeWidth,
        slotClipPadding,
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
        renderMode,
        tapeShapingContext,
      ];
}
