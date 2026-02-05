//+------------------------------------------------------------------+ 
//|                                               ZigZag NK Fibo.mq5 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+ 
//---- author of the indicator
#property copyright "Copyright © 2005, MetaQuotes Software Corp."
//---- link to the website of the author
#property link      "http://www.metaquotes.net/"
//---- indicator version
#property version   "1.00"
#property description "ZigZag"
//+----------------------------------------------+ 
//|  Indicator drawing parameters                |
//+----------------------------------------------+ 
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- 3 buffers are used for calculation and drawing the indicator
#property indicator_buffers 3
//---- one plot is used
#property indicator_plots   1
//---- ZIGZAG is used for the indicator
#property indicator_type1   DRAW_COLOR_ZIGZAG
//---- displaying the indicator label
#property indicator_label1  "ZigZag"
//---- color used for the indicator line
#property indicator_color1 Red,DodgerBlue
//---- the indicator line is a long dashed line
#property indicator_style1  STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width1  1
//+----------------------------------------------+ 
//|  Indicator input parameters                  |
//+----------------------------------------------+ 
input int ExtDepth=13;
input int ExtDeviation=8;
input int ExtBackstep =5;
input group "//---- Fibo features at the last high"
input bool DynamicFiboFlag=true;                          // DynamicFibo display flag 
input color DynamicFibo_color=BlueViolet;                       // DynamicFibo color
input ENUM_LINE_STYLE DynamicFibo_style=STYLE_DASHDOTDOT; // DynamicFibo style
input int DynamicFibo_width=1;                            // DynamicFibo line width
input bool DynamicFibo_AsRay=true;                        // DynamicFibo ray
input group "//---- Fibo features at the second to last high"
input bool StaticFiboFlag=true;                           // StaticFibo display flag
input color StaticFibo_color=Red;                         // StaticFibo color
input ENUM_LINE_STYLE StaticFibo_style=STYLE_DASH;        // StaticFibo style
input int StaticFibo_width=1;                             // StaticFibo line width
input bool StaticFibo_AsRay=false;                        // StaticFibo ray
input group "//---- Market Structure Lines"
input bool MarketStructureLines_Flag=true;                // Market Structure Lines display flag
input color HighLine_color_up=clrLime;                      // High-to-high line color for upward slope
input color HighLine_color_down=clrRed;                     // High-to-high line color for downward slope
input ENUM_LINE_STYLE HighLine_style=STYLE_DASH;         // High-to-high line style
input int HighLine_width=1;                               // High-to-high line width
input color LowLine_color_up=clrLime;                       // Low-to-low line color for upward slope
input color LowLine_color_down=clrRed;                      // Low-to-low line color for downward slope
input ENUM_LINE_STYLE LowLine_style=STYLE_DASH;           // Low-to-low line style
input int LowLine_width=1;                                // Low-to-low line width
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double LowestBuffer[];
double HighestBuffer[];
double ColorBuffer[];
//---- declaration of memory variables for recalculation of the indicator only at the previously not calculated bars
int LASTlowpos,LASThighpos,LASTColor;
double LASTlow0,LASTlow1,LASThigh0,LASThigh1;
//---- declaration of the integer variables for the start of data calculation
int StartBars;
//+------------------------------------------------------------------+
//|  Ñîçäàíèå Fibo                                                   |
//+------------------------------------------------------------------+
void CreateFibo(long     chart_id, // chart ID
                string   name,     // object name
                int      nwin,     // window index
                datetime time1,    // price level time 1
                double   price1,   // price level 1
                datetime time2,    // price level time 2
                double   price2,   // price level 2
                color    Color,    // line color
                int      style,    // line style
                int      width,    // line width
                int      ray,      // ray direction: -1 - to the left, +1 - to the right, other values - no ray
                string   text)     // text
  {
//----
   ObjectCreate(chart_id,name,OBJ_FIBO,nwin,time1,price1,time2,price2);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);

   if(ray>0)ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,true);
   if(ray<0)ObjectSetInteger(chart_id,name,OBJPROP_RAY_LEFT,true);

   if(ray==0)
     {
      ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,false);
      ObjectSetInteger(chart_id,name,OBJPROP_RAY_LEFT,false);
     }

   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);

   // Remove all default levels and add only 62% and 72%
   ObjectSetInteger(chart_id,name,OBJPROP_LEVELS,2);  // we want exactly 2 levels

   // --- First level: 62%
   ObjectSetDouble(chart_id,name,OBJPROP_LEVELVALUE,0,0.62);
   ObjectSetString(chart_id,name,OBJPROP_LEVELTEXT,0,"62%");
   ObjectSetInteger(chart_id,name,OBJPROP_LEVELCOLOR,0,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_LEVELSTYLE,0,style);
   ObjectSetInteger(chart_id,name,OBJPROP_LEVELWIDTH,0,width);

   // --- Second level: 72%
   ObjectSetDouble(chart_id,name,OBJPROP_LEVELVALUE,1,0.72);
   ObjectSetString(chart_id,name,OBJPROP_LEVELTEXT,1,"72%");
   ObjectSetInteger(chart_id,name,OBJPROP_LEVELCOLOR,1,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_LEVELSTYLE,1,style);
   ObjectSetInteger(chart_id,name,OBJPROP_LEVELWIDTH,1,width);
//----
  }
//+------------------------------------------------------------------+
//| Create Text                                                      |
//+------------------------------------------------------------------+
void CreateText(long     chart_id, // chart ID
                string   name,     // object name
                int      nwin,     // window index
                datetime time1,    // price level time 1
                double   price1,   // price level 1
                color    Color,    // text color
                string   text,     // text
                int      anchor)   // anchor
  {
//----
   ObjectCreate(chart_id,name,OBJ_TEXT,nwin,time1,price1);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(chart_id,name,OBJPROP_FONTSIZE,10);
//----
  }
//+------------------------------------------------------------------+
//| Text reinstallation                                              |
//+------------------------------------------------------------------+
void SetText(long     chart_id, // chart ID
             string   name,     // object name
             int      nwin,     // window index
             datetime time1,    // price level time 1
             double   price1,   // price level 1
             color    Color,    // text color
             string   text,     // text
             int      anchor)   // anchor
  {
//----
   if(ObjectFind(chart_id,name)==-1)
     {
      CreateText(chart_id,name,nwin,time1,price1,Color,text,anchor);
     }
   else
     {
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
      ObjectSetInteger(chart_id,name,OBJPROP_ANCHOR,anchor);
     }
//----
  }
//+------------------------------------------------------------------+
//|  Fibo reinstallation                                             |
//+------------------------------------------------------------------+
void SetFibo(long     chart_id, // chart ID
             string   name,     // object name
             int      nwin,     // window index
             datetime time1,    // price level time 1
             double   price1,   // price level 1
             datetime time2,    // price level time 2
             double   price2,   // price level 2
             color    Color,    // line color
             int      style,    // line style
             int      width,    // line width
             int      ray,      // ray direction: -1 - to the left, 0 - no ray, +1 - to the right
             string   text)     // text
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateFibo(chart_id,name,nwin,time1,price1,time2,price2,Color,style,width,ray,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectMove(chart_id,name,1,time2,price2);
     }
//----
  }
//+------------------------------------------------------------------+
//| Searching for the very first ZigZag high in time series buffers  |
//+------------------------------------------------------------------+     
int FindFirstExtremum(int StartPos,int Rates_total,double &UpArray[],double &DnArray[],int &Sign,double &Extremum)
  {
//----
   if(StartPos>=Rates_total)StartPos=Rates_total-1;

   for(int bar=StartPos; bar<Rates_total; bar++)
     {
      if(UpArray[bar]!=0.0 && UpArray[bar]!=EMPTY_VALUE)
        {
         Sign=+1;
         Extremum=UpArray[bar];
         return(bar);
         break;
        }

      if(DnArray[bar]!=0.0 && DnArray[bar]!=EMPTY_VALUE)
        {
         Sign=-1;
         Extremum=DnArray[bar];
         return(bar);
         break;
        }
     }
//----
   return(-1);
  }
//+------------------------------------------------------------------+
//| Searching for the second ZigZag high in time series buffers      |
//+------------------------------------------------------------------+     
int FindSecondExtremum(int Direct,int StartPos,int Rates_total,double &UpArray[],double &DnArray[],int &Sign,double &Extremum)
  {
//----
   if(StartPos>=Rates_total)StartPos=Rates_total-1;

   if(Direct==-1)
      for(int bar=StartPos; bar<Rates_total; bar++)
        {
         if(UpArray[bar]!=0.0 && UpArray[bar]!=EMPTY_VALUE)
           {
            Sign=+1;
            Extremum=UpArray[bar];
            return(bar);
            break;
           }

        }

   if(Direct==+1)
      for(int bar=StartPos; bar<Rates_total; bar++)
        {
         if(DnArray[bar]!=0.0 && DnArray[bar]!=EMPTY_VALUE)
           {
            Sign=-1;
            Extremum=DnArray[bar];
            return(bar);
            break;
           }
        }
//----
   return(-1);
  }
//+------------------------------------------------------------------+ 
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   StartBars=ExtDepth+ExtBackstep;

//---- set dynamic arrays as indicator buffers
   SetIndexBuffer(0,LowestBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,HighestBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ColorBuffer,INDICATOR_COLOR_INDEX);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
//---- create labels to display in Data Window
   PlotIndexSetString(0,PLOT_LABEL,"ZigZag Lowest");
   PlotIndexSetString(1,PLOT_LABEL,"ZigZag Highest");
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(LowestBuffer,true);
   ArraySetAsSeries(HighestBuffer,true);
   ArraySetAsSeries(ColorBuffer,true);
//---- set the position, from which the drawing starts
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBars);
//---- setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string shortname;
   StringConcatenate(shortname,"ZigZag (ExtDepth=",
                     ExtDepth,"ExtDeviation = ",ExtDeviation,"ExtBackstep = ",ExtBackstep,")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//----   
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+     
void OnDeinit(const int reason)
  {
//----
   ObjectDelete(0,"DynamicFibo");
   ObjectDelete(0,"StaticFibo");
   ObjectsDeleteAll(0, "MS_High_");
   ObjectsDeleteAll(0, "MS_Low_");
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
//---- checking the number of bars to be enough for the calculation
   if(rates_total<StartBars) return(0);

//----
   ObjectsDeleteAll(0,"MS_High_");
   ObjectsDeleteAll(0,"MS_Low_");

//---- declarations of local variables 
   int limit,climit,bar,back,lasthighpos,lastlowpos;
   double curlow,curhigh,lasthigh0=0.0,lastlow0=0.0,lasthigh1,lastlow1,val,res;
   bool Max,Min;

//---- declarations of variables for creating Fibo
   int bar1,bar2,bar3,sign;
   double price1,price2,price3;

//---- calculate the limit starting index for loop of bars recalculation and start initialization of variables
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-StartBars; // starting index for calculation of all bars
      climit=limit;                // starting index for the indicator coloring

      lastlow1=-1;
      lasthigh1=-1;
      lastlowpos=-1;
      lasthighpos=-1;
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
      climit=limit+StartBars;            // starting index for the indicator coloring

      //---- restore values of the variables
      lastlow0=LASTlow0;
      lasthigh0=LASThigh0;

      lastlow1=LASTlow1;
      lasthigh1=LASThigh1;

      lastlowpos=LASTlowpos+limit;
      lasthighpos=LASThighpos+limit;
     }

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(time,true);

//---- first big indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- store values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0)
        {
         LASTlow0=lastlow0;
         LASThigh0=lasthigh0;
        }

      //---- low
      val=low[ArrayMinimum(low,bar,ExtDepth)];
      if(val==lastlow0) val=0.0;
      else
        {
         lastlow0=val;
         if((low[bar]-val)>(ExtDeviation*_Point))val=0.0;
         else
           {
            for(back=1; back<=ExtBackstep; back++)
              {
               res=LowestBuffer[bar+back];
               if((res!=0) && (res>val))
                 {
                  LowestBuffer[bar+back]=0.0;
                 }
              }
           }
        }
      LowestBuffer[bar]=val;

      //---- high
      val=high[ArrayMaximum(high,bar,ExtDepth)];
      if(val==lasthigh0) val=0.0;
      else
        {
         lasthigh0=val;
         if((val-high[bar])>(ExtDeviation*_Point))val=0.0;
         else
           {
            for(back=1; back<=ExtBackstep; back++)
              {
               res=HighestBuffer[bar+back];
               if((res!=0) && (res<val))
                 {
                  HighestBuffer[bar+back]=0.0;
                 }
              }
           }
        }
      HighestBuffer[bar]=val;
     }

//---- the second big indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- store values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0)
        {
         LASTlow1=lastlow1;
         LASThigh1=lasthigh1;
         //----
         LASTlowpos=lastlowpos;
         LASThighpos=lasthighpos;
        }

      curlow=LowestBuffer[bar];
      curhigh=HighestBuffer[bar];
      //----
      if((curlow==0) && (curhigh==0))continue;
      //----
      if(curhigh!=0)
        {
         if(lasthigh1>0)
           {
            if(lasthigh1<curhigh)
              {
               HighestBuffer[lasthighpos]=0;
              }
            else
              {
               HighestBuffer[bar]=0;
              }
           }
         //----
         if(lasthigh1<curhigh || lasthigh1<0)
           {
            lasthigh1=curhigh;
            lasthighpos=bar;
           }
         lastlow1=-1;
        }
      //----
      if(curlow!=0)
        {
         if(lastlow1>0)
           {
            if(lastlow1>curlow)
              {
               LowestBuffer[lastlowpos]=0;
              }
            else
              {
               LowestBuffer[bar]=0;
              }
           }
         //----
         if((curlow<lastlow1) || (lastlow1<0))
           {
            lastlow1=curlow;
            lastlowpos=bar;
           }
         lasthigh1=-1;
        }
     }

//---- the third big indicator coloring loop
   for(bar=climit; bar>=0 && !IsStopped(); bar--)
     {
      Max=HighestBuffer[bar];
      Min=LowestBuffer[bar];

      if(!Max && !Min) ColorBuffer[bar]=ColorBuffer[bar+1];
      if(Max && Min)
        {
         if(ColorBuffer[bar+1]==0) ColorBuffer[bar]=1;
         else                      ColorBuffer[bar]=0;
        }

      if( Max && !Min) ColorBuffer[bar]=1;
      if(!Max &&  Min) ColorBuffer[bar]=0;
     }
//---- Fibo creation
   if(StaticFiboFlag || DynamicFiboFlag)
     {
      bar1=FindFirstExtremum(0,rates_total,HighestBuffer,LowestBuffer,sign,price1);
      bar2=FindSecondExtremum(sign,bar1,rates_total,HighestBuffer,LowestBuffer,sign,price2);

      if(DynamicFiboFlag)
        {
         SetFibo(0,"DynamicFibo",0,time[bar2],price2,time[bar1],price1,
                 DynamicFibo_color,DynamicFibo_style,DynamicFibo_width,DynamicFibo_AsRay,"DynamicFibo");
        }
      else
        {
         ObjectDelete(0,"DynamicFibo");
        }

      if(StaticFiboFlag)
        {
         bar3=FindSecondExtremum(sign,bar2,rates_total,HighestBuffer,LowestBuffer,sign,price3);
         SetFibo(0,"StaticFibo",0,time[bar3],price3,time[bar2],price2,
                 StaticFibo_color,StaticFibo_style,StaticFibo_width,StaticFibo_AsRay,"StaticFibo");
        }
      else
        {
         ObjectDelete(0,"StaticFibo");
        }

      ChartRedraw(0);
     }
   else
     {
      ObjectDelete(0,"DynamicFibo");
      ObjectDelete(0,"StaticFibo");
      ChartRedraw(0);
     }
//----     
   DrawMarketStructureLines(rates_total, time);
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Draw Market Structure Lines                                      |
//+------------------------------------------------------------------+
void DrawMarketStructureLines(const int rates_total, const datetime &time[])
{
    if(!MarketStructureLines_Flag)
    {
        ObjectsDeleteAll(0, "MS_High_");
        ObjectsDeleteAll(0, "MS_Low_");
        return;
    }

    int high_pivots_count = 0;
    int low_pivots_count = 0;

    for(int i = 0; i < rates_total; i++)
    {
        if(HighestBuffer[i] > 0) high_pivots_count++;
        if(LowestBuffer[i] > 0) low_pivots_count++;
    }

    if(high_pivots_count < 2 && low_pivots_count < 2) return;

    datetime high_pivots_time[];
    double high_pivots_price[];
    datetime low_pivots_time[];
    double low_pivots_price[];

    ArrayResize(high_pivots_time, high_pivots_count);
    ArrayResize(high_pivots_price, high_pivots_count);
    ArrayResize(low_pivots_time, low_pivots_count);
    ArrayResize(low_pivots_price, low_pivots_count);

    int high_idx = 0;
    int low_idx = 0;

    for(int i = 0; i < rates_total; i++)
    {
        if(HighestBuffer[i] > 0)
        {
            high_pivots_time[high_idx] = time[i];
            high_pivots_price[high_idx] = HighestBuffer[i];
            high_idx++;
        }
        if(LowestBuffer[i] > 0)
        {
            low_pivots_time[low_idx] = time[i];
            low_pivots_price[low_idx] = LowestBuffer[i];
            low_idx++;
        }
    }

    for(int i = 1; i < high_pivots_count; i++)
    {
        string name = "MS_High_" + (string)i;
        color line_color = high_pivots_price[i] > high_pivots_price[i-1] ? HighLine_color_down : HighLine_color_up;
        DrawTrendLine(name, high_pivots_time[i-1], high_pivots_price[i-1], high_pivots_time[i], high_pivots_price[i], line_color, HighLine_style, HighLine_width);
    }

    for(int i = 1; i < low_pivots_count; i++)
    {
        string name = "MS_Low_" + (string)i;
        color line_color = low_pivots_price[i] > low_pivots_price[i-1] ? LowLine_color_down : LowLine_color_up ;
        DrawTrendLine(name, low_pivots_time[i-1], low_pivots_price[i-1], low_pivots_time[i], low_pivots_price[i], line_color, LowLine_style, LowLine_width);
    }
}

//+------------------------------------------------------------------+
//| Draw Trend Line                                                  |
//+------------------------------------------------------------------+
void DrawTrendLine(string name, datetime time1, double price1, datetime time2, double price2, color line_color, ENUM_LINE_STYLE style, int width)
{
    ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);
    ObjectSetInteger(0, name, OBJPROP_COLOR, line_color);
    ObjectSetInteger(0, name, OBJPROP_STYLE, style);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
    ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
}
