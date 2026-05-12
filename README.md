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

The modification must reuse and extend this architecture as much as possible.

The current structure engine is the canonical source of pivot state.

Existing structure interpretation should be modified or used as is to determine:

* higher high (HH)
* lower high (LH)
* lower low (LL)
* higher low (HL)

For example, these calculations are already implicitly performed for structure-line coloring and transition handling. The state (HH, LH, LL, HL) could be infered and stored as part of the swing info. Example:
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

Pivots from previous broker days must not participate in expansion evaluation for the new day.

Use broker server day boundaries.

The engine must remain lightweight.

Continue using:

```
HighState[2]
LowState[2]
```

Do NOT introduce:

* deep pivot arrays
* historical pivot chains
* independent pivot reconstruction systems

Pivot classification mutates throughout a pivot’s lifecycle similar to the segment coloring.

A pivot’s HH/LH/LL/HL classification is continuously updated while it is the current/latest pivot.

By the time a pivot becomes the previous pivot:

* its classification is already finalized
* its structural role is already known

The expansion engine must consume these finalized classifications from the existing structure engine.

Do NOT define contraction as:

```
currentHigh < previousHigh
```

in realtime.

That would incorrectly reset accumulation using mutable/unconfirmed pivots.

Instead:

A contraction is only considered confirmed when the `LH for highs` or `HL for lows` becomes the PREVIOUS pivot, ie. a new current pivot is formed. 

The expansion engine must use stored pivot classification state from the structure engine.

For high pivots:

Maintain:

```
double bullishStored
bool bullishLock
```

Initial:

```
bullishStored = 0;
bullishLock = false;
```

Bullish evaluation allowed ONLY when:

```
bullishLock == false
```

---

## BULLISH EXPANSION
Realtime bullish threshold evaluation must occur continuously during mutable HH evolution.

However, the mutable HH contribution must not be repeatedly accumulated permanently.

The engine must therefore use `bullishProjected` for realtime threshold evaluation. and bullishStored ONLY for finalized confirmed accumulation.

Realtime projected bullish expansion should behave conceptually as: `bullishProjected = bullishStored + (currentHigh.price - previousHigh.price)`

However, `bullishStored` must only permanently accumulate once the pivot becomes finalized.

The engine must NEVER repeatedly add evolving mutable expansion directly into permanent storage.

Where:

- previousHigh is finalized
- currentHigh is mutable

Threshold checks may use: `bullishProjected` since realtime triggering is allowed from mutable pivots.

Permanent accumulation must remain independent from mutable pivot identity.

When the mutable pivot eventually finalizes, ONLY the finalized delta should be permanently committed once.

When the current structure transition confirms bullish continuation:

```
HH (equal high is considered a HH)
```

then:

```
delta = currentHigh.price - previousHigh.price;
```

ONLY positive deltas may accumulate. Negative values must NEVER be added. This prevents mutable contractions from resetting `bullishStored`:

```
if(delta > 0)
    bullishStored += delta;
```

After accumulation:

If:

```
bullishStored >= 24000
```

then:

* plot lime dotted vertical line
* set:

```
bullishLock = true;
bearishLock = false;
```

* reset:

```
bullishStored = 0;
```

After bullish lock:

* no further bullish accumulation
* no bullish threshold evaluation
* bullish contractions ignored while locked

---

## BULLISH CONTRACTION

A bullish contraction is NOT evaluated from the mutable current pivot.

A contraction becomes valid only when:

```
the previous high pivot finalized as LH
```

When a confirmed LH exists AND:

```
bullishLock == false
```

then:

```
bullishStored = 0;
```

The contraction itself is NOT accumulated negatively.

It acts only as an accumulation invalidation/reset.

---

Mirror logic for low pivots.

Maintain:

```
double bearishStored
bool bearishLock
```

Initial:

```
bearishStored = 0;
bearishLock = false;
```

Bearish evaluation allowed ONLY when:

```
bearishLock == false
```

---

## BEARISH EXPANSION
Realtime bearish threshold evaluation must occur continuously during mutable LL evolution.

However, the mutable LL contribution must not be repeatedly accumulated permanently.

The engine must therefore use `bearishProjected` for realtime threshold evaluation. and bearishStored ONLY for finalized confirmed accumulation.

Realtime projected bullish expansion should behave conceptually as: `bearishProjected = bearishStored + (previousLow.price - currentLow.price)`

However, `bearishStored` must only permanently accumulate once the pivot becomes finalized.

The engine must NEVER repeatedly add evolving mutable expansion directly into permanent storage.

Where:

- previousLow is finalized
- currentLow is mutable

Threshold checks may use: `bearishProjected` since realtime triggering is allowed from mutable pivots.

Permanent accumulation must remain independent from mutable pivot identity.

When the mutable pivot eventually finalizes, ONLY the finalized delta should be permanently committed once.

When the current structure transition confirms bearish continuation:

```
LL (equal low is considered a LL)  
```

then:

```
delta = previousLow.price - currentLow.price;
```

ONLY positive deltas may accumulate:

```
if(delta > 0)
    bearishStored += delta;
```

If:

```
bearishStored >= 24000
```

then:

* plot red dotted vertical line
* set:

```
bearishLock = true;
bullishLock = false;
```

* reset:

```
bearishStored = 0;
```

---

## BEARISH CONTRACTION

A bearish contraction becomes valid only when:

```
the previous low pivot finalized as HL
```

When confirmed HL exists AND:

```
bearishLock == false
```

then:

```
bearishStored = 0;
```

Negative values are never accumulated.

---

Historical replay must:

* process pivots sequentially
* reuse the same structure engine logic
* preserve:

  * accumulation
  * reset logic
  * lock state
  * daily reset behavior

When threshold exceeded historically:

* plot the vertical line at the pivot anchor time/index where the exceeding pivot occurred

Realtime mode must:

* process only newly detected structure transitions
* never retroactively rebuild emitted signals

When threshold exceeded realtime:

* immediately plot the vertical line at the moment threshold exceeded

Realtime signals remain immutable permanently.

When both evaluations occur during the same calculation cycle:

1. process highs first
2. process lows second

Bullish threshold:

* color: Lime
* style: dotted
* object type: OBJ_VLINE

Bearish threshold:

* color: Red
* style: dotted
* object type: OBJ_VLINE

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
