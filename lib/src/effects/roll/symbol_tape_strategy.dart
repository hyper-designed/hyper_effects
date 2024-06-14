import 'dart:math';

import 'package:flutter/widgets.dart';

const String _kLowerAlphabet = 'abcdefghijklmnopqrstuvwxyz ';
const String _kUpperAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const String _kNumbers = '0123456789';
const String _kSymbols = '`~!@#\$%^&*()-_=+[{]}\\|;:\'",<.>/?';
const String _kSpace = ' ';
const String _kZeroWidth = '​';

extension _StringHelper on String {
  bool isSymbol() => _kSymbols.contains(this);

  bool isNumber() => _kNumbers.contains(this);

  bool isSpace() => _kSpace.contains(this);

  bool isZeroWidth() => _kZeroWidth.contains(this);

  bool isLowerAlphabet() => _kLowerAlphabet.contains(this);

  bool isUpperAlphabet() => _kUpperAlphabet.contains(this);
}

/// A builder that constructs a tape of characters tailored for a specific
/// condition of characters such as emojis.
abstract class CharacterTapeBuilder {
  /// The characters that are used to build the tape of characters. For example,
  /// an entire emoji set.
  String get characters;

  /// Compares two strings to determine if the builder should be used to
  /// insert the [characters] into the main tape.
  bool compare(String a, String b);
}

/// Defines the strategy to create the tape of character symbols
/// to interpolate to and from.
sealed class SymbolTapeStrategy {
  /// If [repeatCharacters] is true, it means that characters that are
  /// repeated between interpolations in the tape of each character
  /// will be repeated instead of optimized to only render once.
  /// eg: Interpolating between World and Whale, the `W` and `l` will both
  ///     be rendered and animated to roll twice instead of just once.
  final bool repeatCharacters;

  /// A set of [CharacterTapeBuilder]s that can be used to build the tape
  /// of characters to interpolate to and from for a specific set of characters,
  /// like emojis.
  final Set<CharacterTapeBuilder> characterTapeBuilders;

  /// Creates a new [SymbolTapeStrategy] with the given [repeatCharacters]
  /// property.
  const SymbolTapeStrategy({
    this.repeatCharacters = true,
    this.characterTapeBuilders = const {},
  });

  /// Builds the tape of characters to interpolate to and from.
  String build(String a, String b) =>
      repeatCharacters ? _repeatTape(a, b) : _noRepeatTape(a, b);

  String _noRepeatTape(String a, String b) {
    final StringBuffer charKitBuffer = StringBuffer();

    if (a == b) {
      return a;
    } else if (a.isZeroWidth() || b.isZeroWidth()) {
      charKitBuffer.write('$_kZeroWidth${a == _kZeroWidth ? b : a}');
    } else if (a.isSpace() || b.isSpace()) {
      charKitBuffer.write(' ${a == _kSpace ? b : a}');
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
      for (final CharacterTapeBuilder builder in characterTapeBuilders) {
        if (builder.compare(a, b)) {
          charKitBuffer.write(builder.characters);
        }
      }
    }

    final String charKit = charKitBuffer.toString();
    final List<String> charKitList = charKit.characters.toList();
    final int indexA = charKitList.indexOf(a);
    final int indexB = charKitList.indexOf(b);
    final int minIndex = min(indexA, indexB);
    final int maxIndex = max(indexA, indexB);

    if (maxIndex - minIndex <= 1) return a + b;

    return a + charKitList.sublist(minIndex + 1, maxIndex).join('') + b;
  }

  String _repeatTape(String a, String b) {
    final StringBuffer charKitBuffer = StringBuffer();

    if (a == b) {
      charKitBuffer.write('');
    } else if (a.isZeroWidth() || b.isZeroWidth()) {
      charKitBuffer.write('$_kZeroWidth${a == _kZeroWidth ? b : a}');
    } else if (a.isSpace() || b.isSpace()) {
      charKitBuffer.write(' ${a == _kSpace ? b : a}');
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
      for (final CharacterTapeBuilder builder in characterTapeBuilders) {
        if (builder.compare(a, b)) {
          charKitBuffer.write(builder.characters);
        }
      }
    }

    final String charKit = charKitBuffer.toString();
    final List<String> charKitList = charKit.characters.toList();
    final int indexA = charKitList.indexOf(a);
    final int indexB = charKitList.indexOf(b);
    final int minIndex = min(indexA, indexB);
    final int maxIndex = max(indexA, indexB);

    if (maxIndex - minIndex <= 1) return a + b;

    return a + charKitList.sublist(minIndex + 1, maxIndex).join('') + b;
  }
}

/// Constructs symbol tapes that contain all the characters
/// that are contained between two strings in alphabetical order.
///
/// eg: Interpolating between the letters `a` and `z` will result in
///     the creation of a tape containing the entire alphabet
///     `abcdefghijklmnopqrstuvwxyz`.
///
///     Interpolating between `a` and `c` will result in the creation of
///     a tape containing `abc`.
class AllSymbolsTapeStrategy extends SymbolTapeStrategy {
  /// Creates a new [AllSymbolsTapeStrategy] with the given [repeatCharacters]
  /// property.
  const AllSymbolsTapeStrategy({super.repeatCharacters = true});
}

/// Constructs symbol tapes that contain all the characters
/// that are contained between two strings in alphabetical order
/// up to the given [distance].
///
/// The [distance] does not include the characters that are being
/// interpolated, rather only the characters that are between them.
///
/// eg: Interpolating between the letters `a` and `z` with a distance of 2
///     will result in the creation of a tape containing `abyz`.
///
///     Interpolating between `a` and `c` with a distance of 2 will result
///     in the creation of a tape containing `abcc`.
///
///     Interpolating between `a` and `c` with a distance of 0 will result
///     in the creation of a tape containing `ac`.
///
///     Interpolating between `a` and `c` with a distance of 5 will result
///     in the creation of a tape containing `abbbccc`.
///
///     Interpolating between `W` and `W` with a distance of 2 will result
///     in the creation of a tape containing `WWWW`.
class ConsistentSymbolTapeStrategy extends SymbolTapeStrategy {
  /// The number of symbols to include between the two strings.
  final int distance;

  /// Creates a new [ConsistentSymbolTapeStrategy] with the given [distance]
  /// and [repeatCharacters] properties.
  const ConsistentSymbolTapeStrategy(
    this.distance, {
    super.repeatCharacters = true,
    Set<CharacterTapeBuilder> characterTapeBuilders = const {},
  }) : assert(
          distance >= 0,
          'Distance must be >= 0.',
        );

  @override
  String build(String a, String b) {
    final tape = super.build(a, b);
    final maxDistance = this.distance;
    final int length = tape.characters.length;
    final int maxIndex = length - 1;

    if (a == b) {
      if (repeatCharacters) {
        return a * (maxDistance + 2);
      } else {
        return a;
      }
    }
    if (length <= 2) {
      final int halfDist = maxDistance ~/ 2;
      return a * (halfDist + 1) + b * (halfDist + 1);
    }

    final StringBuffer newKit = StringBuffer();

    int distance = maxDistance;
    bool fromStart = true;
    while (distance > 0) {
      final progress = maxDistance - distance;
      if (fromStart) {
        final int start = min(progress, maxIndex - 1);
        newKit.write(tape.characters.elementAt(start + 1));
        // if (newKit.length >= maxDistance + 2) break;
      } else {
        final int end = max(maxIndex - progress, 1);
        newKit.write(tape.characters.elementAt(end - 1));
        // if (newKit.length >= maxDistance + 2) break;
      }
      distance--;
      fromStart = !fromStart;
    }
    return a + newKit.toString() + b;
  }
}
