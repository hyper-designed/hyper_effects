/// Controls which word's shaping context is used when building the
/// intermediate tape frames for rolling between two words (e.g. Arabic
/// `قطة` → `كلب`).
///
/// Only relevant under [TextRenderMode.contextualCharacters]; ignored under
/// [TextRenderMode.independentCharacters].
enum TapeShapingContext {
  /// Always substitute into the OLD word's context. Intermediates shape
  /// as if they were in `oldText`. The end-state renders correctly
  /// (shaped within `newText`'s context naturally) but earlier frames
  /// show the right letter in the WRONG word's shape.
  ///
  /// Fallback: when `oldText` doesn't contain the animating position
  /// (e.g., `newText` is longer, or `oldText` is empty), this variant
  /// falls back to `newText` to avoid shaping the tape character in
  /// isolation. In effect: prefer old; use new when old lacks the position.
  oldWord,

  /// Always substitute into the NEW word's context. Mirror of
  /// [oldWord] — the start frame looks wrong; the end frame is correct.
  ///
  /// Fallback: when `newText` doesn't contain the animating position
  /// (e.g., `oldText` is longer, or `newText` is empty), this variant
  /// falls back to `oldText` to avoid shaping the tape character in
  /// isolation. In effect: prefer new; use old when new lacks the position.
  newWord,

  /// Tape frame 0 (`oldText`'s actual letter) is shaped in the OLD
  /// word's context; tape frame T-1 (`newText`'s actual letter) is
  /// shaped in the NEW word's context; all intermediate frames use
  /// the NEW word's context. Both endpoints render correctly.
  /// A small imperceptible "snap" occurs at frame 0 → 1 coincident
  /// with a character change. This is the default.
  ///
  /// Fallback: when the preferred context word doesn't contain the animating
  /// position, this variant degrades gracefully — step 0 falls back to
  /// `newText` when `oldText` lacks the position; all other steps fall back
  /// to `oldText` when `newText` lacks the position. Both endpoints still
  /// render as correctly as possible given the available context.
  endpointsCorrect,
}
