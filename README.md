## OBJECTIVE
Extend the existing indicator by:
- Using Level 2 only (HighBuffer2, LowBuffer2)
- Drawing market structure lines:
    - High → previous High
    - Low → previous Low
- Displaying point differences between consecutive same-type swings
- Not modifying or interfering with any existing semafor logic
- Adding functionality only

## DEVELOPMENT PASS 1 — Core Feature Build
### PHASE 1 — Swing Extraction (Level 2 Only)
Add a swing extraction layer that scans only:
- HighBuffer2
- LowBuffer2

Requirements:
- Ignore Level 1 and Level 3 buffers completely
- Do not modify any existing buffer logic
- Identify confirmed swings where buffer value != 0
- Build two arrays:
    - HighSwings[]
    - LowSwings[]
- Each swing must store:
    - Bar index
    - Time
    - Price

Swings must be ordered chronologically (oldest → newest).
No drawing yet.

## PHASE 2 — Structure Line Engine
Using HighSwings[] and LowSwings[]:
Draw market structure lines:
- Connect each High to the previous High
- Connect each Low to the previous Low
- Never connect High to Low

Requirements:
- Use OBJ_TREND objects
- No ray extension
- Object name prefixes:
    - "MS_H_"
    - "MS_L_"
- Each connection must have unique name index
- Do not modify arrow plots

Visual rules:
- Color: Lime for High lines, Red for Low lines
- Style: Dash

## PHASE 3 — Point Difference Calculation
For each consecutive pair:

Calculate:
`Points = abs(CurrentPrice - PreviousPrice) / _Point`

Requirements:
- Store as integer
- Format as: "Δ XXX pts"
- Calculation must occur before drawing label

## PHASE 4 — Label Rendering
For every structure line:
Create a text label showing point difference.

Requirements:
- Use OBJ_TEXT
- Position at midpoint of the line
- High connections: Place slightly above midpoint
- Low connections: Place slightly below midpoint
- Object name prefixes:
    - "MS_H_TXT_"
    - "MS_L_TXT_"
- Text color matches line color
- Small readable font

Do not interfere with arrows.

## PHASE 5 — Safe Object Lifecycle Management
ZigZag repaints — structure must rebuild safely.

At the beginning of OnCalculate:
- Delete all objects whose names start with:
    - "MS_H_"
    - "MS_L_"

Requirements:
- Do not delete other chart objects
- Rebuild structure fresh each recalculation
- Keep logic isolated from buffer calculations

This guarantees stability.

