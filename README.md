Refactor the RAW_3_Level_ZZ_Semafor indicator into a Market Structure version where structure lines behave exactly like the Semafor/ZigZag — meaning the most recent leg is not confirmed and can update/repaint until a new pivot forms.

### Core Foundation
- Preserve all three ZigZag levels and existing arrow plots.
- Continue using iCustom ZigZag handles.
- Maintain current arrow rendering and inputs.
- Operate in the main chart window.

### Market Structure Requirements

#### 1. Structure Source

- Use Level 2 ZigZag (HighBuffer2 / LowBuffer2) as the structure engine.
- Every detected pivot should participate immediately in structure logic.
- Do not wait for “confirmation” beyond ZigZag behavior.

#### 2. Dynamic Structure Lines (Semafor Behavior)

Structure lines must:
- Use DRAW_COLOR_SECTION buffers.
- Connect the last pivot to the current developing pivot.
- Update in real time as the ZigZag leg extends.
- Repaint the current leg if ZigZag updates.
- Keep historical legs fixed once ZigZag shifts to a new pivot.

In other words:
- The most recent structure leg is dynamic.
- All prior legs are stable.

#### 3. Coloring Logic

For each leg:
- Green if current pivot price > previous pivot price.
- Red if current pivot price < previous pivot price.
- Color updates dynamically for the active leg.

#### 4. Descriptive Δ Labels

For each structure leg:
- Display midpoint label: Δ XXX pts
- Label color must match the leg color.
- Historical labels remain fixed.
- The active (developing) leg’s label must update dynamically as price extends.
- Use OBJ_TEXT for labels.
- Do not delete all objects each tick.
- Only update the active leg’s label; leave historical ones untouched.

#### 5. Performance Model (Critical)

The indicator must:
- Avoid full historical rescans on every tick.
- Avoid deleting and recreating all objects.
- Avoid full-buffer ArrayInitialize per tick.
- Track only:
    - Previous pivot
    - Current pivot
- Update only the developing leg in real time.
- Achieve near O(1) processing per tick.

#### 6. Rendering Rules

- Two DRAW_COLOR_SECTION plots:
    - High Structure
    - Low Structure
- Use EMPTY_VALUE for unused bars.
- No ghost sections.
- No flickering.

### Expected Final Behavior

- Structure lines visually “grow” and adjust like ZigZag.
- The last leg repaints naturally.
- Historical legs remain fixed.
- Δ labels update only for the active leg.
- Indicator remains lightweight and stable even on large histories.
