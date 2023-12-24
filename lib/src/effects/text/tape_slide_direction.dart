import '../../../hyper_effects.dart';

/// Determines the direction in which each tape of characters will
/// slide in the [RollingTextEffect].
enum TapeSlideDirection {
  /// The tape of characters will slide from bottom to top.
  up,

  /// The tape of characters will slide from top to bottom.
  down,

  /// The tape of characters will alternate every other character
  /// between sliding from bottom to top and top to bottom.
  alternating,

  /// The tape of characters will slide in a random direction.
  random,
}
