# Phase 2 — ShapedText Primitive Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `ShapedText` primitive — a single-shaped-paragraph abstraction with ligature-safe per-cluster rects — plus `ClusterPainter` + `ClusterEffect` + an LRU cache. This is the foundation that Phase 3 (`BlurRevealEffect`) and Phase 4 (new rolling render path) will sit on top of.

**Architecture:** One `TextPainter.layout()` per `ShapedText.build`, then `Paragraph.getGlyphInfoAt` per grapheme cluster for ligature-safe rect extraction (Skia auto-expands partial-range queries to the enclosing cluster). Clusters are sorted into visual order (visual-left-to-right within each line, respecting bidi). A module-level LRU cache keeps paragraphs alive for reuse; eviction calls `Paragraph.dispose()`. `ClusterPainter` draws the paragraph once for identity-effect clusters and per-cluster for non-identity effects (transform / opacity / blur / clip) using a `saveLayer` + `clipRect` + translated-draw trick.

**Tech stack:** Flutter `dart:ui` (`ui.Paragraph`, `ui.ParagraphBuilder`, `GlyphInfo`, `LineMetrics`), `dart:collection` (`LinkedHashMap` for LRU), `package:characters` (grapheme clusters), existing `alchemist` goldens for visual verification.

---

## Scope

Phase 2 only. Corresponds to "Rollout → Phase 2" of `docs/superpowers/specs/2026-04-17-shaped-text-rendering-design.md`. No public API changes, no effects wired up, no rolling migration — those are Phases 3 and 4.

**What's in Phase 2:**

- `ShapedText` + `ShapedCluster` (under `lib/src/text/`, not exported).
- `ClusterPainter` + `ClusterEffect` (under `lib/src/text/`, not exported).
- Module-level LRU cache with dispose on eviction.
- Multiline support via `maxWidth`.
- Unit and widget tests for the primitive.
- Two golden tests that visually verify ligature safety and per-cluster paint effects.

**What's NOT in Phase 2:**

- No `BlurRevealEffect` (Phase 3).
- No `TextRenderMode` enum, no `HyperEffectsScope`, no `.roll()` changes (Phase 4).
- No prewarm helper yet — users of the cache get it through normal `build()` calls; Phase 4 adds `RollingTextEffect.prewarm`.
- No public exports from `lib/hyper_effects.dart`. Tests import via `package:hyper_effects/src/text/...`.
- No fix of the four known source bugs catalogued in `docs/known-bugs.md` — those are still pinned.

## Conventions

- **TDD cycle per task**: write failing test → run, see it fail with the expected error → implement minimal code → run, see pass → commit.
- **Commits**: one per task, message format `:sparkles: <what>` for new features, `:white_check_mark: <what>` for test-only additions, `:camera_flash: <what>` for golden updates.
- **Imports**: tests import via `package:hyper_effects/src/text/shaped_text.dart` etc. (same pattern as `rolling_text_controller_test.dart`).
- **Test helpers**: `wrapInTestApp` from `test/helpers/test_app.dart`, `withTextRendering` from `test/helpers/alchemist_config.dart`, TestLatin/TestArabic/TestHebrew/TestDevanagari/TestEmoji fonts loaded via `loadTestFonts`.
- **Cache reset between tests**: `ShapedText.debugClearCache()` is added as a `@visibleForTesting` hook; tests call it in `setUp`.

## Known deviations (discovered during G1 execution)

- `TextPainter.paragraph` is not public in current Flutter. Task 2's original snippet suggested it; implementation pivoted to constructing `ui.Paragraph` via `ui.ParagraphBuilder` directly. All subsequent tasks should use the ParagraphBuilder pattern already in `lib/src/text/shaped_text.dart`.
- `import 'package:flutter/rendering.dart';` is unused in `lib/src/text/`. `flutter/painting.dart` transitively re-exports `TextRange`, `TextDirection`, `Rect`, `LineMetrics`. Do not add this import in new Task 4-11 files.
- RTL + `double.infinity` width returns empty `computeLineMetrics()` from Skia. Task 3 added a conditional re-layout at `maxIntrinsicWidth` when line metrics come back empty. Downstream tasks should not reintroduce `double.infinity` re-layout assumptions.

## File Structure

### Created

```
lib/src/text/
  shaped_text.dart           # ShapedText class + factory + module-level LRU cache + ShapedTextKey
  shaped_cluster.dart        # ShapedCluster value class
  cluster_effect.dart        # ClusterEffect value class + identity detection
  cluster_painter.dart       # ClusterPainter.paintWithClusters helper
test/unit/text/
  shaped_cluster_test.dart
  shaped_text_test.dart
  shaped_text_cache_test.dart
  cluster_effect_test.dart
test/widget/text/
  cluster_painter_test.dart
test/golden/text/
  shaped_text_cluster_rects_goldens_test.dart
  cluster_painter_effects_goldens_test.dart
```

### Modified

- `CHANGELOG.md` — add to Unreleased.

### Not touched

All existing `lib/` code. No existing test file is modified. The Phase 1 suite stays green.

---

## Task 1: `ShapedCluster` value class

**Files:**
- Create: `lib/src/text/shaped_cluster.dart`
- Create: `test/unit/text/shaped_cluster_test.dart`

`ShapedCluster` is a plain immutable data record. It carries a cluster's logical index, visual index (after bidi sort), code-unit range in the source string, visual bounds (rect), writing direction, the cluster text itself, and the line index.

- [ ] **Step 1.1: Write the failing test**

Create `test/unit/text/shaped_cluster_test.dart`:

```dart
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/text/shaped_cluster.dart';

void main() {
  group('ShapedCluster', () {
    test('stores every field exactly', () {
      const cluster = ShapedCluster(
        logicalIndex: 3,
        visualIndex: 1,
        codeUnitRange: TextRange(start: 2, end: 4),
        bounds: Rect.fromLTWH(10, 20, 30, 40),
        direction: TextDirection.rtl,
        text: 'ل',
        lineIndex: 0,
      );
      expect(cluster.logicalIndex, 3);
      expect(cluster.visualIndex, 1);
      expect(cluster.codeUnitRange, const TextRange(start: 2, end: 4));
      expect(cluster.bounds, const Rect.fromLTWH(10, 20, 30, 40));
      expect(cluster.direction, TextDirection.rtl);
      expect(cluster.text, 'ل');
      expect(cluster.lineIndex, 0);
    });

    test('equality is structural', () {
      const a = ShapedCluster(
        logicalIndex: 0,
        visualIndex: 0,
        codeUnitRange: TextRange(start: 0, end: 1),
        bounds: Rect.fromLTWH(0, 0, 10, 20),
        direction: TextDirection.ltr,
        text: 'a',
        lineIndex: 0,
      );
      const b = ShapedCluster(
        logicalIndex: 0,
        visualIndex: 0,
        codeUnitRange: TextRange(start: 0, end: 1),
        bounds: Rect.fromLTWH(0, 0, 10, 20),
        direction: TextDirection.ltr,
        text: 'a',
        lineIndex: 0,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString is informative', () {
      const cluster = ShapedCluster(
        logicalIndex: 0,
        visualIndex: 0,
        codeUnitRange: TextRange(start: 0, end: 1),
        bounds: Rect.fromLTWH(0, 0, 10, 20),
        direction: TextDirection.ltr,
        text: 'a',
        lineIndex: 0,
      );
      final s = cluster.toString();
      expect(s, contains('ShapedCluster'));
      expect(s, contains("'a'"));
      expect(s, contains('logical: 0'));
    });
  });
}
```

- [ ] **Step 1.2: Run to see it fail**

Run: `flutter test test/unit/text/shaped_cluster_test.dart --reporter expanded`
Expected: compilation error — `shaped_cluster.dart` doesn't exist.

- [ ] **Step 1.3: Implement**

Create `lib/src/text/shaped_cluster.dart`:

```dart
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

/// A single grapheme-cluster slice of a [ShapedText].
///
/// Clusters are ligature-safe: Arabic `لا`, Devanagari conjuncts, and
/// ZWJ emoji sequences each come back as one cluster with one rect.
@immutable
class ShapedCluster {
  /// The cluster's position in the source string (logical order).
  final int logicalIndex;

  /// The cluster's position in visual order within its line.
  /// For LTR text this equals [logicalIndex]; for RTL or mixed-bidi
  /// the visual order differs.
  final int visualIndex;

  /// The UTF-16 code-unit range in the source string this cluster covers.
  /// For ligatures, this range spans multiple code units.
  final TextRange codeUnitRange;

  /// The cluster's visual rect relative to the paragraph origin.
  final Rect bounds;

  /// The writing direction of the cluster.
  final TextDirection direction;

  /// The grapheme cluster text (may be multiple code units for ligatures
  /// or ZWJ emoji sequences).
  final String text;

  /// The index of the line this cluster belongs to (0-based).
  final int lineIndex;

  const ShapedCluster({
    required this.logicalIndex,
    required this.visualIndex,
    required this.codeUnitRange,
    required this.bounds,
    required this.direction,
    required this.text,
    required this.lineIndex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShapedCluster &&
          other.logicalIndex == logicalIndex &&
          other.visualIndex == visualIndex &&
          other.codeUnitRange == codeUnitRange &&
          other.bounds == bounds &&
          other.direction == direction &&
          other.text == text &&
          other.lineIndex == lineIndex;

  @override
  int get hashCode => Object.hash(
        logicalIndex,
        visualIndex,
        codeUnitRange,
        bounds,
        direction,
        text,
        lineIndex,
      );

  @override
  String toString() =>
      "ShapedCluster('$text' logical: $logicalIndex visual: $visualIndex "
      'line: $lineIndex dir: $direction bounds: $bounds)';
}
```

- [ ] **Step 1.4: Run, expect pass**

Run: `flutter test test/unit/text/shaped_cluster_test.dart --reporter expanded`
Expected: 3 tests pass.

- [ ] **Step 1.5: Commit**

```bash
git add lib/src/text/shaped_cluster.dart test/unit/text/shaped_cluster_test.dart
git commit -m ":sparkles: Add ShapedCluster value class"
```

---

## Task 2: `ShapedText.build` — single-line, no cache

Establish the core `ShapedText` class with just-enough behavior to build a paragraph and expose a `paint` method. No clusters yet, no cache yet — those come in later tasks.

**Files:**
- Create: `lib/src/text/shaped_text.dart`
- Create: `test/unit/text/shaped_text_test.dart`

- [ ] **Step 2.1: Write failing test**

Create `test/unit/text/shaped_text_test.dart`:

```dart
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../../helpers/test_font_loader.dart';

void main() {
  setUp(loadTestFonts);

  const style = TextStyle(fontFamily: 'TestLatin', fontSize: 32);

  group('ShapedText.build — single line', () {
    test('builds a paragraph for an ASCII string', () {
      final shaped = ShapedText.build(text: 'Hello', style: style);
      expect(shaped.paragraph, isA<ui.Paragraph>());
      expect(shaped.size.width, greaterThan(0));
      expect(shaped.size.height, greaterThan(0));
      expect(shaped.lines, hasLength(1));
    });

    test('empty string has zero width and one line', () {
      final shaped = ShapedText.build(text: '', style: style);
      expect(shaped.size.width, 0);
      expect(shaped.lines, hasLength(1));
    });

    test('size reflects the longest line', () {
      final short = ShapedText.build(text: 'hi', style: style);
      final longer = ShapedText.build(text: 'hello world', style: style);
      expect(longer.size.width, greaterThan(short.size.width));
    });
  });
}
```

Before this test can even compile, the helper import path needs adjusting. The test sits at `test/unit/text/` so the relative path to `test/helpers/test_font_loader.dart` is `../../helpers/test_font_loader.dart`. Confirm that path before running.

- [ ] **Step 2.2: Run, expect compile failure**

Run: `flutter test test/unit/text/shaped_text_test.dart --reporter expanded`
Expected: compile error — `shaped_text.dart` missing.

- [ ] **Step 2.3: Implement**

Create `lib/src/text/shaped_text.dart`:

```dart
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'shaped_cluster.dart';

/// A shaped, laid-out paragraph exposing per-grapheme-cluster rects.
///
/// `ShapedText` is the primitive for per-character text effects. It runs
/// exactly one `TextPainter.layout()` per instance, then uses
/// [ui.Paragraph.getGlyphInfoAt] to enumerate clusters ligature-safely.
@immutable
class ShapedText {
  ShapedText._({
    required this.paragraph,
    required this.size,
    required this.lines,
    required this.clusters,
  });

  /// The underlying shaped paragraph. Owned by this [ShapedText]; do not
  /// dispose directly — the cache does that on eviction.
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

  /// Builds a [ShapedText] for [text] with [style].
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
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection ?? TextDirection.ltr,
      textAlign: textAlign ?? TextAlign.start,
      textScaler: textScaler ?? TextScaler.noScaling,
      strutStyle: strutStyle,
      textHeightBehavior: textHeightBehavior,
      locale: locale,
    )..layout(maxWidth: maxWidth ?? double.infinity);

    final paragraph = painter.paragraph;
    if (paragraph == null) {
      throw StateError('TextPainter.paragraph was null after layout.');
    }

    final size = Size(painter.width, painter.height);
    final lines = paragraph.computeLineMetrics();

    // Clusters will be populated in Task 3. For now, leave empty so the
    // single-line build tests can pass.
    const clusters = <ShapedCluster>[];

    return ShapedText._(
      paragraph: paragraph,
      size: size,
      lines: lines,
      clusters: clusters,
    );
  }
}
```

- [ ] **Step 2.4: Run, expect pass**

Run: `flutter test test/unit/text/shaped_text_test.dart --reporter expanded`
Expected: 3 tests pass.

- [ ] **Step 2.5: Commit**

```bash
git add lib/src/text/shaped_text.dart test/unit/text/shaped_text_test.dart
git commit -m ":sparkles: ShapedText.build with paragraph + size + lines"
```

---

## Task 3: Cluster enumeration via `getGlyphInfoAt`

Populate `ShapedText.clusters` by iterating `text.characters` (grapheme clusters) and calling `paragraph.getGlyphInfoAt` for each cluster's starting code unit offset. Each returned `GlyphInfo` carries `graphemeClusterLayoutBounds` (ligature-safe rect), `graphemeClusterCodeUnitRange` (the full cluster range), and `writingDirection`. This is the Phase 2 spec's primary primitive, validated against Skia source (`ParagraphImpl.cpp::getGlyphInfoAtUTF16Offset` expands to cluster boundaries).

**Files:**
- Modify: `lib/src/text/shaped_text.dart`
- Modify: `test/unit/text/shaped_text_test.dart`

- [ ] **Step 3.1: Add failing tests**

Append to `test/unit/text/shaped_text_test.dart` inside the existing `main()` (after the current `group` block):

```dart
  group('ShapedText.build — clusters', () {
    test('Latin "abc" returns 3 clusters in logical order', () {
      final shaped = ShapedText.build(text: 'abc', style: style);
      expect(shaped.clusters, hasLength(3));
      expect(shaped.clusters[0].text, 'a');
      expect(shaped.clusters[1].text, 'b');
      expect(shaped.clusters[2].text, 'c');
      for (int i = 0; i < 3; i++) {
        expect(shaped.clusters[i].logicalIndex, i);
      }
    });

    test('clusters have non-zero bounds', () {
      final shaped = ShapedText.build(text: 'abc', style: style);
      for (final c in shaped.clusters) {
        expect(c.bounds.width, greaterThan(0));
        expect(c.bounds.height, greaterThan(0));
      }
    });

    test('clusters have LTR direction for Latin text', () {
      final shaped = ShapedText.build(text: 'abc', style: style);
      for (final c in shaped.clusters) {
        expect(c.direction, TextDirection.ltr);
      }
    });

    test('empty string returns empty clusters list', () {
      final shaped = ShapedText.build(text: '', style: style);
      expect(shaped.clusters, isEmpty);
    });

    test('Arabic lam-alef "لا" returns ONE ligature-spanning cluster', () {
      const arabicStyle =
          TextStyle(fontFamily: 'TestArabic', fontSize: 32);
      final shaped = ShapedText.build(
        text: 'لا',
        style: arabicStyle,
        textDirection: TextDirection.rtl,
      );
      expect(shaped.clusters, hasLength(2),
          reason: 'lam-alef is 2 grapheme clusters in Unicode '
              '(U+0644 U+0627); the ligature is a shaping concern, '
              'not a clustering concern. Each letter is its own cluster.');
    });

    test('ZWJ family emoji "👨‍👩‍👧‍👦" is a SINGLE cluster', () {
      const emojiStyle = TextStyle(
        fontFamilyFallback: ['TestLatin', 'TestEmoji'],
        fontSize: 32,
      );
      final shaped = ShapedText.build(
        text: '👨‍👩‍👧‍👦',
        style: emojiStyle,
      );
      expect(shaped.clusters, hasLength(1),
          reason: 'ZWJ family is ONE grapheme cluster per UAX #29');
      expect(shaped.clusters.single.text, '👨‍👩‍👧‍👦');
      expect(shaped.clusters.single.codeUnitRange.end -
          shaped.clusters.single.codeUnitRange.start,
          greaterThan(1),
          reason: 'Range spans multiple code units');
    });

    test('combining mark "é" (NFD: e + U+0301) is one cluster', () {
      final shaped = ShapedText.build(text: 'e\u0301', style: style);
      expect(shaped.clusters, hasLength(1));
      expect(shaped.clusters.single.text, 'e\u0301');
    });
  });
```

Per the research (skia ParagraphImpl.cpp): lam-alef `لا` has 2 Unicode grapheme clusters (one per base letter). The shaper CREATES a ligature glyph, but from our API's perspective there are still 2 rects — one per cluster — and the ligature glyph is shared between them (both rects point into the same rendered ligature region). That's why the test expects 2, not 1. Confirm by running and inspecting.

**However**, the ZWJ emoji case IS a single grapheme cluster per UAX #29 — the emoji spec treats the ZWJ sequence as one cluster. That's why that test expects 1.

- [ ] **Step 3.2: Run, expect failures on cluster-based tests**

Run: `flutter test test/unit/text/shaped_text_test.dart --reporter expanded`
Expected: first 3 `build — single line` tests still pass; new `clusters` tests fail because `clusters` is currently hardcoded to `[]`.

- [ ] **Step 3.3: Implement cluster enumeration**

Edit `lib/src/text/shaped_text.dart`. Replace the `factory ShapedText.build(...)` body's `const clusters = <ShapedCluster>[];` line with a real enumeration:

```dart
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
          clusters.add(
            ShapedCluster(
              logicalIndex: logicalIndex,
              // Visual index equals logical for now; Task 4 sorts to visual.
              visualIndex: logicalIndex,
              codeUnitRange:
                  TextRange(start: codeUnitStart, end: codeUnitEnd),
              bounds: glyphInfo.graphemeClusterLayoutBounds,
              direction: glyphInfo.writingDirection,
              text: cluster,
              // lineIndex is filled in Task 5 when multiline support lands.
              lineIndex: 0,
            ),
          );
        }
        codeUnitStart = codeUnitEnd;
        logicalIndex++;
      }
    }
```

Add imports at the top of the file:
- `import 'package:characters/characters.dart';` (for `String.characters` extension — the analyzer prefers an explicit import)

The `clusters` variable is no longer `const`. Remove `const` from the previous line. Return the builder with the populated list.

Make sure `pubspec.yaml` has `characters` in `dependencies:` (not just `dev_dependencies`). If it's only a transitive dep, add it explicitly now — this is the first `lib/` consumer. Check with: `grep characters pubspec.yaml`. If absent, add `characters: any` under `dependencies:`.

- [ ] **Step 3.4: Run, expect all passing**

Run: `flutter test test/unit/text/shaped_text_test.dart --reporter expanded`
Expected: all 10 tests pass.

If the lam-alef test fails with unexpected count (e.g. returns 1 instead of 2, or vice versa), adjust the test expectation to match actual Skia behavior and add a comment explaining what was observed. Do NOT silently rewrite — note the discrepancy in your report.

- [ ] **Step 3.5: Commit**

```bash
git add lib/src/text/shaped_text.dart test/unit/text/shaped_text_test.dart pubspec.yaml
git commit -m ":sparkles: Enumerate grapheme clusters via getGlyphInfoAt"
```

---

## Task 4: Visual-order cluster sort

Reorder `ShapedText.clusters` from logical into visual order: group by line, sort by `bounds.left` ascending within each line. Populate `visualIndex` to the sorted position. `logicalIndex` stays as the source-string order.

**Files:**
- Modify: `lib/src/text/shaped_text.dart`
- Modify: `test/unit/text/shaped_text_test.dart`

- [ ] **Step 4.1: Add failing test for RTL visual order**

Append to `test/unit/text/shaped_text_test.dart`:

```dart
  group('ShapedText.build — visual order', () {
    test('LTR text has visualIndex == logicalIndex', () {
      final shaped = ShapedText.build(text: 'abc', style: style);
      for (final c in shaped.clusters) {
        expect(c.visualIndex, c.logicalIndex);
      }
    });

    test('RTL Arabic text has clusters in visual (LTR pixel) order', () {
      const arabicStyle =
          TextStyle(fontFamily: 'TestArabic', fontSize: 32);
      final shaped = ShapedText.build(
        text: 'مرحبا',
        style: arabicStyle,
        textDirection: TextDirection.rtl,
      );
      // In visual order (left to right on screen), RTL text appears
      // with its LAST source character on the LEFT and its FIRST
      // source character on the RIGHT. So cluster with logicalIndex=0
      // should have the largest visualIndex.
      expect(shaped.clusters, hasLength(5));
      // Clusters are emitted in visual order by our iteration, so
      // clusters[0] is the visually leftmost.
      expect(shaped.clusters[0].bounds.left,
          lessThan(shaped.clusters[4].bounds.left));
      // And the leftmost visual cluster should be the LAST logical
      // character (for pure RTL text).
      expect(shaped.clusters[0].logicalIndex, 4);
      expect(shaped.clusters[4].logicalIndex, 0);
    });

    test('clusters are sorted by bounds.left within a line', () {
      final shaped = ShapedText.build(text: 'abc', style: style);
      for (int i = 1; i < shaped.clusters.length; i++) {
        expect(shaped.clusters[i].bounds.left,
            greaterThanOrEqualTo(shaped.clusters[i - 1].bounds.left));
      }
    });
  });
```

- [ ] **Step 4.2: Run, expect the RTL test to fail**

Run: `flutter test test/unit/text/shaped_text_test.dart --reporter expanded`
Expected: RTL-order test fails because clusters are currently in logical order regardless of direction.

- [ ] **Step 4.3: Implement visual sort**

Edit `lib/src/text/shaped_text.dart`. After the `for (final cluster in text.characters)` loop completes (i.e., after the `clusters` list is filled in logical order), add a final sort step before returning:

```dart
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
```

Change the returned `clusters` to `ordered`. Task 5 handles `lineIndex`; for now it stays `0` for every cluster (single-line) and the line tiebreaker is harmless.

- [ ] **Step 4.4: Run, expect all passing**

Run: `flutter test test/unit/text/shaped_text_test.dart --reporter expanded`
Expected: all tests from Tasks 2–4 pass (should be ~13 total).

- [ ] **Step 4.5: Commit**

```bash
git add lib/src/text/shaped_text.dart test/unit/text/shaped_text_test.dart
git commit -m ":sparkles: Sort ShapedText clusters into visual order"
```

---

## Task 5: Multiline (`maxWidth`) + `lineIndex`

When `maxWidth` is set to a finite value, the paragraph wraps. Populate each cluster's `lineIndex` correctly by inspecting its `bounds.top` against the paragraph's line metrics (via `paragraph.computeLineMetrics()` — each `LineMetrics` has `baseline` and `height`).

**Files:**
- Modify: `lib/src/text/shaped_text.dart`
- Modify: `test/unit/text/shaped_text_test.dart`

- [ ] **Step 5.1: Add failing multiline tests**

Append to `test/unit/text/shaped_text_test.dart`:

```dart
  group('ShapedText.build — multiline', () {
    test('wraps text when maxWidth is tight', () {
      // 'hello world' at fontSize 32 in TestLatin is ~180-200px; force
      // it to wrap by setting a narrow maxWidth.
      final shaped = ShapedText.build(
        text: 'hello world',
        style: style,
        maxWidth: 100,
      );
      expect(shaped.lines.length, greaterThanOrEqualTo(2),
          reason: 'narrow maxWidth must produce at least 2 lines');
    });

    test('clusters carry correct lineIndex after wrap', () {
      final shaped = ShapedText.build(
        text: 'hello world',
        style: style,
        maxWidth: 100,
      );
      final lineIndices = shaped.clusters.map((c) => c.lineIndex).toSet();
      expect(lineIndices.length, greaterThanOrEqualTo(2));
      // lineIndex values are 0-based and contiguous.
      for (int i = 0; i < shaped.lines.length; i++) {
        expect(lineIndices, contains(i));
      }
    });

    test('explicit \\n creates multiple lines even without maxWidth', () {
      final shaped = ShapedText.build(text: 'a\nb', style: style);
      expect(shaped.lines.length, 2);
      // One cluster per visible glyph; \n is not a cluster.
      expect(shaped.clusters, hasLength(2));
      expect(shaped.clusters[0].lineIndex, 0);
      expect(shaped.clusters[1].lineIndex, 1);
    });

    test('visual order groups by line first', () {
      final shaped = ShapedText.build(text: 'ab\ncd', style: style);
      // Within each line, LTR left-to-right; across lines, line 0 then 1.
      expect(shaped.clusters.map((c) => c.visualIndex),
          orderedEquals([0, 1, 2, 3]));
      expect(shaped.clusters[0].lineIndex, 0);
      expect(shaped.clusters[1].lineIndex, 0);
      expect(shaped.clusters[2].lineIndex, 1);
      expect(shaped.clusters[3].lineIndex, 1);
    });
  });
```

Note the test `explicit \\n creates multiple lines` — grapheme iteration over `'a\nb'` yields `['a', '\n', 'b']` — THREE clusters, not two. But `getGlyphInfoAt` for the `\n` offset may return null (newline isn't visually drawn). The test expects 2 clusters — verify this is accurate when you run; if Skia returns a GlyphInfo for `\n` (empty bounds), exclude empty-bounds clusters or accept 3. Adjust test to match observed behavior, document via comment.

- [ ] **Step 5.2: Run, expect failures**

Run: `flutter test test/unit/text/shaped_text_test.dart --reporter expanded`
Expected: multiline tests fail — `maxWidth` is wired through but `lineIndex` is hardcoded to 0.

- [ ] **Step 5.3: Implement lineIndex resolution**

Edit `lib/src/text/shaped_text.dart`. Replace the `lineIndex: 0,` in the cluster construction with a resolved value. Compute the line for each cluster by looking up its `bounds.top` against the paragraph's line metrics.

Just before the `for (final cluster in text.characters)` loop, compute the line baselines for quick lookup:

```dart
    // Cache line tops for line-index lookup.
    final lineTops = <double>[
      for (final line in lines) line.baseline - line.ascent,
    ];
    int _lineIndexForY(double top) {
      int idx = 0;
      for (int i = 0; i < lineTops.length; i++) {
        if (top >= lineTops[i] - 0.5) idx = i;
      }
      return idx;
    }
```

Then inside the cluster loop, when constructing the `ShapedCluster`, use:
```dart
    lineIndex: _lineIndexForY(glyphInfo.graphemeClusterLayoutBounds.top),
```

The 0.5 fuzz accounts for subpixel top values from Skia.

- [ ] **Step 5.4: Run, expect passing**

Run: `flutter test test/unit/text/shaped_text_test.dart --reporter expanded`
Expected: all tests from Tasks 2–5 pass.

If any multiline test fails, likely because `maxWidth` wasn't threaded through or the lineTops lookup misfires at the boundary. Debug by printing `lineTops` and each cluster's `bounds.top`.

- [ ] **Step 5.5: Commit**

```bash
git add lib/src/text/shaped_text.dart test/unit/text/shaped_text_test.dart
git commit -m ":sparkles: Multiline support + per-cluster lineIndex"
```

---

## Task 6: LRU cache with dispose on eviction

Add a module-level `_ShapedTextCache` (an LRU keyed on a `ShapedTextKey`) that `ShapedText.build` consults. On cache miss, run the TextPainter + extraction; on hit, return the cached instance. On eviction of the oldest entry, call `paragraph.dispose()` to free native memory.

**Files:**
- Modify: `lib/src/text/shaped_text.dart`
- Create: `test/unit/text/shaped_text_cache_test.dart`

- [ ] **Step 6.1: Write failing cache test**

Create `test/unit/text/shaped_text_cache_test.dart`:

```dart
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  const style = TextStyle(fontFamily: 'TestLatin', fontSize: 32);

  test('identical build args return the same cached ShapedText', () {
    final a = ShapedText.build(text: 'hello', style: style);
    final b = ShapedText.build(text: 'hello', style: style);
    expect(identical(a, b), isTrue);
  });

  test('different text bypasses the cache', () {
    final a = ShapedText.build(text: 'hello', style: style);
    final b = ShapedText.build(text: 'world', style: style);
    expect(identical(a, b), isFalse);
  });

  test('different style bypasses the cache', () {
    const altStyle = TextStyle(fontFamily: 'TestLatin', fontSize: 24);
    final a = ShapedText.build(text: 'hello', style: style);
    final b = ShapedText.build(text: 'hello', style: altStyle);
    expect(identical(a, b), isFalse);
  });

  test('cache honors max size — evicts least-recently-used', () {
    // With max size 128, building 130 distinct entries forces eviction
    // of the 2 oldest. Verify that the first entry is gone (identity
    // no longer holds when rebuilt).
    final first = ShapedText.build(text: 'entry_0', style: style);
    for (int i = 1; i < 130; i++) {
      ShapedText.build(text: 'entry_$i', style: style);
    }
    final firstAgain = ShapedText.build(text: 'entry_0', style: style);
    expect(identical(first, firstAgain), isFalse,
        reason: 'first entry should have been evicted');
  });

  test('debugClearCache resets the cache', () {
    final a = ShapedText.build(text: 'hello', style: style);
    ShapedText.debugClearCache();
    final b = ShapedText.build(text: 'hello', style: style);
    expect(identical(a, b), isFalse);
  });
}
```

- [ ] **Step 6.2: Run, expect failures**

Run: `flutter test test/unit/text/shaped_text_cache_test.dart --reporter expanded`
Expected: fails — `debugClearCache` doesn't exist and identity isn't preserved across builds.

- [ ] **Step 6.3: Implement cache**

At the top of `lib/src/text/shaped_text.dart`, add a key class and LRU. Insert after existing imports (add `import 'dart:collection';` and `import 'package:flutter/foundation.dart';` for `@visibleForTesting`):

```dart
class _ShapedTextKey {
  _ShapedTextKey({
    required this.text,
    required this.styleHash,
    required this.textDirection,
    required this.textAlign,
    required this.textScalerHash,
    required this.strutStyleHash,
    required this.textHeightBehavior,
    required this.locale,
    required this.maxWidth,
  });

  final String text;
  final int styleHash;
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  final int textScalerHash;
  final int strutStyleHash;
  final ui.TextHeightBehavior? textHeightBehavior;
  final Locale? locale;
  final double? maxWidth;

  @override
  bool operator ==(Object other) =>
      other is _ShapedTextKey &&
      other.text == text &&
      other.styleHash == styleHash &&
      other.textDirection == textDirection &&
      other.textAlign == textAlign &&
      other.textScalerHash == textScalerHash &&
      other.strutStyleHash == strutStyleHash &&
      other.textHeightBehavior == textHeightBehavior &&
      other.locale == locale &&
      other.maxWidth == maxWidth;

  @override
  int get hashCode => Object.hash(
        text,
        styleHash,
        textDirection,
        textAlign,
        textScalerHash,
        strutStyleHash,
        textHeightBehavior,
        locale,
        maxWidth,
      );
}

const int _kMaxCacheEntries = 128;
final LinkedHashMap<_ShapedTextKey, ShapedText> _cache =
    LinkedHashMap<_ShapedTextKey, ShapedText>();
```

Inside `ShapedText`, add:

```dart
  /// Clears the module-level cache. For test use only.
  @visibleForTesting
  static void debugClearCache() {
    for (final entry in _cache.values) {
      entry.paragraph.dispose();
    }
    _cache.clear();
  }
```

Modify `factory ShapedText.build` to consult the cache. Wrap the existing body:

```dart
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
    final key = _ShapedTextKey(
      text: text,
      styleHash: style.hashCode,
      textDirection: textDirection,
      textAlign: textAlign,
      textScalerHash: (textScaler ?? TextScaler.noScaling).hashCode,
      strutStyleHash: strutStyle?.hashCode ?? 0,
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

    // Existing build path: create painter, layout, enumerate clusters...
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
    // Move the existing factory body (painter creation, cluster
    // enumeration, visual sort) here, then return
    // ShapedText._(...).
  }
```

**IMPORTANT**: Move the previous factory body (painter creation, cluster loop, visual sort) into `_buildUncached`. Return `ShapedText._(...)` from `_buildUncached`.

- [ ] **Step 6.4: Run, expect passing**

Run: `flutter test test/unit/text/shaped_text_cache_test.dart --reporter expanded`
Also re-run: `flutter test test/unit/text/ --reporter expanded`
Expected: all pass.

- [ ] **Step 6.5: Commit**

```bash
git add lib/src/text/shaped_text.dart test/unit/text/shaped_text_cache_test.dart
git commit -m ":sparkles: LRU cache with dispose-on-evict for ShapedText"
```

---

## Task 7: `ClusterEffect` value class

A decoration describing per-cluster visual effects: transform, opacity, blur sigma, color filter, visibility. Identity detection returns true when the effect is a no-op.

**Files:**
- Create: `lib/src/text/cluster_effect.dart`
- Create: `test/unit/text/cluster_effect_test.dart`

- [ ] **Step 7.1: Write failing test**

Create `test/unit/text/cluster_effect_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/text/cluster_effect.dart';

void main() {
  group('ClusterEffect', () {
    test('identity() is the no-op default', () {
      const effect = ClusterEffect.identity;
      expect(effect.isIdentity, isTrue);
      expect(effect.opacity, 1.0);
      expect(effect.blurSigma, 0.0);
      expect(effect.transform, isNull);
      expect(effect.colorFilter, isNull);
      expect(effect.visible, isTrue);
    });

    test('non-identity when opacity < 1', () {
      const effect = ClusterEffect(opacity: 0.5);
      expect(effect.isIdentity, isFalse);
    });

    test('non-identity when blurSigma > 0', () {
      const effect = ClusterEffect(blurSigma: 5);
      expect(effect.isIdentity, isFalse);
    });

    test('non-identity when transform is not null', () {
      final effect = ClusterEffect(transform: Matrix4.identity());
      expect(effect.isIdentity, isFalse,
          reason: 'any transform object, even identity matrix, '
              'counts as non-identity because the paint path differs');
    });

    test('non-identity when visible = false', () {
      const effect = ClusterEffect(visible: false);
      expect(effect.isIdentity, isFalse);
    });

    test('equality is structural', () {
      const a = ClusterEffect(opacity: 0.5, blurSigma: 2);
      const b = ClusterEffect(opacity: 0.5, blurSigma: 2);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
```

- [ ] **Step 7.2: Run, expect compile failure**

Run: `flutter test test/unit/text/cluster_effect_test.dart --reporter expanded`
Expected: `cluster_effect.dart` doesn't exist.

- [ ] **Step 7.3: Implement**

Create `lib/src/text/cluster_effect.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// Describes a per-cluster visual effect applied by [ClusterPainter].
///
/// `ClusterEffect.identity` is the no-op default; any non-default field
/// marks the effect as non-identity and routes the cluster through the
/// `saveLayer`-based paint path.
@immutable
class ClusterEffect {
  /// No-op default. Clusters with this effect take the cheap identity
  /// paint path (one `drawParagraph` for all identity clusters).
  static const ClusterEffect identity = ClusterEffect();

  /// Matrix applied around the cluster's bounds center. `null` = no transform.
  final Matrix4? transform;

  /// 1.0 = fully visible. Clamped to [0, 1] at paint time.
  final double opacity;

  /// Gaussian blur radius in logical pixels. 0 = no blur.
  final double blurSigma;

  /// Optional color filter (tint, invert, etc.).
  final ColorFilter? colorFilter;

  /// If false, the cluster is skipped entirely.
  final bool visible;

  const ClusterEffect({
    this.transform,
    this.opacity = 1.0,
    this.blurSigma = 0.0,
    this.colorFilter,
    this.visible = true,
  });

  /// True when this effect is a no-op.
  bool get isIdentity =>
      transform == null &&
      opacity == 1.0 &&
      blurSigma == 0.0 &&
      colorFilter == null &&
      visible == true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClusterEffect &&
          other.transform == transform &&
          other.opacity == opacity &&
          other.blurSigma == blurSigma &&
          other.colorFilter == colorFilter &&
          other.visible == visible;

  @override
  int get hashCode =>
      Object.hash(transform, opacity, blurSigma, colorFilter, visible);
}
```

- [ ] **Step 7.4: Run, expect pass**

Run: `flutter test test/unit/text/cluster_effect_test.dart --reporter expanded`
Expected: 6 tests pass.

- [ ] **Step 7.5: Commit**

```bash
git add lib/src/text/cluster_effect.dart test/unit/text/cluster_effect_test.dart
git commit -m ":sparkles: ClusterEffect value class with identity detection"
```

---

## Task 8: `ClusterPainter.paintWithClusters`

Paint a `ShapedText` on a `Canvas`, applying per-cluster `ClusterEffect`s returned by a decorator callback. Identity-effect clusters batch into one `drawParagraph` (cheap); non-identity clusters use `saveLayer` + `clipRect` + translate tricks to re-draw just their region under the effect.

**Files:**
- Create: `lib/src/text/cluster_painter.dart`
- Create: `test/widget/text/cluster_painter_test.dart`

- [ ] **Step 8.1: Write a widget test exercising the painter**

Create `test/widget/text/cluster_painter_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/src/text/cluster_effect.dart';
import 'package:hyper_effects/src/text/cluster_painter.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_font_loader.dart';

class _Harness extends StatelessWidget {
  const _Harness({required this.decorator});
  final ClusterEffect Function(int visualIndex) decorator;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 50),
      painter: _HarnessPainter(decorator: decorator),
    );
  }
}

class _HarnessPainter extends CustomPainter {
  _HarnessPainter({required this.decorator});
  final ClusterEffect Function(int visualIndex) decorator;

  @override
  void paint(Canvas canvas, Size size) {
    final text = ShapedText.build(
      text: 'abc',
      style: const TextStyle(fontFamily: 'TestLatin', fontSize: 32),
    );
    ClusterPainter.paintWithClusters(
      canvas,
      text,
      Offset.zero,
      (cluster) => decorator(cluster.visualIndex),
    );
  }

  @override
  bool shouldRepaint(_HarnessPainter old) => old.decorator != decorator;
}

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  testWidgets('identity decorator paints without error', (tester) async {
    await tester.pumpWidget(
      wrapInTestApp(
        _Harness(decorator: (_) => ClusterEffect.identity),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('per-cluster opacity decorator paints without error',
      (tester) async {
    await tester.pumpWidget(
      wrapInTestApp(
        _Harness(
          decorator: (i) => ClusterEffect(opacity: i * 0.33),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('invisible cluster paints without error', (tester) async {
    await tester.pumpWidget(
      wrapInTestApp(
        _Harness(
          decorator: (i) =>
              i == 1 ? const ClusterEffect(visible: false) : ClusterEffect.identity,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('transform decorator paints without error', (tester) async {
    await tester.pumpWidget(
      wrapInTestApp(
        _Harness(
          decorator: (i) => ClusterEffect(
            transform: Matrix4.translationValues(0, i * 2.0, 0),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('blur decorator paints without error', (tester) async {
    await tester.pumpWidget(
      wrapInTestApp(
        _Harness(
          decorator: (i) => ClusterEffect(blurSigma: i * 3.0),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 8.2: Run, expect failure**

Run: `flutter test test/widget/text/cluster_painter_test.dart --reporter expanded`
Expected: `cluster_painter.dart` doesn't exist.

- [ ] **Step 8.3: Implement**

Create `lib/src/text/cluster_painter.dart`:

```dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'cluster_effect.dart';
import 'shaped_cluster.dart';
import 'shaped_text.dart';

/// Paints a [ShapedText] with per-cluster decorators.
///
/// Clusters with [ClusterEffect.identity] are batched into a single
/// `drawParagraph` call; non-identity clusters use a `saveLayer` +
/// `clipRect` + translated-draw trick to re-render just their region
/// under the effect.
class ClusterPainter {
  ClusterPainter._();

  /// Paints [text] at [offset], routing each cluster through [decorator].
  static void paintWithClusters(
    Canvas canvas,
    ShapedText text,
    Offset offset,
    ClusterEffect Function(ShapedCluster cluster) decorator,
  ) {
    // Pass 1: collect non-identity clusters. Paint identity ones as a
    // single drawParagraph.
    final nonIdentityEffects = <int, ClusterEffect>{};
    bool hasAnyIdentity = false;
    for (final c in text.clusters) {
      final e = decorator(c);
      if (e.isIdentity) {
        hasAnyIdentity = true;
      } else if (e.visible) {
        nonIdentityEffects[c.visualIndex] = e;
      }
      // Invisible non-identity effects contribute nothing.
    }

    // If no cluster has a non-identity effect and at least one is
    // identity-visible, draw the whole paragraph cheaply.
    if (nonIdentityEffects.isEmpty && hasAnyIdentity) {
      text.paint(canvas, offset);
      return;
    }

    // Mixed or all-non-identity path.
    // First, draw the identity batch by clipping OUT all non-identity
    // cluster rects and drawing the paragraph once.
    if (hasAnyIdentity) {
      canvas.save();
      final path = Path()..addRect(Rect.largest);
      for (final c in text.clusters) {
        if (nonIdentityEffects.containsKey(c.visualIndex)) {
          path.addRect(c.bounds.shift(offset));
        }
      }
      canvas.clipPath(Path.combine(PathOperation.difference,
          Path()..addRect(Rect.largest), _rectsPath(
              text.clusters
                  .where((c) => nonIdentityEffects.containsKey(c.visualIndex))
                  .map((c) => c.bounds.shift(offset)))));
      text.paint(canvas, offset);
      canvas.restore();
    }

    // Then draw each non-identity cluster in its own saveLayer.
    for (final c in text.clusters) {
      final effect = nonIdentityEffects[c.visualIndex];
      if (effect == null) continue;

      final clusterRect = c.bounds.shift(offset);
      canvas.save();
      canvas.clipRect(clusterRect);

      // Apply transform around cluster center.
      if (effect.transform != null) {
        final center = clusterRect.center;
        canvas
          ..translate(center.dx, center.dy)
          ..transform(effect.transform!.storage)
          ..translate(-center.dx, -center.dy);
      }

      // Set up the paint for opacity / blur / color filter.
      final paint = Paint();
      if (effect.opacity < 1.0) {
        paint.color =
            Color.fromRGBO(0, 0, 0, effect.opacity.clamp(0.0, 1.0));
      }
      if (effect.blurSigma > 0) {
        paint.imageFilter =
            ui.ImageFilter.blur(sigmaX: effect.blurSigma, sigmaY: effect.blurSigma);
      }
      if (effect.colorFilter != null) {
        paint.colorFilter = effect.colorFilter;
      }

      if (effect.opacity < 1.0 ||
          effect.blurSigma > 0 ||
          effect.colorFilter != null) {
        canvas.saveLayer(clusterRect, paint);
        canvas.drawParagraph(text.paragraph, offset);
        canvas.restore();
      } else {
        canvas.drawParagraph(text.paragraph, offset);
      }
      canvas.restore();
    }
  }

  static Path _rectsPath(Iterable<Rect> rects) {
    final p = Path();
    for (final r in rects) {
      p.addRect(r);
    }
    return p;
  }
}
```

Note: the identity-batch clipOut implementation above uses `Path.combine(difference, ...)` to exclude non-identity cluster rects from the paragraph paint. This is the standard "paint everywhere except these rects" trick. Verify rendering on the first golden test.

- [ ] **Step 8.4: Run widget tests**

Run: `flutter test test/widget/text/cluster_painter_test.dart --reporter expanded`
Expected: all 5 tests pass.

- [ ] **Step 8.5: Commit**

```bash
git add lib/src/text/cluster_painter.dart test/widget/text/cluster_painter_test.dart
git commit -m ":sparkles: ClusterPainter with identity batching + saveLayer per-cluster"
```

---

## Task 9: Cluster-rects golden (visual verification of ligature safety)

Visually verify that Arabic / Devanagari / ZWJ-emoji clusters come back as ligature-spanning rects. The golden draws the shaped text normally, then overlays a colored rectangle around each cluster's `bounds`. Human inspection of the generated PNG is how we trust the primitive — the rectangles must wrap actual rendered glyphs cleanly.

**Files:**
- Create: `test/golden/text/shaped_text_cluster_rects_goldens_test.dart`
- Generated: `test/golden/text/goldens/ci/shaped_text_cluster_rects_goldens.png`

- [ ] **Step 9.1: Write the golden test**

Create `test/golden/text/shaped_text_cluster_rects_goldens_test.dart`:

```dart
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
              child: _ClusterRectsScene(
                text: 'Hello',
                fontFamily: 'TestLatin',
                direction: TextDirection.ltr,
              ),
            ),
            GoldenTestScenario(
              name: 'arabic "سلام"',
              child: _ClusterRectsScene(
                text: 'سلام',
                fontFamily: 'TestArabic',
                direction: TextDirection.rtl,
              ),
            ),
            GoldenTestScenario(
              name: 'arabic lam-alef "لا"',
              child: _ClusterRectsScene(
                text: 'لا',
                fontFamily: 'TestArabic',
                direction: TextDirection.rtl,
              ),
            ),
            GoldenTestScenario(
              name: 'devanagari "क्ष" (conjunct)',
              child: _ClusterRectsScene(
                text: 'क्ष',
                fontFamily: 'TestDevanagari',
                direction: TextDirection.ltr,
              ),
            ),
            GoldenTestScenario(
              name: 'zwj family emoji',
              child: _ClusterRectsScene(
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
```

- [ ] **Step 9.2: Generate baseline**

Run:
```
CI=true flutter test --update-goldens test/golden/text/shaped_text_cluster_rects_goldens_test.dart
```
Expected: golden PNG written under `test/golden/text/goldens/ci/`.

- [ ] **Step 9.3: Verify comparison passes**

Run: `CI=true flutter test test/golden/text/shaped_text_cluster_rects_goldens_test.dart`
Expected: pass.

**Visually inspect the generated PNG** — each scenario should show:
- Latin "Hello": 5 red rectangles, one per letter, wrapping each glyph tightly.
- Arabic "سلام": 4 rectangles, positioned RIGHT-to-LEFT visually, each wrapping one Arabic letter as rendered in context.
- Arabic "لا": 2 rectangles — if they overlap on the same ligature glyph, that's the expected "shared ligature" behavior per Skia research.
- Devanagari "क्ष": up to 3 rectangles (one per cluster), possibly overlapping on the single conjunct glyph.
- ZWJ family: ONE red rectangle wrapping the full family emoji.

Report observed behavior in the commit message if it diverges meaningfully from the expected description.

- [ ] **Step 9.4: Commit**

```bash
git add test/golden/text/shaped_text_cluster_rects_goldens_test.dart \
        test/golden/text/goldens/ci/shaped_text_cluster_rects_goldens.png
git commit -m ":camera_flash: ShapedText cluster-rects golden (ligature safety)"
```

---

## Task 10: Cluster-painter effects golden (visual verification of blur/opacity/transform)

Visually verify that `ClusterPainter.paintWithClusters` correctly applies per-cluster effects. Simulates what `BlurRevealEffect` will do in Phase 3 without shipping the effect itself.

**Files:**
- Create: `test/golden/text/cluster_painter_effects_goldens_test.dart`
- Generated: `test/golden/text/goldens/ci/cluster_painter_effects_goldens.png`

- [ ] **Step 10.1: Write the golden test**

Create `test/golden/text/cluster_painter_effects_goldens_test.dart`:

```dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:hyper_effects/src/text/cluster_effect.dart';
import 'package:hyper_effects/src/text/cluster_painter.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../../helpers/alchemist_config.dart';

void main() => withTextRendering(() {
      goldenTest(
        'cluster_painter_effects',
        fileName: 'cluster_painter_effects_goldens',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 500),
          children: [
            GoldenTestScenario(
              name: 'identity (baseline)',
              child: _EffectsScene(effect: (_, __) => ClusterEffect.identity),
            ),
            GoldenTestScenario(
              name: 'per-cluster opacity ramp',
              child: _EffectsScene(
                effect: (i, total) =>
                    ClusterEffect(opacity: (i + 1) / total),
              ),
            ),
            GoldenTestScenario(
              name: 'per-cluster blur ramp',
              child: _EffectsScene(
                effect: (i, total) =>
                    ClusterEffect(blurSigma: (total - i - 1) * 2.0),
              ),
            ),
            GoldenTestScenario(
              name: 'per-cluster y-translate',
              child: _EffectsScene(
                effect: (i, total) => ClusterEffect(
                  transform: Matrix4.translationValues(0, i * 4.0, 0),
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'mixed — first half blurred, second half identity',
              child: _EffectsScene(
                effect: (i, total) => i < total ~/ 2
                    ? const ClusterEffect(blurSigma: 4)
                    : ClusterEffect.identity,
              ),
            ),
          ],
        ),
      );
    });

class _EffectsScene extends StatelessWidget {
  const _EffectsScene({required this.effect});
  final ClusterEffect Function(int visualIndex, int total) effect;

  @override
  Widget build(BuildContext context) {
    final shaped = ShapedText.build(
      text: 'Hello',
      style: const TextStyle(
        fontFamily: 'TestLatin',
        fontSize: 64,
        color: Color(0xFF111111),
      ),
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFFFFFFFF),
        padding: const EdgeInsets.all(16),
        child: CustomPaint(
          size: shaped.size,
          painter: _EffectsPainter(
            shaped: shaped,
            effect: effect,
          ),
        ),
      ),
    );
  }
}

class _EffectsPainter extends CustomPainter {
  _EffectsPainter({required this.shaped, required this.effect});
  final ShapedText shaped;
  final ClusterEffect Function(int visualIndex, int total) effect;

  @override
  void paint(Canvas canvas, Size size) {
    ClusterPainter.paintWithClusters(
      canvas,
      shaped,
      Offset.zero,
      (c) => effect(c.visualIndex, shaped.clusters.length),
    );
  }

  @override
  bool shouldRepaint(_EffectsPainter old) => old.shaped != shaped;
}
```

- [ ] **Step 10.2: Generate baseline**

Run:
```
CI=true flutter test --update-goldens test/golden/text/cluster_painter_effects_goldens_test.dart
```

- [ ] **Step 10.3: Verify**

Run: `CI=true flutter test test/golden/text/cluster_painter_effects_goldens_test.dart`

**Visually inspect**:
- identity scenario: plain "Hello".
- opacity ramp: first letter nearly invisible, last fully opaque, gradient between.
- blur ramp: first letter very blurred, last letter sharp.
- y-translate: letters staircase downward by 4px each.
- mixed: first 2-3 letters blurred, rest sharp.

- [ ] **Step 10.4: Commit**

```bash
git add test/golden/text/cluster_painter_effects_goldens_test.dart \
        test/golden/text/goldens/ci/cluster_painter_effects_goldens.png
git commit -m ":camera_flash: ClusterPainter effects golden (opacity/blur/transform)"
```

---

## Task 11: CHANGELOG + full-suite verification

Verify all Phase 2 work integrates cleanly, update CHANGELOG, and confirm no Phase 1 regressions.

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 11.1: Run the full suite**

Run: `CI=true flutter test --reporter expanded`
Expected: all pass. Count should be approximately:
- Phase 1: 84 tests
- Phase 2 unit: ShapedCluster 3 + ShapedText 13 + Cache 5 + ClusterEffect 6 = 27
- Phase 2 widget: ClusterPainter 5
- Phase 2 golden: 2
Total: ~118

- [ ] **Step 11.2: Run analyzer**

Run: `flutter analyze lib test`
Expected: no new warnings or errors in Phase 2 files. Pre-existing `lib/` deprecations (from Phase 1 review) may remain.

- [ ] **Step 11.3: Update CHANGELOG**

Read `CHANGELOG.md`. Under the existing `## Unreleased` section, add new bullets before the existing Phase 1 entries:

```markdown
- Added `ShapedText` primitive (`lib/src/text/shaped_text.dart`) — one-paragraph, ligature-safe per-cluster rect enumeration via `Paragraph.getGlyphInfoAt`. Module-level LRU cache with `paragraph.dispose()` on eviction. Not exported yet; will power `BlurRevealEffect` (Phase 3) and the new rolling render path (Phase 4).
- Added `ShapedCluster`, `ClusterEffect`, and `ClusterPainter` (also under `lib/src/text/`). `ClusterPainter.paintWithClusters` batches identity clusters into a single `drawParagraph` and applies per-cluster effects (transform / opacity / blur / color filter / visibility) via `saveLayer`.
- Added 2 new goldens verifying ligature-safety (`shaped_text_cluster_rects_goldens.png`) and per-cluster effect correctness (`cluster_painter_effects_goldens.png`).
```

- [ ] **Step 11.4: Commit**

```bash
git add CHANGELOG.md
git commit -m ":memo: CHANGELOG: Phase 2 ShapedText primitive"
```

- [ ] **Step 11.5: Save baseline run log**

Run: `CI=true flutter test --reporter expanded 2>&1 | tee /tmp/phase2-baseline-run.log | tail -10`
Record the final pass count in your Phase 2 completion report.

---

## Self-review

Spec coverage check against `docs/superpowers/specs/2026-04-17-shaped-text-rendering-design.md` Section "The primitive: ShapedText" and Section "Rendering helper: ClusterPainter + ClusterEffect":

- ShapedText factory with text/style/textDirection/textAlign/textScaler/strutStyle/textHeightBehavior/locale/maxWidth: **Task 2**.
- paragraph / size / lines / clusters: **Task 2 / 3 / 5 / 4**.
- paint(Canvas, Offset): **Task 2**.
- Cluster ligature safety via getGlyphInfoAt: **Task 3**.
- Visual order with logicalIndex preserved: **Task 4**.
- Multiline with lineIndex: **Task 5**.
- LRU cache keyed on (text, style-hash, direction, textScaler, maxWidth, ...) bounded to 128, dispose on evict: **Task 6**.
- ClusterEffect with transform / opacity / blurSigma / colorFilter / visible: **Task 7**.
- ClusterPainter.paintWithClusters with identity batching: **Task 8**.
- Golden verification: **Tasks 9–10**.
- CHANGELOG: **Task 11**.

Omitted from Phase 2 per spec scope:
- `ShapedText.prewarm` static — YAGNI for Phase 2; cache populates on `build()`. Phase 4 will add `RollingTextEffect.prewarm` when there's a consumer.
- `boxHeightStyle` / `boxWidthStyle` params from the spec — `getGlyphInfoAt` (now the primary primitive per the spec's Section 1 update) ignores these. Rolling will derive slot height from `lineMetrics` in Phase 4 if needed.

All other Phase 2 spec items covered.

Placeholder scan: no TBD/TODO markers, no "similar to Task N" back-references, all code blocks complete, all commands have expected output.

Type consistency: `ShapedText.clusters` returns `List<ShapedCluster>` across all tasks; `ClusterEffect.isIdentity` bool getter used consistently; `ClusterPainter.paintWithClusters` signature stable across task definitions.
