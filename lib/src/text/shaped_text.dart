import 'dart:collection';
import 'dart:ui' as ui;

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';

import 'shaped_cluster.dart';

// ---------------------------------------------------------------------------
// Module-level LRU cache
// ---------------------------------------------------------------------------

bool _systemFontsListenerInstalled = false;

void _ensureSystemFontsListener() {
  if (_systemFontsListenerInstalled) return;
  PaintingBinding.instance.systemFonts.addListener(_onSystemFontsChanged);
  _systemFontsListenerInstalled = true;
}

void _onSystemFontsChanged() {
  // Platform reported a fontsChange (new font installed, or a loader
  // like GoogleFonts finishing an async download). Every cached entry
  // was shaped against the previous font set, so paragraphs rendered
  // with a fallback before the target font resolved would persist as
  // stale — the "Hello not rendering in cursive font" bug. Clearing
  // here lets subsequent builds re-shape against the current font set.
  ShapedText.clearCache();
}

class _ShapedTextKey {
  const _ShapedTextKey({
    required this.text,
    required this.style,
    required this.textDirection,
    required this.textAlign,
    required this.textScaler,
    required this.strutStyle,
    required this.textHeightBehavior,
    required this.locale,
    required this.maxWidth,
  });

  final String text;
  final TextStyle style;
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  final TextScaler textScaler; // default TextScaler.noScaling if null
  final StrutStyle? strutStyle;
  final ui.TextHeightBehavior? textHeightBehavior;
  final Locale? locale;
  final double? maxWidth;

  @override
  bool operator ==(Object other) =>
      other is _ShapedTextKey &&
      other.text == text &&
      other.style == style &&
      other.textDirection == textDirection &&
      other.textAlign == textAlign &&
      other.textScaler == textScaler &&
      other.strutStyle == strutStyle &&
      other.textHeightBehavior == textHeightBehavior &&
      other.locale == locale &&
      other.maxWidth == maxWidth;

  @override
  int get hashCode => Object.hash(
        text,
        style,
        textDirection,
        textAlign,
        textScaler,
        strutStyle,
        textHeightBehavior,
        locale,
        maxWidth,
      );
}

/// Max entries in the module-level LRU cache.
///
/// Budget reasoning: 128 entries × ~2KB native Skia memory per paragraph
/// ≈ 256KB. A typical app may shape ~30 unique paragraphs per screen;
/// 128 gives ~4× headroom before eviction kicks in. Adjust if profiling
/// shows this is too low for a scrolling-list use case.
const int _kMaxCacheEntries = 128;
int _debugUncachedBuildCount = 0;

final LinkedHashMap<_ShapedTextKey, ShapedText> _cache =
    LinkedHashMap<_ShapedTextKey, ShapedText>();

/// Sub-pixel tolerance for line-top comparisons.
/// Skia may return a line top like `31.999...` instead of `32.0`; this
/// fuzz keeps the comparison robust without false-sharing lines.
const double _kLineTopFuzz = 0.5;

/// A shaped, laid-out paragraph exposing per-grapheme-cluster rects.
///
/// `ShapedText` is the primitive for per-character text effects. It runs
/// exactly one `ui.Paragraph.layout()` per instance, then uses
/// [ui.Paragraph.getGlyphInfoAt] to enumerate clusters ligature-safely.
@immutable
class ShapedText {
  const ShapedText._({
    required this.paragraph,
    required this.size,
    required this.lines,
    required this.clusters,
  });

  /// The underlying shaped paragraph.
  ///
  /// Owned by the module-level LRU cache. May be disposed when the cache
  /// evicts this entry (after 128 distinct builds). Callers MUST NOT retain
  /// a [ShapedText] across paint frames — instead, call [ShapedText.build]
  /// each time you need it. The cache returns the same instance for
  /// identical arguments, so repeated builds with the same key are cheap.
  final ui.Paragraph paragraph;

  /// Dimensions of the laid-out paragraph.
  final Size size;

  /// Per-line metrics after layout.
  final List<ui.LineMetrics> lines;

  /// Clusters in visual order. Carries [ShapedCluster.logicalIndex] for
  /// source-string ordering and [ShapedCluster.visualIndex] for the
  /// visual position.
  final List<ShapedCluster> clusters;

  /// Paints the entire shaped paragraph at [offset] on [canvas].
  void paint(Canvas canvas, Offset offset) {
    canvas.drawParagraph(paragraph, offset);
  }

  /// Clears the module-level LRU cache and disposes all cached paragraphs.
  ///
  /// Call this when you need every subsequent [ShapedText.build] to
  /// re-shape from scratch — typically after an async font loader
  /// (e.g. `google_fonts`) has resolved, to ensure paragraphs that were
  /// shaped during the fallback window get discarded.
  ///
  /// This runs automatically when the platform fires a
  /// [PaintingBinding.systemFonts] change notification, so most apps
  /// won't need to call it manually. Use it as a manual escape hatch if
  /// your font loader doesn't participate in that mechanism.
  static void clearCache() {
    for (final entry in _cache.values) {
      entry.paragraph.dispose();
    }
    _cache.clear();
  }

  /// Test-only alias for [clearCache]; kept for backwards-compatibility
  /// with existing `setUp` callers.
  @visibleForTesting
  static void debugClearCache() => clearCache();

  /// Test-only: simulate a platform fontsChange notification. Dispatches
  /// through [PaintingBinding.handleSystemMessage] so every real
  /// `systemFonts` listener fires — module-level cache clear *and* any
  /// widget-level listeners that need to rebuild. Mirrors the path a
  /// real font loader (google_fonts etc.) hits in production.
  @visibleForTesting
  static Future<void> debugTriggerFontsChanged() {
    return PaintingBinding.instance
        .handleSystemMessage(<String, dynamic>{'type': 'fontsChange'});
  }

  /// Number of uncached builds performed since the last
  /// [debugResetBuildCount] call. Use to detect O(N) eager shaping paths
  /// in tests (e.g. a slot that rebuilds every tape frame per paint).
  @visibleForTesting
  static int get debugUncachedBuildCount => _debugUncachedBuildCount;

  /// Resets the uncached build counter. Call in test `setUp`.
  @visibleForTesting
  static void debugResetBuildCount() {
    _debugUncachedBuildCount = 0;
  }

  /// Builds a [ShapedText] for [text] with [style].
  ///
  /// Results are cached in a module-level LRU (max 128 entries). Identical
  /// arguments return the same [ShapedText] instance.
  ///
  /// [maxWidth] enables line wrapping; omit or pass [double.infinity] for
  /// single-line layout (text still wraps at explicit `\n` characters).
  factory ShapedText.build({
    required String text,
    required TextStyle style,
    TextDirection? textDirection,
    TextAlign? textAlign,
    TextScaler? textScaler,
    StrutStyle? strutStyle,
    ui.TextHeightBehavior? textHeightBehavior,
    Locale? locale,
    double? maxWidth,
  }) {
    // Subscribe lazily on first use so the cache auto-invalidates when
    // platform fonts change. Deferring to first build keeps teardown
    // simple: anyone who never shapes text never installs the listener.
    _ensureSystemFontsListener();

    final key = _ShapedTextKey(
      text: text,
      style: style,
      textDirection: textDirection,
      textAlign: textAlign,
      textScaler: textScaler ?? TextScaler.noScaling,
      strutStyle: strutStyle,
      textHeightBehavior: textHeightBehavior,
      locale: locale,
      maxWidth: maxWidth,
    );

    // LRU: LinkedHashMap preserves insertion order. Access by removing
    // and re-inserting moves the entry to the most-recent end.
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }

    // Cache miss — build the paragraph and all cluster data.
    _debugUncachedBuildCount += 1;
    final shaped = _buildUncached(
      text: text,
      style: style,
      textDirection: textDirection,
      textAlign: textAlign,
      textScaler: textScaler,
      strutStyle: strutStyle,
      textHeightBehavior: textHeightBehavior,
      locale: locale,
      maxWidth: maxWidth,
    );

    _cache[key] = shaped;
    // Evict LRU entries if we're over budget.
    while (_cache.length > _kMaxCacheEntries) {
      final firstKey = _cache.keys.first;
      final evicted = _cache.remove(firstKey);
      evicted?.paragraph.dispose();
    }
    return shaped;
  }

  static ShapedText _buildUncached({
    required String text,
    required TextStyle style,
    TextDirection? textDirection,
    TextAlign? textAlign,
    TextScaler? textScaler,
    StrutStyle? strutStyle,
    ui.TextHeightBehavior? textHeightBehavior,
    Locale? locale,
    double? maxWidth,
  }) {
    final resolvedDirection = textDirection ?? TextDirection.ltr;
    final resolvedScaler = textScaler ?? TextScaler.noScaling;

    // Build the paragraph directly via ui.ParagraphBuilder so we can access
    // the underlying ui.Paragraph (needed for getGlyphInfoAt in Task 3).
    // TextPainter does not expose paragraph as a public getter in this
    // Flutter version.
    final paragraphStyle = style.getParagraphStyle(
      textAlign: textAlign ?? TextAlign.start,
      textDirection: resolvedDirection,
      textScaler: resolvedScaler,
      textHeightBehavior: textHeightBehavior,
      locale: locale,
      strutStyle: strutStyle,
    );

    final builder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(style.getTextStyle(textScaler: resolvedScaler))
      ..addText(text)
      ..pop();

    final paragraph = builder.build();

    // Lay out the paragraph. When maxWidth is infinite (no wrapping), Skia
    // returns empty computeLineMetrics() and null getGlyphInfoAt for RTL text
    // because glyph positions fall at the right edge of an infinite canvas.
    // Mirror TextPainter's fix: first layout with the requested width, then
    // re-layout with maxIntrinsicWidth so glyph positions are finite and
    // line metrics are populated. For finite maxWidth we skip the second
    // layout pass.
    final double requestedWidth = maxWidth ?? double.infinity;
    paragraph.layout(ui.ParagraphConstraints(width: requestedWidth));
    if (requestedWidth.isInfinite && paragraph.computeLineMetrics().isEmpty) {
      // Re-layout at the intrinsic width so RTL clusters have finite bounds
      // and computeLineMetrics() returns at least one entry for non-empty text.
      final double intrinsicWidth = paragraph.maxIntrinsicWidth;
      if (intrinsicWidth.isFinite && intrinsicWidth > 0) {
        paragraph.layout(ui.ParagraphConstraints(width: intrinsicWidth));
      }
    }

    // Measure content dimensions: width is the longest line, height is total.
    // For empty strings, longestLine may be negative/infinite; clamp to 0.
    final double rawWidth = paragraph.longestLine;
    final double contentWidth =
        rawWidth.isFinite && rawWidth > 0 ? rawWidth : 0.0;
    final double contentHeight = paragraph.height;
    final size = Size(contentWidth, contentHeight);
    final lines = paragraph.computeLineMetrics();

    // Cache line tops for line-index lookup.
    // Each LineMetrics has baseline and ascent; the top of the line is
    // baseline - ascent. We use a 0.5 pixel fuzz to handle sub-pixel tops
    // returned by Skia (e.g. 0.399... instead of 0.4).
    final lineTops = <double>[
      for (final line in lines) line.baseline - line.ascent,
    ];
    int lineIndexForY(double top) {
      if (lineTops.isEmpty) return 0;
      int idx = 0;
      for (int i = 0; i < lineTops.length; i++) {
        if (top >= lineTops[i] - _kLineTopFuzz) idx = i;
      }
      return idx;
    }

    // Enumerate grapheme clusters via `text.characters` and resolve each
    // to a ShapedCluster via paragraph.getGlyphInfoAt.
    final clusters = <ShapedCluster>[];
    if (text.isNotEmpty) {
      int codeUnitStart = 0;
      int logicalIndex = 0;
      for (final cluster in text.characters) {
        final codeUnitEnd = codeUnitStart + cluster.length;
        final glyphInfo = paragraph.getGlyphInfoAt(codeUnitStart);
        if (glyphInfo != null) {
          final bounds = glyphInfo.graphemeClusterLayoutBounds;
          // Skip degenerate (zero-width) glyphs such as newline characters
          // ('\n'). Skia returns a non-null GlyphInfo for '\n' but with
          // left == right, meaning no visible glyph. Including them would
          // produce ghost clusters that corrupt visual order and lineIndex.
          if (bounds.width <= 0) {
            codeUnitStart = codeUnitEnd;
            logicalIndex++;
            continue;
          }
          clusters.add(
            ShapedCluster(
              logicalIndex: logicalIndex,
              // Visual index will be set after sorting below.
              visualIndex: logicalIndex,
              codeUnitRange: TextRange(start: codeUnitStart, end: codeUnitEnd),
              bounds: bounds,
              direction: glyphInfo.writingDirection,
              text: cluster,
              lineIndex: lineIndexForY(bounds.top),
            ),
          );
        }
        codeUnitStart = codeUnitEnd;
        logicalIndex++;
      }
    }

    // Visual order = sort by (lineIndex, bounds.left).
    // After sort, reassign visualIndex.
    clusters.sort((a, b) {
      final byLine = a.lineIndex.compareTo(b.lineIndex);
      if (byLine != 0) return byLine;
      return a.bounds.left.compareTo(b.bounds.left);
    });
    // `ShapedCluster` is immutable, so rebuild with correct visualIndex.
    final ordered = <ShapedCluster>[
      for (int i = 0; i < clusters.length; i++)
        ShapedCluster(
          logicalIndex: clusters[i].logicalIndex,
          visualIndex: i,
          codeUnitRange: clusters[i].codeUnitRange,
          bounds: clusters[i].bounds,
          direction: clusters[i].direction,
          text: clusters[i].text,
          lineIndex: clusters[i].lineIndex,
        ),
    ];

    return ShapedText._(
      paragraph: paragraph,
      size: size,
      lines: lines,
      clusters: ordered,
    );
  }
}
