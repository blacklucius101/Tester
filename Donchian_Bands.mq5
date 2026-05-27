//+------------------------------------------------------------------+
//|                                               Donchian_Bands.mq5 |
//|                                    Copyright © 2025 Wolfforex.com|
//|                                        https://www.wolfforex.com |
//+------------------------------------------------------------------+
#property version   "1.00"
#property strict

#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots 7

#property indicator_label1 "Upper Line"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrGreen
#property indicator_width1 2

#property indicator_label2 "Lower Line"
#property indicator_type2 DRAW_LINE
#property indicator_color2 clrRed
#property indicator_width2 2

#property indicator_label3 "Mid Line"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrBlue
#property indicator_width3 1

#property indicator_label4 "Resistance"
#property indicator_type4 DRAW_LINE
#property indicator_style4 STYLE_DOT
#property indicator_color4 clrPaleGreen
#property indicator_width4 1

#property indicator_label5 "Support"
#property indicator_type5 DRAW_LINE
#property indicator_style5 STYLE_DOT
#property indicator_color5 clrSalmon
#property indicator_width5 1

#property indicator_label6 "Resistance Span"
#property indicator_type6 DRAW_FILLING
#property indicator_color6 clrDarkSlateGray, clrDarkSlateGray
#property indicator_width6 1

#property indicator_label7 "Support Span"
#property indicator_type7 DRAW_FILLING
#property indicator_color7 clrMaroon, clrMaroon
#property indicator_width7 1

input int InpPeriod = 20; // Period

double UpBuffer[];
double DownBuffer[];
double MidBuffer[];
double ResistanceBuffer[];
double SupportBuffer[];
double ResistanceFillingBuffer[];
double ResistanceFillingAddBuffer[];
double SupportFillingBuffer[];
double SupportFillingAddBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

    SetIndexBuffer(0, UpBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, DownBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, MidBuffer, INDICATOR_DATA);
    SetIndexBuffer(3, ResistanceBuffer, INDICATOR_DATA);
    SetIndexBuffer(4, SupportBuffer, INDICATOR_DATA);
    SetIndexBuffer(5, ResistanceFillingBuffer, INDICATOR_DATA);
    SetIndexBuffer(6, ResistanceFillingAddBuffer, INDICATOR_DATA);
    SetIndexBuffer(7, SupportFillingBuffer, INDICATOR_DATA);
    SetIndexBuffer(8, SupportFillingAddBuffer, INDICATOR_DATA);

    for (int i = 0; i < 7; i++)
    {
        PlotIndexSetInteger(i, PLOT_DRAW_BEGIN, InpPeriod - 1);
        PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, EMPTY_VALUE);
    }

    return INIT_SUCCEEDED;
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
    if (rates_total < InpPeriod) return 0;

    int pos = prev_calculated - 1;
    if (pos < InpPeriod - 1)
    {
        for (int i = 0; i < InpPeriod - 1; i++)
        {
            UpBuffer[i] = EMPTY_VALUE;
            DownBuffer[i] = EMPTY_VALUE;
            MidBuffer[i] = EMPTY_VALUE;
            ResistanceBuffer[i] = EMPTY_VALUE;
            SupportBuffer[i] = EMPTY_VALUE;
            ResistanceFillingBuffer[i] = EMPTY_VALUE;
            ResistanceFillingAddBuffer[i] = EMPTY_VALUE;
            SupportFillingBuffer[i] = EMPTY_VALUE;
            SupportFillingAddBuffer[i] = EMPTY_VALUE;
        }
        pos = InpPeriod - 1;
    }

    for (int i = pos; i < rates_total && !IsStopped(); i++)
    {
        int window_start = i - InpPeriod + 1;
        
        int highest_high_idx = ArrayMaximum(high, window_start, InpPeriod);
        int lowest_low_idx   = ArrayMinimum(low,  window_start, InpPeriod);
        int highest_low_idx  = ArrayMaximum(low,  window_start, InpPeriod);
        int lowest_high_idx  = ArrayMinimum(high, window_start, InpPeriod);

        if (highest_high_idx != -1 && lowest_low_idx != -1 && highest_low_idx != -1 && lowest_high_idx != -1)
        {
            UpBuffer[i]         = high[highest_high_idx];
            DownBuffer[i]       = low[lowest_low_idx];
            ResistanceBuffer[i] = low[highest_low_idx];
            SupportBuffer[i]    = high[lowest_high_idx];
            MidBuffer[i]        = (UpBuffer[i] + DownBuffer[i]) / 2.0;

            // Resistance Span: between Upper and Resistance
            ResistanceFillingBuffer[i]    = UpBuffer[i];
            ResistanceFillingAddBuffer[i] = ResistanceBuffer[i];
            
            // Support Span: between Support and Lower
            SupportFillingBuffer[i]    = SupportBuffer[i];
            SupportFillingAddBuffer[i] = DownBuffer[i];
        }
        else
        {
            UpBuffer[i] = EMPTY_VALUE;
            DownBuffer[i] = EMPTY_VALUE;
            MidBuffer[i] = EMPTY_VALUE;
            ResistanceBuffer[i] = EMPTY_VALUE;
            SupportBuffer[i] = EMPTY_VALUE;
            ResistanceFillingBuffer[i] = EMPTY_VALUE;
            ResistanceFillingAddBuffer[i] = EMPTY_VALUE;
            SupportFillingBuffer[i] = EMPTY_VALUE;
            SupportFillingAddBuffer[i] = EMPTY_VALUE;
        }
    }

    return rates_total;
}
