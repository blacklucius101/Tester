//+------------------------------------------------------------------+
//|                                              MACD_Flat_Trend.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://mql5.com"
#property version   "1.00"
#property description "MACD Flat Trend indicator"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   3
//--- plot UP
#property indicator_label1  "Up trend"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot DN
#property indicator_label2  "Down trend"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot NL
#property indicator_label3  "Flat"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrLightSteelBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- defines
#define   COUNT            (3)
//--- input parameters
input uint                 InpPeriodFast     =  12;            // MACD fast EMA period
input uint                 InpPeriodSlow     =  26;            // MACD slow EMA period
input uint                 InpPeriodSig      =  9;             // MACD signal period
input ENUM_APPLIED_PRICE   InpAppliedPrice   =  PRICE_CLOSE;   // Applied price
//--- indicator buffers
double         BufferUP[];
double         BufferDN[];
double         BufferNL[];
double         BufferMACD[];
double         BufferSignal[];
//--- global variables
string         prefix;
int            wnd;
int            period_fast;
int            period_slow;
int            period_sig;
int            period_max;
int            handle_macd;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set global variables
   prefix=MQLInfoString(MQL_PROGRAM_NAME)+"_";
   wnd=ChartWindowFind();
   SizeByScale();
   Descriptions();
   period_fast=int(InpPeriodFast<1 ? 1 : InpPeriodFast);
   period_slow=int(InpPeriodSlow==period_fast ? period_fast+1 : InpPeriodSlow<1 ? 1 : InpPeriodSlow);
   period_sig=int(InpPeriodSig<1 ? 1 : InpPeriodSig);
   period_max=fmax(period_fast,fmax(period_slow,period_sig));
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferUP,INDICATOR_DATA);
   SetIndexBuffer(1,BufferDN,INDICATOR_DATA);
   SetIndexBuffer(2,BufferNL,INDICATOR_DATA);
   SetIndexBuffer(3,BufferMACD,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,BufferSignal,INDICATOR_CALCULATIONS);
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   for(int i=0; i<COUNT; i++)
      PlotIndexSetInteger(i,PLOT_ARROW,167);
//--- setting indicator parameters
   IndicatorSetString(INDICATOR_SHORTNAME,"MACD Flat Trend ("+(string)period_fast+","+(string)period_slow+","+(string)period_sig+")");
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
   IndicatorSetInteger(INDICATOR_LEVELS,2);
   IndicatorSetInteger(INDICATOR_HEIGHT,60);
   IndicatorSetDouble(INDICATOR_MINIMUM,0);
   IndicatorSetDouble(INDICATOR_MAXIMUM,1);
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(BufferUP,true);
   ArraySetAsSeries(BufferDN,true);
   ArraySetAsSeries(BufferNL,true);
   ArraySetAsSeries(BufferMACD,true);
   ArraySetAsSeries(BufferSignal,true);
//--- create MACD handle
   ResetLastError();
   handle_macd=iMACD(NULL,PERIOD_CURRENT,period_fast,period_slow,period_sig,InpAppliedPrice);
   if(handle_macd==INVALID_HANDLE)
     {
      Print("The iMA(",(string)period_fast,",",(string)period_slow,",",(string)period_sig,") object was not created: Error ",GetLastError());
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
   if(rates_total<fmax(period_max,4)) return 0;
//--- Проверка и расчёт количества просчитываемых баров
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-1;
      ArrayInitialize(BufferUP,EMPTY_VALUE);
      ArrayInitialize(BufferDN,EMPTY_VALUE);
      ArrayInitialize(BufferNL,EMPTY_VALUE);
      ArrayInitialize(BufferMACD,0);
      ArrayInitialize(BufferSignal,0);
     }
//--- Подготовка данных
   int count=(limit>1 ? rates_total : 1),copied=0;
   copied=CopyBuffer(handle_macd,MAIN_LINE,0,count,BufferMACD);
   if(copied!=count) return 0;
   copied=CopyBuffer(handle_macd,SIGNAL_LINE,0,count,BufferSignal);
   if(copied!=count) return 0;
   
//--- Расчёт индикатора
   for(int i=limit; i>=0 && !IsStopped(); i--)
     {
      BufferNL[i]=BufferDN[i]=BufferUP[i]=EMPTY_VALUE;
      if(BufferMACD[i]>0 && BufferSignal[i]<BufferMACD[i])
        {
         BufferUP[i]=0.5;
         BufferNL[i]=BufferDN[i]=EMPTY_VALUE;
        }
      else
        {
         if(BufferMACD[i]<0 && BufferSignal[i]>BufferMACD[i])
           {
            BufferDN[i]=0.5;
            BufferNL[i]=BufferUP[i]=EMPTY_VALUE;
           }
         else
           {
            BufferNL[i]=0.5;
            BufferDN[i]=BufferUP[i]=EMPTY_VALUE;
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
//| Возвращает размер, соответствующий масштабу                      |
//+------------------------------------------------------------------+
uchar SizeByScale(void)
  {
   uchar scale=(uchar)ChartGetInteger(0,CHART_SCALE);
   uchar size=(scale<3 ? 1 : scale==3 ? 2 : scale==4 ? 5 : 8);
   return size;
  }
//+------------------------------------------------------------------+
//| Описание                                                         |
//+------------------------------------------------------------------+
void Descriptions(void)
  {
   int x=4;
   int y=1;
   int arr_colors[]={indicator_color1,indicator_color2,indicator_color3};
   string arr_texts[]={"Up trend","Down trend","Flat"};
   string arr_names[COUNT];
   for(int i=0; i<COUNT; i++)
     {
      arr_names[i]=prefix+"label"+(string)i;
      arr_colors[i]=PlotIndexGetInteger(i,PLOT_LINE_COLOR);
      x=(i==0 ? x : i==1 ? 80 : 170);
      Label(arr_names[i],x,y,CharToString(167),16,arr_colors[i],"Wingdings");
      Label(arr_names[i]+"_txt",x+10,y+5,arr_texts[i],10,clrGray,"Calibri");
     }
  }
//+------------------------------------------------------------------+
//| Выводит текстовую метку                                          |
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
