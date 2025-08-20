//+------------------------------------------------------------------+
//|                                                 labelled-RSI.mq5 |
//|                             Copyright 2000-2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2000-2025, MetaQuotes Ltd."
#property link        "https://www.mql5.com"
#property description "Relative Strength Index with Buy/Sell Signal"
//--- indicator settings
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 30
#property indicator_level2 70
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue

//--- input parameters
input int InpPeriodRSI=75; // Period
//--- label parameters
input int       LabelShiftX=200;       // Label horizontal shift
input int       LabelShiftY=15;       // Label vertical shift
input color     LabelColor=clrWhite;  // Label text color
input string    LabelFont="Arial";    // Label font
input int       LabelFontSize=10;     // Label font size
input bool      LabelBackground=true; // Show label background
input color     LabelBgColor=clrGray; // Label background color

//--- indicator buffers
double    ExtRSIBuffer[];
double    ExtPosBuffer[];
double    ExtNegBuffer[];

int       ExtPeriodRSI;
int       indicatorWindow=-1; // Will store our subwindow index
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input
   if(InpPeriodRSI<1)
     {
      ExtPeriodRSI=14;
      PrintFormat("Incorrect value for input variable InpPeriodRSI = %d. Indicator will use value %d for calculations.",
                  InpPeriodRSI,ExtPeriodRSI);
     }
   else
      ExtPeriodRSI=InpPeriodRSI;
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtRSIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtPosBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,ExtNegBuffer,INDICATOR_CALCULATIONS);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPeriodRSI);
//--- name for DataWindow and indicator subwindow label
   string short_name="RSI("+string(ExtPeriodRSI)+")";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   
   //--- get our indicator subwindow index
   indicatorWindow=ChartWindowFind(0,short_name);
   if(indicatorWindow<0)
     {
      Print("Failed to find indicator subwindow!");
      return;
     }

   //--- create label for RSI signal text
   CreateOrUpdateLabel("Calculating...",LabelColor);
  }
//+------------------------------------------------------------------+
//| Creates or updates the signal label                              |
//+------------------------------------------------------------------+
void CreateOrUpdateLabel(string text,color textColor)
  {
//--- delete the label if it already exists
   if(ObjectFind(0,"RSI_Signal")>=0)
      ObjectDelete(0,"RSI_Signal");

//--- create the label in our indicator subwindow
   if(!ObjectCreate(0,"RSI_Signal",OBJ_LABEL,indicatorWindow,0,0))
     {
      Print("Failed to create RSI label! Error code: ",GetLastError());
      return;
     }

//--- set label properties
   ObjectSetInteger(0,"RSI_Signal",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,"RSI_Signal",OBJPROP_XDISTANCE,LabelShiftX);
   ObjectSetInteger(0,"RSI_Signal",OBJPROP_YDISTANCE,LabelShiftY);
   ObjectSetInteger(0,"RSI_Signal",OBJPROP_FONTSIZE,LabelFontSize);
   ObjectSetString(0,"RSI_Signal",OBJPROP_FONT,LabelFont);
   ObjectSetString(0,"RSI_Signal",OBJPROP_TEXT,text);
   ObjectSetInteger(0,"RSI_Signal",OBJPROP_COLOR,textColor);
   ObjectSetInteger(0,"RSI_Signal",OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,"RSI_Signal",OBJPROP_HIDDEN,true);

//--- set background properties if enabled
   if(LabelBackground)
     {
      ObjectSetInteger(0,"RSI_Signal",OBJPROP_BACK,true);
      ObjectSetInteger(0,"RSI_Signal",OBJPROP_BGCOLOR,LabelBgColor);
      ObjectSetInteger(0,"RSI_Signal",OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,"RSI_Signal",OBJPROP_WIDTH,1);
     }
  }
//+------------------------------------------------------------------+
//| Relative Strength Index                                          |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   if(rates_total<=ExtPeriodRSI)
      return(0);
//--- preliminary calculations
   int pos=prev_calculated-1;
   if(pos<=ExtPeriodRSI)
     {
      double sum_pos=0.0;
      double sum_neg=0.0;
      //--- first RSIPeriod values of the indicator are not calculated
      ExtRSIBuffer[0]=0.0;
      ExtPosBuffer[0]=0.0;
      ExtNegBuffer[0]=0.0;
      for(int i=1; i<=ExtPeriodRSI; i++)
        {
         ExtRSIBuffer[i]=0.0;
         ExtPosBuffer[i]=0.0;
         ExtNegBuffer[i]=0.0;
         double diff=price[i]-price[i-1];
         sum_pos+=(diff>0?diff:0);
         sum_neg+=(diff<0?-diff:0);
        }
      //--- calculate first visible value
      ExtPosBuffer[ExtPeriodRSI]=sum_pos/ExtPeriodRSI;
      ExtNegBuffer[ExtPeriodRSI]=sum_neg/ExtPeriodRSI;
      if(ExtNegBuffer[ExtPeriodRSI]!=0.0)
         ExtRSIBuffer[ExtPeriodRSI]=100.0-(100.0/(1.0+ExtPosBuffer[ExtPeriodRSI]/ExtNegBuffer[ExtPeriodRSI]));
      else
        {
         if(ExtPosBuffer[ExtPeriodRSI]!=0.0)
            ExtRSIBuffer[ExtPeriodRSI]=100.0;
         else
            ExtRSIBuffer[ExtPeriodRSI]=50.0;
        }
      //--- prepare the position value for main calculation
      pos=ExtPeriodRSI+1;
     }
//--- the main loop of calculations
   for(int i=pos; i<rates_total && !IsStopped(); i++)
     {
      double diff=price[i]-price[i-1];
      ExtPosBuffer[i]=(ExtPosBuffer[i-1]*(ExtPeriodRSI-1)+(diff>0.0?diff:0.0))/ExtPeriodRSI;
      ExtNegBuffer[i]=(ExtNegBuffer[i-1]*(ExtPeriodRSI-1)+(diff<0.0?-diff:0.0))/ExtPeriodRSI;
      if(ExtNegBuffer[i]!=0.0)
         ExtRSIBuffer[i]=100.0-100.0/(1+ExtPosBuffer[i]/ExtNegBuffer[i]);
      else
        {
         if(ExtPosBuffer[i]!=0.0)
            ExtRSIBuffer[i]=100.0;
         else
            ExtRSIBuffer[i]=50.0;
        }
     }
     
   //--- Update RSI signal text based on current RSI value
   if(rates_total>0 && indicatorWindow>=0)
     {
      string signalText;
      color textColor;
      double currentRSI=ExtRSIBuffer[rates_total-1];
      
      if(currentRSI > 70)
        {
         signalText="RSI: "+DoubleToString(currentRSI,2)+" (Overbought - Sell)";
         textColor=clrRed;
        }
      else if(currentRSI > 50)
        {
         signalText="RSI: "+DoubleToString(currentRSI,2)+" (Bullish - Buy)";
         textColor=clrLime;
        }
      else if(currentRSI < 30)
        {
         signalText="RSI: "+DoubleToString(currentRSI,2)+" (Oversold - Buy)";
         textColor=clrLime;
        }
      else
        {
         signalText="RSI: "+DoubleToString(currentRSI,2)+" (Bearish - Sell)";
         textColor=clrRed;
        }
      
      // Only update if something changed
      if(ObjectGetString(0,"RSI_Signal",OBJPROP_TEXT)!=signalText)
        {
         CreateOrUpdateLabel(signalText,textColor);
         ChartRedraw();
        }
     }
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Deinitialization function                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- delete our graphical objects
   ObjectDelete(0,"RSI_Signal");
  }
//+------------------------------------------------------------------+
