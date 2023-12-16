import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../hyper_effects.dart';

const String _kLowerAlphabet = 'abcdefghijklmnopqrstuvwxyz ';
const String _kUpperAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const String _kNumbers = '0123456789';
const String _kSymbols = '`~!@#\$%^&*()-_=+[{]}\\|;:\'",<.>/?';
const String _kSpace = ' ';
const String _kAlphabet = _kLowerAlphabet + _kUpperAlphabet;
const String _kAlphanumeric = _kAlphabet + _kNumbers;
const String _kAll = _kAlphanumeric + _kSymbols;

extension _StringHelper on String {
  bool isSymbol() => _kSymbols.contains(this);

  bool isNumber() => _kNumbers.contains(this);

  bool isSpace() => _kSpace.contains(this);

  bool isLowerAlphabet() => _kLowerAlphabet.contains(this);

  bool isUpperAlphabet() => _kUpperAlphabet.contains(this);
}

class RollingTextController with ChangeNotifier {
  final String oldText;
  final String newText;
  final SymbolTapeStrategy rollStrategy;

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
  /// in the [BuildContext] of the [Text]
  ///
  /// If null, the ambient [DefaultSelectionStyle] is used (if any); failing
  /// that, the selection color defaults to [DefaultSelectionStyle.defaultColor]
  /// (semi-transparent grey).
  final Color? selectionColor;

  RollingTextController({
    required this.oldText,
    required this.newText,
    required this.rollStrategy,
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

  late List<String> charKits = buildCharKits();
  late List<TextPainter> charKitPainters = buildPainters(charKits);

  String charKitAtIndex(int index) {
    return charKits[index];
  }

  int mapCharKitIndexToSelection(String charKit, int index) {
    return index * 2;
  }

  double charKitHeight(int index) {
    final charKit = charKits[index];
    final painter = charKitPainters[index];

    final int mutatedIndex =
        mapCharKitIndexToSelection(charKit, charKit.length - 1);
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

  double charHeightAtValueForIndex(int charKitIndex, double value) {
    final charKit = charKits[charKitIndex];
    final endIndex = charKit.length - 1;
    final mutatedIndex = mapCharKitIndexToSelection(charKit, endIndex);
    final painter = charKitPainters[charKitIndex];
    final selection =
        TextSelection(baseOffset: mutatedIndex, extentOffset: mutatedIndex + 1);
    final boxes = painter.getBoxesForSelection(
      selection,
      boxHeightStyle: ui.BoxHeightStyle.max,
    );
    return boxes.map((b) => b.toRect().height).reduce((a, b) => a + b);
  }

  TextSelection textSelectionAtCharKitIndexNearValue(
      int charKitIndex, double value) {
    final charKit = charKits[charKitIndex];
    final length = charKit.length;
    final maxIndex = length - 1;
    final int effectiveIndex = (value * maxIndex).clamp(0, maxIndex).round();
    final mutatedIndex = mapCharKitIndexToSelection(charKit, effectiveIndex);
    final TextSelection selection = TextSelection(
      baseOffset: mutatedIndex,
      extentOffset: mutatedIndex + 1,
    );
    return selection;
  }

  void layout() {
    disposePainters(charKitPainters);
    charKitPainters.clear();

    charKits = buildCharKits();
    charKitPainters = buildPainters(charKits);

    for (final TextPainter painter in charKitPainters) {
      painter.layout();
    }
  }

  Widget paintIndex(
    int charIndex,
    double value, {
    Curve curve = appleEaseInOut,
    Duration duration = const Duration(milliseconds: 350),
    double? fixedWidth,
  }) {
    final painter = charKitPainters[charIndex];
    final TextSelection selection =
        textSelectionAtCharKitIndexNearValue(charIndex, value);
    final box = painter
        .getBoxesForSelection(selection, boxHeightStyle: ui.BoxHeightStyle.max)
        .map((b) => b.toRect())
        .reduce((a, b) => a.expandToInclude(b));
    return CustomPaint(
      painter: RollingTextPainter(charKitPainters[charIndex]),
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
    disposePainters(charKitPainters);
    super.dispose();
  }

  List<String> buildCharKits() => [
        for (int i = 0; i < max(oldText.length, newText.length); i++)
          selectCharKit(oldText.length <= i ? '​' : oldText[i],
              newText.length <= i ? '​' : newText[i]),
      ];

  List<TextPainter> buildPainters(List<String> charKits) {
    return [
      for (final String charKit in charKits)
        buildTextPainter(charKit.split('').join('\n')),
    ];
  }

  void disposePainters(List<TextPainter> painters) {
    for (final TextPainter painter in painters) {
      painter.dispose();
    }
  }

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

  String selectCharKit(String a, String b) => switch (rollStrategy) {
        AllSymbolsTapeStrategy(repeatCharacters: bool repeatCharacters) =>
          repeatCharacters ? repeatCharKit(a, b) : noRepeatCharKit(a, b),
        ConsistentSymbolTapeStrategy(
          distance: int distance,
          repeatCharacters: bool repeatCharacters
        ) =>
          trimmedCharKit(
            a,
            b,
            repeatCharacters ? repeatCharKit(a, b) : noRepeatCharKit(a, b),
            maxDistance: distance,
            repeat: repeatCharacters,
          ),
      };

  String trimmedCharKit(String a, String b, String kit,
      {required int maxDistance, required bool repeat}) {
    final int length = kit.length;
    final int maxIndex = length - 1;

    if (a == b) {
      if (repeat) {
        return a * (maxDistance + 2);
      } else {
        return a;
      }
    }
    if (length <= 2) return kit;

    final StringBuffer newKit = StringBuffer();

    int distance = maxDistance;
    bool fromStart = true;
    while (distance > 0) {
      final progress = maxDistance - distance;
      if (fromStart) {
        final int start = min(progress, maxIndex - 1);
        newKit.write(kit[1 + start]);
        // if (newKit.length >= maxDistance + 2) break;
      } else {
        final int end = max(maxIndex - progress, 1);
        newKit.write(kit[end - 1]);
        // if (newKit.length >= maxDistance + 2) break;
      }
      distance--;
      fromStart = !fromStart;
    }
    return a + newKit.toString() + b;
  }

  String noRepeatCharKit(String a, String b) {
    final StringBuffer charKitBuffer = StringBuffer();

    if (a == b) {
      return a;
    } else if (a == '​' || b == '​') {
      charKitBuffer.write('​${a == '​' ? b : a}');
    } else if (a.isSpace() || b.isSpace()) {
      charKitBuffer.write(' ${a == ' ' ? b : a}}');
    } else {
      if (a.isSymbol() || b.isSymbol()) {
        charKitBuffer.write(_kSymbols);
      }
      if (a.isUpperAlphabet() || b.isUpperAlphabet()) {
        charKitBuffer.write(_kUpperAlphabet);
      }
      if (a.isLowerAlphabet() || b.isLowerAlphabet()) {
        charKitBuffer.write(_kLowerAlphabet);
      }
      if (a.isNumber() || b.isNumber()) {
        charKitBuffer.write(_kNumbers);
      }
    }

    final String charKit = charKitBuffer.toString();
    final int indexA = charKit.indexOf(a);
    final int indexB = charKit.indexOf(b);
    final int minIndex = min(indexA, indexB);
    final int maxIndex = max(indexA, indexB);

    if (maxIndex - minIndex <= 1) return a + b;

    return a + charKit.substring(minIndex + 1, maxIndex) + b;
  }

  String repeatCharKit(String a, String b) {
    final StringBuffer charKitBuffer = StringBuffer();

    if (a == b) {
      charKitBuffer.write('');
    } else if (a == '​' || b == '​') {
      charKitBuffer.write('​${a == '​' ? b : a}');
    } else if (a.isSpace() || b.isSpace()) {
      charKitBuffer.write(' ${a == ' ' ? b : a}}');
    } else {
      if (a.isSymbol() || b.isSymbol()) {
        charKitBuffer.write(_kSymbols);
      }
      if (a.isUpperAlphabet() || b.isUpperAlphabet()) {
        charKitBuffer.write(_kUpperAlphabet);
      }
      if (a.isLowerAlphabet() || b.isLowerAlphabet()) {
        charKitBuffer.write(_kLowerAlphabet);
      }
      if (a.isNumber() || b.isNumber()) {
        charKitBuffer.write(_kNumbers);
      }
    }

    final String charKit = charKitBuffer.toString();
    final int indexA = charKit.indexOf(a);
    final int indexB = charKit.indexOf(b);
    final int minIndex = min(indexA, indexB);
    final int maxIndex = max(indexA, indexB);

    if (maxIndex - minIndex <= 1) return a + b;

    return a + charKit.substring(minIndex + 1, maxIndex) + b;
  }
}

class RollingTextPainter extends CustomPainter {
  final TextPainter painter;

  // final TextSelection selection;
  // final ui.LineMetrics? lineMetrics;
  // final List<ui.Rect> boxes;
  // final double height;

  RollingTextPainter(
    this.painter,
    //   this.selection,
    //   this.lineMetrics,
    //   this.boxes,
    //   this.height,
  );

  @override
  void paint(Canvas canvas, Size size) {
    // final randomSeed =
    //     Random((selection.baseOffset + selection.extentOffset).hashCode)
    //         .nextDouble();
    // final randomColor = HSVColor.fromAHSV(
    //   1,
    //   randomSeed * 360,
    //   1,
    //   1,
    // ).toColor();
    // Rect rect = painter
    //     .getBoxesForSelection(selection, boxHeightStyle: ui.BoxHeightStyle.max)
    //     .map((sel) => sel.toRect())
    //     .reduce((value, element) => value.expandToInclude(element));
    // rect = Rect.fromLTWH(rect.left, rect.top, rect.width, height);
    // // Rect rect = boxes
    // //     .reduce((value, element) => value.expandToInclude(element))
    // //     .expandToInclude(Offset.zero & size);
    // // if (lineMetrics case ui.LineMetrics metrics) {
    // //   rect = Rect.fromCenter(center: rect.center, width: metrics.width, height: metrics.height);
    // // }
    // canvas.drawRect(
    //   rect,
    //   Paint()
    //     ..color = randomColor
    //     ..style = PaintingStyle.stroke
    //     ..strokeWidth = 2,
    // );
    // // Draw a crosshair inside the rect.
    // canvas.drawLine(
    //     rect.topCenter,
    //     rect.bottomCenter,
    //     Paint()
    //       ..color = Colors.yellow
    //       ..style = PaintingStyle.stroke
    //       ..strokeWidth = 1);
    // canvas.drawLine(
    //     rect.centerLeft,
    //     rect.centerRight,
    //     Paint()
    //       ..color = Colors.yellow
    //       ..style = PaintingStyle.stroke
    //       ..strokeWidth = 1);
    // canvas.clipRect(Offset.zero & size);
    // canvas.drawRect(Offset.zero & size, Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 2);
    painter.paint(canvas, Offset.zero);
    // final double baseline =
    //     painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    //
    // // render baseline.
    // canvas.drawLine(
    //     Offset(0, baseline),
    //     Offset(size.width, baseline),
    //     Paint()
    //       ..color = Colors.red
    //       ..style = PaintingStyle.stroke
    //       ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
