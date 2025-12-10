//+------------------------------------------------------------------+
//| Indicator deinitialization function                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, subwindow_index, -1, "UO_Breakout_");
  }
//+------------------------------------------------------------------+
//|                                          Ultimate_Oscillator.mq5 |
//|                             Copyright 2000-2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2000-2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#include <MovingAverages.mqh>
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
//--- input parameters
input int InpFastPeriod=7;     // Fast ATR period
input int InpMiddlePeriod=14;  // Middle ATR period
input int InpSlowPeriod=28;    // Slow ATR period
input int InpFastK=4;          // Fast K
input int InpMiddleK=2;        // Middle K
input int InpSlowK=1;          // Slow K
//--- indicator buffers
double    ExtUOBuffer[];
double    ExtBPBuffer[];
double    ExtFastATRBuffer[];
double    ExtMiddleATRBuffer[];
double    ExtSlowATRBuffer[];
//--- indicator handles
int       ExtFastATRhandle;
int       ExtMiddleATRhandle;
int       ExtSlowATRhandle;

//--- Pivot and Breakout Variables
datetime lastPivotHighTime=0;
double   lastPivotHighValue=0;
bool     isPivotHighBroken=false;

datetime lastPivotLowTime=0;
double   lastPivotLowValue=0;
bool     isPivotLowBroken=false;
//---

//--- Subwindow index for drawing
int       subwindow_index = 0;
//---

double    ExtDivider;
int       ExtMaxPeriod;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtUOBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtBPBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,ExtFastATRBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtMiddleATRBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtSlowATRBuffer,INDICATOR_CALCULATIONS);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//--- set levels
   IndicatorSetInteger(INDICATOR_LEVELS,2);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,30);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,70);
//--- set maximum and minimum for subwindow
   IndicatorSetDouble(INDICATOR_MINIMUM,0);
   IndicatorSetDouble(INDICATOR_MAXIMUM,100);
//--- set first bar from which index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpSlowPeriod-1);
//--- name for DataWindow and indicator subwindow label
   string short_name=StringFormat("UOS(%d,%d,%d)",InpFastPeriod,InpMiddlePeriod,InpSlowPeriod);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);

   //--- Find the indicator's subwindow
   subwindow_index = ChartWindowFind();
   if(subwindow_index < 0)
     {
      Print("Error finding indicator subwindow, objects will be drawn on the main chart.");
      subwindow_index = 0; // Default to main chart on failure
     }
//--- get handles
   ExtFastATRhandle=iATR(Symbol(),0,InpFastPeriod);
   ExtMiddleATRhandle=iATR(Symbol(),0,InpMiddlePeriod);
   ExtSlowATRhandle=iATR(Symbol(),0,InpSlowPeriod);
//---
   ExtDivider=InpFastK+InpMiddleK+InpSlowK;
   ExtMaxPeriod=InpSlowPeriod;
   if(ExtMaxPeriod<InpMiddlePeriod)
      ExtMaxPeriod=InpMiddlePeriod;
   if(ExtMaxPeriod<InpFastPeriod)
      ExtMaxPeriod=InpFastPeriod;
  }
//+------------------------------------------------------------------+
//| Ultimate Oscillator                                              |
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
   if(rates_total<ExtMaxPeriod)
      return(0);
//--- not all data may be calculated
   int calculated=BarsCalculated(ExtFastATRhandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtFastATRhandle is calculated (",calculated," bars). Error ",GetLastError());
      return(0);
     }
   calculated=BarsCalculated(ExtMiddleATRhandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtMiddleATRhandle is calculated (",calculated," bars). Error ",GetLastError());
      return(0);
     }
   calculated=BarsCalculated(ExtSlowATRhandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtSlowATRhandle is calculated (",calculated," bars). Error ",GetLastError());
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
//--- get ATR buffers
   if(IsStopped()) // checking for stop flag
      return(0);
   if(CopyBuffer(ExtFastATRhandle,0,0,to_copy,ExtFastATRBuffer)<=0)
     {
      Print("getting ExtFastATRhandle is failed! Error ",GetLastError());
      return(0);
     }
   if(IsStopped()) // checking for stop flag
      return(0);
   if(CopyBuffer(ExtMiddleATRhandle,0,0,to_copy,ExtMiddleATRBuffer)<=0)
     {
      Print("getting ExtMiddleATRhandle is failed! Error ",GetLastError());
      return(0);
     }
   if(IsStopped()) // checking for stop flag
      return(0);
   if(CopyBuffer(ExtSlowATRhandle,0,0,to_copy,ExtSlowATRBuffer)<=0)
     {
      Print("getting ExtSlowATRhandle is failed! Error ",GetLastError());
      return(0);
     }
//--- preliminary calculations
   int i,start;
   if(prev_calculated==0)
     {
      ExtBPBuffer[0]=0.0;
      ExtUOBuffer[0]=0.0;
      //--- set value for first InpSlowPeriod bars
      for(i=1; i<=InpSlowPeriod; i++)
        {
         ExtUOBuffer[i]=0.0;
         double true_low=MathMin(low[i],close[i-1]);
         ExtBPBuffer[i]=close[i]-true_low;
        }
      //--- now we are going to calculate from start index in main loop
      start=InpSlowPeriod+1;
     }
   else
      start=prev_calculated-1;
//--- the main loop of calculations
   for(i=start; i<rates_total && !IsStopped(); i++)
     {
      double true_low=MathMin(low[i],close[i-1]);
      ExtBPBuffer[i]=close[i]-true_low;           // buying pressure

      if(ExtFastATRBuffer[i]!=0.0 &&
         ExtMiddleATRBuffer[i]!=0.0 &&
         ExtSlowATRBuffer[i]!=0.0)
        {
         double raw_uo=InpFastK*SimpleMA(i,InpFastPeriod,ExtBPBuffer)/ExtFastATRBuffer[i]+
                       InpMiddleK*SimpleMA(i,InpMiddlePeriod,ExtBPBuffer)/ExtMiddleATRBuffer[i]+
                       InpSlowK*SimpleMA(i,InpSlowPeriod,ExtBPBuffer)/ExtSlowATRBuffer[i];
         ExtUOBuffer[i]=raw_uo/ExtDivider*100;
        }
      else
         ExtUOBuffer[i]=ExtUOBuffer[i-1]; // set current Ultimate value as previous Ultimate value
     }
//--- OnCalculate done. Return new prev_calculated.
   int start_breakout_bar;
   if(prev_calculated == 0)
      start_breakout_bar = InpSlowPeriod + 1;
   else
      start_breakout_bar = prev_calculated - 1;

//--- Breakout detection logic starts here
   for(int i = start_breakout_bar; i < rates_total; i++)
     {
      //--- Skip the most recent bars to avoid repainting pivots
      if(i >= rates_total - 1)
         continue;

      //--- Pivot High Detection: Slope changes from up to down
      if(ExtUOBuffer[i-1] < ExtUOBuffer[i] && ExtUOBuffer[i] > ExtUOBuffer[i+1])
        {
         lastPivotHighValue = ExtUOBuffer[i];
         lastPivotHighTime = time[i];
         isPivotHighBroken = false; // Reset breakout flag for the new pivot
        }

      //--- Pivot Low Detection: Slope changes from down to up
      if(ExtUOBuffer[i-1] > ExtUOBuffer[i] && ExtUOBuffer[i] < ExtUOBuffer[i+1])
        {
         lastPivotLowValue = ExtUOBuffer[i];
         lastPivotLowTime = time[i];
         isPivotLowBroken = false; // Reset breakout flag for the new pivot
        }

      //--- Breakout Above Last Pivot High
      if(lastPivotHighTime != 0 && !isPivotHighBroken && ExtUOBuffer[i] > lastPivotHighValue)
        {
         string object_name = "UO_Breakout_" + (string)lastPivotHighTime + "_" + (string)time[i];
         if(ObjectFind(0, object_name) < 0)
           {
            ObjectCreate(0, object_name, OBJ_TREND, subwindow_index, lastPivotHighTime, lastPivotHighValue, time[i], ExtUOBuffer[i]);
            ObjectSetInteger(0, object_name, OBJPROP_COLOR, clrAqua);
            ObjectSetInteger(0, object_name, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, object_name, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, object_name, OBJPROP_RAY_RIGHT, true);
           }
         isPivotHighBroken = true; // Mark pivot as used
        }

      //--- Breakout Below Last Pivot Low
      if(lastPivotLowTime != 0 && !isPivotLowBroken && ExtUOBuffer[i] < lastPivotLowValue)
        {
         string object_name = "UO_Breakout_" + (string)lastPivotLowTime + "_" + (string)time[i];
         if(ObjectFind(0, object_name) < 0)
           {
            ObjectCreate(0, object_name, OBJ_TREND, subwindow_index, lastPivotLowTime, lastPivotLowValue, time[i], ExtUOBuffer[i]);
            ObjectSetInteger(0, object_name, OBJPROP_COLOR, clrMagenta);
            ObjectSetInteger(0, object_name, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, object_name, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, object_name, OBJPROP_RAY_RIGHT, true);
           }
         isPivotLowBroken = true; // Mark pivot as used
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
