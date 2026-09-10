import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

const _childKey = Key('child');
const _effectKey = Key('effect');

double _opacity(WidgetTester tester) => tester
    .widgetList<Opacity>(
      find.ancestor(of: find.byKey(_childKey), matching: find.byType(Opacity)),
    )
    .fold<double>(1, (value, widget) => value * widget.opacity);

void main() {
  testWidgets('equal target adopts changed explicit start', (tester) async {
    var startOpacity = 0.0;

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: EffectQuery(
            linearValue: 0,
            curvedValue: 0,
            isTransition: false,
            child: EffectWidget(
              key: _effectKey,
              start: OpacityEffect(opacity: startOpacity),
              end: OpacityEffect(opacity: 1),
              child: const SizedBox.shrink(key: _childKey),
            ),
          ),
        );

    await tester.pumpWidget(host());
    expect(_opacity(tester), 0);

    startOpacity = 0.5;
    await tester.pumpWidget(host());

    expect(_opacity(tester), 0.5,
        reason: 'an explicit start update is configuration even when the '
            'target remains equal');
  });

  testWidgets('incompatible effect replacement reseeds state', (tester) async {
    Effect end = OpacityEffect(opacity: 0.5);

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: EffectQuery(
            linearValue: 1,
            curvedValue: 1,
            isTransition: false,
            child: EffectWidget(
              key: _effectKey,
              end: end,
              child: const SizedBox.shrink(key: _childKey),
            ),
          ),
        );

    await tester.pumpWidget(host());
    expect(find.byType(Opacity), findsOneWidget);

    end = PaddingEffect(padding: const EdgeInsets.all(12));
    await tester.pumpWidget(host());

    expect(find.byType(Padding), findsOneWidget);
    expect(find.byType(Opacity), findsNothing);
  });
}
