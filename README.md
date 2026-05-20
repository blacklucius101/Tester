Develop an MT5 custom indicator implementing a dual-level semafor system with day-scoped processing and controlled repaint behavior.

## Core Requirements

The indicator only works on a per day basis with intraday timeframes. Ignore any candles that fall outside the specified daily session.

Default behavior:

* Process the current trading day only.

Optional behavior:

* User may specify a historical date.
* When a historical date is selected, processing is restricted to candles belonging to that date only.

The indicator must process data candle-by-candle in chronological order.

## Indicator Levels
These are hardcoded and shouldn't be modified:
LEVEL 1

* Period: 2
* Backstep: 2
* Draw Type: DRAW_ARROW
* Arrow Code: 159
* Width: 1
* High Color: Aqua
* Low Color: Magenta

LEVEL 2

* Period: 13
* Backstep: 5
* Draw Type: DRAW_ARROW
* Arrow Code: 108
* Width: 1
* High Color: Aqua
* Low Color: Magenta

## Definitions

Period:

* Number of candles used to determine the highest high or lowest low.

Backstep:

* Number of candles a new extreme looks back to determine if it is a new unique semafor or a continuation. If a previous semafor falls within Backstep range of a current semafor, the previous semafor is deleted and it lives on as the current semafor (essentially suggesting that previous repainted to its current position).

## Operational Logic

1. Daily Initialization

* At the start of each new day, initialize the indicator state.
* Bootstrap by assigning preliminary dual high-low semafors to the extremes of the first candle of the day (both levels 1 and 2).
* This double pair of preliminary markings is static to this candle and is not subject to repaint rules.

2. Level 1 & 2 Processing

* Once enough candles exist to satisfy the Level 1 period requirement:

  * Evaluate the highest high within the Level 1 period window.
  * Evaluate the lowest low within the Level 1 period window.
* Plot Level 1 semafor arrows accordingly.

* Same goes for Level 2 processing.

3. Repaint Logic

* A previous semafor may repaint if within Backstep range of a current semafor.
* If a more extreme high or low appears and previous is within the Backstep window:

  * Remove or relocate the previous semafor.
  * Plot the new semafor at the more extreme candle.

5. Historical Processing

* When loading historical data:

  * Process candles sequentially from oldest to newest.
  * Evaluate semafor conditions candle-by-candle exactly as they would have formed in real time.
* No future-looking calculations are allowed outside the defined repaint/backstep window.

6. Real-Time Processing

* After historical initialization completes:

  * Process only newly closed candles (ie. processing should occur on the first tick of a newly opened candle, which finalizes the previous candle as closed.).
  * Calculations and repaint decisions must occur on candle close, not tick-by-tick.

7. Anchor Retention Logic

The indicator is NOT intended to behave like a conventional ZigZag implementation that maintains a full historical pivot chain through indicator buffers.

Instead, the system should maintain only the two most recent confirmed semafor anchors per direction:

* Two most recent HIGH anchors
* Two most recent LOW anchors

Behavioral Requirements:

* When a new valid high semafor is confirmed:

  * Shift the previous most recent high into the secondary position.
  * Discard any older high anchors beyond the most recent two.
* Apply the same logic independently for low semafors.

Repaint Scope:

* Repainting is permitted only within the configured Backstep window.
* Once an anchor is finalized outside its repaint scope, it becomes immutable unless displaced by the rolling two-anchor retention policy.

Implementation Guidance:

* Avoid traditional full-history ZigZag buffer architecture.
* Prefer a lightweight state-driven structure maintaining only active semafor states and recent anchor references.
* Historical plotting should reflect only anchors that would still exist under the rolling retention model.
* The indicator should not continuously recalculate or redraw deep historical pivot structures.

Expected Result:

* At any given time, the chart should display only the latest actionable semafor structure rather than an accumulated historical zigzag map.
* This behavior is intentional and central to the design.

## Functional Expectations

* Indicator must support standard MT5 chart timeframes.
* Indicator must avoid unnecessary recalculation of previously finalized candles.
* Repainting must be limited strictly to the configured Backstep range.
* Arrows must remain visually aligned with candle highs/lows.
* The implementation should be optimized for low CPU usage during live updates.
*  The implementation must compile cleanly in the Metatrader 5 platform without triggering warnings or errors.

## Additional Notes

* State management is important because Level 1 markers may later graduate into Level 2 markers.
* Historical reconstruction and live processing must produce identical results for the same candle sequence.
