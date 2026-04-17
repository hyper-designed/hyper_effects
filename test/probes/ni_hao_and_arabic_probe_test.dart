// Focused probe: render the two transitions that exposed bugs in the
// row-level rewrite — Ni Hao → Namaste (Latin growing-in-tail
// floating artifact) and an Arabic RTL roll (mirrored glyphs from
// the canvas-flip). Output goes to /tmp/ for human inspection.
//
// Run: flutter test test/probes/ni_hao_and_arabic_probe_test.dart

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

  const progressPoints = <double>[0.0, 0.05, 0.15, 0.30, 0.5, 0.7, 1.0];

  testWidgets('Ni Hao → Namaste — growing-in tail (no floating artifact)',
      (tester) async {
    const style = TextStyle(
      fontFamily: 'TestLatin',
      fontSize: 48,
      color: Color(0xFF111111),
    );
    for (final p in progressPoints) {
      final png = await _capture(
        tester,
        from: 'Ni Hao',
        to: 'Namaste',
        progress: p,
        style: style,
        textDirection: TextDirection.ltr,
      );
      File('/tmp/probe_nihao_to_namaste_p'
              '${(p * 100).round().toString().padLeft(3, '0')}.png')
          .writeAsBytesSync(png);
    }
  });

  testWidgets('Arabic مرحبا → شكرا — RTL roll (no glyph mirroring)',
      (tester) async {
    const style = TextStyle(
      fontFamily: 'TestArabic',
      fontSize: 48,
      color: Color(0xFF111111),
    );
    for (final p in progressPoints) {
      final png = await _capture(
        tester,
        from: 'مرحبا',
        to: 'شكرا',
        progress: p,
        style: style,
        textDirection: TextDirection.rtl,
      );
      File('/tmp/probe_arabic_marhaba_to_shukran_p'
              '${(p * 100).round().toString().padLeft(3, '0')}.png')
          .writeAsBytesSync(png);
    }
  });

  testWidgets('Arabic مرحبا (settled) — sanity check vs plain Text',
      (tester) async {
    const style = TextStyle(
      fontFamily: 'TestArabic',
      fontSize: 48,
      color: Color(0xFF111111),
    );
    // Reference: plain Text("مرحبا") and plain Text("شكرا").
    {
      final png = await _captureRaw(
        tester,
        const Text('مرحبا', style: style),
        textDirection: TextDirection.rtl,
      );
      File('/tmp/probe_arabic_plain_text.png').writeAsBytesSync(png);
    }
    {
      final png = await _captureRaw(
        tester,
        const Text('شكرا', style: style),
        textDirection: TextDirection.rtl,
      );
      File('/tmp/probe_arabic_plain_shukran.png').writeAsBytesSync(png);
    }
    // Subject: rolling widget at rest (no transition; just the
    // initial render via mount).
    {
      final png = await _capture(
        tester,
        from: 'مرحبا',
        to: 'مرحبا',
        progress: 1.0,
        style: style,
        textDirection: TextDirection.rtl,
      );
      File('/tmp/probe_arabic_rolled_settled.png').writeAsBytesSync(png);
    }
    {
      final png = await _capture(
        tester,
        from: 'شكرا',
        to: 'شكرا',
        progress: 1.0,
        style: style,
        textDirection: TextDirection.rtl,
      );
      File('/tmp/probe_arabic_rolled_shukran_settled.png').writeAsBytesSync(png);
    }
  });
}

Future<Uint8List> _capture(
  WidgetTester tester, {
  required String from,
  required String to,
  required double progress,
  required TextStyle style,
  required TextDirection textDirection,
}) async {
  return _captureRaw(
    tester,
    _PinnedRollHarness(
      from: from,
      to: to,
      progress: progress,
      style: style,
    ),
    textDirection: textDirection,
  );
}

Future<Uint8List> _captureRaw(
  WidgetTester tester,
  Widget child, {
  required TextDirection textDirection,
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
            child: child,
          ),
        ),
      ),
      textDirection: textDirection,
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
    if (widget.from != widget.to) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _text = widget.to);
      });
    }
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
