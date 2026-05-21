Develop an MT5 custom indicator implementing the specifications detailed below.

## Core Requirements

The indicator only works on a per day basis with intraday timeframes. (we're targeting BTCUSD M1 exclusively). Reset the indicator at the start of each day. Process only visible bars for selected day.

Default behavior:
* Process the current trading day only.

Optional behavior:
* User may specify a historical date using input datetime.
* When a historical date is selected, processing is restricted to candles belonging to that date only. Ignore any candles that fall outside the specified date. Day boundaries use broker server time. Historical date is based on broker server calendar date.

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

Example case:
Backstep = 2 (ie. 2 previous candles inclusive)
Period = 2 (ie. 2 previous candles inclusive)
Newly closed candle = 10

Repaint scope is candles 9 - 10.
Period scope is also candles 9 - 10.

## Operational Logic
1. Level 1 & 2 Processing
* At the start of the day, wait until enough candles exist to satisfy the Level 1 period requirement. Once this condition is met:
  * Evaluate the highest high within the Level 1 period window.
`highest high > all other highs in period`
  * Evaluate the lowest low within the Level 1 period window.
`lowest low < all other lows in period`
* Using buffers, plot Level 1 semafor arrows accordingly at the highest high/ lowest low.
* High and low semafor streams operate independently.
* Equal high/low does not qualify as higher high or lower low.
* Semafors can only repaint higher or lower.
* The same candle can simultaneously host both high and low for the same level.

* Same goes for Level 2 processing.
* Level 1 and Level 2 operate independently and can simultaneously exist on the same candle.

3. Repaint Logic
* A previous semafor may repaint if within Backstep range of a current semafor.
* If a more extreme high or low appears and previous is within the Backstep window:
  * Remove or relocate the previous semafor.
  * Plot the new semafor at the more extreme candle.

4. Historical Processing
* When loading historical data:
  * Process candles sequentially from oldest to newest.
  * Evaluate semafor conditions candle-by-candle exactly as they would have formed in real time.

5. Real-Time Processing
* After historical initialization completes:
  * Calculations and repaint decisions must occur on candle close, not tick-by-tick. All calculations use closed candles only (ie. shift >= 1). No intra-candle recalculation.

6. Anchor Retention Logic
The indicator is NOT intended to behave like a conventional ZigZag implementation.
For analysis purposes the system should maintain only the two most recent semafor anchors per direction:
* Two most recent HIGH anchors
* Two most recent LOW anchors
Visually all confirmed semafor arrows for that day should persist.
This holds for both levels 1 and 2.

Example case:
Given a high sequence A → B → C:
* Semafor anchor at A (H1) becomes confirmed when semafor anchor at  B (H2) is formed, where A is outside the backstep range of B. Semafor A becomes immutable. Our retained anchors become [A, B].
* When high C arrives, it is evaluated and if B is in the backstep range of C, the H2 is relocated to C. However, if B is not in the backstep range of C, a new semafor (H3) is formed at C and this anchor pushes out anchor A such that we now retain [B, C]. Note that the visual semafor arrow (H1) at A stays persistent. The two retained anchors have information which will, in a later development pass, be used to generate market structure lines.

Behavioral Requirements:
* When a new valid high semafor is confirmed:
  * Shift the previous most recent high into the secondary position.
  * Discard any older high anchors beyond the most recent two (retain them visually).
* Apply the same logic independently for low semafors.

Repaint Scope:
* Repainting is permitted only within the configured Backstep window.
* Once an anchor is finalized outside its repaint scope, it becomes immutable unless displaced by the rolling two-anchor retention policy.
* There's a difference between a semafor anchor and the semafor arrow itself. An anchor refers to the candle whose high/low has a semafor arrow.
* The indicator should not continuously recalculate or redraw deep historical pivot structures. It's a one pass then retain model.

## Functional Expectations
* Indicator must avoid unnecessary recalculation of previously finalized candles.
* Repainting must be limited strictly to the configured Backstep range.
* Arrows must remain visually aligned exactly with candle highs/lows. No offset required. Arrow-candle overlap is expected.
* The implementation should be optimized for low CPU usage during live updates.
*  The implementation must compile cleanly in the Metatrader 5 platform without triggering warnings or errors.

## Additional Notes
* Historical reconstruction and live processing must produce identical results for the same candle sequence.
