// Probe: render the EmojiLine-style scenario (rolled text on a
// solid coloured pill background, no ShaderMask) so we can verify
// the seam-blend's outer saveLayer composites onto the parent
// without color over-saturation.

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

  testWidgets('Emoji-style: rolled text on solid background, no shaders',
      (tester) async {
    // Same shape as `EmojiLine`: a Container with a coloured
    // background, the rolled text inside. Captures whether seam
    // blending bleeds the parent background color through into the
    // glyphs.
    final pngs = <(String, Uint8List)>[];
    for (final p in const [0.0, 0.30, 0.60, 1.0]) {
      pngs.add(('p${(p * 100).round().toString().padLeft(3, '0')}',
          await _captureEmojiPill(tester, progress: p)));
    }
    for (final entry in pngs) {
      File('/tmp/probe_emoji_${entry.$1}.png').writeAsBytesSync(entry.$2);
    }
  });
}

Future<Uint8List> _captureEmojiPill(
  WidgetTester tester, {
  required double progress,
}) async {
  final key = GlobalKey();
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        // Vivid solid color — like the EmojiLine
                        // primaryContainer pill but exaggerated so
                        // any color leak through the seam-blend
                        // would be obvious.
                        color: const Color(0xFFFF7F50), // coral
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: _PinnedRollHarness(
                        progress: progress,
                      ),
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
  const _PinnedRollHarness({required this.progress});
  final double progress;
  @override
  State<_PinnedRollHarness> createState() => _PinnedRollHarnessState();
}

class _PinnedRollHarnessState extends State<_PinnedRollHarness> {
  late String _text = 'Hello World';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _text = 'Greetings All');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Black text on coral background — if seam-blend's plus
    // composite escaped the outer saveLayer, the coral background
    // would be added to itself in the seam regions and visually
    // saturate. Black text additively-blended against opaque coral
    // would also blow out. The fix wraps the row's plus composites
    // inside an outer transparent layer.
    return EffectQuery(
      linearValue: widget.progress,
      curvedValue: widget.progress,
      isTransition: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          _text,
          style: const TextStyle(
            fontFamily: 'TestLatin',
            color: Color(0xFF111111),
            fontSize: 56,
          ),
        ).roll(
          renderMode: TextRenderMode.contextualCharacters,
          tapeStrategy: const ConsistentSymbolTapeStrategy(0),
          slotClipPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }
}
