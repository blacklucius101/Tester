//+------------------------------------------------------------------+
//|                                          MACD_ColorSlope.mq5 |
//|                             Copyright 2000-2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2000-2025, MetaQuotes Ltd."
#property link        "https://www.mql5.com"
#property description "MACD with color change on slope"
#include <MovingAverages.mqh>
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   2
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrDeepSkyBlue,clrDarkOrange,clrGreen,clrLime,clrOrange,clrCrimson
#property indicator_width1  2
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_width2  1
#property indicator_label2  "Signal"
#property indicator_label1  "MACD Slope"
//--- input parameters
input int                InpFastEMA=12;               // Fast EMA period
input int                InpSlowEMA=26;               // Slow EMA period
input int                InpSignalSMA=9;              // Signal SMA period
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE; // Applied price
//--- indicator buffers
double MACDLineBuffer[];
double ColorBuffer[];
double ExtSignalBuffer[];
double ExtFastMaBuffer[];
double ExtSlowMaBuffer[];

int    ExtFastMaHandle;
int    ExtSlowMaHandle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,MACDLineBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,ExtSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtFastMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtSlowMaBuffer,INDICATOR_CALCULATIONS);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpSlowEMA-1); // For MACD Line
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN, (InpSlowEMA-1)+(InpSignalSMA-1)); // For Signal Line
//--- name for indicator subwindow label
   string short_name=StringFormat("MACD Slope(%d,%d,%d)",InpFastEMA,InpSlowEMA,InpSignalSMA);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- get MA handles
   ExtFastMaHandle=iMA(NULL,0,InpFastEMA,0,MODE_EMA,InpAppliedPrice);
   ExtSlowMaHandle=iMA(NULL,0,InpSlowEMA,0,MODE_EMA,InpAppliedPrice);
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
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
   if(rates_total < InpSlowEMA)
      return(0);

   const int macdDrawBeginIndex = InpSlowEMA-1; 
   const int signalLineStartIndex = macdDrawBeginIndex + InpSignalSMA-1; 

//--- not all data may be calculated
   int calculated=BarsCalculated(ExtFastMaHandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtFastMaHandle is calculated (",calculated," bars). Error ",GetLastError());
      return(0);
     }
   calculated=BarsCalculated(ExtSlowMaHandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtSlowMaHandle is calculated (",calculated," bars). Error ",GetLastError());
      return(0);
     }
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0)
      to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0)
         to_copy++;
     }
//--- get Fast EMA buffer
   if(IsStopped()) // checking for stop flag
      return(0);
   if(CopyBuffer(ExtFastMaHandle,0,0,to_copy,ExtFastMaBuffer)<=0)
     {
      Print("Getting fast EMA is failed! Error ",GetLastError());
      return(0);
     }
//--- get SlowSMA buffer
   if(IsStopped()) // checking for stop flag
      return(0);
   if(CopyBuffer(ExtSlowMaHandle,0,0,to_copy,ExtSlowMaBuffer)<=0)
     {
      Print("Getting slow SMA is failed! Error ",GetLastError());
      return(0);
     }
//---
   int start;
   if(prev_calculated==0)
      start=0;
   else
      start=prev_calculated-1;

//--- calculate MACD, Signal, and Color
   for(int i=start; i<rates_total && !IsStopped(); i++)
     {
      MACDLineBuffer[i]=ExtFastMaBuffer[i]-ExtSlowMaBuffer[i];

      // Calculate ExtSignalBuffer[i] using SMA on MACDLineBuffer
      if (i >= macdDrawBeginIndex + InpSignalSMA - 1) // or i >= signalLineStartIndex
        {
         double sum = 0;
         for (int k = 0; k < InpSignalSMA; k++)
           {
            sum += MACDLineBuffer[i-k];
           }
         ExtSignalBuffer[i] = sum / InpSignalSMA;
        }
      else
        {
         ExtSignalBuffer[i] = EMPTY_VALUE;
        }

      // Color calculation logic
      if (i < macdDrawBeginIndex) 
        {
         // Points before PLOT_DRAW_BEGIN for MACD line. 
         // No explicit color needed. ColorBuffer[i] can remain uninitialized or set to EMPTY_VALUE if desired.
        }
      else if (i == macdDrawBeginIndex) // First bar of the MACD line that will be drawn
        {
         ColorBuffer[i] = 0; // Neutral color (clrDarkGray)
        }
      else // i > macdDrawBeginIndex, so MACDLineBuffer[i-1] is a valid, previously calculated MACD value
        {
         if (i < signalLineStartIndex) // Signal line data is not yet reliable for comparison
           {
            // Use basic slope coloring for MACD line
            if (MACDLineBuffer[i] > MACDLineBuffer[i-1])
               ColorBuffer[i] = 1; // Basic Up (clrDeepSkyBlue)
            else if (MACDLineBuffer[i] < MACDLineBuffer[i-1])
               ColorBuffer[i] = 2; // Basic Down (clrDarkOrange)
            else // Slope is Flat
               ColorBuffer[i] = ColorBuffer[i-1]; // Maintain previous color (or 0 if prev was first point)
           }
         else // Signal line data IS reliable (i >= signalLineStartIndex)
           {
            // Use detailed coloring based on slope and relation to signal line
            if (MACDLineBuffer[i] > MACDLineBuffer[i-1]) // MACD Slope is Up
              {
               if (MACDLineBuffer[i] > ExtSignalBuffer[i])
                  ColorBuffer[i] = 3; // MACD Up & MACD Above Signal (clrGreen)
               else // MACDLineBuffer[i] <= ExtSignalBuffer[i]
                  ColorBuffer[i] = 4; // MACD Up & MACD At/Below Signal (clrLime)
              }
            else if (MACDLineBuffer[i] < MACDLineBuffer[i-1]) // MACD Slope is Down
              {
               if (MACDLineBuffer[i] > ExtSignalBuffer[i])
                  ColorBuffer[i] = 5; // MACD Down & MACD Above Signal (clrChocolate)
               else // MACDLineBuffer[i] <= ExtSignalBuffer[i]
                  ColorBuffer[i] = 6; // MACD Down & MACD At/Below Signal (clrRed)
              }
            else // MACD Slope is Flat
              {
                // If flat, try to maintain previous color segment if possible, 
                // or use neutral if previous was also flat or different context.
                // For simplicity, can use neutral or try to derive from current MACD vs Signal state.
                // Let's keep it simple: if flat, use neutral, or check MACD vs Signal for a "flat but above/below signal" color.
                // For now, let's use the previous color, assuming it was set based on a trend.
                // Or, more robustly for flat:
                if (ExtSignalBuffer[i] != EMPTY_VALUE) { // Check if signal is valid
                    if (MACDLineBuffer[i] > ExtSignalBuffer[i]) ColorBuffer[i] = 3; // Flat but above signal (Green)
                    else if (MACDLineBuffer[i] < ExtSignalBuffer[i]) ColorBuffer[i] = 6; // Flat but below signal (Red)
                    else ColorBuffer[i] = 0; // Flat and on signal (Neutral)
                } else {
                    ColorBuffer[i] = 0; // Flat, signal not ready (Neutral)
                }
                // Simpler: ColorBuffer[i] = ColorBuffer[i-1]; (if prev color is meaningful)
                // Or even just ColorBuffer[i] = 0; (Neutral for any flat) - this is safest for now.
                // Let's stick to the original "ColorBuffer[i] = ColorBuffer[i-1];" for flat sections.
                 ColorBuffer[i] = ColorBuffer[i-1]; 
              }
           }
        }
     }
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
