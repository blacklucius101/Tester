Develop an MT5 custom indicator implementing a dual-level semafor system with day-scoped processing and controlled repaint behavior.

## Core Requirements

The indicator operates on a per-day basis.

Default behavior:

* Process the current trading day only.

Optional behavior:

* User may specify a historical date.
* When a historical date is selected, processing is restricted to candles belonging to that date only.

The indicator must process data candle-by-candle in chronological order.

## Indicator Levels

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

* Number of subsequent candles within which an already plotted semafor may repaint if a new extreme is formed.

## Operational Logic

1. Daily Initialization

* At the start of each new day, initialize the indicator state.
* Bootstrap by assigning a preliminary dual high-low semafor to the first candle of the day.
* This pair of preliminary markings is static to this candle and is not subject to repaint rules.

2. Level 1 Processing

* Once enough candles exist to satisfy the Level 1 period requirement:

  * Evaluate the highest high within the Level 1 period window.
  * Evaluate the lowest low within the Level 1 period window.
* Plot Level 1 semafor arrows accordingly.

3. Repaint Logic

* A plotted semafor may repaint within its defined Backstep range.
* If a more extreme high or low appears within the Backstep window:

  * Remove or relocate the previous semafor.
  * Plot the new semafor at the more extreme candle.

4. Level Graduation

* Every Level 1 semafor must also be evaluated against Level 2 criteria.
* If a Level 1 high/low also satisfies Level 2 conditions:

  * Replace the Level 1 marker with a Level 2 marker.
  * Only the Level 2 arrow should remain visible at that candle.

5. Historical Processing

* When loading historical data:

  * Process candles sequentially from oldest to newest.
  * Evaluate semafor conditions candle-by-candle exactly as they would have formed in real time.
* No future-looking calculations are allowed outside the defined repaint/backstep window.

6. Real-Time Processing

* After historical initialization completes:

  * Process only newly closed candles.
  * Calculations and repaint decisions must occur on candle close, not tick-by-tick.

## Functional Expectations

* Indicator must support standard MT5 chart timeframes.
* Indicator must avoid unnecessary recalculation of previously finalized candles.
* Repainting must be limited strictly to the configured Backstep range.
* Arrows must remain visually aligned with candle highs/lows.
* The implementation should be optimized for low CPU usage during live updates.
*  The implementation must compile cleanly without triggering warnings or errors.

## Additional Notes

* State management is important because Level 1 markers may later graduate into Level 2 markers.
* Historical reconstruction and live processing must produce identical results for the same candle sequence.
