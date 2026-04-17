import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';

/// One frame of a rolling tape, for one grapheme-cluster position.
///
/// A frame is everything the row painter needs to draw the cluster at
/// `position` against the paragraph that step `tapeStep` substitutes in:
///
/// * [substitutedText] — the paragraph the cluster lives in. Re-shape
///   on demand via the module-level [ShapedText] cache.
/// * [clusterBounds] — Skia's `graphemeClusterLayoutBounds` for the
///   animating cluster inside that paragraph.
/// * [lineAscent] / [lineDescent] — the cluster's line-metric split
///   around its baseline. Stored here so the row can position every
///   slot's cluster on a shared baseline without re-shaping at layout
///   time.
/// * [clusterIsParagraphLeftEdge] / [clusterIsParagraphRightEdge] —
///   VISUAL-edge anchor flags for the row painter's outer
///   left-/right-clip-padding. Computed from the cluster's
///   `visualIndex` (post-sort by line + bounds.left), not its
///   `logicalIndex`, so they correctly classify the paragraph's
///   visual edges even for mixed-direction substituted text. The
///   painter only extends the clip past the cluster's advance edge
///   on the matching side when the cluster sits at that VISUAL edge
///   of its paragraph; otherwise the extension would reach into a
///   neighbour cluster's ink (the "Marhaaba" / "Konnichiwwa"
///   doubled-letter bug). Both flags are `false` for
///   sentinel/missing-cluster frames — there is nothing to anchor.
@immutable
class TapeFrame {
  const TapeFrame({
    required this.substitutedText,
    required this.clusterBounds,
    required this.tapeStep,
    required this.lineAscent,
    required this.lineDescent,
    required this.slideHeight,
    required this.clusterIsParagraphLeftEdge,
    required this.clusterIsParagraphRightEdge,
  });

  /// Paragraph text the cluster lives in (the slot's tape character at
  /// `position`, with the surrounding context word filling the rest).
  final String substitutedText;

  /// Skia's `graphemeClusterLayoutBounds` for the cluster at this
  /// frame's slot position within [substitutedText].
  final Rect clusterBounds;

  /// Index of this frame within the slot's tape (0-based).
  final int tapeStep;

  /// Vertical distance from the paragraph's top to the alphabetic
  /// baseline. Used by the painter to anchor the cluster's baseline on
  /// the row's shared baseline.
  final double lineAscent;

  /// Vertical distance from the alphabetic baseline to the paragraph's
  /// bottom. Used together with [lineAscent] for layout sizing.
  final double lineDescent;

  /// Total slide stride for the tape's vertical roll. This is the
  /// distance step A must travel up (and step B must rise from below)
  /// for the two letters to NOT overlap mid-roll. Derived from the
  /// strut-inclusive paragraph height (`paragraph.height`), which
  /// adds [StrutStyle.leading] padding to the line — exactly the knob
  /// `symbolDistanceMultiplier` controls (`leading = mult - 1`). Kept
  /// SEPARATE from `lineAscent + lineDescent` (the cluster's font-
  /// natural box) because layout/baseline use the leading-free metric
  /// to keep the rolled box compact, while the slide stride needs the
  /// leading-inclusive metric to keep step A and step B from
  /// double-exposing during transitions (the "ghost emoji" bug).
  final double slideHeight;

  /// True iff the cluster sits at the visual left edge of its
  /// substituted paragraph. The painter uses this to gate
  /// row-leading outer-pad extensions (cursive flourishes, leading
  /// marks). False for sentinel/missing-cluster frames.
  final bool clusterIsParagraphLeftEdge;

  /// True iff the cluster sits at the visual right edge of its
  /// substituted paragraph. Mirror of [clusterIsParagraphLeftEdge]
  /// for the row's trailing outer pad.
  final bool clusterIsParagraphRightEdge;

  /// Total height of the cluster's line (ascent + descent). Equivalent
  /// to [clusterBounds.height] when the cluster is on the first line
  /// of a single-line paragraph, but cached separately so the row
  /// can size against a sentinel-collapsed slot without crashing.
  double get lineHeight => lineAscent + lineDescent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TapeFrame &&
          other.substitutedText == substitutedText &&
          other.clusterBounds == clusterBounds &&
          other.tapeStep == tapeStep &&
          other.lineAscent == lineAscent &&
          other.lineDescent == lineDescent &&
          other.slideHeight == slideHeight &&
          other.clusterIsParagraphLeftEdge == clusterIsParagraphLeftEdge &&
          other.clusterIsParagraphRightEdge == clusterIsParagraphRightEdge;

  @override
  int get hashCode => Object.hash(
        substitutedText,
        clusterBounds,
        tapeStep,
        lineAscent,
        lineDescent,
        slideHeight,
        clusterIsParagraphLeftEdge,
        clusterIsParagraphRightEdge,
      );

  @override
  String toString() =>
      'TapeFrame(step: $tapeStep, text: "$substitutedText", '
      'bounds: $clusterBounds, ascent: $lineAscent, descent: $lineDescent, '
      'slide: $slideHeight, '
      'leftEdge: $clusterIsParagraphLeftEdge, '
      'rightEdge: $clusterIsParagraphRightEdge)';
}
