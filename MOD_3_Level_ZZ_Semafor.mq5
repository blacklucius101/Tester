// this does not work: structure lines are not displayed!
//+------------------------------------------------------------------+
//|                                       3_Level_ZZ_Semafor_MS.mq5 |
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
//---- ten buffers are used for calculation and drawing the indicator
#property indicator_buffers 10
//---- eight plots are used
#property indicator_plots   8
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
//|  High Structure drawing parameters           |
//+----------------------------------------------+
//---- drawing the indicator 7 as a color section
#property indicator_type7   DRAW_COLOR_SECTION
//---- green for higher high, red for lower high
#property indicator_color7  clrGreen,clrRed
//---- dashed line
#property indicator_style7  STYLE_DASH
//---- thickness of the indicator line 7 is equal to 1
#property indicator_width7  1
//---- displaying the indicator high structure label
#property indicator_label7  "High Structure"
//+----------------------------------------------+
//|  Low Structure drawing parameters            |
//+----------------------------------------------+
//---- drawing the indicator 8 as a color section
#property indicator_type8   DRAW_COLOR_SECTION
//---- green for higher low, red for lower low
#property indicator_color8  clrGreen,clrRed
//---- dashed line
#property indicator_style8  STYLE_DASH
//---- thickness of the indicator line 8 is equal to 1
#property indicator_width8  1
//---- displaying the indicator low structure label
#property indicator_label8  "Low Structure"
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
//+----------------------------------------------+
//---- declaration of dynamic arrays that
// will be used as indicator buffers
double HighBuffer1[],LowBuffer1[];
double HighBuffer2[],LowBuffer2[];
double HighBuffer3[],LowBuffer3[];
double MSHighBuffer[],MSHighColorBuffer[];
double MSLowBuffer[],MSLowColorBuffer[];
//---- declaration of the integer variables for the start of data calculation
int StartBar1,StartBar2,StartBar3,StartBar;
//---- declaration of variables for storing indicators handles
int Handle1,Handle2,Handle3;
//---- Market Structure tracking
int last_h_idx=-1, prev_h_idx=-1;
int last_l_idx=-1, prev_l_idx=-1;
int last_rates_total=0;
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
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(LowBuffer1,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(1,HighBuffer1,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"High1");
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,HighSymbol1);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(HighBuffer1,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(2,LowBuffer2,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 3
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(2,PLOT_LABEL,"Low2");
//---- indicator symbol
   PlotIndexSetInteger(2,PLOT_ARROW,LowSymbol2);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(LowBuffer2,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(3,HighBuffer2,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 4
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(3,PLOT_LABEL,"High2");
//---- indicator symbol
   PlotIndexSetInteger(3,PLOT_ARROW,HighSymbol2);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(HighBuffer2,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(4,LowBuffer3,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 5
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(4,PLOT_LABEL,"Low3");
//---- indicator symbol
   PlotIndexSetInteger(4,PLOT_ARROW,LowSymbol3);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(LowBuffer3,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(5,HighBuffer3,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 6
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(5,PLOT_LABEL,"High3");
//---- indicator symbol
   PlotIndexSetInteger(5,PLOT_ARROW,HighSymbol3);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(HighBuffer3,true);

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

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(6,MSHighBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,StartBar2);
   PlotIndexSetString(6,PLOT_LABEL,"High Structure");
   ArraySetAsSeries(MSHighBuffer,true);

   SetIndexBuffer(7,MSHighColorBuffer,INDICATOR_COLOR_INDEX);
   ArraySetAsSeries(MSHighColorBuffer,true);

   SetIndexBuffer(8,MSLowBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(7,PLOT_DRAW_BEGIN,StartBar2);
   PlotIndexSetString(7,PLOT_LABEL,"Low Structure");
   ArraySetAsSeries(MSLowBuffer,true);

   SetIndexBuffer(9,MSLowColorBuffer,INDICATOR_COLOR_INDEX);
   ArraySetAsSeries(MSLowColorBuffer,true);

//---- initializations of a variable for the indicator short name
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,"3_Level_ZZ_Semafor_MS");
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

      last_h_idx = -1; prev_h_idx = -1;
      last_l_idx = -1; prev_l_idx = -1;
      ArrayInitialize(MSHighBuffer, EMPTY_VALUE);
      ArrayInitialize(MSHighColorBuffer, EMPTY_VALUE);
      ArrayInitialize(MSLowBuffer, EMPTY_VALUE);
      ArrayInitialize(MSLowColorBuffer, EMPTY_VALUE);
     }
   else
     {
      limit=rates_total-prev_calculated;
      to_copy1=MathMax(limit+StartBar1, 500);
      to_copy2=MathMax(limit+StartBar2, 500);
      to_copy3=MathMax(limit+StartBar3, 500);

      int diff = rates_total - last_rates_total;
      if(diff > 0)
        {
         if(last_h_idx != -1) last_h_idx += diff;
         if(prev_h_idx != -1) prev_h_idx += diff;
         if(last_l_idx != -1) last_l_idx += diff;
         if(prev_l_idx != -1) prev_l_idx += diff;
        }
     }
   last_rates_total = rates_total;

//---- copy the newly appeared data in the indicator buffers
   if(CopyBuffer(Handle1,1,0,to_copy1,HighBuffer1)<=0) return(0);
   if(CopyBuffer(Handle1,2,0,to_copy1,LowBuffer1)<=0) return(0);
   if(CopyBuffer(Handle2,1,0,to_copy2,HighBuffer2)<=0) return(0);
   if(CopyBuffer(Handle2,2,0,to_copy2,LowBuffer2)<=0) return(0);
   if(CopyBuffer(Handle3,1,0,to_copy3,HighBuffer3)<=0) return(0);
   if(CopyBuffer(Handle3,2,0,to_copy3,LowBuffer3)<=0) return(0);

//---- Market Structure
   if(prev_calculated <= 0)
     {
      int p_h = -1, p_l = -1;
      for(int i = rates_total - 1; i >= 0; i--)
        {
         double val_h = HighBuffer2[i];
         if(val_h > 0 && val_h < EMPTY_VALUE)
           {
            MSHighBuffer[i] = val_h;
            if(p_h != -1) MSHighColorBuffer[i] = (val_h > HighBuffer2[p_h]) ? 0 : 1;
            prev_h_idx = p_h;
            last_h_idx = i;
            p_h = i;
           }
         double val_l = LowBuffer2[i];
         if(val_l > 0 && val_l < EMPTY_VALUE)
           {
            MSLowBuffer[i] = val_l;
            if(p_l != -1) MSLowColorBuffer[i] = (val_l > LowBuffer2[p_l]) ? 0 : 1;
            prev_l_idx = p_l;
            last_l_idx = i;
            p_l = i;
           }
        }
     }
   else
     {
      // Highs
      int cur_last_h = -1;
      for(int i=0; i<MathMin(rates_total, 500); i++) { if(HighBuffer2[i]>0 && HighBuffer2[i]<EMPTY_VALUE) { cur_last_h=i; break; } }
      if(cur_last_h != -1)
        {
         int cur_prev_h = -1;
         for(int i=cur_last_h+1; i<rates_total; i++) { if(HighBuffer2[i]>0 && HighBuffer2[i]<EMPTY_VALUE) { cur_prev_h=i; break; } }
         if(cur_last_h != last_h_idx || cur_prev_h != prev_h_idx)
           {
            if(last_h_idx != -1 && (HighBuffer2[last_h_idx] == 0 || HighBuffer2[last_h_idx] >= EMPTY_VALUE)) MSHighBuffer[last_h_idx] = EMPTY_VALUE;
            if(prev_h_idx != -1 && (HighBuffer2[prev_h_idx] == 0 || HighBuffer2[prev_h_idx] >= EMPTY_VALUE)) MSHighBuffer[prev_h_idx] = EMPTY_VALUE;
            last_h_idx = cur_last_h;
            prev_h_idx = cur_prev_h;
            MSHighBuffer[last_h_idx] = HighBuffer2[last_h_idx];
            if(prev_h_idx != -1)
              {
               MSHighBuffer[prev_h_idx] = HighBuffer2[prev_h_idx];
               MSHighColorBuffer[last_h_idx] = (HighBuffer2[last_h_idx] > HighBuffer2[prev_h_idx]) ? 0 : 1;
              }
           }
         else if(HighBuffer2[last_h_idx] != MSHighBuffer[last_h_idx])
           {
            MSHighBuffer[last_h_idx] = HighBuffer2[last_h_idx];
            if(prev_h_idx != -1) MSHighColorBuffer[last_h_idx] = (HighBuffer2[last_h_idx] > HighBuffer2[prev_h_idx]) ? 0 : 1;
           }
        }
      
      // Lows
      int cur_last_l = -1;
      for(int i=0; i<MathMin(rates_total, 500); i++) { if(LowBuffer2[i]>0 && LowBuffer2[i]<EMPTY_VALUE) { cur_last_l=i; break; } }
      if(cur_last_l != -1)
        {
         int cur_prev_l = -1;
         for(int i=cur_last_l+1; i<rates_total; i++) { if(LowBuffer2[i]>0 && LowBuffer2[i]<EMPTY_VALUE) { cur_prev_l=i; break; } }
         if(cur_last_l != last_l_idx || cur_prev_l != prev_l_idx)
           {
            if(last_l_idx != -1 && (LowBuffer2[last_l_idx] == 0 || LowBuffer2[last_l_idx] >= EMPTY_VALUE)) MSLowBuffer[last_l_idx] = EMPTY_VALUE;
            if(prev_l_idx != -1 && (LowBuffer2[prev_l_idx] == 0 || LowBuffer2[prev_l_idx] >= EMPTY_VALUE)) MSLowBuffer[prev_l_idx] = EMPTY_VALUE;
            last_l_idx = cur_last_l;
            prev_l_idx = cur_prev_l;
            MSLowBuffer[last_l_idx] = LowBuffer2[last_l_idx];
            if(prev_l_idx != -1)
              {
               MSLowBuffer[prev_l_idx] = LowBuffer2[prev_l_idx];
               MSLowColorBuffer[last_l_idx] = (LowBuffer2[last_l_idx] > LowBuffer2[prev_l_idx]) ? 0 : 1;
              }
           }
         else if(LowBuffer2[last_l_idx] != MSLowBuffer[last_l_idx])
           {
            MSLowBuffer[last_l_idx] = LowBuffer2[last_l_idx];
            if(prev_l_idx != -1) MSLowColorBuffer[last_l_idx] = (LowBuffer2[last_l_idx] > LowBuffer2[prev_l_idx]) ? 0 : 1;
           }
        }
     }

//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
