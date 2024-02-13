import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../hyper_effects.dart';

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

  /// Determines the direction in which each tape of characters will
  /// slide.
  final TextTapeSlideDirection tapeSlideDirection;

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

  /// {@macro flutter.painting.textPainter.textWidthBasis}
  final TextWidthBasis? textWidthBasis;

  /// {@macro dart.ui.textHeightBehavior}
  final ui.TextHeightBehavior? textHeightBehavior;

  /// Creates a new [RollingTextController] with the given parameters.
  RollingTextController({
    required this.oldText,
    required this.newText,
    required this.tapeStrategy,
    this.tapeSlideDirection = TextTapeSlideDirection.up,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
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
  late final Map<int, double> tapeHeights = {};

  /// Returns the height of a tape at the given index.
  double getTapeHeight(int tapeIndex) => tapeHeights[tapeIndex] ?? 0;

  /// Returns the height of the character that is actively visible
  /// or in frame at the given tape-index.
  ///
  /// [end] determines whether to return the height of the first or last
  /// character in the tape.
  TextSelection selectionAtTapeIndexNearValue(int tapeIndex, bool end) {
    final tape = tapes[tapeIndex];
    final mutatedTape = tape.characters.join('\n');

    if (end) {
      final lastCharacter = mutatedTape.characters.last.length;
      return TextSelection(
        baseOffset: mutatedTape.length - lastCharacter,
        extentOffset: mutatedTape.length,
      );
    } else {
      final firstCharacter = mutatedTape.characters.first.length;
      return TextSelection(baseOffset: 0, extentOffset: firstCharacter);
    }
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
    bool? directionReversed,
    Curve widthCurve = appleEaseInOut,
    Duration widthDuration = const Duration(milliseconds: 350),
    double? fixedWidth,
  }) {
    final painter = tapePainters[tapeIndex];
    directionReversed ??= switch (tapeSlideDirection) {
      TextTapeSlideDirection.up => false,
      TextTapeSlideDirection.down => true,
      TextTapeSlideDirection.alternating => tapeIndex % 2 == 0,
      TextTapeSlideDirection.random => Random('$tapeIndex'.hashCode).nextBool(),
    };
    final selection = selectionAtTapeIndexNearValue(
      tapeIndex,
      value > 0.5 ? !directionReversed : directionReversed,
    );
    final rects = painter
        .getBoxesForSelection(selection, boxHeightStyle: ui.BoxHeightStyle.max)
        .map((b) => b.toRect());
    final box = rects.isEmpty
        ? Rect.zero
        : rects.reduce((a, b) => a.expandToInclude(b));

    return CustomPaint(
      painter: RollingTextPainter(painter),
      child: AnimatedContainer(
        duration: widthDuration,
        curve: widthCurve,
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
  List<String> buildTapes() {
    final tapes = <String>[];
    final longest = max(oldText.characters.length, newText.characters.length);
    for (int i = 0; i < longest; i++) {
      final String tape = tapeStrategy.build(
        oldText.characters.length <= i
            ? _kZeroWidth
            : oldText.characters.elementAt(i),
        newText.characters.length <= i
            ? _kZeroWidth
            : newText.characters.elementAt(i),
      );

      tapes.add(switch (tapeSlideDirection) {
        TextTapeSlideDirection.up => tape,
        TextTapeSlideDirection.down => tape.characters.toList().reversed.join(''),
        TextTapeSlideDirection.alternating =>
          i % 2 == 0 ? tape : tape.characters.toList().reversed.join(''),
        TextTapeSlideDirection.random => Random('$i'.hashCode).nextBool()
            ? tape
            : tape.characters.toList().reversed.join(''),
      });
    }

    return tapes;
  }

  /// Builds a list of painters that represent each tape of characters
  /// from [tapes].
  List<TextPainter> buildTapePainters(List<String> tapes) {
    return [
      for (final String tape in tapes)
        buildTextPainter(tape.characters.join('\n')),
    ];
  }

  /// Calculates the height of each tape painter.
  Map<int, double> calculateTapeHeights() => {
        for (int i = 0; i < tapes.length; i++) i: calculateTapeHeight(i),
      };

  /// Calculates the height of a tape painter at the given index.
  double calculateTapeHeight(int index) {
    final tape = tapes[index];
    final mutatedTaped = tape.characters.join('\n');
    final painter = tapePainters[index];

    final TextSelection selection = TextSelection(
      baseOffset: 0,
      extentOffset: mutatedTaped.length,
    );
    final boxes = painter.getBoxesForSelection(
      selection,
      boxHeightStyle: ui.BoxHeightStyle.max,
    );

    // Don't include the last item.
    final oneLess = boxes.sublist(0, boxes.length - 1);

    return oneLess.isEmpty
        ? 0
        : oneLess
            .map((b) => b.toRect())
            .reduce((a, b) => a.expandToInclude(b))
            .height;
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
