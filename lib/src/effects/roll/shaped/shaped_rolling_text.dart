import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../effect_query.dart';
import '../../../text/shaped_text.dart';
import '../slide_direction.dart';
import '../symbol_tape_strategy.dart';
import '../tape_shaping_context.dart';
import 'shaped_rolling_text_controller.dart';
import 'shaped_tape_frame.dart';

/// Shaped rolling text — the renderer behind
/// `RollingTextEffect` under [TextRenderMode.contextualCharacters].
///
/// Architecturally this widget is a state shell that owns the
/// [ShapedRollingTextController] for the current `oldText → newText`
/// transition (rebuilt in `didUpdateWidget`) and a couple of lifecycle
/// concerns (font-change handling, paragraph prewarming). The
/// per-frame rendering is delegated to [_RolledRow] / [RenderShapedRolledRow]:
/// a single render object that lays out and paints every cluster
/// position together. That row-level architecture is what makes the
/// [_RolledRow] painter's clip-and-pad invariants feasible — see the
/// doc on [RenderShapedRolledRow] for the rules it enforces.
class ShapedRollingText extends StatefulWidget {
  const ShapedRollingText({
    super.key,
    required this.text,
    required this.tapeStrategy,
    required this.style,
    this.tapeShapingContext = TapeShapingContext.endpointsCorrect,
    this.tapeSlideDirection = TextTapeSlideDirection.up,
    this.clipBehavior = Clip.hardEdge,
    this.padding = EdgeInsets.zero,
    this.textDirection,
    this.textAlign,
    this.textScaler,
    this.strutStyle,
    this.staggerTapes = true,
    this.staggerSoftness = 1,
    this.reverseStaggerDirection = false,
    this.tapeCurve,
    this.fixedTapeWidth,
    this.slotClipPadding = EdgeInsets.zero,
  });

  final String text;
  final SymbolTapeStrategy tapeStrategy;
  final TextStyle style;
  final TapeShapingContext tapeShapingContext;
  final TextTapeSlideDirection tapeSlideDirection;
  final Clip clipBehavior;
  final EdgeInsets padding;
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  final TextScaler? textScaler;
  final StrutStyle? strutStyle;
  final bool staggerTapes;
  final int staggerSoftness;
  final bool reverseStaggerDirection;
  final Curve? tapeCurve;
  final double? fixedTapeWidth;

  /// Per-edge ink overflow allowance for the row.
  ///
  /// * `left` extends the leftmost VISIBLE cluster's clip leftward —
  ///   gives entry swashes / italic overshoot on the row's first
  ///   letter room to render.
  /// * `right` extends the rightmost VISIBLE cluster's clip rightward
  ///   — same idea on the trailing letter.
  /// * `top` / `bottom` apply uniformly so cursive loops above the
  ///   line top / below descent stay visible on every cluster.
  ///
  /// Both horizontal extensions only fire when the active cluster is
  /// actually the first / last in its substituted paragraph; mid-
  /// paragraph clusters get a tight clip even when they happen to be
  /// the row's outermost VISIBLE slot at some progress. This prevents
  /// the doubled-letter artifact that plagued the previous slot-based
  /// design during length-mismatched transitions.
  final EdgeInsets slotClipPadding;

  @override
  State<ShapedRollingText> createState() => _ShapedRollingTextState();
}

class _ShapedRollingTextState extends State<ShapedRollingText> {
  /// The last rendered `widget.text`. Initialised to itself so the
  /// first mount settles immediately (no animation until a real text
  /// change flips through `didUpdateWidget`).
  late String _previousText = widget.text;

  /// The text direction we last built the controller against. Both
  /// the controller (for shaping) and the render object (for visual
  /// row order) must use the SAME resolved direction; otherwise an
  /// ambient-RTL app where `widget.textDirection` is null would
  /// shape paragraphs LTR while the row painted RTL — the kind of
  /// silent direction mismatch codex flagged in review.
  late TextDirection _resolvedDirection = _resolveDirection();

  late ShapedRollingTextController _controller = _buildController();

  /// Set by [_handleFontsChanged] when a platform fontsChange arrives
  /// during an in-flight roll. [build] consumes it as soon as
  /// progress is back at a settled value (0.0 or 1.0), so we don't
  /// swap controllers mid-animation and produce a one-frame
  /// fallback→target geometry flash.
  bool _pendingFontRebuild = false;

  /// Resolves the effective text direction from (in order): the
  /// widget's explicit `textDirection`, the ambient `Directionality`,
  /// or LTR as the last-resort fallback. Called from `initState`,
  /// `didChangeDependencies`, and `didUpdateWidget` so the controller
  /// and render object always agree on a single, non-null direction.
  TextDirection _resolveDirection() =>
      widget.textDirection ??
      Directionality.maybeOf(context) ??
      TextDirection.ltr;

  ShapedRollingTextController _buildController() =>
      ShapedRollingTextController(
        oldText: _previousText,
        newText: widget.text,
        tapeStrategy: widget.tapeStrategy,
        style: widget.style,
        tapeShapingContext: widget.tapeShapingContext,
        textDirection: _resolvedDirection,
        textAlign: widget.textAlign,
        textScaler: widget.textScaler,
        strutStyle: widget.strutStyle,
      );

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.systemFonts.addListener(_handleFontsChanged);
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_handleFontsChanged);
    super.dispose();
  }

  void _handleFontsChanged() {
    if (!mounted) return;
    _pendingFontRebuild = true;
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ambient `Directionality` change → the resolved direction may
    // differ. Rebuild the controller so its shaped paragraphs match
    // what the row will paint.
    final next = _resolveDirection();
    if (next != _resolvedDirection) {
      _resolvedDirection = next;
      _controller = _buildController();
      _schedulePrewarm();
    }
  }

  @override
  void didUpdateWidget(covariant ShapedRollingText old) {
    super.didUpdateWidget(old);
    final nextDirection = _resolveDirection();
    final directionChanged = nextDirection != _resolvedDirection;
    if (directionChanged) _resolvedDirection = nextDirection;

    if (old.text != widget.text) {
      _previousText = old.text;
      _controller = _buildController();
      _schedulePrewarm();
    } else if (directionChanged ||
        old.style != widget.style ||
        old.tapeStrategy != widget.tapeStrategy ||
        old.tapeShapingContext != widget.tapeShapingContext ||
        old.textAlign != widget.textAlign ||
        old.textScaler != widget.textScaler ||
        old.strutStyle != widget.strutStyle ||
        old.staggerTapes != widget.staggerTapes ||
        old.staggerSoftness != widget.staggerSoftness ||
        old.reverseStaggerDirection != widget.reverseStaggerDirection ||
        old.tapeCurve != widget.tapeCurve ||
        old.fixedTapeWidth != widget.fixedTapeWidth) {
      _controller = _buildController();
      _schedulePrewarm();
    }
  }

  /// Eagerly shapes every tape frame of the current controller in a
  /// post-frame callback so the first animated paint isn't on a cold
  /// `ShapedText.build` for any cluster's lastFrame. The render
  /// object always reads both endpoint frames (firstFrame and
  /// lastFrame) at layout time, so without this prewarm the trigger
  /// frame would pay N synchronous shaping calls and drop a frame.
  void _schedulePrewarm() {
    final target = _controller;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_controller, target)) return;
      for (int p = 0; p < target.positionCount; p++) {
        final len = target.tapeLength(position: p);
        for (int s = 0; s < len; s++) {
          target.frameAt(position: p, step: s);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = EffectQuery.maybeOf(context);
    final progress = query?.curvedValue ?? 1.0;

    if (_pendingFontRebuild && (progress == 0.0 || progress >= 1.0)) {
      _controller = _buildController();
      _pendingFontRebuild = false;
    }

    Widget result = _RolledRow(
      controller: _controller,
      progress: progress,
      tapeCurve: widget.tapeCurve,
      staggerTapes: widget.staggerTapes,
      staggerSoftness: widget.staggerSoftness,
      reverseStaggerDirection: widget.reverseStaggerDirection,
      tapeSlideDirection: widget.tapeSlideDirection,
      fixedTapeWidth: widget.fixedTapeWidth,
      slotClipPadding: widget.slotClipPadding,
      // Always pass the same resolved direction the controller was
      // built against — paint order and shape direction must agree.
      textDirection: _resolvedDirection,
    );

    if (widget.clipBehavior != Clip.none) {
      result = ClipRect(clipBehavior: widget.clipBehavior, child: result);
    }

    if (widget.padding != EdgeInsets.zero) {
      result = Padding(padding: widget.padding, child: result);
    }

    return result;
  }
}

/// Leaf widget that wires `ShapedRollingText`'s state into the row
/// render object. All real work lives in [RenderShapedRolledRow].
class _RolledRow extends LeafRenderObjectWidget {
  const _RolledRow({
    required this.controller,
    required this.progress,
    required this.tapeCurve,
    required this.staggerTapes,
    required this.staggerSoftness,
    required this.reverseStaggerDirection,
    required this.tapeSlideDirection,
    required this.fixedTapeWidth,
    required this.slotClipPadding,
    required this.textDirection,
  });

  final ShapedRollingTextController controller;
  final double progress;
  final Curve? tapeCurve;
  final bool staggerTapes;
  final int staggerSoftness;
  final bool reverseStaggerDirection;
  final TextTapeSlideDirection tapeSlideDirection;
  final double? fixedTapeWidth;
  final EdgeInsets slotClipPadding;
  final TextDirection textDirection;

  @override
  RenderShapedRolledRow createRenderObject(BuildContext context) =>
      RenderShapedRolledRow(
        controller: controller,
        progress: progress,
        tapeCurve: tapeCurve,
        staggerTapes: staggerTapes,
        staggerSoftness: staggerSoftness,
        reverseStaggerDirection: reverseStaggerDirection,
        tapeSlideDirection: tapeSlideDirection,
        fixedTapeWidth: fixedTapeWidth,
        slotClipPadding: slotClipPadding,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderShapedRolledRow renderObject,
  ) {
    renderObject
      ..controller = controller
      ..progress = progress
      ..tapeCurve = tapeCurve
      ..staggerTapes = staggerTapes
      ..staggerSoftness = staggerSoftness
      ..reverseStaggerDirection = reverseStaggerDirection
      ..tapeSlideDirection = tapeSlideDirection
      ..fixedTapeWidth = fixedTapeWidth
      ..slotClipPadding = slotClipPadding
      ..textDirection = textDirection;
  }
}

/// Per-position resolved geometry, captured during `performLayout` and
/// consumed by `paint`. Splitting the math out of `paint` lets the
/// painter run as straight-line code with no allocations and lets
/// `computeMin/MaxIntrinsicWidth` (added later if we need them) reuse
/// the same helper.
class _SlotGeometry {
  _SlotGeometry({
    required this.position,
    required this.slotW,
    required this.slotH,
    required this.slideHeight,
    required this.lineAscent,
    required this.lineDescent,
    required this.stepFractional,
    required this.tapeLength,
    required this.firstFrame,
    required this.lastFrame,
    required this.reversed,
    required this.bounceOffsetY,
  });

  final int position;
  final double slotW;
  final double slotH;

  /// Slide stride for the rolling tape's vertical motion. See
  /// [TapeFrame.slideHeight]. Used by the painter to compute step A
  /// and step B's vertical offsets so they don't overlap mid-roll.
  /// SEPARATE from [slotH] (the slot's box-height contribution to the
  /// row's intrinsic size, leading-free) — keeps the row compact for
  /// parents that anchor by box, while the painter has enough range
  /// to fully clear A on the upward slide before B arrives.
  final double slideHeight;

  final double lineAscent;
  final double lineDescent;
  final double stepFractional;
  final int tapeLength;

  /// Both endpoint frames are kept on the entry so the painter can
  /// look up both stepA and stepB without re-going through the
  /// controller; the controller call hits the same cache anyway, this
  /// is just to skip the indirection at paint time.
  final TapeFrame firstFrame;
  final TapeFrame? lastFrame;

  /// Slide direction for THIS slot (resolved from the row's
  /// `tapeSlideDirection`, which can per-position-vary under
  /// `alternating` and `random`). True iff the cluster slides
  /// downward (current exits bottom, next enters top).
  final bool reversed;

  /// Already sign-corrected for [reversed] — apply directly as a
  /// vertical translate. The painter never has to think about which
  /// way the curve should overshoot, only how much.
  final double bounceOffsetY;
}

/// The row-level renderer for `ShapedRollingText`.
///
/// **Why a render object instead of `Row of CustomPaint`s.** The old
/// design stamped one `CustomPaint` per cluster and let the parent
/// `Row` lay them out side-by-side. Each painter independently
/// decided its own clip extents from per-slot pad inputs, and the
/// widget level decided which slot got the row's outer pad based on
/// `position == newLen - 1`. That positional approximation was wrong
/// at the start of length-mismatched transitions: the slot at
/// `newLen - 1` was actually painting an interior cluster of `oldText`
/// (e.g. the `h` in `Marhaba` for `Marhaba → Hola`), and the right
/// pad extended the painter clip 24 px past `h` into the next
/// cluster's footprint — exposing the leading edge of `a` and
/// producing the user-reported "Marhaaba" / "Konnichiwwa" doubled-
/// letter artifact.
///
/// **Invariants this design enforces.**
///
/// 1. **Per-cluster clip never reaches into a neighbour cluster.**
///    Each slot's painter clip stops at the cluster's advance edge
///    unless the cluster IS the first / last cluster in its
///    paragraph (read from `TapeFrame.isFirst/LastClusterInParagraph`).
///    That predicate makes the previous bug structurally impossible.
///
/// 2. **Outer pads attach to the row's actual outermost slot per
///    progress.** `firstVisible` / `lastVisible` are computed from
///    `slotW > 0` after layout — so the row's left pad and right pad
///    follow the cluster that's truly outermost RIGHT NOW, not a
///    static `position == 0` / `position == newLen - 1`.
///
/// 3. **All clusters share a baseline.** The row's height is
///    `topPad + maxAscent + maxDescent + bottomPad`, and every
///    paragraph is drawn so its line baseline coincides with
///    `topPad + maxAscent`. Mixed-metric content (Latin + emoji)
///    aligns naturally without falling back to per-slot center
///    cross-axis alignment.
///
/// 4. **Layout `Size` is exactly what `paint` will fill.** The same
///    per-position arithmetic produces both the size and the per-
///    cluster paint geometry; the painter cannot drift outside the
///    box, and outer parents (e.g. `ShaderMask`) get a stable
///    intrinsic to size against.
class RenderShapedRolledRow extends RenderBox {
  RenderShapedRolledRow({
    required ShapedRollingTextController controller,
    required double progress,
    required Curve? tapeCurve,
    required bool staggerTapes,
    required int staggerSoftness,
    required bool reverseStaggerDirection,
    required TextTapeSlideDirection tapeSlideDirection,
    required double? fixedTapeWidth,
    required EdgeInsets slotClipPadding,
    required TextDirection textDirection,
  })  : _controller = controller,
        _progress = progress,
        _tapeCurve = tapeCurve,
        _staggerTapes = staggerTapes,
        _staggerSoftness = staggerSoftness,
        _reverseStaggerDirection = reverseStaggerDirection,
        _tapeSlideDirection = tapeSlideDirection,
        _fixedTapeWidth = fixedTapeWidth,
        _slotClipPadding = slotClipPadding,
        _textDirection = textDirection;

  // Setters all funnel through `_invalidate` so identity-only changes
  // skip the relayout cost when the actual configuration matches.

  ShapedRollingTextController _controller;
  ShapedRollingTextController get controller => _controller;
  set controller(ShapedRollingTextController value) {
    if (identical(_controller, value)) return;
    _controller = value;
    _invalidate();
  }

  double _progress;
  double get progress => _progress;
  set progress(double value) {
    if (_progress == value) return;
    _progress = value;
    _invalidate();
  }

  Curve? _tapeCurve;
  Curve? get tapeCurve => _tapeCurve;
  set tapeCurve(Curve? value) {
    if (_tapeCurve == value) return;
    _tapeCurve = value;
    _invalidate();
  }

  bool _staggerTapes;
  bool get staggerTapes => _staggerTapes;
  set staggerTapes(bool value) {
    if (_staggerTapes == value) return;
    _staggerTapes = value;
    _invalidate();
  }

  int _staggerSoftness;
  int get staggerSoftness => _staggerSoftness;
  set staggerSoftness(int value) {
    if (_staggerSoftness == value) return;
    _staggerSoftness = value;
    _invalidate();
  }

  bool _reverseStaggerDirection;
  bool get reverseStaggerDirection => _reverseStaggerDirection;
  set reverseStaggerDirection(bool value) {
    if (_reverseStaggerDirection == value) return;
    _reverseStaggerDirection = value;
    _invalidate();
  }

  TextTapeSlideDirection _tapeSlideDirection;
  TextTapeSlideDirection get tapeSlideDirection => _tapeSlideDirection;
  set tapeSlideDirection(TextTapeSlideDirection value) {
    if (_tapeSlideDirection == value) return;
    _tapeSlideDirection = value;
    _invalidate();
  }

  double? _fixedTapeWidth;
  double? get fixedTapeWidth => _fixedTapeWidth;
  set fixedTapeWidth(double? value) {
    if (_fixedTapeWidth == value) return;
    _fixedTapeWidth = value;
    _invalidate();
  }

  EdgeInsets _slotClipPadding;
  EdgeInsets get slotClipPadding => _slotClipPadding;
  set slotClipPadding(EdgeInsets value) {
    if (_slotClipPadding == value) return;
    _slotClipPadding = value;
    _invalidate();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    _invalidate();
  }

  void _invalidate() {
    markNeedsLayout();
  }

  // Per-position geometry resolved during layout. `_slots` only
  // contains slots that are actually visible at the current
  // progress (slotW > 0 && slotH > 0); collapsed slots are skipped
  // outright. `_rowBaselineY`, `_leftEdgePad`, `_rightEdgePad` are
  // the row-level outputs the painter consumes alongside `_slots`.
  final List<_SlotGeometry> _slots = <_SlotGeometry>[];
  double _rowBaselineY = 0;
  double _leftEdgePad = 0;
  double _rightEdgePad = 0;

  @override
  bool get sizedByParent => false;

  /// Pure layout pass: walks the controller's positions, resolves
  /// per-slot geometry, and reports back the row's intrinsic size,
  /// baseline, outer pads, and slot list. Shared by [performLayout]
  /// (which writes the result into the render object's fields and
  /// sets [size]) and the dry-layout/dry-baseline overrides (which
  /// need the same metrics without mutating state).
  ///
  /// `targetSlots` is a sink the caller owns: pass the long-lived
  /// `_slots` list from `performLayout` to populate it in place;
  /// pass a fresh list from dry-layout to avoid clobbering paint
  /// state.
  ({
    Size intrinsicSize,
    double rowBaselineY,
    double leftEdgePad,
    double rightEdgePad,
  }) _resolveRowGeometry(List<_SlotGeometry> targetSlots) {
    targetSlots.clear();
    final positionCount = _controller.positionCount;

    double maxAscent = 0;
    double maxDescent = 0;
    double sumSlotW = 0;

    for (int position = 0; position < positionCount; position++) {
      final length = _controller.tapeLength(position: position);
      if (length == 0) {
        // No tape at all for this position (degenerate); skip.
        continue;
      }

      // Stagger.
      double scaled;
      if (!_staggerTapes) {
        scaled = _progress;
      } else {
        double charPercent = (position + _staggerSoftness) /
            (positionCount + _staggerSoftness);
        if (_reverseStaggerDirection) charPercent = 1 - charPercent;
        scaled = (_progress / charPercent).clamp(0.0, 1.0);
      }
      final double curvedRaw =
          _tapeCurve != null ? _tapeCurve!.transform(scaled) : scaled;
      final double curved = curvedRaw.clamp(0.0, 1.0).toDouble();

      // Endpoint frames. We always need lastFrame at curved > 0 for
      // the slide-from-below paint, but `_schedulePrewarm` makes the
      // shaping cost zero in steady state — so at curved == 0 we
      // skip lastFrame to defer its first build to when it's
      // actually needed (the trigger frame).
      final TapeFrame firstFrame =
          _controller.frameAt(position: position, step: 0);
      final TapeFrame? lastFrame = curved > 0.0
          ? _controller.frameAt(position: position, step: length - 1)
          : null;

      final double firstW = firstFrame.clusterBounds.width;
      final double lastW = lastFrame?.clusterBounds.width ?? firstW;
      final double slotW = _fixedTapeWidth ??
          (curved <= 0 ? firstW : firstW * (1 - curved) + lastW * curved);

      // Per-slot ascent / descent — same lerp as widths so a slot
      // that's collapsing (lastFrame is sentinel ⇒ zero metrics) sees
      // its vertical contribution shrink in step with its width.
      //
      // The painter places each cluster's baseline on the row's
      // baseline using `frame.lineAscent` (= `paragraph.alphabetic
      // Baseline`). Layout, however, must size the row to fit the
      // cluster's actual ink extent — which can exceed
      // `paragraph.height` when `StrutStyle.forceStrutHeight` clamps
      // the line box smaller than the font's natural metrics. Most
      // visible on Arabic (`ر` tail descends past the strut-clamped
      // line bottom) but applies to any tall-descender / overhang
      // font under a `leading=0` strut. Derive the slot's box ascent
      // from the cluster's actual top relative to the alphabetic
      // baseline (`lineAscent - clusterBounds.top`), and box descent
      // from the cluster's actual bottom (`clusterBounds.bottom -
      // lineAscent`). For typical Latin where `clusterBounds.top` is
      // ~0 and `clusterBounds.bottom` is ~paragraph.height, this
      // collapses to the previous lineAscent/lineDescent formula.
      final double firstA = firstFrame.lineAscent;
      final double lastA = lastFrame?.lineAscent ?? firstA;
      final double lineAscent =
          curved <= 0 ? firstA : firstA * (1 - curved) + lastA * curved;
      final double firstSlotAsc =
          firstFrame.lineAscent - firstFrame.clusterBounds.top;
      final double lastSlotAsc = lastFrame == null
          ? firstSlotAsc
          : lastFrame.lineAscent - lastFrame.clusterBounds.top;
      final double firstSlotDsc =
          firstFrame.clusterBounds.bottom - firstFrame.lineAscent;
      final double lastSlotDsc = lastFrame == null
          ? firstSlotDsc
          : lastFrame.clusterBounds.bottom - lastFrame.lineAscent;
      final double slotAscent = curved <= 0
          ? firstSlotAsc
          : firstSlotAsc * (1 - curved) + lastSlotAsc * curved;
      final double slotDescent = curved <= 0
          ? firstSlotDsc
          : firstSlotDsc * (1 - curved) + lastSlotDsc * curved;
      final double lineDescent = slotDescent;
      final double slotH = slotAscent + slotDescent;

      // Slide stride for the painter — leading-inclusive paragraph
      // height (`paragraph.height`, baked in by the controller as
      // `TapeFrame.slideHeight`). Use the larger of first/last so a
      // collapsing slot still has enough stride to slide its first
      // frame fully off-screen on the way out. Independent of layout
      // metrics — see `_SlotGeometry.slideHeight`.
      final double firstS = firstFrame.slideHeight;
      final double lastS = lastFrame?.slideHeight ?? firstS;
      final double slideHeight =
          firstS > lastS ? firstS : lastS;

      if (slotW <= 0 || slotH <= 0) continue;

      // Slide direction (per-position for `alternating` / `random`).
      final bool reversed = switch (_tapeSlideDirection) {
        TextTapeSlideDirection.up => false,
        TextTapeSlideDirection.down => true,
        TextTapeSlideDirection.alternating => position.isOdd,
        TextTapeSlideDirection.random =>
          Random('$position'.hashCode).nextBool(),
      };

      // Bounce: only the OVERSHOT portion of the curve, in slide-
      // height units, sign-corrected per slide direction. Up-sliding
      // slots bounce DOWN at the start (anticipation) and UP past
      // their target at the end (follow-through). Down-sliding mirror.
      // Scales with the SLIDE stride (not the box-height stride) so
      // bounce magnitude tracks the leading-driven slide distance.
      final double rawOvershoot = (curvedRaw - curved) * slideHeight;
      final double bounceOffsetY = reversed ? rawOvershoot : -rawOvershoot;

      // Step indexing inside the tape.
      final double stepFractional =
          length <= 1 ? 0.0 : curved * (length - 1);

      targetSlots.add(_SlotGeometry(
        position: position,
        slotW: slotW,
        slotH: slotH,
        slideHeight: slideHeight,
        lineAscent: lineAscent,
        lineDescent: lineDescent,
        stepFractional: stepFractional,
        tapeLength: length,
        firstFrame: firstFrame,
        lastFrame: lastFrame,
        reversed: reversed,
        bounceOffsetY: bounceOffsetY,
      ));

      sumSlotW += slotW;
      // `slotAscent` / `slotDescent` are the cluster's actual ink
      // extent (see comment above). The row's box uses these so
      // tall-descender fonts under a clamping strut (Arabic 'ر')
      // don't get their tails clipped at the slot's vertical edge.
      if (slotAscent > maxAscent) maxAscent = slotAscent;
      if (slotDescent > maxDescent) maxDescent = slotDescent;
    }

    final double topPad = _slotClipPadding.top;
    final double bottomPad = _slotClipPadding.bottom;
    final double leftPad = _slotClipPadding.left;
    final double rightPad = _slotClipPadding.right;

    // Outer pads are reserved unconditionally when there is content,
    // so the row's total width changes only via slot-width lerps
    // (smooth) — never as a discrete jump when the visually rightmost
    // slot shifts during a length-mismatched roll. Whether the
    // painter ACTUALLY draws into the reserved pad band is gated per
    // frame by `clusterIsParagraphLeft/RightEdge` + `isFullyGrown`.
    if (targetSlots.isEmpty) {
      return (
        intrinsicSize: Size(0, topPad + bottomPad),
        rowBaselineY: topPad,
        leftEdgePad: 0,
        rightEdgePad: 0,
      );
    }

    final double width = leftPad + sumSlotW + rightPad;
    final double height = topPad + maxAscent + maxDescent + bottomPad;
    return (
      intrinsicSize: Size(width, height),
      rowBaselineY: topPad + maxAscent,
      leftEdgePad: leftPad,
      rightEdgePad: rightPad,
    );
  }

  @override
  void performLayout() {
    final geometry = _resolveRowGeometry(_slots);
    _rowBaselineY = geometry.rowBaselineY;
    _leftEdgePad = geometry.leftEdgePad;
    _rightEdgePad = geometry.rightEdgePad;
    size = constraints.constrain(geometry.intrinsicSize);
  }

  /// Dry-layout sizing. Some parents (intrinsic-sizing widgets,
  /// `IntrinsicHeight`, animated builders that probe their child's
  /// size) call this without a paint pass; without an override the
  /// default falls back through `performLayout`, which mutates
  /// `_slots` mid-build and asserts. We resolve geometry into a
  /// throwaway list so the live render state is left alone.
  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final dryList = <_SlotGeometry>[];
    final geometry = _resolveRowGeometry(dryList);
    return constraints.constrain(geometry.intrinsicSize);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  /// Row baseline — see [computeDistanceToActualBaseline].
  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final dryList = <_SlotGeometry>[];
    final geometry = _resolveRowGeometry(dryList);
    return geometry.rowBaselineY;
  }

  /// Expose the row's typographic baseline so a parent
  /// `Row(crossAxisAlignment: baseline, textBaseline: alphabetic)`
  /// can align the rolled widget with sibling `Text` widgets. Without
  /// this override, `RenderBox` returns `null` and parents fall back
  /// to centering by box height — which throws the rolled baseline
  /// off the sibling baseline by half the `slotClipPadding.vertical`
  /// (the rolled widget is taller because the pad reserves room for
  /// ascenders/descenders that overshoot the line metrics).
  ///
  /// Currently both `TextBaseline.alphabetic` and `ideographic` map to
  /// the same y — the line metrics we get from `ShapedText` only
  /// expose `ascent` (alphabetic baseline = `topPad + maxAscent`).
  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return _rowBaselineY;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_slots.isEmpty) return;

    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    // RTL: walk the logical `_slots` list IN REVERSE so slot 0 (the
    // logically-first cluster) ends up painted at the row's right
    // edge. We do NOT mirror the canvas — the per-slot paragraphs are
    // already shaped against their textDirection, so each glyph is
    // drawn correctly oriented; we just reverse the row's slot order
    // to match RTL visual layout.
    final bool ltr = _textDirection == TextDirection.ltr;
    final int last = _slots.length - 1;

    double cursorX = _leftEdgePad;
    for (int j = 0; j < _slots.length; j++) {
      final int i = ltr ? j : (last - j);
      final slot = _slots[i];
      final bool isVisualLeftmost = j == 0;
      final bool isVisualRightmost = j == last;
      _paintSlot(
        canvas: canvas,
        slot: slot,
        rowX: cursorX,
        isVisualLeftmost: isVisualLeftmost,
        isVisualRightmost: isVisualRightmost,
      );
      cursorX += slot.slotW;
    }

    canvas.restore();
  }

  void _paintSlot({
    required Canvas canvas,
    required _SlotGeometry slot,
    required double rowX,
    required bool isVisualLeftmost,
    required bool isVisualRightmost,
  }) {
    if (slot.tapeLength == 0) return;
    final int stepA =
        slot.stepFractional.floor().clamp(0, slot.tapeLength - 1);
    final int stepB = (stepA + 1).clamp(0, slot.tapeLength - 1);
    final double t = slot.stepFractional - stepA;

    final double yFractionA = slot.reversed ? t : -t;
    final double yFractionB = slot.reversed ? t - 1 : 1 - t;

    canvas.save();
    if (slot.bounceOffsetY != 0) {
      canvas.translate(0, slot.bounceOffsetY);
    }

    _paintFrame(
      canvas: canvas,
      slot: slot,
      rowX: rowX,
      step: stepA,
      yFraction: yFractionA,
      isVisualLeftmost: isVisualLeftmost,
      isVisualRightmost: isVisualRightmost,
    );
    // Skip frame B at endpoints — at t==0 stepB's vertical offset is
    // exactly outside the slot, so it'd be clipped anyway. Skipping
    // also avoids the cold-path shape on the trigger frame for tapes
    // we haven't visited yet.
    if (stepA != stepB && t > 0) {
      _paintFrame(
        canvas: canvas,
        slot: slot,
        rowX: rowX,
        step: stepB,
        yFraction: yFractionB,
        isVisualLeftmost: isVisualLeftmost,
        isVisualRightmost: isVisualRightmost,
      );
    }

    canvas.restore();
  }

  void _paintFrame({
    required Canvas canvas,
    required _SlotGeometry slot,
    required double rowX,
    required int step,
    required double yFraction,
    required bool isVisualLeftmost,
    required bool isVisualRightmost,
  }) {
    final frame = _controller.frameAt(position: slot.position, step: step);

    // Sentinel guard: a frame whose cluster lookup failed (the tape
    // char at this step is zero-width — typical for the still-empty
    // endpoint of a growing-in slot) carries `clusterBounds = Rect
    // .zero`. Without this guard the painter would draw the
    // substituted paragraph at `Offset(rowX, …)` with no
    // cluster-specific shift, painting the paragraph's FIRST cluster
    // in this slot's window — i.e. `Namaste`'s 'N' in the slot meant
    // for the growing-in 'e' at the row's tail (the floating
    // horizontal-stroke artifact at the start of "Ni Hao →
    // Namaste"). Better: paint nothing.
    if (frame.clusterBounds.isEmpty) return;

    final shaped = ShapedText.build(
      text: frame.substitutedText,
      style: _controller.style,
      textDirection: _controller.textDirection,
      textAlign: _controller.textAlign,
      textScaler: _controller.textScaler,
      strutStyle: _controller.strutStyle,
    );
    final rect = frame.clusterBounds;

    // Per-frame outer-pad gating (leading/trailing flourishes on the
    // row's visual end caps). Three conditions must all hold:
    //
    //  1. This slot is the row's visually outermost slot on that
    //     side (leftmost / rightmost in `_slots` after RTL flip).
    //  2. The frame's animating cluster sits at the matching VISUAL
    //     edge of its substituted paragraph
    //     (`clusterIsParagraphLeft/RightEdge`, computed from
    //     `visualIndex` so this works for mixed-direction paragraphs
    //     too). `false` ⇒ extending the clip would expose a
    //     neighbour cluster's ink (the "Marhaaba" / "Konnichiwwa"
    //     doubled-letter bug).
    //  3. The slot's lerped width MATCHES this frame's cluster
    //     width within sub-pixel tolerance — symmetric, not the
    //     one-sided `slotW >= rect.width` test, so a slot whose
    //     lerped width has GROWN PAST the frame's natural width
    //     (= the frame is shrinking out) doesn't get falsely
    //     classified as "settled at this frame". At progress=0 the
    //     active frame is firstFrame and `slotW == firstW`; at
    //     progress=1 the active frame is lastFrame and `slotW ==
    //     lastW`. Mid-roll, slotW is between the two, neither
    //     matches, and pads stay tight.
    final bool slotMatchesFrame =
        (slot.slotW - rect.width).abs() <= 0.5;
    final double outerLeftPad = (isVisualLeftmost &&
            frame.clusterIsParagraphLeftEdge &&
            slotMatchesFrame)
        ? _leftEdgePad
        : 0;
    final double outerRightPad = (isVisualRightmost &&
            frame.clusterIsParagraphRightEdge &&
            slotMatchesFrame)
        ? _rightEdgePad
        : 0;

    // Slot's clip box. Hard clip at the cluster's advance edges —
    // we only extend past the slot's visual edge when the slot is
    // at the row's outermost edge AND `outerLeftPad` /
    // `outerRightPad` are non-zero (then the row reserves a tail
    // zone for cursive flourishes / leading marks that overshoot
    // the cluster's advance box).
    //
    // We deliberately do NOT bleed each slot's clip into its
    // neighbour's region. An earlier attempt did so with an alpha-
    // gradient + `BlendMode.plus` saveLayer to smooth cursive
    // joins, but that approach reads each slot's substituted
    // paragraph at the seam — and during mid-roll different slots
    // are at different tape steps under stagger. The seam zone
    // ends up exposing the OLD-context character from one slot's
    // paragraph and the NEW-context character from the next, then
    // additive-blends them — visible as ghost duplicate strokes
    // through every glyph on the example app's `EmojiLine`. With
    // a hard clip, cursive flourishes stay whole because the
    // cluster's `bounds.right - bounds.left` (the layout-bounds
    // width Skia reports for `graphemeClusterLayoutBounds`) covers
    // the whole flourish in `slotW` already; the row sizing in
    // `_resolveRowGeometry` derives ascent/descent from those
    // bounds too, so vertical overshoot is absorbed by `topPad` /
    // `bottomPad` rather than seam bleed.
    final double leftExt = isVisualLeftmost ? outerLeftPad : 0;
    final double rightExt = isVisualRightmost ? outerRightPad : 0;

    // Vertical: anchor the cluster's baseline on the row's shared
    // baseline, then add the slide offset. Multiply yFraction by the
    // SLIDE stride (`slot.slideHeight`, leading-inclusive paragraph
    // height) — NOT `slot.slotH` (the leading-free box stride).
    // `slideHeight` is what `symbolDistanceMultiplier` controls (it
    // injects strut leading); using it here makes the slide cleanly
    // clear the slot before steps A and B can stack vertically
    // mid-roll (the "ghost emoji" bug on dense content).
    //
    // `frame.lineAscent` is `paragraph.alphabeticBaseline` (the
    // baseline distance from the paragraph's top), which is exactly
    // where `canvas.drawParagraph` puts the cluster's baseline. So
    // `offsetY = baselineYInRow - frame.lineAscent` lines the
    // cluster's baseline up with `baselineYInRow`. We do NOT subtract
    // `rect.top`: cluster bounds report the cluster's ink extent
    // within the paragraph (which can be negative for fonts whose
    // ascent overshoots the line box, e.g. GloriaHallelujah at
    // -8.7), but ink-extent is irrelevant for baseline anchoring —
    // the alphabetic baseline is what matters, and that's already
    // factored in.
    final double baselineYInRow = _rowBaselineY + slot.slideHeight * yFraction;
    final double offsetY = baselineYInRow - frame.lineAscent;
    final double offsetX = rowX - rect.left;

    final Rect slotBounds = Rect.fromLTRB(
      rowX - leftExt,
      0,
      rowX + slot.slotW + rightExt,
      size.height,
    );

    canvas.save();
    canvas.clipRect(slotBounds);
    canvas.drawParagraph(shaped.paragraph, Offset(offsetX, offsetY));
    canvas.restore();
  }
}
