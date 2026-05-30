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

input int InpPeriod = 17;      // Period
input datetime InpTargetDate = 0; // Target Date (0 = Latest Day)

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
    ArraySetAsSeries(UpBuffer,false);
    SetIndexBuffer(1, DownBuffer, INDICATOR_DATA);
    ArraySetAsSeries(DownBuffer,false);
    SetIndexBuffer(2, MidBuffer, INDICATOR_DATA);
    ArraySetAsSeries(MidBuffer,false);
    SetIndexBuffer(3, ResistanceBuffer, INDICATOR_DATA);
    ArraySetAsSeries(ResistanceBuffer,false);
    SetIndexBuffer(4, SupportBuffer, INDICATOR_DATA);
    ArraySetAsSeries(SupportBuffer,false);
    SetIndexBuffer(5, ResistanceFillingBuffer, INDICATOR_DATA);
    ArraySetAsSeries(ResistanceFillingBuffer,false);
    SetIndexBuffer(6, ResistanceFillingAddBuffer, INDICATOR_DATA);
    ArraySetAsSeries(ResistanceFillingAddBuffer,false);
    SetIndexBuffer(7, SupportFillingBuffer, INDICATOR_DATA);
    ArraySetAsSeries(SupportFillingBuffer,false);
    SetIndexBuffer(8, SupportFillingAddBuffer, INDICATOR_DATA);
    ArraySetAsSeries(SupportFillingAddBuffer,false);

    for (int i = 0; i < 7; i++)
    {
        PlotIndexSetInteger(i, PLOT_DRAW_BEGIN, 0);
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

    static datetime lastTargetDayStart = 0;

    // Determine target day
    datetime targetDayTime = InpTargetDate;
    if (targetDayTime == 0)
        targetDayTime = time[rates_total - 1];

    MqlDateTime dt;
    TimeToStruct(targetDayTime, dt);
    dt.hour = 0; dt.min = 0; dt.sec = 0;
    datetime targetDayStart = StructToTime(dt);

    // If target day changed or full recalculation, clear all buffers
    if (targetDayStart != lastTargetDayStart || prev_calculated == 0)
    {
        ArrayFill(UpBuffer, 0, rates_total, EMPTY_VALUE);
        ArrayFill(DownBuffer, 0, rates_total, EMPTY_VALUE);
        ArrayFill(MidBuffer, 0, rates_total, EMPTY_VALUE);
        ArrayFill(ResistanceBuffer, 0, rates_total, EMPTY_VALUE);
        ArrayFill(SupportBuffer, 0, rates_total, EMPTY_VALUE);
        ArrayFill(ResistanceFillingBuffer, 0, rates_total, EMPTY_VALUE);
        ArrayFill(ResistanceFillingAddBuffer, 0, rates_total, EMPTY_VALUE);
        ArrayFill(SupportFillingBuffer, 0, rates_total, EMPTY_VALUE);
        ArrayFill(SupportFillingAddBuffer, 0, rates_total, EMPTY_VALUE);
        lastTargetDayStart = targetDayStart;
    }

    // Always ensure the currently forming candle is empty (closed candles only)
    UpBuffer[rates_total - 1] = EMPTY_VALUE;
    DownBuffer[rates_total - 1] = EMPTY_VALUE;
    MidBuffer[rates_total - 1] = EMPTY_VALUE;
    ResistanceBuffer[rates_total - 1] = EMPTY_VALUE;
    SupportBuffer[rates_total - 1] = EMPTY_VALUE;
    ResistanceFillingBuffer[rates_total - 1] = EMPTY_VALUE;
    ResistanceFillingAddBuffer[rates_total - 1] = EMPTY_VALUE;
    SupportFillingBuffer[rates_total - 1] = EMPTY_VALUE;
    SupportFillingAddBuffer[rates_total - 1] = EMPTY_VALUE;

    int start_idx = -1;
    int end_idx = -1;

    // Search for the target day's range of candles
    for (int i = rates_total - 1; i >= 0; i--)
    {
        MqlDateTime candle_dt;
        TimeToStruct(time[i], candle_dt);
        candle_dt.hour = 0; candle_dt.min = 0; candle_dt.sec = 0;
        datetime candle_day = StructToTime(candle_dt);

        if (candle_day == targetDayStart)
        {
            if (end_idx == -1) end_idx = i;
            start_idx = i;
        }
        else if (end_idx != -1)
        {
            break;
        }
    }

    if (start_idx == -1) return rates_total;

    // Only process closed candles
    int calc_end_idx = end_idx;
    if (calc_end_idx == rates_total - 1) calc_end_idx--;

    if (calc_end_idx < start_idx) return rates_total;

    // Recalculate from where we left off, but stay within the target day
    int limit = prev_calculated - 1;
    if (limit < start_idx) limit = start_idx;
    
    // If target day changed, we must recalculate the entire new session
    if (prev_calculated == 0 || targetDayStart != lastTargetDayStart) limit = start_idx;

    for (int i = limit; i <= calc_end_idx && !IsStopped(); i++)
    {
        if (i < InpPeriod - 1)
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
            continue;
        }

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

            ResistanceFillingBuffer[i]    = UpBuffer[i];
            ResistanceFillingAddBuffer[i] = ResistanceBuffer[i];
            
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
