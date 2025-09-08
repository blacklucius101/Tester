//+------------------------------------------------------------------+
//|                                     MACD_Cloud_Color_Bars.mq5    |
//|                                                          Jules   |
//|                                                                  |
//| Colors bars/candles based on the MACD cloud color.               |
//|                                       |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 5 // Open, High, Low, Close, ColorIndex
#property indicator_plots   1
#property version           "1.0"
#property description       "Colors bars based on MACD cloud"
#property copyright         "Jules"

//---- Input parameters for MACD
input group              "MACD Settings"
input int                InpFastEMA      = 12;          // Fast EMA period
input int                InpSlowEMA      = 26;          // Slow EMA period
input int                InpSignalSMA    = 9;           // Signal SMA period
input ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_CLOSE; // Applied price for MACD

//---- Global buffers for price plotting
double priceOpen[];
double priceHigh[];
double priceLow[];
double priceClose[];
double colorIndex[];

//---- MACD Handle
int macdHandle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Set up indicator buffers
   SetIndexBuffer(0, priceOpen, INDICATOR_DATA);
   SetIndexBuffer(1, priceHigh, INDICATOR_DATA);
   SetIndexBuffer(2, priceLow, INDICATOR_DATA);
   SetIndexBuffer(3, priceClose, INDICATOR_DATA);
   SetIndexBuffer(4, colorIndex, INDICATOR_COLOR_INDEX);
   
   //--- Set drawing style to color candles
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_COLOR_CANDLES);
   
   //--- Set colors for different signal types
   PlotIndexSetInteger(0, PLOT_COLOR_INDEXES, 2);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, clrLime);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 1, clrDeepPink);
   
   //--- Set empty value
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   
   //--- Set indicator name
   string short_name = StringFormat("MACD Cloud Clr (%d,%d,%d)", 
                                    InpFastEMA, InpSlowEMA, InpSignalSMA);
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);
   PlotIndexSetString(0, PLOT_LABEL, "MACD Cloud Colored Bars");

   //--- Get MACD handle
   macdHandle = iMACD(_Symbol, _Period, InpFastEMA, InpSlowEMA, InpSignalSMA, InpAppliedPrice);
   if(macdHandle == INVALID_HANDLE)
   {
      Print("Error getting MACD handle");
      return(INIT_FAILED);
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int min_rates = InpSlowEMA + InpSignalSMA;
   if(rates_total < min_rates)
      return(0);

   //--- Copy price data to our buffers
   ArraySetAsSeries(priceOpen, true);
   ArraySetAsSeries(priceHigh, true);
   ArraySetAsSeries(priceLow, true);
   ArraySetAsSeries(priceClose, true);
   ArraySetAsSeries(colorIndex, true);
   
   ArrayCopy(priceOpen, open, 0, 0, rates_total);
   ArrayCopy(priceHigh, high, 0, 0, rates_total);
   ArrayCopy(priceLow, low, 0, 0, rates_total);
   ArrayCopy(priceClose, close, 0, 0, rates_total);

   //--- Define MACD buffers
   double macdMain[], macdSignal[];
   
   ArraySetAsSeries(macdMain, true);
   ArraySetAsSeries(macdSignal, true);
   
   //--- Copy MACD data
   if(CopyBuffer(macdHandle, MAIN_LINE, 0, rates_total, macdMain) <= 0)
      return(0);
   if(CopyBuffer(macdHandle, SIGNAL_LINE, 0, rates_total, macdSignal) <= 0)
      return(0);

   //--- Set start position for calculations
   int start_pos = prev_calculated - 1;
   if(start_pos < 0)
      start_pos = 0;
      
   if(prev_calculated == 0)
      start_pos = rates_total - min_rates -1;

   //--- Generate color signals
   for(int i = start_pos; i >= 0; i--)
   {
      if(macdMain[i] > macdSignal[i])
         colorIndex[i] = 0; // Lime
      else
         colorIndex[i] = 1; // DeepPink
   }

   return(rates_total);
}
