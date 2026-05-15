Refactor the provided `Donchian Ultimate.mq5` MT5 indicator into a simplified, production-ready Donchian Channel core indicator while preserving its visual structure.

PRIMARY OBJECTIVE
Create a lean indicator that retains all 5 plotted bands and visual fills, but removes all non-core logic and complexity.

REMOVE COMPLETELY
1. Alert System (entirely remove)

* Remove:
    * All alert inputs
    * All alert state variables
    * All alert messages
    * All alert functions:
        * HandleAlerts()
        * IssueAlerts()
        * HasMidLineBullishCrossing()
        * HasMidLineBearishCrossing()
        * HasCandleCloseInsideResistance()
        * HasCandleCloseInsideSupport()
        * ResetGlobalVariables()
        * RefreshGlobalVariables()
* Remove:
    * Alert()
    * SendMail()
    * SendNotification()

2. Multi-Timeframe (MTF) Support (fully remove)
Remove:
* InpTimeframe
* Timeframe
* deltaHighTF
* CopyClose()
* iBarShift()
* Any higher-timeframe mapping logic

Indicator MUST operate only on:
* high[]
* low[]
* open[]
* close[]
from the current chart timeframe.

3. All alternative calculation modes (remove completely)
Remove:
* ENUM_PRICE_TYPE
* PriceType
* All switch-case logic for price variations

KEEP (VISUAL SYSTEM MUST REMAIN)
Retain all 5 bands and rendering exactly:
* Upper Line (highest high)
* Lower Line (lowest low)
* Mid Line (average of upper/lower)
* Resistance Line (lowest high)
* Support Line (highest low)
* Resistance Fill Zone
* Support Fill Zone

Also retain:
* DRAW_LINE
* DRAW_DOT styles
* DRAW_FILLING
* colors
* buffer structure
* plot configuration

CORE CALCULATION RULE (STRICT)
Use ONLY this logic:

Window
For each bar i: `start = i - InpPeriod + 1`

Bounds
* Upper Line = highest HIGH in window
* Lower Line = lowest LOW in window

Inner Structure (IMPORTANT — preserve exactly)
* Resistance = highest LOW in window
* Support = lowest HIGH in window

Midline 
* Mid = (Upper + Lower) / 2

IMPLEMENTATION REQUIREMENTS
* Use ONLY ArrayMaximum() and ArrayMinimum() on:
    * high[]
    * low[]
* No MTF functions
* No iHighest/iLowest
* No CopyClose
* No shift/timeframe mapping

PERFORMANCE RULE
Ensure:
* No unnecessary repeated scans where possible
* No redundant recalculations outside loop
* Safe indexing (start >= 0)
* Skip calculation if i < InpPeriod - 1

VISUAL REQUIREMENTS
Preserve:
* 5-band structure
* Fill zones between:
    * Resistance ↔ Upper
    * Support ↔ Lower
* Same colors and styles

FINAL OUTPUT REQUIREMENT
Produce:
* Clean, compile-ready MQL5 code
* Strict mode compatible
* Minimal, readable structure
* No unused variables or dead code

GOAL SUMMARY
A simplified Donchian indicator that:
* behaves exactly like the original visually
* but contains only core mathematical logic
* no alerts
* no MTF
* no alternate price models
* no feature bloat

Ensure the resulting code compiles cleanly in the Metatrader 5 platform without tiggering any warnings or errors.
