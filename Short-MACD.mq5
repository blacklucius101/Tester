//+------------------------------------------------------------------+ 
//|                                                   Short-MACD.mq5 | 
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"
//--- indicator version
#property version   "1.00"
//--- indicator description
#property description "MACD Visual Trend"
//--- drawing the indicator in a separate window
#property indicator_separate_window
//--- number of indicator buffers 7 (5 for plots, 2 for calculations)
#property indicator_buffers 7
//--- five plots are used
#property indicator_plots   5

#define RESET  0 // a constant for returning the indicator recalculation command to the terminal
#define   COUNT            (5)

//+----------------------------------------------+
//|  Indicator drawing parameters (arrows)       |
//+----------------------------------------------+

//--- Plot 1: Bullish Increasing (Green)
#property indicator_label1  "Bullish Increasing"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- Plot 2: Bullish Decreasing (Orange)
#property indicator_label2  "Bullish Decreasing"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrOrange
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- Plot 3: Bearish Increasing (Crimson)
#property indicator_label3  "Bearish Increasing"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrCrimson
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

//--- Plot 4: Bearish Decreasing (Lime)
#property indicator_label4  "Bearish Decreasing"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrLime
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1

//--- Plot 5: Flat (Gray)
#property indicator_label5  "Flat"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrGray
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1

//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input uint FastMACD     = 12;
input uint SlowMACD     = 26;
input uint SignalMACD   = 9;
input ENUM_APPLIED_PRICE PriceMACD=PRICE_CLOSE;

//+-----------------------------------+
//--- declaration of integer variables for the start of data calculation
int  min_rates_total;
//--- indicator buffers
double BullishIncrBuffer[];
double BullishDecrBuffer[];
double BearishIncrBuffer[];
double BearishDecrBuffer[];
double FlatBuffer[];
double MacdBuffer[];
double SignalBuffer[];

//--- declaration of integer variables for the indicators handles
int MACD_Handle;
string prefix;
int wnd;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set global variables
   prefix=MQLInfoString(MQL_PROGRAM_NAME)+"_";
   wnd=ChartWindowFind();
//--- initialization of variables of the start of data calculation
   min_rates_total=int(SignalMACD+MathMax(FastMACD,SlowMACD));
   
//--- getting the handle of iMACD
   MACD_Handle=iMACD(NULL,0,FastMACD,SlowMACD,SignalMACD,PriceMACD);
   if(MACD_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of iMACD");
      return(INIT_FAILED);
     }

//--- indicator buffers mapping
   SetIndexBuffer(0,BullishIncrBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,BullishDecrBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,BearishIncrBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,BearishDecrBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,FlatBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,MacdBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,SignalBuffer,INDICATOR_CALCULATIONS);

//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   for(int i=0; i<5; i++)
      PlotIndexSetInteger(i,PLOT_ARROW,167);

//--- setting buffer arrays as timeseries
   ArraySetAsSeries(BullishIncrBuffer,true);
   ArraySetAsSeries(BullishDecrBuffer,true);
   ArraySetAsSeries(BearishIncrBuffer,true);
   ArraySetAsSeries(BearishDecrBuffer,true);
   ArraySetAsSeries(FlatBuffer,true);
   ArraySetAsSeries(MacdBuffer,true);
   ArraySetAsSeries(SignalBuffer,true);

//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);

//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"Short-MACD Visual");
   IndicatorSetInteger(INDICATOR_HEIGHT,60);

//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
   IndicatorSetDouble(INDICATOR_MINIMUM,0);
   IndicatorSetDouble(INDICATOR_MAXIMUM,1);

   Descriptions();
//--- initialization end
   return(INIT_SUCCEEDED);
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
//--- checking if the number of bars is enough for the calculation
   if(BarsCalculated(MACD_Handle)<rates_total || rates_total<min_rates_total)
      return(RESET);

//--- declarations of local variables
   int to_copy,limit;

//--- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)
      limit=rates_total-min_rates_total-1;
   else
      limit=rates_total-prev_calculated;
   to_copy=limit+1;

//--- copy newly appeared data in the arrays
   if(CopyBuffer(MACD_Handle,MAIN_LINE,0,to_copy,MacdBuffer)<=0)
      return(RESET);
   if(CopyBuffer(MACD_Handle,SIGNAL_LINE,0,to_copy,SignalBuffer)<=0)
      return(RESET);

//--- create a temporary buffer to hold the line values
   double LineValueBuffer[];
   ArraySetAsSeries(LineValueBuffer,true);
   ArrayResize(LineValueBuffer,rates_total);

//--- main indicator calculation loop
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      LineValueBuffer[bar] = MacdBuffer[bar] - SignalBuffer[bar];
     }

//--- to avoid out-of-bounds, we can't calculate the last bar in a full recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)
      limit--;

//--- Main loop for setting arrow buffers
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //--- Reset all buffers for the current bar
      BullishIncrBuffer[bar] = EMPTY_VALUE;
      BullishDecrBuffer[bar] = EMPTY_VALUE;
      BearishIncrBuffer[bar] = EMPTY_VALUE;
      BearishDecrBuffer[bar] = EMPTY_VALUE;
      FlatBuffer[bar] = EMPTY_VALUE;

      //--- Default to Flat
      FlatBuffer[bar] = 0.5;

      double line_current = LineValueBuffer[bar];
      double line_previous = LineValueBuffer[bar+1];

      //--- Check for momentum state
      if(line_current > 0) // Bullish
        {
         if(line_current > line_previous)
           {
            BullishIncrBuffer[bar] = 0.5; // Bullish Increasing
            FlatBuffer[bar] = EMPTY_VALUE;
           }
         else if(line_current < line_previous)
           {
            BullishDecrBuffer[bar] = 0.5; // Bullish Decreasing
            FlatBuffer[bar] = EMPTY_VALUE;
           }
        }
      else if(line_current < 0) // Bearish
        {
         if(line_current < line_previous)
           {
            BearishIncrBuffer[bar] = 0.5; // Bearish Increasing
            FlatBuffer[bar] = EMPTY_VALUE;
           }
         else if(line_current > line_previous)
           {
            BearishDecrBuffer[bar] = 0.5; // Bearish Decreasing
            FlatBuffer[bar] = EMPTY_VALUE;
           }
        }
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   if(id==CHARTEVENT_CHART_CHANGE)
     {
      for(int i=0;i<COUNT;i++)
         PlotIndexSetInteger(i,PLOT_LINE_WIDTH,SizeByScale());
      Descriptions();
      ChartRedraw();
     }
  }
//+------------------------------------------------------------------+
//| Returns a size corresponding to the scale                        |
//+------------------------------------------------------------------+
uchar SizeByScale(void)
  {
   uchar scale=(uchar)ChartGetInteger(0,CHART_SCALE);
   uchar size=(scale<3 ? 1 : scale==3 ? 2 : scale==4 ? 5 : 8);
   return size;
  }
//+------------------------------------------------------------------+
//| Description                                                      |
//+------------------------------------------------------------------+
void Descriptions(void)
  {
   int x=4;
   int y=1;
   color arr_colors[COUNT];
   string arr_texts[]={"Bullish Incr","Bullish Decr","Bearish Incr","Bearish Decr","Flat"};
   string arr_names[COUNT];
   for(int i=0; i<COUNT; i++)
     {
      arr_names[i]=prefix+"label"+(string)i;
      arr_colors[i]=(color)PlotIndexGetInteger(i,PLOT_LINE_COLOR);
      x=(i==0 ? 4 : x+90);
      Label(arr_names[i],x,y,CharToString(167),16,arr_colors[i],"Wingdings");
      Label(arr_names[i]+"_txt",x+12,y+5,arr_texts[i],10,clrGray,"Calibri");
     }
  }
//+------------------------------------------------------------------+
//| Displays a text label                                            |
//+------------------------------------------------------------------+
void Label(const string name,const int x,const int y,const string text,const int size,const color clr,const string font)
  {
   if(ObjectFind(0,name)!=wnd)
      ObjectCreate(0,name,OBJ_LABEL,wnd,0,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
//---
   ObjectSetString(0,name,OBJPROP_FONT,font);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"\n");
  }
//+------------------------------------------------------------------+
