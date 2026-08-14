import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  test('compiles the stamp chain into typed keyframe tracks', () {
    const content = SizedBox.square(dimension: 74);
    final chain = content
        .scale(0)
        .rotate(0)
        .step(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutQuart,
        )
        .scale(1.5)
        .rotate(15 * pi / 180)
        .step(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          delay: const Duration(milliseconds: 150),
        )
        .scale(1)
        .rotate(0);

    final spec = TimelineSpec.compile(chain);

    expect(spec.segments, [
      const TimelineSegment(
        duration: Duration(milliseconds: 350),
        curve: Curves.easeOutQuart,
        delay: Duration.zero,
      ),
      const TimelineSegment(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        delay: Duration(milliseconds: 150),
      ),
    ]);
    expect(spec.totalDuration, const Duration(milliseconds: 800));

    expect(spec.tracks, hasLength(2));
    final scaleTrack =
        spec.tracks.singleWhere((t) => t.effectType == ScaleEffect);
    expect(scaleTrack.keyframes, [
      ScaleEffect(scale: 0),
      ScaleEffect(scale: 1.5),
      ScaleEffect(scale: 1),
    ]);
    final rotationTrack =
        spec.tracks.singleWhere((t) => t.effectType == RotationEffect);
    expect(rotationTrack.keyframes, [
      const RotationEffect(angle: 0),
      const RotationEffect(angle: 15 * pi / 180),
      const RotationEffect(angle: 0),
    ]);

    expect(spec.child, same(content));
  });

  test('a type missing from a keyframe carries the previous value forward',
      () {
    const content = SizedBox.square(dimension: 74);
    final chain = content
        .scale(0.5)
        .step(duration: const Duration(milliseconds: 100))
        .fadeOut()
        .step(duration: const Duration(milliseconds: 100))
        .scale(1);

    final spec = TimelineSpec.compile(chain);

    final scaleTrack =
        spec.tracks.singleWhere((t) => t.effectType == ScaleEffect);
    expect(scaleTrack.keyframes, [
      ScaleEffect(scale: 0.5),
      ScaleEffect(scale: 0.5), // carried forward through keyframe 1
      ScaleEffect(scale: 1),
    ]);

    // Opacity first appears at keyframe 1: earlier keyframes idle.
    final opacityTrack =
        spec.tracks.singleWhere((t) => t.effectType == OpacityEffect);
    expect(opacityTrack.keyframes[1], OpacityEffect(opacity: 0));
    expect(opacityTrack.keyframes[0], OpacityEffect(opacity: 0).idle());
    // And carries forward to the final keyframe.
    expect(opacityTrack.keyframes[2], OpacityEffect(opacity: 0));
  });

  test('duplicate effect type within one keyframe throws', () {
    const content = SizedBox.square(dimension: 74);
    final chain = content.scale(0.5).scale(2);
    expect(() => TimelineSpec.compile(chain), throwsFlutterError);
  });
}
