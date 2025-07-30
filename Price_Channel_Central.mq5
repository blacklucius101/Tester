//+------------------------------------------------------------------+
//|                                        Price_Channel_Central.mq5 |
//|                             Copyright © 2015, Yuriy Tokman (YTG) |
//|                                               http://ytg.com.ua/ |
//+------------------------------------------------------------------+
//---- àâòîðñòâî èíäèêàòîðà
#property copyright "Yuriy Tokman (YTG)"
//---- ññûëêà íà ñàéò àâòîðà
#property link      "http://ytg.com.ua/"
//---- íîìåð âåðñèè èíäèêàòîðà
#property version   "1.00"
#property description "Price Channel Central" 
//---- îòðèñîâêà èíäèêàòîðà â ãëàâíîì îêíå
#property indicator_chart_window 
//---- äëÿ ðàñ÷åòà è îòðèñîâêè èíäèêàòîðà èñïîëüçîâàíî 5 áóôåðîâ
#property indicator_buffers 5
//---- èñïîëüçîâàíî âñåãî ïÿòü ãðàôè÷åñêèõ ïîñòðîåíèé
#property indicator_plots   5
//+----------------------------------------------+ 
//| Ïàðàìåòðû îòðèñîâêè èíäèêàòîðà               |
//+----------------------------------------------+
//---- â êà÷åñòâå èíäèêàòîðà èñïîëüçîâàíà ëèíèÿ
#property indicator_type1   DRAW_LINE
//---- îòîáðàæåíèå ìåòêè èíäèêàòîðà
#property indicator_label1  "Chanell Upper"
//---- â êà÷åñòâå öâåòîâ ëèíèè èíäèêàòîðà èñïîëüçîâàí
#property indicator_color1 clrLime
//---- ëèíèÿ èíäèêàòîðà - ñïëîøíàÿ
#property indicator_style1  STYLE_SOLID
//---- òîëùèíà ëèíèè èíäèêàòîðà ðàâíà 2
#property indicator_width1  2
//+----------------------------------------------+ 
//| Ïàðàìåòðû îòðèñîâêè èíäèêàòîðà               |
//+----------------------------------------------+
//---- â êà÷åñòâå èíäèêàòîðà èñïîëüçîâàíà ëèíèÿ
#property indicator_type2   DRAW_LINE
//---- îòîáðàæåíèå ìåòêè èíäèêàòîðà
#property indicator_label2  "Chanell Middle"
//---- â êà÷åñòâå öâåòîâ ëèíèè èíäèêàòîðà èñïîëüçîâàí
#property indicator_color2 clrBlue
//---- ëèíèÿ èíäèêàòîðà - ñïëîøíàÿ
#property indicator_style2  STYLE_SOLID
//---- òîëùèíà ëèíèè èíäèêàòîðà ðàâíà 2
#property indicator_width2  2
//+----------------------------------------------+ 
//| Ïàðàìåòðû îòðèñîâêè èíäèêàòîðà               |
//+----------------------------------------------+
//---- â êà÷åñòâå èíäèêàòîðà èñïîëüçîâàíà ëèíèÿ
#property indicator_type3   DRAW_LINE
//---- îòîáðàæåíèå ìåòêè èíäèêàòîðà
#property indicator_label3  "Chanell Lower"
//---- â êà÷åñòâå öâåòîâ ëèíèè èíäèêàòîðà èñïîëüçîâàí
#property indicator_color3 clrRed
//---- ëèíèÿ èíäèêàòîðà - ñïëîøíàÿ
#property indicator_style3  STYLE_SOLID
//---- òîëùèíà ëèíèè èíäèêàòîðà ðàâíà 2
#property indicator_width3  2
//+----------------------------------------------+
//| Ïàðàìåòðû îòðèñîâêè ìåäâåæüåãî èíäèêàòîðà    |
//+----------------------------------------------+
//--- îòðèñîâêà èíäèêàòîðà 4 â âèäå ñèìâîëà
#property indicator_type4   DRAW_ARROW
//--- â êà÷åñòâå öâåòà ìåäâåæüåé ëèíèè èíäèêàòîðà èñïîëüçîâàí ðîçîâûé öâåò
#property indicator_color4  clrMagenta
//--- òîëùèíà ëèíèè èíäèêàòîðà 4 ðàâíà 5
#property indicator_width4  5
//--- îòîáðàæåíèå ìåäâåæüåé ìåòêè èíäèêàòîðà
#property indicator_label4  "Price_Channel_Central Sell"
//+----------------------------------------------+
//| Ïàðàìåòðû îòðèñîâêè áû÷üåãî èíäèêàòîðà       |
//+----------------------------------------------+
//--- îòðèñîâêà èíäèêàòîðà 5 â âèäå ñèìâîëà
#property indicator_type5   DRAW_ARROW
//--- â êà÷åñòâå öâåòà áû÷üåé ëèíèè èíäèêàòîðà èñïîëüçîâàí ãîëóáîé öâåò
#property indicator_color5  clrDodgerBlue
//--- òîëùèíà ëèíèè èíäèêàòîðà 5 ðàâíà 5
#property indicator_width5  5
//--- îòîáðàæåíèå áû÷üåé ìåòêè èíäèêàòîðà
#property indicator_label5 "Price_Channel_Central Buy"
//+----------------------------------------------+ 
//| Îáúÿâëåíèå êîíñòàíò                          |
//+----------------------------------------------+ 
#define RESET 0 // êîíñòàíòà äëÿ âîçâðàòà òåðìèíàëó êîìàíäû íà ïåðåñ÷åò èíäèêàòîðà
//+----------------------------------------------+ 
//| Âõîäíûå ïàðàìåòðû èíäèêàòîðà                 |
//+----------------------------------------------+ 
input uint Bars_Count=32;
input color  Upper_color=clrTeal;
input color  Middle_color=clrBlue;
input color  Lower_color=clrRed;
//+----------------------------------------------+
//---- îáúÿâëåíèå äèíàìè÷åñêèõ ìàññèâîâ, êîòîðûå áóäóò â 
//---- äàëüíåéøåì èñïîëüçîâàíû â êà÷åñòâå èíäèêàòîðíûõ áóôåðîâ
double LowestBuffer[];
double HighestBuffer[];
double MiddleBuffer[];
double SellBuffer[];
double BuyBuffer[];
//---- îáúÿâëåíèå öåëî÷èñëåííûõ ïåðåìåííûõ íà÷àëà îòñ÷åòà äàííûõ
int min_rates_total;
//---- îáúÿâëåíèå öåëî÷èñëåííûõ ïåðåìåííûõ äëÿ õåíäëîâ èíäèêàòîðîâ
int ATR_Handle;
//---- îáúÿâëåíèå ñòðîêîâûõ ïåðåìåííûõ äëÿ òåêñòîâûõ ìåòîê
string upper_name,middle_name,lower_name;
//+------------------------------------------------------------------+ 
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+ 
int OnInit()
  {
//---- èíèöèàëèçàöèÿ ïåðåìåííûõ íà÷àëà îòñ÷åòà äàííûõ
   int ATR_Period=15;
   min_rates_total=int(MathMax(Bars_Count,ATR_Period))+1;
//--- ïîëó÷åíèå õåíäëà èíäèêàòîðà ATR
   ATR_Handle=iATR(NULL,0,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Íå óäàëîñü ïîëó÷èòü õåíäë èíäèêàòîðà ATR");
      return(INIT_FAILED);
     }
//---- èíèöèàëèçàöèÿ ñòðîêîâûõ ïåðåìåííûõ
   upper_name="Price_Channel_Central upper text lable";
   middle_name="Price_Channel_Central middle text lable";
   lower_name="Price_Channel_Central lower text lable";
//---- ïðåâðàùåíèå äèíàìè÷åñêèõ ìàññèâîâ â èíäèêàòîðíûå áóôåðû    
   SetIndexBuffer(0,HighestBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,MiddleBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,LowestBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,SellBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,BuyBuffer,INDICATOR_DATA);
//---- çàïðåò íà îòðèñîâêó èíäèêàòîðîì ïóñòûõ çíà÷åíèé
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0.0);
//---- èíäåêñàöèÿ ýëåìåíòîâ â áóôåðàõ êàê â òàéìñåðèÿõ   
   ArraySetAsSeries(LowestBuffer,true);
   ArraySetAsSeries(HighestBuffer,true);
   ArraySetAsSeries(MiddleBuffer,true);
   ArraySetAsSeries(SellBuffer,true);
   ArraySetAsSeries(BuyBuffer,true);
//---- óñòàíîâêà ïîçèöèè, ñ êîòîðîé íà÷èíàåòñÿ îòðèñîâêà
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
//---- óñòàíîâêà ôîðìàòà òî÷íîñòè îòîáðàæåíèÿ èíäèêàòîðà
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- èìÿ äëÿ îêîí äàííûõ è ëýéáà äëÿ ñóáúîêîí 
   string shortname;
   StringConcatenate(shortname,"Price_Channel_Central(",Bars_Count,")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   ObjectDelete(0,upper_name);
   ObjectDelete(0,middle_name);
   ObjectDelete(0,lower_name);
//----
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
//---- ïðîâåðêà êîëè÷åñòâà áàðîâ íà äîñòàòî÷íîñòü äëÿ ðàñ÷åòà
   if(BarsCalculated(ATR_Handle)<rates_total || rates_total<min_rates_total)return(RESET);
//---- îáúÿâëåíèå ëîêàëüíûõ ïåðåìåííûõ 
   int limit,to_copy,bar;
   double ATR[];
//---- ðàñ÷åò ñòàðòîâîãî íîìåðà limit äëÿ öèêëà ïåðåñ÷åòà áàðîâ è ñòàðòîâàÿ èíèöèàëèçàöèÿ ïåðåìåííûõ
   if(prev_calculated>rates_total || prev_calculated<=0)// ïðîâåðêà íà ïåðâûé ñòàðò ðàñ÷åòà èíäèêàòîðà
     {
      limit=rates_total-1-min_rates_total; // ñòàðòîâûé íîìåð äëÿ ðàñ÷åòà âñåõ áàðîâ
     }
   else
     {
      limit=rates_total-prev_calculated; // ñòàðòîâûé íîìåð äëÿ ðàñ÷åòà íîâûõ áàðîâ
     }
   to_copy=limit+1;
//---- èíäåêñàöèÿ ýëåìåíòîâ â ìàññèâàõ êàê â òàéìñåðèÿõ 
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(ATR,true);
//---- êîïèðóåì âíîâü ïîÿâèâøèåñÿ äàííûå â ìàññèâ
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);
//---- ïåðâûé áîëüøîé öèêë ðàñ÷åòà èíäèêàòîðà
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      double HH=high[ArrayMaximum(high,bar,Bars_Count)];
      double LL=low[ArrayMinimum(low,bar,Bars_Count)];
      double MM=(HH+LL)/2;
      HighestBuffer[bar]=HH;
      LowestBuffer[bar]=LL;
      MiddleBuffer[bar]=MM;
      //---
      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;
      //---
      if(close[bar]>HighestBuffer[bar+1]) BuyBuffer[bar]=low[bar]-ATR[bar]*3/8;
      if(close[bar]<LowestBuffer[bar+1]) SellBuffer[bar]=high[bar]+ATR[bar]*3/8;
     }
   SetRightPrice(0,upper_name,0,time[0],HighestBuffer[0],Upper_color,"Georgia");
   SetRightPrice(0,middle_name,0,time[0],MiddleBuffer[0],Middle_color,"Georgia");
   SetRightPrice(0,lower_name,0,time[0],LowestBuffer[0],Lower_color,"Georgia");
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|  RightPrice creation                                             |
//+------------------------------------------------------------------+
void CreateRightPrice(long chart_id,// chart ID
                      string   name,              // object name
                      int      nwin,              // window index
                      datetime time,              // price level time
                      double   price,             // price level
                      color    Color,             // Text color
                      string   Font)              // Text font
  {
//----
   ObjectCreate(chart_id,name,OBJ_ARROW_RIGHT_PRICE,nwin,time,price);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetString(chart_id,name,OBJPROP_FONT,Font);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
//----
  }
//+------------------------------------------------------------------+
//|  RightPrice reinstallation                                       |
//+------------------------------------------------------------------+
void SetRightPrice(long chart_id,              // chart ID
                   string   name,              // object name
                   int      nwin,              // window index
                   datetime time,              // price level time
                   double   price,             // price level
                   color    Color,             // Text color
                   string   Font)              // Text font
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateRightPrice(chart_id,name,nwin,time,price,Color,Font);
   else ObjectMove(chart_id,name,0,time,price);
//----
  }
//+------------------------------------------------------------------+
