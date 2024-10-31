import 'package:flutter/cupertino.dart';

/// Provides a way to configure the animation behavior globally for a subtree.
class HyperEffectsAnimationConfig extends InheritedWidget {
  /// The animation behavior to use for the subtree.
  final AnimationBehavior? animationBehavior;

  /// Returns the [HyperEffectsAnimationConfig] from the closest instance of
  /// this class that encloses the given context.
  static HyperEffectsAnimationConfig of(BuildContext context) {
    return maybeOf(context)!;
  }

  /// Returns the [HyperEffectsAnimationConfig] from the closest instance of
  /// this class that encloses the given context.
  static HyperEffectsAnimationConfig? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<HyperEffectsAnimationConfig>();
  }

  /// Creates a new [HyperEffectsAnimationConfig] widget.
  const HyperEffectsAnimationConfig({
    super.key,
    required super.child,
    this.animationBehavior,
  });

  @override
  bool updateShouldNotify(covariant HyperEffectsAnimationConfig oldWidget) {
    return animationBehavior != oldWidget.animationBehavior;
  }
}
