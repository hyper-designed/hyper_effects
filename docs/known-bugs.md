# Known Bugs Pinned by Phase 1 Baseline Tests

Phase 1 baseline tests captured four bugs in current source. Each bug is pinned
with a `KNOWN BUG` comment in a test expectation. When the source is fixed, flip
the test expectation (the comment in each test explains what to flip to) and
update this index.

| # | Source location | Bug | Pinned by |
|---|---|---|---|
| 1 | `lib/src/effects/roll/symbol_tape_strategy.dart` near line 108 | `_repeatTape('a','a')` returns `'aa'` instead of `'a'` — asymmetric with `_noRepeatTape` which correctly early-returns. | `test/unit/effects/roll/symbol_tape_strategy_test.dart` — the `identical inputs` test in the `repeatCharacters: true` group |
| 2 | `lib/src/effects/roll/symbol_tape_strategy.dart:170` (docstring example) | Docstring claims `ConsistentSymbolTapeStrategy(2).build('a','z') == 'abyz'`; actual is `'abxz'` due to alternating-walk logic. | `test/unit/effects/roll/symbol_tape_strategy_test.dart` — `distance 2 between a and z` |
| 3 | `lib/src/effects/roll/symbol_tape_strategy.dart:173` (docstring example) | Docstring claims `ConsistentSymbolTapeStrategy(2).build('a','c') == 'abcc'`; actual is `'abac'`. | `test/unit/effects/roll/symbol_tape_strategy_test.dart` — `distance 2 between a and c` |
| 4 | `lib/src/effects/roll/text_extensions.dart:91-94` | `symbolDistanceMultiplier` assertion is `> 0`, but values in `(0, 1)` crash Flutter's `StrutStyle` (leading becomes negative). Assertion should be `>= 1`. | `test/widget/roll/rolling_text_configuration_test.dart` — `symbolDistanceMultiplier >= 1 accepted` |

These bugs are NOT fixed in Phase 1. They will be addressed in a later phase
(likely Phase 2, alongside the shaped-text rendering refactor).
