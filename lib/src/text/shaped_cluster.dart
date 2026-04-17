import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';

/// A single grapheme-cluster slice of a [ShapedText].
///
/// Clusters are ligature-safe: Arabic `لا`, Devanagari conjuncts, and
/// ZWJ emoji sequences each come back as one cluster with one rect.
@immutable
class ShapedCluster {
  /// The cluster's position in the source string (logical order).
  final int logicalIndex;

  /// The cluster's position in visual order within its line.
  /// For LTR text this equals [logicalIndex]; for RTL or mixed-bidi
  /// the visual order differs.
  final int visualIndex;

  /// The UTF-16 code-unit range in the source string this cluster covers.
  /// For ligatures, this range spans multiple code units.
  final TextRange codeUnitRange;

  /// The cluster's visual rect relative to the paragraph origin.
  final Rect bounds;

  /// The writing direction of the cluster.
  final TextDirection direction;

  /// The grapheme cluster text (may be multiple code units for ligatures
  /// or ZWJ emoji sequences).
  final String text;

  /// The index of the line this cluster belongs to (0-based).
  final int lineIndex;

  /// Creates a [ShapedCluster]. All fields are required; the class is
  /// immutable and supports structural equality.
  const ShapedCluster({
    required this.logicalIndex,
    required this.visualIndex,
    required this.codeUnitRange,
    required this.bounds,
    required this.direction,
    required this.text,
    required this.lineIndex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShapedCluster &&
          other.logicalIndex == logicalIndex &&
          other.visualIndex == visualIndex &&
          other.codeUnitRange == codeUnitRange &&
          other.bounds == bounds &&
          other.direction == direction &&
          other.text == text &&
          other.lineIndex == lineIndex;

  @override
  int get hashCode => Object.hash(
        logicalIndex,
        visualIndex,
        codeUnitRange,
        bounds,
        direction,
        text,
        lineIndex,
      );

  @override
  String toString() =>
      "ShapedCluster('$text' logical: $logicalIndex visual: $visualIndex "
      'line: $lineIndex dir: $direction bounds: $bounds)';
}
