//+------------------------------------------------------------------+
//|                                       Final_Custom_Indicator.mq5 |
//|                                  Copyright 2024, Software Agency |
//|                                       Optimized for BTCUSD M1    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property version   "1.21"
#property indicator_chart_window
#property indicator_buffers 15
#property indicator_plots   13

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
#property indicator_color8  clrAqua
#property indicator_width8  1
//--- plot Level 1 Low
#property indicator_label9  "Level 1 Low"
#property indicator_type9   DRAW_ARROW
#property indicator_color9  clrMagenta
#property indicator_width9  1
//--- plot Level 2 High
#property indicator_label10 "Level 2 High"
#property indicator_type10  DRAW_ARROW
#property indicator_color10 clrAqua
#property indicator_width10 1
//--- plot Level 2 Low
#property indicator_label11 "Level 2 Low"
#property indicator_type11  DRAW_ARROW
#property indicator_color11 clrMagenta
#property indicator_width11 1

//--- plot Bullish Events
#property indicator_label12 "Bullish Events"
#property indicator_type12  DRAW_ARROW
#property indicator_color12 clrLime
#property indicator_width12 2
//--- plot Bearish Events
#property indicator_label13 "Bearish Events"
#property indicator_type13  DRAW_ARROW
#property indicator_color13 clrRed
#property indicator_width13 2

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
double         BufferBullishEvents[];
double         BufferBearishEvents[];

//--- Level Settings (Hardcoded as per requirements)
const int L1_PERIOD = 2;
const int L1_BACKSTEP = 2;
const int L1_ARROW = 159;

const int L2_PERIOD = 13;
const int L2_BACKSTEP = 6;
const int L2_ARROW = 108;

struct LevelState;

void ProcessLevel(int idx, int period, int backstep, int firstBar, const double &pOpen[], const double &pHigh[], const double &pLow[], const double &pClose[], const datetime &pTime[], LevelState &state, double &bufH[], double &bufL[], bool isLevel2);

//--- Anchor structure for state retention
struct SemaforAnchor {
   int      barIndex;
   double   price;
   datetime time;
   bool     isActive;
   int      id;
};

enum EInteractionType {
   INT_NONE,
   INT_CROSS,
   INT_SWIPE
};

enum EBOSMSSState {
   BOS_MSS_NONE,
   BOS_MSS_TRIGGERED_BOS,
   BOS_MSS_TRIGGERED_MSS,
   BOS_MSS_CONFIRMED_BOS,
   BOS_MSS_CONFIRMED_MSS
};

struct BorderState {
   EInteractionType activeType;
   int              triggerBarIdx;
   double           triggerOpen;
   double           precedingExtreme;
   bool             isStale;
   double           staleLevel;
};

struct PushState {
   bool             active;
   bool             isCrossPush;
   int              triggerBarIdx;
   double           triggerOpen;
   double           extremeBetween;
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

   // Phase 5 state
   BorderState   resState;
   BorderState   midState;
   BorderState   supState;
   PushState     bullPushState;
   PushState     bearPushState;

   // Phase 6 variables
   EBOSMSSState  bosMssState;
   int           bosMssTriggerIdx;
   bool          bosMssIsPush;
   bool          bosMssIsCrossPush;
   double        bosMssTriggerOpen;
   double        bosMssExtremeBetween;
   int           bosMssTriggerSemaforId;
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
   SetIndexBuffer(13, BufferBullishEvents, INDICATOR_DATA);
   SetIndexBuffer(14, BufferBearishEvents, INDICATOR_DATA);

   //--- set arrow codes for Level 1 and Level 2
   PlotIndexSetInteger(7, PLOT_ARROW, L1_ARROW);
   PlotIndexSetInteger(8, PLOT_ARROW, L1_ARROW);
   PlotIndexSetInteger(9, PLOT_ARROW, L2_ARROW);
   PlotIndexSetInteger(10, PLOT_ARROW, L2_ARROW);
   PlotIndexSetInteger(11, PLOT_ARROW, 233); // Bullish event
   PlotIndexSetInteger(12, PLOT_ARROW, 234); // Bearish event

   //--- set empty values
   for(int i=0; i<7; i++) {
      PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   }
   for(int i=7; i<13; i++) {
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

void DrawBOSMSSLine(int barIndex, datetime t) {
   string name = "L2_BOS_MSS_Line_" + IntegerToString(barIndex);
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_VLINE, 0, t, 0);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrMagenta);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
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
   
   // Reset Phase 5 interaction states on lock transition
   ResetBorderState(state.resState);
   ResetBorderState(state.midState);
   ResetBorderState(state.supState);
   ResetPushState(state.bullPushState);
   ResetPushState(state.bearPushState);

   state.bosMssState = BOS_MSS_NONE;
   state.bosMssTriggerIdx = -1;
   state.bosMssIsPush = false;
   state.bosMssIsCrossPush = false;
   state.bosMssTriggerOpen = 0;
   state.bosMssExtremeBetween = 0;
   state.bosMssTriggerSemaforId = -1;
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

   // Reset Phase 5 interaction states on lock transition
   ResetBorderState(state.resState);
   ResetBorderState(state.midState);
   ResetBorderState(state.supState);
   ResetPushState(state.bullPushState);
   ResetPushState(state.bearPushState);

   state.bosMssState = BOS_MSS_NONE;
   state.bosMssTriggerIdx = -1;
   state.bosMssIsPush = false;
   state.bosMssIsCrossPush = false;
   state.bosMssTriggerOpen = 0;
   state.bosMssExtremeBetween = 0;
   state.bosMssTriggerSemaforId = -1;
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
void ResetBorderState(BorderState &bs) {
   bs.activeType = INT_NONE;
   bs.triggerBarIdx = -1;
   bs.triggerOpen = 0;
   bs.precedingExtreme = 0;
   bs.isStale = false;
   bs.staleLevel = 0;
}

void ResetPushState(PushState &ps) {
   ps.active = false;
   ps.isCrossPush = false;
   ps.triggerBarIdx = -1;
   ps.triggerOpen = 0;
   ps.extremeBetween = 0;
}

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

   ResetBorderState(state.resState);
   ResetBorderState(state.midState);
   ResetBorderState(state.supState);
   ResetPushState(state.bullPushState);
   ResetPushState(state.bearPushState);

   state.bosMssState = BOS_MSS_NONE;
   state.bosMssTriggerIdx = -1;
   state.bosMssTriggerSemaforId = -1;
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

      // --- Invalid Candle Check ---
      bool bullPushAllowed = (!stateL2.bullishLock && !stateL2.bearishLock) || stateL2.bearishLock || (stateL2.bosMssState == BOS_MSS_CONFIRMED_BOS || stateL2.bosMssState == BOS_MSS_CONFIRMED_MSS);
      bool bearPushAllowed = (!stateL2.bullishLock && !stateL2.bearishLock) || stateL2.bullishLock || (stateL2.bosMssState == BOS_MSS_CONFIRMED_BOS || stateL2.bosMssState == BOS_MSS_CONFIRMED_MSS);
      
      bool isPush = false;
      if(i > stateL2.firstBarOfDay && BufferUp[i] != EMPTY_VALUE && BufferUp[i-1] != EMPTY_VALUE) {
         if(bullPushAllowed && BufferUp[i] > BufferUp[i-1]) isPush = true;
         if(bearPushAllowed && BufferDown[i] < BufferDown[i-1]) isPush = true;
         
         if(!isPush) {
            if(high[i] >= BufferUp[i] || low[i] <= BufferDown[i]) {
               // Invalid candle: contacts outer border but is not a push
               continue;
            }
         }
      }

      ProcessLevel(i, L1_PERIOD, L1_BACKSTEP, stateL1.firstBarOfDay, open, high, low, close, time, stateL1, BufferL1H, BufferL1L, false);
      ProcessLevel(i, L2_PERIOD, L2_BACKSTEP, stateL2.firstBarOfDay, open, high, low, close, time, stateL2, BufferL2H, BufferL2L, true);

      // Phase 5 processing (mainly driven by Level 2 state locks)
      ProcessPhase5(i, open, high, low, close, stateL2);
      
      // Phase 6 BOS/MSS confirmation and reset handling
      HandleBOSMSS(i, open, high, low, close, time, stateL2);
   }

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Phase 5 Helpers                                                  |
//+------------------------------------------------------------------+
bool IsClosedThrough(double pOpen, double pClose, double border) {
   if(border == EMPTY_VALUE) return false;
   if(pOpen == border || pClose == border) return true;
   if((pOpen > border && pClose < border) || (pOpen < border && pClose > border)) return true;
   return false;
}

bool IsMidlineTouch(double pOpen, double pHigh, double pLow, double pClose, double mid) {
   if(mid == EMPTY_VALUE) return false;
   // Wick contacts midline, body remains entirely on one side
   bool wickTouches = (pHigh >= mid && pLow <= mid);
   bool bodyAbove = (pOpen > mid && pClose > mid);
   bool bodyBelow = (pOpen < mid && pClose < mid);
   return wickTouches && (bodyAbove || bodyBelow);
}

//+------------------------------------------------------------------+
//| Process Phase 5 interactions                                     |
//+------------------------------------------------------------------+
void ProcessPhase5(int idx, const double &open[], const double &high[], const double &low[], const double &close[], LevelState &state) {
   if(idx < 1) return;
   
   double up = BufferUp[idx];
   double down = BufferDown[idx];
   double mid = BufferMid[idx];
   double res = BufferResistance[idx];
   double sup = BufferSupport[idx];
   
   if(up == EMPTY_VALUE || down == EMPTY_VALUE) return;

   // Midline overlap rules
   bool midExists = true;
   if(mid >= res || mid <= sup) midExists = false;
   
   bool resSupExists = true;
   if(res <= sup) resSupExists = false;

   double curMid = midExists ? mid : EMPTY_VALUE;
   double curRes = resSupExists ? res : EMPTY_VALUE;
   double curSup = resSupExists ? sup : EMPTY_VALUE;

   // --- Push Event Logic ---
   HandlePushEvents(idx, open, high, low, close, state, up, down, curMid, curRes, curSup);

   // --- Candle-Border Interaction Logic ---
   if(state.bullishLock) {
      HandleBullishInteractions(idx, open, high, low, close, state, up, down, curMid, curRes, curSup);
   } else if(state.bearishLock) {
      HandleBearishInteractions(idx, open, high, low, close, state, up, down, curMid, curRes, curSup);
   }
}

//+------------------------------------------------------------------+
//| Push Event Logic                                                 |
//+------------------------------------------------------------------+
void HandlePushEvents(int idx, const double &open[], const double &high[], const double &low[], const double &close[], LevelState &state, double up, double down, double mid, double res, double sup) {
   double prevUp = BufferUp[idx-1];
   double prevDown = BufferDown[idx-1];
   if(prevUp == EMPTY_VALUE || prevDown == EMPTY_VALUE) return;

   // 1. Monitor for new extremes (Pushes)
   // Bullish Push (at upper line)
   bool bullPushAllowed = !state.bullishLock || (state.bosMssState == BOS_MSS_CONFIRMED_BOS || state.bosMssState == BOS_MSS_CONFIRMED_MSS);
   if(bullPushAllowed) { // Only if no lock or bearish lock (upper is disagreeing), or BOS/MSS confirmed
      bool newHigh = (up > prevUp);
      if(newHigh) {
         bool isBullishCandle = (close[idx] > open[idx]);
         bool isBearishCandle = (close[idx] < open[idx]);
         
         int crossed = 0;
         if(IsClosedThrough(open[idx], close[idx], res)) crossed++;
         if(IsClosedThrough(open[idx], close[idx], mid)) crossed++;
         if(IsClosedThrough(open[idx], close[idx], sup)) crossed++;
         bool midTouch = IsMidlineTouch(open[idx], high[idx], low[idx], close[idx], mid);

         if(isBullishCandle) { // Cross push
            if(crossed <= 1 && !(crossed > 0 && midTouch)) {
               state.bullPushState.active = true;
               state.bullPushState.isCrossPush = true;
               state.bullPushState.triggerBarIdx = idx;
               state.bullPushState.triggerOpen = open[idx];
               state.bullPushState.extremeBetween = MathMin(low[idx], low[idx-1]);

               if(state.bosMssTriggerIdx == idx && (state.bosMssState == BOS_MSS_TRIGGERED_BOS || state.bosMssState == BOS_MSS_TRIGGERED_MSS)) {
                  state.bosMssIsPush = true;
                  state.bosMssIsCrossPush = true;
                  state.bosMssTriggerOpen = state.bullPushState.triggerOpen;
                  state.bosMssExtremeBetween = state.bullPushState.extremeBetween;
               }
            } else {
               state.bullPushState.active = false;
            }
         } else if(isBearishCandle) { // Counter-cross push
            // Preceding candle must touch upper line
            if(high[idx-1] >= prevUp && crossed <= 2) {
               state.bullPushState.active = true;
               state.bullPushState.isCrossPush = false;
               state.bullPushState.triggerBarIdx = idx;
               state.bullPushState.triggerOpen = open[idx];
               state.bullPushState.extremeBetween = 0; // Not used for CC push

               if(state.bosMssTriggerIdx == idx && (state.bosMssState == BOS_MSS_TRIGGERED_BOS || state.bosMssState == BOS_MSS_TRIGGERED_MSS)) {
                  state.bosMssIsPush = true;
                  state.bosMssIsCrossPush = false;
                  state.bosMssTriggerOpen = state.bullPushState.triggerOpen;
                  state.bosMssExtremeBetween = 0;
               }
            } else {
               state.bullPushState.active = false; 
            }
         } else {
            state.bullPushState.active = false;
         }
      }
   } else {
      state.bullPushState.active = false;
   }

   // Bearish Push (at lower line)
   bool bearPushAllowed = !state.bearishLock || (state.bosMssState == BOS_MSS_CONFIRMED_BOS || state.bosMssState == BOS_MSS_CONFIRMED_MSS);
   if(bearPushAllowed) { // Only if no lock or bullish lock (lower is disagreeing), or BOS/MSS confirmed
      bool newLow = (down < prevDown);
      if(newLow) {
         bool isBearishCandle = (close[idx] < open[idx]);
         bool isBullishCandle = (close[idx] > open[idx]);

         int crossed = 0;
         if(IsClosedThrough(open[idx], close[idx], res)) crossed++;
         if(IsClosedThrough(open[idx], close[idx], mid)) crossed++;
         if(IsClosedThrough(open[idx], close[idx], sup)) crossed++;
         bool midTouch = IsMidlineTouch(open[idx], high[idx], low[idx], close[idx], mid);

         if(isBearishCandle) { // Cross push
            if(crossed <= 1 && !(crossed > 0 && midTouch)) {
               state.bearPushState.active = true;
               state.bearPushState.isCrossPush = true;
               state.bearPushState.triggerBarIdx = idx;
               state.bearPushState.triggerOpen = open[idx];
               state.bearPushState.extremeBetween = MathMax(high[idx], high[idx-1]);

               if(state.bosMssTriggerIdx == idx && (state.bosMssState == BOS_MSS_TRIGGERED_BOS || state.bosMssState == BOS_MSS_TRIGGERED_MSS)) {
                  state.bosMssIsPush = true;
                  state.bosMssIsCrossPush = true;
                  state.bosMssTriggerOpen = state.bearPushState.triggerOpen;
                  state.bosMssExtremeBetween = state.bearPushState.extremeBetween;
               }
            } else {
               state.bearPushState.active = false;
            }
         } else if(isBullishCandle) { // Counter-cross push
            // Preceding candle must touch lower line
            if(low[idx-1] <= prevDown && crossed <= 2) {
               state.bearPushState.active = true;
               state.bearPushState.isCrossPush = false;
               state.bearPushState.triggerBarIdx = idx;
               state.bearPushState.triggerOpen = open[idx];
               state.bearPushState.extremeBetween = 0;

               if(state.bosMssTriggerIdx == idx && (state.bosMssState == BOS_MSS_TRIGGERED_BOS || state.bosMssState == BOS_MSS_TRIGGERED_MSS)) {
                  state.bosMssIsPush = true;
                  state.bosMssIsCrossPush = false;
                  state.bosMssTriggerOpen = state.bearPushState.triggerOpen;
                  state.bosMssExtremeBetween = 0;
               }
            } else {
               state.bearPushState.active = false;
            }
         } else {
            state.bearPushState.active = false;
         }
      }
   } else {
      state.bearPushState.active = false;
   }

   // 2. Monitor for counter-cross of pushed extremes
   // Bullish Push Counter-cross (at Resistance)
   if(state.bullPushState.active && res != EMPTY_VALUE) {
      // Disruption: intervening bullish candle (except for CC push itself if it's the trigger)
      if(idx > state.bullPushState.triggerBarIdx && close[idx] > open[idx]) {
         state.bullPushState.active = false;
      } else {
         // Check for counter-cross
         if(close[idx] <= res) {
            bool valid = true;
            if(state.bullPushState.isCrossPush) {
               // 50% rule
               double range = state.bullPushState.triggerOpen - state.bullPushState.extremeBetween;
               if(low[idx] < state.bullPushState.extremeBetween + 0.5 * range) valid = false;
               
               // Balding for cross push
               bool crossBald = (low[state.bullPushState.triggerBarIdx] == close[state.bullPushState.triggerBarIdx]);
               bool ccBald = (low[idx] == open[idx]);
               if(crossBald || ccBald) {
                  if(!(crossBald && ccBald && (idx == state.bullPushState.triggerBarIdx + 1))) {
                     valid = false;
                     // We don't mark stale here as push levels are dynamic/outer, 
                     // but requirements say "failed balding invalidates that particular border level"
                  }
               }
            }
            // Max internal border crossing rule: counter-cross push candle must not close through > 2 internal borders.
            // Other counter-crosses (for cross push) must not close through > 1 internal border.
            int crossed = 0;
            if(IsClosedThrough(open[idx], close[idx], res)) crossed++;
            if(IsClosedThrough(open[idx], close[idx], mid)) crossed++;
            if(IsClosedThrough(open[idx], close[idx], sup)) crossed++;
            
            if(state.bullPushState.isCrossPush) {
               if(crossed > 1) valid = false;
            } else {
               if(idx == state.bullPushState.triggerBarIdx) {
                  if(crossed > 2) valid = false;
               } else {
                  if(crossed > 1) valid = false;
               }
            }

            if(valid) {
               BufferBearishEvents[idx] = high[idx];
               state.bullPushState.active = false;
            }
         }
      }
   }

   // Bearish Push Counter-cross (at Support)
   if(state.bearPushState.active && sup != EMPTY_VALUE) {
      // Disruption: intervening bearish candle
      if(idx > state.bearPushState.triggerBarIdx && close[idx] < open[idx]) {
         state.bearPushState.active = false;
      } else {
         // Check for counter-cross
         if(close[idx] >= sup) {
            bool valid = true;
            if(state.bearPushState.isCrossPush) {
               // 50% rule
               double range = state.bearPushState.extremeBetween - state.bearPushState.triggerOpen;
               if(high[idx] > state.bearPushState.extremeBetween - 0.5 * range) valid = false;
               
               // Balding for cross push
               bool crossBald = (high[state.bearPushState.triggerBarIdx] == close[state.bearPushState.triggerBarIdx]);
               bool ccBald = (high[idx] == open[idx]);
               if(crossBald || ccBald) {
                  if(!(crossBald && ccBald && (idx == state.bearPushState.triggerBarIdx + 1))) {
                     valid = false;
                  }
               }
            }
            int crossed = 0;
            if(IsClosedThrough(open[idx], close[idx], res)) crossed++;
            if(IsClosedThrough(open[idx], close[idx], mid)) crossed++;
            if(IsClosedThrough(open[idx], close[idx], sup)) crossed++;

            if(state.bearPushState.isCrossPush) {
               if(crossed > 1) valid = false;
            } else {
               if(idx == state.bearPushState.triggerBarIdx) {
                  if(crossed > 2) valid = false;
               } else {
                  if(crossed > 1) valid = false;
               }
            }

            if(valid) {
               BufferBullishEvents[idx] = low[idx];
               state.bearPushState.active = false;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Bullish Interaction Logic                                        |
//+------------------------------------------------------------------+
void HandleBullishInteractions(int idx, const double &open[], const double &high[], const double &low[], const double &close[], LevelState &state, double up, double down, double mid, double res, double sup) {
   // If BOS/MSS is confirmed, resistance zone and midline become partial bearish lock zones
   bool resMidAgree = (state.bosMssState == BOS_MSS_NONE || state.bosMssState == BOS_MSS_TRIGGERED_BOS || state.bosMssState == BOS_MSS_TRIGGERED_MSS);
   
   // Support is always disagreeing internal border for active bullish lock
   ProcessInteraction(idx, open, high, low, close, state.supState, sup, true, false, state, true);
   
   if(resMidAgree) {
      // Normal bullish lock logic
      ProcessInteraction(idx, open, high, low, close, state.resState, res, true, true, state, true);
      ProcessInteraction(idx, open, high, low, close, state.midState, mid, true, true, state, true);
   } else {
      // BOS/MSS Confirmed: Resistance and Midline switch to Bearish interaction logic
      // Resistance is disagreeing for bearish lock
      ProcessInteraction(idx, open, high, low, close, state.resState, res, false, false, state, false);
      // Midline uses agreeing rules for any lock
      ProcessInteraction(idx, open, high, low, close, state.midState, mid, false, true, state, false);
   }
}

//+------------------------------------------------------------------+
//| Bearish Interaction Logic                                        |
//+------------------------------------------------------------------+
void HandleBearishInteractions(int idx, const double &open[], const double &high[], const double &low[], const double &close[], LevelState &state, double up, double down, double mid, double res, double sup) {
   // If BOS/MSS is confirmed, support zone and midline become partial bullish lock zones
   bool supMidAgree = (state.bosMssState == BOS_MSS_NONE || state.bosMssState == BOS_MSS_TRIGGERED_BOS || state.bosMssState == BOS_MSS_TRIGGERED_MSS);
   
   // Resistance is always disagreeing internal border for active bearish lock
   ProcessInteraction(idx, open, high, low, close, state.resState, res, false, false, state, false);
   
   if(supMidAgree) {
      // Normal bearish lock logic
      ProcessInteraction(idx, open, high, low, close, state.midState, mid, false, true, state, false);
      ProcessInteraction(idx, open, high, low, close, state.supState, sup, false, true, state, false);
   } else {
      // BOS/MSS Confirmed: Support and Midline switch to Bullish interaction logic
      // Midline uses agreeing rules
      ProcessInteraction(idx, open, high, low, close, state.midState, mid, true, true, state, true);
      // Support is disagreeing for bullish lock
      ProcessInteraction(idx, open, high, low, close, state.supState, sup, true, false, state, true);
   }
}

//+------------------------------------------------------------------+
//| Phase 6 BOS/MSS Logic                                            |
//+------------------------------------------------------------------+
void HandleBOSMSS(int idx, const double &open[], const double &high[], const double &low[], const double &close[], const datetime &time[], LevelState &state) {
   if(!state.bullishLock && !state.bearishLock) return;

   double res = BufferResistance[idx];
   double sup = BufferSupport[idx];
   double mid = BufferMid[idx];

   // 1. Handle Confirmation and Resets for TRIGGERED state
   if(state.bosMssState == BOS_MSS_TRIGGERED_BOS || state.bosMssState == BOS_MSS_TRIGGERED_MSS) {
      // Disruption/Reset rules for TRIGGERED state
      bool reset = false;
      if(state.bullishLock) {
         // Evolution check
         if(state.highAnchors[1].id == state.bosMssTriggerSemaforId && state.highAnchors[1].barIndex > state.bosMssTriggerIdx) {
            reset = true; // Evolution (higher LH) resets TRIGGERED state
         }
         // New same-type semafor check
         if(state.highAnchors[1].id > state.bosMssTriggerSemaforId) {
            reset = true;
         }
      } else {
         if(state.lowAnchors[1].id == state.bosMssTriggerSemaforId && state.lowAnchors[1].barIndex > state.bosMssTriggerIdx) {
            reset = true;
         }
         if(state.lowAnchors[1].id > state.bosMssTriggerSemaforId) {
            reset = true;
         }
      }

      if(reset) {
         state.bosMssState = BOS_MSS_NONE;
         return;
      }

      bool confirmAttempt = false;
      bool confirmed = false;
      
      if(state.bullishLock) {
         // Agreeing internal border is Resistance. Confirm on close back within (close < resistance).
         if(res != EMPTY_VALUE && close[idx] < res) {
            confirmAttempt = true;
            
            // Apply Phase 5 rules
            bool valid = true;
            int crossed = 0;
            if(IsClosedThrough(open[idx], close[idx], res)) crossed++;
            if(IsClosedThrough(open[idx], close[idx], mid)) crossed++;
            if(IsClosedThrough(open[idx], close[idx], sup)) crossed++;
            
            // Confirmation candle is affected by push rules and border rules only.
            // If the trigger semafor was a push candle, use push rules.
            if(state.bosMssIsPush) {
               if(state.bosMssIsCrossPush) {
                  if(crossed > 1) valid = false;
                  double range = state.bosMssTriggerOpen - state.bosMssExtremeBetween;
                  if(low[idx] < state.bosMssExtremeBetween + 0.5 * range) valid = false;
                  
                  // Balding for cross push exception
                  bool crossBald = (low[state.bosMssTriggerIdx] == close[state.bosMssTriggerIdx]);
                  bool ccBald = (low[idx] == open[idx]);
                  if(crossBald || ccBald) {
                     if(!(crossBald && ccBald && (idx == state.bosMssTriggerIdx + 1))) {
                        valid = false;
                     }
                  }
               } else {
                  if(idx == state.bosMssTriggerIdx) {
                     if(crossed > 2) valid = false;
                  } else {
                     if(crossed > 1) valid = false;
                  }
               }
            } else {
               // Normal border rules: max 1 internal border.
               if(crossed > 1) valid = false;
            }
            
            if(valid) confirmed = true;
         }
      } else {
         // Bearish Lock: Agreeing internal border is Support. Confirm on close back within (close > support).
         if(sup != EMPTY_VALUE && close[idx] > sup) {
            confirmAttempt = true;
            
            bool valid = true;
            int crossed = 0;
            if(IsClosedThrough(open[idx], close[idx], res)) crossed++;
            if(IsClosedThrough(open[idx], close[idx], mid)) crossed++;
            if(IsClosedThrough(open[idx], close[idx], sup)) crossed++;
            
            if(state.bosMssIsPush) {
               if(state.bosMssIsCrossPush) {
                  if(crossed > 1) valid = false;
                  double range = state.bosMssExtremeBetween - state.bosMssTriggerOpen;
                  if(high[idx] > state.bosMssExtremeBetween - 0.5 * range) valid = false;
                  
                  // Balding for cross push exception
                  bool crossBald = (high[state.bosMssTriggerIdx] == close[state.bosMssTriggerIdx]);
                  bool ccBald = (high[idx] == open[idx]);
                  if(crossBald || ccBald) {
                     if(!(crossBald && ccBald && (idx == state.bosMssTriggerIdx + 1))) {
                        valid = false;
                     }
                  }
               } else {
                  if(idx == state.bosMssTriggerIdx) {
                     if(crossed > 2) valid = false;
                  } else {
                     if(crossed > 1) valid = false;
                  }
               }
            } else {
               if(crossed > 1) valid = false;
            }
            
            if(valid) confirmed = true;
         }
      }

      if(confirmed) {
         bool isMss = (state.bosMssState == BOS_MSS_TRIGGERED_MSS);
         if(state.bosMssState == BOS_MSS_TRIGGERED_BOS) state.bosMssState = BOS_MSS_CONFIRMED_BOS;
         else state.bosMssState = BOS_MSS_CONFIRMED_MSS;
         
         // MSS immediate lock trigger check
         bool lockTriggered = false;
         if(isMss) {
            if(state.bullishLock) {
               if(state.totalExpansionBearish <= -12000) {
                  TriggerBearishLock(state, idx, time[idx]);
                  lockTriggered = true;
               }
            } else {
               if(state.totalExpansionBullish >= 12000) {
                  TriggerBullishLock(state, idx, time[idx]);
                  lockTriggered = true;
               }
            }
         }
         
         // Highlight confirmation candle
         if(state.bullishLock) BufferBearishEvents[idx] = high[idx];
         else BufferBullishEvents[idx] = low[idx];

         if(!lockTriggered) {
            DrawBOSMSSLine(idx, time[idx]);
         }
      } else if(confirmAttempt) {
         // "If the first candle that closes back within the agreeing internal border ... failed to confirm ... then the triggered state resets."
         state.bosMssState = BOS_MSS_NONE;
      }
   }
   
   // 2. Handle Resets for Confirmed state
   if(state.bosMssState == BOS_MSS_CONFIRMED_BOS || state.bosMssState == BOS_MSS_CONFIRMED_MSS) {
      if(state.bullishLock) {
         // Reset when close beyond disagreeing border (support) and back within.
         // Must be a valid counter-cross.
         if(sup != EMPTY_VALUE && close[idx] > sup && close[idx-1] < sup) {
            // Validate Phase 5 rules for this reset counter-cross
            int crossed = 0;
            if(IsClosedThrough(open[idx], close[idx], res)) crossed++;
            if(IsClosedThrough(open[idx], close[idx], mid)) crossed++;
            if(IsClosedThrough(open[idx], close[idx], sup)) crossed++;
            
            if(crossed <= 1) {
               state.bosMssState = BOS_MSS_NONE;
            }
         }
      } else {
         // Bearish lock: disagreeing border is Resistance.
         if(res != EMPTY_VALUE && close[idx] < res && close[idx-1] > res) {
            int crossed = 0;
            if(IsClosedThrough(open[idx], close[idx], res)) crossed++;
            if(IsClosedThrough(open[idx], close[idx], mid)) crossed++;
            if(IsClosedThrough(open[idx], close[idx], sup)) crossed++;
            
            if(crossed <= 1) {
               state.bosMssState = BOS_MSS_NONE;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Generic Interaction Processor                                    |
//+------------------------------------------------------------------+
void ProcessInteraction(int idx, const double &open[], const double &high[], const double &low[], const double &close[], BorderState &bs, double border, bool isBullishLock, bool isAgreeing, LevelState &state, bool toBullBuffer) {
   if(border == EMPTY_VALUE) {
      bs.activeType = INT_NONE;
      return;
   }
   
   // Check staleness (failed balding)
   if(bs.isStale) {
      if(border != bs.staleLevel) {
         bs.isStale = false;
      } else {
         return; // Level still stale
      }
   }

   bool isBearishCandle = (close[idx] < open[idx]);
   bool isBullishCandle = (close[idx] > open[idx]);
   
   // Internal borders for crossing/touching rules
   double r = BufferResistance[idx];
   double m = BufferMid[idx];
   double s = BufferSupport[idx];

   // 1. Check for Counter-cross if active
   if(bs.activeType != INT_NONE) {
      bool counterCross = false;
      bool failedCounterCross = false;
      bool disrupted = false;

      if(isBullishLock) {
         // Bullish counter-cross: bullish candle closes above border
         if(isBullishCandle && close[idx] >= border) counterCross = true;
         // Failed: touches but fails to close above
         else if(high[idx] >= border && close[idx] < border) failedCounterCross = true;
         // Disruption: (bullish) cross/swipe disrupted by bearish float
         else if(isBearishCandle && low[idx] > border) disrupted = true;
      } else {
         // Bearish counter-cross: bearish candle closes below border
         if(isBearishCandle && close[idx] <= border) counterCross = true;
         // Failed: touches but fails to close below
         else if(low[idx] <= border && close[idx] > border) failedCounterCross = true;
         // Disruption: (bearish) cross/swipe disrupted by bullish float
         else if(isBullishCandle && high[idx] < border) disrupted = true;
      }

      if(counterCross) {
         // Validate rules: max crossing, midline touch, balding
         bool valid = true;
         
         // Border crossing rules
         int crossed = 0;
         if(IsClosedThrough(open[idx], close[idx], r)) crossed++;
         if(IsClosedThrough(open[idx], close[idx], m)) crossed++;
         if(IsClosedThrough(open[idx], close[idx], s)) crossed++;
         if(crossed > 1) valid = false; // counter-cross candle must not close through > 1 internal border.
         
         // Counter-cross is immune to midline touch rule
         
         // Special rules for midline + agreeing internal border
         if(isAgreeing && (border == r || border == s || border == m)) {
            // Preceding must have more extreme extreme
            if(isBullishLock) {
               // the candle preceding the (bullish) cross/swipe must have a higher high than the (bullish) cross/swipe.
               if(high[bs.triggerBarIdx-1] <= high[bs.triggerBarIdx]) valid = false;
               // 50% rule: high must not reach more than 50% of (high[preceding] - open[trigger]) from open[trigger]
               double dist = high[bs.triggerBarIdx-1] - bs.triggerOpen;
               if(high[idx] > bs.triggerOpen + 0.5 * dist) valid = false;
               
               // Intervening bullish float candles disrupt
               for(int j = bs.triggerBarIdx + 1; j < idx; j++) {
                  if(close[j] > open[j] && low[j] > border) { valid = false; break; }
               }
               // "The two candles must occur side by side."
               if(idx != bs.triggerBarIdx + 1) valid = false;
            } else {
               // the candle preceding the (bearish) cross/swipe must have a lower low than the (bearish) cross/swipe.
               if(low[bs.triggerBarIdx-1] >= low[bs.triggerBarIdx]) valid = false;
               // 50% rule: low must not reach more than 50% of (open[trigger] - low[preceding]) from open[trigger]
               double dist = bs.triggerOpen - low[bs.triggerBarIdx-1];
               if(low[idx] < bs.triggerOpen - 0.5 * dist) valid = false;
               
               // Intervening bearish float candles disrupt
               for(int j = bs.triggerBarIdx + 1; j < idx; j++) {
                  if(close[j] < open[j] && high[j] < border) { valid = false; break; }
               }
               // "The two candles must occur side by side."
               if(idx != bs.triggerBarIdx + 1) valid = false;
            }
         }

         // Balding
         if(border != m && (border == r || border == s || border == BufferUp[idx] || border == BufferDown[idx])) {
            bool crossBald = false;
            bool ccBald = false;
            if(isBullishLock) {
               if(low[bs.triggerBarIdx] == close[bs.triggerBarIdx]) crossBald = true;
               if(low[idx] == open[idx]) ccBald = true;
            } else {
               if(high[bs.triggerBarIdx] == close[bs.triggerBarIdx]) crossBald = true;
               if(high[idx] == open[idx]) ccBald = true;
            }
            
            if(crossBald || ccBald) {
               if(crossBald && ccBald && (idx == bs.triggerBarIdx + 1)) {
                  // Valid balding pair
               } else {
                  // Failed balding
                  bs.isStale = true;
                  bs.staleLevel = border;
                  valid = false;
               }
            }
         }

         if(valid) {
            if(toBullBuffer) BufferBullishEvents[idx] = low[idx];
            else BufferBearishEvents[idx] = high[idx];
         }
         bs.activeType = INT_NONE;
      } else if(disrupted || failedCounterCross) {
         bs.activeType = INT_NONE;
      }
   }

   // 2. Check for new Cross/Swipe
   int crossed = 0;
   if(IsClosedThrough(open[idx], close[idx], r)) crossed++;
   if(IsClosedThrough(open[idx], close[idx], m)) crossed++;
   if(IsClosedThrough(open[idx], close[idx], s)) crossed++;
   bool midTouch = IsMidlineTouch(open[idx], high[idx], low[idx], close[idx], m);
   bool midConstraint = (crossed > 0 && midTouch);

   if(isBullishLock) {
      // (Bullish) Cross: bearish candle closes beneath border
      if(isBearishCandle && open[idx] >= border && close[idx] < border) {
         if(crossed <= 1 && !midConstraint) {
            bs.activeType = INT_CROSS;
            bs.triggerBarIdx = idx;
            bs.triggerOpen = open[idx];
            bs.precedingExtreme = high[idx-1];
         } else bs.activeType = INT_NONE;
      }
      // (Bullish) Swipe: upper wick touches border
      else if(isBearishCandle && open[idx] < border && high[idx] >= border) {
         if(crossed <= 1 && !midConstraint) {
            bs.activeType = INT_SWIPE;
            bs.triggerBarIdx = idx;
            bs.triggerOpen = open[idx];
            bs.precedingExtreme = high[idx-1];
         } else bs.activeType = INT_NONE;
      }
      // Special midline counter-cross push
      else if(border == m && isBullishCandle && open[idx] > border && close[idx] > border && low[idx] <= border && low[idx-1] > border) {
          if(crossed == 0) BufferBullishEvents[idx] = low[idx];
      }
   } else {
      // (Bearish) Cross: bullish candle closes above border
      if(isBullishCandle && open[idx] <= border && close[idx] > border) {
         if(crossed <= 1 && !midConstraint) {
            bs.activeType = INT_CROSS;
            bs.triggerBarIdx = idx;
            bs.triggerOpen = open[idx];
            bs.precedingExtreme = low[idx-1];
         } else bs.activeType = INT_NONE;
      }
      // (Bearish) Swipe: lower wick touches border
      else if(isBullishCandle && open[idx] > border && low[idx] <= border) {
         if(crossed <= 1 && !midConstraint) {
            bs.activeType = INT_SWIPE;
            bs.triggerBarIdx = idx;
            bs.triggerOpen = open[idx];
            bs.precedingExtreme = low[idx-1];
         } else bs.activeType = INT_NONE;
      }
      // Special midline counter-cross push
      else if(border == m && isBearishCandle && open[idx] < border && close[idx] < border && high[idx] >= border && high[idx-1] < border) {
          if(crossed == 0) BufferBearishEvents[idx] = high[idx];
      }
   }
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
void ProcessLevel(int idx, int period, int backstep, int firstBar, const double &pOpen[], const double &pHigh[], const double &pLow[], const double &pClose[], const datetime &pTime[], LevelState &state, double &bufH[], double &bufL[], bool isLevel2) {
   // Check if enough candles exist since the start of the day to satisfy Period requirement
   if(idx - firstBar < period - 1) return;

   double res = 0, up = 0, dn = 0, sup = 0;
   bool inZone = false;

   // --- High Semafor ---
   bool isHighSemafor = true;
   for(int j = idx - 1; j > idx - period; j--) {
      // Equal high does not qualify as higher high
      if(pHigh[idx] <= pHigh[j]) {
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
            state.highAnchors[1].price = pHigh[idx];
            state.highAnchors[1].time = pTime[idx];
            bufH[idx] = pHigh[idx];
            repainted = true;
            
            if(isLevel2 && state.highAnchors[0].isActive) {
               UpdateL2HighConnection(state.highAnchors[0], state.highAnchors[1]);
               
               // Phase 3: Evaluate lock on repaint
               if(!state.bullishLock) {
                  double current_temp = (state.highAnchors[1].price - state.highAnchors[0].price) / _Point;
                  double threshold = 24000;
                  if(state.bearishLock && state.bosMssState == BOS_MSS_CONFIRMED_MSS) threshold = 12000;
                  if(state.totalExpansionBullish + current_temp >= threshold) {
                     TriggerBullishLock(state, idx, pTime[idx]);
                  }
               }
               // Phase 6: Evaluate BOS/MSS on repaint
               else if(state.bullishLock) {
                  bool canTrigger = (state.bosMssState == BOS_MSS_NONE || state.bosMssState == BOS_MSS_TRIGGERED_BOS || state.bosMssState == BOS_MSS_TRIGGERED_MSS);
                  if(canTrigger) {
                     state.bosMssState = BOS_MSS_NONE;
                     res = BufferResistance[idx];
                     up = BufferUp[idx];
                     inZone = (res != EMPTY_VALUE && up != EMPTY_VALUE && ((pOpen[idx] > res && pOpen[idx] < up) || (pClose[idx] > res && pClose[idx] < up)));
                     if(inZone) {
                        double current_temp = (state.highAnchors[1].price - state.highAnchors[0].price) / _Point;
                        double val = state.totalContractionBullish + current_temp;
                        if(val <= -24000) { 
                           state.bosMssState = BOS_MSS_TRIGGERED_MSS; 
                           state.bosMssTriggerIdx = idx; 
                           state.bosMssTriggerSemaforId = state.highAnchors[1].id;
                        }
                        else if(val <= -9500) { 
                           state.bosMssState = BOS_MSS_TRIGGERED_BOS; 
                           state.bosMssTriggerIdx = idx; 
                           state.bosMssTriggerSemaforId = state.highAnchors[1].id;
                        }
                     }
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
         state.highAnchors[1].price = pHigh[idx];
         state.highAnchors[1].time = pTime[idx];
         state.highAnchors[1].isActive = true;
         state.highAnchors[1].id = state.highCounter;
         bufH[idx] = pHigh[idx];
         
         if(isLevel2 && state.highAnchors[0].isActive) {
            UpdateL2HighConnection(state.highAnchors[0], state.highAnchors[1]);
            
            // Phase 3: Evaluate lock on new anchor
            if(!state.bullishLock) {
               double current_temp = (state.highAnchors[1].price - state.highAnchors[0].price) / _Point;
               double threshold = 24000;
               if(state.bearishLock && state.bosMssState == BOS_MSS_CONFIRMED_MSS) threshold = 12000;
               if(state.totalExpansionBullish + current_temp >= threshold) {
                  TriggerBullishLock(state, idx, pTime[idx]);
               }
            }
            // Phase 6: Evaluate BOS/MSS on new anchor
            else if(state.bullishLock) {
               bool canTrigger = (state.bosMssState == BOS_MSS_NONE || state.bosMssState == BOS_MSS_TRIGGERED_BOS || state.bosMssState == BOS_MSS_TRIGGERED_MSS);
               if(canTrigger) {
                  state.bosMssState = BOS_MSS_NONE;
                  res = BufferResistance[idx];
                  up = BufferUp[idx];
                  inZone = (res != EMPTY_VALUE && up != EMPTY_VALUE && ((pOpen[idx] > res && pOpen[idx] < up) || (pClose[idx] > res && pClose[idx] < up)));
                  if(inZone) {
                     double current_temp = (state.highAnchors[1].price - state.highAnchors[0].price) / _Point;
                     double val = state.totalContractionBullish + current_temp;
                     if(val <= -24000) { 
                        state.bosMssState = BOS_MSS_TRIGGERED_MSS; 
                        state.bosMssTriggerIdx = idx; 
                        state.bosMssTriggerSemaforId = state.highAnchors[1].id;
                     }
                     else if(val <= -9500) { 
                        state.bosMssState = BOS_MSS_TRIGGERED_BOS; 
                        state.bosMssTriggerIdx = idx; 
                        state.bosMssTriggerSemaforId = state.highAnchors[1].id;
                     }
                  }
               }
            }
         }
      }
   }

   // --- Low Semafor ---
   bool isLowSemafor = true;
   for(int j = idx - 1; j > idx - period; j--) {
      // Equal low does not qualify as lower low
      if(pLow[idx] >= pLow[j]) {
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
            state.lowAnchors[1].price = pLow[idx];
            state.lowAnchors[1].time = pTime[idx];
            bufL[idx] = pLow[idx];
            repainted = true;
            
            if(isLevel2 && state.lowAnchors[0].isActive) {
               UpdateL2LowConnection(state.lowAnchors[0], state.lowAnchors[1]);
               
               // Phase 3: Evaluate lock on repaint
               if(!state.bearishLock) {
                  double current_temp = (state.lowAnchors[1].price - state.lowAnchors[0].price) / _Point;
                  double threshold = -24000;
                  if(state.bullishLock && state.bosMssState == BOS_MSS_CONFIRMED_MSS) threshold = -12000;
                  if(state.totalExpansionBearish + current_temp <= threshold) {
                     TriggerBearishLock(state, idx, pTime[idx]);
                  }
               }
               // Phase 6: Evaluate BOS/MSS on repaint
               else if(state.bearishLock) {
                  bool canTrigger = (state.bosMssState == BOS_MSS_NONE || state.bosMssState == BOS_MSS_TRIGGERED_BOS || state.bosMssState == BOS_MSS_TRIGGERED_MSS);
                  if(canTrigger) {
                     state.bosMssState = BOS_MSS_NONE;
                     sup = BufferSupport[idx];
                     dn = BufferDown[idx];
                     inZone = (sup != EMPTY_VALUE && dn != EMPTY_VALUE && ((pOpen[idx] < sup && pOpen[idx] > dn) || (pClose[idx] < sup && pClose[idx] > dn)));
                     if(inZone) {
                        double current_temp = (state.lowAnchors[1].price - state.lowAnchors[0].price) / _Point;
                        double val = state.totalContractionBearish + current_temp;
                        if(val >= 24000) { 
                           state.bosMssState = BOS_MSS_TRIGGERED_MSS; 
                           state.bosMssTriggerIdx = idx; 
                           state.bosMssTriggerSemaforId = state.lowAnchors[1].id;
                        }
                        else if(val >= 9500) { 
                           state.bosMssState = BOS_MSS_TRIGGERED_BOS; 
                           state.bosMssTriggerIdx = idx; 
                           state.bosMssTriggerSemaforId = state.lowAnchors[1].id;
                        }
                     }
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
         state.lowAnchors[1].price = pLow[idx];
         state.lowAnchors[1].time = pTime[idx];
         state.lowAnchors[1].isActive = true;
         state.lowAnchors[1].id = state.lowCounter;
         bufL[idx] = pLow[idx];
         
         if(isLevel2 && state.lowAnchors[0].isActive) {
            UpdateL2LowConnection(state.lowAnchors[0], state.lowAnchors[1]);
            
            // Phase 3: Evaluate lock on new anchor
            if(!state.bearishLock) {
               double current_temp = (state.lowAnchors[1].price - state.lowAnchors[0].price) / _Point;
               double threshold = -24000;
               if(state.bullishLock && state.bosMssState == BOS_MSS_CONFIRMED_MSS) threshold = -12000;
               if(state.totalExpansionBearish + current_temp <= threshold) {
                  TriggerBearishLock(state, idx, pTime[idx]);
               }
            }
            // Phase 6: Evaluate BOS/MSS on new anchor
            else if(state.bearishLock) {
               bool canTrigger = (state.bosMssState == BOS_MSS_NONE || state.bosMssState == BOS_MSS_TRIGGERED_BOS || state.bosMssState == BOS_MSS_TRIGGERED_MSS);
               if(canTrigger) {
                  state.bosMssState = BOS_MSS_NONE;
                  sup = BufferSupport[idx];
                  dn = BufferDown[idx];
                  inZone = (sup != EMPTY_VALUE && dn != EMPTY_VALUE && ((pOpen[idx] < sup && pOpen[idx] > dn) || (pClose[idx] < sup && pClose[idx] > dn)));
                  if(inZone) {
                     double current_temp = (state.lowAnchors[1].price - state.lowAnchors[0].price) / _Point;
                     double val = state.totalContractionBearish + current_temp;
                     if(val >= 24000) { 
                        state.bosMssState = BOS_MSS_TRIGGERED_MSS; 
                        state.bosMssTriggerIdx = idx; 
                        state.bosMssTriggerSemaforId = state.lowAnchors[1].id;
                     }
                     else if(val >= 9500) { 
                        state.bosMssState = BOS_MSS_TRIGGERED_BOS; 
                        state.bosMssTriggerIdx = idx; 
                        state.bosMssTriggerSemaforId = state.lowAnchors[1].id;
                     }
                  }
               }
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
