// Diagnostic probe: render shaped roll for length-mismatched transitions
// at sample progress values, save each frame as a PNG to /tmp so a human
// can inspect what the user is seeing in the screenshots they shared
// (Marhalaba / Konnichiwwa / Namasté artifacts at start of roll).
//
// Run: flutter test test/probes/start_frame_artifacts_probe_test.dart
// Output: /tmp/start_frame_<from>_to_<to>_p<NN>.png + a contact-sheet
//         <from>_to_<to>.png per pair.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../helpers/test_app.dart';
import '../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  // Pairs that exercise the length-mismatch case the user flagged.
  const pairs = <(String, String)>[
    ('Marhaba', 'Hola'),
    ('Hola', 'Marhaba'),
    ('Saluton', 'Konnichiwa'),
    ('Konnichiwa', 'Annyeong'),
    ('Ni Hao', 'Namaste'),
  ];

  // Progress points spanning start (overshoot bounce range), mid-roll,
  // and the tail. The user-reported artifacts appear in the early-mid
  // band for them, so sample densely there.
  const progressPoints = <double>[
    0.00, 0.02, 0.05, 0.10, 0.15, 0.20, 0.30, 0.40, 0.50, 0.70, 0.90, 1.00,
  ];

  const style = TextStyle(
    fontFamily: 'TestLatin',
    fontSize: 48,
    color: Color(0xFF111111),
  );

  for (final (from, to) in pairs) {
    testWidgets('render $from → $to at progress points', (tester) async {
      final pngs = <Uint8List>[];
      for (final p in progressPoints) {
        final png = await _capture(
          tester,
          from: from,
          to: to,
          progress: p,
          style: style,
        );
        pngs.add(png);
        final fname = '/tmp/start_frame_${_slug(from)}_to_${_slug(to)}'
            '_p${(p * 100).round().toString().padLeft(3, '0')}.png';
        File(fname).writeAsBytesSync(png);
      }
      // Also write a contact-sheet stack to /tmp for quick visual scan.
      final sheet = await _stackVertical(pngs);
      File('/tmp/${_slug(from)}_to_${_slug(to)}.png')
          .writeAsBytesSync(sheet);
      // ignore: avoid_print
      print('Wrote ${pngs.length} PNGs for $from → $to to /tmp/');
    });
  }
}

String _slug(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

Future<Uint8List> _capture(
  WidgetTester tester, {
  required String from,
  required String to,
  required double progress,
  required TextStyle style,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    wrapInTestApp(
      RepaintBoundary(
        key: key,
        child: ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _PinnedRollHarness(
              from: from,
              to: to,
              progress: progress,
              style: style,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Run on the test scheduler binding's element so RenderRepaintBoundary
  // is visible; tester.runAsync is required to allow toImage to use the
  // platform dispatcher loop.
  return tester.runAsync<Uint8List>(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData!.buffer.asUint8List();
  }).then((value) => value!);
}

/// Stacks PNGs vertically into a single "contact sheet" image.
Future<Uint8List> _stackVertical(List<Uint8List> pngs) async {
  // Decode each, find common width, stack heights.
  final images = <ui.Image>[];
  for (final bytes in pngs) {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    images.add(frame.image);
  }
  int width = 0;
  int height = 0;
  for (final img in images) {
    if (img.width > width) width = img.width;
    height += img.height;
  }
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  // White background.
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  double y = 0;
  for (final img in images) {
    canvas.drawImage(img, Offset(0, y), Paint());
    y += img.height;
  }
  final picture = recorder.endRecording();
  final stacked = await picture.toImage(width, height);
  final byteData = await stacked.toByteData(format: ui.ImageByteFormat.png);
  stacked.dispose();
  for (final img in images) {
    img.dispose();
  }
  picture.dispose();
  return byteData!.buffer.asUint8List();
}

/// Renders a shaped roll mid-transition, pinned at a specific [progress]
/// via an explicit `EffectQuery` — bypasses `AnimatedEffect` so the
/// snapshot is deterministic regardless of ticker timing. Uses the same
/// `slotClipPadding` and `tapeCurve` as the example app's `Translation`
/// widget so the probe captures the user's actual visual config.
class _PinnedRollHarness extends StatefulWidget {
  const _PinnedRollHarness({
    required this.from,
    required this.to,
    required this.progress,
    required this.style,
  });

  final String from;
  final String to;
  final double progress;
  final TextStyle style;

  @override
  State<_PinnedRollHarness> createState() => _PinnedRollHarnessState();
}

class _PinnedRollHarnessState extends State<_PinnedRollHarness> {
  late String _text = widget.from;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _text = widget.to);
    });
  }

  @override
  Widget build(BuildContext context) {
    return EffectQuery(
      linearValue: widget.progress,
      curvedValue: widget.progress,
      isTransition: false,
      child: Text(_text, style: widget.style).roll(
        renderMode: TextRenderMode.contextualCharacters,
        tapeCurve: Curves.easeInOutBack,
        slotClipPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      ),
    );
  }
}
