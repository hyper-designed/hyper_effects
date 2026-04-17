import 'package:flutter/material.dart';

/// Describes a per-cluster visual effect applied by [ClusterPainter].
///
/// `ClusterEffect.identity` is the no-op default; any non-default field
/// marks the effect as non-identity and routes the cluster through the
/// `saveLayer`-based paint path.
@immutable
class ClusterEffect {
  /// No-op default. Clusters with this effect take the cheap identity
  /// paint path (one `drawParagraph` for all identity clusters).
  static const ClusterEffect identity = ClusterEffect();

  /// Matrix applied around the cluster's bounds center. `null` = no transform.
  final Matrix4? transform;

  /// 1.0 = fully visible. Clamped to [0, 1] at paint time.
  final double opacity;

  /// Gaussian blur radius in logical pixels. 0 = no blur.
  final double blurSigma;

  /// Optional color filter (tint, invert, etc.).
  final ColorFilter? colorFilter;

  /// If false, the cluster is skipped entirely.
  final bool visible;

  /// Creates a [ClusterEffect]. All fields have no-op defaults; any
  /// non-default value marks the effect as non-identity and routes the
  /// cluster through the `saveLayer`-based paint path.
  const ClusterEffect({
    this.transform,
    this.opacity = 1.0,
    this.blurSigma = 0.0,
    this.colorFilter,
    this.visible = true,
  });

  /// True when this effect is a no-op.
  bool get isIdentity =>
      transform == null &&
      opacity == 1.0 &&
      blurSigma == 0.0 &&
      colorFilter == null &&
      visible;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClusterEffect &&
          other.transform == transform &&
          other.opacity == opacity &&
          other.blurSigma == blurSigma &&
          other.colorFilter == colorFilter &&
          other.visible == visible;

  @override
  int get hashCode =>
      Object.hash(transform, opacity, blurSigma, colorFilter, visible);
}
