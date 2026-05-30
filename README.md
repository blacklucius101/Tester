Modify `Donchian_Bands.mq5` to operate as a Daily Session Donchian indicator.

Requirements:

* Users can specify a historical date using input datetime. Default is to use the current day.
* Detect the first candle of each new trading day using broker/server time.
* At the first candle of a new day, start a new Donchian session.
* For that first candle, calculate the bands using the previous `InpPeriod` candles immediately preceding the day's first candle.
* Do not wait for `InpPeriod` candles to form within the new day before generating values.
* Process candles sequentially in chronological order on candle close, using a rolling lookback window ending at the current candle.
* Each candle's values must be based only on data available up to and including that candle (no look-ahead bias).

Daily reset behavior:

* When a new trading day begins, completely remove all Donchian plots, support/resistance lines, and filled spans from the previous day.
* Only the current trading day's session should be visible on the chart.
* All buffers belonging to previous days and future days must be set to `EMPTY_VALUE`.

Calculations:

* Upper Line = highest high of the lookback window.
* Lower Line = lowest low of the lookback window.
* Resistance = highest low of the lookback window.
* Support = lowest high of the lookback window.
* Mid Line = (Upper + Lower) / 2.

Performance:

* Do not calculate or maintain Donchian values for the entire chart history.
* Restrict calculations to the current trading day only.
* Recalculate only the active daily session as new candles close.
* Preserve all existing plot styles, colors, widths, labels, and filling behavior.
* Provide the complete updated MQL5 source code.
