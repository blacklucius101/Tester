# PHASE 1
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

Backstep is evaluated from the current candle being processed. If backstep = 2 and our current candle being processed is 10, a semafor at 9 repaints to 10. This ensures only one same-direction semafor arrow can exist within backstep distance of the current candle being processed.

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

--------------------------------------------------------------

# PHASE 2
Modify the MT5 custom indicator with the following specifications:

Same type level 2 semafor arrows should be connected with dashed lines and their price difference in points calculated and displayed. Example case:
Given the sequence of level 2 highs: A → B → C
Assuming B is HH1 and C is LH1. Since B is a higher high, it should be connected to A with a dashed lime line, and the difference `B - A` in points calculated and displayed. Since C is a lower high, it should be connected to B with a dashed red line, and the difference `C - B` in points calculated and displayed. The lines should be anchored to the highs of the respective candles.

The same is mirrored for level 2 lows.

Given the sequence of level 2 lows: A → B → C
Assuming B is LL1 and C is HL1. Since B is a lower low, it should be connected to A with a dashed red line, and the difference `B - A` in points calculated and displayed. Since C is a higher low, it should be connected to B with a dashed lime line, and the difference `C - B` in points calculated and displayed. The lines should be anchored to the lows of the respective candles.

--------------------------------------------------------------

# PHASE 3
Definition of terms
Expansion:
- bullish expansion: HH1 → HH2
- bearish expansion: LL1 → LL2

Contraction:
- bullish contraction: HH1 → LH1
- bearish contraction: LL1 → HL1

We should have expansion and contraction accumulation supported by the following variables (not finalised naming):
- total_expansion (bullish, bearish).
- total_contraction (bullish, bearish), will be used for further analysis in a future iteration.
- current_temp (bullish, bearish).

Expansion in points is evaluated against a threshold of 24000.

If bullish expansion in points >= 24000, plot a dotted vertical lime line at that bar index and trigger a bullish lock that prevents any further bullish expansion accumulation or evaluation and resets bullish total_expansion to 0 until a bearish lock unlocks bullish accumulation.

If bearish expansion in points >= 24000, plot a dotted vertical red line at that bar index and trigger a bearish lock that prevents any further bearish expansion accumulation or evaluation and resets bearish total_expansion to 0 until a bullish lock unlocks bearish accumulation.

Example bullish case:
Given the sequence HH1 → HH2 → HH3
Assuming HH1 is the first high of the day, total_expansion and total_contraction would be 0. When HH2 is formed, `current_temp = HH2 - HH1`. Threshold evaluation is `(bullish total_expansion + current_temp) >= 24000`:
- Assuming this evaluates to false, when HH3 is formed, current_temp is added to total_expansion before doing the new calculation `current_temp = HH3 - HH2` followed by a new threshold evaluation.
- However, if it evaluated to true, plot the vertical line and trigger bullish lock. When HH3 is formed current_temp is only used for point difference display and segment colouring. No bullish accumulation or threshold evaluation.

Given the sequence HH1 → HH2 → LH1 → LH2 → HH3 → HH4
Assuming HH1 is the first high of the day.
- If HH2 fails to trigger a bullish lock, when LH1 forms (LH1 - HH2) is a negative value. For bullish expansion accumulation, negative values cannot be added to total_expansion. When LH2 forms, LH1 is confirmed and since (LH1 - HH2) cannot be added to total_expansion, total_expansion is reset to 0. current_temp becomes (LH2 - LH1). When HH3 forms, LH2 is confirmed and since (LH2 - LH1) cannot be added, total_expansion remains 0. current_temp becomes (HH3 - LH2).
- However, if HH2 triggers a bullish lock, bullish expansion accumulation and threshold evaluation is halted. When LH2 forms, total_contraction becomes (LH1 - HH2). When HH3 forms, (LH2 - LH1) is added to total_contraction. When HH4 forms, total_contraction will be reset to 0 since bullish contraction only accepts negative values.

Note that bullish contraction accumulation is only allowed when the bullish lock is active.

Mirror logic for level 2 lows.

Example bearish case:
Given the sequence LL1 → LL2 → LL3
Assuming LL1 is the first low of the day, total_expansion and total_contraction would be 0. When HH2 is formed, `current_temp = LL2 - LL1`. Threshold evaluation is `(bearish total_expansion + current_temp) <= -24000`:
- Assuming this evaluates to false, when LL3 is formed, current_temp is added to total_expansion before doing the new calculation `current_temp = LL3 - LL2` followed by a new threshold evaluation.
- However, if it evaluated to true, plot the vertical line and trigger bearish lock. When LL3 is formed current_temp is only used for point difference display and segment colouring. No bearish accumulation or threshold evaluation.

Given the sequence LL1 → LL2 → HL1 → HL2 → LL3 → LL4
Assuming LL1 is the first low of the day.
- If LL2 fails to trigger a bearish lock, when HL1 forms (HL1 - LL2) is a positive value. For bearish expansion accumulation, positive values cannot be added to total_expansion. When HL2 forms, HL1 is confirmed and since (HL1 - LL2) cannot be added to total_expansion, total_expansion is reset to 0. current_temp becomes (HL2 - HL1). When LL3 forms, HL2 is confirmed and since (HL2 - HL1) cannot be added, total_expansion remains 0. current_temp becomes (LL3 - HL2).
- However, if LL2 triggers a bearish lock, bearish expansion accumulation and threshold evaluation is halted. When HL2 forms, total_contraction becomes (HL1 - LL2). When LL3 forms, (HL2 - HL1) is added to total_contraction. When LL4 forms, total_contraction will be reset to 0 since bearish contraction only accepts positive values.

Note that bearish contraction accumulation is only allowed when the bearish lock is active.

--------------------------------------------------------------

# PHASE 4
`Donchian_Bands.mq5` has the following lines:
- Upper line
- Resistance
- Midline
- Support
- Lower line

Upper and lower line form the outer borders. Everything else comprises the internal borders.

Resistance zone spans Upper line → Resistance.
Support zone spans Lower line → Support.

Midline may overlap with resistance/ support, in which case resistance/ support become the only valid borders. Resistance and support may not overlap. In that case, we technically have no valid internal borders.

Definition of terms:
- If bullish lock is active:
    - agreeing border is resistance, disagreeing border is support.
- If bearish lock is active:
    - agreeing border is support, disagreeing border is resistance.

- A close is considered beyond agreeing/disagreeing border if the close is nearer to the outer border than it is to the midline.
- A close is considered within agreeing/disagreeing border if the close is nearer to the midline than it is to the outer border.

When a lock is active, contractions cause BOS and MSS, if they occur in the support/resistance zones.
When candles cross beyond an agreeing border, `total_contraction + current_temp` is evaluated.
* `>=9500 is BOS`
* `>=24000 is MSS`
If this evaluates to true, the first candle that closes back within the agreeing border confirms BOS/MSS.
When a BOS or MSS is triggered, draw a vertical solid magenta line. 
If price crosses beyond a disagreeing border and closes back within the disagreeing border, MSS and BOS are reset.
An MSS causes an expansion of 12000 points to trigger a lock state (ie. it halves the threshold value).

--------------------------------------------------------------

# PHASE 5
Definition of terms:
Push occurs when price creates a new extreme, ie. pushes upper line higher, or pushes lower line lower.
Push can only occur at a disagreeing outer border.
When no lock is active (eg. at the start of the day) both outer borders are considered disagreeing.

Push comes in two forms:
- Cross push:
    - Bullish cross push: Occurs at the upper line. Bullish candle creates the new extreme. We then monitor for the first candle to cross back within the disagreeing internal border (ie. resistance counter-cross). There should be no intervening bullish candles between the bullish cross push candle and the resistance counter-cross candle. These disrupt the push. The resistance counter-cross candle must not span more than 50% of the distance from the bullish cross push candle open and the lowest low between the bullish cross push candle and the candle that precedes it. Preliminary bearish candles that occur before the actual resistance counter-cross candle are referred to as buffers.
    - Bearish cross push: Occurs at the lower line. Bearish candle creates the new extreme. We then monitor for the first candle to cross back within the disagreeing internal border (ie. support counter-cross). There should be no intervening bearish candles between the bearish cross push candle and the support counter-cross candle. These disrupt the push. The support counter-cross candle must not span more than 50% of the distance from the bearish cross push candle open and the lowest low between the bearish cross push candle and the candle that precedes it. Preliminary bullish candles that occur before the actual support counter-cross candle are referred to as buffers.

- Counter-cross push:
    - Bullish counter-cross push: Occurs at the upper line. Bearish candle creates the new extreme. We then monitor for the first candle to cross back within the disagreeing internal border (ie. resistance counter-cross). The push candle itself may also be the resistance counter-cross candle. There should be no intervening bullish candles between the counter-cross push candle and the resistance counter-cross candle. These disrupt the push. The candle preceding the counter-cross push candle must touch the upper line. If the push candle fails to double as the resistance counter-cross candle, preliminary bearish candles (buffers) may occur before the actual resistance counter-cross candle.
    - Bearish counter-cross push: Occurs at the lower line. Bullish candle creates the new extreme. We then monitor for the first candle to cross back within the disagreeing internal border (ie. support counter-cross). The push candle itself may also be the support counter-cross candle. There should be no intervening bearish candles between the counter-cross push candle and the support counter-cross candle. These disrupt the push. The candle preceding the counter-cross push candle must touch the lower line. If the push candle fails to double as the support counter-cross candle, preliminary bullish candles (buffers) may occur before the actual support counter-cross candle.

The resistance and support counter-cross candles should be visually marked out for identification.

------
## Candle - Border interaction specifics with active locks
1. Bullish lock active
Definition of terms:
- (Bullish) Cross: occurs when a bearish candle crosses through a border and closes beneath it (ie. open > border, close < border).
- (Bullish) Swipe: occurs when only the upper wick of a bearish candle touches the border (ie. open < border, high >= border).

Valid cross is accompanied by a valid counter-cross. The counter-cross must be visually marked out for identification.

- (Bullish) Counter-cross: occurs when a bullish candle closes above a border after a (bullish) cross occurred at that border.
- (Bullish) Failed counter-cross: occurs when the bullish candle touches the border but fails to close above it.

When a cross is disrupted, it stops being relevant.
(Bullish) Cross is disrupted when one of the following occurs before the (bullish) counter-cross:
- if another (bullish) cross or swipe occurs, the latest succeeds
- if a bearish float (ie. doesn't touch the border in question) candle occurs
- if a (bullish) failed counter-cross occurs

Additional notes on the (bullish) cross and counter-cross interactions with the disagreeing internal border (support) and midline + agreeing internal border (resistance):
- disagreeing internal border (support):  after the (bullish) cross, intervening bullish float candles (buffers) may occur before the actual (bullish) counter-cross.

- midline + agreeing internal border (resistance): the candle preceding the (bullish) cross must have a higher high than the (bullish) cross. The (bullish) counter-cross must not span past 50% of the distance between the (bullish) cross open and the highest high of the candle preceding the (bullish) cross.

- Special (bullish) counter-cross push at midline: this occurs when a reverse (bullish) swipe occurs at midline, ie. a bullish candle touches the midline but opens and closes above it. The candle preceding this push candle must not touch the midline.

- (Bullish) balding: occurs when a (bullish) cross has close == low, and (bullish) counter-cross has open == low. The transition is essentially a flat bottom. The two candles must occur side by side. When (bullish) cross is bald, (bullish) counter-cross must also be bald. When (bullish) counter-cross is bald, (bullish) cross must also be bald. Otherwise the cross and counter-cross are invalid, since balding must occur as a cross+counter-cross pair. Failed balding invalidates that particular border level, and no other readings can be taken from that border until the level changes.

All valid counter-cross candles must be visually marked out for identification.

Mirror logic for bearish lock active.

------
1. Bearish lock active
Definition of terms:
- (Bearish) Cross: occurs when a bullish candle crosses through a border and closes above it (ie. open < border, close > border).
- (Bearish) Swipe: occurs when only the lower wick of a bullish candle touches the border (ie. open > border, low <= border).

Valid cross is accompanied by a valid counter-cross. The counter-cross must be visually marked out for identification.

- (Bearish) Counter-cross: occurs when a bearish candle closes beneath a border after a (bearish) cross occurred at that border.
- (Bearish) Failed counter-cross: occurs when the bearish candle touches the border but fails to close below it.

When a cross is disrupted, it stops being relevant.
(Bearish) Cross is disrupted when one of the following occurs before the (bearish) counter-cross:
- if another (bearish) cross or swipe occurs, the latest succeeds
- if a bulliish float (ie. doesn't touch the border in question) candle occurs
- if a (bearish) failed counter-cross occurs

Additional notes on the (bearish) cross and counter-cross interactions with the disagreeing internal border (resistance) and midline + agreeing internal border (support):
- disagreeing internal border (resistance):  after the (bearish) cross, intervening bearish float candles (buffers) may occur before the actual (bearish) counter-cross.

- midline + agreeing internal border (support): the candle preceding the (bearish) cross must have a lower low than the (bearish) cross. The (bearish) counter-cross must not span past 50% of the distance between the (bearish) cross open and the lowest low of the candle preceding the (bearish) cross.

- Special (bearish) counter-cross push at midline: this occurs when a reverse (bearish) swipe occurs at midline, ie. a bearish candle touches the midline but opens and closes below it. The candle preceding this push candle must not touch the midline.

- (Bearish) balding: occurs when a (bearish) cross has close == high, and (bearish) counter-cross has open == high. The transition is essentially a flat top. The two candles must occur side by side. When (bearish) cross is bald, (bearish) counter-cross must also be bald. When (bearish) counter-cross is bald, (bearish) cross must also be bald. Otherwise the cross and counter-cross are invalid, since balding must occur as a cross+counter-cross pair. Failed balding invalidates that particular border level, and no other readings can be taken from that border until the level changes.

All valid counter-cross candles must be visually marked out for identification.

------
When bullish lock is active, BOS or MSS serves as a partial bearish lock:
- (Bearish) Counter-cross and (bearish) push are allowed and highlighted at the agreeing outer and internal border (ie. Upper line and resistance), and midline.
- The disagreeing outer and internal border (ie. Lower line and support) still only allow (bullish) counter-cross and (bullish) push highlights. The partial bearish lock is disrupted when a valid (bullish) counter-cross or (bullish) push forms.

------
When bearish lock is active, BOS or MSS serves as a partial bullish lock:
- (Bullish) Counter-cross and (bullish) push are allowed and highlighted at the agreeing outer and internal border (ie. Lower line and support), and midline.
- The disagreeing outer and internal border (ie. Upper line and resistance) still only allow (bearish) counter-cross and (bearish) push highlights. The partial bullish lock is disrupted when a valid (bearish) counter-cross or (bearish) push forms.
