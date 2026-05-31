# PHASE 4
Integrate `Donchian_Bands.mq5` into `Custom_Indicator.mq5`.
Donchian_Bands.mq5 has the following lines (visualisation must be retained in the integration):
- Upper line
- Resistance
- Midline
- Support
- Lower line

# PHASE 5
Once the borders are defined, proceed to define push events and candle-border interactions with active locks.

## Definition of terms that will be encountered in the next phases
Upper and lower line form the outer borders. Resistance, Midline and Support form the internal borders.

- Resistance zone spans: Upper line → Resistance.
- Support zone spans: Lower line → Support.

- If bullish lock is active:
  - (bullish) agreeing internal border is resistance, (bullish) disagreeing internal border is support.
  - (bullish) agreeing outer border is upper line, (bullish) disagreeing outer border is lower line.
- If bearish lock is active:
  - (bearish) agreeing internal border is support, (bearish) disagreeing internal border is resistance.
  - (bearish) agreeing outer border is lower line, (bearish) disagreeing outer border is upper line.

For a candle crossing a border (i.e., open is on one side of the border and close is on the opposite side):
- candle close is considered "beyond agreeing/disagreeing border" if the close is nearer to the outer border than it is to the midline.
- candle close is considered "within agreeing/disagreeing border" if the close is nearer to the midline than it is to the outer border.

Beyond and within are simply terms used to relate candle close position relative to the agreeing/disagreeing border. Distance to the outer borders or midline is irrelevant. In other terms we would say:
- "beyond (bullish) agreeing internal border" means `candle close > (bullish) agreeing internal border`, and "within (bullish) agreeing internal border" means `candle close < (bullish) agreeing internal border`.
- "beyond (bullish) disagreeing internal border" means `candle close < (bullish) disagreeing internal border`, and "within (bullish) disagreeing internal border" means `candle close > (bullish) disagreeing internal border`.

Mirror logic for (bearish) agreeing/disagreeing internal border:
- "beyond (bearish) agreeing internal border" means `candle close < (bearish) agreeing internal border`, and "within (bearish) agreeing internal border" means `candle close > (bearish) agreeing internal border`.
- "beyond (bearish) disagreeing internal border" means `candle close > (bearish) disagreeing internal border`, and "within (bearish) disagreeing internal border" means `candle close < (bearish) disagreeing internal border`.

---

Push occurs when price creates a new extreme, i.e., candle pushes upper line higher, or candle pushes lower line lower.
Push only occurs at a disagreeing outer border.
When no lock is active (e.g., at the start of the day) both outer borders are considered disagreeing. When a lock is active, there can only be one disagreeing outer border.

Push comes in two forms:
- Cross push:
    - Bullish cross push: Occurs at the upper line. Bullish candle creates the new extreme. We then monitor for the first candle to cross back within the disagreeing internal border (ie. resistance counter-cross). There should be no intervening bullish candles between the bullish cross push candle and the resistance counter-cross candle. These disrupt the push. The resistance counter-cross candle must not span more than 50% of the distance from the bullish cross push candle open and the lowest low between the bullish cross push candle and the candle that precedes it. Preliminary bearish candles that occur before the actual resistance counter-cross candle are referred to as buffers.
    - Bearish cross push: Occurs at the lower line. Bearish candle creates the new extreme. We then monitor for the first candle to cross back within the disagreeing internal border (ie. support counter-cross). There should be no intervening bearish candles between the bearish cross push candle and the support counter-cross candle. These disrupt the push. The support counter-cross candle must not span more than 50% of the distance from the bearish cross push candle open and the lowest low between the bearish cross push candle and the candle that precedes it. Preliminary bullish candles that occur before the actual support counter-cross candle are referred to as buffers.

- Counter-cross push:
    - Bullish counter-cross push: Occurs at the upper line. Bearish candle creates the new extreme. We then monitor for the first candle to cross back within the disagreeing internal border (ie. resistance counter-cross). The push candle itself may also be the resistance counter-cross candle. There should be no intervening bullish candles between the counter-cross push candle and the resistance counter-cross candle. These disrupt the push. The candle preceding the counter-cross push candle must touch the upper line. If the push candle itself fails to double as the resistance counter-cross candle, preliminary bearish candles (buffers) may occur before the actual resistance counter-cross candle.
    - Bearish counter-cross push: Occurs at the lower line. Bullish candle creates the new extreme. We then monitor for the first candle to cross back within the disagreeing internal border (ie. support counter-cross). The push candle itself may also be the support counter-cross candle. There should be no intervening bearish candles between the counter-cross push candle and the support counter-cross candle. These disrupt the push. The candle preceding the counter-cross push candle must touch the lower line. If the push candle itself fails to double as the support counter-cross candle, preliminary bullish candles (buffers) may occur before the actual support counter-cross candle.

The resistance and support counter-cross candles should be visually marked out for identification.

---

## Candle - Border interaction specifics with active locks
1. Bullish lock active
Definition of terms:
- (Bullish) Cross: occurs when a bearish candle crosses through a border and closes beneath it (ie. open >= border, close < border).
- (Bullish) Swipe: occurs when only the upper wick of a bearish candle touches the border (ie. open < border, high >= border).

Valid cross is accompanied by a valid counter-cross. The counter-cross must be visually marked out for identification.

- (Bullish) Counter-cross: occurs when a bullish candle closes above a border (ie. close >= border), after a (bullish) cross occurred at that border.
- (Bullish) Failed counter-cross: occurs when the bullish candle touches the border but fails to close above it (ie. close < border), after a (bullish) cross occurred at that border.

When a cross is disrupted, it stops being relevant.
(Bullish) Cross is disrupted when one of the following occurs before the (bullish) counter-cross:
- if another (bullish) cross or swipe occurs, the latest succeeds the former
- if a bearish float (ie. doesn't touch the border in question) candle occurs
- if a (bullish) failed counter-cross occurs

Additional notes on the (bullish) cross and (bullish) counter-cross interactions with the disagreeing internal border (support) and midline + agreeing internal border (resistance):
- disagreeing internal border (support):  after the (bullish) cross, intervening bullish float candles (buffers) may occur before the actual (bullish) counter-cross.

- midline + agreeing internal border (resistance): the candle preceding the (bullish) cross must have a higher high than the (bullish) cross. The (bullish) counter-cross must not span past 50% of the distance between the (bullish) cross open and the highest high of the candle preceding the (bullish) cross.

- Special (bullish) counter-cross push at midline: this occurs when a reverse (bullish) swipe occurs at midline, ie. a bullish candle touches the midline but opens and closes above it (`open > midline, close > midline, low <= midline`). The candle preceding this push candle must not touch the midline (low > midline).

- (Bullish) balding: occurs when a (bullish) cross has `close == low`, and (bullish) counter-cross has `open == low`. The transition is essentially a flat bottom. The two candles must occur side by side. When (bullish) cross is bald, (bullish) counter-cross must also be bald. When (bullish) counter-cross is bald, (bullish) cross must also be bald. Otherwise the cross and counter-cross are invalid, since balding must occur as a cross + counter-cross pair. Failed balding invalidates that particular border level, and no other readings can be taken from that border until the level changes. Balding is only valid if it occurs in the resistance/support zones. Midline does not recognize balding.

All valid counter-cross candles must be visually marked out for identification.

Mirror logic for bearish lock active.

---
1. Bearish lock active
Definition of terms:
- (Bearish) Cross: occurs when a bullish candle crosses through a border and closes above it (ie. open <= border, close > border).
- (Bearish) Swipe: occurs when only the lower wick of a bullish candle touches the border (ie. open > border, low <= border).

Valid cross is accompanied by a valid counter-cross. The counter-cross must be visually marked out for identification.

- (Bearish) Counter-cross: occurs when a bearish candle closes beneath a border (ie. close <= border) after a (bearish) cross occurred at that border.
- (Bearish) Failed counter-cross: occurs when the bearish candle touches the border but fails to close below it (ie. close > border) after a (bearish) cross occurred at that border.

When a cross is disrupted, it stops being relevant.
(Bearish) Cross is disrupted when one of the following occurs before the (bearish) counter-cross:
- if another (bearish) cross or swipe occurs, the latest succeeds the former
- if a bulliish float (ie. doesn't touch the border in question) candle occurs
- if a (bearish) failed counter-cross occurs

Additional notes on the (bearish) cross and (bearish) counter-cross interactions with the disagreeing internal border (resistance) and midline + agreeing internal border (support):
- disagreeing internal border (resistance):  after the (bearish) cross, intervening bearish float candles (buffers) may occur before the actual (bearish) counter-cross.

- midline + agreeing internal border (support): the candle preceding the (bearish) cross must have a lower low than the (bearish) cross. The (bearish) counter-cross must not span past 50% of the distance between the (bearish) cross open and the lowest low of the candle preceding the (bearish) cross.

- Special (bearish) counter-cross push at midline: this occurs when a reverse (bearish) swipe occurs at midline, ie. a bearish candle touches the midline but opens and closes below it (`open < midline, close < midline, high >= midline`). The candle preceding this push candle must not touch the midline (high < midline).

- (Bearish) balding: occurs when a (bearish) cross has `close == high`, and (bearish) counter-cross has `open == high`. The transition is essentially a flat top. The two candles must occur side by side. When (bearish) cross is bald, (bearish) counter-cross must also be bald. When (bearish) counter-cross is bald, (bearish) cross must also be bald. Otherwise the cross and counter-cross are invalid, since balding must occur as a cross+counter-cross pair. Failed balding invalidates that particular border level, and no other readings can be taken from that border until the level changes. Balding is only valid if it occurs in the resistance/support zones. Midline does not recognize balding.

All valid counter-cross candles must be visually marked out for identification.

---

## Border rules
Midline may overlap with resistance or support, in which case resistance and support become the only valid borders and midline is treated as practically non-existent.

Resistance and support may not overlap. If they do, we technically have no valid internal borders, since they cancel out and as a result both are treated as practically non-existent.

* A counter-cross push candle must not close through more than 2 internal borders.
* A cross push, cross, or counter-cross candle must not close through more than 1 internal border.

A candle is considered to have closed through a border when its open is on one side of the border and its close is on the opposite side.

Additionally, a cross push or cross candle must not both:

1. close through a border, and
2. touch the midline.

A candle is considered to touch the midline only when:

* the wick contacts the midline, and
* the candle body remains entirely on one side of the midline.

---

# PHASE 6
After defining how candles interact with borders during active locks, define the required behavior for contractions, BOS, and MSS.

## Partial locks when BOS or MSS occurs:
Required behaviour:
When a lock is active, (*active lock type) contractions (LH/HL, as defined in Phase 3) cause (*active lock type) BOS and MSS, if they occur beyond the corresponding agreeing internal border of that lock state. We'll refer to (*active lock type) contraction semafors in the agreeing border zone as valid (*active lock type) contractions hereafter.

When a valid (*active lock type) contraction occurs, `total_contraction + current_temp` is evaluated.
* BOS threshold is 9500
* MSS threshold is 24000

- For (bullish) contraction, `total_contraction + current_temp` <= -9500 or -24000.
- For (bearish) contraction, `total_contraction + current_temp` >= 9500 or 24000.

Check Phase 3 for why (bullish) contraction uses negative values and (bearish) contraction uses positive values.

If this evaluates to true for a semafor candle, the first candle (which can be the semafor candle itself) that closes back within the agreeing border confirms (*active lock type) BOS/MSS and triggers the drawing of a vertical solid magenta line.

With (*active lock type) BOS/MSS still active, if a candle closes beyond the disagreeing border of that lock state and closes back within the disagreeing border of that lock state, any active (*active lock type) MSS and BOS  state is reset.
Any active (*active lock type) BOS and MSS state is also reset when the opposite lock is triggered (ie. (*active lock type) BOS/MSS do not persist between lock transitions: bullish → bearish, bearish → bullish).
An active (*active lock type) MSS causes an expansion of 12000 points to trigger the opposite lock state (ie. it halves the threshold value).

Example bullish case:
Given the sequence HH1 → HH2 → LH1 → LH2, where HH2 triggers a bullish lock state. If LH2 occurs in the resistance zone, we evaluate BOS/MSS threshold. If `(bullish) total_contraction + current_temp` <= -9500 or -24000 at LH2, BOS/MSS is triggered.
A triggered BOS/MSS threshold requires confirmation exactly once. A confirmed BOS/MSS here acts as a partial bearish lock influencing resistance zone and midline. The bullish lock maintains influence of the support zone. Thus we essentially have two disagreeing border zones, and no agreeing border zones.
- If semafor candle LH2 was a bullish push candle (ie. it created a new higher high upper line), the counter-cross candle (which might be the push candle itself) must follow the bullish push rules outlined in Phase 5.
- If semafor candle LH2 was not a bullish push candle, then the counter-cross candle is simply the first candle to close back within the resistance (close < resistance).

A successful close back within resistance is what confirms BOS/MSS and a solid vertical magenta line is plotted at that counter-cross candle's bar index.
If a new level 2 high is formed before BOS/MSS is confirmed, BOS/MSS threshold triggered state is reset.
If a candle closes beyond support (ie. close < support), it has entered bullish lock administration. The first candle to close back within support (ie. close > support), resets BOS/MSS threshold triggered state. However if price continues lower, note that MSS halves the expansion threshold of 24000, therefore a lower low expansion `(bearish) total_expansion + current_temp` < -12000 will trigger a bearish lock. Bearish lock immediately resets BOS/MSS threshold triggered state.

Mirror logic for bearish lock state.

Example bearish case:
Given the sequence LL1 → LL2 → HL1 → HL2, where LL2 triggers a bearish lock state. If HL2 occurs in the support zone, we evaluate BOS/MSS threshold. If `(bearish) total_contraction + current_temp` >= 9500 or 24000 at LH2, BOS/MSS is triggered.
A triggered BOS/MSS threshold requires confirmation exactly once. A confirmed BOS/MSS here acts as a partial bullish lock influencing support zone and midline. The bearish lock maintains influence of the resistance zone. Thus we essentially have two disagreeing border zones, and no agreeing border zones.
- If semafor candle HL2 was a bearish push candle (ie. it created a new lower low lower line), the counter-cross candle (which might be the push candle itself) must follow the bearish push rules outlined in Phase 5.
- If semafor candle HL2 was not a bearish push candle, then the counter-cross candle is simply the first candle to close back within the support (close > support).

A successful close back within support is what confirms BOS/MSS and a solid vertical magenta line is plotted at that counter-cross candle's bar index.
If a new level 2 low is formed before BOS/MSS is confirmed, BOS/MSS threshold triggered state is reset.
If a candle closes beyond resistance (ie. close > resistance), it has entered bearish lock administration. The first candle to close back within resistance (ie. close < resistance), resets BOS/MSS threshold triggered state. However if price continues higher, note that MSS halves the expansion threshold of 24000, therefore a lower low expansion `(bearish) total_expansion + current_temp` > 12000 will trigger a bullish lock. Bullish lock immediately resets BOS/MSS threshold triggered state.
