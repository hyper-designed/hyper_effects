import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

const String _kLowerAlphabet = 'abcdefghijklmnopqrstuvwxyz ';
const String _kUpperAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const String _kNumbers = '0123456789';
const String _kSymbols = '`~!@#\$%^&*()-_=+[{]}\\|;:\'",<.>/?';
const String _kSpace = ' ';
const String _kAlphabet = _kLowerAlphabet + _kUpperAlphabet;
const String _kAlphanumeric = _kAlphabet + _kNumbers;
const String _kAll = _kAlphanumeric + _kSymbols;

extension StringHelper on String {
  bool isSymbol() => _kSymbols.contains(this);

  bool isAlphabet() => _kAlphabet.contains(this);

  bool isAlphanumeric() => _kAlphanumeric.contains(this);

  bool isNumber() => _kNumbers.contains(this);

  bool isSpace() => _kSpace.contains(this);

  bool isLowerAlphabet() => _kLowerAlphabet.contains(this);

  bool isUpperAlphabet() => _kUpperAlphabet.contains(this);
}

sealed class SymbolRollStrategy {
  const SymbolRollStrategy();
}

class AllSymbolsRollStrategy extends SymbolRollStrategy {
  const AllSymbolsRollStrategy();
}

class ConsistentDistanceRollStrategy extends SymbolRollStrategy {
  final int distance;

  const ConsistentDistanceRollStrategy(this.distance);
}

/// Provides a extension method to apply a [TextEffect] to a [Widget].
extension TextEffectExt on Text {
  /// Rolls each character individually to form the [newText].
  Widget roll(
    String newText, {
    SymbolRollStrategy rollStrategy = const AllSymbolsRollStrategy(),
  }) {
    print('OLD TEXT: $data');
    print('NEW TEXT: $newText');
    return AnimatableEffect(
      end: TextEffect(
        oldText: data ?? '',
        newText: newText,
        rollStrategy: rollStrategy,
        value: 1,
        roll: true,
        style: style,
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
}

/// An [Effect] that applies a Text to a [Widget].
class TextEffect extends Effect {
  final String oldText;
  final String newText;
  final double? value;
  final SymbolRollStrategy rollStrategy;

  /// Setting this to true will lerp the text from the current text to the new
  /// text by rolling each character individually though the alphabet.
  final bool roll;

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

  /// Creates a [TextEffect].
  const TextEffect({
    required this.oldText,
    required this.newText,
    required this.value,
    required this.rollStrategy,
    this.roll = false,
    this.style,
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
  TextEffect lerp(covariant TextEffect other, double value) {
    print('old text: $oldText');
    print('new text: $newText');
    return TextEffect(
      oldText: oldText,
      newText: newText,
      value: value,
      rollStrategy: rollStrategy,
      style: TextStyle.lerp(style, other.style, value),
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
    );
  }

  @override
  Widget apply(BuildContext context, Widget child) {
    return RollingText(
      newText: newText,
      oldText: oldText,
      rollStrategy: rollStrategy,
      value: value ?? 0,
      style: style,
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
        roll,
        value,
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

class RollingText extends StatelessWidget {
  final String oldText;
  final String newText;
  final SymbolRollStrategy rollStrategy;
  final double value;

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
    required this.value,
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

  String selectCharKit(String a, String b) => switch (rollStrategy) {
        AllSymbolsRollStrategy() => smartCharKit(a, b),
        ConsistentDistanceRollStrategy(distance: int distance) =>
          trimmedCharKit(a, b, distance),
      };

  String trimmedCharKit(String a, String b, int maxDistance) {
    final String kit = smartCharKit(a, b);
    final int length = kit.length;
    final effectiveMaxDist = maxDistance ~/ 2;

    final StringBuffer startKit = StringBuffer();
    final StringBuffer endKit = StringBuffer();

    int distance = effectiveMaxDist;
    while (distance > 0) {
      final progress = effectiveMaxDist - distance;
      final int start = min(progress, length - 1);
      final int end = max(length - 1 - progress, 0);
      startKit.write(kit[start]);
      endKit.write(kit[end]);
      distance--;
    }

    return startKit.toString() + endKit.toString();
  }

  String smartCharKit(String a, String b) {
    final StringBuffer charKitBuffer = StringBuffer();

    if (a.isSpace() && b.isSpace()) {
      charKitBuffer.write(_kSpace);
    } else if (a.isSpace() != b.isSpace()) {
      charKitBuffer.write(_kSpace + (a.isSpace() ? b : a));
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

    if (indexA == indexB) return charKit;

    return charKit.substring(min(indexA, indexB), max(indexA, indexB) + 1);
  }

  @override
  Widget build(BuildContext context) {
    final before = oldText;
    final after = newText;
    final beforeL = before.length;
    final afterL = after.length;
    final longest = max(beforeL, afterL);

    final double height = style?.fontSize ?? 16;
    final gap = height / 4;

    return SizedBox(
      height: height + gap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: height,
            color: Colors.red,
          ),
          Positioned(
            top: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int charIndex = 0; charIndex < longest; charIndex++)
                  Builder(builder: (context) {
                    final beforeChar =
                        charIndex < beforeL ? before[charIndex] : ' ';
                    final afterChar =
                        charIndex < afterL ? after[charIndex] : ' ';
                    final charKit = selectCharKit(beforeChar, afterChar);

                    // Transforms the global value such that it only affects 1 characters
                    // before and after the current character.
                    final beforeIndex = charKit.indexOf(beforeChar);
                    final afterIndex = charKit.indexOf(afterChar);
                    final distance = beforeIndex - afterIndex;
                    final sign = distance.sign;

                    // Lerp the value between the before and after indices.
                    final transformedValue =
                        (sign < 0 ? 1 - value : value * -1) *
                            distance *
                            (height + gap);

                    final minIndex = min(beforeIndex, afterIndex);
                    final maxIndex = max(beforeIndex, afterIndex);

                    return Transform.translate(
                      offset: Offset(0, transformedValue),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int char = minIndex; char <= maxIndex; char++)
                            Padding(
                              padding: EdgeInsets.only(
                                top: gap / 2,
                                bottom: gap / 2,
                              ),
                              child: Text(
                                charKit[char],
                                style: style,
                                strutStyle:
                                    const StrutStyle(forceStrutHeight: true),
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
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
