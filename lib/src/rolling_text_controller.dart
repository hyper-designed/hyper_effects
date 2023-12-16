import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../hyper_effects.dart';

const String _kZeroWidth = '​';

/// A controller for [RollingText] widgets.
class RollingTextController with ChangeNotifier {
  /// The text to display interpolating away from.
  final String oldText;

  /// The text to display interpolating to.
  final String newText;

  /// Used to determine the string of characters to create and
  /// roll through for each character index between the old and
  /// new text.
  final SymbolTapeStrategy tapeStrategy;

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

  /// Creates a new [RollingTextController] with the given parameters.
  RollingTextController({
    required this.oldText,
    required this.newText,
    required this.tapeStrategy,
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
  });

  /// A list containing strings that represent a tape of characters
  /// to roll through for each character index between the old and
  /// new text.
  late final List<String> tapes = [];

  /// A list containing painters that represent each tape of characters
  /// from [tapes].
  late final List<TextPainter> tapePainters = [];

  /// A cached map of tape heights for each tape painter.
  late final Map<int, double> tapeHeights;

  /// Multiplies the index by 2 to account for new-line \n characters.
  int _mapCharKitIndexToSelection(String charKit, int index) => index * 2;

  /// Returns the height of a tape at the given index.
  double getTapeHeight(int tapeIndex) => tapeHeights[tapeIndex] ?? 0;

  /// Returns the height of the character that is actively visible
  /// or in frame at the given tape-index.
  TextSelection textSelectionAtCharKitIndexNearValue(
      int charKitIndex, double value) {
    final charKit = tapes[charKitIndex];
    final length = charKit.length;
    final maxIndex = length - 1;
    final int effectiveIndex = (value * maxIndex).clamp(0, maxIndex).round();
    final mutatedIndex = _mapCharKitIndexToSelection(charKit, effectiveIndex);
    final TextSelection selection = TextSelection(
      baseOffset: mutatedIndex,
      extentOffset: mutatedIndex + 1,
    );
    return selection;
  }

  /// Lays out the text painters and caches the tape heights.
  void layout() {
    disposePainters();

    tapes
      ..clear()
      ..addAll(buildTapes());
    tapePainters
      ..clear()
      ..addAll(buildTapePainters(tapes));

    for (final TextPainter painter in tapePainters) {
      painter.layout();
    }

    tapeHeights
      ..clear()
      ..addAll(calculateTapeHeights());
  }

  /// Disposes of the text painters.
  void disposePainters() {
    for (final TextPainter painter in tapePainters) {
      painter.dispose();
    }
  }

  /// Returns a [Widget] that paints the tape of text at the given index.
  Widget paintTape(
    int tapeIndex,
    double value, {
    Curve curve = appleEaseInOut,
    Duration duration = const Duration(milliseconds: 350),
    double? fixedWidth,
  }) {
    final painter = tapePainters[tapeIndex];
    final selection = textSelectionAtCharKitIndexNearValue(tapeIndex, value);
    final box = painter
        .getBoxesForSelection(selection, boxHeightStyle: ui.BoxHeightStyle.max)
        .map((b) => b.toRect())
        .reduce((a, b) => a.expandToInclude(b));

    return CustomPaint(
      painter: RollingTextPainter(painter),
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        width: fixedWidth ?? box.width,
        height: box.height,
      ),
    );
  }

  @override
  void dispose() {
    disposePainters();
    super.dispose();
  }

  /// Builds a list of tapes that represent the characters to roll through
  /// for each character index between the old and new text.
  List<String> buildTapes() => [
        for (int i = 0; i < max(oldText.length, newText.length); i++)
          tapeStrategy.build(
            oldText.length <= i ? _kZeroWidth : oldText[i],
            newText.length <= i ? _kZeroWidth : newText[i],
          ),
      ];

  /// Builds a list of painters that represent each tape of characters
  /// from [tapes].
  List<TextPainter> buildTapePainters(List<String> charKits) {
    return [
      for (final String charKit in charKits)
        buildTextPainter(charKit.split('').join('\n')),
    ];
  }

  /// Calculates the height of each tape painter.
  Map<int, double> calculateTapeHeights() => {
        for (int i = 0; i < tapes.length; i++) i: calculateTapeHeight(i),
      };

  /// Calculates the height of a tape painter at the given index.
  double calculateTapeHeight(int index) {
    final charKit = tapes[index];
    final painter = tapePainters[index];

    final int mutatedIndex =
        _mapCharKitIndexToSelection(charKit, charKit.length - 1);
    final TextSelection selection = TextSelection(
      baseOffset: 0,
      extentOffset: mutatedIndex + 1,
    );
    final boxes = painter.getBoxesForSelection(
      selection,
      boxHeightStyle: ui.BoxHeightStyle.max,
    );

    final length = charKit.length;
    double sum = 0;
    for (int i = 0; i < length; i++) {
      if (i >= length - 1) break;
      final box = boxes[i];
      sum += box.toRect().height;
    }

    return sum;
  }

  /// Builds a [TextPainter] with the given [text].
  TextPainter buildTextPainter(String text) => TextPainter(
        text: TextSpan(
          text: text,
          style: style,
        ),
        textDirection: textDirection ?? TextDirection.ltr,
        textAlign: textAlign ?? TextAlign.start,
        textWidthBasis: textWidthBasis ?? TextWidthBasis.parent,
        textHeightBehavior: textHeightBehavior,
        textScaler: textScaler ?? TextScaler.noScaling,
        strutStyle: strutStyle,
        maxLines: maxLines,
        locale: locale,
        ellipsis: overflow == TextOverflow.ellipsis ? '\u2026' : null,
      );
}

/// A [CustomPainter] that paints a [TextPainter].
class RollingTextPainter extends CustomPainter {
  /// The [TextPainter] to paint.
  final TextPainter painter;

  /// Creates a new [RollingTextPainter] with the given [painter].
  const RollingTextPainter(this.painter);

  @override
  void paint(Canvas canvas, Size size) => painter.paint(canvas, Offset.zero);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
