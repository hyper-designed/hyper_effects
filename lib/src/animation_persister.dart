import 'package:flutter/widgets.dart';

import '../hyper_effects.dart';

/// A StatefulWidget that retains the state of an [AnimatedEffect] widget.
///
/// This widget is responsible for managing the state of animations, by
/// not allowing [AnimationTriggerType.oneShot] animations from replaying
/// if their [State] got disposed and recreated.
///
/// This is useful for HyperEffect animations that are used in
/// [ListView.builder], [GridView.builder] or any other widget that
/// disposes and recreates its children, discouraging the replay of
/// animations that already played.
class AnimatedEffectStateRetainer extends StatefulWidget {
  /// A subtree of widgets that contain [AnimatedEffect] widgets.
  final Widget child;

  /// Creates an [AnimatedEffectStateRetainer].
  const AnimatedEffectStateRetainer({super.key, required this.child});

  @override
  State<AnimatedEffectStateRetainer> createState() =>
      _AnimatedEffectStateRetainerState();

  /// Returns the [AnimatedEffectStateRetainerInheritedWidget] from the
  /// closest instance of this class that encloses the given context.
  ///
  /// If no [AnimatedEffectStateRetainerInheritedWidget] is found, returns null.
  static AnimatedEffectStateRetainerInheritedWidget? maybeOf(
      BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<
        AnimatedEffectStateRetainerInheritedWidget>();
  }

  /// Returns the [AnimatedEffectStateRetainerInheritedWidget] from the
  /// closest instance of this class that encloses the given context.
  ///
  /// Throws an exception if no [AnimatedEffectStateRetainerInheritedWidget] is found.
  static AnimatedEffectStateRetainerInheritedWidget of(BuildContext context) {
    final AnimatedEffectStateRetainerInheritedWidget? result = maybeOf(context);
    assert(result != null,
        'No AnimatedEffectStateRetainerInheritedWidget found in context.');
    return result!;
  }
}

class _AnimatedEffectStateRetainerState
    extends State<AnimatedEffectStateRetainer> {
  final Map<Key, bool> _animationStates = {};

  void _markAsPlayed(Key key) {
    _animationStates[key] = true;
  }

  bool _didPlay(Key key) => _animationStates[key] ?? false;

  @override
  Widget build(BuildContext context) {
    return AnimatedEffectStateRetainerInheritedWidget(
      playedCallback: _markAsPlayed,
      didPlayCallback: _didPlay,
      child: widget.child,
    );
  }
}

/// A callback that returns whether an [AnimatedEffect] widget with the given
/// [Key] has played.
typedef DidPlayCallback = bool Function(Key key);

/// An [InheritedWidget] that delegates callbacks to the
/// [AnimatedEffectStateRetainer] parent widget.
class AnimatedEffectStateRetainerInheritedWidget extends InheritedWidget {
  /// A callback that marks an [AnimatedEffect] widget with the given [Key]
  /// as played.
  final ValueChanged<Key> playedCallback;

  /// A callback that returns whether an [AnimatedEffect] widget with the given
  /// [Key] has played.
  final DidPlayCallback didPlayCallback;

  /// Creates an [AnimatedEffectStateRetainerInheritedWidget].
  const AnimatedEffectStateRetainerInheritedWidget({
    super.key,
    required super.child,
    required this.playedCallback,
    required this.didPlayCallback,
  });

  /// Marks an [AnimatedEffect] widget with the given [Key] as played.
  void markAsPlayed(Key key) => playedCallback(key);

  /// Returns whether an [AnimatedEffect] widget with the given [Key] has played.
  bool didPlay(Key key) => didPlayCallback(key);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
