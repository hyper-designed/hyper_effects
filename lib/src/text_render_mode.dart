/// Selects how per-character text effects (e.g. [RollingTextEffect],
/// [BlurRevealEffect]) lay out and paint their characters.
///
/// Per-effect resolution order:
///
/// 1. Explicit `renderMode` parameter on the effect.
/// 2. [HyperEffectsScope.renderMode] via an ancestor.
/// 3. [HyperEffects.defaultTextRenderMode] globally.
/// 4. Fallback: [TextRenderMode.contextualCharacters] (as of v0.4.0).
enum TextRenderMode {
  /// Each character is shaped in isolation.
  ///
  /// Does **not** support Arabic, Devanagari, Thai, or any other script
  /// requiring contextual shaping.
  ///
  /// Deprecated: as of v0.4.0, the default is [contextualCharacters] which
  /// supports all scripts. This variant is retained for backward
  /// compatibility and will be removed in v0.5.0.
  @Deprecated(
      'Use TextRenderMode.contextualCharacters. Will be removed in v0.5.0.')
  independentCharacters,

  /// Text is shaped as a single paragraph with full context, then split
  /// into per-cluster rects for animation.
  ///
  /// Supports all scripts correctly, including RTL, ligatures, and
  /// complex-script conjuncts.
  contextualCharacters,
}
