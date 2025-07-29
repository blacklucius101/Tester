//+------------------------------------------------------------------+
//|                                                 Super Arrows.mq5 |
//|                   Copyright 2023, Your Name (or company name)    |
//|                                      http://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright  ©  2013,  Lucifer   ©  Tankk,  16 October 2021,  https://www.forexfactory.com/"
#property link      "https://www.forexfactory.com/thread/1109767-indicators-collection-of-tankk"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

//--- plot Buy
#property indicator_label1  "Buy"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLime
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Sell
#property indicator_label2  "Sell"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- indicator buffers
double         BuyBuffer[];
double         SellBuffer[];

//--- input parameters
input ENUM_TIMEFRAMES TimeFrame  =  PERIOD_CURRENT;
input int FasterMovingAverage = 5;
input int SlowerMovingAverage = 12;
input int RSIPeriod = 12;
input int MagicFilterPeriod = 1;
input int BollingerbandsPeriod = 10;
input int BollingerbandsShift = 0;
input double BollingerbandsDeviation = 0.5;
input int BullsPowerPeriod = 50;
input int BearsPowerPeriod = 50;
input bool Alerts = true;
input int Utstup = 10;

//--- global variables
bool Gi_132 = false;
bool Gi_136 = false;
bool Gi_140 = false;
bool Gi_144 = false;
bool Gi_148 = false;
bool Gi_152 = false;
bool Gi_156 = false;
bool Gi_160 = false;
bool Gi_164 = false;
bool Gi_168 = false;
int Gi_172 = 0;
bool Gi_176 = false;
bool Gi_180 = false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,BuyBuffer,INDICATOR_DATA);
   PlotIndexSetString(0,PLOT_LABEL,"Buy");
   PlotIndexSetInteger(0,PLOT_ARROW,233);
   SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);
   PlotIndexSetString(1,PLOT_LABEL,"Sell");
   PlotIndexSetInteger(1,PLOT_ARROW,234);

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
//---
   int i,limit;
   if(rates_total<prev_calculated) limit=0;
   else limit=prev_calculated-1;
   if(limit<0) limit=0;

   for(i=limit; i<rates_total && !IsStopped(); i++)
     {
      int y = iBarShift(NULL,TimeFrame,time[i],false);

      double ima_12_buffer[], ima_20_buffer[], ima_28_buffer[], ima_36_buffer[];
      double irsi_44_buffer[], irsi_52_buffer[];
      double ibullspower_60_buffer[], ibullspower_68_buffer[];
      double ibearspower_76_buffer[], ibearspower_84_buffer[];
      double ibands_152_buffer[], ibands_160_buffer[], ibands_168_buffer[], ibands_176_buffer[];
      double Ld_92_buffer[], Ld_100_buffer[];

      int ima_12_handle = iMA(_Symbol, TimeFrame, FasterMovingAverage, 0, MODE_EMA, PRICE_CLOSE);
      CopyBuffer(ima_12_handle, 0, y, 1, ima_12_buffer);
      double ima_12 = ima_12_buffer[0];

      int ima_28_handle = iMA(_Symbol, TimeFrame, FasterMovingAverage, 0, MODE_EMA, PRICE_CLOSE);
      CopyBuffer(ima_28_handle, 0, y + 1, 1, ima_28_buffer);
      double ima_28 = ima_28_buffer[0];

      int ima_20_handle = iMA(_Symbol, TimeFrame, SlowerMovingAverage, 0, MODE_EMA, PRICE_CLOSE);
      CopyBuffer(ima_20_handle, 0, y, 1, ima_20_buffer);
      double ima_20 = ima_20_buffer[0];

      int ima_36_handle = iMA(_Symbol, TimeFrame, SlowerMovingAverage, 0, MODE_EMA, PRICE_CLOSE);
      CopyBuffer(ima_36_handle, 0, y + 1, 1, ima_36_buffer);
      double ima_36 = ima_36_buffer[0];

      int irsi_44_handle = iRSI(_Symbol, TimeFrame, RSIPeriod, PRICE_CLOSE);
      CopyBuffer(irsi_44_handle, 0, y, 1, irsi_44_buffer);
      double irsi_44 = irsi_44_buffer[0];

      int irsi_52_handle = iRSI(_Symbol, TimeFrame, RSIPeriod, PRICE_CLOSE);
      CopyBuffer(irsi_52_handle, 0, y + 1, 1, irsi_52_buffer);
      double irsi_52 = irsi_52_buffer[0];

      int ibullspower_60_handle = iBullsPower(_Symbol, TimeFrame, BullsPowerPeriod);
      CopyBuffer(ibullspower_60_handle, 0, y, 1, ibullspower_60_buffer);
      double ibullspower_60 = ibullspower_60_buffer[0];

      int ibullspower_68_handle = iBullsPower(_Symbol, TimeFrame, BullsPowerPeriod);
      CopyBuffer(ibullspower_68_handle, 0, y + 1, 1, ibullspower_68_buffer);
      double ibullspower_68 = ibullspower_68_buffer[0];

      int ibearspower_76_handle = iBearsPower(_Symbol, TimeFrame, BearsPowerPeriod);
      CopyBuffer(ibearspower_76_handle, 0, y, 1, ibearspower_76_buffer);
      double ibearspower_76 = ibearspower_76_buffer[0];

      int ibearspower_84_handle = iBearsPower(_Symbol, TimeFrame, BearsPowerPeriod);
      CopyBuffer(ibearspower_84_handle, 0, y + 1, 1, ibearspower_84_buffer);
      double ibearspower_84 = ibearspower_84_buffer[0];

      int ibands_152_handle = iBands(_Symbol, TimeFrame, BollingerbandsPeriod, BollingerbandsShift, BollingerbandsDeviation, PRICE_CLOSE);
      CopyBuffer(ibands_152_handle, 1, y, 1, ibands_152_buffer);
      double ibands_152 = ibands_152_buffer[0];

      int ibands_160_handle = iBands(_Symbol, TimeFrame, BollingerbandsPeriod, BollingerbandsShift, BollingerbandsDeviation, PRICE_CLOSE);
      CopyBuffer(ibands_160_handle, 2, y, 1, ibands_160_buffer);
      double ibands_160 = ibands_160_buffer[0];

      int ibands_168_handle = iBands(_Symbol, TimeFrame, BollingerbandsPeriod, BollingerbandsShift, BollingerbandsDeviation, PRICE_CLOSE);
      CopyBuffer(ibands_168_handle, 1, y + 1, 1, ibands_168_buffer);
      double ibands_168 = ibands_168_buffer[0];

      int ibands_176_handle = iBands(_Symbol, TimeFrame, BollingerbandsPeriod, BollingerbandsShift, BollingerbandsDeviation, PRICE_CLOSE);
      CopyBuffer(ibands_176_handle, 2, y + 1, 1, ibands_176_buffer);
      double ibands_176 = ibands_176_buffer[0];

      double Ld_92 = iHighest(_Symbol,TimeFrame, MODE_HIGH, MagicFilterPeriod, y);
      double Ld_100 = iLowest(_Symbol,TimeFrame, MODE_LOW, MagicFilterPeriod, y);
      double Ld_108 = 100 - 100.0 * ((Ld_92 - 0.0) / 10.0);
      double Ld_116 = 100 - 100.0 * ((Ld_100 - 0.0) / 10.0);
      if (Ld_108 == 0.0) Ld_108 = 0.0000001;
      if (Ld_116 == 0.0) Ld_116 = 0.0000001;
      double Ld_124 = Ld_108 - Ld_116;

      if (Ld_124 >= 0.0) {
         Gi_148 = true;
         Gi_168 = false;
      } else {
         if (Ld_124 < 0.0) {
            Gi_148 = false;
            Gi_168 = true;
         }
      }
      if (iClose(NULL,TimeFrame,y) > ibands_152 && iClose(NULL,TimeFrame,y+1) >= ibands_168) {
         Gi_144 = false;
         Gi_164 = true;
      }
      if (iClose(NULL,TimeFrame,y) < ibands_160 && iClose(NULL,TimeFrame,y+1) <= ibands_176) {
         Gi_144 = true;
         Gi_164 = false;
      }
      if (ibullspower_60 > 0.0 && ibullspower_68 > ibullspower_60) {
         Gi_140 = false;
         Gi_160 = true;
      }
      if (ibearspower_76 < 0.0 && ibearspower_84 < ibearspower_76) {
         Gi_140 = true;
         Gi_160 = false;
      }
      if (irsi_44 > 50.0 && irsi_52 < 50.0) {
         Gi_136 = true;
         Gi_156 = false;
      }
      if (irsi_44 < 50.0 && irsi_52 > 50.0) {
         Gi_136 = false;
         Gi_156 = true;
      }
      if (ima_12 > ima_20 && ima_28 < ima_36) {
         Gi_132 = true;
         Gi_152 = false;
      }
      if (ima_12 < ima_20 && ima_28 > ima_36) {
         Gi_132 = false;
         Gi_152 = true;
      }

      BuyBuffer[i] = EMPTY_VALUE;
      SellBuffer[i] = EMPTY_VALUE;

      if (Gi_132 == true && Gi_136 == true && Gi_144 == true && Gi_140 == true && Gi_148 == true && Gi_172 != 1) {
         BuyBuffer[i] = low[y] - (SymbolInfoDouble(_Symbol,SYMBOL_POINT) * Utstup);
         if (i == rates_total-1 && Alerts && (!Gi_176)) {
            Alert(Symbol(), " ", EnumToString(Period()), "   BUY");
            Gi_176 = true;
            Gi_180 = false;
         }
         Gi_172 = 1;
      } else {
         if (Gi_152 == true && Gi_156 == true && Gi_164 == true && Gi_160 == true && Gi_168 == false && Gi_172 != 2) {
            SellBuffer[i] = high[y] + (SymbolInfoDouble(_Symbol,SYMBOL_POINT) * Utstup);
            if (i == rates_total-1 && Alerts && (!Gi_180)) {
               Alert(Symbol(), " ", EnumToString(Period()), "   SELL");
               Gi_180 = true;
               Gi_176 = false;
            }
            Gi_172 = 2;
         }
      }
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Comment("");
   ObjectsDeleteAll(0, -1, OBJ_ARROW);
  }
//+------------------------------------------------------------------+
