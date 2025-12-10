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
#property indicator_buffers 6
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDodgerBlue,clrBrown
//--- input parameters
input int InpFastPeriod=7;     // Fast ATR period
input int InpMiddlePeriod=14;  // Middle ATR period
input int InpSlowPeriod=28;    // Slow ATR period
input int InpFastK=4;          // Fast K
input int InpMiddleK=2;        // Middle K
input int InpSlowK=1;          // Slow K
//--- indicator buffers
double    ExtUOBuffer[];
double    ExtColorBuffer[];
double    ExtBPBuffer[];
double    ExtFastATRBuffer[];
double    ExtMiddleATRBuffer[];
double    ExtSlowATRBuffer[];
//--- indicator handles
int       ExtFastATRhandle;
int       ExtMiddleATRhandle;
int       ExtSlowATRhandle;

double    ExtDivider;
int       ExtMaxPeriod;

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
int indicatorSubwindow = -1; // To store the indicator's subwindow index

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtUOBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,ExtBPBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtFastATRBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtMiddleATRBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,ExtSlowATRBuffer,INDICATOR_CALCULATIONS);
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

   //--- Initialize pivot and breakout variables
   lastPivotHighPrice = 0;
   lastPivotHighTime = 0;
   lastPivotHighIndex = -1;
   pivotHighUsed = false;
   lastPivotLowPrice = 0;
   lastPivotLowTime = 0;
   lastPivotLowIndex = -1;
   pivotLowUsed = false;
   prevSlope = 0;

   //--- Find the indicator's subwindow
   indicatorSubwindow = ChartWindowFind();
   if(indicatorSubwindow < 0)
     {
      Print("ChartWindowFind() failed, error ", GetLastError());
     }
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, indicatorSubwindow, "BreakoutLine_");
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

      if(i > 0)
        {
         if(ExtUOBuffer[i] > ExtUOBuffer[i-1])
            ExtColorBuffer[i] = 0; // Blue for up
         else if(ExtUOBuffer[i] < ExtUOBuffer[i-1])
            ExtColorBuffer[i] = 1; // Brown for down
         else
            ExtColorBuffer[i] = ExtColorBuffer[i-1]; // Same color for flat
        }
      else
        {
         ExtColorBuffer[i] = 0; // Default color
        }

      // --- New breakout logic ---
      if(i < 1) continue; // Need at least two bars to determine slope

      // 1. Determine current slope
      int currentSlope = 0;
      if(ExtUOBuffer[i] > ExtUOBuffer[i-1])
         currentSlope = 1; // Up
      else if(ExtUOBuffer[i] < ExtUOBuffer[i-1])
         currentSlope = -1; // Down

      // 2. Detect slope change and confirm pivots
      if(currentSlope != 0 && prevSlope != 0 && currentSlope != prevSlope)
      {
         // Slope changed from up to down -> Pivot High confirmed at bar i-1
         if(prevSlope == 1 && currentSlope == -1)
         {
            lastPivotHighPrice = ExtUOBuffer[i-1];
            lastPivotHighTime = time[i-1];
            lastPivotHighIndex = i-1;
            pivotHighUsed = false; // Reset the used flag for the new pivot
         }
         // Slope changed from down to up -> Pivot Low confirmed at bar i-1
         else if(prevSlope == -1 && currentSlope == 1)
         {
            lastPivotLowPrice = ExtUOBuffer[i-1];
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
      if(lastPivotHighPrice > 0 && !pivotHighUsed && ExtUOBuffer[i] > lastPivotHighPrice)
      {
         string objName = "BreakoutLine_" + (string)lastPivotHighTime + "_" + (string)time[i];
         if(ObjectFind(0, objName) < 0)
         {
            ObjectCreate(0, objName, OBJ_TREND, indicatorSubwindow, lastPivotHighTime, lastPivotHighPrice, time[i], ExtUOBuffer[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrAqua);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, false);
         }
         pivotHighUsed = true; // Mark this pivot as used
      }

      // Breakout below pivot low
      if(lastPivotLowPrice > 0 && !pivotLowUsed && ExtUOBuffer[i] < lastPivotLowPrice)
      {
         string objName = "BreakoutLine_" + (string)lastPivotLowTime + "_" + (string)time[i];
         if(ObjectFind(0, objName) < 0)
         {
            ObjectCreate(0, objName, OBJ_TREND, indicatorSubwindow, lastPivotLowTime, lastPivotLowPrice, time[i], ExtUOBuffer[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrMagenta);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, false);
         }
         pivotLowUsed = true; // Mark this pivot as used
      }
     }
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
