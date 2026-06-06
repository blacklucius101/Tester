# PHASE 1
Develop an MT5 custom indicator implementing the specifications detailed below.

## Core Requirements

The indicator only works on a per day basis with intraday timeframes. (we're targeting BTCUSD M1 exclusively). Reset the indicator at the start of each day. Process only visible bars for selected day.

Note that:
* " → " denotes flow, eg. A → B means from A to B
* " - " denotes subtraction, eg. A - B means A minus B

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
* High Color: Magenta
* Low Color: Aqua

LEVEL 2
* Period: 13
* Backstep: 6
* Draw Type: DRAW_ARROW
* Arrow Code: 108
* Width: 1
* High Color: Magenta
* Low Color: Aqua

## Definitions
Period:
* Number of candles used to determine the highest high or lowest low.

Backstep:
* Number of candles a new extreme looks back to determine if it is a new unique semafor or a continuation. If a previous semafor falls within Backstep range of a current semafor, the previous semafor is deleted and it lives on as the current semafor (essentially suggesting that previous repainted to its current position).

Example case:
Backstep = 2 (ie. 2 previous candles inclusive)
Period = 2 (ie. 2 previous candles inclusive)
Newly closed candle = 10

Repaint scope is candles 9 → 10.
Period scope is also candles 9 → 10.

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

---

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
Assuming LL1 is the first low of the day, total_expansion and total_contraction would be 0. When LL2 is formed, `current_temp = LL2 - LL1`. Threshold evaluation is `(bearish total_expansion + current_temp) <= -24000`:
- Assuming this evaluates to false, when LL3 is formed, current_temp is added to total_expansion before doing the new calculation `current_temp = LL3 - LL2` followed by a new threshold evaluation.
- However, if it evaluated to true, plot the vertical line and trigger bearish lock. When LL3 is formed current_temp is only used for point difference display and segment colouring. No bearish accumulation or threshold evaluation.

Given the sequence LL1 → LL2 → HL1 → HL2 → LL3 → LL4
Assuming LL1 is the first low of the day.
- If LL2 fails to trigger a bearish lock, when HL1 forms (HL1 - LL2) is a positive value. For bearish expansion accumulation, positive values cannot be added to total_expansion. When HL2 forms, HL1 is confirmed and since (HL1 - LL2) cannot be added to total_expansion, total_expansion is reset to 0. current_temp becomes (HL2 - HL1). When LL3 forms, HL2 is confirmed and since (HL2 - HL1) cannot be added, total_expansion remains 0. current_temp becomes (LL3 - HL2).
- However, if LL2 triggers a bearish lock, bearish expansion accumulation and threshold evaluation is halted. When HL2 forms, total_contraction becomes (HL1 - LL2). When LL3 forms, (HL2 - HL1) is added to total_contraction. When LL4 forms, total_contraction will be reset to 0 since bearish contraction only accepts positive values.

Note that bearish contraction accumulation is only allowed when the bearish lock is active.

---

# PHASE 4
Integrate `Donchian_Bands.mq5` into `Custom_Indicator.mq5`.
Donchian_Bands.mq5 has the following lines (visualisation must be retained in the integration):
- Upper line
- Resistance
- Midline
- Support
- Lower line

---

# PHASE 5
Once the borders are defined, proceed to define candle-border interactions with & without active locks.

## Definition of terms
Outer borders: Upper line, Lower line.

Internal borders: Resistance, Midline, Support.

Resistance zone spans: Upper line → Resistance.

Support zone spans: Lower line → Support.

1. Bullish lock active:
  - (bullish) agreeing internal border: resistance
  - (bullish) disagreeing internal border: support
  - (bullish) agreeing outer border: upper line
  - (bullish) disagreeing outer border: lower line
  - (bullish) agreeing border zone: resistance zone
  - (bullish) disagreeing border zone: support zone

2. Bearish lock active:
  - (bearish) agreeing internal border: support
  - (bearish) disagreeing internal border: resistance
  - (bearish) agreeing outer border: lower line
  - (bearish) disagreeing outer border: upper line
  - (bearish) agreeing border zone: support zone
  - (bearish) disagreeing border zone: resistance zone

candle is considered as "crossing a border"/"closing through a border" when open is on one side of the border and close is on the opposite side

candle is considered as "touching a border" when only the wick contacts the border and the body is fully on one side

candle is considered a "float candle" if it doesn't touch any border at all

candle is considered a buffer if it touches the border but doesn't close through it

"beyond" and "within" are terms used to relate candle close position relative to the agreeing/disagreeing internal border:
- beyond resistance means candle close > resistance
- within resistance means candle close < resistance
- beyond support means candle close < support
- within support means candle close > support

---

## candle-border interactions
1. Outer borders
- Serve as price envelopes and thus cannot be closed through.
- Push occurs when price creates a new extreme, i.e. relevant candle has a higher `upper line` or lower `lower line` compared to the preceding candle.
- Push is the only time price is allowed to make contact with the outer borders.
- Note that, contact with a lower `upper line` or higher `lower line` does not count as a Push.
- Push only occurs at a disagreeing outer border.
- When no lock is active (e.g. at the start of the day) both outer borders are considered disagreeing.
- When a lock is active, there can only be one disagreeing outer border, exception being the special case with BOS/MSS which act as partial locks and cause both outer borders to be considered disagreeing.

Push comes in two forms:
1. Cross push:
    a.) Bullish cross push:
        - Occurs at the `upper line`.
        - Bullish candle creates the new extreme. We then monitor for the first candle to cross back within the disagreeing internal border (ie. resistance counter-cross).
        - There should be no intervening bullish candles between the bullish cross push candle and the resistance counter-cross candle. These disrupt the bullish push.
        - The resistance counter-cross candle low must not span into more than 50% of the distance from the bullish cross push candle open and the lowest low between the bullish cross push candle low and the low of the candle that precedes it.
        - Preliminary bearish buffer candles can occur before the actual resistance counter-cross candle.

    b.) Bearish cross push:
        - Occurs at the lower line.
        - Bearish candle creates the new extreme. We then monitor for the first candle to cross back within the disagreeing internal border (ie. support counter-cross).
        - There should be no intervening bearish candles between the bearish cross push candle and the support counter-cross candle. These disrupt the bearish push.
        - The support counter-cross candle high must not span into more than 50% of the distance from the bearish cross push candle open and the highest high between the bearish cross push candle high and the high of the candle that precedes it.
        - Preliminary bullish buffer/float candles can occur before the actual support counter-cross candle.

2. Counter-cross push:
    a.) Bullish counter-cross push:
        - Occurs at the upper line.
        - Bearish candle creates the new extreme. We then monitor for the first candle to cross back within the disagreeing internal border (ie. resistance counter-cross).
        - The push candle itself may also be the resistance counter-cross candle.
        - The candle preceding the counter-cross push candle must touch the `upper line`.
        - If the push candle itself fails to double as the resistance counter-cross candle:
            - Preliminary bearish buffer/float candles may occur before the actual resistance counter-cross candle.
            - There should be no intervening bullish candles between the counter-cross push candle and the resistance counter-cross candle. These disrupt the push.

    b.) Bearish counter-cross push:
        - Occurs at the lower line.
        - Bullish candle creates the new extreme. We then monitor for the first candle to cross back within the disagreeing internal border (ie. support counter-cross).
        - The push candle itself may also be the support counter-cross candle.
        - The candle preceding the counter-cross push candle must touch the `lower line`. 
        - If the push candle itself fails to double as the support counter-cross candle:
            - Preliminary bullish buffer/float candles may occur before the actual support counter-cross candle.
            - There should be no intervening bearish candles between the counter-cross push candle and the support counter-cross candle. These disrupt the push.

The resistance and support counter-cross candles should be visually marked out for identification.

---

2. Internal borders

## Definition of terms:
1. Bullish lock active
    - (bullish) cross: occurs when a bearish candle crosses through an internal border and closes beneath it (ie. open >= border, close < border).
    - (bullish) swipe: occurs when only the upper wick of a bearish candle touches the internal border (ie. open < border, high >= border).

    - (bullish) counter-cross: occurs when a bullish candle closes above an internal border (ie. close >= border), after a (bullish) cross/swipe occurred at that internal border.
    - (bullish) failed counter-cross: occurs when the bullish candle touches the internal border but fails to close above it (ie. high >= border, close < border), after a (bullish) cross/swipe occurred at that internal border.

Valid (bullish) cross/swipe is accompanied by a valid (bullish) counter-cross. They occur in pairs.

The counter-cross must be visually marked out for identification. 

Failed counter-cross is not highlighted.

When a cross/swipe is disrupted, it stops being relevant.

(Bullish) Cross/swipe is disrupted when one of the following occurs before the (bullish) counter-cross:
- if another (bullish) cross/swipe occurs, the latest succeeds the former
- if a bearish float candle occurs
- if a (bullish) failed counter-cross occurs

Additional notes on the (bullish) cross/swipe and (bullish) counter-cross interactions with the disagreeing internal border (support), midline and agreeing internal border (resistance):
- disagreeing internal border (support): 
    - after the (bullish) cross/swipe, intervening bullish float candles may occur before the actual (bullish) counter-cross.

- midline, agreeing internal border (resistance):
    - the candle preceding the (bullish) cross/swipe candle must have a higher high than the (bullish) cross/swipe candle.
    - the (bullish) counter-cross candle's high price must not span into more than 50% of the distance from the (bullish) cross/swipe candle open and the high of the candle preceding the (bullish) cross/swipe candle.
    - there must be no intervening bullish float candles between (bullish) cross/swipe and the actual (bullish) counter-cross. The two candles must occur side by side.

- Special (bullish) counter-cross push at midline:
    - occurs when a reverse (bullish) swipe occurs at midline, ie. a bullish candle touches the midline but opens and closes above it (`open > midline, close > midline, low <= midline`).
    - the candle preceding this push candle must not touch the midline (low > midline).
    - this push candle's body must not cross any border.

- (Bullish) balding:
    - occurs when a (bullish) cross/swipe has `close == low`, and (bullish) counter-cross has `open == low`, and (bullish) cross/swipe close == (bullish) counter-cross open. The transition is essentially a flat bottom.
    - the two candles must occur side by side.
    - when (bullish) cross/swipe is bald, (bullish) counter-cross must also be bald. When (bullish) counter-cross is bald, (bullish) cross/swipe must also be bald. Otherwise it is a failed balding and the cross/swipe and counter-cross are invalid, since balding must occur as a cross/swipe + counter-cross pair.
    - failed balding invalidates that particular border level, and no other readings can be taken from that border until the level changes (eg. balding detected at support level $67890, makes that level stale until support shifts higher/lower).
    - balding is only valid if it occurs within the resistance/support zones (ie. midline does not recognize balding).
    - balding applies to cross push events, since they have a cross + counter-cross pair.
    - there's no balding for BOS/MSS counter-cross candles, since there is no cross candle.
    - there's no balding for counter-cross push events, since there is no cross candle.

All valid counter-cross candles must be visually marked out for identification.

Mirror logic for bearish lock active.

---

1. Bearish lock active
    - (bearish) cross: occurs when a bullish candle crosses through an internal border and closes above it (ie. open <= border, close > border).
    - (bearish) swipe: occurs when only the lower wick of a bullish candle touches the internal border (ie. open > border, low <= border).

    - (bearish) counter-cross: occurs when a bearish candle closes below an internal border (ie. close <= border), after a (bearish) cross/swipe occurred at that internal border.
    - (bearish) failed counter-cross: occurs when the bearish candle touches the internal border but fails to close below it (ie. low <= border, close > border), after a (bearish) cross/swipe occurred at that internal border.

Valid (bearish) cross/swipe is accompanied by a valid (bearish) counter-cross. They occur in pairs.

The counter-cross must be visually marked out for identification. 

Failed counter-cross is not highlighted.

When a cross/swipe is disrupted, it stops being relevant.
(Bearish) Cross/swipe is disrupted when one of the following occurs before the (bearish) counter-cross:
- if another (bearish) cross/swipe occurs, the latest succeeds the former
- if a bullish float candle occurs
- if a (bearish) failed counter-cross occurs

Additional notes on the (bearish) cross/swipe and (bearish) counter-cross interactions with the disagreeing internal border (resistance), midline and agreeing internal border (support):
- disagreeing internal border (resistance): 
    - after the (bearish) cross/swipe, intervening bearish float candles may occur before the actual (bearish) counter-cross.

- midline, agreeing internal border (support):
    - the candle preceding the (bearish) cross/swipe candle must have a lower low than the (bearish) cross/swipe candle.
    - the (bearish) counter-cross candle's low price must not span into more than 50% of the distance from the (bearish) cross/swipe candle open and the low of the candle preceding the (bearish) cross/swipe candle.
    - there must be no intervening bearish float candles between (bearish) cross/swipe and the actual (bearish) counter-cross. The two candles must occur side by side.

- Special (bearish) counter-cross push at midline:
    - occurs when a reverse (bearish) swipe occurs at midline, ie. a bearish candle touches the midline but opens and closes below it (`open < midline, close < midline, high >= midline`).
    - the candle preceding this push candle must not touch the midline (high < midline).
    - this push candle's body must not cross any border.

- (Bearish) balding:
    - occurs when a (bearish) cross/swipe has `close == high`, and (bearish) counter-cross has `open == high`, and (bearish) cross/swipe close == (bearish) counter-cross open. The transition is essentially a flat top.
    - the two candles must occur side by side.
    - when (bearish) cross/swipe is bald, (bearish) counter-cross must also be bald. When (bearish) counter-cross is bald, (bearish) cross/swipe must also be bald. Otherwise it is a failed balding and the cross/swipe and counter-cross are invalid, since balding must occur as a cross/swipe + counter-cross pair.
    - failed balding invalidates that particular border level, and no other readings can be taken from that border until the level changes (eg. balding detected at support level $67890, makes that level stale until support shifts higher/lower).
    - balding is only valid if it occurs within the resistance/support zones (ie. midline does not recognize balding).
    - balding applies to cross push events, since they have a cross + counter-cross pair.
    - there's no balding for BOS/MSS counter-cross candles, since there is no cross candle (exception being cross push events).
    - there's no balding for counter-cross push events, since there is no cross candle.

All valid counter-cross candles must be visually marked out for identification.

Every valid counter-cross event shall be plotted using an arrow buffer. Bullish events buffer uses arrow code 233 plotted beneath the candle. Bearish events buffer uses arrow code 234 plotted above the candle.

---

## Border rules
Midline may overlap with resistance or support (ie. midline >= resistance, midline <= support), in which case resistance and support become the only valid borders and midline is treated as practically non-existent.

Resistance and support may not overlap (resistance <= support). If they do, we technically have no valid internal borders, since they cancel each other out and as a result both are treated as practically non-existent.

Treating a border as practically non-existent means the border is visible on the chart but invisible to the indicator's logic.

* counter-cross push candle must not close through more than 2 internal borders.
* cross push candle, cross candle, or counter-cross candle must not close through more than 1 internal border.

A candle is considered to have closed through a border when its open is on one side of the border and its close is on the opposite side. Outer borders (ie. upper line/lower line) cannot be closed through since they act as envelopes of price.

Additionally, cross push candle or cross candle must not both:
1. close through an internal border, and
2. touch the midline.

Counter-cross candles are immune to this midline touch.

Equality (close/open == border) counts as a border crossing when evaluating maximum border crossings.

A candle must not contact the outer borders unless it is a push candle. Non-push candles contacting the outer borders are invalid cross/counter-cross candle candidates.

The special midline push candle must not close through any border.

---

# PHASE 6
After defining how candles interact with borders with and without active locks, define the required behavior for contractions, BOS, and MSS.

## Definition of terms:
When a lock is active, (*active lock type) contractions (LH/HL, as defined in Phase 3) cause (*active lock type) BOS/MSS, if they occur beyond the corresponding agreeing internal border of that lock state. The LH/HL candle must open/close inside the agreeing border zone. We'll refer to (*active lock type) contraction semafor candles that satisfy these conditions as valid (*active lock type) contractions hereafter.

BOS/MSS will work with the following states (implementation isn't restricted to this pattern, this is just to make the explanation clear):
- NOT_TRIGGERED: no valid (*active lock type) contraction detected. It is the default state.
- TRIGGERED_WAITING_CONFIRMATION: valid (*active lock type) contraction detected and BOS/MSS threshold check evaluates true.
- CONFIRMED: agreeing internal border counter-cross candle forms after BOS/MSS threshold triggers.

Note that the agreeing internal border counter-cross candle is the first candle to close back within the agreeing internal border. This counter-cross candle can be the contraction semafor candle itself. This counter-cross candle only follows the push rules and border rules outlined in Phase 5.

When a valid (*active lock type) contraction occurs, `total_contraction + current_temp` is evaluated against the BOS/MSS thresholds:
* BOS threshold is 9500 points
* MSS threshold is 24000 points

MSS supersedes BOS, thus a single valid (*active lock type) contraction cannot trigger both at the same time.

- For (bullish) contraction, `(bullish) total_contraction + current_temp` <= -9500 or -24000.
- For (bearish) contraction, `(bearish) total_contraction + current_temp` >= 9500 or 24000.

current_temp is the same one used to calculate structure segment distances, as described in Phase 3.

Check Phase 3 for why (bullish) contraction uses negative values and (bearish) contraction uses positive values.

## BOS/MSS reset rules:
1. TRIGGERED_WAITING_CONFIRMATION
This BOS/MSS state is disrupted and reset to NOT_TRIGGERED when:
- agreeing internal border counter-cross candle is invalid (ie. fails the relevant push or border rules)
- the associated valid contraction semafor (LH/HL) evolves higher/lower at the next candle
- a new same-type semafor is formed

From Phase 3, note that LH → HH/HL → LL will reset (*active lock type) total_contraction to 0.

2. CONFIRMED
This BOS/MSS state is disrupted and reset to NOT_TRIGGERED when:
- price closes back within the (*active lock type) disagreeing border after closing beyond the (*active lock type) disagreeing border. This must be a valid counter-cross candle (check Phase 5 for details).
- the opposite lock is triggered (ie. (*active lock type) BOS/MSS do not persist between lock transitions: bullish → bearish, bearish → bullish). CONFIRMED (*active lock type) MSS causes an expansion of 12000 points to trigger the opposite lock state (ie. it halves the expansion threshold value).

---

Example bullish case:
Given the sequence HH1 → HH2 → LH1 → LH2/HH3, where HH2 triggers a bullish lock state, (bullish) BOS/MSS state becomes NOT_TRIGGERED.
- If LH1 is a valid (bullish) contraction, the BOS/MSS threshold is evaluated. If it evaluates true, (bullish) BOS/MSS state becomes TRIGGERED_WAITING_CONFIRMATION. We then wait for a resistance counter-cross candle (which can be the LH1 candle itself):
    - If the resistance counter-cross candle fails the push/border rules, (bullish) BOS/MSS state becomes NOT_TRIGGERED.
    - If price stays up in the resistance zone, not once closing beneath it, and eventually forms a new semafor (LH2/HH3):
        - If LH2, BOS/MSS state immediately resets to NOT_TRIGGERED, and if LH2 is a valid (bullish) contraction BOS/MSS threshold is evaluated.
        - If HH3, (bullish) BOS/MSS state immediately resets to NOT_TRIGGERED, and (bullish) total_contraction resets to 0.
    - If the resistance counter-cross candle doesn't fail the push/border rules, (bullish) BOS/MSS state becomes CONFIRMED. Plot a solid vertical magenta line at the resistance counter-cross candle's bar index to mark out exactly where the (bullish) BOS/MSS was confirmed. The resistance counter-cross candle must also be highlighted with the same arrows targeting other counter-cross candles (as detailed in Phase 5).
        - CONFIRMED (bullish) BOS/MSS acts as a partial bearish lock influencing midline + resistance zone. The active bullish lock maintains influence of the support zone. Thus we essentially have two disagreeing border zones, and no agreeing border zone.
            - resistance zone only highlights counter-cross candles associated with the bearish lock (ie. resistance counter-cross from bullish push, (bearish) counter-cross)
            - midline only highlights counter-cross candles associated with the bearish lock (ie. (bearish) counter-cross, special (bearish) counter-cross push at midline)
            - support zone only highlights counter-cross candles associated with the active bullish lock (ie. support counter-cross from bearish push, (bullish) counter-cross. Valid counter-cross candle at the support zone resets (bullish) BOS/MSS state to NOT_TRIGGERED.
        - CONFIRMED (bullish) MSS halves bearish expansion threshold. If at the time of confirmation (bearish) total_expansion <= -12000 points, then instead of a solid vertical magenta line, we trigger bearish lock and plot the associated red dotted vertical line. Otherwise we have to wait for price to form a LL expansion that triggers the halved threshold, (bearish) total_expansion + current_temp <= -12000 points. Bearish lock immediately resets (bullish) BOS/MSS state to NOT_TRIGGERED, and (bullish) total_contraction to 0.
        - CONFIRMED (bullish) MSS is not affected by the formation of LH2/HH3, provided price didn't close within the support zone.

Mirror logic for bearish lock state.

---

Example bearish case:
Given the sequence LL1 → LL2 → HL1 → HL2/LL3, where LL2 triggers a bearish lock state, (bearish) BOS/MSS state becomes NOT_TRIGGERED.
- If HL1 is a valid (bearish) contraction, the BOS/MSS threshold is evaluated. If it evaluates true, (bearish) BOS/MSS state becomes TRIGGERED_WAITING_CONFIRMATION. We then wait for a support counter-cross candle (which can be the HL1 candle itself):
    - If the support counter-cross candle fails the push/border rules, (bearish) BOS/MSS state becomes NOT_TRIGGERED.
    - If price stays down in the support zone, not once closing above it, and eventually forms a new semafor (HL2/LL3):
        - If HL2, BOS/MSS state immediately resets to NOT_TRIGGERED, and if HL2 is a valid (bearish) contraction BOS/MSS threshold is evaluated.
        - If LL3, (bearish) BOS/MSS state immediately resets to NOT_TRIGGERED, and (bearish) total_contraction resets to 0.
    - If the support counter-cross candle doesn't fail the push/border rules, (bearish) BOS/MSS state becomes CONFIRMED. Plot a solid vertical magenta line at the support counter-cross candle's bar index to mark out exactly where the (bearish) BOS/MSS was confirmed. The support counter-cross candle must also be highlighted with the same arrows targeting other counter-cross candles (as detailed in Phase 5).
        - CONFIRMED (bearish) BOS/MSS acts as a partial bullish lock influencing midline + support zone. The active bearish lock maintains influence of the resistance zone. Thus we essentially have two disagreeing border zones, and no agreeing border zone.
            - support zone only highlights counter-cross candles associated with the bullish lock (ie. support counter-cross from bearish push, (bullish) counter-cross)
            - midline only highlights counter-cross candles associated with the bullish lock (ie. (bullish) counter-cross, special (bullish) counter-cross push at midline)
            - resistance zone only highlights counter-cross candles associated with the active bearish lock (ie. resistance counter-cross from bullish push, (bearish) counter-cross). Valid counter-cross candle at the resistance zone resets (bearish) BOS/MSS state to NOT_TRIGGERED.
        - CONFIRMED (bearish) MSS halves bullish expansion threshold. If at the time of confirmation (bullish) total_expansion >= 12000 points, then instead of a solid vertical magenta line, we trigger bullish lock and plot the associated lime dotted vertical line. Otherwise we have to wait for price to form a HH expansion that triggers the halved threshold, (bullish) total_expansion + current_temp >= 12000 points. Bullish lock immediately resets (bearish) BOS/MSS state to NOT_TRIGGERED, and (bearish) total_contraction to 0.
        - CONFIRMED (bearish) MSS is not affected by the formation of HL2/LL3, provided price didn't close within the resistance zone.

---

# Phase 7: Review and Testing

## Preliminary Error Report
`Prototype_Custom_Indicator.mq5` is the working indicator up to phase 4.

`Final_Custom_Indicator.mq5` is the partially working indicator up to phase 6. Partially working because during testing, semafors stop evolving higher/lower with price once a red/lime vertical threshold line is triggered. The semafor remains anchored to its triggering candle even after that candle stops being the highest high/ lowest low of that particular period. This seems to be an error in the integration of phases 5 and 6 with the initial 4 phases. Cross-reference `Prototype_Custom_Indicator.mq5` to identify exactly what is wrong and correct it.

Additionally, for some reason counter-cross candles are not being highlighted at all. This is contrary to the expected requirements.

Record the identified issues as comments alongside the corrected code.

Conduct a review pass to ensure the corrected code satisfies expected requirements. Ensure the final code compiles in MetaTrader 5 without triggering errors or warnings.
