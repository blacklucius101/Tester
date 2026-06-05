//+------------------------------------------------------------------+
//|                                             Custom_Indicator.mq5 |
//|                                  Copyright 2024, Software Agency |
//|                                       Optimized for BTCUSD M1    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property version   "1.20"
#property indicator_chart_window
#property indicator_buffers 13
#property indicator_plots   11

//--- plot Donchian Upper Line
#property indicator_label1 "Upper Line"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrGreen
#property indicator_width1 2

//--- plot Donchian Lower Line
#property indicator_label2 "Lower Line"
#property indicator_type2 DRAW_LINE
#property indicator_color2 clrRed
#property indicator_width2 2

//--- plot Donchian Mid Line
#property indicator_label3 "Mid Line"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrBlue
#property indicator_width3 1

//--- plot Donchian Resistance
#property indicator_label4 "Resistance"
#property indicator_type4 DRAW_LINE
#property indicator_style4 STYLE_DOT
#property indicator_color4 clrPaleGreen
#property indicator_width4 1

//--- plot Donchian Support
#property indicator_label5 "Support"
#property indicator_type5 DRAW_LINE
#property indicator_style5 STYLE_DOT
#property indicator_color5 clrSalmon
#property indicator_width5 1

//--- plot Donchian Resistance Span
#property indicator_label6 "Resistance Span"
#property indicator_type6 DRAW_FILLING
#property indicator_color6 clrDarkSlateGray, clrDarkSlateGray
#property indicator_width6 1

//--- plot Donchian Support Span
#property indicator_label7 "Support Span"
#property indicator_type7 DRAW_FILLING
#property indicator_color7 clrMaroon, clrMaroon
#property indicator_width7 1

//--- plot Level 1 High
#property indicator_label8  "Level 1 High"
#property indicator_type8   DRAW_ARROW
#property indicator_color8  clrMagenta
#property indicator_width8  1
//--- plot Level 1 Low
#property indicator_label9  "Level 1 Low"
#property indicator_type9   DRAW_ARROW
#property indicator_color9  clrAqua
#property indicator_width9  1
//--- plot Level 2 High
#property indicator_label10 "Level 2 High"
#property indicator_type10  DRAW_ARROW
#property indicator_color10 clrMagenta
#property indicator_width10 1
//--- plot Level 2 Low
#property indicator_label11 "Level 2 Low"
#property indicator_type11  DRAW_ARROW
#property indicator_color11 clrAqua
#property indicator_width11 1

//--- input parameters
input datetime InpHistoricalDate = 0; // Historical Date (YYYY.MM.DD) - 0 for Current Day
input int      InpDonchianPeriod = 17; // Donchian Period

//--- indicator buffers
double         BufferUp[];
double         BufferDown[];
double         BufferMid[];
double         BufferResistance[];
double         BufferSupport[];
double         BufferResFilling1[];
double         BufferResFilling2[];
double         BufferSupFilling1[];
double         BufferSupFilling2[];

double         BufferL1H[];
double         BufferL1L[];
double         BufferL2H[];
double         BufferL2L[];

//--- Level Settings (Hardcoded as per requirements)
const int L1_PERIOD = 2;
const int L1_BACKSTEP = 2;
const int L1_ARROW = 159;

const int L2_PERIOD = 13;
const int L2_BACKSTEP = 6;
const int L2_ARROW = 108;

//--- Anchor structure for state retention
struct SemaforAnchor {
   int      barIndex;
   double   price;
   datetime time;
   bool     isActive;
   int      id;
};

struct LevelState {
   SemaforAnchor highAnchors[2]; // Two most recent HIGH anchors
   SemaforAnchor lowAnchors[2];  // Two most recent LOW anchors
   int           firstBarOfDay;
   int           highCounter;
   int           lowCounter;

   // Phase 3 variables
   double        totalExpansionBullish;
   double        totalExpansionBearish;
   double        totalContractionBullish;
   double        totalContractionBearish;
   bool          bullishLock;
   bool          bearishLock;
};

LevelState stateL1;
LevelState stateL2;

datetime targetDayStart = 0;
datetime targetDayEnd = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   //--- indicator buffers mapping
   SetIndexBuffer(0, BufferUp, INDICATOR_DATA);
   SetIndexBuffer(1, BufferDown, INDICATOR_DATA);
   SetIndexBuffer(2, BufferMid, INDICATOR_DATA);
   SetIndexBuffer(3, BufferResistance, INDICATOR_DATA);
   SetIndexBuffer(4, BufferSupport, INDICATOR_DATA);
   SetIndexBuffer(5, BufferResFilling1, INDICATOR_DATA);
   SetIndexBuffer(6, BufferResFilling2, INDICATOR_DATA);
   SetIndexBuffer(7, BufferSupFilling1, INDICATOR_DATA);
   SetIndexBuffer(8, BufferSupFilling2, INDICATOR_DATA);
   SetIndexBuffer(9, BufferL1H, INDICATOR_DATA);
   SetIndexBuffer(10, BufferL1L, INDICATOR_DATA);
   SetIndexBuffer(11, BufferL2H, INDICATOR_DATA);
   SetIndexBuffer(12, BufferL2L, INDICATOR_DATA);

   //--- set arrow codes for Level 1 and Level 2
   PlotIndexSetInteger(7, PLOT_ARROW, L1_ARROW);
   PlotIndexSetInteger(8, PLOT_ARROW, L1_ARROW);
   PlotIndexSetInteger(9, PLOT_ARROW, L2_ARROW);
   PlotIndexSetInteger(10, PLOT_ARROW, L2_ARROW);

   //--- set empty values
   for(int i=0; i<7; i++) {
      PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   }
   for(int i=7; i<11; i++) {
      PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0.0);
   }

   //--- name for DataWindow
   IndicatorSetString(INDICATOR_SHORTNAME, "Semafor Indicator (BTCUSD M1 Optimized)");

   //--- symbol/period check (informational)
   if(Symbol() != "BTCUSD" || _Period != PERIOD_M1) {
      Print("Note: This indicator is optimized for BTCUSD M1.");
   }

   //--- initialize state
   ResetLevelState(stateL1);
   ResetLevelState(stateL2);
   targetDayStart = 0;
   targetDayEnd = 0;

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Draw a vertical dotted lock line                                 |
//+------------------------------------------------------------------+
void DrawLockLine(int barIndex, datetime t, color clr, string prefix) {
   string name = prefix + "_" + IntegerToString(barIndex);
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_VLINE, 0, t, 0);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
   }
}

//+------------------------------------------------------------------+
//| Trigger Bullish Lock                                             |
//+------------------------------------------------------------------+
void TriggerBullishLock(LevelState &state, int barIdx, datetime t) {
   state.bullishLock = true;
   state.bearishLock = false;
   state.totalExpansionBullish = 0;
   state.totalContractionBullish = 0;
   state.totalContractionBearish = 0;
   DrawLockLine(barIdx, t, clrLime, "L2_Bullish_Lock");
}

//+------------------------------------------------------------------+
//| Trigger Bearish Lock                                             |
//+------------------------------------------------------------------+
void TriggerBearishLock(LevelState &state, int barIdx, datetime t) {
   state.bearishLock = true;
   state.bullishLock = false;
   state.totalExpansionBearish = 0;
   state.totalContractionBearish = 0;
   state.totalContractionBullish = 0;
   DrawLockLine(barIdx, t, clrRed, "L2_Bearish_Lock");
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "L2_");
}

//+------------------------------------------------------------------+
//| Reset the state for a specific level                             |
//+------------------------------------------------------------------+
void ResetLevelState(LevelState &state) {
   for(int i=0; i<2; i++) {
      state.highAnchors[i].isActive = false;
      state.highAnchors[i].barIndex = -1;
      state.highAnchors[i].price = 0;
      state.highAnchors[i].time = 0;
      state.highAnchors[i].id = 0;
      state.lowAnchors[i].isActive = false;
      state.lowAnchors[i].barIndex = -1;
      state.lowAnchors[i].price = 0;
      state.lowAnchors[i].time = 0;
      state.lowAnchors[i].id = 0;
   }
   state.firstBarOfDay = -1;
   state.highCounter = 0;
   state.lowCounter = 0;

   state.totalExpansionBullish = 0;
   state.totalExpansionBearish = 0;
   state.totalContractionBullish = 0;
   state.totalContractionBearish = 0;
   state.bullishLock = false;
   state.bearishLock = false;
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
   if(rates_total < MathMax(MathMax(L1_PERIOD, L2_PERIOD), InpDonchianPeriod)) return 0;

   // Always ensure the currently forming candle is empty for Donchian (closed candles only)
   BufferUp[rates_total - 1] = EMPTY_VALUE;
   BufferDown[rates_total - 1] = EMPTY_VALUE;
   BufferMid[rates_total - 1] = EMPTY_VALUE;
   BufferResistance[rates_total - 1] = EMPTY_VALUE;
   BufferSupport[rates_total - 1] = EMPTY_VALUE;
   BufferResFilling1[rates_total - 1] = EMPTY_VALUE;
   BufferResFilling2[rates_total - 1] = EMPTY_VALUE;
   BufferSupFilling1[rates_total - 1] = EMPTY_VALUE;
   BufferSupFilling2[rates_total - 1] = EMPTY_VALUE;

   // Determine target day boundaries
   datetime lastBarTime = time[rates_total - 1];
   datetime refTime = (InpHistoricalDate == 0) ? lastBarTime : InpHistoricalDate;
   
   MqlDateTime dt;
   TimeToStruct(refTime, dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime dayStart = StructToTime(dt);
   datetime dayEnd = dayStart + 86400;

   bool fullReset = false;
   if(dayStart != targetDayStart) {
      targetDayStart = dayStart;
      targetDayEnd = dayEnd;
      fullReset = true;
   }

   int start_idx;
   if(fullReset || prev_calculated == 0) {
      start_idx = 0;
      // Clear all buffers for the entire range
      ArrayInitialize(BufferUp, EMPTY_VALUE);
      ArrayInitialize(BufferDown, EMPTY_VALUE);
      ArrayInitialize(BufferMid, EMPTY_VALUE);
      ArrayInitialize(BufferResistance, EMPTY_VALUE);
      ArrayInitialize(BufferSupport, EMPTY_VALUE);
      ArrayInitialize(BufferResFilling1, EMPTY_VALUE);
      ArrayInitialize(BufferResFilling2, EMPTY_VALUE);
      ArrayInitialize(BufferSupFilling1, EMPTY_VALUE);
      ArrayInitialize(BufferSupFilling2, EMPTY_VALUE);
      ArrayInitialize(BufferL1H, 0.0);
      ArrayInitialize(BufferL1L, 0.0);
      ArrayInitialize(BufferL2H, 0.0);
      ArrayInitialize(BufferL2L, 0.0);
      
      ObjectsDeleteAll(0, "L2_");
      
      ResetLevelState(stateL1);
      ResetLevelState(stateL2);
      
      // Find the first bar of the day
      while(start_idx < rates_total && time[start_idx] < targetDayStart) {
         start_idx++;
      }
      stateL1.firstBarOfDay = start_idx;
      stateL2.firstBarOfDay = start_idx;
   } else {
      // Start from the last processed bar minus one to handle repaints
      start_idx = prev_calculated - 1;
      if(start_idx < 0) start_idx = 0;
      // Safety: make sure we don't start before the target day
      while(start_idx < rates_total && time[start_idx] < targetDayStart) {
         start_idx++;
      }
   }

   // Process only closed candles chronologically (up to rates_total - 2)
   // rates_total - 1 is the currently forming candle.
   for(int i = start_idx; i < rates_total - 1; i++) {
      // Ignore candles outside the target day
      if(time[i] < targetDayStart) continue;
      if(time[i] >= targetDayEnd) break;

      // --- Donchian Bands Calculation ---
      if(i >= InpDonchianPeriod - 1) {
         int window_start = i - InpDonchianPeriod + 1;
         int hh_idx = ArrayMaximum(high, window_start, InpDonchianPeriod);
         int ll_idx = ArrayMinimum(low,  window_start, InpDonchianPeriod);
         int hl_idx = ArrayMaximum(low,  window_start, InpDonchianPeriod);
         int lh_idx = ArrayMinimum(high, window_start, InpDonchianPeriod);

         if(hh_idx != -1 && ll_idx != -1 && hl_idx != -1 && lh_idx != -1) {
            BufferUp[i]         = high[hh_idx];
            BufferDown[i]       = low[ll_idx];
            BufferResistance[i] = low[hl_idx];
            BufferSupport[i]    = high[lh_idx];
            BufferMid[i]        = (BufferUp[i] + BufferDown[i]) / 2.0;

            BufferResFilling1[i] = BufferUp[i];
            BufferResFilling2[i] = BufferResistance[i];
            BufferSupFilling1[i] = BufferSupport[i];
            BufferSupFilling2[i] = BufferDown[i];
         }
      }

      ProcessLevel(i, L1_PERIOD, L1_BACKSTEP, stateL1.firstBarOfDay, high, low, time, stateL1, BufferL1H, BufferL1L, false);
      ProcessLevel(i, L2_PERIOD, L2_BACKSTEP, stateL2.firstBarOfDay, high, low, time, stateL2, BufferL2H, BufferL2L, true);
   }

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Helper to update L2 Trend Line                                   |
//+------------------------------------------------------------------+
void UpdateL2Trend(string name, datetime t1, double p1, datetime t2, double p2, color clr) {
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
   } else {
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, p1);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 1, p2);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   }
}

//+------------------------------------------------------------------+
//| Helper to update L2 Text Label                                   |
//+------------------------------------------------------------------+
void UpdateL2Text(string name, datetime t, double p, string text, color clr, bool isHigh) {
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_TEXT, 0, t, p);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, isHigh ? ANCHOR_BOTTOM : ANCHOR_TOP);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   } else {
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, t);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, p);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   }
}

//+------------------------------------------------------------------+
//| Update Level 2 High connection (line and label)                  |
//+------------------------------------------------------------------+
void UpdateL2HighConnection(const SemaforAnchor &a1, const SemaforAnchor &a2) {
   string lineName = "L2_H_Line_" + IntegerToString(a2.id);
   string labelName = "L2_H_Label_" + IntegerToString(a2.id);
   
   double diffPoints = (a2.price - a1.price) / _Point;
   color clr = (a2.price > a1.price) ? clrLime : clrRed;
   
   UpdateL2Trend(lineName, a1.time, a1.price, a2.time, a2.price, clr);
   
   datetime t_mid = (datetime)(((long)a1.time + (long)a2.time) / 2);
   double p_mid = (a1.price + a2.price) / 2;
   
   string text = (diffPoints >= 0 ? "+" : "") + DoubleToString(diffPoints, 0);
   UpdateL2Text(labelName, t_mid, p_mid, text, clr, true);
}

//+------------------------------------------------------------------+
//| Update Level 2 Low connection (line and label)                   |
//+------------------------------------------------------------------+
void UpdateL2LowConnection(const SemaforAnchor &a1, const SemaforAnchor &a2) {
   string lineName = "L2_L_Line_" + IntegerToString(a2.id);
   string labelName = "L2_L_Label_" + IntegerToString(a2.id);
   
   double diffPoints = (a2.price - a1.price) / _Point;
   color clr = (a2.price > a1.price) ? clrLime : clrRed;
   
   UpdateL2Trend(lineName, a1.time, a1.price, a2.time, a2.price, clr);
   
   datetime t_mid = (datetime)(((long)a1.time + (long)a2.time) / 2);
   double p_mid = (a1.price + a2.price) / 2;
   
   string text = (diffPoints >= 0 ? "+" : "") + DoubleToString(diffPoints, 0);
   UpdateL2Text(labelName, t_mid, p_mid, text, clr, false);
}

//+------------------------------------------------------------------+
//| Process semafors for a specific level and candle index           |
//+------------------------------------------------------------------+
void ProcessLevel(int idx, int period, int backstep, int firstBar, const double &high[], const double &low[], const datetime &time[], LevelState &state, double &bufH[], double &bufL[], bool isLevel2) {
   // Check if enough candles exist since the start of the day to satisfy Period requirement
   if(idx - firstBar < period - 1) return;

   // --- High Semafor ---
   bool isHighSemafor = true;
   for(int j = idx - 1; j > idx - period; j--) {
      // Equal high does not qualify as higher high
      if(high[idx] <= high[j]) {
         isHighSemafor = false;
         break;
      }
   }

   if(isHighSemafor) {
      bool repainted = false;
      // Check if we can repaint the most recent active anchor within Backstep range
      if(state.highAnchors[1].isActive) {
         int dist = idx - state.highAnchors[1].barIndex;
         if(dist < backstep) {
            // Repaint: remove old visual and relocate to current extreme
            bufH[state.highAnchors[1].barIndex] = 0;
            state.highAnchors[1].barIndex = idx;
            state.highAnchors[1].price = high[idx];
            state.highAnchors[1].time = time[idx];
            bufH[idx] = high[idx];
            repainted = true;
            
            if(isLevel2 && state.highAnchors[0].isActive) {
               UpdateL2HighConnection(state.highAnchors[0], state.highAnchors[1]);
               
               // Phase 3: Evaluate lock on repaint
               if(!state.bullishLock) {
                  double current_temp = (state.highAnchors[1].price - state.highAnchors[0].price) / _Point;
                  if(state.totalExpansionBullish + current_temp >= 24000) {
                     TriggerBullishLock(state, idx, time[idx]);
                  }
               }
            }
         }
      }
      
      if(!repainted) {
         if(isLevel2 && state.highAnchors[1].isActive && state.highAnchors[0].isActive) {
            // Phase 3: Confirm previous move
            double prev_temp = (state.highAnchors[1].price - state.highAnchors[0].price) / _Point;
            if(!state.bullishLock) {
               if(prev_temp > 0) state.totalExpansionBullish += prev_temp;
               else state.totalExpansionBullish = 0;
            } else {
               if(prev_temp < 0) state.totalContractionBullish += prev_temp;
               else state.totalContractionBullish = 0;
            }
         }

         // New anchor: push previous to secondary position and finalize current
         state.highAnchors[0] = state.highAnchors[1];
         state.highCounter++;
         state.highAnchors[1].barIndex = idx;
         state.highAnchors[1].price = high[idx];
         state.highAnchors[1].time = time[idx];
         state.highAnchors[1].isActive = true;
         state.highAnchors[1].id = state.highCounter;
         bufH[idx] = high[idx];
         
         if(isLevel2 && state.highAnchors[0].isActive) {
            UpdateL2HighConnection(state.highAnchors[0], state.highAnchors[1]);
            
            // Phase 3: Evaluate lock on new anchor
            if(!state.bullishLock) {
               double current_temp = (state.highAnchors[1].price - state.highAnchors[0].price) / _Point;
               if(state.totalExpansionBullish + current_temp >= 24000) {
                  TriggerBullishLock(state, idx, time[idx]);
               }
            }
         }
      }
   }

   // --- Low Semafor ---
   bool isLowSemafor = true;
   for(int j = idx - 1; j > idx - period; j--) {
      // Equal low does not qualify as lower low
      if(low[idx] >= low[j]) {
         isLowSemafor = false;
         break;
      }
   }

   if(isLowSemafor) {
      bool repainted = false;
      // Check if we can repaint the most recent active anchor within Backstep range
      if(state.lowAnchors[1].isActive) {
         int dist = idx - state.lowAnchors[1].barIndex;
         if(dist < backstep) {
            // Repaint: remove old visual and relocate to current extreme
            bufL[state.lowAnchors[1].barIndex] = 0;
            state.lowAnchors[1].barIndex = idx;
            state.lowAnchors[1].price = low[idx];
            state.lowAnchors[1].time = time[idx];
            bufL[idx] = low[idx];
            repainted = true;
            
            if(isLevel2 && state.lowAnchors[0].isActive) {
               UpdateL2LowConnection(state.lowAnchors[0], state.lowAnchors[1]);
               
               // Phase 3: Evaluate lock on repaint
               if(!state.bearishLock) {
                  double current_temp = (state.lowAnchors[1].price - state.lowAnchors[0].price) / _Point;
                  if(state.totalExpansionBearish + current_temp <= -24000) {
                     TriggerBearishLock(state, idx, time[idx]);
                  }
               }
            }
         }
      }
      
      if(!repainted) {
         if(isLevel2 && state.lowAnchors[1].isActive && state.lowAnchors[0].isActive) {
            // Phase 3: Confirm previous move
            double prev_temp = (state.lowAnchors[1].price - state.lowAnchors[0].price) / _Point;
            if(!state.bearishLock) {
               if(prev_temp < 0) state.totalExpansionBearish += prev_temp;
               else state.totalExpansionBearish = 0;
            } else {
               if(prev_temp > 0) state.totalContractionBearish += prev_temp;
               else state.totalContractionBearish = 0;
            }
         }

         // New anchor: push previous to secondary position and finalize current
         state.lowAnchors[0] = state.lowAnchors[1];
         state.lowCounter++;
         state.lowAnchors[1].barIndex = idx;
         state.lowAnchors[1].price = low[idx];
         state.lowAnchors[1].time = time[idx];
         state.lowAnchors[1].isActive = true;
         state.lowAnchors[1].id = state.lowCounter;
         bufL[idx] = low[idx];
         
         if(isLevel2 && state.lowAnchors[0].isActive) {
            UpdateL2LowConnection(state.lowAnchors[0], state.lowAnchors[1]);
            
            // Phase 3: Evaluate lock on new anchor
            if(!state.bearishLock) {
               double current_temp = (state.lowAnchors[1].price - state.lowAnchors[0].price) / _Point;
               if(state.totalExpansionBearish + current_temp <= -24000) {
                  TriggerBearishLock(state, idx, time[idx]);
               }
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
