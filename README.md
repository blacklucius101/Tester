You are modifying an MT5 indicator expansion engine inside `ProcessPivot()`.

The current implementation incorrectly treats `BULL_LOCKED` and `BEAR_LOCKED` as fully inactive states. This causes stale expansion origins to persist and later trigger false threshold events.

You must preserve the existing architecture and only modify the state behavior logic inside `ProcessPivot()`.

# Intended State Semantics

## WAITING

* Initial state at the start of a new day.
* No pivots processed yet.

## BULL_LOCKED

Meaning:

* Bullish expansion accumulation is frozen.
* Bearish expansion processing remains active.

Behavior:

* Every new HIGH pivot automatically becomes the new bullish origin.
* No distinction between HH and LH while frozen.
* No bullish threshold calculations while frozen.
* Bullish contraction logic is disabled while frozen.
* Bearish logic continues normally.

Example:
If HH1 triggers threshold:

* plot lime vertical line at HH1
* state becomes BULL_LOCKED
* OriginHH shifts to HH1

Then:

* HH2 automatically becomes new OriginHH
* LH1 automatically becomes new OriginHH
* no bullish expansion accumulation occurs

Bearish side continues operating normally.

---

## BEAR_LOCKED

Meaning:

* Bearish expansion accumulation is frozen.
* Bullish expansion processing remains active.

Behavior:

* Every new LOW pivot automatically becomes the new bearish origin.
* No distinction between LL and HL while frozen.
* No bearish threshold calculations while frozen.
* Bearish contraction logic is disabled while frozen.
* Bullish logic continues normally.

Example:
If LL2 triggers threshold:

* plot red vertical line at LL2
* state becomes BEAR_LOCKED
* OriginLL shifts to LL2

Then:

* HL1 automatically becomes new OriginLL
* HL2 automatically becomes new OriginLL
* no bearish expansion accumulation occurs

Bullish side continues operating normally.

# Required Fix

Currently the code does this:

```cpp
if(state.dirState != BEAR_LOCKED)
{
   // bearish logic
}
```

and similarly for bullish logic.

This is WRONG because frozen sides stop updating origins entirely.

You must replace this behavior with:

# Correct Behavior For Frozen Side

When `state.dirState == BEAR_LOCKED`:

* EVERY low pivot must immediately become:

  * `state.bearOriginPrice`
  * `state.bearLowestPrice`
* `state.bearHasOrigin = true`
* `state.bearHasTentativeHL = false`
* NO threshold calculations
* NO LL/HL distinction
* NO contraction logic

When `state.dirState == BULL_LOCKED`:

* EVERY high pivot must immediately become:

  * `state.bullOriginPrice`
  * `state.bullHighestPrice`
* `state.bullHasOrigin = true`
* `state.bullHasTentativeLH = false`
* NO threshold calculations
* NO HH/LH distinction
* NO contraction logic

# Important

Do NOT redesign the engine.

Do NOT change:

* drawing logic
* object naming
* OnCalculate()
* UpdateMarketStructure()
* pivot detection

Only modify the state-handling logic inside `ProcessPivot()`.

# Expected Result

Sequence:

OriginHH [110000]
OriginLL [100000]
LL1 [88980]
HH1 [150134] -> threshold -> BULL_LOCKED
LL2 [47110] -> threshold -> BEAR_LOCKED
HL1 [72360]
HH2 [165025]
LH1 [149560]
HH3 [150295]
HL2 [138680]

Expected:

* Lime line at HH1 only
* Red line at LL2 only
* NO red line at HL1
* HL1 and HL2 automatically become new OriginLL because BEAR_LOCKED ignores LL/HL distinction
* HH2 does NOT trigger threshold because:
  165025 - 150134 = 14891 < 24000
