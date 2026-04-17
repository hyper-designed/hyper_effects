import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../../helpers/alchemist_config.dart';

void main() => withTextRendering(() {
      goldenTest(
        'shaped_text_cluster_rects',
        fileName: 'shaped_text_cluster_rects_goldens',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 500),
          children: [
            GoldenTestScenario(
              name: 'latin "Hello"',
              child: const _ClusterRectsScene(
                text: 'Hello',
                fontFamily: 'TestLatin',
                direction: TextDirection.ltr,
              ),
            ),
            GoldenTestScenario(
              name: 'arabic "سلام"',
              child: const _ClusterRectsScene(
                text: 'سلام',
                fontFamily: 'TestArabic',
                direction: TextDirection.rtl,
              ),
            ),
            GoldenTestScenario(
              name: 'arabic lam-alef "لا"',
              child: const _ClusterRectsScene(
                text: 'لا',
                fontFamily: 'TestArabic',
                direction: TextDirection.rtl,
              ),
            ),
            GoldenTestScenario(
              name: 'devanagari "क्ष" (conjunct)',
              child: const _ClusterRectsScene(
                text: 'क्ष',
                fontFamily: 'TestDevanagari',
                direction: TextDirection.ltr,
              ),
            ),
            GoldenTestScenario(
              name: 'zwj family emoji',
              child: const _ClusterRectsScene(
                text: '👨‍👩‍👧‍👦',
                fontFamily: 'TestEmoji',
                direction: TextDirection.ltr,
              ),
            ),
          ],
        ),
      );
    });

class _ClusterRectsScene extends StatelessWidget {
  const _ClusterRectsScene({
    required this.text,
    required this.fontFamily,
    required this.direction,
  });
  final String text;
  final String fontFamily;
  final TextDirection direction;

  @override
  Widget build(BuildContext context) {
    final shaped = ShapedText.build(
      text: text,
      style: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const ['TestLatin', 'TestEmoji'],
        fontSize: 64,
        color: const Color(0xFF111111),
      ),
      textDirection: direction,
    );
    return Directionality(
      textDirection: direction,
      child: Container(
        color: const Color(0xFFFFFFFF),
        padding: const EdgeInsets.all(16),
        child: CustomPaint(
          size: shaped.size,
          painter: _RectsOverlayPainter(shaped),
        ),
      ),
    );
  }
}

class _RectsOverlayPainter extends CustomPainter {
  _RectsOverlayPainter(this.shaped);
  final ShapedText shaped;

  @override
  void paint(Canvas canvas, Size size) {
    shaped.paint(canvas, Offset.zero);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE14B4B);
    for (final c in shaped.clusters) {
      canvas.drawRect(c.bounds, stroke);
    }
  }

  @override
  bool shouldRepaint(_RectsOverlayPainter old) => old.shaped != shaped;
}
