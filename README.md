Analyze (Custom_Indicator.mq5) and create a concise Flow of Operation document focused on execution order.

Include:
1. The indicator's entry points (e.g., OnInit, OnCalculate, OnDeinit, timer/chart/event handlers).
2. The exact sequence in which functions are called during:
- Indicator initialization
- Each new tick / recalculation
- User interactions or events (if applicable)
- Indicator shutdown
3. A hierarchical call flow showing which functions call other functions.
4. A step-by-step execution timeline from startup to normal operation.
5. Any conditional branches that alter the execution path.

Format the output as a decision tree (pure markdown, no visual aids):

Execution Flow Overview

Startup
1. OnInit()
   - FunctionA()
   - FunctionB()

Runtime (OnCalculate)
1. OnCalculate()
   - FunctionC()
     - FunctionD()
     - FunctionE()

Shutdown
1. OnDeinit()
   - FunctionF()

Focus on actual execution order and call relationships, not code explanations. Keep the document concise and technical.
