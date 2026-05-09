Modify the existing MT5 indicator `MOD_3_Level_ZZ_Semafor.mq5`.

The current implementation already contains:
* Level 2 expansion engine
* directional lock state machine
* threshold detection
* repaint-aware mutable pivot processing
* daily reset logic
* historical bootstrap reconstruction

DO NOT rewrite the indicator architecture.

Apply ONLY the following targeted corrections.

# OBJECTIVE
Stabilize live-state behavior by:
1. preventing repeated processing of identical mutable pivots
2. converting directional lock into a true active-regime freeze mechanism

The goal is:
* stable live forward behavior
* reduced state churn
* cleaner regime transitions
* improved computational efficiency

Historical replay precision is NOT a concern.

DO NOT redesign the engine into a fully event-sourced system.

Maintain the existing lightweight architecture.

# REQUIRED CORRECTION 1 — PIVOT DEDUPLICATION

## PROBLEM
The current implementation repeatedly calls:
```
ProcessPivot(...)
```
on every tick for the same mutable Level 2 pivot.

This causes:
* redundant state mutation
* repeated tentative-state processing
* repeated reset evaluation
* unnecessary CPU churn
* unstable live-state behavior during repainting

# REQUIRED FIX
Add lightweight pivot deduplication.
The expansion engine must process a pivot ONLY IF:
* pivot timestamp changed
  OR
* pivot price changed materially

DO NOT process identical mutable pivots repeatedly.

# IMPLEMENTATION REQUIREMENTS
Add the following fields to:
```
struct ExpansionEngineState
```

Add:
```
datetime lastProcessedHighTime;
double   lastProcessedHighPrice;

datetime lastProcessedLowTime;
double   lastProcessedLowPrice;
```

Initialize/reset them properly inside:
```
Reset(...)
```

Use:
* time comparison
* AND price comparison

# LIVE PROCESSING RULES
In live incremental mode:
Replace unconditional calls: `ProcessPivot(...)`
with guarded processing.

Example logic:
```
bool highChanged =
   HighState[1].time != state.lastProcessedHighTime ||
   MathAbs(HighState[1].price - state.lastProcessedHighPrice) > _Point;
```

ONLY process when:
```
highChanged == true
```

After processing:
* update stored lastProcessed fields

Apply same logic to:
* highs
* lows

# IMPORTANT
DO NOT suppress repaint responsiveness.

If:
* pivot time changes
  OR
* mutable pivot price extends

the engine MUST still process it.

The goal is:
* event-like behavior
  without redesigning the architecture.

# REQUIRED CORRECTION 2 — TRUE DIRECTIONAL LOCK FREEZE

# PROBLEM
Current implementation only suppresses:
* additional threshold creation

But the locked direction still continues:
* origin updates
* tentative structure tracking
* reset handling
* expansion accumulation

This creates:
* hidden state drift
* unnecessary processing
* unstable directional semantics

# REQUIRED FIX
Directional lock must become:
* an ACTIVE regime freeze

Meaning:

When:
```
dirState == BULL_LOCKED
```

Then:
* ALL bullish expansion processing must stop entirely

INCLUDING:
* bullish origin updates
* bullish HH tracking
* bullish tentative LH tracking
* bullish reset handling
* bullish accumulation logic

ONLY bearish-side logic remains active.

Likewise:

When:
```
dirState == BEAR_LOCKED
```

Then:
* ALL bearish expansion processing must stop entirely

ONLY bullish-side logic remains active.

# IMPORTANT EXCEPTION
Opposite-direction confirmation logic MUST still function.

Example:

When:
```
dirState == BULL_LOCKED
```

the engine must STILL allow:
* bearish-side confirmation logic
* bearish expansion tracking
* bearish threshold detection

because bearish threshold achievement is what transitions the regime out of:
```
BULL_LOCKED
```

# REQUIRED PROCESSING FLOW

## HIGH pivot branch
Allow:
* bearish confirmation/reset logic

Then:

If:
```
dirState == BULL_LOCKED
```

Immediately exit bullish-side processing.
Do NOT continue bullish expansion logic.

# LOW pivot branch

Allow:
* bullish confirmation/reset logic

Then:

If:
```
dirState == BEAR_LOCKED
```

Immediately exit bearish-side processing.
Do NOT continue bearish expansion logic.

# TARGET BEHAVIOR
WAITING
* both engines active

BULL_LOCKED
* bearish engine only active

BEAR_LOCKED
* bullish engine only active

# IMPORTANT CONSTRAINTS
Maintain compatibility with:
* existing semafor plotting
* existing market structure drawing
* existing repaint handling
* existing object naming
* existing threshold logic
* existing daily reset behavior

DO NOT:
* redesign the architecture
* introduce full event sourcing
* rewrite the structure engine
* introduce heavy historical replay simulation

The indicator must:
* compile cleanly
* produce no warnings/errors
* remain lightweight
* preserve current behavior except for the corrections above
* remain repaint-aware
* remain incrementally processed
* remain optimized for live usage
