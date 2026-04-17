import 'dart:math';

import 'package:flutter/material.dart';

import '../../../text/shaped_cluster.dart';
import '../../../text/shaped_text.dart';
import '../symbol_tape_strategy.dart';
import '../tape_shaping_context.dart';
import 'shaped_tape_frame.dart';

/// Zero-width space (U+200B). Used as padding when one source string has
/// fewer grapheme clusters than the other, so animating positions beyond
/// the shorter word's length roll toward an invisible character. Matches
/// the legacy controller's padding (see
/// `legacy_rolling_text_controller.dart:229`).
///
/// **Important**: this pad value MUST trigger the tape strategy's
/// `isZeroWidth` branch. Padding with `''` (empty string) silently falls
/// through the `ConsistentSymbolTapeStrategy` `length <= 2` short-circuit
/// and produces a 1-step `'t'`-only tape — the animating position renders
/// the old letter forever, producing "Createte" / "GrowGG" bugs.
const String _kZeroWidth = '​';

/// Drives per-position tape-frame shaping for [RollingTextEffect] under
/// [TextRenderMode.contextualCharacters].
///
/// Each rolling slot (character position) maintains a list of [TapeFrame]s
/// built lazily as the animation progresses. The controller owns per-slot
/// caches; the module-level [ShapedText] cache handles paragraph reuse.
class ShapedRollingTextController {
  ShapedRollingTextController({
    required this.oldText,
    required this.newText,
    required this.tapeStrategy,
    required this.style,
    this.tapeShapingContext = TapeShapingContext.endpointsCorrect,
    this.textDirection,
    this.textAlign,
    this.textScaler,
    this.strutStyle,
  });

  final String oldText;
  final String newText;
  final SymbolTapeStrategy tapeStrategy;
  final TextStyle style;
  final TapeShapingContext tapeShapingContext;
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  final TextScaler? textScaler;
  final StrutStyle? strutStyle;

  /// Grapheme-cluster count for each source string.
  late final int _oldLen = oldText.characters.length;
  late final int _newLen = newText.characters.length;

  /// Number of rolling slots (one per max-length position).
  int get positionCount => max(_oldLen, _newLen);

  /// Cached tape string per position (the tape character sequence).
  final Map<int, String> _tapePerPosition = {};

  /// Cached frames per position: `_frames[position][step]`.
  final Map<int, List<TapeFrame?>> _frames = {};

  /// Cached slot widths per position.
  final Map<int, double> _slotWidths = {};

  /// Returns the tape length (number of steps) for [position].
  int tapeLength({required int position}) {
    final tape = _tapeFor(position);
    return tape.characters.length;
  }

  /// Returns the cluster-bounds height of the tape's first frame at
  /// [position] — i.e. the OLD letter's height at that slot.
  /// Paired with [lastFrameHeight] for the per-position slot-height
  /// lerp in `_Slot.build`: height animates from first→last mirrored
  /// on the width lerp, so a slot naturally grows or shrinks to fit
  /// whichever glyph it's currently painting. No static overshoot
  /// fudge-factor; cluster bounds already carry the full glyph extent
  /// (ascent/descent including marks above/below the nominal line box).
  double firstFrameHeight({required int position}) {
    final len = tapeLength(position: position);
    if (len == 0) return 0;
    return frameAt(position: position, step: 0).clusterBounds.height;
  }

  /// Returns the cluster-bounds height of the tape's last frame at
  /// [position] — the NEW letter's (or ZWS-collapsed) height.
  double lastFrameHeight({required int position}) {
    final len = tapeLength(position: position);
    if (len == 0) return 0;
    return frameAt(position: position, step: len - 1).clusterBounds.height;
  }


  /// Returns the [TapeFrame] at ([position], [step]), building it lazily.
  TapeFrame frameAt({required int position, required int step}) {
    final list = _frames.putIfAbsent(position, () {
      final len = tapeLength(position: position);
      return List<TapeFrame?>.filled(len, null, growable: false);
    });
    final cached = list[step];
    if (cached != null) return cached;
    final built = _buildFrame(position: position, step: step);
    list[step] = built;
    return built;
  }

  /// Returns the slot's fixed width = max cluster width across all frames.
  /// Forces all frames for the position to be built (this is acceptable
  /// because slot width must be stable for the whole animation; lazy
  /// building only helps for off-screen or far-future positions).
  double slotWidth({required int position}) {
    return _slotWidths.putIfAbsent(position, () {
      final len = tapeLength(position: position);
      double maxWidth = 0;
      for (int s = 0; s < len; s++) {
        final frame = frameAt(position: position, step: s);
        if (frame.clusterBounds.width > maxWidth) {
          maxWidth = frame.clusterBounds.width;
        }
      }
      return maxWidth;
    });
  }

  String _tapeFor(int position) => _tapePerPosition.putIfAbsent(position, () {
        final oldChar = position < _oldLen
            ? oldText.characters.elementAt(position)
            : _kZeroWidth;
        final newChar = position < _newLen
            ? newText.characters.elementAt(position)
            : _kZeroWidth;
        return tapeStrategy.build(oldChar, newChar);
      });

  TapeFrame _buildFrame({required int position, required int step}) {
    final tape = _tapeFor(position);
    final tapeChar = tape.characters.elementAt(step);
    final substituted =
        _substitute(position: position, step: step, tapeChar: tapeChar);
    final shaped = ShapedText.build(
      text: substituted,
      style: style,
      textDirection: textDirection,
      textAlign: textAlign,
      textScaler: textScaler,
      strutStyle: strutStyle,
    );
    // The cluster at `position` in the substituted string is the animating
    // slot. `ShapedText.clusters` is in visual order; we need logical order.
    // Look up by logicalIndex.
    //
    // **Why the orElse returns zero-bounds (not clusters.first)**:
    // `ShapedText.build` filters out zero-width clusters at
    // `shaped_text.dart:282-286` (originally added to drop newline ghost
    // clusters). When the tape char at this step is ZWS — e.g. the final
    // step of a collapsing position (Innovate → Create, position 6) — the
    // substituted text like "Create​" has the ZWS filtered out, so the
    // cluster at logicalIndex=position is absent. The correct render for
    // "cluster was filtered because it's zero-width" is: render nothing.
    // Returning `clusters.first` here would leak the first letter of the
    // word into the slot (the "CreateC" bug).
    const zeroBoundsSentinel = ShapedCluster(
      logicalIndex: 0,
      visualIndex: 0,
      codeUnitRange: TextRange(start: 0, end: 0),
      bounds: Rect.zero,
      direction: TextDirection.ltr,
      text: '',
      lineIndex: 0,
    );
    final cluster = shaped.clusters.firstWhere(
      (c) => c.logicalIndex == position,
      orElse: () => zeroBoundsSentinel,
    );

    // Effectively-empty cluster check. `ShapedText.build` filters
    // clusters whose `bounds.width <= 0`, but some fonts emit a
    // sub-pixel non-zero width for zero-width characters (e.g.
    // Sacramento renders a ZWS as a 0.2 px-wide cluster). That
    // sneaks past the filter, makes `firstWhere` find a "real"
    // cluster, and lets `performLayout` keep the slot in `_slots`
    // (slotW > 0). The painter then expands the slot's clip with
    // `rightClipPadding` and catches ink overshoot from neighbour
    // clusters in the same substituted paragraph (e.g. `Sacramento
    // 't'`'s cross-stroke at the start of a "Ni Hao → Namaste"
    // roll). Treat anything below the 0.5 px sub-pixel threshold
    // as a sentinel so the slot collapses cleanly upstream.
    final bool isResolvedSentinel = identical(cluster, zeroBoundsSentinel);
    final bool isSubPixelEmpty = cluster.bounds.width < 0.5;
    final bool clusterFound = !isResolvedSentinel && !isSubPixelEmpty;

    // Visual-edge flags. The painter only extends slot-clip-padding
    // past the cluster's advance edge when the cluster sits at the
    // matching VISUAL edge of its substituted paragraph; otherwise
    // the extension would reach into a neighbour cluster's ink
    // (the "Marhaaba" / "Konnichiwwa" doubled-letter bug). We use
    // the cluster's `visualIndex` (post-sort by line + bounds.left
    // in [ShapedText._buildUncached]) rather than `logicalIndex` so
    // the flags work correctly even for mixed-direction paragraphs
    // where logical and visual order diverge. Sentinel-collapsed
    // slots get neither flag — there is nothing to anchor.
    final int lastVisualIndex = shaped.clusters.length - 1;
    final bool clusterIsParagraphLeftEdge =
        clusterFound && cluster.visualIndex == 0;
    final bool clusterIsParagraphRightEdge =
        clusterFound && cluster.visualIndex == lastVisualIndex;

    // Line metrics for layout + baseline. We pull from
    // `paragraph.alphabeticBaseline` (and derive descent from the
    // paragraph's full height) — NOT `lineMetrics[0].ascent`. The
    // two values DIVERGE under the merged-style configurations the
    // example app actually uses: when a Material `DefaultTextStyle`
    // contributes `style.height` (1.43 by default) AND the
    // `.roll()` extension overlays a `StrutStyle.leading`,
    // `lineMetrics.ascent` reports the line-box ascent (without
    // leading half) but the paragraph's actual painted baseline
    // sits at `paragraph.alphabeticBaseline` (with leading half).
    // Painting via `canvas.drawParagraph` puts the cluster's
    // baseline at `paragraph.alphabeticBaseline` from the
    // paragraph top — the row's reported baseline must match the
    // paint, otherwise `Row(crossAxisAlignment: baseline)` aligns
    // by the leading-free metric while the glyph paints offset by
    // the leading half (the "Create / Learn sits below 'We help
    // you'" bug). For fonts with quirky metrics (GloriaHallelujah:
    // tall ascent) or unusual style.height values the offset is
    // dramatic; for others it just happens to coincide. Pull from
    // alphabeticBaseline so both layout and paint use the same
    // anchor.
    double lineAscent = 0;
    double lineDescent = 0;
    if (shaped.lines.isNotEmpty) {
      lineAscent = shaped.paragraph.alphabeticBaseline;
      lineDescent = shaped.paragraph.height - lineAscent;
    }

    // Slide stride for the rolling tape's vertical motion. Use the
    // strut-inclusive paragraph height — this includes any leading
    // padding `StrutStyle.leading` adds (the knob
    // `symbolDistanceMultiplier` exposes). It must be larger than
    // `lineAscent + lineDescent` for `mult > 1`, otherwise step A
    // (sliding out) and step B (sliding in) overlap mid-roll because
    // the slide distance is too short to clear the slot's vertical
    // span — visible as the "ghost emoji" bug on the EmojiLine
    // example.
    final double slideHeight =
        clusterFound ? shaped.paragraph.height : 0;

    return TapeFrame(
      substitutedText: substituted,
      // Force `Rect.zero` for sentinel / sub-pixel-empty frames so
      // the painter's `frame.clusterBounds.isEmpty` guard fires and
      // `performLayout`'s `slotW <= 0` filter excludes the slot.
      clusterBounds: clusterFound ? cluster.bounds : Rect.zero,
      tapeStep: step,
      lineAscent: clusterFound ? lineAscent : 0,
      lineDescent: clusterFound ? lineDescent : 0,
      slideHeight: slideHeight,
      clusterIsParagraphLeftEdge: clusterIsParagraphLeftEdge,
      clusterIsParagraphRightEdge: clusterIsParagraphRightEdge,
    );
  }

  String _substitute({
    required int position,
    required int step,
    required String tapeChar,
  }) {
    final positionInOld = position < _oldLen;
    final positionInNew = position < _newLen;

    // Pick a context word that actually CONTAINS this position.
    // Fall back to whichever word has it when the requested context doesn't.
    bool useOld;
    switch (tapeShapingContext) {
      case TapeShapingContext.oldWord:
        useOld = positionInOld;
        break;
      case TapeShapingContext.newWord:
        useOld = !positionInNew && positionInOld;
        break;
      case TapeShapingContext.endpointsCorrect:
        // Step 0 wants old context for a correct-looking start frame.
        // If oldText doesn't have this position (or is empty), degrade to newText.
        useOld = step == 0 && positionInOld;
        break;
    }

    final context = useOld ? oldText : newText;
    final chars = context.characters;
    final buf = StringBuffer();
    for (int i = 0; i < max(_oldLen, _newLen); i++) {
      if (i == position) {
        buf.write(tapeChar);
      } else if (i < chars.length) {
        buf.write(chars.elementAt(i));
      }
    }
    return buf.toString();
  }
}
