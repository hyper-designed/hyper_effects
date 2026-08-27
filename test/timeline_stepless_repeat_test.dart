import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  testWidgets('looping a chain with no step() explains what is missing',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const SizedBox(width: 10, height: 10)
            .rotate(1.0)
            .timeline(trigger: #immediate, repeat: -1),
      ),
    );

    final Object? error = tester.takeException();
    expect(error, isFlutterError);
    expect(
      (error as FlutterError).message,
      allOf(
        contains('step()'),
        contains('repeat'),
        isNot(contains('_periodInSeconds')),
      ),
    );
  });
}
