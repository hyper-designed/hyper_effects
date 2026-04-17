import 'package:flutter/material.dart';

import '../../effect_widget.dart';
import 'blur_reveal_effect.dart';

export 'blur_reveal_effect.dart';

/// Adds a [Text.blurReveal] extension that applies a [BlurRevealEffect].
extension BlurRevealTextExt on Text {
  /// Reveals this text one grapheme cluster at a time with a staggered
  /// blur + opacity + (optional) rise-from translate.
  ///
  /// Compose with [Widget.animate] to drive the reveal:
  ///
  /// ```dart
  /// Text('Hello, World!').blurReveal().animate(trigger: visible);
  /// ```
  ///
  /// The effect is ligature-safe and RTL-aware — Arabic renders with correct
  /// cursive connection and reveals right-to-left in RTL contexts.
  ///
  /// If no [AnimatedEffect] / [ScrollTransition] ancestor is present, the
  /// reveal is rendered as fully complete (equivalent to static [Text]).
  ///
  /// [speedReveal] is the timeline-compression multiplier (default 1.0 =
  /// last cluster finishes exactly at progress 1.0; higher = faster).
  /// [speedSegment] is the per-cluster reveal window as a fraction of the
  /// total timeline (default 0.5). [blurSigma] is the starting blur radius
  /// in logical pixels (default 10). [riseFrom] is the translate each
  /// cluster animates from (default `Offset(0, 12)`; pass `Offset.zero`
  /// to disable rise). [curve] defaults to `Curves.easeOutCubic`.
  Widget blurReveal({
    Duration delay = Duration.zero,
    double speedReveal = 1.0,
    double speedSegment = 0.5,
    double blurSigma = 10.0,
    Offset riseFrom = const Offset(0, 12),
    Curve curve = Curves.easeOutCubic,
    double? maxWidth,
  }) {
    return Builder(
      builder: (context) {
        final defaultStyle =
            DefaultTextStyle.of(context).style.copyWith(inherit: true);
        final effectiveStyle =
            style != null ? defaultStyle.merge(style) : defaultStyle;
        return EffectWidget(
          end: BlurRevealEffect(
            text: data ?? '',
            style: effectiveStyle,
            textDirection: textDirection,
            textAlign: textAlign,
            textScaler: textScaler,
            strutStyle: strutStyle,
            textHeightBehavior: textHeightBehavior,
            locale: locale,
            maxWidth: maxWidth,
            delay: delay,
            speedReveal: speedReveal,
            speedSegment: speedSegment,
            blurSigma: blurSigma,
            riseFrom: riseFrom,
            curve: curve,
          ),
          child: this,
        );
      },
    );
  }
}
