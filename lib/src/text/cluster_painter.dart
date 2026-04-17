import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'cluster_effect.dart';
import 'shaped_cluster.dart';
import 'shaped_text.dart';

/// Paints a [ShapedText] with per-cluster decorators.
///
/// Clusters with [ClusterEffect.identity] are batched into a single
/// `drawParagraph` call; non-identity clusters use a `saveLayer` +
/// `clipRect` + translated-draw trick to re-render just their region
/// under the effect.
class ClusterPainter {
  ClusterPainter._();

  /// Paints [text] at [offset], routing each cluster through [decorator].
  ///
  /// Identity clusters (where [ClusterEffect.isIdentity] is true) are painted
  /// cheaply as a single `drawParagraph`. Non-identity clusters are painted
  /// individually via `saveLayer` + `clipRect` so the effect is isolated to
  /// that cluster's bounds only.
  static void paintWithClusters(
    Canvas canvas,
    ShapedText text,
    Offset offset,
    ClusterEffect Function(ShapedCluster cluster) decorator,
  ) {
    if (text.clusters.isEmpty) {
      // Nothing to paint.
      return;
    }

    // Pass 1: classify clusters as identity or non-identity.
    final nonIdentityEffects = <int, ClusterEffect>{};
    final invisibleRects = <Rect>[];
    bool hasAnyIdentity = false;

    for (final c in text.clusters) {
      final e = decorator(c);
      if (e.isIdentity) {
        hasAnyIdentity = true;
      } else if (e.visible) {
        // Non-identity visible cluster: needs per-cluster paint.
        nonIdentityEffects[c.visualIndex] = e;
      } else {
        // Invisible non-identity: must also be cut from the identity batch
        // so the glyph does not leak through the paragraph draw.
        invisibleRects.add(c.bounds.shift(offset));
      }
    }

    // Fast path: no cluster has a non-identity effect AND none are invisible.
    // Paint whole paragraph once.
    if (nonIdentityEffects.isEmpty && invisibleRects.isEmpty) {
      if (hasAnyIdentity) {
        text.paint(canvas, offset);
      }
      return;
    }

    // Mixed path: draw the identity batch (paragraph minus non-identity rects
    // and invisible rects) and then each non-identity cluster in its own
    // saveLayer.

    // Identity batch: clip out all non-identity and invisible cluster rects,
    // then draw once.
    if (hasAnyIdentity) {
      canvas.save();
      // Build a path that covers everything EXCEPT non-identity and invisible
      // cluster rects.
      final holeRects = <Rect>[
        for (final c in text.clusters)
          if (nonIdentityEffects.containsKey(c.visualIndex))
            c.bounds.shift(offset),
        ...invisibleRects,
      ];
      canvas.clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Rect.largest),
          _rectsPath(holeRects),
        ),
      );
      text.paint(canvas, offset);
      canvas.restore();
    }

    // Non-identity clusters: each gets its own saveLayer for the effect.
    for (final c in text.clusters) {
      final effect = nonIdentityEffects[c.visualIndex];
      if (effect == null) continue;

      final clusterRect = c.bounds.shift(offset);

      // Save canvas state and clip to this cluster's rect so effects
      // don't bleed into adjacent clusters.
      canvas.save();
      canvas.clipRect(clusterRect);

      // Apply transform around the cluster's center.
      if (effect.transform != null) {
        final center = clusterRect.center;
        canvas
          ..translate(center.dx, center.dy)
          ..transform(effect.transform!.storage)
          ..translate(-center.dx, -center.dy);
      }

      // Set up the paint for opacity / blur / color filter.
      final needsLayer = effect.opacity < 1.0 ||
          effect.blurSigma > 0 ||
          effect.colorFilter != null;

      if (needsLayer) {
        final layerPaint = Paint();
        if (effect.opacity < 1.0) {
          // Alpha compositing via saveLayer color — standard Flutter pattern.
          layerPaint.color =
              Color.fromRGBO(0, 0, 0, effect.opacity.clamp(0.0, 1.0));
        }
        if (effect.blurSigma > 0) {
          layerPaint.imageFilter = ui.ImageFilter.blur(
            sigmaX: effect.blurSigma,
            sigmaY: effect.blurSigma,
          );
        }
        if (effect.colorFilter != null) {
          layerPaint.colorFilter = effect.colorFilter;
        }

        // saveLayer isolates opacity/blur/colorFilter to this cluster.
        canvas.saveLayer(clusterRect, layerPaint);
        canvas.drawParagraph(text.paragraph, offset);
        canvas.restore(); // restore saveLayer
      } else {
        // Transform-only: no layer needed, draw directly within clip.
        canvas.drawParagraph(text.paragraph, offset);
      }

      canvas.restore(); // restore clip + transform save
    }
  }

  static Path _rectsPath(Iterable<Rect> rects) {
    final p = Path();
    for (final r in rects) {
      p.addRect(r);
    }
    return p;
  }
}
