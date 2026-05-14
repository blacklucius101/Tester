Modify the existing MT5 indicator `MOD_3_Level_ZZ_Semafor.mq5` by extending the current realtime market structure engine with a directional expansion threshold engine.

The indicator already contains a realtime pivot lifecycle/state engine using:
```
HighState[2]
LowState[2]
```

and the function:
```
UpdateMarketStructure()
```

This existing engine already handles:
* mutable ZigZag pivots
* pivot replacement
* pivot confirmation
* structural transitions
* historical replay reconstruction

The modification must reuse the available architecture where possible.

The current structure engine is the canonical source of pivot state.

Existing structure interpretation should be used to determine:
* higher high (HH)
* lower high (LH)
* lower low (LL)
* higher low (HL)

The structure engine performs these calculations for structure-line coloring and segment labeling. The pivot state (HH, LH, LL, HL) should be infered and stored as part of the swing info. Example:
- for high pivots, lime segment is a HH, and red segment is a LH.
- for low pivots, red segment is a LL, and lime segment is a HH.

Add a directional expansion accumulation engine using:
* Level 2 highs (`HighState`)
* Level 2 lows (`LowState`)

The current/latest pivot is mutable. The previous pivot is finalized.

A pivot becomes finalized ONLY after: a new current pivot replaces it.

The engine accumulates same-direction expansion until:
* threshold exceeded
  OR
* confirmed contraction invalidates accumulation

Threshold:
```
24000 points
```

Signals:
* bullish threshold → lime dotted vertical line
* bearish threshold → red dotted vertical line

Vertical lines are immutable once drawn.

Use aggressive realtime triggering.

Signals may be emitted from mutable/latest pivots.

If a pivot later repaints/disappears:

* DO NOT remove prior vertical lines
* DO NOT retroactively rebuild signals
* DO NOT reevaluate previously emitted events

Signals are event-based and immutable.

The expansion engine must explicitly separate:
1. finalized accumulation state
2. realtime projected accumulation state

This separation is REQUIRED because ZigZag pivots are mutable and may:
* extend
* relocate
* repaint
* disappear
* change classification

throughout their lifecycle.

The engine must support realtime threshold triggering from mutable pivots without permanently double-counting mutable expansion.

Do NOT permanently accumulate mutable pivot expansion repeatedly on every recalculation. That approach causes accumulation inflation because the mutable pivot continuously evolves while remaining the same pivot.

Historical reconstruction does NOT need to perfectly reproduce realtime chronology.

At the start of each broker server day:
* reset bullish accumulation
* reset bearish accumulation
* reset bullish lock
* reset bearish lock
* reset expansion-state variables

Pivots from previous broker days must not participate in expansion evaluation for the new day. The expansion engine is effectively blind to any pivots that do not occur on the current day.

Use broker server day boundaries.

The engine must remain lightweight.

Do NOT introduce:
* deep pivot arrays
* historical pivot chains
* independent pivot reconstruction systems

Pivot classification mutates throughout a pivot’s lifecycle similar to the segment coloring. Classification belongs to the pivot itself relative to the previous same-type finalized pivot.

A pivot’s classification is continuously updated while it is the current/latest pivot.

By the time a pivot becomes the previous pivot:
* its classification is already finalized
* its structural role is already known

The expansion engine must consume these finalized classifications from the existing structure engine. The expansion engine must reuse the exact directional point-distance calculation already used by DrawStructureSegment() for segment labeling. 
The same normalized point delta value must be used for:
* segment text
* realtime current expansion
* finalized accumulation

Do not introduce a second independent distance calculation path. 

All expansion and contraction distances use absolute normalized point delta identical to DrawStructureSegment().

Do NOT define contraction as:
```
currentHigh < previousHigh
```

in realtime.

That would incorrectly reset accumulation using mutable/unconfirmed pivots.

Instead:

A contraction is only considered confirmed when the `LH for highs` or `HL for lows` becomes the PREVIOUS pivot, ie. a new current pivot is formed. 

Realtime threshold evaluation must occur continuously during mutable pivot evolution.

However, the mutable pivot contribution must not be repeatedly accumulated permanently.

The engine must therefore use 2 variables to track pivot difference:
* one for realtime threshold evaluation (which ideally should be derived from the same calculation which populates segment labels)
* the other for finalized confirmed accumulation.

A mutable contribution becomes finalized exclusively when the current pivot survives and a newer pivot of the same type becomes current.

Mutable realtime contribution must be recomputed from the current live pivot state each calculation cycle, while finalized accumulation may only change during confirmed pivot-state transitions.

## Bullish example:
Given the pivot sequence: HH1 → HH2 → [new day] → HH3 → HH4 → HH5. And two variables: stored, and current.
• HH2 → [new day] → HH3: `HH3 - HH2` shouldn't be possible. Also, both `stored` and `current` variables are reset to 0 when price crosses the daily boundary.
• HH3 → HH4: HH3 is the previous finalized pivot, HH4 is the current mutable pivot. To avoid redundant operations, segment label calculations (ie. `currentHigh - previousHigh` converted to points) populate `current`, and then `(stored + current) >= 24000` is evaluated. If true, a lime dotted vertical line is drawn at this candle and `stored` resets to 0 and further bullish expansion evaluation/accumulation is halted. If the pivot repaints, the calculations are redone.
• HH4 → HH5: new pivot detected, so `current` which at this moment still contains `HH4 - HH3`is added to stored (assuming threshold event wasn't triggered at the previous step) . Then a new `current` is populated based on the current mutable pivot `HH5 - HH4`.

Given the pivot sequence: [new day] → HH1 → HH2 → LH1 → HH3.
• [new day] → HH1: `stored` resets to 0 the moment price crosses the daily boundary. expansion/ threshold evaluation not possible with only one pivot.
• HH1 → HH2: `current` is `HH2 - HH1` which let's assume is <24000.
• HH2 → LH1: `stored = current`. Then new `current` is calculated.
• LH1 → HH3: if previous pivot is a contraction (ie. LH) then `stored` resets to 0, instead of adding in the `current`. Then `current` is `HH3 - LH1`. If >24000 draw the lime vertical line.

Given the pivot sequence: HH1 → HH2 → LH1 → LH2 → HH3 .
 • HH1 → HH2: `current` is `HH2 - HH1` and threshold evaluation is done on `stored + current` which let's assume is >24000. Lime vertical line is drawn and `stored` is reset to 0.
 • HH2 → LH1: The threshold event triggers a bullish lock which prevents accumulation of `stored`. New `current` is calculated.
 • LH1 → LH2: Contractions are accumulated separately, but only if the bullish lock has been triggered. Therefore, `stored_contraction = current`. Then new `current` is calculated. Contractions are informational-only and are not evaluated against any threshold. For now they're just calculated but remain unused beyond segment labeling.
 • LH2 → HH3: `stored` accumulation is blocked, so it is still effectively 0. `current` is calculated but only for segment labeling. Evaluation is unrequired when the lock has been triggered. HH pivot, even if mutable, will reset `stored_contraction`. This is because the same high pivot can only ever mutate higher.

Mirror logic for low pivots.

## Bearish example:
Given the pivot sequence: LL1 → LL2 → [new day] → LL3 → LL4 → LL5. And two variables: stored, and current.
• LL2 → [new day] → LL3: `LL3 - LL2` shouldn't be possible. Also, both `stored` and `current` variables are reset to 0 when price crosses the daily boundary.
• LL3 → LL4: LL3 is the previous finalized pivot, LL4 is the current mutable pivot. To avoid redundant operations, segment label calculations (ie. `currentLow - previousLow`, converted to points) populate `current`, and then `(stored + current) >= 24000` is evaluated. If true, a red dotted vertical line is drawn at this candle and `stored` resets to 0 and further bearish expansion evaluation/accumulation is halted.
• LL4 → LL5: new pivot detected, so `current` which at this moment still contains `LL4 - LL3`is added to stored (assuming threshold event wasn't triggered at the previous step). Then a new `current` is populated based on the current mutable pivot `LL5 - LL4`.

Given the pivot sequence: [new day] → LL1 → LL2 → HL1 → LL3.
• [new day] → LL1: `stored` resets to 0 the moment price crosses the daily boundary. expansion/ threshold evaluation not possible with only one pivot.
• LL1 → LL2: `current` is `LL2 - LL1` which let's assume is <24000.
• LL2 → HL1: `stored = current`. Then new `current` is calculated.
• HL1 → LL3: if previous pivot is a contraction (ie. HL) then `stored` resets to 0, instead of adding in the `current`. Then new `current` is `LL3 - LH1`. If >24000 draw the red vertical line.

Given the pivot sequence: LL1 → LL2 → HL1 → HL2 → LL3 .
 • LL1 → LL2: `current` is `LL2 - LL1` and threshold evaluation is done on `stored + current` which let's assume is >24000. Red vertical line is drawn and `stored` is reset to 0.
 • LL2 → HL1: The threshold event triggers a bearish lock which prevents accumulation of `stored`. New `current` is calculated.
 • HL1 → HL2: Contractions are accumulated separately, but only if the bearish lock has been triggered. Therefore, `stored_contraction = current`. Then new `current` is calculated. Contractions are informational-only and are not evaluated against any threshold. For now they're just calculated but remain unused beyond segment labeling.
 • HL2 → LL3: `stored` accumulation is blocked, so it is still effectively 0. `current` is calculated but only for segment labeling. Evaluation is unrequired when the lock has been triggered. LL pivot, even if mutable, will reset `stored_contraction`. This is because the same high pivot can only ever mutate higher.

---
stored_contraction resets when:
* a same-direction expansion pivot becomes current
OR
* broker-day reset occurs
OR
* opposite directional lock activates

When a new current pivot is detected:
1. finalize the previous current pivot classification
2. evaluate contraction reset logic
3. transfer mutable current contribution into finalized stored accumulation if eligible
4. initialize new mutable current contribution
5. evaluate realtime threshold state

At the first calculation cycle where bar time differs from the stored broker day:
* all expansion state resets immediately
* any active mutable contribution resets immediately
* any pivot whose mutation/update time belongs to the previous broker day becomes invalid for expansion evaluation even if the pivot still exists in ZigZag state.

A bullish threshold event immediately:
* activates bullish lock
* deactivates bearish lock

A bearish threshold event immediately:
* activates bearish lock
* deactivates bullish lock

Lock state changes caused by emitted threshold events are permanent until opposite lock activation or broker-day reset, even if the triggering mutable pivot later repaints or disappears.

Historical replay does NOT need to simulate every intermediate mutable pivot mutation tick-by-tick.

Historical replay may process only sequential finalized structure transitions as long as:
* accumulation state
* lock state
* threshold behavior
* daily reset logic

remain internally deterministic.

Historical replay divergence is acceptable.

The current lock state, and the pairs (low, high) of `current`, `stored` and `stored_contraction` must be exposed as global variables for possible use by external indicators.

Dual directional accumulations coexist provided no locks are active.
--- 

Historical replay must:
* process pivots sequentially
* reuse the same structure engine logic
* preserve:
  * accumulation
  * reset logic
  * lock state
  * daily reset behavior

When threshold exceeded in historical replay:
* plot the vertical line at the pivot anchor time/index where the exceeding pivot occurred

Realtime mode must:
* process only newly detected structure transitions
* never retroactively rebuild emitted signals

When threshold exceeded in realtime:
* immediately plot the vertical line at the moment threshold exceeded

Realtime signals remain immutable permanently.

When both evaluations occur during the same calculation cycle:
1. process highs first
2. process lows second

But this might be irrelevant since this tool is intended for use in BTCUSD M1, where it is unlikely for dual pivots to occur on the same candle.

Threshold condition is: (stored + current) >= 24000 

Once a directional threshold event fires:
* no further signals in the same direction may be emitted
until:
* opposite-direction lock activation
OR
* broker-day reset

Bullish threshold:
* color: Lime
* style: dotted
* object type: OBJ_VLINE (OBJPROP_BACK = false)

Bearish threshold:
* color: Red
* style: dotted
* object type: OBJ_VLINE (OBJPROP_BACK = false) 

Object names must be deterministic and unique.

Recommended:
```
EXP_BULL_<time>
EXP_BEAR_<time>
```

Do NOT:
* remove existing market structure functionality
* alter ZigZag settings
* duplicate pivot lifecycle logic
* create independent pivot scanners
* retroactively mutate emitted vertical lines
* allow duplicate signals after lock activation

The implementation must remain:
* lightweight
* realtime-safe
* replay-safe
* deterministic
* fully integrated with the existing state engine.
