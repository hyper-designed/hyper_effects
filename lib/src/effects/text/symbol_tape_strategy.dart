/// Defines the strategy to create the tape of character symbols
/// to interpolate to and from.
sealed class SymbolTapeStrategy {
  /// If [repeatCharacters] is true, it means that characters that are
  /// repeated between interpolations in the tape of each character
  /// will be repeated instead of optimized to only render once.
  /// eg: Interpolating between World and Whale, the `W` and `l` will both
  ///     be rendered and animated to roll twice instead of just once.
  final bool repeatCharacters;

  /// Creates a new [SymbolTapeStrategy] with the given [repeatCharacters]
  /// property.
  const SymbolTapeStrategy([this.repeatCharacters = true]);
}

/// Constructs symbol tapes that contain all the characters
/// that are contained between two strings in alphabetical order.
///
/// eg: Interpolating between the letters `a` and `z` will result in
///     the creation of a tape containing the entire alphabet
///     `abcdefghijklmnopqrstuvwxyz`.
///
///     Interpolating between `a` and `c` will result in the creation of
///     a tape containing `abc`.
class AllSymbolsTapeStrategy extends SymbolTapeStrategy {
  /// Creates a new [AllSymbolsTapeStrategy] with the given [repeatCharacters]
  /// property.
  const AllSymbolsTapeStrategy([super.repeatCharacters = true]);
}

/// Constructs symbol tapes that contain all the characters
/// that are contained between two strings in alphabetical order
/// up to the given [distance].
///
/// The [distance] does not include the characters that are being
/// interpolated, rather only the characters that are between them.
///
/// eg: Interpolating between the letters `a` and `z` with a distance of 2
///     will result in the creation of a tape containing `abyz`.
///
///     Interpolating between `a` and `c` with a distance of 2 will result
///     in the creation of a tape containing `abcc`.
///
///     Interpolating between `a` and `c` with a distance of 0 will result
///     in the creation of a tape containing `ac`.
///
///     Interpolating between `a` and `c` with a distance of 5 will result
///     in the creation of a tape containing `abbbccc`.
///
///     Interpolating between `W` and `W` with a distance of 2 will result
///     in the creation of a tape containing `WWWW`.
class ConsistentSymbolTapeStrategy extends SymbolTapeStrategy {
  /// The number of symbols to include between the two strings.
  final int distance;

  /// Creates a new [ConsistentSymbolTapeStrategy] with the given [distance]
  /// and [repeatCharacters] properties.
  const ConsistentSymbolTapeStrategy(this.distance,
      [super.repeatCharacters = true])
      : assert(
          distance >= 0,
          'Distance must be >= 0.',
        );
}
