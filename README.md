Modify the existing MT5 indicator: `MOD_3_Level_ZZ_Semafor.mq5`.

The indicator already:
- generates multi-level ZigZag semafor pivots
- tracks mutable pivot state
- handles repainting internally
- maintains market structure state using Level 2 semafors

The new functionality must be integrated DIRECTLY into the existing primary indicator.

# OBJECTIVE
Add a Level 2 directional expansion engine that detects cumulative directional expansion across consecutive structural continuation swings.

When cumulative directional expansion reaches or exceeds 24000 points:
- draw a permanent vertical line
- lock that direction
- ignore additional same-direction signals
- until the opposite directional threshold event occurs

The logic must use ONLY:
- Level 2 High semafors
- Level 2 Low semafors

Ignore Levels 1 and 3 entirely.

# CORE CONCEPT
This is NOT pairwise pivot comparison.

The system must:
- accumulate directional expansion across multiple consecutive Higher Highs (HH)
- accumulate directional expansion across multiple consecutive Lower Lows (LL)

The expansion origin remains active until structurally invalidated.

# IMPORTANT STRUCTURAL RULES

## 1. Bullish Expansion Logic
Assume consecutive Level 2 High semafors: A → B → C → D

If:
B > A
C > B
D > C

Then bullish expansion remains active.

The bullish expansion distance is ALWAYS:

(CurrentHighestHH - ExpansionOriginHH) / _Point

Example:
A = 1.10000
B = 1.14000
C = 1.18000
D = 1.34000

Expansion distance: D - A = 24000 points

At the FIRST candle where: distance >= 24000

Draw:
- one bullish vertical line
- color = clrLime
- style = STYLE_DOT
- width = 1

Then:
- lock bullish direction
- ignore all future bullish threshold events
- even if higher HHs continue forming

Bullish triggers remain disabled until: a bearish threshold event occurs.

# 2. Bearish Expansion Logic
Assume consecutive Level 2 Low semafors: A → B → C → D

If:
B < A
C < B
D < C

Then bearish expansion remains active.

The bearish expansion distance is ALWAYS: (ExpansionOriginLL - CurrentLowestLL) / _Point

Example:
A = 1.34000
B = 1.30000
C = 1.26000
D = 1.10000

Expansion distance: A - D = 24000 points

At the FIRST candle where: distance >= 24000

Draw:
- one bearish vertical line
- color = clrRed
- style = STYLE_DOT
- width = 1

Then:
- lock bearish direction
- ignore all future bearish threshold events
- even if lower LLs continue forming

Bearish triggers remain disabled until: a bullish threshold event occurs.

# 3. STRUCTURAL INVALIDATION RULES (CRITICAL)
A Lower High (LH) is NOT confirmed immediately.

A tentative LH becomes STRUCTURALLY CONFIRMED ONLY IF: a Level 2 Low semafor forms afterward (HL or LL).

Until that low-side semafor forms:
- the tentative LH may still repaint into a HH
- bullish expansion remains active
- bullish origin must NOT reset

Likewise:

A Higher Low (HL) is NOT confirmed immediately.

A tentative HL becomes STRUCTURALLY CONFIRMED ONLY IF: a Level 2 High semafor forms afterward (LH or HH).

Until that high-side semafor forms:
- the tentative HL may still repaint into a LL
- bearish expansion remains active
- bearish origin must NOT reset

# 4. EXPANSION RESET RULES
Bullish expansion resets ONLY when: a LH becomes structurally confirmed.

Bearish expansion resets ONLY when: a HL becomes structurally confirmed.

At reset:
- establish a new expansion origin
- restart accumulation from the new structure

# 5. REPAINTING BEHAVIOR
The indicator MUST use: the latest mutable Level 2 semafor pivots.

DO NOT wait for final ZigZag stabilization.

However: structural invalidation/reset logic must obey confirmation rules described above.

Once a vertical line is drawn:
- NEVER move it
- NEVER delete it
- NEVER redraw it
- even if pivots repaint farther afterward

Vertical lines are permanent.

# 6. DAILY RESET LOGIC
At the start of each new trading day:

Reset:
- bullish expansion origin
- bearish expansion origin
- directional lock state
- structural tracking variables

Ignore all previous-day semafors for new calculations.

HOWEVER:
DO NOT delete historical vertical lines already drawn.

The first same-day Level 2 pivot becomes the new expansion baseline.

# 7. DIRECTIONAL LOCK STATE MACHINE
Implement:
```
enum DirectionState
{
   WAITING,
   BULL_LOCKED,
   BEAR_LOCKED
};
```

Behavior:

WAITING
- bullish threshold → BULL_LOCKED
- bearish threshold → BEAR_LOCKED

BULL_LOCKED
- ignore all bullish threshold events
- bearish threshold → BEAR_LOCKED

BEAR_LOCKED
- ignore all bearish threshold events
- bullish threshold → BULL_LOCKED

# 8. PERFORMANCE REQUIREMENTS
DO NOT scan full chart history repeatedly.

The indicator already maintains incremental structure state.

Extend the existing incremental architecture.

The expansion engine must:
- process incrementally
- evaluate only when pivots update
- avoid expensive rescans

# 9. HISTORICAL COMPATIBILITY
When the indicator first loads:
- reconstruct historical expansion events chronologically
- draw historical vertical lines
- obey all:
  - repaint logic
  - confirmation rules
  - daily reset rules
  - directional lock rules

After initialization:
- continue incrementally only

# 10. VERTICAL LINE DRAWING
Bullish line:
- color = clrLime
- style = STYLE_DOT
- width = 1

Bearish line:
- color = clrRed
- style = STYLE_DOT
- width = 1

The vertical line must be drawn at:
- the candle where the threshold was FIRST observed

# 11. OBJECT NAMING

Use deterministic names.

Examples:

"HH_24000_" + IntegerToString((long)time)
"LL_24000_" + IntegerToString((long)time)

Where:
time = open time of the candle where the threshold breach was first detected.

Prevent duplicate object creation.

# 12. POINT CALCULATION
Use:

distance = MathAbs(priceB - priceA) / _Point;

DO NOT convert to pips.

Threshold:
24000 points

# 13. IMPLEMENTATION REQUIREMENTS
Maintain compatibility with:
- existing semafor plotting
- existing market structure drawing
- existing repaint handling
- existing object management

Do NOT break current functionality.

Add:
- clean helper functions
- comments explaining logic
- robust state handling
- safe object creation checks

The modified indicator must:
- compile cleanly
- produce no warnings/errors
- remain lightweight
- function correctly in both live and historical environments.
