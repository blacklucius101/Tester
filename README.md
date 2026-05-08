Create an MT5 custom indicator in MQL5 that acts as a secondary analytical layer for the existing indicator: `MOD_3_Level_ZZ_Semafor`.

The primary indicator already:
- generates ZigZag semafor pivots
- exposes pivot buffers
- handles repainting internally

The secondary indicator must NOT replicate ZigZag calculations.
It must call the primary indicator once during OnInit() using iCustom() and read its buffers using CopyBuffer().

# Objective
The secondary indicator detects directional expansion events based on Level 2 semafors only.
When the distance between consecutive: Higher Highs (HH) OR Lower Lows (LL) reaches or exceeds 24000 points the indicator plots a vertical line at the candle where the threshold is FIRST observed.

# IMPORTANT LOGIC RULES
1. Use ONLY Level 2 semafors from the primary indicator. Ignore all other semafor levels.
2. Daily reset behavior. The logic operates independently for each trading day.
At the start of a new day:
- clear all internal tracking variables
- clear directional lock state
- ignore previous day semafors

DO NOT delete historical vertical lines already drawn.

3. Consecutive HH logic
Example:
A = previous High2 semafor
B = latest High2 semafor

If:
B > A

then compute:
(B - A) / _Point

If the result is:
>= 24000

then:
draw ONE bullish vertical line
color = clrLime
style = STYLE_DOT
width = 1

The vertical line must be drawn at the candle where the threshold is FIRST observed.

4. Consecutive LL logic
Example:
A = previous Low2 semafor
B = latest Low2 semafor

If:
B < A

then compute:
(A - B) / _Point

If the result is:
>= 24000

then:
draw ONE bearish vertical line
color = clrRed
style = STYLE_DOT
width = 1

The vertical line must be drawn at the candle where the threshold is FIRST observed.

5. Alternation lock logic (VERY IMPORTANT)
After a bullish threshold event fires:
- ignore ALL future bullish events
- even if larger HHs form
- even if the semafor repaints higher

Bullish events remain disabled until: a bearish threshold event occurs.

After a bearish threshold event fires: 
- ignore ALL future bearish events
- even if larger LLs form
- even if the semafor repaints lower

Bearish events remain disabled until: a bullish threshold event occur.

Implement this using a directional state machine.

Suggested enum:
```
enum DirectionState
{
   WAITING,
   BULL_LOCKED,
   BEAR_LOCKED
};
```

6. Repainting behavior
The latest semafor pivot MUST be used.
Do NOT wait for pivot confirmation.

Reason: the objective is to capture the FIRST threshold breach, not the final stabilized ZigZag pivot.

If a semafor later repaints farther:
- DO NOT move the vertical line
- DO NOT redraw it
- DO NOT delete it

Vertical lines are permanent once created.

7. Performance requirements
The indicator must evaluate conditions ONLY once per completed candle.
Do NOT process logic on every tick.

Suggested approach:
`if(time[1] != lastProcessedBarTime)`

The latest mutable semafor may still be read from: buffer[0] but calculations must only occur after candle close.

8. Incremental processing only
Do NOT repeatedly scan the entire chart history.
Maintain incremental state variables such as:
- previous HH
- previous LL
- current directional lock
- last processed bar time
- current trading day

The indicator should be lightweight and efficient.

9. Vertical line naming
Use deterministic object names to prevent duplicates.

Examples:
```
"HH_24000_" + IntegerToString((long)time)
"LL_24000_" + IntegerToString((long)time)
```

10. Expected behavior example
Example bullish sequence:
```
HH1 = 1.1000
HH2 = 1.3400
```

Difference: 24000 points

Immediately:
- draw Lime dotted vertical line
- lock bullish direction

If semafor later repaints to: 1.5800

DO NOT:
- move the line
- redraw another bullish line

Continue ignoring bullish signals until: a bearish 24000 LL event occurs.

# Deliverables
Produce:
- complete compilable MQL5 indicator code
- proper OnInit()
- proper OnCalculate()
- proper object management
- proper state machine implementation
- proper daily reset logic
- compatibility with historical data
- proper incremental processing
- comments explaining all major logic blocks

The indicator must compile cleanly in MetaEditor with no warnings or errors.
