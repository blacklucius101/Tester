//+------------------------------------------------------------------+
//|                              RegimeID_MOD_3_Level_ZZ_Semafor.mq5 |
//|                                      Copyright 2000, asystem2000 |
//|                                            asystem2000@yandex.ru |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "2000, asystem2000"
//---- link to the author's website
#property link      "asystem2000@yandex.ru"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- six buffers are used for calculation and drawing the indicator
#property indicator_buffers 6
//---- six plots are used
#property indicator_plots   6
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- use light aqua color for level 1
#property indicator_color1  clrAqua
//---- thickness of the indicator line is equal to 1
#property indicator_width1  1
//---- displaying the indicator bullish symbol label
#property indicator_label1  "Low1"
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a symbol
#property indicator_type2   DRAW_ARROW
//---- use light magenta color for level 1
#property indicator_color2  clrMagenta
//---- thickness of the indicator 2 line is equal to 1
#property indicator_width2  1
//---- displaying the indicator bearish symbol label
#property indicator_label2 "High1"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 3 as a symbol
#property indicator_type3 DRAW_ARROW
//---- medium aqua color for level 2
#property indicator_color3  clrDodgerBlue
//---- thickness of the indicator line 3 is equal to 1
#property indicator_width3  1
//---- displaying the indicator bullish symbol label
#property indicator_label3  "Low2"
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 4 as a symbol
#property indicator_type4 DRAW_ARROW
//---- medium magenta color for level 2
#property indicator_color4 clrDarkOrchid
//---- thickness of the indicator line 4 is equal to 1
#property indicator_width4  1
//---- displaying the indicator bearish symbol label
#property indicator_label4 "High2"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 5 as a symbol
#property indicator_type5 DRAW_ARROW
//---- dark aqua color for level 3
#property indicator_color5 clrDarkBlue 
//---- thickness of the indicator line 5 is equal to 1
#property indicator_width5  1
//---- displaying the indicator bullish symbol label
#property indicator_label5  "Low3"
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 6 as a symbol
#property indicator_type6 DRAW_ARROW
//---- dark magenta color for level 3
#property indicator_color6 clrPurple
//---- thickness of the indicator line 4 is equal to 1
#property indicator_width6  1
//---- displaying of the bearish label of the indicator
#property indicator_label6 "High3"
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int Period1=5;
input int Deviation1=1;
input int Backstep1=3;
input int HighSymbol1=159;
input int LowSymbol1=159;

input int Period2=13;
input int Deviation2=8;
input int Backstep2=5;
input int HighSymbol2=108;
input int LowSymbol2=108;

input int Period3=34;
input int Deviation3=21;
input int Backstep3=12;
input int HighSymbol3=163;
input int LowSymbol3=163;
input int PixelOffset=-8; // Offset for arrows in pixels

//+------------------------------------------------------------------+
//|  Expansion Engine Constants                                      |
//+------------------------------------------------------------------+
#define EXP_THRESHOLD 24000.0
#define GV_PREFIX "M3LZZ_EXP_"

//+------------------------------------------------------------------+
//|  Market Structure Structures                                     |
//+------------------------------------------------------------------+
struct SwingInfo
  {
   int               barIndex;
   datetime          time;
   double            price;
  };

//+----------------------------------------------+
//---- declaration of dynamic arrays that
// will be used as indicator buffers
double HighBuffer1[],LowBuffer1[];
double HighBuffer2[],LowBuffer2[];
double HighBuffer3[],LowBuffer3[];
//---- market structure swing storage
static SwingInfo HighState[2], LowState[2];
//---- declaration of the integer variables for the start of data calculation
int StartBar1,StartBar2,StartBar3,StartBar;
//---- expansion engine state
static double stored_high = 0;
static double current_high = 0;
static double stored_contraction_high = 0;
static bool lock_bullish = false;

static double stored_low = 0;
static double current_low = 0;
static double stored_contraction_low = 0;
static bool lock_bearish = false;

static datetime last_broker_day = 0;
//---- declaration of variables for storing indicators handles
int Handle1,Handle2,Handle3;
//+------------------------------------------------------------------+
//|  Global Variable Management                                      |
//+------------------------------------------------------------------+
void SyncGlobalVariables()
  {
   GlobalVariableSet(GV_PREFIX + "STORED_HIGH", stored_high);
   GlobalVariableSet(GV_PREFIX + "CURRENT_HIGH", current_high);
   GlobalVariableSet(GV_PREFIX + "CONTRACTION_HIGH", stored_contraction_high);
   GlobalVariableSet(GV_PREFIX + "LOCK_BULLISH", (double)lock_bullish);
   GlobalVariableSet(GV_PREFIX + "STORED_LOW", stored_low);
   GlobalVariableSet(GV_PREFIX + "CURRENT_LOW", current_low);
   GlobalVariableSet(GV_PREFIX + "CONTRACTION_LOW", stored_contraction_low);
   GlobalVariableSet(GV_PREFIX + "LOCK_BEARISH", (double)lock_bearish);
  }

void DeleteGlobalVariables()
  {
   GlobalVariableDel(GV_PREFIX + "STORED_HIGH");
   GlobalVariableDel(GV_PREFIX + "CURRENT_HIGH");
   GlobalVariableDel(GV_PREFIX + "CONTRACTION_HIGH");
   GlobalVariableDel(GV_PREFIX + "LOCK_BULLISH");
   GlobalVariableDel(GV_PREFIX + "STORED_LOW");
   GlobalVariableDel(GV_PREFIX + "CURRENT_LOW");
   GlobalVariableDel(GV_PREFIX + "CONTRACTION_LOW");
   GlobalVariableDel(GV_PREFIX + "LOCK_BEARISH");
  }

void ResetExpansionEngine()
  {
   stored_high = 0;
   current_high = 0;
   stored_contraction_high = 0;
   lock_bullish = false;

   stored_low = 0;
   current_low = 0;
   stored_contraction_low = 0;
   lock_bearish = false;
   
   SyncGlobalVariables();
  }

bool IsSameDay(datetime t1, datetime t2)
  {
   if(t1 == 0 || t2 == 0) return false;
   MqlDateTime dt1, dt2;
   TimeToStruct(t1, dt1);
   TimeToStruct(t2, dt2);
   return (dt1.day == dt2.day && dt1.mon == dt2.mon && dt1.year == dt2.year);
  }

bool CheckNewBrokerDay(datetime barTime)
  {
   if(last_broker_day == 0)
     {
      last_broker_day = barTime;
      return false;
     }
   
   MqlDateTime dt_current, dt_last;
   TimeToStruct(barTime, dt_current);
   TimeToStruct(last_broker_day, dt_last);

   if(dt_current.day != dt_last.day || dt_current.mon != dt_last.mon || dt_current.year != dt_last.year)
     {
      ResetExpansionEngine();
      last_broker_day = barTime;
      return true;
     }
   return false;
  }

double GetPointDelta(double p1, double p2)
  {
   return MathRound(MathAbs(p2 - p1) / _Point);
  }

bool IsHighExpansion(double prev, double curr) { return curr > prev + _Point/10.0; }
bool IsHighContraction(double prev, double curr) { return curr < prev - _Point/10.0; }
bool IsLowExpansion(double prev, double curr) { return curr < prev - _Point/10.0; }
bool IsLowContraction(double prev, double curr) { return curr > prev + _Point/10.0; }

void TriggerBullishThreshold(datetime t)
  {
   if(lock_bullish) return;
   
   string name = "EXP_BULL_" + IntegerToString((long)t);
   if(ObjectCreate(0, name, OBJ_VLINE, 0, t, 0))
     {
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrLime);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
     }
     
   lock_bullish = true;
   lock_bearish = false;
   stored_high = 0;
   stored_contraction_low = 0;
   SyncGlobalVariables();
  }

void TriggerBearishThreshold(datetime t)
  {
   if(lock_bearish) return;

   string name = "EXP_BEAR_" + IntegerToString((long)t);
   if(ObjectCreate(0, name, OBJ_VLINE, 0, t, 0))
     {
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
     }

   lock_bearish = true;
   lock_bullish = false;
   stored_low = 0;
   stored_contraction_high = 0;
   SyncGlobalVariables();
  }

void UpdateExpansionEngine(bool isHigh, bool isFinalizing, datetime triggerTime)
  {
   if(isHigh)
     {
      if(HighState[0].time == 0 || HighState[1].time == 0) return;
      if(!IsSameDay(HighState[0].time, last_broker_day) || !IsSameDay(HighState[1].time, last_broker_day))
        {
         current_high = 0;
         SyncGlobalVariables();
         return;
        }

      if(isFinalizing)
        {
         if(IsHighExpansion(HighState[0].price, HighState[1].price))
            stored_high += current_high;
         else if(IsHighContraction(HighState[0].price, HighState[1].price))
           {
            stored_high = 0;
            if(lock_bullish) stored_contraction_high += current_high;
           }
        }
      else
        {
         current_high = GetPointDelta(HighState[0].price, HighState[1].price);
         if(IsHighExpansion(HighState[0].price, HighState[1].price))
           {
            stored_contraction_high = 0;
            if(!lock_bullish && (stored_high + current_high >= EXP_THRESHOLD))
               TriggerBullishThreshold(triggerTime);
           }
         else if(IsHighContraction(HighState[0].price, HighState[1].price))
           {
            if(lock_bullish) stored_contraction_high = current_high;
           }
        }
     }
   else
     {
      if(LowState[0].time == 0 || LowState[1].time == 0) return;
      if(!IsSameDay(LowState[0].time, last_broker_day) || !IsSameDay(LowState[1].time, last_broker_day))
        {
         current_low = 0;
         SyncGlobalVariables();
         return;
        }

      if(isFinalizing)
        {
         if(IsLowExpansion(LowState[0].price, LowState[1].price))
            stored_low += current_low;
         else if(IsLowContraction(LowState[0].price, LowState[1].price))
           {
            stored_low = 0;
            if(lock_bearish) stored_contraction_low += current_low;
           }
        }
      else
        {
         current_low = GetPointDelta(LowState[0].price, LowState[1].price);
         if(IsLowExpansion(LowState[0].price, LowState[1].price))
           {
            stored_contraction_low = 0;
            if(!lock_bearish && (stored_low + current_low >= EXP_THRESHOLD))
               TriggerBearishThreshold(triggerTime);
           }
         else if(IsLowContraction(LowState[0].price, LowState[1].price))
           {
            if(lock_bearish) stored_contraction_low = current_low;
           }
        }
     }
   SyncGlobalVariables();
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Initialize constants
   StartBar1=Period1+Deviation1+Backstep1+1;
   StartBar2=Period2+Deviation2+Backstep2+1;
   StartBar3=Period3+Deviation3+Backstep3+1;
   StartBar=(int)MathMax(StartBar1,MathMax(StartBar2,StartBar3));

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,LowBuffer1,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"Low1");
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,LowSymbol1);
//---- indexing elements in the buffer (0 is newest)
   ArraySetAsSeries(LowBuffer1,true);
   ArraySetAsSeries(HighBuffer1,true);
   ArraySetAsSeries(LowBuffer2,true);
   ArraySetAsSeries(HighBuffer2,true);
   ArraySetAsSeries(LowBuffer3,true);
   ArraySetAsSeries(HighBuffer3,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(1,HighBuffer1,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"High1");
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,HighSymbol1);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(2,LowBuffer2,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 3
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(2,PLOT_LABEL,"Low2");
//---- indicator symbol
   PlotIndexSetInteger(2,PLOT_ARROW,LowSymbol2);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(3,HighBuffer2,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 4
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(3,PLOT_LABEL,"High2");
//---- indicator symbol
   PlotIndexSetInteger(3,PLOT_ARROW,HighSymbol2);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(4,LowBuffer3,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 5
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(4,PLOT_LABEL,"Low3");
//---- indicator symbol
   PlotIndexSetInteger(4,PLOT_ARROW,LowSymbol3);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(5,HighBuffer3,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 6
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(5,PLOT_LABEL,"High3");
//---- indicator symbol
   PlotIndexSetInteger(5,PLOT_ARROW,HighSymbol3);

//---- Set colors for different levels (lighter for level 1, darker for higher levels)
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, clrDarkBlue);      // Level 1 Bullish - Light
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, clrDarkMagenta);      // Level 1 Bearish - Light
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, clrDodgerBlue);     // Level 2 Bullish - Medium
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, clrMediumOrchid);   // Level 2 Bearish - Medium
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, clrLightBlue);       // Level 3 Bullish - Dark
   PlotIndexSetInteger(5, PLOT_LINE_COLOR, clrLightPink);    // Level 3 Bearish - Dark

//---- Set the pixel offset for the arrows
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,-PixelOffset); // Low 1
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,PixelOffset);  // High 1
   PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,-PixelOffset); // Low 2
   PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,PixelOffset);  // High 2
   PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,-PixelOffset); // Low 3
   PlotIndexSetInteger(5,PLOT_ARROW_SHIFT,PixelOffset);  // High 3

//---- initializations of a variable for the indicator short name
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,"3_Level_ZZ_Semafor");
//---- determination of accuracy of displaying of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

//---- Get indicator's handle
   Handle1=iCustom(NULL,0,"Examples\\ZigZag",Period1,Deviation1,Backstep1);
   if(Handle1==INVALID_HANDLE) Print(" Failed to get handle of the ZigZag1 indicator");
//---- Get indicator's handle
   Handle2=iCustom(NULL,0,"Examples\\ZigZag",Period2,Deviation2,Backstep2);
   if(Handle2==INVALID_HANDLE) Print(" Failed to get handle of the ZigZag2 indicator");
//---- Get indicator's handle
   Handle3=iCustom(NULL,0,"Examples\\ZigZag",Period3,Deviation3,Backstep3);
   if(Handle3==INVALID_HANDLE) Print(" Failed to get handle of the ZigZag3 indicator");
//----
   SyncGlobalVariables();
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   DeleteObjectsByPrefix("MS_H_");
   DeleteObjectsByPrefix("MS_L_");
   DeleteObjectsByPrefix("EXP_BULL_");
   DeleteObjectsByPrefix("EXP_BEAR_");
   DeleteGlobalVariables();
  }
//+------------------------------------------------------------------+
//| Deletes objects by prefix                                        |
//+------------------------------------------------------------------+
void DeleteObjectsByPrefix(string prefix)
  {
   ObjectsDeleteAll(0, prefix);
  }
//+------------------------------------------------------------------+
//| Helper to draw segments and labels                               |
//+------------------------------------------------------------------+
void DrawStructureSegment(string prefix, SwingInfo &s1, SwingInfo &s2, bool isLatest)
  {
   string name = prefix + (isLatest ? "LATEST" : (IntegerToString((long)s1.time) + "_" + IntegerToString((long)s2.time)));
   ObjectCreate(0, name, OBJ_TREND, 0, s1.time, s1.price, s2.time, s2.price);

   color lineColor = (s2.price > s1.price) ? clrLime : clrRed;

   ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);

// Label
   int points = (int)MathRound(MathAbs(s2.price - s1.price) / _Point);
   string txtName = prefix + "TXT_" + (isLatest ? "LATEST" : (IntegerToString((long)s1.time) + "_" + IntegerToString((long)s2.time)));
   datetime midTime = (datetime)(((long)s1.time + (long)s2.time) / 2);
   double midPrice = (s1.price + s2.price) / 2.0;

   ObjectCreate(0, txtName, OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, txtName, OBJPROP_TEXT, "Δ " + IntegerToString(points) + " pts");
   ObjectSetInteger(0, txtName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, txtName, OBJPROP_FONTSIZE, 15);
   ObjectSetInteger(0, txtName, OBJPROP_ANCHOR, (prefix == "MS_H_") ? ANCHOR_BOTTOM : ANCHOR_TOP);
   ObjectSetInteger(0, txtName, OBJPROP_SELECTABLE, false);
  }
//+------------------------------------------------------------------+
//| Helper to update market structure incrementally                  |
//+------------------------------------------------------------------+
void UpdateMarketStructure(string prefix, SwingInfo &state[], const double &buffer[], const datetime &times[], int lookback, int rates_total, bool isHistorical)
  {
   bool isHigh = (prefix == "MS_H_");
// Find latest pivot in buffer (within lookback or at least 100 bars)
   SwingInfo current;
   current.price = 0;
   current.time = 0;
   int searchLimit = MathMax(lookback * 2, 100);
   if(searchLimit > rates_total) searchLimit = rates_total;

   for(int i = 0; i < searchLimit; i++)
     {
      if(buffer[i] > 0.0)
        {
         current.time = times[i];
         current.price = buffer[i];
         current.barIndex = i;
         break;
        }
     }

   if(current.time == 0) // No pivot found in recent history
     {
      if(state[1].time != 0)
        {
         // Check if our state pivot still exists further back
         bool stillExists = false;
         for(int i = 0; i < rates_total; i++)
           {
            if(times[i] == state[1].time)
              {
               if(buffer[i] > 0.0) stillExists = true;
               break;
              }
            if(times[i] < state[1].time) break;
           }
         if(!stillExists)
           {
            ObjectDelete(0, prefix + "LATEST");
            ObjectDelete(0, prefix + "TXT_LATEST");
            state[1].time = 0;
            state[1].price = 0;
           }
        }
      return;
     }

   if(state[1].time == 0)
     {
      state[1] = current;
      if(state[0].time != 0)
         DrawStructureSegment(prefix, state[0], state[1], true);
     }
   else if(current.time == state[1].time)
     {
      // Case 1: Existing pivot update
      if(MathAbs(current.price - state[1].price) > _Point / 10.0)
        {
         state[1].price = current.price;
         ObjectDelete(0, prefix + "LATEST");
         ObjectDelete(0, prefix + "TXT_LATEST");
         if(state[0].time != 0)
            DrawStructureSegment(prefix, state[0], state[1], true);
        }
     }
   else if(current.time > state[1].time)
     {
      // New pivot or moved pivot
      bool oldStillExists = false;
      for(int i = 0; i < rates_total; i++)
        {
         if(times[i] == state[1].time)
           {
            if(buffer[i] > 0.0) oldStillExists = true;
            break;
           }
         if(times[i] < state[1].time) break;
        }

      if(oldStillExists)
        {
         // Case 2: New pivot confirmed. Shift state.
         
         // --- EXPANSION ENGINE: FINALIZE PREVIOUS ---
         UpdateExpansionEngine(isHigh, true, current.time);
         // -------------------------------------------

         ObjectDelete(0, prefix + "LATEST");
         ObjectDelete(0, prefix + "TXT_LATEST");
         if(state[0].time != 0)
            DrawStructureSegment(prefix, state[0], state[1], false); // Freeze previous

         state[0] = state[1];
         state[1] = current;
         DrawStructureSegment(prefix, state[0], state[1], true);
        }
      else
        {
         // Case 3: Pivot moved forward or replaced
         state[1] = current;
         ObjectDelete(0, prefix + "LATEST");
         ObjectDelete(0, prefix + "TXT_LATEST");
         if(state[0].time != 0)
            DrawStructureSegment(prefix, state[0], state[1], true);
        }
     }

   else if(current.time < state[1].time)
     {
      // Latest state pivot disappeared, current is now older
      bool stillExists = false;
      for(int i = 0; i < rates_total; i++)
        {
         if(times[i] == state[1].time)
           {
            if(buffer[i] > 0.0) stillExists = true;
            break;
           }
         if(times[i] < state[1].time) break;
        }
      if(!stillExists)
        {
         state[1] = current;
         ObjectDelete(0, prefix + "LATEST");
         ObjectDelete(0, prefix + "TXT_LATEST");
         if(state[0].time != 0)
            DrawStructureSegment(prefix, state[0], state[1], true);
        }
     }

   // --- EXPANSION ENGINE: REALTIME UPDATE ---
   UpdateExpansionEngine(isHigh, false, isHistorical ? state[1].time : TimeCurrent());
   // -----------------------------------------
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<StartBar) return(0);

//---- declarations of local variables 
   int limit,to_copy1,to_copy2,to_copy3;

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      limit=rates_total-StartBar;  // starting index for calculation of all bars
      to_copy1=rates_total;
      to_copy2=rates_total;
      to_copy3=rates_total;
     }
   else
     {
      limit=rates_total-prev_calculated;
      to_copy1=limit+StartBar1;
      to_copy2=limit+StartBar2;
      to_copy3=limit+StartBar3;
     }

//---- copy the newly appeared data in the indicator buffers
   if(CopyBuffer(Handle1,1,0,to_copy1,HighBuffer1)<=0) return(0);
   if(CopyBuffer(Handle1,2,0,to_copy1,LowBuffer1)<=0) return(0);
   if(CopyBuffer(Handle2,1,0,to_copy2,HighBuffer2)<=0) return(0);
   if(CopyBuffer(Handle2,2,0,to_copy2,LowBuffer2)<=0) return(0);
   if(CopyBuffer(Handle3,1,0,to_copy3,HighBuffer3)<=0) return(0);
   if(CopyBuffer(Handle3,2,0,to_copy3,LowBuffer3)<=0) return(0);

//--- Market Structure Engine ---
   datetime times[];
   if(CopyTime(_Symbol, _Period, 0, rates_total, times) <= 0) return(rates_total);
   // Buffers are Series (0=newest), so we make times Series too for consistency.
   ArraySetAsSeries(times, true);

   if(prev_calculated <= 0)
     {
      DeleteObjectsByPrefix("MS_H_");
      DeleteObjectsByPrefix("MS_L_");
      DeleteObjectsByPrefix("EXP_BULL_");
      DeleteObjectsByPrefix("EXP_BEAR_");
      ZeroMemory(HighState);
      ZeroMemory(LowState);
      ResetExpansionEngine();
      last_broker_day = 0;

      // 1. Scan and process historical pivots sequentially (chronologically oldest to newest)
      for(int i = rates_total - 1; i >= 0; i--)
        {
         bool isH = (HighBuffer2[i] > 0.0);
         bool isL = (LowBuffer2[i] > 0.0);
         
         if(isH || isL)
           {
            CheckNewBrokerDay(times[i]);
            
            if(isH)
              {
               SwingInfo current;
               current.time = times[i];
               current.price = HighBuffer2[i];
               current.barIndex = i;
               
               if(HighState[1].time != 0)
                 {
                  // Finalize previous
                  UpdateExpansionEngine(true, true, current.time);
                  
                  DrawStructureSegment("MS_H_", HighState[0], HighState[1], false);
                  HighState[0] = HighState[1];
                  HighState[1] = current;
                 }
               else if(HighState[0].time != 0)
                 {
                  HighState[1] = current;
                 }
               else
                 {
                  HighState[0] = current;
                 }
               
               // Mutable update (historical context)
               UpdateExpansionEngine(true, false, HighState[1].time);
              }

            if(isL)
              {
               SwingInfo current;
               current.time = times[i];
               current.price = LowBuffer2[i];
               current.barIndex = i;

               if(LowState[1].time != 0)
                 {
                  // Finalize previous
                  UpdateExpansionEngine(false, true, current.time);

                  DrawStructureSegment("MS_L_", LowState[0], LowState[1], false);
                  LowState[0] = LowState[1];
                  LowState[1] = current;
                 }
               else if(LowState[0].time != 0)
                 {
                  LowState[1] = current;
                 }
               else
                 {
                  LowState[0] = current;
                 }

               // Mutable update (historical context)
               UpdateExpansionEngine(false, false, LowState[1].time);
              }
           }
        }

      // Draw the latest mutable segments
      if(HighState[0].time != 0 && HighState[1].time != 0)
         DrawStructureSegment("MS_H_", HighState[0], HighState[1], true);
      if(LowState[0].time != 0 && LowState[1].time != 0)
         DrawStructureSegment("MS_L_", LowState[0], LowState[1], true);
     }
   else
     {
      CheckNewBrokerDay(times[0]);
      UpdateMarketStructure("MS_H_", HighState, HighBuffer2, times, StartBar2, rates_total, false);
      UpdateMarketStructure("MS_L_", LowState, LowBuffer2, times, StartBar2, rates_total, false);
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
