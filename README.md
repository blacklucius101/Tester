Refactor the attached MT5 indicator into a unified candle-by-candle replay engine using a single processing path for both historical and realtime execution.

IMPORTANT ARCHITECTURAL GOALS

The current implementation has:

* separate historical reconstruction logic
* separate realtime mutation/update logic

This must be replaced with:

* one unified sequential processing engine
* identical behavior for historical and realtime execution
* candle-close processing only
* use shift = 1 (previous candle) logic only, instead of shift = 0 (current candle)
* no tick-level processing
* no separate historical reconstruction branch

The resulting architecture should behave as a deterministic state machine.

CORE DESIGN PRINCIPLES

1. PROCESS ONLY CLOSED CANDLES

* The engine must execute only when a new bar forms.
* All logic must use shift = 1.
* No processing should occur on shift = 0.
* Ignore intra-candle mutations entirely.

2. SINGLE PROCESSING FUNCTION
   Create a unified function similar to:

```cpp
void ProcessBar(int shift,
                const datetime &time[],
                const double &high[],
                const double &low[],
                int rates_total)
```

This function must:

* read ZigZag buffers
* detect pivot creation/replacement
* update market structure
* update expansion engine
* manage locks
* update visual objects

The same function must be used for:

* historical replay
* realtime updates

3. HISTORICAL REPLAY
   On first initialization:

* replay candles sequentially from oldest to newest
* process one candle at a time
* emulate live execution exactly

Example:

```cpp
for(int i = rates_total - 2; i >= 1; i--)
{
    ProcessBar(i, ...);
}
```

Do NOT:

* scan only pivot bars
* use separate historical pivot reconstruction
* use separate mutable/finalized historical logic

4. REALTIME EXECUTION
   After initialization:

* detect new closed candle
* call the exact same ProcessBar() function

Example:

```cpp
if(IsNewBar())
{
    ProcessBar(1, ...);
}
```

5. KEEP EXISTING ZIGZAG HANDLES
   Retain:

* Handle1
* Handle2
* Handle3

Continue using:

* CopyBuffer()

Do NOT rewrite ZigZag calculations manually.

6. MARKET STRUCTURE PHILOSOPHY
   The system intentionally accepts mutable ZigZag pivots.

However:

* pivots are only processed at candle close
* finalized state transitions are authoritative
* no rollback/reversal system is required

This is acceptable because:

* bullish high pivots only repaint upward
* bearish low pivots only repaint downward
* expansion logic is monotonic
* locks are irreversible by same-direction expansion

Therefore:

* replay windows are NOT required
* rollback systems are NOT required
* processing once per closed candle is sufficient

7. REMOVE SPLIT HISTORICAL/REALTIME LOGIC
   Eliminate:

* historical-only pivot replay branches
* duplicate market structure update paths
* separate mutable/finalized historical reconstruction code

The engine should instead rely entirely on sequential candle replay.

8. PIVOT HANDLING RULES
   Retain support for:

* pivot replacement
* pivot movement
* pivot disappearance
* mutable latest pivot logic

The current state-machine behavior using:

* state[0]
* state[1]

should remain conceptually intact.

9. EXPANSION ENGINE RULES
   Retain:

* bullish/bearish lock logic
* threshold triggering
* accumulation behavior
* contraction tracking

Expansion accumulation must still occur ONLY on finalized transitions.

10. PERFORMANCE REQUIREMENTS
    Avoid:

* full-history recalculation every tick
* excessive object recreation

Historical replay should occur only:

* on initialization
* or full recalculation events

Realtime execution should process only one new closed candle.

11. OBJECT MANAGEMENT
    Retain:

* structure segment drawing
* labels
* expansion vertical lines

However:

* avoid unnecessary delete/recreate cycles where possible
* update mutable latest objects efficiently

12. IMPORTANT IMPLEMENTATION DETAIL
    Buffers and timeseries must remain synchronized.

If buffers are series arrays:

* times[] must also be treated as series arrays.

13. DESIRED RESULT
    The final architecture should behave like:

INITIALIZATION:

```text
Replay candles sequentially oldest → newest
using ProcessBar()
```

LIVE:

```text
On each new closed candle:
    ProcessBar(1)
```

with identical state behavior in both modes.

The end result should be:

* deterministic
* replay-safe
* candle-close driven
* single-path architecture
* cleaner than the current implementation
* easier to extend with future candle-level features
* compile cleanly in the Metatrader 5 platform without triggering errors or warnings
