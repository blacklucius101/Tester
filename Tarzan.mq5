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
#property indicator_buffers 7
#property indicator_plots   6
//--- plot RSI
#property indicator_label1  "RSI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrCadetBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
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
   SetIndexBuffer(1,BufferCentral,INDICATOR_DATA);
   SetIndexBuffer(2,BufferColors,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(3,BufferTop,INDICATOR_DATA);
   SetIndexBuffer(4,BufferBottom,INDICATOR_DATA);
   SetIndexBuffer(5,BufferArrowUP,INDICATOR_DATA);
   SetIndexBuffer(6,BufferArrowDN,INDICATOR_DATA);
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
