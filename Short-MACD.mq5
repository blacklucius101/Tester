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
#property description "OsMA Colored Line"
//--- drawing the indicator in a separate window
#property indicator_separate_window
//--- number of indicator buffers 2 (now only need 2)
#property indicator_buffers 2 
//--- one plot is used (just the line now)
#property indicator_plots   1

#define RESET  0 // a constant for returning the indicator recalculation command to the terminal

//+----------------------------------------------+
//|  Indicator drawing parameters (line only)    |
//+----------------------------------------------+
//--- drawing indicator as a colored line
#property indicator_type1 DRAW_COLOR_LINE
//--- colors of the line are as follows
#property indicator_color1 clrCrimson,clrLime,clrGray,clrOrange,clrGreen
//--- indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//--- indicator line width is 2 (can be increased for better visibility)
#property indicator_width1 2
//--- displaying the indicator label
#property indicator_label1 "MACD Line"

//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input uint FastMACD     = 12;
input uint SlowMACD     = 26;
input uint SignalMACD   = 9;
input ENUM_APPLIED_PRICE PriceMACD=PRICE_CLOSE;
input double LineMultiplier = 3.0; // New input for line scaling

//+-----------------------------------+
//--- declaration of integer variables for the start of data calculation
int  min_rates_total;
//--- declaration of dynamic arrays that will be used as indicator buffers
double LineBuffer[],ColorBuffer[];

//--- declaration of integer variables for the indicators handles
int MACD_Handle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- initialization of variables of the start of data calculation
   min_rates_total=int(SignalMACD+MathMax(FastMACD,SlowMACD));
   
//--- getting the handle of iMACD
   MACD_Handle=iMACD(NULL,0,FastMACD,SlowMACD,SignalMACD,PriceMACD);
   if(MACD_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of iMACD");
      return(INIT_FAILED);
     }

//--- set buffers for line
   SetIndexBuffer(0,LineBuffer,INDICATOR_DATA);
   ArraySetAsSeries(LineBuffer,true);
   
//--- setting a dynamic array as a color index buffer   
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   ArraySetAsSeries(ColorBuffer,true);

//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);

//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"MACD Colored Line");

//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);

//--- initialization end
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+  
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &Tick_Volume[],
                const long &Volume[],
                const int &Spread[])
  {
//--- checking if the number of bars is enough for the calculation
   if(BarsCalculated(MACD_Handle)<rates_total || rates_total<min_rates_total) return(RESET);

//--- declarations of local variables 
   int to_copy,limit;

//--- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)
      limit=rates_total-min_rates_total-1;
   else limit=rates_total-prev_calculated;
   
   to_copy=limit+1;

//--- temporary buffers for MACD components
   double tmpMACD[], tmpSignal[];
   ArraySetAsSeries(tmpMACD, true);
   ArraySetAsSeries(tmpSignal, true);

//--- copy newly appeared data in the arrays
   if(CopyBuffer(MACD_Handle,MAIN_LINE,0,to_copy,tmpMACD)<=0) return(RESET);
   if(CopyBuffer(MACD_Handle,SIGNAL_LINE,0,to_copy,tmpSignal)<=0) return(RESET);

//--- main indicator calculation loop
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      // Calculate the line value (difference between MACD and Signal line)
      LineBuffer[bar] = LineMultiplier*(tmpMACD[bar] - tmpSignal[bar])/_Point;
     }

   if(prev_calculated>rates_total || prev_calculated<=0) limit--;

//--- Main loop of the line coloring
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      int clr=2; // default gray color
      if(LineBuffer[bar]>0)
        {
         if(LineBuffer[bar]>LineBuffer[bar+1]) clr=4; // blue - bullish momentum increasing
         if(LineBuffer[bar]<LineBuffer[bar+1]) clr=3; // deepskyblue - bullish momentum decreasing
        }
      if(LineBuffer[bar]<0)
        {
         if(LineBuffer[bar]<LineBuffer[bar+1]) clr=0; // brown - bearish momentum increasing
         if(LineBuffer[bar]>LineBuffer[bar+1]) clr=1; // violet - bearish momentum decreasing
        }
      ColorBuffer[bar]=clr;
     }
     
   return(rates_total);
  }
//+------------------------------------------------------------------+
