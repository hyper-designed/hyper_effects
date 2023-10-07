/// Defines the state of an object in the context of its associated scroll view.
/// This mainly indicates whether the object is visible in the scroll view or
/// is either leaving or entering the scroll view.
enum ScrollPhase {
  /// The object is leaving the top/left edge of the scroll view.
  topLeading,

  /// The object is fully visible in the scroll view.
  identity,

  /// The object is leaving the bottom/right edge of the scroll view.
  bottomTrailing;

  /// A convenience method that returns true if the phase is
  /// [ScrollPhase.topLeading].
  bool get isTopLeading => this == ScrollPhase.topLeading;

  /// A convenience method that returns true if the phase is
  /// [ScrollPhase.identity].
  bool get isIdentity => this == ScrollPhase.identity;

  /// A convenience method that returns true if the phase is
  /// [ScrollPhase.bottomTrailing].
  bool get isBottomTrailing => this == ScrollPhase.bottomTrailing;
}
