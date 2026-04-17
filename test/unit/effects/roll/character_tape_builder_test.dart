import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

class _TestBuilder extends CharacterTapeBuilder {
  _TestBuilder(this._chars);
  final String _chars;
  @override
  String get characters => _chars;
  @override
  bool compare(String a, String b) =>
      _chars.contains(a) && _chars.contains(b);
}

void main() {
  group('CharacterTapeBuilder contract', () {
    test('characters getter returns the exact configured string', () {
      final b = _TestBuilder('abc');
      expect(b.characters, 'abc');
    });

    test('compare returns true only when both inputs are in the set', () {
      final b = _TestBuilder('abc');
      expect(b.compare('a', 'b'), isTrue);
      expect(b.compare('a', 'd'), isFalse);
      expect(b.compare('x', 'y'), isFalse);
    });

    test('empty character set makes compare always false', () {
      final b = _TestBuilder('');
      expect(b.compare('a', 'a'), isFalse);
    });

    test('compare is order-independent for presence', () {
      final b = _TestBuilder('ab');
      expect(b.compare('a', 'b'), isTrue);
      expect(b.compare('b', 'a'), isTrue);
    });

    test('grapheme-cluster emoji are matched by their composed representation',
        () {
      const family = '👨‍👩‍👧‍👦';
      final b = _TestBuilder(family);
      expect(b.compare(family, family), isTrue);
    });
  });
}
