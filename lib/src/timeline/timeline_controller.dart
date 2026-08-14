import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'timeline_effect.dart';

/// An external handle for driving a [TimelineEffect] imperatively.
///
/// A [TimelineController] can be owned anywhere — a State, a cubit, a
/// service — and outlives remounts of the widget it drives. Attach it via
/// the `controller` parameter of `.timeline()`.
///
/// Listeners are notified whenever the timeline's [progress] changes.
class TimelineController extends ChangeNotifier {
  AnimationController? _driven;

  /// Whether this controller is currently attached to a mounted
  /// [TimelineEffect].
  bool get isAttached => _driven != null;

  AnimationController get _controller {
    final AnimationController? driven = _driven;
    if (driven == null) {
      throw StateError(
        'This TimelineController is not attached to a TimelineEffect. '
        'Pass it to `.timeline(controller: ...)` and ensure that widget is '
        'mounted before driving it.',
      );
    }
    return driven;
  }

  /// The timeline's current position, 0..1.
  double get progress => _controller.value;

  /// Plays the timeline forward from its current position.
  Future<void> play() => _controller.forward();

  /// Plays the timeline backward from its current position.
  Future<void> reverse() => _controller.reverse();

  /// Freezes the timeline at its current position.
  void pause() => _controller.stop();

  /// Jumps the timeline to [progress] (0..1) without animating.
  void seek(double progress) {
    _controller.value = progress.clamp(0.0, 1.0);
  }

  /// Binds this controller to a [TimelineEffect]'s internal animation
  /// controller. Called by [TimelineEffect]; not part of the public API.
  @internal
  void attach(AnimationController controller) {
    _driven?.removeListener(notifyListeners);
    _driven = controller;
    controller.addListener(notifyListeners);
  }

  /// Unbinds this controller if it is currently bound to [controller].
  /// Called by [TimelineEffect]; not part of the public API.
  @internal
  void detach(AnimationController controller) {
    if (_driven == controller) {
      controller.removeListener(notifyListeners);
      _driven = null;
    }
  }
}
