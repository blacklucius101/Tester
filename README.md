**Objective**: Modify the current MT5 structure engine to track only the last two pivots (highs and lows), making older pivots immutable while updating only the latest segment for new or repainting pivots.

### 1. Define Minimal Stateful Storage
- Introduce small fixed-size arrays for the latest pivots:
  - HighState[2] → holds the last two high pivots.
  - LowState[2] → holds the last two low pivots.
- Each pivot should store:
  - datetime time → pivot time
  - double price → pivot price
  - Optional: barIndex for naming objects
  - Optional: object names for trendline and label (objName, txtName)
- Only the last two pivots are mutable; older pivots are frozen.

### 2. Initialization (First Load)
- Scan all historical Level 2 ZigZag pivots.
- Draw trendlines and labels connecting all pivots.
- Populate HighState and LowState with only the last two pivots per type.
- Older segments remain drawn but will not be updated later.

### 3. Incremental Updates (Per Tick)
- Check only a recent lookback window (e.g., last 20 bars) for new pivots.
- Compare the new pivot with the last pivot in state using time, not index.
- Handle updates according to cases:
  1. Pivot exists and price changed → update the last segment.
  2. New pivot confirmed → shift state: move previous pivot to position 0, store new pivot in position 1, draw a new segment.
  3. Pivot disappeared/repainted → replace only the last segment with the new pivot.
- Always maintain only the last two pivots in mutable state.

### 4. Object Management
- Only delete and redraw the last segment and its label.
- Keep all older trendlines and labels intact.
- Trendline:
  - Use OBJ_TREND from previous pivot to latest pivot.
  - Set color according to slope (e.g., rising = green, falling = red) and dashed style.
- Label:
  - Use OBJ_TEXT at midpoint showing point difference.
  - Do not modify labels for older, immutable segments.

### 5. Time-Based Identification
- Track pivots by datetime (pivot time) and price, not bar index, because MT5 indexes shift when new candles form.
- Use time to detect whether a pivot has moved, disappeared, or is new.

### 6. Repainting Rules
- Only the latest pivot is mutable.
- The second-last pivot becomes immutable once a new pivot is confirmed.
- Old pivots are never modified, which eliminates unnecessary redraws and minimizes CPU usage.

### 7. Edge Case Handling
- Pivot moves forward by 1 candle → update only last segment.
- New pivot forms → shift state, draw new segment, leave older structures intact.
- Pivot disappears unexpectedly → replace last segment only.
- Timeframe/symbol changes → trigger full reset of state.

### 8. Performance Optimization
- Limit history scan to recent lookback to detect new pivots.
- Keep state arrays small and fixed (2 elements per type).
- Avoid full redraw of all historical pivots after initialization.

### 9. Developer Implementation Flow
1. Initialization:
- Scan all historical pivots.
- Draw trendlines/labels for full history.
- Store last two pivots in HighState and LowState.

2. Per Tick:
- Detect new pivots in lookback window.
- Compare against HighState/LowState.
- Update last segment if needed or add new segment.
- Shift state so only last two pivots are mutable.

3. Object Handling:
- Delete/redraw only the last segment and its label.
- Leave older objects untouched.

4. Frozen History:
- Older pivots and trendlines remain unchanged and immutable.
