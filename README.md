Consider `ZigZag NK Fibo.mq5`. Enhance the existing ZigZag / Market Structure logic so that only Higher Highs (HH) and Lower Lows (LL) display a numeric label showing the point difference from the previous corresponding pivot.

## Functional Requirements
1. HH / LL Detection
- A Higher High (HH) occurs when: `current_high > previous_high`
- A Lower Low (LL) occurs when: `current_low < previous_low`
- Do not display any measurement for:
    - Lower Highs (LH)
    - Higher Lows (HL)

2. Point Difference Calculation
- For HH: `delta_points = (current_high - previous_high) / _Point`
- For LL: `delta_points = (previous_low - current_low) / _Point`
- Display the value as an integer number of points (no decimals unless symbol precision requires it).

3. Text Object Creation
- Use OBJ_TEXT for the labels.
- One label per HH or LL pivot.
- Naming convention:
    - `MS_HH_Text_<index>`
    - `MS_LL_Text_<index>`
- Labels must be updated or recreated on recalculation, and removed on deinit.

4. Visual Anchoring (Pixel-Based)
- The label must be visually anchored just beyond the pivot price, not at the exact price.
- Use pixel offsets, not price offsets.
- Directional behavior:
    - HH → label slightly above the pivot
    - LL → label slightly below the pivot
