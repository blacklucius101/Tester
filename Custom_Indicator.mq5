//+------------------------------------------------------------------+
//|                                             Custom_Indicator.mq5 |
//|                                  Copyright 2024, Software Agency |
//|                                       Optimized for BTCUSD M1    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property version   "1.10"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4

//--- plot Level 1 High
#property indicator_label1  "Level 1 High"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrAqua
#property indicator_width1  1
//--- plot Level 1 Low
#property indicator_label2  "Level 1 Low"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrMagenta
#property indicator_width2  1
//--- plot Level 2 High
#property indicator_label3  "Level 2 High"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrAqua
#property indicator_width3  1
//--- plot Level 2 Low
#property indicator_label4  "Level 2 Low"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrMagenta
#property indicator_width4  1

//--- input parameters
input datetime InpHistoricalDate = 0; // Historical Date (YYYY.MM.DD) - 0 for Current Day

//--- indicator buffers
double         BufferL1H[];
double         BufferL1L[];
double         BufferL2H[];
double         BufferL2L[];

//--- Level Settings (Hardcoded as per requirements)
const int L1_PERIOD = 2;
const int L1_BACKSTEP = 2;
const int L1_ARROW = 159;

const int L2_PERIOD = 13;
const int L2_BACKSTEP = 5;
const int L2_ARROW = 108;

//--- Anchor structure for state retention
struct SemaforAnchor {
   int      barIndex;
   double   price;
   datetime time;
   bool     isActive;
};

struct LevelState {
   SemaforAnchor highAnchors[2]; // Two most recent HIGH anchors
   SemaforAnchor lowAnchors[2];  // Two most recent LOW anchors
   int           firstBarOfDay;
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
   //--- indicator buffers mapping
   SetIndexBuffer(0, BufferL1H, INDICATOR_DATA);
   SetIndexBuffer(1, BufferL1L, INDICATOR_DATA);
   SetIndexBuffer(2, BufferL2H, INDICATOR_DATA);
   SetIndexBuffer(3, BufferL2L, INDICATOR_DATA);

   //--- set arrow codes
   PlotIndexSetInteger(0, PLOT_ARROW, L1_ARROW);
   PlotIndexSetInteger(1, PLOT_ARROW, L1_ARROW);
   PlotIndexSetInteger(2, PLOT_ARROW, L2_ARROW);
   PlotIndexSetInteger(3, PLOT_ARROW, L2_ARROW);

   //--- set empty values
   for(int i=0; i<4; i++) PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0.0);

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
//| Reset the state for a specific level                             |
//+------------------------------------------------------------------+
void ResetLevelState(LevelState &state) {
   for(int i=0; i<2; i++) {
      state.highAnchors[i].isActive = false;
      state.highAnchors[i].barIndex = -1;
      state.highAnchors[i].price = 0;
      state.highAnchors[i].time = 0;
      state.lowAnchors[i].isActive = false;
      state.lowAnchors[i].barIndex = -1;
      state.lowAnchors[i].price = 0;
      state.lowAnchors[i].time = 0;
   }
   state.firstBarOfDay = -1;
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
   if(rates_total < MathMax(L1_PERIOD, L2_PERIOD)) return 0;

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
      ArrayInitialize(BufferL1H, 0.0);
      ArrayInitialize(BufferL1L, 0.0);
      ArrayInitialize(BufferL2H, 0.0);
      ArrayInitialize(BufferL2L, 0.0);
      
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

      ProcessLevel(i, L1_PERIOD, L1_BACKSTEP, stateL1.firstBarOfDay, high, low, time, stateL1, BufferL1H, BufferL1L);
      ProcessLevel(i, L2_PERIOD, L2_BACKSTEP, stateL2.firstBarOfDay, high, low, time, stateL2, BufferL2H, BufferL2L);
   }

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Process semafors for a specific level and candle index           |
//+------------------------------------------------------------------+
void ProcessLevel(int idx, int period, int backstep, int firstBar, const double &high[], const double &low[], const datetime &time[], LevelState &state, double &bufH[], double &bufL[]) {
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
         }
      }
      
      if(!repainted) {
         // New anchor: push previous to secondary position and finalize current
         state.highAnchors[0] = state.highAnchors[1];
         state.highAnchors[1].barIndex = idx;
         state.highAnchors[1].price = high[idx];
         state.highAnchors[1].time = time[idx];
         state.highAnchors[1].isActive = true;
         bufH[idx] = high[idx];
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
         }
      }
      
      if(!repainted) {
         // New anchor: push previous to secondary position and finalize current
         state.lowAnchors[0] = state.lowAnchors[1];
         state.lowAnchors[1].barIndex = idx;
         state.lowAnchors[1].price = low[idx];
         state.lowAnchors[1].time = time[idx];
         state.lowAnchors[1].isActive = true;
         bufL[idx] = low[idx];
      }
   }
}
//+------------------------------------------------------------------+
