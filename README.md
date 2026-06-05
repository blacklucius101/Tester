# PHASE 5
Once the borders are defined, proceed to define candle-border interactions with & without active locks.

## Definition of terms
- Outer borders: Upper line, Lower line.
- Internal borders: Resistance, Midline, Support.

- Resistance zone spans: Upper line → Resistance.
- Support zone spans: Lower line → Support.

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

- candle is considered as "crossing a border"/"closing through a border" when open is on one side of the border and close is on the opposite side
- candle is considered as "touching a border" when only the wick contacts the border and the body is fully on one side
- candle is considered a "float candle" if it doesn't touch any border at all
- candle is considered a buffer if it touches the border but doesn't close through it

"beyond" and "within" are terms used to relate candle close position relative to the agreeing/disagreeing internal border:
- beyond resistance means candle close > resistance
- within resistance means candle close < resistance
- beyond support means candle close < support
- within support means candle close > support

---

## candle-border interactions
1. Outer borders
Serve as price envelopes and thus cannot be closed through.
Push occurs when price creates a new extreme, i.e. relevant candle has a higher `upper line` or lower `lower line` compared to the preceding candle.
Push is the only time price is allowed to make contact with the outer borders.
Note that, contact with a lower `upper line` or higher `lower line` does not count as a Push.
Push only occurs at a disagreeing outer border.
When no lock is active (e.g. at the start of the day) both outer borders are considered disagreeing.
When a lock is active, there can only be one disagreeing outer border, exception being the special case with BOS/MSS which act as partial locks and cause both outer borders to be considered disagreeing.

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

A candle is considered to have closed through a border when its open is on one side of the border and its close is on the opposite side. Outer borders (ie. upper/lower line) cannot be closed through since they act as envelopes of price.

Additionally, cross push candle or cross candle must not both:
1. close through an internal border, and
2. touch the midline.

Counter-cross candles are immune to this midline touch.

Equality (close/open == border) counts as a border crossing when evaluating maximum border crossings.

A candle must not contact the outer borders unless it is a push candle.

The special midline push candle must not close through any border.

---

# PHASE 6
After defining how candles interact with borders with and without active locks, define the required behavior for contractions, BOS, and MSS.

## Partial locks when BOS/MSS occurs
Definition of terms:
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
