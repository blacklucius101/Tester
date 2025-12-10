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

//--- Global variables for pivot and breakout logic
double lastPivotHighPrice = 0;
datetime lastPivotHighTime = 0;
int lastPivotHighIndex = -1;
bool pivotHighUsed = false;

double lastPivotLowPrice = 0;
datetime lastPivotLowTime = 0;
int lastPivotLowIndex = -1;
bool pivotLowUsed = false;

int prevSlope = 0; // 1 for up, -1 for down

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,LineBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   
   PlotIndexSetString(0, PLOT_LABEL, "Close Line");
   
   //--- Initialize global variables
   lastPivotHighPrice = 0;
   lastPivotHighTime = 0;
   lastPivotHighIndex = -1;
   pivotHighUsed = false;

   lastPivotLowPrice = 0;
   lastPivotLowTime = 0;
   lastPivotLowIndex = -1;
   pivotLowUsed = false;

   prevSlope = 0;

//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Loop through all objects on the chart
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);

      // Remove only the objects created by this indicator
      if(StringFind(name, "BreakoutLine_") == 0)
      {
         ObjectDelete(0, name);
      }
   }
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
   int start = (prev_calculated > 0) ? prev_calculated - 1 : 0;

   for(int i = start; i < rates_total; i++)
   {
      // --- Draw the colored close line (original functionality) ---
      LineBuffer[i] = close[i];
      if(i > 0)
      {
         if(close[i] > close[i-1])
            ColorBuffer[i] = 0; // Blue for up
         else if(close[i] < close[i-1])
            ColorBuffer[i] = 1; // Brown for down
         else
            ColorBuffer[i] = ColorBuffer[i-1]; // Same color for flat
      }
      else
      {
         ColorBuffer[i] = 0; // Default color
      }

      // --- New breakout logic ---
      if(i < 1) continue; // Need at least two bars to determine slope

      // 1. Determine current slope
      int currentSlope = 0;
      if(close[i] > close[i-1])
         currentSlope = 1; // Up
      else if(close[i] < close[i-1])
         currentSlope = -1; // Down

      // 2. Detect slope change and confirm pivots
      if(currentSlope != 0 && prevSlope != 0 && currentSlope != prevSlope)
      {
         // Slope changed from up to down -> Pivot High confirmed at bar i-1
         if(prevSlope == 1 && currentSlope == -1)
         {
            lastPivotHighPrice = close[i-1];
            lastPivotHighTime = time[i-1];
            lastPivotHighIndex = i-1;
            pivotHighUsed = false; // Reset the used flag for the new pivot
         }
         // Slope changed from down to up -> Pivot Low confirmed at bar i-1
         else if(prevSlope == -1 && currentSlope == 1)
         {
            lastPivotLowPrice = close[i-1];
            lastPivotLowTime = time[i-1];
            lastPivotLowIndex = i-1;
            pivotLowUsed = false; // Reset the used flag for the new pivot
         }
      }

      // Update slope for the next iteration
      if(currentSlope != 0)
      {
         prevSlope = currentSlope;
      }

      // 3. Monitor for price breakouts
      // Breakout above pivot high
      if(lastPivotHighPrice > 0 && !pivotHighUsed && close[i] > lastPivotHighPrice)
      {
         string objName = "BreakoutLine_" + (string)lastPivotHighTime + "_" + (string)time[i];
         if(ObjectFind(0, objName) < 0)
         {
            ObjectCreate(0, objName, OBJ_TREND, 0, lastPivotHighTime, lastPivotHighPrice, time[i], close[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrAqua);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, false);
         }
         pivotHighUsed = true; // Mark this pivot as used
      }

      // Breakout below pivot low
      if(lastPivotLowPrice > 0 && !pivotLowUsed && close[i] < lastPivotLowPrice)
      {
         string objName = "BreakoutLine_" + (string)lastPivotLowTime + "_" + (string)time[i];
         if(ObjectFind(0, objName) < 0)
         {
            ObjectCreate(0, objName, OBJ_TREND, 0, lastPivotLowTime, lastPivotLowPrice, time[i], close[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrMagenta);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, false);
         }
         pivotLowUsed = true; // Mark this pivot as used
      }
   }
   return(rates_total);
}
//+------------------------------------------------------------------+
