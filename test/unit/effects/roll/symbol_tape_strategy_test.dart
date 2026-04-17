import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  group('AllSymbolsTapeStrategy (repeatCharacters: true)', () {
    const strategy = AllSymbolsTapeStrategy();

    test('identical inputs return the input doubled (repeat branch)', () {
      // KNOWN BUG (Phase 1 pin): _repeatTape produces 'aa' here, but the
      // asymmetric _noRepeatTape branch correctly returns 'a' for identical
      // inputs. Cause: _repeatTape's `a == b` branch writes '' to the buffer
      // instead of early-returning `a`, so execution falls through to
      // `return a + b`. See lib/src/effects/roll/symbol_tape_strategy.dart
      // near line 108. When this is fixed, flip expectation to 'a'.
      expect(strategy.build('a', 'a'), 'aa');
    });

    test('adjacent lowercase letters return just the two letters', () {
      // _repeatTape: maxIndex - minIndex <= 1 shortcut.
      expect(strategy.build('a', 'b'), 'ab');
    });

    test('far-apart lowercase letters include the intermediate alphabet', () {
      final result = strategy.build('a', 'z');
      expect(result.startsWith('a'), isTrue);
      expect(result.endsWith('z'), isTrue);
      expect(result, contains('bcdefghijklmnopqrstuvwxy'));
    });

    test('uppercase inputs include the uppercase alphabet set', () {
      final result = strategy.build('A', 'Z');
      expect(result.startsWith('A'), isTrue);
      expect(result.endsWith('Z'), isTrue);
      expect(result, contains('BCDEFGHIJKLMNOPQRSTUVWXY'));
    });

    test('digit inputs include the digit set', () {
      final result = strategy.build('0', '9');
      expect(result.startsWith('0'), isTrue);
      expect(result.endsWith('9'), isTrue);
      expect(result, contains('12345678'));
    });

    test('symbol inputs include the symbol set', () {
      final result = strategy.build('!', '?');
      expect(result.startsWith('!'), isTrue);
      expect(result.endsWith('?'), isTrue);
    });

    test('zero-width inputs use the zero-width shortcut', () {
      const zw = '\u200B';
      final result = strategy.build(zw, 'A');
      expect(result.startsWith(zw), isTrue);
      expect(result.endsWith('A'), isTrue);
    });

    test('space inputs use the space shortcut', () {
      final result = strategy.build(' ', 'A');
      expect(result, ' A');
    });
  });

  group('AllSymbolsTapeStrategy (repeatCharacters: false)', () {
    const strategy = AllSymbolsTapeStrategy(repeatCharacters: false);

    test('identical inputs return the input unchanged (no-repeat branch)', () {
      expect(strategy.build('a', 'a'), 'a');
    });

    test('adjacent lowercase letters return the two letters', () {
      expect(strategy.build('a', 'b'), 'ab');
    });

    test('far-apart lowercase letters include intermediate alphabet', () {
      final result = strategy.build('a', 'z');
      expect(result.startsWith('a'), isTrue);
      expect(result.endsWith('z'), isTrue);
    });
  });

  group('ConsistentSymbolTapeStrategy', () {
    test('distance 0 returns just a + b for different inputs', () {
      const strategy = ConsistentSymbolTapeStrategy(0);
      final result = strategy.build('a', 'z');
      expect(result.startsWith('a'), isTrue);
      expect(result.endsWith('z'), isTrue);
      expect(result.characters.length, lessThanOrEqualTo(2));
    });

    test('distance 2 between a and z yields 4-char tape including near-ends',
        () {
      const strategy = ConsistentSymbolTapeStrategy(2);
      final result = strategy.build('a', 'z');
      // KNOWN BUG (Phase 1 pin): the source docstring at
      // lib/src/effects/roll/symbol_tape_strategy.dart:170 says this should
      // be 'abyz', but the fromStart/fromEnd alternating walk picks 'b'
      // (tape[1]) then 'x' (tape[23] via `end-1` where end=24). The
      // algorithm disagrees with its own docs. When fixed, flip to 'abyz'.
      expect(result, 'abxz');
    });

    test('distance 2 between a and c yields "abac"', () {
      const strategy = ConsistentSymbolTapeStrategy(2);
      final result = strategy.build('a', 'c');
      // KNOWN BUG (Phase 1 pin): source docstring at
      // lib/src/effects/roll/symbol_tape_strategy.dart:173 says this should
      // be 'abcc'. Actual walk on a 3-char base 'abc': iteration 1 picks
      // tape[1] = 'b'; iteration 2 picks tape[0] = 'a'. Algorithm disagrees
      // with docs. When fixed, flip to 'abcc'.
      expect(result, 'abac');
    });

    test('same character with distance 2 repeats when repeatCharacters true', () {
      const strategy = ConsistentSymbolTapeStrategy(2);
      final result = strategy.build('W', 'W');
      // Per doc: "WWWW" for distance 2 with repeat.
      expect(result, 'WWWW');
    });

    test('same character with distance 0 returns single char when repeat false',
        () {
      const strategy =
          ConsistentSymbolTapeStrategy(0, repeatCharacters: false);
      final result = strategy.build('W', 'W');
      expect(result, 'W');
    });

    test('distance assertion fires for negative values', () {
      expect(() => ConsistentSymbolTapeStrategy(-1), throwsAssertionError);
    });
  });

  group('Character tape builder injection', () {
    test('custom builder characters appear in tape when compare returns true',
        () {
      const emojiRange = '🎈🎉🎊';
      final builder = _EmojiBuilder(emojiRange);
      final strategy = ConsistentSymbolTapeStrategy(
        10,
        characterTapeBuilders: {builder},
      );
      final result = strategy.build('🎈', '🎊');
      expect(result.startsWith('🎈'), isTrue);
      expect(result.endsWith('🎊'), isTrue);
    });
  });
}

class _EmojiBuilder extends CharacterTapeBuilder {
  _EmojiBuilder(this._chars);
  final String _chars;
  @override
  String get characters => _chars;
  @override
  bool compare(String a, String b) =>
      _chars.contains(a) && _chars.contains(b);
}
