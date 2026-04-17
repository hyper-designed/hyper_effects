// Probe: render the rolling widget alongside a sibling Text to check
// baseline alignment. Mirrors the example app's Translation widget
// shape (rolled text + ", Stranger" sibling) so the user can spot
// any baseline drift visually.

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

  const style = TextStyle(
    fontFamily: 'TestLatin',
    fontSize: 48,
    color: Color(0xFF111111),
  );

  testWidgets('rolled "Ni Hao" + sibling Text(", Stranger") at p=0',
      (tester) async {
    final png = await _captureRow(
      tester,
      progress: 0.0,
      from: 'Ni Hao',
      to: 'Namaste',
      style: style,
    );
    File('/tmp/probe_baseline_nihao_p000.png').writeAsBytesSync(png);
  });

  testWidgets('rolled "Ni Hao" + sibling Text(", Stranger") at p=0.30',
      (tester) async {
    final png = await _captureRow(
      tester,
      progress: 0.30,
      from: 'Ni Hao',
      to: 'Namaste',
      style: style,
    );
    File('/tmp/probe_baseline_nihao_p030.png').writeAsBytesSync(png);
  });

  testWidgets('rolled "Namaste" + sibling Text(", Stranger") at p=1.0',
      (tester) async {
    final png = await _captureRow(
      tester,
      progress: 1.0,
      from: 'Ni Hao',
      to: 'Namaste',
      style: style,
    );
    File('/tmp/probe_baseline_namaste_p100.png').writeAsBytesSync(png);
  });
}

Future<Uint8List> _captureRow(
  WidgetTester tester, {
  required double progress,
  required String from,
  required String to,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                _PinnedRollHarness(
                  from: from,
                  to: to,
                  progress: progress,
                  style: style,
                ),
                Text(', Stranger', style: style),
              ],
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
