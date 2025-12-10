//+------------------------------------------------------------------+
//|                                                       Tarzan.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://mql5.com"
#property version   "1.00"
#property description "\"Tarzan\" Indicator"
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   6
//--- plot RSI
#property indicator_label1  "RSI"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDodgerBlue,clrBrown
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Central
#property indicator_label2  "Central"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrDodgerBlue,clrGreen,clrOrange,clrRed,clrLightGray
#property indicator_style2  STYLE_SOLID
#property indicator_width2  3
//--- plot Top
#property indicator_label3  "Top"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrMediumTurquoise
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot Bottom
#property indicator_label4  "Bottom"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrMediumTurquoise
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//--- plot Arrow Up
#property indicator_label5  "Sell"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrRed
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
//--- plot Arrow Down
#property indicator_label6  "Buy"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrBlue
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1
//--- input parameters
input uint                 InpPeriodRSI      =  5;             // RSI period
input ENUM_APPLIED_PRICE   InpAppliedPrice   =  PRICE_CLOSE;   // RSI Applied price
input uint                 InpPeriodMA       =  50;            // MA period
input ENUM_MA_METHOD       InpMethod         =  MODE_SMA;      // MA Method
input uint                 InpChannelTop     =  20;            // Channel top size
input uint                 InpChannelBottom  =  20;            // Channel bottom size
//--- indicator buffers
double         BufferRSI[];
double         BufferRSIColors[];
double         BufferCentral[];
double         BufferColors[];
double         BufferTop[];
double         BufferBottom[];
double         BufferArrowUP[];
double         BufferArrowDN[];
//--- global variables
int            period_rsi;
int            period_ma;
int            handle_rsi;
int            weight_sum;
int            subwindow_handle;

//--- Global variables for pivot and breakout logic
double lastPivotHighPrice = 0;
datetime lastPivotHighTime = 0;
bool pivotHighUsed = false;

double lastPivotLowPrice = 0;
datetime lastPivotLowTime = 0;
bool pivotLowUsed = false;

//--- includes
#include <MovingAverages.mqh>
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set global variables
   period_rsi=int(InpPeriodRSI<1 ? 1 : InpPeriodRSI);
   period_ma=int(InpPeriodMA<2 ? 2 : InpPeriodMA);
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferRSI,INDICATOR_DATA);
   SetIndexBuffer(1,BufferRSIColors,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,BufferCentral,INDICATOR_DATA);
   SetIndexBuffer(3,BufferColors,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4,BufferTop,INDICATOR_DATA);
   SetIndexBuffer(5,BufferBottom,INDICATOR_DATA);
   SetIndexBuffer(6,BufferArrowUP,INDICATOR_DATA);
   SetIndexBuffer(7,BufferArrowDN,INDICATOR_DATA);

   subwindow_handle = ChartWindowFind();

   //--- Initialize global variables
   lastPivotHighPrice = 0;
   lastPivotHighTime = 0;
   pivotHighUsed = false;

   lastPivotLowPrice = 0;
   lastPivotLowTime = 0;
   pivotLowUsed = false;
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(4,PLOT_ARROW,242);
   PlotIndexSetInteger(5,PLOT_ARROW,241);
//--- setting indicator parameters
   IndicatorSetString(INDICATOR_SHORTNAME,"Tarzan ("+(string)period_rsi+","+(string)period_ma+")");
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
   IndicatorSetDouble(INDICATOR_MINIMUM,0);
   IndicatorSetDouble(INDICATOR_MAXIMUM,100);
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(BufferRSI,true);
   ArraySetAsSeries(BufferRSIColors,true);
   ArraySetAsSeries(BufferCentral,true);
   ArraySetAsSeries(BufferColors,true);
   ArraySetAsSeries(BufferTop,true);
   ArraySetAsSeries(BufferBottom,true);
   ArraySetAsSeries(BufferArrowUP,true);
   ArraySetAsSeries(BufferArrowDN,true);
//--- create MA's handles
   ResetLastError();
   handle_rsi=iRSI(NULL,PERIOD_CURRENT,period_rsi,InpAppliedPrice);
   if(handle_rsi==INVALID_HANDLE)
     {
      Print("The iRSI(",(string)period_rsi,")object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Loop through all objects on the chart
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);

      // Remove only the objects created by this indicator
      if(StringFind(name, "TarzanBreakout_") == 0)
      {
         ObjectDelete(0, name);
      }
   }
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
//--- Проверка и расчёт количества просчитываемых баров
   if(rates_total<4) return 0;
//--- Проверка и расчёт количества просчитываемых баров
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-2;
      ArrayInitialize(BufferRSI,EMPTY_VALUE);
      ArrayInitialize(BufferCentral,EMPTY_VALUE);
      ArrayInitialize(BufferTop,EMPTY_VALUE);
      ArrayInitialize(BufferBottom,EMPTY_VALUE);
      ArrayInitialize(BufferArrowUP,EMPTY_VALUE);
      ArrayInitialize(BufferArrowDN,EMPTY_VALUE);
     }
//--- Подготовка данных
   int count=(limit>1 ? rates_total : 1),copied=0;
   copied=CopyBuffer(handle_rsi,0,0,count,BufferRSI);
   if(copied!=count) return 0;
   switch(InpMethod)
     {
      case MODE_EMA  :  ExponentialMAOnBuffer(rates_total,prev_calculated,period_rsi,period_ma,BufferRSI,BufferCentral);               break;
      case MODE_SMMA :  SmoothedMAOnBuffer(rates_total,prev_calculated,period_rsi,period_ma,BufferRSI,BufferCentral);                  break;
      case MODE_LWMA :  LinearWeightedMAOnBuffer(rates_total,prev_calculated,period_rsi,period_ma,BufferRSI,BufferCentral,weight_sum); break;
      //---MODE_SMA
      default        :  SimpleMAOnBuffer(rates_total,prev_calculated,period_rsi,period_ma,BufferRSI,BufferCentral);                    break;
     }
//--- Расчёт индикатора
   for(int i=limit; i>=0 && !IsStopped(); i--)
     {
      // --- Draw the colored rsi line ---
      if(i < rates_total-1)
      {
         if(BufferRSI[i] > BufferRSI[i+1])
            BufferRSIColors[i] = 0; // Blue for up
         else if(BufferRSI[i] < BufferRSI[i+1])
            BufferRSIColors[i] = 1; // Brown for down
         else
            BufferRSIColors[i] = BufferRSIColors[i+1]; // Same color for flat
      }
      else
      {
         BufferRSIColors[i] = 0; // Default color
      }
      
      // --- New breakout logic ---
      if(i < rates_total-2)
      {
         bool isPivotHigh = BufferRSI[i] < BufferRSI[i+1] && BufferRSI[i+1] > BufferRSI[i+2];
         bool isPivotLow = BufferRSI[i] > BufferRSI[i+1] && BufferRSI[i+1] < BufferRSI[i+2];

         if (isPivotHigh)
         {
            lastPivotHighPrice = BufferRSI[i+1];
            lastPivotHighTime = time[i+1];
            pivotHighUsed = false;
         }

         if (isPivotLow)
         {
            lastPivotLowPrice = BufferRSI[i+1];
            lastPivotLowTime = time[i+1];
            pivotLowUsed = false;
         }
      }

      // Breakout above pivot high
      if(lastPivotHighPrice > 0 && !pivotHighUsed && BufferRSI[i] > lastPivotHighPrice)
      {
         string objName = "TarzanBreakout_" + (string)lastPivotHighTime + "_" + (string)time[i];
         if(ObjectFind(0, objName) < 0)
         {
            ObjectCreate(0, objName, OBJ_TREND, subwindow_handle, lastPivotHighTime, lastPivotHighPrice, time[i], BufferRSI[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrAqua);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, false);
         }
         pivotHighUsed = true; // Mark this pivot as used
      }

      // Breakout below pivot low
      if(lastPivotLowPrice > 0 && !pivotLowUsed && BufferRSI[i] < lastPivotLowPrice)
      {
         string objName = "TarzanBreakout_" + (string)lastPivotLowTime + "_" + (string)time[i];
         if(ObjectFind(0, objName) < 0)
         {
            ObjectCreate(0, objName, OBJ_TREND, subwindow_handle, lastPivotLowTime, lastPivotLowPrice, time[i], BufferRSI[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrMagenta);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, false);
         }
         pivotLowUsed = true; // Mark this pivot as used
      }
      
      double MA=BufferCentral[i];
      double UP=(MA+InpChannelTop > 100 ? 100 : MA+InpChannelTop);
      double DN=(MA-InpChannelBottom < 0 ? 0 : MA-InpChannelBottom);
      BufferTop[i]=UP;
      BufferBottom[i]=DN;
      double RSI_0=BufferRSI[i];
      double RSI_1=BufferRSI[i+1];
      bool cross_to_up=false;
      bool cross_to_dn=false;
      if(RSI_0>DN && RSI_1<=DN)
        {
         cross_to_up=true;
         BufferArrowDN[i]=DN;
        }
      else
         BufferArrowDN[i]=EMPTY_VALUE;
      if(RSI_0<UP && RSI_1>=UP)
        {
         cross_to_dn=true;
         BufferArrowUP[i]=UP;
        }
      else
         BufferArrowUP[i]=EMPTY_VALUE;
      //--- clrDodgerBlue,clrGreen,clrOrange,clrRed,clrLightGray
      BufferColors[i]=
        (
         //--- Пересечение снизу-вверх
         cross_to_up ? 1 :
         //--- Пересечение сверху-вниз
         cross_to_dn ? 3 :
         //--- Внутри выше МА
         RSI_0>MA && RSI_0<=UP ? 0 : 
         //--- Внутри ниже МА
         RSI_0<MA && RSI_0>=DN ? 2 : 
         //--- Остальное
         4
        );

     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
