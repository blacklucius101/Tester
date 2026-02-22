## Goal:
The logic of the `3_Level_ZZ_Semafor.mq5` indicator is correct and must remain unchanged, but the current implementation is inefficient and causes performance issues due to full-history recalculation and repeated object deletion/recreation.

Refactor the structure drawing engine to operate in an incremental, event-driven manner with near O(1) processing per new swing, instead of O(n) per tick.

Apply the architectural optimizations while keeping the functional logic identical.

## Optimization Requirements:
1. Eliminate full-history recalculation on every tick.
- Use incremental processing based on prev_calculated.
- Only process newly formed bars or newly confirmed ZigZag swings.

2. Stop deleting and recreating all chart objects on every calculation.
- Objects should only be created when a new swing is confirmed.
- Existing objects should be updated (moved/modified) only if the latest swing repaints.

3. Remove unnecessary full-array resizing to rates_total.
- Store only confirmed swings in compact dynamic arrays.

4. Avoid copying full historical buffers repeatedly.
- Copy only the minimal required recent data after the first calculation.

5. Eliminate unnecessary calls like CopyTime() if equivalent data is already available in OnCalculate.

6. Ensure no redundant object property updates occur if nothing has changed.

7. Preserve:
- Exact visual output
- Same line connections
- Same slope color logic
- Same label text, but remove the pixel offset feature
