Refactor this MQL5 Donchian Channel indicator into a simplified “pure” Donchian implementation while preserving all existing visual bands and chart appearance.

Requirements:

1. REMOVE the entire alert system

* Remove all alert-related inputs
* Remove all alert-related global variables
* Remove all alert functions, including:

  * HandleAlerts()
  * IssueAlerts()
  * HasMidLineBullishCrossing()
  * HasMidLineBearishCrossing()
  * HasCandleCloseInsideResistance()
  * HasCandleCloseInsideSupport()
  * ResetGlobalVariables()
  * RefreshGlobalVariables()
* Remove all SendMail, SendNotification, and Alert logic
* Remove all alert message strings and state tracking

2. REMOVE all multi-timeframe (MTF) support

* Remove:

  * InpTimeframe input
  * Timeframe variable
  * deltaHighTF variable
  * CopyClose() usage
  * iBarShift() usage
  * all timeframe conversion logic
  * all PERIOD_CURRENT vs higher timeframe synchronization logic
* The indicator should operate ONLY on the current chart timeframe

3. REMOVE all alternative calculation modes

* Delete ENUM_PRICE_TYPE entirely
* Remove PriceType input
* Remove all switch-case logic related to price calculation modes
* Retain ONLY the classic Donchian calculation:

  * Upper Line = highest HIGH over InpPeriod
  * Lower Line = lowest LOW over InpPeriod

4. RETAIN all 5 visual bands/lines and their visualization
   Keep:

* Upper Line
* Lower Line
* Mid Line
* Resistance
* Support

Keep:

* existing colors
* line styles
* widths
* fills/shaded zones
* DRAW_FILLING visualization
* support/resistance zone rendering

5. SIMPLIFY the calculation logic
   Use only current timeframe data arrays:

* high[]
* low[]
* open[]
* close[]

Simplify calculations to:

* Upper = highest high over period
* Lower = lowest low over period
* Mid = (Upper + Lower) / 2

Resistance and Support bands should still be calculated and rendered exactly as before, but using only current timeframe data.

6. CLEANUP

* Remove unused variables
* Remove dead code
* Remove unnecessary comments
* Preserve indicator behavior and appearance
* Preserve buffer ordering and plot rendering
* Keep the code compile-safe for MT5 strict mode

Goal:
Create a lean, readable, maintainable Donchian indicator that preserves the full visual structure while removing:

* alerts
* MTF complexity
* alternative price modes
* unnecessary abstraction

Ensure the resulting code compiles cleanly in the Metatrader 5 platform without tiggering any warnings or errors.
