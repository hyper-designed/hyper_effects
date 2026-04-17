// Probe: capture the EmojiLine scenario at many progress values
// to expose blending / rendering artifacts during transition.
// Mirrors the example app's `EmojiLine` config exactly:
//
//   * Container with primaryContainer-coloured pill background.
//   * tapeStrategy: ConsistentSymbolTapeStrategy(4, +EmojiTapeBuilder).
//   * tapeSlideDirection: alternating.
//   * tapeCurve: easeInOutBack (overshoots both ends).
//   * symbolDistanceMultiplier: 2.
//   * staggerSoftness: 30, staggerTapes: true.
//   * Hello → Sexy / World → Effect with emoji string in the middle.
//
// Using TestLatin + TestEmoji fallback. Each emoji is dense RGB
// content — additive plus-blend artifacts manifest as ghost
// overlays in mid-roll frames.
//
// Captures: /tmp/probe_emoji_sweep_p<NNN>.png at progress
// 0.00..1.00 in 0.05 increments.

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

  for (final progress in [
    0.00,
    0.05,
    0.10,
    0.15,
    0.20,
    0.25,
    0.30,
    0.35,
    0.40,
    0.45,
    0.50,
    0.55,
    0.60,
    0.65,
    0.70,
    0.75,
    0.80,
    0.85,
    0.90,
    0.95,
    1.00,
  ]) {
    testWidgets(
        'emoji sweep p=${progress.toStringAsFixed(2)}',
        (tester) async {
      final png = await _capture(tester, progress: progress);
      final tag = (progress * 100).round().toString().padLeft(3, '0');
      File('/tmp/probe_emoji_sweep_p$tag.png').writeAsBytesSync(png);
    });
  }
}

Future<Uint8List> _capture(
  WidgetTester tester, {
  required double progress,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      ),
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.noScaling),
          child: Scaffold(
            backgroundColor: const Color(0xFFEAE2FF),
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: const _EmojiHarness(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Drive the harness's progress.
  final state = tester.state<_EmojiHarnessState>(find.byType(_EmojiHarness));
  state.setProgress(progress);
  await tester.pumpAndSettle();

  return tester.runAsync<Uint8List>(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData!.buffer.asUint8List();
  }).then((value) => value!);
}

class _EmojiHarness extends StatefulWidget {
  const _EmojiHarness();
  @override
  State<_EmojiHarness> createState() => _EmojiHarnessState();
}

class _EmojiHarnessState extends State<_EmojiHarness> {
  double _progress = 0.0;

  void setProgress(double p) {
    setState(() {
      _progress = p;
      // Toggle text on first non-zero progress so the controller
      // sees a real transition.
      if (p > 0 && _text == _from) {
        _text = _to;
      } else if (p == 0) {
        _text = _from;
      }
    });
  }

  static const _from = 'Hello 😀😃😄😁😆 Sexy';
  static const _to = 'World 🧳🌂☂️🧵🪡 Effect';
  String _text = _from;

  @override
  Widget build(BuildContext context) {
    return EffectQuery(
      linearValue: _progress,
      curvedValue: _progress,
      isTransition: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Text(
          _text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontFamily: 'TestLatin',
            fontFamilyFallback: const ['TestEmoji'],
            fontSize: 32,
          ),
        ).roll(
          tapeStrategy: const ConsistentSymbolTapeStrategy(4),
          tapeSlideDirection: TextTapeSlideDirection.alternating,
          staggerTapes: true,
          tapeCurve: Curves.easeInOutBack,
          widthCurve: Curves.easeOutQuart,
          symbolDistanceMultiplier: 2,
          staggerSoftness: 30,
          tapeShapingContext: TapeShapingContext.newWord,
        ),
      ),
    );
  }
}
