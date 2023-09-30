import 'package:flutter/widgets.dart';

extension AnimatedEffectExt on Widget {
  Widget animate({
    required Object? toggle,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedEffect(
      toggle: toggle,
      duration: duration,
      curve: curve,
      child: this,
    );
  }
}

class AnimatedEffect extends StatefulWidget {
  final Widget child;
  final Object? toggle;
  final Duration duration;
  final Curve curve;

  const AnimatedEffect({
    super.key,
    required this.child,
    required this.toggle,
    required this.duration,
    this.curve = Curves.easeInOut,
  });

  @override
  State<AnimatedEffect> createState() => _AnimatedEffectState();

  EffectAnimationValue? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EffectAnimationValue>();
}

class _AnimatedEffectState extends State<AnimatedEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
    duration: widget.duration,
  );

  @override
  void didUpdateWidget(covariant AnimatedEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.toggle != oldWidget.toggle) _controller.forward(from: 0);
    _controller.duration = widget.duration;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => EffectAnimationValue(
        value: _controller.value,
        isTransition: false,
        child: child!,
      ),
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class EffectAnimationValue extends InheritedWidget {
  final double value;
  final bool isTransition;

  const EffectAnimationValue({
    super.key,
    required super.child,
    required this.value,
    required this.isTransition,
  });

  @override
  bool updateShouldNotify(covariant EffectAnimationValue oldWidget) {
    return oldWidget.value != value || oldWidget.isTransition != isTransition;
  }
}
