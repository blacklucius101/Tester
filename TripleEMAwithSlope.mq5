//+------------------------------------------------------------------+
//|                                           TripleEMAwithSlope.mq5 |
//|                                      Copyright 2025, @mobilebass |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Your Name"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   3

//---- plot Fast EMA (12)
#property indicator_label1  "Fast EMA (12)"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//---- plot Medium EMA (50)
#property indicator_label2  "Medium EMA (50)"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrGreen, clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//---- plot Slow EMA (200)
#property indicator_label3  "Slow EMA (200)"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

//--- input parameters
input int InpFastMAPeriod = 12;   // Fast EMA Period (12)
input int InpMediumMAPeriod = 50; // Medium EMA Period (50)
input int InpSlowMAPeriod = 200;  // Slow EMA Period (200)
input int InpMAShift      = 0;    // Horizontal Shift

//--- indicator buffers
double ExtFastEMABuffer[];
double ExtMediumEMABuffer[];
double ExtSlowEMABuffer[];
double ExtColorBuffer[];
double ExtTempBuffer[]; // Temporary buffer for EMA calculations

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0, ExtFastEMABuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtMediumEMABuffer, INDICATOR_DATA);
   SetIndexBuffer(2, ExtColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(3, ExtSlowEMABuffer, INDICATOR_DATA);
   SetIndexBuffer(4, ExtTempBuffer, INDICATOR_CALCULATIONS);

//--- set plot labels
   PlotIndexSetString(0, PLOT_LABEL, "Fast EMA(" + IntegerToString(InpFastMAPeriod) + ")");
   PlotIndexSetString(1, PLOT_LABEL, "Medium EMA(" + IntegerToString(InpMediumMAPeriod) + ")");
   PlotIndexSetString(2, PLOT_LABEL, "Slow EMA(" + IntegerToString(InpSlowMAPeriod) + ")");

//--- set drawing empty value
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);

//--- set shift
   PlotIndexSetInteger(0, PLOT_SHIFT, InpMAShift);
   PlotIndexSetInteger(1, PLOT_SHIFT, InpMAShift);
   PlotIndexSetInteger(2, PLOT_SHIFT, InpMAShift);

//--- set draw begin
   int draw_begin = MathMax(MathMax(InpFastMAPeriod, InpMediumMAPeriod), InpSlowMAPeriod);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, draw_begin);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, draw_begin);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, draw_begin);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   //--- check for rates
   if(rates_total < MathMax(MathMax(InpFastMAPeriod, InpMediumMAPeriod), InpSlowMAPeriod))
      return(0);

   //--- calculate fast EMA (12)
   CalculateEMA(rates_total, prev_calculated, begin, price, InpFastMAPeriod, ExtFastEMABuffer);

   //--- calculate medium EMA (50)
   CalculateEMA(rates_total, prev_calculated, begin, price, InpMediumMAPeriod, ExtMediumEMABuffer);

   //--- calculate slow EMA (200)
   CalculateEMA(rates_total, prev_calculated, begin, price, InpSlowMAPeriod, ExtSlowEMABuffer);

   //--- set colors for medium EMA (50) based on slope
   for(int i = prev_calculated > 0 ? prev_calculated - 1 : 0; i < rates_total; i++)
     {
      if(i > 0)
        {
         if(ExtMediumEMABuffer[i] > ExtMediumEMABuffer[i - 1])
            ExtColorBuffer[i] = 0.0; // Green - uptrend
         else if(ExtMediumEMABuffer[i] < ExtMediumEMABuffer[i - 1])
            ExtColorBuffer[i] = 1.0; // Red - downtrend
         else
            ExtColorBuffer[i] = ExtColorBuffer[i - 1]; // Same color as previous
        }
      else
        {
         ExtColorBuffer[i] = 0.0; // Default to green for first bar
        }
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|  exponential moving average                                      |
//+------------------------------------------------------------------+
void CalculateEMA(int rates_total, int prev_calculated, int begin, const double &price[], int period, double &buffer[])
  {
   int    i, start;
   double SmoothFactor = 2.0 / (1.0 + period);

   if(prev_calculated == 0)
     {
      start = period + begin;
      buffer[begin] = price[begin];
      for(i = begin + 1; i < start; i++)
         buffer[i] = price[i] * SmoothFactor + buffer[i - 1] * (1.0 - SmoothFactor);
     }
   else
      start = prev_calculated - 1;

   for(i = start; i < rates_total && !IsStopped(); i++)
      buffer[i] = price[i] * SmoothFactor + buffer[i - 1] * (1.0 - SmoothFactor);
  }
//+------------------------------------------------------------------+
