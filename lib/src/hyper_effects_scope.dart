import 'package:flutter/widgets.dart';

import 'text_render_mode.dart';

/// An [InheritedWidget] that scopes package-wide configuration to a
/// subtree. Today it only carries [renderMode]; future additions will
/// land here as optional fields.
class HyperEffectsScope extends InheritedWidget {
  /// Creates a [HyperEffectsScope].
  const HyperEffectsScope({
    super.key,
    this.renderMode,
    required super.child,
  });

  /// The [TextRenderMode] to apply to descendant text effects.
  /// `null` means "inherit from [HyperEffects.defaultTextRenderMode] or
  /// fall back to [TextRenderMode.contextualCharacters]."
  final TextRenderMode? renderMode;

  /// Returns the nearest [HyperEffectsScope] above [context], or null.
  static HyperEffectsScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HyperEffectsScope>();

  @override
  bool updateShouldNotify(covariant HyperEffectsScope oldWidget) =>
      oldWidget.renderMode != renderMode;
}

/// Package-wide global configuration. Most users should set defaults here
/// once at app start:
///
/// ```dart
/// void main() {
///   HyperEffects.defaultTextRenderMode = TextRenderMode.contextualCharacters;
///   runApp(const MyApp());
/// }
/// ```
class HyperEffects {
  HyperEffects._();

  /// Default [TextRenderMode] used when no [HyperEffectsScope] is present
  /// and no per-effect override was provided.
  ///
  /// When null, text effects fall back to
  /// [TextRenderMode.contextualCharacters] (as of v0.4.0).
  static TextRenderMode? defaultTextRenderMode;

  /// Forces every text-effect widget and its shaped-paragraph cache to
  /// re-shape on the next frame. Use this if your font loader does not
  /// participate in Flutter's `systemFonts` notification and you need to
  /// invalidate stale fallback-shaped paragraphs after the real font is
  /// available.
  ///
  /// Most consumers never call this: loaders like `google_fonts` already
  /// fire a platform fontsChange notification and every text-effect
  /// widget listens for that signal.
  ///
  /// Implemented by dispatching a synthetic `fontsChange` platform
  /// message so that both the module-level paragraph cache AND any
  /// mounted widget that caches derived geometry (tape frames, slot
  /// widths, row heights) react in lockstep. Awaiting the returned
  /// [Future] guarantees listeners have finished running.
  static Future<void> clearShapedTextCache() =>
      PaintingBinding.instance
          .handleSystemMessage(<String, dynamic>{'type': 'fontsChange'});
}

/// Resolves the effective [TextRenderMode] for an effect.
///
/// Precedence (first non-null wins):
///
/// 1. [override] — the per-effect explicit parameter.
/// 2. [HyperEffectsScope.renderMode] — nearest ancestor scope.
/// 3. [HyperEffects.defaultTextRenderMode] — app-wide global.
/// 4. [TextRenderMode.contextualCharacters] — permanent fallback (as of v0.4.0).
TextRenderMode resolveTextRenderMode(
  BuildContext context, {
  TextRenderMode? override,
}) {
  if (override != null) return override;
  final scope = HyperEffectsScope.maybeOf(context);
  if (scope?.renderMode != null) return scope!.renderMode!;
  return HyperEffects.defaultTextRenderMode ??
      TextRenderMode.contextualCharacters;
}
