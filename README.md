Modify the `RAW_3_Level_ZZ_Semafor.mq5` indicator to visualize market structure lines for Level 2 highs and lows. Use the existing HighBuffer2[] and LowBuffer2[] buffers. Each consecutive pair of non-empty points in these buffers should be connected by a line to show the historical market structure.

Requirements:
1. Maintain the original Semafor arrows for Level 2 highs and lows.
2. Add additional plots using DRAW_SECTION for Level 2 highs and lows, so lines connect all consecutive points historically.
3. Lines should be styled distinctly (color: dodger blue, style: dashed) and do not affect CPU performance significantly.
4. Ensure lines correctly ignore bars with no Level 2 high/low (EMPTY_VALUE).
5. Keep the rest of the indicator (Level 1/3 arrows, buffers) unchanged.
