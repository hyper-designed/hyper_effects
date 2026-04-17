# Phase 5 — Default Flip + Demo Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flip the default `TextRenderMode` fallback from `independentCharacters` to `contextualCharacters`, deprecate the legacy mode, update the example app to showcase the new default, and publish a migration doc. Legacy path stays fully functional behind the explicit mode + scope.

**Architecture:** One-line change in `resolveTextRenderMode` flips the fallback. `@Deprecated` annotation on `TextRenderMode.independentCharacters` surfaces IDE warnings. Phase 1 widget/golden tests that relied on the legacy default are updated to pass `renderMode: TextRenderMode.independentCharacters` explicitly, preserving their regression-tracking role under the legacy path. Storyboard updated with a side-by-side comparison demo and defaults to the new contextual mode.

**Tech stack:** No new dependencies. Existing `HyperEffectsScope`, `resolveTextRenderMode`, alchemist goldens, storyboard infrastructure.

---

## Scope

Phase 5 only. Corresponds to "Rollout → Phase 5" of `docs/superpowers/specs/2026-04-17-shaped-text-rendering-design.md`. Target version: v0.4.0.

**What's in Phase 5:**

- Flip fallback in `resolveTextRenderMode` to `contextualCharacters`.
- `@Deprecated` annotation on `TextRenderMode.independentCharacters`.
- Phase 1 legacy tests/goldens updated to pass `renderMode: independentCharacters` explicitly (their intent — pin the legacy path's behavior — is preserved).
- Storyboard update: default mode is `contextualCharacters`; add a side-by-side comparison demo (same Arabic text, legacy vs shaped); add Hebrew + Devanagari demos.
- `docs/migration/v0.3-to-v0.4.md` migration doc.
- CHANGELOG bump with breaking-change notice.

**What's NOT in Phase 5:**

- No legacy code removal (Phase 6).
- No fix for the 4 known source bugs in `docs/known-bugs.md` (they apply to both paths).
- No API additions or removals.
- No perf optimization of the shaped path (covered in Phase 4 review notes; deferred to post-release tuning).
- No README rewrite (could be a follow-up polish commit).

## Conventions

- **TDD cycle per task**: change → run tests → observe failure or regeneration needed → fix/regen → commit.
- **`git add <path>`** with specific paths; never `-A`.
- **Phase 1 goldens**: updated in-place to match the legacy path's output when called with explicit `renderMode: independentCharacters`. If the rendering hasn't changed (same code path, just explicit param), goldens shouldn't need regenerating — verify first.
- **Phase 4 goldens**: already use `renderMode: TextRenderMode.contextualCharacters` explicitly in every scene. Unaffected by the default flip.
- **Commit messages**: `:warning:` for breaking changes, `:memo:` for docs, `:sparkles:` for demo additions, `:wrench:` for refactors.

## File Structure

### Created

```
docs/migration/v0.3-to-v0.4.md
```

### Modified

- `lib/src/hyper_effects_scope.dart` — flip fallback in `resolveTextRenderMode`.
- `lib/src/text_render_mode.dart` — `@Deprecated` on `independentCharacters`.
- `test/unit/hyper_effects_scope_test.dart` — update the "fallback when nothing set" test to expect contextual.
- `test/widget/roll/rolling_text_widget_test.dart` — pass `renderMode: independentCharacters` explicitly in scenes that rely on legacy tree shape.
- `test/widget/roll/rolling_text_configuration_test.dart` — same.
- `test/widget/roll/rolling_text_rtl_current_behavior_test.dart` — same (these explicitly pin the broken RTL behavior; must stay on legacy).
- `test/golden/roll/rolling_*_goldens_test.dart` — pass `renderMode: independentCharacters` in scenes. Regenerate only the goldens whose output meaningfully changes (expect none if the explicit mode path matches the previous default path).
- `example/lib/stories/text_animation.dart` — default `_mode` flipped to contextual; add side-by-side comparison demo + Hebrew/Devanagari phrases.
- `CHANGELOG.md` — Unreleased bullets.

### Not touched

- `lib/src/effects/roll/legacy/` (still compiled, reachable via explicit mode or scope).
- `lib/src/effects/roll/shaped/` (unchanged).
- `docs/known-bugs.md` (bugs still pinned; status unchanged).

---

## Task 1: Flip the default fallback

**Files:**
- Modify: `lib/src/hyper_effects_scope.dart`
- Modify: `test/unit/hyper_effects_scope_test.dart`

- [ ] **Step 1.1: Update the test**

Read `test/unit/hyper_effects_scope_test.dart`. Find the test named `'4. fallback when nothing set'`. Update its expectation from `independentCharacters` to `contextualCharacters`:

```dart
testWidgets('4. fallback when nothing set', (tester) async {
  TextRenderMode? resolved;
  await tester.pumpWidget(
    wrapInTestApp(
      Builder(builder: (context) {
        resolved = resolveTextRenderMode(context);
        return const SizedBox();
      }),
    ),
  );
  expect(resolved, TextRenderMode.contextualCharacters);
});
```

Rename the test to something clearer while you're there:

```dart
testWidgets('4. fallback is contextualCharacters (v0.4.0 default flip)', ...
```

- [ ] **Step 1.2: Run, expect failure**

Run: `flutter test test/unit/hyper_effects_scope_test.dart --reporter expanded`
Expected: the renamed test fails because `resolveTextRenderMode` still falls back to `independentCharacters`.

- [ ] **Step 1.3: Flip the fallback**

Read `lib/src/hyper_effects_scope.dart`. Find the `resolveTextRenderMode` function body's last line:

```dart
return HyperEffects.defaultTextRenderMode ??
    TextRenderMode.independentCharacters;
```

Change to:

```dart
return HyperEffects.defaultTextRenderMode ??
    TextRenderMode.contextualCharacters;
```

Update the function's dartdoc accordingly. The Step 4 comment should now say `TextRenderMode.contextualCharacters`:

```dart
/// 4. [TextRenderMode.contextualCharacters] — permanent fallback (as of v0.4.0).
```

Also update the class-level dartdoc on `TextRenderMode` at `lib/src/text_render_mode.dart` so point 4 reflects the new fallback.

- [ ] **Step 1.4: Run, expect pass**

Run: `flutter test test/unit/hyper_effects_scope_test.dart --reporter expanded`
Expected: all 7 tests pass.

- [ ] **Step 1.5: Commit**

```bash
git add lib/src/hyper_effects_scope.dart \
        lib/src/text_render_mode.dart \
        test/unit/hyper_effects_scope_test.dart
git commit -m ":warning: Flip TextRenderMode fallback to contextualCharacters"
```

---

## Task 2: Deprecate `TextRenderMode.independentCharacters`

**Files:**
- Modify: `lib/src/text_render_mode.dart`

- [ ] **Step 2.1: Add the deprecation**

Read `lib/src/text_render_mode.dart`. Find the `independentCharacters` variant. Add a `@Deprecated` annotation:

```dart
/// Each character is shaped in isolation.
///
/// Does **not** support Arabic, Hebrew, Devanagari, Thai, or any other
/// script requiring contextual shaping.
///
/// Deprecated: as of v0.4.0, the default is [contextualCharacters] which
/// supports all scripts. This variant is retained for backward
/// compatibility and will be removed in v0.5.0.
@Deprecated(
    'Use TextRenderMode.contextualCharacters. Will be removed in v0.5.0.')
independentCharacters,
```

Keep the `,` at the end; Dart enum variants still use comma separators even with annotations.

- [ ] **Step 2.2: Run analyzer**

Run: `flutter analyze lib 2>&1 | grep -i "deprecat\|independentCharacters"`

Expected: the analyzer reports `deprecated_member_use_from_same_package` for every remaining use of `TextRenderMode.independentCharacters` in `lib/`. Grep for these:

```bash
grep -rn "independentCharacters" lib test example | head -30
```

Expected call sites in `lib/`:
- `resolveTextRenderMode` doc comment (fine to reference in docs — but the identifier reference will still lint).
- The `switch` in `RollingTextEffect.apply` — this reference is necessary and must be kept. Wrap the switch in `// ignore_for_file: deprecated_member_use_from_same_package` at the top of `rolling_text_effect.dart`, OR use `// ignore: deprecated_member_use_from_same_package` on each specific line.
- Same pattern anywhere else a legacy branch is needed.

Choose the per-line `// ignore:` pattern — it's more specific and shows reviewers exactly where the legacy identifier is referenced.

Add the `// ignore:` comments where needed so `flutter analyze lib` produces no new warnings.

- [ ] **Step 2.3: Run analyzer again**

Run: `flutter analyze lib test 2>&1 | grep -v deprecated_member_use_from_same_package | grep -v "deprecated_member_use " | head`

(The `deprecated_member_use_from_same_package` filter drops suppressed warnings from lib/; `deprecated_member_use ` with trailing space drops the pre-existing shake_effect/transform_effect issues.)

Expected: zero lines of output, meaning no new lint issues were introduced by the deprecation.

For `test/` — the tests explicitly reference `independentCharacters` to pin legacy behavior. Dart's `@Deprecated` fires in `test/` the same as `lib/`. Add `// ignore_for_file: deprecated_member_use` at the top of every test file that references `independentCharacters` (that's: `test/unit/hyper_effects_scope_test.dart`, `test/unit/text_render_mode_test.dart`, and any Phase 1 test updated in Task 3).

- [ ] **Step 2.4: Run full suite**

Run: `CI=true flutter test --reporter expanded 2>&1 | tail -5`
Expected: 165 tests pass (count may tick up if you added a deprecation-marker test; see Step 2.5).

- [ ] **Step 2.5: Commit**

```bash
git add lib/src/text_render_mode.dart \
        lib/src/effects/roll/rolling_text_effect.dart \
        test/unit/hyper_effects_scope_test.dart \
        test/unit/text_render_mode_test.dart
git commit -m ":warning: Deprecate TextRenderMode.independentCharacters"
```

---

## Task 3: Pin Phase 1 legacy tests to explicit `independentCharacters`

Phase 1 widget tests and goldens were written when `.roll()` defaulted to the legacy path. After Phase 5, they default to shaped. To preserve their intent — pin the LEGACY path's observable behavior (including the known bugs) — they need explicit `renderMode: TextRenderMode.independentCharacters`.

**Files:**
- Modify: `test/widget/roll/rolling_text_widget_test.dart`
- Modify: `test/widget/roll/rolling_text_configuration_test.dart`
- Modify: `test/widget/roll/rolling_text_rtl_current_behavior_test.dart`
- Modify: `test/widget/roll/rolling_text_multiline_assertion_test.dart` (if it uses `.roll()` without explicit mode)
- Modify: `test/golden/roll/*_goldens_test.dart` (5-7 files)
- Modify: `test/integration/package_smoke_test.dart`

- [ ] **Step 3.1: Find all `.roll()` call sites without explicit `renderMode`**

Run:
```bash
grep -rn "\\.roll(" test/widget/roll test/golden/roll test/integration 2>&1 | grep -v "renderMode:" | head -40
```

Expected: each `.roll(` call site that doesn't already have `renderMode:`.

- [ ] **Step 3.2: Add explicit `renderMode` to each call site**

For each `.roll()` call in test code that was written in Phase 1 (i.e., pre-Phase-4), add `renderMode: TextRenderMode.independentCharacters,` as a parameter. If the call is `.roll()`, change to `.roll(renderMode: TextRenderMode.independentCharacters)`. If the call has other params, add `renderMode:` as the first or last param (Dart named-param order doesn't matter syntactically).

Example:
```dart
// Before:
const Text('Hello').roll().animate(trigger: 0),

// After:
// ignore: deprecated_member_use
const Text('Hello').roll(
  renderMode: TextRenderMode.independentCharacters,
).animate(trigger: 0),
```

Note: the `// ignore:` comment has to go on the line IMMEDIATELY before the `TextRenderMode.independentCharacters` reference, or `ignore_for_file` at the top of the whole file. File-level is cleaner for Phase 1 tests that have many references.

For the golden test files, add `// ignore_for_file: deprecated_member_use` at the very top.

- [ ] **Step 3.3: Run Phase 1 widget + integration tests**

Run:
```bash
flutter test test/widget/roll/ test/integration/ --reporter expanded 2>&1 | tail -10
```

Expected: all tests pass. The legacy path renders identically to what Phase 1 pinned.

- [ ] **Step 3.4: Regenerate Phase 1 goldens only if needed**

Run: `CI=true flutter test test/golden/roll/ --reporter expanded 2>&1 | tail -10`

Expected: all pass with no diff. The legacy path hasn't changed; the goldens should match byte-for-byte.

If any golden fails: the `--update-goldens` command regenerates and you commit the new PNG. But this shouldn't happen — if it does, investigate before blindly regenerating. The only way a legacy golden changes is if we accidentally broke the legacy path.

- [ ] **Step 3.5: Commit**

```bash
git add test/widget/roll/ test/integration/package_smoke_test.dart test/golden/roll/
git commit -m ":wrench: Pin Phase 1 legacy tests to explicit renderMode"
```

---

## Task 4: Migration doc

**Files:**
- Create: `docs/migration/v0.3-to-v0.4.md`

- [ ] **Step 4.1: Write the migration doc**

Create `docs/migration/v0.3-to-v0.4.md`:

```markdown
# Migrating from v0.3 to v0.4

v0.4 flips the default text-rendering path of `RollingTextEffect` (and any
future per-character text effect) from `TextRenderMode.independentCharacters`
(legacy, each character shaped in isolation) to
`TextRenderMode.contextualCharacters` (shaped as a single paragraph with
per-cluster animation).

**The short version:** if you only use `RollingTextEffect` with Latin text,
nothing changes visually. If you use Arabic, Hebrew, Devanagari, or any other
script requiring contextual shaping, your text now renders correctly with
cursive joining / conjuncts / proper bidi order.

## Breaking changes

### The default render path changed

Before v0.4:

```dart
Text('Hello').roll().animate(trigger: value);
// → legacy path (independent characters)
```

After v0.4:

```dart
Text('Hello').roll().animate(trigger: value);
// → shaped path (contextual characters)
```

### What this means for Latin text

Visually identical at steady state. The shaped path may produce sub-pixel
differences in character widths when the tape contains characters with
different contextual forms — but for plain Latin strings with the default
`ConsistentSymbolTapeStrategy(0)`, output is pixel-stable.

### What this means for RTL / complex scripts

Arabic, Hebrew, Devanagari, Thai — these used to render as disconnected
isolated glyphs. Now they render correctly with proper shaping. This is a
visual change from broken → correct.

### What this means for custom `CharacterTapeBuilder` users

If you inject characters from a different script than the surrounding word
(e.g. emoji inside Latin text), the shaped path substitutes them into the
full-word context. The intermediate frames may look odd. Legacy behavior:
each character was shaped in isolation, so script-mix was naturally handled.

To preserve legacy behavior:

```dart
// ignore: deprecated_member_use
Text('Hello').roll(
  renderMode: TextRenderMode.independentCharacters,
  tapeStrategy: ConsistentSymbolTapeStrategy(
    5,
    characterTapeBuilders: {MyEmojiTapeBuilder()},
  ),
);
```

## Deprecations

`TextRenderMode.independentCharacters` is deprecated. It still works, but the
analyzer now warns on every use. It will be removed in v0.5.0.

## Opting out globally

If your app can't absorb the visual change right now, pin every rolling text
to the legacy path globally:

```dart
void main() {
  // ignore: deprecated_member_use
  HyperEffects.defaultTextRenderMode = TextRenderMode.independentCharacters;
  runApp(const MyApp());
}
```

Or in a subtree:

```dart
// ignore: deprecated_member_use
HyperEffectsScope(
  renderMode: TextRenderMode.independentCharacters,
  child: MyLegacyScreen(),
)
```

Or per-call:

```dart
// ignore: deprecated_member_use
Text('Hello').roll(renderMode: TextRenderMode.independentCharacters);
```

## Opting in explicitly (if you were already)

If your v0.3 code already passed `renderMode: TextRenderMode.contextualCharacters`
to opt in early, that call continues to work unchanged. You can now drop the
explicit parameter since it matches the default:

```dart
// Before (v0.3 with early opt-in):
Text('Hello').roll(renderMode: TextRenderMode.contextualCharacters);

// After (v0.4, redundant but still valid):
Text('Hello').roll();
```

## New APIs introduced in v0.3 (for context)

If you missed them during the v0.3 minor releases, v0.4 carries them forward:

- `TextRenderMode` enum + `HyperEffectsScope` + `HyperEffects.defaultTextRenderMode`.
- `TapeShapingContext` enum (`oldWord`, `newWord`, `endpointsCorrect`) on
  `.roll()`.
- `RollingTextEffect.prewarm(...)` static to pre-populate the shaped-text cache.
- `BlurRevealEffect` + `Text.blurReveal()` extension (always uses the shaped
  path regardless of the flag).

## Known limitations in v0.4

- Custom `CharacterTapeBuilder` + cross-script tape characters can produce
  awkward intermediate frames under the shaped path. If this affects you,
  stay on legacy for that specific effect via the per-call `renderMode`.
- The shaped path's painter draws the full substituted paragraph per slot
  (clipped to slot width). Benchmarks may show marginally higher frame cost
  vs. legacy on long strings (>20 characters). Tracked for v0.5 tuning.

## Removing in v0.5

In v0.5.0:

- `TextRenderMode.independentCharacters` will be removed.
- `TextRenderMode` may be removed entirely (all rendering becomes contextual).
- `lib/src/effects/roll/legacy/` will be deleted.

If your code still references `independentCharacters` after v0.4, plan to
either migrate to the shaped path (recommended) or pin your dependency to
`^0.4.x` before v0.5 ships.
```

- [ ] **Step 4.2: Commit**

```bash
git add docs/migration/v0.3-to-v0.4.md
git commit -m ":memo: Migration guide: v0.3 → v0.4 default render-path flip"
```

---

## Task 5: Storyboard refresh — default contextual + side-by-side demo

Bring the example app up to speed. Default mode becomes contextual; add a side-by-side comparison that dramatizes the difference; add Hebrew and Devanagari demos.

**Files:**
- Modify: `example/lib/stories/text_animation.dart`

- [ ] **Step 5.1: Flip the default mode in the story state**

Read `example/lib/stories/text_animation.dart`. Find the line:

```dart
TextRenderMode _mode = TextRenderMode.independentCharacters;
```

Change to:

```dart
TextRenderMode _mode = TextRenderMode.contextualCharacters;
```

If the segmented button's labels say "Independent (legacy)" and "Contextual (shaped)", update the legacy label to reflect deprecation:

```dart
const [
  // ignore: deprecated_member_use
  ButtonSegment(
    value: TextRenderMode.independentCharacters,
    label: Text('Legacy — deprecated'),
  ),
  ButtonSegment(
    value: TextRenderMode.contextualCharacters,
    label: Text('Shaped (default)'),
  ),
]
```

- [ ] **Step 5.2: Add a side-by-side comparison demo**

Add a new top-level demo in the story's body that renders the same Arabic string twice — once forced to legacy, once forced to shaped — side by side, so the difference is unambiguous.

Insert above the existing `ArabicRollingDemo` or wherever makes visual sense:

```dart
// ... other existing demos

// Side-by-side comparison: legacy vs shaped.
const _CompareLabel(text: 'Same string, two render paths'),
const SizedBox(height: 12),
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _ComparePane(
      label: 'LEGACY',
      // ignore: deprecated_member_use
      mode: TextRenderMode.independentCharacters,
    ),
    const SizedBox(width: 48),
    _ComparePane(
      label: 'SHAPED',
      mode: TextRenderMode.contextualCharacters,
    ),
  ],
),
const SizedBox(height: 48),
```

And add the `_CompareLabel` / `_ComparePane` widgets at the bottom of the file:

```dart
class _CompareLabel extends StatelessWidget {
  const _CompareLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
}

class _ComparePane extends StatefulWidget {
  const _ComparePane({required this.label, required this.mode});
  final String label;
  final TextRenderMode mode;

  @override
  State<_ComparePane> createState() => _ComparePaneState();
}

class _ComparePaneState extends State<_ComparePane> {
  static const _phrases = <String>['مرحبا', 'شكرا', 'سلام', 'أهلا'];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(widget.label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            )),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            _phrases[_index],
            style: GoogleFonts.notoNaskhArabic(fontSize: 48),
          )
              .roll(renderMode: widget.mode)
              .animate(
                trigger: _index,
                duration: const Duration(milliseconds: 700),
              ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() =>
              _index = (_index + 1) % _phrases.length),
          child: const Text('Next'),
        ),
      ],
    );
  }
}
```

Import `google_fonts` at the top of the file if not already imported — other demos use it.

- [ ] **Step 5.3: Add Hebrew + Devanagari phrase-cycler demos**

After the existing Arabic demo, add two more demos that show Hebrew and Devanagari work correctly under the shaped path. Match the visual style of the existing Arabic demo:

```dart
const SizedBox(height: 48),
const _CompareLabel(text: 'Hebrew'),
const SizedBox(height: 12),
_PhraseDemo(
  phrases: const ['שלום', 'תודה', 'בוקר טוב'],
  direction: TextDirection.rtl,
  font: GoogleFonts.notoSansHebrew(fontSize: 48),
),
const SizedBox(height: 48),
const _CompareLabel(text: 'Devanagari'),
const SizedBox(height: 12),
_PhraseDemo(
  phrases: const ['नमस्ते', 'शुभ', 'धन्यवाद'],
  direction: TextDirection.ltr,
  font: GoogleFonts.notoSansDevanagari(fontSize: 48),
),
```

Add a shared `_PhraseDemo` helper at the bottom of the file (factor out the duplication from the existing Arabic demo at the same time if possible — but don't force a refactor if the existing demo has distinct structure):

```dart
class _PhraseDemo extends StatefulWidget {
  const _PhraseDemo({
    required this.phrases,
    required this.direction,
    required this.font,
  });
  final List<String> phrases;
  final TextDirection direction;
  final TextStyle font;

  @override
  State<_PhraseDemo> createState() => _PhraseDemoState();
}

class _PhraseDemoState extends State<_PhraseDemo> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Directionality(
          textDirection: widget.direction,
          child: Text(widget.phrases[_index], style: widget.font)
              .roll()
              .animate(
                trigger: _index,
                duration: const Duration(milliseconds: 700),
              ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() =>
              _index = (_index + 1) % widget.phrases.length),
          child: const Text('Next'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5.4: Verify example compiles**

Run: `cd example && flutter analyze lib 2>&1 | head -20`
Expected: no new errors. Pre-existing `deprecated_member_use` warnings in lib/ remain; the storyboard may pick up 1-2 new `deprecated_member_use` warnings from the legacy-mode button segment and comparison pane — those are expected and ok since they're intentional uses of the deprecated API.

- [ ] **Step 5.5: Commit**

```bash
git add example/lib/stories/text_animation.dart
git commit -m ":sparkles: Storyboard: default contextual + side-by-side + Hebrew/Devanagari"
```

---

## Task 6: CHANGELOG + Phase 5 verification

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 6.1: Run full suite**

Run: `CI=true flutter test --reporter expanded 2>&1 | tail -5`
Expected: 165 tests pass (no new tests in Phase 5; all existing continue to pass).

- [ ] **Step 6.2: Run analyzer**

Run: `flutter analyze lib test 2>&1 | grep -v deprecated_member_use | head`
Expected: no new issues.

- [ ] **Step 6.3: Update CHANGELOG**

Read `CHANGELOG.md`. Under the existing `## Unreleased` section (which has Phase 1-4 entries), prepend Phase 5 bullets:

```markdown
- **BREAKING**: The default `TextRenderMode` fallback is now `contextualCharacters` (was `independentCharacters`). For Latin text, visual output is pixel-stable; for RTL / complex scripts (Arabic, Hebrew, Devanagari, Thai), rolling text now renders correctly with proper shaping. See `docs/migration/v0.3-to-v0.4.md` for details and opt-out instructions.
- Deprecated `TextRenderMode.independentCharacters`. Will be removed in v0.5.0.
- Added `docs/migration/v0.3-to-v0.4.md` migration guide.
- Storyboard: default mode flipped to contextual; added a side-by-side legacy-vs-shaped Arabic comparison and Hebrew / Devanagari phrase-cycler demos.
```

- [ ] **Step 6.4: Commit**

```bash
git add CHANGELOG.md
git commit -m ":memo: CHANGELOG: Phase 5 default flip + deprecation"
```

---

## Self-review

Spec coverage against `docs/superpowers/specs/2026-04-17-shaped-text-rendering-design.md` Section "Deprecation timeline → v0.4.0":

- Default flips to `contextualCharacters`: **Task 1**.
- `independentCharacters` marked `@Deprecated`: **Task 2**.
- Migration doc published: **Task 4**.
- Storyboard updated: **Task 5**.

Spec coverage against the user's explicit ask:

- "Update our demo example" — Task 5 refreshes the storyboard with default contextual + comparison demo + Hebrew/Devanagari.

Omitted from Phase 5 per spec scope:

- Legacy code removal (Phase 6).
- Fix of 4 known source bugs (deferred indefinitely).
- Perf tuning (spec notes this as post-release work).

Placeholder scan: no TBD/TODO markers.

Type consistency:
- `TextRenderMode.independentCharacters` spelling stable across all files (the enum variant name doesn't change, only gets annotated).
- `resolveTextRenderMode` signature unchanged; only the fallback constant changes.
- Storyboard helper widgets (`_CompareLabel`, `_ComparePane`, `_PhraseDemo`) have internal, consistent signatures.

Breaking-change communication:
- `:warning:` commit prefix on the flip.
- CHANGELOG `**BREAKING**` bold prefix.
- Dedicated migration doc with opt-out examples at global, scope, and per-call levels.
- `@Deprecated` annotation fires analyzer warnings for existing users.
