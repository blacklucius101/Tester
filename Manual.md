# Custom_Indicator.mq5 - Flow of Operation

This document provides a detailed technical analysis of the actual implemented behavior of the `Custom_Indicator.mq5` file.

---

## 1. Execution Flow

### OnInit()
1.  **Indicator Setup**: Sets decimal digits to `_Digits`.
2.  **Buffer Mapping**: Maps 15 indicator buffers (0-14) using `SetIndexBuffer`.
3.  **Plot Configuration**:
    *   Plots at Indices 7-10 (Level 1 & 2 High/Low) are assigned arrow codes `L1_ARROW` (159) and `L2_ARROW` (108).
    *   Plots at Indices 11-12 (Bullish/Bearish Events) are assigned arrow codes 233 and 234.
4.  **Empty Value Initialization**:
    *   Plots 0-6 (Donchian Lines/Spans) are set to `EMPTY_VALUE`.
    *   Plots 7-12 (Arrows/Events) are set to `0.0`.
5.  **State Reset**: Calls `ResetLevelState` for `stateL1` and `stateL2`. Sets `targetDayStart` and `targetDayEnd` to `0`.

### OnCalculate()
1.  **Safety Check**: If `rates_total` is less than the maximum of (`L1_PERIOD`, `L2_PERIOD`, `InpDonchianPeriod`), calculation exits.
2.  **Current Candle Cleanup**: Buffers for `rates_total - 1` are explicitly cleared (set to `EMPTY_VALUE` or `0.0`) to ensure only closed candles show values.
3.  **Day Boundary Calculation**:
    *   `refTime` is determined by `InpHistoricalDate` (or `lastBarTime` if 0).
    *   `dayStart` and `dayEnd` are calculated for that specific 24-hour period.
4.  **Reset Handling**:
    *   If the target day has changed (`dayStart != targetDayStart`) or `prev_calculated == 0`:
        *   All 15 buffers are initialized.
        *   All chart objects with the "L2_" prefix are deleted.
        *   `stateL1` and `stateL2` are reset.
        *   `firstBarOfDay` is identified.
5.  **Chronological Loop**: Processes bars from `start_idx` to `rates_total - 2` (closed candles only).
    *   **Donchian Bands**: If `i >= InpDonchianPeriod - 1`, calculates High/Low/Resistance/Support/Mid levels using `ArrayMaximum` and `ArrayMinimum` over the `InpDonchianPeriod`.
    *   **Invalid Candle Check**: `isInvalidCandidate` is flagged if a candle contacts the outer Donchian borders (`BufferUp` or `BufferDown`) but does not qualify as a "Push" (as determined by current locks and BOS/MSS states).
    *   **ProcessLevel (L1 & L2)**: Handles semafor (Level 1/2) logic, repaint logic, expansion/contraction tracking, and L2 lock/BOS/MSS triggering.
    *   **ProcessPhase5**: Handles push events and candle-border interactions (Cross, Swipe, Counter-cross).
    *   **HandleBOSMSS**: Handles the confirmation or reset of BOS/MSS states.

### OnDeinit()
1.  **Cleanup**: Deletes all chart objects with the "L2_" prefix.

---

## 2. Data Flow

### Inputs to Calculations
*   **`InpHistoricalDate`**: Drives the `targetDayStart/End` filtering.
*   **`InpDonchianPeriod`**: Directly defines the lookback window for `BufferUp`, `BufferDown`, `BufferResistance`, `BufferSupport`, and `BufferMid`.

### Buffer Dependencies
*   **`BufferUp/Down/Mid/Resistance/Support`**: Used as dynamic price boundaries for all interaction logic.
*   **`BufferL1H/L` & `BufferL2H/L`**: Populated by `ProcessLevel`. Highs take `pHigh[idx]`, Lows take `pLow[idx]`.
*   **`BufferBullishEvents` & `BufferBearishEvents`**: Populated by:
    *   `HandlePushEvents` (Counter-cross of pushes).
    *   `ProcessInteraction` (Counter-cross of internal borders).
    *   `HandleBOSMSS` (Confirmation of BOS/MSS state).

### State Transitions
*   **Expansion/Contraction**: Summed point differences between consecutive L2 semafors.
*   **Locks**: Triggered when expansion exceeds point thresholds (24000 default).
*   **BOS/MSS**: Triggered when L2 semafors occur within specific zones (`Resistance-Up` or `Down-Support`) and point contraction exceeds thresholds (9500 for BOS, 24000 for MSS).

---

## 3. Signal Logic

### Level 1 & 2 Arrows
*   **High Arrow**: Triggered if `pHigh[idx]` is the highest high within the last `period` bars. Subject to `backstep` repaint.
*   **Low Arrow**: Triggered if `pLow[idx]` is the lowest low within the last `period` bars. Subject to `backstep` repaint.

### Bullish Event (Plot Index 11, Arrow 233)
1.  **Bearish Push Counter-cross**:
    *   Current Bearish Push is active (`bearPushState.active`). (Note: A Bearish Push is only activated if the candle *preceding* the push candle touched the lower Donchian border).
    *   Candle closes above or at Support (`close[idx] >= BufferSupport[idx]`).
    *   Must satisfy 50% retracement rule and balding rules if it was a cross-push.
    *   Must not close through more than 1 internal border (or 2 if it was the trigger candle of a counter-cross push).
2.  **Bullish Interaction (Counter-cross)**:
    *   Active Bullish Lock.
    *   Candle closes above an internal border (`res`, `mid`, or `sup`) after a "Cross" or "Swipe" was registered.
    *   Must not close through more than 1 internal border.
    *   Specific 50% and "side-by-side" rules apply if it's the `res` or `mid` border.
3.  **Midline Counter-cross Push**:
    *   Candle opens and closes above `mid`, while `low` touches or pierces `mid`, and previous `low` was above `mid`.
4.  **BOS/MSS Confirmation**:
    *   Active Bearish Lock and `BOS_MSS_TRIGGERED_...` state.
    *   Candle closes above Support (`close[idx] > BufferSupport[idx]`) and satisfies Phase 5 validation rules.

### Bearish Event (Plot Index 12, Arrow 234)
1.  **Bullish Push Counter-cross**:
    *   Current Bullish Push is active (`bullPushState.active`). (Note: A Bullish Push is only activated if the candle *preceding* the push candle touched the upper Donchian border).
    *   Candle closes below or at Resistance (`close[idx] <= BufferResistance[idx]`).
    *   Validation rules similar to Bullish Push Counter-cross (50% rule, balding, border counts).
2.  **Bearish Interaction (Counter-cross)**:
    *   Active Bearish Lock.
    *   Candle closes below an internal border (`res`, `mid`, or `sup`) after a "Cross" or "Swipe" was registered.
3.  **Midline Counter-cross Push**:
    *   Candle opens and closes below `mid`, while `high` touches or pierces `mid`, and previous `high` was below `mid`.
4.  **BOS/MSS Confirmation**:
    *   Active Bullish Lock and `BOS_MSS_TRIGGERED_...` state.
    *   Candle closes below Resistance (`close[idx] < BufferResistance[idx]`) and satisfies Phase 5 validation rules.

---

## 4. State & Memory

### LevelState Structure
The indicator maintains two instances: `stateL1` and `stateL2`. `stateL2` is the primary driver for advanced logic.

| Variable | Type | Description |
| :--- | :--- | :--- |
| `highAnchors[2]` | `SemaforAnchor` | Stores the two most recent High semafors (bar index, price, time, ID). |
| `lowAnchors[2]` | `SemaforAnchor` | Stores the two most recent Low semafors. |
| `totalExpansionBullish` | `double` | Cumulative points of consecutive rising High semafors (reset if move is negative). |
| `totalExpansionBearish` | `double` | Cumulative points of consecutive falling Low semafors (reset if move is positive). |
| `totalContractionBullish`| `double` | Cumulative points of falling High semafors during a Bullish Lock. |
| `totalContractionBearish`| `double` | Cumulative points of rising Low semafors during a Bearish Lock. |
| `bullishLock` | `bool` | True if a Bullish Lock is active. |
| `bearishLock` | `bool` | True if a Bearish Lock is active. |
| `resState`, `midState`, `supState` | `BorderState` | Tracks "Cross" or "Swipe" status for internal borders. |
| `bullPushState`, `bearPushState` | `PushState` | Tracks "Cross Push" or "Counter-Cross Push" status at outer borders. |
| `bosMssState` | `enum` | Current Phase 6 state (`NONE`, `TRIGGERED_BOS/MSS`, `CONFIRMED_BOS/MSS`). |

### State Transitions Table (L2)

| Current State | Event | Condition | New State |
| :--- | :--- | :--- | :--- |
| `bullishLock = false` | High Semafor Repaint/New | `totalExpansionBullish + current >= 24000` | `bullishLock = true` |
| `bearishLock = false` | Low Semafor Repaint/New | `totalExpansionBearish + current <= -24000` | `bearishLock = true` |
| `bearishLock = true` | High Semafor Repaint/New | `totalExpansionBullish + current >= 12000` AND `bosMssState == BOS_MSS_CONFIRMED_MSS` | `bullishLock = true`, `bearishLock = false` |
| `bullishLock = true` | High Semafor Repaint/New | `totalContractionBullish + current <= -9500` (In Zone, `!isInvalid`) | `bosMssState = BOS_MSS_TRIGGERED_BOS` |
| `bullishLock = true` | High Semafor Repaint/New | `totalContractionBullish + current <= -24000` (In Zone, `!isInvalid`) | `bosMssState = BOS_MSS_TRIGGERED_MSS` |
| `BOS_MSS_TRIGGERED_BOS` | `close[idx] < res` (Bull Lock) | `!isInvalid`, max 1 border cross | `bosMssState = BOS_MSS_CONFIRMED_BOS` |
| `BOS_MSS_TRIGGERED_MSS` | `close[idx] < res` (Bull Lock) | `!isInvalid`, max 1 border cross | `bosMssState = BOS_MSS_CONFIRMED_MSS` |
| `BOS_MSS_CONFIRMED_MSS` | `totalExpansionBearish <= -12000` | Immediate Check in `HandleBOSMSS` | `bearishLock = true`, `bullishLock = false` |
| `BOS_MSS_CONFIRMED_...` | Valid Counter-cross | Close back across disagreeing border | `bosMssState = BOS_MSS_NONE` |

---

## 5. Function Audit

### OnInit
*   **Purpose**: Indicator initialization.
*   **Inputs**: None.
*   **Outputs**: `int` (status code).
*   **Side Effects**: Maps buffers, sets plot properties, resets global states.
*   **Callers**: Terminal.

### OnCalculate
*   **Purpose**: Main calculation loop.
*   **Inputs**: Price arrays, volumes, spreads, etc.
*   **Outputs**: `int` (bars processed).
*   **Side Effects**: Populates all 15 indicator buffers, creates/updates chart objects via child functions.
*   **Callers**: Terminal.

### OnDeinit
*   **Purpose**: Cleanup on removal.
*   **Inputs**: Reason code.
*   **Outputs**: None.
*   **Side Effects**: Deletes all L2 chart objects.
*   **Callers**: Terminal.

### ProcessLevel
*   **Purpose**: Detects Level 1 and Level 2 semafors and manages L2 lock/BOS/MSS triggers.
*   **Inputs**: `idx`, `period`, `backstep`, `firstBar`, `pOpen[]`, `pHigh[]`, `pLow[]`, `pClose[]`, `pTime[]`, `state`, `bufH[]`, `bufL[]`, `isLevel2`, `isInvalid`.
*   **Outputs**: None.
*   **Side Effects**: Updates `LevelState` anchors, expansion/contraction counters, triggers locks, sets `bosMssState`, populates L1/L2 buffers.
*   **Logic**:
    1.  Scans back `period` to verify if current bar is a local extreme.
    2.  **Repaint Logic**: If current bar index is within `backstep` of the last anchor, it updates that anchor's position and price. Visuals and connections are updated.
    3.  **Expansion Tracking**: For L2, tracks cumulative points between anchors. If a move is "counter" to the expected expansion (e.g., lower High when seeking Bullish Lock), the counter resets to zero.
    4.  **Lock Logic**: If cumulative expansion exceeds 24,000 points (or 12,000 if transitioning from a Confirmed MSS), calls `TriggerBullishLock` or `TriggerBearishLock`.
    5.  **BOS/MSS Logic**: If locked, checks if new semafor (Repaint or New) occurs within the "Zone" (between `BufferResistance` and `BufferUp` for Bull Lock). If `!isInvalid` and contraction exceeds 9,500 (BOS) or 24,000 (MSS) points, `bosMssState` is updated.
*   **Callers**: `OnCalculate`.

### ProcessPhase5
*   **Purpose**: Coordinates interaction logic for internal borders and pushes.
*   **Inputs**: `idx`, price arrays, `state`, `isInvalid`.
*   **Outputs**: None.
*   **Side Effects**: Updates `bullPushState`, `bearPushState`, and interaction states via child calls.
*   **Callers**: `OnCalculate`.

### HandlePushEvents
*   **Purpose**: Implementation of outer-border push and counter-cross logic.
*   **Inputs**: `idx`, price arrays, `state`, `up`, `down`, `mid`, `res`, `sup`, `isInvalid`.
*   **Outputs**: None.
*   **Side Effects**: Updates `bullPushState`, `bearPushState`. Populates `BufferBullishEvents` and `BufferBearishEvents`.
*   **Logic**:
    1.  **Detection**: Monitors for `up > prevUp` or `down < prevDown`.
        *   **Cross Push**: Candle closes beyond previous border. Body direction must agree with push (e.g., bullish candle for upward push). Max 1 internal border crossing allowed.
        *   **Counter-Cross Push**: Reversal candle at the border. **Rule**: The immediately preceding candle must have touched the outer border (`high[idx-1] >= BufferUp[idx-1]` for bullish, `low[idx-1] <= BufferDown[idx-1]` for bearish). Body direction must disagree with push. Max 2 internal border crossings allowed for the trigger candle.
    2.  **Persistence**: If active, monitors for a "Counter-cross" (close back within internal border).
    3.  **Validation**: Enforces 50% retracement rule (low must not be < 50% of push range for bullish cross-push) and balding rules (prevents signal if either trigger or CC candle is "bald" unless side-by-side).
*   **Callers**: `ProcessPhase5`.

### ProcessInteraction
*   **Purpose**: Generic processor for internal border interactions (Cross/Swipe/Counter-cross).
*   **Inputs**: `idx`, price arrays, `bs` (BorderState), `border`, `isBullishLock`, `isAgreeing`, `state`, `toBullBuffer`, `isInvalid`.
*   **Outputs**: None.
*   **Side Effects**: Updates `BorderState`, populates event buffers.
*   **Logic**:
    1.  **Counter-cross Check**: If `bs.activeType` is set, checks if current candle closes back across `border`.
    2.  **Validation**: Checks `isInvalid`, max 1 internal border cross, and 50% distance rules (for `res/mid/sup` if `isAgreeing`).
    3.  **Balding**: Marks level as "stale" if balding rules are violated.
    4.  **Trigger Detection**: Detects "Cross" (body close) or "Swipe" (wick touch) for bearish candle in bullish lock (or bullish candle in bearish lock).
*   **Callers**: `HandleBullishInteractions`, `HandleBearishInteractions`.

### HandleBOSMSS
*   **Purpose**: Processes Phase 6 state transitions and confirmation signals.
*   **Inputs**: `idx`, price arrays, `time[]`, `state`, `isInvalid`.
*   **Outputs**: None.
*   **Side Effects**: Updates `bosMssState`, triggers locks (MSS), populates event buffers, creates `BOSMSSLine`.
*   **Logic**:
    1.  **Triggered State Disruption**: Resets `bosMssState` to `NONE` if "Evolution" occurs (semafor anchor ID remains same but bar index increases via repaint) or if a newer semafor ID is created.
    2.  **Confirmation**: Monitors for a candle closing back within the agreeing internal border.
        *   Validates using Phase 5 rules (max 1 internal border crossing, `!isInvalid`).
        *   If the trigger semafor was a push candle, applies push validation (50% retracement, balding).
        *   Failure to confirm on the *first* candle that closes back within the border results in an immediate reset to `NONE`.
    3.  **MSS Immediate Lock**: If MSS is confirmed and the counter-move already exceeds 12,000 points, immediately triggers the opposing Lock.
    4.  **Confirmed State Reset**: Monitors for a valid Phase 5 counter-cross of the *disagreeing* internal border to reset the state to `NONE`.
*   **Callers**: `OnCalculate`.

### TriggerBullishLock / TriggerBearishLock
*   **Purpose**: Transitions the indicator into a locked state.
*   **Inputs**: `state`, `barIdx`, `t`.
*   **Outputs**: None.
*   **Side Effects**: Sets `bullishLock/bearishLock`, resets expansion/contraction counters, resets all `BorderState` and `PushState` variables, draws vertical dotted line.
*   **Callers**: `ProcessLevel`, `HandleBOSMSS`.

### ResetLevelState / ResetBorderState / ResetPushState
*   **Purpose**: Resets state structures to default values.
*   **Inputs**: Reference to state structure.
*   **Outputs**: None.
*   **Side Effects**: Zeroes out all member variables.
*   **Callers**: `OnInit`, `OnCalculate`, `TriggerBullishLock`, `TriggerBearishLock`.

### IsMidlineTouch
*   **Purpose**: Specifically checks for the "Midline Touch" rule (wick contact, body on one side).
*   **Inputs**: `pOpen`, `pHigh`, `pLow`, `pClose`, `mid`.
*   **Outputs**: `bool`.
*   **Callers**: `ProcessPhase5`, `HandlePushEvents`, `ProcessInteraction`.

### IsClosedThrough
*   **Purpose**: Checks if a candle's body spans across a specific price level.
*   **Inputs**: `pOpen`, `pClose`, `border`.
*   **Outputs**: `bool`.
*   **Callers**: `ProcessPhase5`, `HandlePushEvents`, `HandleBOSMSS`, `ProcessInteraction`.

### UpdateL2Trend / UpdateL2Text / UpdateL2HighConnection / UpdateL2LowConnection
*   **Purpose**: Visualizes L2 semafor connections and point differences.
*   **Inputs**: Coordinates, prices, IDs, colors.
*   **Outputs**: None.
*   **Side Effects**: Creates or modifies `OBJ_TREND` and `OBJ_TEXT` objects on the chart.
*   **Callers**: `ProcessLevel`.

### DrawLockLine / DrawBOSMSSLine
*   **Purpose**: Draws vertical lines for significant state changes.
*   **Inputs**: Bar index, time, color, prefix.
*   **Outputs**: None.
*   **Side Effects**: Creates `OBJ_VLINE` objects.
*   **Callers**: `TriggerBullishLock`, `TriggerBearishLock`, `HandleBOSMSS`.
