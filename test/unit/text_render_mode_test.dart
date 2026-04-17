// ignore_for_file: deprecated_member_use
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  test('TextRenderMode has exactly two values', () {
    expect(TextRenderMode.values.length, 2);
    expect(TextRenderMode.values, containsAll([
      TextRenderMode.independentCharacters,
      TextRenderMode.contextualCharacters,
    ]));
  });
}
