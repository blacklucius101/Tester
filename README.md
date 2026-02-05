## Objective:
Using the existing `ZigZag_NK_Fibo.mq5` indicator, display the point differences between consecutive high pivots and consecutive low pivots without modifying the existing market structure lines.

## Requirements:
1. Preserve the current functionality and visual appearance of market structure lines.
2. For each pair of consecutive high pivots:
    - Compute `delta = high[i] - high[i-1]`.
    - Display `delta` as a text label above the line, offset by a few pixels (e.g., 5–10 px) using `ChartTimePriceToXY` to get pixel coordinates and `ChartXYToTimePrice` to map back to chart coordinates.
3. Repeat the same for low pivots, placing the label below the line with a small pixel offset.
4.  Make sure the labels update dynamically when new bars are calculated or old bars are removed.
5.  Labels should have a unique name, e.g., `"MS_HighDelta_1"`, `"MS_LowDelta_1"`, to avoid conflicts with the existing lines.
6.  Keep all color, style, and width settings of lines unchanged.

## Suggested Steps:
- After drawing each trend line in `DrawMarketStructureLines()`:
1. Convert the midpoint of the trend line to pixel coordinates using `ChartTimePriceToXY()`.
2. Apply the desired pixel offset in X and Y (e.g., 10 px above for highs, 10 px below for lows).
3. Convert the adjusted pixel coordinates back to chart coordinates using `ChartXYToTimePrice()`.
4. Use `CreateText()` or `SetText()` to draw the delta label at the new position.

- Ensure the label displays only the point difference with correct sign (positive/negative).
- Optionally, format the delta to a fixed number of digits using `_Digits` or `NormalizeDouble()`.

## Outcome:
On the chart, each market structure line between pivots will have a corresponding label showing the exact point difference, without touching the existing lines. The labels will follow the market structure lines dynamically as the chart updates.
