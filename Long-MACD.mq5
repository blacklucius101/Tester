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
#property indicator_buffers 11 // 7 for plots + 4 for calculations
#property indicator_plots   7

//--- plot Neutral
#property indicator_label1  "Neutral"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrDarkGray
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- plot Basic Up
#property indicator_label2  "Basic Up"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrDeepSkyBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- plot Basic Down
#property indicator_label3  "Basic Down"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrDarkOrange
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

//--- plot MACD Up > Signal
#property indicator_label4  "MACD Up > Signal"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrGreen
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1

//--- plot MACD Up < Signal
#property indicator_label5  "MACD Up < Signal"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrLime
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1

//--- plot MACD Down > Signal
#property indicator_label6  "MACD Down > Signal"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrOrange
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1

//--- plot MACD Down < Signal
#property indicator_label7  "MACD Down < Signal"
#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrCrimson
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1

//--- defines
#define COUNT 7

//--- input parameters
input int                InpFastEMA=180;               // Fast EMA period
input int                InpSlowEMA=390;               // Slow EMA period
input int                InpSignalSMA=135;              // Signal SMA period
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE; // Applied price

//--- indicator buffers
double         BufferNeutral[];
double         BufferBasicUp[];
double         BufferBasicDown[];
double         BufferMACDUpAbove[];
double         BufferMACDUpBelow[];
double         BufferMACDDnAbove[];
double         BufferMACDDnBelow[];

double         MACDLineBuffer[];
double         ExtSignalBuffer[];
double         ExtFastMaBuffer[];
double         ExtSlowMaBuffer[];

//--- global variables
string         prefix;
int            wnd;
int            ExtFastMaHandle;
int            ExtSlowMaHandle;

//--- indicator initialization function
void OnInit()
  {
//--- set global variables
   prefix=MQLInfoString(MQL_PROGRAM_NAME)+"_";
   wnd=ChartWindowFind();
   SizeByScale();
   Descriptions();

//--- indicator buffers mapping
   SetIndexBuffer(0,BufferNeutral,INDICATOR_DATA);
   SetIndexBuffer(1,BufferBasicUp,INDICATOR_DATA);
   SetIndexBuffer(2,BufferBasicDown,INDICATOR_DATA);
   SetIndexBuffer(3,BufferMACDUpAbove,INDICATOR_DATA);
   SetIndexBuffer(4,BufferMACDUpBelow,INDICATOR_DATA);
   SetIndexBuffer(5,BufferMACDDnAbove,INDICATOR_DATA);
   SetIndexBuffer(6,BufferMACDDnBelow,INDICATOR_DATA);
   
   SetIndexBuffer(7,MACDLineBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,ExtSignalBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,ExtFastMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,ExtSlowMaBuffer,INDICATOR_CALCULATIONS);

//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   for(int i=0; i<COUNT; i++)
      PlotIndexSetInteger(i,PLOT_ARROW,167);

//--- name for indicator subwindow label
   string short_name=StringFormat("MACD_Flat(%d,%d,%d)",InpFastEMA,InpSlowEMA,InpSignalSMA);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
   IndicatorSetInteger(INDICATOR_LEVELS,2);
   IndicatorSetInteger(INDICATOR_HEIGHT,60);
   IndicatorSetDouble(INDICATOR_MINIMUM,0);
   IndicatorSetDouble(INDICATOR_MAXIMUM,1);

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
        }
      else
        {
         ExtSignalBuffer[i] = EMPTY_VALUE;
        }

      //--- Initialize plot buffers
      BufferNeutral[i] = EMPTY_VALUE;
      BufferBasicUp[i] = EMPTY_VALUE;
      BufferBasicDown[i] = EMPTY_VALUE;
      BufferMACDUpAbove[i] = EMPTY_VALUE;
      BufferMACDUpBelow[i] = EMPTY_VALUE;
      BufferMACDDnAbove[i] = EMPTY_VALUE;
      BufferMACDDnBelow[i] = EMPTY_VALUE;
      
      //--- Set plot buffers based on conditions
      if (i < macdDrawBeginIndex) 
        {
         // Points before PLOT_DRAW_BEGIN for MACD line
        }
      else if (i == macdDrawBeginIndex)
        {
         BufferNeutral[i] = 0.5; // Neutral color
        }
      else
        {
         if (i < signalLineStartIndex)
           {
            if (MACDLineBuffer[i] > MACDLineBuffer[i-1])
               BufferBasicUp[i] = 0.5; // Basic Up
            else if (MACDLineBuffer[i] < MACDLineBuffer[i-1])
               BufferBasicDown[i] = 0.5; // Basic Down
            else
            {
                // Find the last active buffer and carry it forward
                if(BufferNeutral[i-1] != EMPTY_VALUE) BufferNeutral[i] = 0.5;
                if(BufferBasicUp[i-1] != EMPTY_VALUE) BufferBasicUp[i] = 0.5;
                if(BufferBasicDown[i-1] != EMPTY_VALUE) BufferBasicDown[i] = 0.5;
            }
           }
         else
           {
            if (MACDLineBuffer[i] > MACDLineBuffer[i-1])
              {
               if (MACDLineBuffer[i] > ExtSignalBuffer[i])
                  BufferMACDUpAbove[i] = 0.5; // MACD Up & Above Signal
               else
                  BufferMACDUpBelow[i] = 0.5; // MACD Up & Below Signal
              }
            else if (MACDLineBuffer[i] < MACDLineBuffer[i-1])
              {
               if (MACDLineBuffer[i] > ExtSignalBuffer[i])
                  BufferMACDDnAbove[i] = 0.5; // MACD Down & Above Signal
               else
                  BufferMACDDnBelow[i] = 0.5; // MACD Down & Below Signal
              }
            else
              {
                // Find the last active buffer and carry it forward
                if(BufferMACDUpAbove[i-1] != EMPTY_VALUE) BufferMACDUpAbove[i] = 0.5;
                else if(BufferMACDUpBelow[i-1] != EMPTY_VALUE) BufferMACDUpBelow[i] = 0.5;
                else if(BufferMACDDnAbove[i-1] != EMPTY_VALUE) BufferMACDDnAbove[i] = 0.5;
                else if(BufferMACDDnBelow[i-1] != EMPTY_VALUE) BufferMACDDnBelow[i] = 0.5;
                else // If none of the signal-related states were active, check the basic states
                {
                    if(BufferNeutral[i-1] != EMPTY_VALUE) BufferNeutral[i] = 0.5;
                    if(BufferBasicUp[i-1] != EMPTY_VALUE) BufferBasicUp[i] = 0.5;
                    if(BufferBasicDown[i-1] != EMPTY_VALUE) BufferBasicDown[i] = 0.5;
                }
              }
           }
        } 
     }

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
//| Returns size corresponding to the scale                          |
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
   string arr_texts[]={"Neutral","Basic Up","Basic Down","MACD Up > Sig","MACD Up < Sig","MACD Dn > Sig","MACD Dn < Sig"};
   string arr_names[COUNT];
   for(int i=0; i<COUNT; i++)
     {
      arr_names[i]=prefix+"label"+(string)i;
      arr_colors[i]=(color)PlotIndexGetInteger(i,PLOT_LINE_COLOR);
      if(i==0) x=4;
      else if(i==1) x=70;
      else if(i==2) x=145;
      else if(i==3) x=230;
      else if(i==4) x=330;
      else if(i==5) x=430;
      else if(i==6) x=530;
      
      Label(arr_names[i],x,y,CharToString(167),16,arr_colors[i],"Wingdings");
      Label(arr_names[i]+"_txt",x+12,y+5,arr_texts[i],10,clrGray,"Calibri");
     }
  }
//+------------------------------------------------------------------+
//| Draws a text label                                               |
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
