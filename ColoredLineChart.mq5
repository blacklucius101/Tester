//+------------------------------------------------------------------+
//|                                             ColoredLineChart.mq5 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                              https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#property indicator_buffers 2
#property indicator_plots   1

//--- plot Line
#property indicator_label1  "Line"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDodgerBlue,clrBrown
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- indicator buffers
double         LineBuffer[];
double         ColorBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,LineBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   
   PlotIndexSetString(0, PLOT_LABEL, "Close Line");

//---
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
   for(int i = prev_calculated; i < rates_total; i++)
   {
      LineBuffer[i] = close[i];

      if(i > 0)
      {
         if(close[i] > close[i-1])
            ColorBuffer[i] = 0; // Green
         else if(close[i] < close[i-1])
            ColorBuffer[i] = 1; // Red
         else
            ColorBuffer[i] = ColorBuffer[i-1]; // Repeat previous color
      }
      else
      {
         ColorBuffer[i] = 0; // Default to green
      }
   }
   return(rates_total);
}
//+------------------------------------------------------------------+
