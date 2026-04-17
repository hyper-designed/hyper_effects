import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../effect_query.dart';
import '../../text/cluster_effect.dart';
import '../../text/cluster_painter.dart';
import '../../text/shaped_cluster.dart';
import '../../text/shaped_text.dart';
import '../effect.dart';

/// An effect that reveals a [Text] one grapheme cluster at a time with a
/// staggered blur → opacity → (optional) rise-from transform.
///
/// Ligature-safe and RTL-aware by construction. Invoke via the
/// `Text.blurReveal()` extension:
///
/// ```dart
/// Text('Hello').blurReveal().animate(trigger: revealed);
/// ```
class BlurRevealEffect extends Effect {
  /// The text to reveal.
  final String text;

  /// The resolved text style.
  final TextStyle style;

  /// Text direction override. Defaults to ambient `Directionality` when null.
  final TextDirection? textDirection;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Text scaler.
  final TextScaler? textScaler;

  /// Strut style.
  final StrutStyle? strutStyle;

  /// Text height behavior.
  final ui.TextHeightBehavior? textHeightBehavior;

  /// Locale hint for shaping.
  final Locale? locale;

  /// Max layout width. When null, the enclosing constraints are used.
  final double? maxWidth;

  /// Delay before the reveal starts.
  final Duration delay;

  /// Timeline-compression multiplier.
  ///
  /// * `1.0` (default) = last cluster finishes exactly at progress 1.0.
  /// * `2.0` = animation completes twice as fast (at progress 0.5).
  /// * `0.5` = animation extends past progress 1.0 (clipped at the end by
  ///   the animation controller's upper bound).
  ///
  /// Higher values = faster reveal. Default 1.0.
  final double speedReveal;

  /// Per-cluster reveal duration as a fraction of the total timeline.
  /// Default 0.5.
  final double speedSegment;

  /// Starting blur sigma. Default 10.
  final double blurSigma;

  /// Translate offset each cluster rises FROM. `Offset.zero` disables rise.
  /// Default `Offset(0, 12)`.
  final Offset riseFrom;

  /// Per-cluster easing curve. Default `Curves.easeOutCubic`.
  final Curve curve;

  /// Creates a [BlurRevealEffect].
  const BlurRevealEffect({
    required this.text,
    required this.style,
    this.textDirection,
    this.textAlign,
    this.textScaler,
    this.strutStyle,
    this.textHeightBehavior,
    this.locale,
    this.maxWidth,
    this.delay = Duration.zero,
    this.speedReveal = 1.0,
    this.speedSegment = 0.5,
    this.blurSigma = 10.0,
    this.riseFrom = const Offset(0, 12),
    this.curve = Curves.easeOutCubic,
  });

  @override
  BlurRevealEffect lerp(covariant BlurRevealEffect other, double value) =>
      other;

  @override
  Widget apply(BuildContext context, Widget? child) =>
      _BlurRevealWidget(effect: this);

  @override
  List<Object?> get props => [
        text,
        style,
        textDirection,
        textAlign,
        textScaler,
        strutStyle,
        textHeightBehavior,
        locale,
        maxWidth,
        delay,
        speedReveal,
        speedSegment,
        blurSigma,
        riseFrom,
        curve,
      ];
}

/// Computes the per-cluster [ClusterEffect] for a [BlurRevealEffect] at the
/// given animation [progress] (0..1). Exposed for unit-testing.
@visibleForTesting
ClusterEffect computeBlurRevealClusterEffect({
  required BlurRevealEffect effect,
  required int visualIndex,
  required int totalClusters,
  required double progress,
}) =>
    _computeClusterEffect(
      effect: effect,
      visualIndex: visualIndex,
      totalClusters: totalClusters,
      progress: progress,
    );

ClusterEffect _computeClusterEffect({
  required BlurRevealEffect effect,
  required int visualIndex,
  required int totalClusters,
  required double progress,
}) {
  if (totalClusters <= 0) return ClusterEffect.identity;

  // Per-cluster window size (fraction of the 0..1 timeline).
  final reveal = effect.speedSegment.clamp(0.01, 1.0);
  // Gap between successive cluster starts.
  final gap = totalClusters > 1 ? (1.0 - reveal) / (totalClusters - 1) : 0.0;
  // How far into the timeline the last cluster should finish.
  //   speedReveal > 1 → finishes earlier (less than 1.0)
  //   speedReveal = 1 → fills the full 0..1 timeline
  //   speedReveal < 1 → extends past 1.0 (clipped by the animation bound)
  final scale = 1.0 / effect.speedReveal.clamp(0.1, 10.0);

  final start = visualIndex * gap * scale;
  final end = start + reveal * scale;
  final denom = end - start;
  final local = denom <= 0
      ? (progress >= start ? 1.0 : 0.0)
      : ((progress - start) / denom).clamp(0.0, 1.0);
  final eased = effect.curve.transform(local);

  final rise = (effect.riseFrom == Offset.zero || eased >= 1.0)
      ? null
      : Matrix4.translationValues(
          effect.riseFrom.dx * (1.0 - eased),
          effect.riseFrom.dy * (1.0 - eased),
          0,
        );

  return ClusterEffect(
    opacity: eased,
    blurSigma: effect.blurSigma * (1.0 - eased),
    transform: rise,
  );
}

class _BlurRevealWidget extends StatelessWidget {
  const _BlurRevealWidget({required this.effect});

  final BlurRevealEffect effect;

  @override
  Widget build(BuildContext context) {
    final query = EffectQuery.maybeOf(context);
    final progress = query?.curvedValue ?? 1.0;
    // Use a _BlurRevealLayout RenderObject so that alchemist's Table-based
    // intrinsic sizing pass does not hit the LayoutBuilder restriction.
    return _BlurRevealLayout(
      effect: effect,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _BlurRevealPainter(effect: effect, progress: progress),
        ),
      ),
    );
  }
}

/// A single-child layout widget that sizes itself to the shaped-text dimensions
/// and supports intrinsic sizing (required by alchemist's Table golden group).
class _BlurRevealLayout extends SingleChildRenderObjectWidget {
  const _BlurRevealLayout({required this.effect, required super.child});

  final BlurRevealEffect effect;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBlurRevealLayout(effect: effect);

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderBlurRevealLayout renderObject) {
    renderObject.effect = effect;
  }
}

class _RenderBlurRevealLayout extends RenderProxyBox {
  _RenderBlurRevealLayout({required BlurRevealEffect effect})
      : _effect = effect;

  BlurRevealEffect _effect;

  BlurRevealEffect get effect => _effect;
  set effect(BlurRevealEffect value) {
    if (_effect == value) return;
    _effect = value;
    markNeedsLayout();
  }

  ShapedText _buildShaped(double width) => ShapedText.build(
        text: _effect.text,
        style: _effect.style,
        textDirection: _effect.textDirection,
        textAlign: _effect.textAlign,
        textScaler: _effect.textScaler,
        strutStyle: _effect.strutStyle,
        textHeightBehavior: _effect.textHeightBehavior,
        locale: _effect.locale,
        maxWidth: _effect.maxWidth ?? width,
      );

  @override
  double computeMinIntrinsicWidth(double height) =>
      _buildShaped(double.infinity).size.width;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _buildShaped(double.infinity).size.width;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _buildShaped(width.isFinite ? width : double.infinity).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _buildShaped(width.isFinite ? width : double.infinity).size.height;

  @override
  void performLayout() {
    final shaped = _buildShaped(
        constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity);
    size = constraints.constrain(shaped.size);
    child?.layout(BoxConstraints.tight(size));
  }
}

class _BlurRevealPainter extends CustomPainter {
  _BlurRevealPainter({required this.effect, required this.progress});

  final BlurRevealEffect effect;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Re-resolve the ShapedText each frame — the cache returns the same
    // instance for identical args, so this is cheap. Holding a ShapedText
    // reference across frames is unsafe (paragraphs may be disposed on
    // cache eviction).
    final shaped = ShapedText.build(
      text: effect.text,
      style: effect.style,
      textDirection: effect.textDirection,
      textAlign: effect.textAlign,
      textScaler: effect.textScaler,
      strutStyle: effect.strutStyle,
      textHeightBehavior: effect.textHeightBehavior,
      locale: effect.locale,
      maxWidth: effect.maxWidth ?? size.width,
    );
    final total = shaped.clusters.length;
    ClusterPainter.paintWithClusters(
      canvas,
      shaped,
      Offset.zero,
      (ShapedCluster c) => _computeClusterEffect(
        effect: effect,
        visualIndex: c.visualIndex,
        totalClusters: total,
        progress: progress,
      ),
    );
  }

  @override
  bool shouldRepaint(_BlurRevealPainter old) =>
      old.effect != effect || old.progress != progress;
}
