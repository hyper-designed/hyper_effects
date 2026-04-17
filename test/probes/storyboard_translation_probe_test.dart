// Probe: replicate the example app's `Translation` widget pixel-for-
// pixel — Sacramento cursive at 56 pt, the two nested ShaderMasks
// for the gradient + fade, the exact `slotClipPadding` and tape
// curves — and capture the EXACT frame the user is critiquing.
//
// Two scenarios per word:
//
//   * "before"  — settled state, progress = 1.0 against an unchanged
//                 trigger (mounted with from == to). This is what
//                 the user sees just before the trigger flips.
//   * "first"   — first frame of the new roll. Mounted with `from`,
//                 then a postFrameCallback flips to `to`. We capture
//                 at progress = 0.0 (just after the controller
//                 swapped, before the curve has advanced) so the
//                 row holds oldText geometry but is in transition.
//
// Run: flutter test test/probes/storyboard_translation_probe_test.dart
// Output: /tmp/probe_storyboard_<word>_<phase>.png

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  // Latin Sacramento captures the swash issue most cleanly. The
  // cycle in the example app rolls through these in order; we
  // probe the two the user called out (Salaam + Ni Hao) and pick
  // adjacent words so the controller's `oldText → newText`
  // matches what the running app produces.
  testWidgets('Salaam — before roll (settled)', (tester) async {
    final png = await _captureStoryboard(
      tester,
      from: 'Salaam',
      to: 'Salaam',
      progress: 1.0,
    );
    File('/tmp/probe_storyboard_salaam_before.png').writeAsBytesSync(png);
  });

  testWidgets('Salaam → Hello — first frame (progress=0.0)',
      (tester) async {
    // Trigger order: mount with from=Namaste (the prev word in the
    // example cycle), flip to Salaam, then capture at progress 0.0
    // — that's the user's "before roll starts on Salaam".
    final png = await _captureStoryboard(
      tester,
      from: 'Namaste',
      to: 'Salaam',
      progress: 0.0,
    );
    File('/tmp/probe_storyboard_salaam_first.png').writeAsBytesSync(png);
  });

  testWidgets('Ni Hao — before roll (settled)', (tester) async {
    final png = await _captureStoryboard(
      tester,
      from: 'Ni Hao',
      to: 'Ni Hao',
      progress: 1.0,
    );
    File('/tmp/probe_storyboard_nihao_before.png').writeAsBytesSync(png);
  });

  testWidgets('Ni Hao → Namaste — first frame (progress=0.0)',
      (tester) async {
    final png = await _captureStoryboard(
      tester,
      from: 'Ni Hao',
      to: 'Namaste',
      progress: 0.0,
    );
    File('/tmp/probe_storyboard_nihao_first.png').writeAsBytesSync(png);
  });

  testWidgets('Ni Hao → Namaste — first frame WITHOUT ShaderMask',
      (tester) async {
    // Strip the gradient layers to isolate whether the artifact is
    // produced by the painter alone or by ShaderMask interaction.
    final png = await _captureStoryboard(
      tester,
      from: 'Ni Hao',
      to: 'Namaste',
      progress: 0.0,
      withShaderMask: false,
    );
    File('/tmp/probe_storyboard_nihao_first_noshader.png')
        .writeAsBytesSync(png);
  });

  // The codex review's secondary point: shrink endpoints (e.g. settled
  // "Salaam" REACHED VIA Namaste→Salaam where N is wider than S) used
  // to suppress leading-edge swash because slotW=SW < max(NW,SW)=NW.
  // The per-frame fully-grown gate fixes that. These captures
  // exercise both directions:
  //
  //   * Namaste(7) → Salaam(6) settled at progress=1 — leading 'S'
  //     swash should render (slotW=SW matches lastFrame's 'S' width).
  //   * Salaam(6) → Namaste(7) settled at progress=1 — trailing 'e'
  //     swash should render.
  testWidgets('Namaste→Salaam — settled at progress=1.0',
      (tester) async {
    final png = await _captureStoryboard(
      tester,
      from: 'Namaste',
      to: 'Salaam',
      progress: 1.0,
    );
    File('/tmp/probe_storyboard_namaste_to_salaam_settled.png')
        .writeAsBytesSync(png);
  });

  testWidgets('Salaam→Namaste — settled at progress=1.0',
      (tester) async {
    final png = await _captureStoryboard(
      tester,
      from: 'Salaam',
      to: 'Namaste',
      progress: 1.0,
    );
    File('/tmp/probe_storyboard_salaam_to_namaste_settled.png')
        .writeAsBytesSync(png);
  });

  // Mid-roll captures — stagger creates per-cluster y offsets that
  // would (without seam blending) produce a hard discontinuity at
  // every adjacent-cluster seam in cursive scripts. With seam-overlap
  // alpha-gradient blending, the discontinuity becomes a smooth
  // gradient across ~8 px at each seam.
  for (final p in const [0.10, 0.25, 0.50, 0.75]) {
    testWidgets('Namaste→Salaam mid-roll at progress=$p', (tester) async {
      final png = await _captureStoryboard(
        tester,
        from: 'Namaste',
        to: 'Salaam',
        progress: p,
      );
      File('/tmp/probe_storyboard_namaste_to_salaam_mid_p'
              '${(p * 100).round().toString().padLeft(3, '0')}.png')
          .writeAsBytesSync(png);
    });
  }

  // Same comparison but with a translucent magenta highlighter behind
  // the rolled widget so the widget's own bounds are visible. Lets us
  // tell whether the dash sits INSIDE the rolled widget's box (a
  // painter bug) or OUTSIDE (something else painting into the row).
  testWidgets('Ni Hao before — bg-tinted', (tester) async {
    final png = await _captureStoryboard(
      tester,
      from: 'Ni Hao',
      to: 'Ni Hao',
      progress: 1.0,
      withShaderMask: false,
      tintRolled: true,
    );
    File('/tmp/probe_storyboard_nihao_before_tinted.png')
        .writeAsBytesSync(png);
  });

  testWidgets('Ni Hao → Namaste first — bg-tinted', (tester) async {
    final png = await _captureStoryboard(
      tester,
      from: 'Ni Hao',
      to: 'Namaste',
      progress: 0.0,
      withShaderMask: false,
      tintRolled: true,
    );
    File('/tmp/probe_storyboard_nihao_first_tinted.png')
        .writeAsBytesSync(png);
  });
}

/// Mirrors the example app's `Translation` widget shell: dark
/// background, two nested ShaderMasks, padded ", Stranger" sibling,
/// Sacramento at 56 pt, etc. The rolled `Text(...).roll()` config is
/// copy-pasted from `example/lib/stories/text_animation.dart`.
Future<Uint8List> _captureStoryboard(
  WidgetTester tester, {
  required String from,
  required String to,
  required double progress,
  bool withShaderMask = true,
  bool tintRolled = false,
}) async {
  final key = GlobalKey();
  Widget rolled = _PinnedRollHarness(
    from: from,
    to: to,
    progress: progress,
  );
  if (tintRolled) {
    // 30% magenta backdrop on the rolled widget's box. Anything
    // painted *outside* this tint is not coming from the rolled
    // widget — it's coming from a sibling or the parent Row's
    // layout state.
    rolled = ColoredBox(color: const Color(0x4DFF00FF), child: rolled);
  }
  if (withShaderMask) {
    rolled = ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white,
          Colors.white,
          Colors.white,
          Colors.white,
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(rect),
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [
            Color(0xFFD4145A),
            Color(0xFFFBB03B),
          ],
        ).createShader(rect),
        child: rolled,
      ),
    );
  }
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.noScaling),
          child: Scaffold(
            backgroundColor: const Color(0xFF111111),
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: const Color(0xFF111111),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      // Match the example app: baseline alignment so
                      // the rolled widget anchors against the sibling
                      // Text's typographic baseline.
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        rolled,
                        const Text(
                          ', Stranger',
                          style: TextStyle(
                            fontFamily: 'TestSacramento',
                            color: Colors.white,
                            fontSize: 56,
                          ),
                          strutStyle: StrutStyle(
                            fontSize: 56,
                            height: 1,
                            forceStrutHeight: true,
                            leading: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.runAsync<Uint8List>(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData!.buffer.asUint8List();
  }).then((value) => value!);
}

class _PinnedRollHarness extends StatefulWidget {
  const _PinnedRollHarness({
    required this.from,
    required this.to,
    required this.progress,
  });
  final String from;
  final String to;
  final double progress;
  @override
  State<_PinnedRollHarness> createState() => _PinnedRollHarnessState();
}

class _PinnedRollHarnessState extends State<_PinnedRollHarness> {
  late String _text = widget.from;

  @override
  void initState() {
    super.initState();
    if (widget.from != widget.to) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _text = widget.to);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // No `.animate()` here on purpose: AnimatedEffect would inject
    // its own ticker-driven EffectQuery, overriding the one we want
    // to pin. EffectQuery wrapping the bare `.roll()` is the way to
    // freeze progress at a specific frame for offline capture.
    return EffectQuery(
      linearValue: widget.progress,
      curvedValue: widget.progress,
      isTransition: false,
      child: Text(
        _text,
        style: const TextStyle(
          fontFamily: 'TestSacramento',
          fontWeight: FontWeight.bold,
          fontSize: 56,
          color: Colors.white,
        ),
      ).roll(
        symbolDistanceMultiplier: 2,
        tapeCurve: Curves.easeInOutBack,
        widthCurve: Curves.easeInOutQuart,
        padding: const EdgeInsets.only(right: 3),
        slotClipPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 4,
        ),
      ),
    );
  }
}
