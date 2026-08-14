import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  testWidgets(
    'completed oneShot does not restart when animation config changes',
    (tester) async {
      final hostKey = GlobalKey<_AnimationConfigHostState>();

      await tester.pumpWidget(_AnimationConfigHost(key: hostKey));
      await tester.pumpAndSettle();

      expect(_opacity(tester), 1);

      hostKey.currentState!.changeAnimationBehavior();
      await tester.pump();

      expect(_opacity(tester), 1);
    },
  );
}

double _opacity(WidgetTester tester) =>
    tester.widget<Opacity>(find.byType(Opacity)).opacity;

class _AnimationConfigHost extends StatefulWidget {
  const _AnimationConfigHost({super.key});

  @override
  State<_AnimationConfigHost> createState() => _AnimationConfigHostState();
}

class _AnimationConfigHostState extends State<_AnimationConfigHost> {
  AnimationBehavior _animationBehavior = AnimationBehavior.normal;

  void changeAnimationBehavior() {
    setState(() {
      _animationBehavior = AnimationBehavior.preserve;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HyperEffectsAnimationConfig(
      animationBehavior: _animationBehavior,
      child: const SizedBox().fadeIn().immediate(),
    );
  }
}
