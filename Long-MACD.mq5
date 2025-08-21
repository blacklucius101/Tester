//+------------------------------------------------------------------+
//|                                                    Long-MACD.mq5 |
//|                             Copyright 2000-2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2000-2025, MetaQuotes Ltd."
#property link        "https://www.mql5.com"
#property description "MACD with color change"
#include <MovingAverages.mqh>

//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   2
#property indicator_color1  clrDarkGray,clrDeepSkyBlue,clrDarkOrange,clrGreen,clrLime,clrOrange,clrCrimson
#property indicator_width1  2
#property indicator_color2  clrRed,clrLime  // Added clrLime for when MACD is above signal
#property indicator_width2  1
#property indicator_label2  "Signal"

//--- input parameters
input int                InpFastEMA=12;               // Fast EMA period
input int                InpSlowEMA=26;               // Slow EMA period
input int                InpSignalSMA=9;              // Signal SMA period
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE; // Applied price
input bool               ShowAsHistogram=false;       // Show as histogram

//--- indicator buffers
double MACDLineBuffer[];
double ColorBuffer[];
double ExtSignalBuffer[];
double SignalColorBuffer[];  // New buffer for signal line colors
double ExtFastMaBuffer[];
double ExtSlowMaBuffer[];

int    ExtFastMaHandle;
int    ExtSlowMaHandle;

//--- indicator initialization function
void OnInit()
  {
//--- Set plot properties based on ShowAsHistogram input
   if(ShowAsHistogram)
     {
      PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_COLOR_HISTOGRAM);
      PlotIndexSetString(0,PLOT_LABEL,"MACD Histogram");
     }
   else
     {
      PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_COLOR_LINE);
      PlotIndexSetString(0,PLOT_LABEL,"MACD Line");
     }

//--- indicator buffers mapping
   SetIndexBuffer(0,MACDLineBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,ExtSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,SignalColorBuffer,INDICATOR_COLOR_INDEX);  // New buffer for signal line colors
   SetIndexBuffer(4,ExtFastMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,ExtSlowMaBuffer,INDICATOR_CALCULATIONS);

//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpSlowEMA-1); // For MACD Line/Histogram
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN, (InpSlowEMA-1)+(InpSignalSMA-1)); // For Signal Line
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_COLOR_LINE);  // Changed to color line
   PlotIndexSetInteger(1,PLOT_LINE_COLOR,0,clrRed);  // Default color when MACD is below
   PlotIndexSetInteger(1,PLOT_LINE_COLOR,1,clrLime); // Color when MACD is above

//--- name for indicator subwindow label
   string short_name=StringFormat("MACD(%d,%d,%d) %s",InpFastEMA,InpSlowEMA,InpSignalSMA,ShowAsHistogram?"Histogram":"Line");
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);

//--- get MA handles
   ExtFastMaHandle=iMA(NULL,0,InpFastEMA,0,MODE_EMA,InpAppliedPrice);
   ExtSlowMaHandle=iMA(NULL,0,InpSlowEMA,0,MODE_EMA,InpAppliedPrice);
  }

//--- Moving Averages Convergence/Divergence calculation
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
//--- calculate MACD, Signal, and Color
   int start;
   if(prev_calculated==0)
      start=0;
   else
      start=prev_calculated-1;

//--- calculate values
   for(int i=start; i<rates_total && !IsStopped(); i++)
     {
      MACDLineBuffer[i]=ExtFastMaBuffer[i]-ExtSlowMaBuffer[i];

      // Calculate ExtSignalBuffer[i] using SMA on MACDLineBuffer
      if (i >= macdDrawBeginIndex + InpSignalSMA - 1)
        {
         double sum = 0;
         for (int k = 0; k < InpSignalSMA; k++)
           {
            sum += MACDLineBuffer[i-k];
           }
         ExtSignalBuffer[i] = sum / InpSignalSMA;
         
         // Set signal line color based on MACD position
         if (MACDLineBuffer[i] > ExtSignalBuffer[i])
            SignalColorBuffer[i] = 1; // MACD above signal - use clrLime
         else
            SignalColorBuffer[i] = 0; // MACD below signal - use clrRed
        }
      else
        {
         ExtSignalBuffer[i] = EMPTY_VALUE;
         SignalColorBuffer[i] = 0; // Default color
        }

      // Original color calculation logic for MACD line
      if (i < macdDrawBeginIndex) 
        {
         // Points before PLOT_DRAW_BEGIN for MACD line
        }
      else if (i == macdDrawBeginIndex)
        {
         ColorBuffer[i] = 0; // Neutral color (clrDarkGray)
        }
      else
        {
         if (i < signalLineStartIndex)
           {
            if (MACDLineBuffer[i] > MACDLineBuffer[i-1])
               ColorBuffer[i] = 1; // Basic Up (clrDeepSkyBlue)
            else if (MACDLineBuffer[i] < MACDLineBuffer[i-1])
               ColorBuffer[i] = 2; // Basic Down (clrDarkOrange)
            else
               ColorBuffer[i] = ColorBuffer[i-1];
           }
         else
           {
            if (MACDLineBuffer[i] > MACDLineBuffer[i-1])
              {
               if (MACDLineBuffer[i] > ExtSignalBuffer[i])
                  ColorBuffer[i] = 3; // MACD Up & Above Signal (clrGreen)
               else
                  ColorBuffer[i] = 4; // MACD Up & Below Signal (clrLime)
              }
            else if (MACDLineBuffer[i] < MACDLineBuffer[i-1])
              {
               if (MACDLineBuffer[i] > ExtSignalBuffer[i])
                  ColorBuffer[i] = 5; // MACD Down & Above Signal (clrOrange)
               else
                  ColorBuffer[i] = 6; // MACD Down & Below Signal (clrCrimson)
              }
            else
              {
               ColorBuffer[i] = ColorBuffer[i-1]; 
              }
           }
        } 
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
