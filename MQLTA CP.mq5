#property link          "https://www.earnforex.com/metatrader-indicators/candlestick-pattern-indicator/"
#property version       "1.03"

#property copyright     "EarnForex.com - 2019-2024"
#property description   "Place price lines with alerts."
#property description   ""
#property description   "WARNING: Use this software at your own risk."
#property description   "The creator of this indicator cannot be held responsible for any damage or loss."
#property description   ""
#property description   "Find more on www.EarnForex.com"
#property icon          "\\Files\\EF-Icon-64x64px.ico"

#include <MQLTA Candlestick Patterns.mqh>
#include <MQLTA Utils.mqh>

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_type1   DRAW_NONE
#property indicator_label1  "Pattern Direction"
#property indicator_type2   DRAW_NONE
#property indicator_label2  "Pattern Detected"

input string Comment_1 = "====================";         // Pattern Detector Settings
input string IndicatorName = "PTRNDET";                  // Indicator Name (used to draw objects)
input string Comment_2 = "====================";         // Pattern To Detect
input int MaxCandle = 500;                               // Candles to scan (0 = all)
input bool DetectBullish = true;                         // Detect Bullish Patterns
input bool DetectBearish = true;                         // Detect Bearish Patterns
input bool DetectUncertain = true;                       // Detect Uncertain Patterns
input string Comment_2a = "====================";        // Individual Pattern Selection
input bool DetectDojiNeutral = true;                     // Doji
input bool DetectDojiDragonfly = true;                   // Doji Dragonfly
input bool DetectDojiGravestone = true;                  // Doji Gravestone
input bool DetectSpinningTopBull = true;                 // Spinning Top Bullish
input bool DetectSpinningTopBear = true;                 // Spinning Top Bearish
input bool DetectMarubozuUp = true;                      // Marubozu Bullish
input bool DetectMarubozuDown = true;                    // Marubozu Bearish
input bool DetectHammer = true;                          // Hammer
input bool DetectHangingMan = true;                      // Hanging Man
input bool DetectInvertedHammer = true;                  // Inverted Hammer
input bool DetectShootingStar = true;                    // Shooting Star
input bool DetectEngulfingBull = true;                   // Engulfing Bull
input bool DetectEngulfingBear = true;                   // Engulfing Bear
input bool DetectTweezerTop = true;                      // Tweezer Top
input bool DetectTweezerBottom = true;                   // Tweezer Bottom
input bool DetectThreeWhiteSoldier = true;               // Three White Soldier
input bool DetectThreeBlackCrows = true;                 // Three Black Crows
input bool DetectThreeInsideUp = true;                   // Three Inside Up
input bool DetectThreeInsideDown = true;                 // Three Inside Down
input bool DetectMorningStar = true;                     // Morning Star
input bool DetectEveningStar = true;                     // Evening Star
input bool DetectBullishHarami = true;                   // Bullish Harami
input bool DetectBearishHarami = true;                   // Bearish Harami
input bool DetectBullishThreeLineStrike = true;          // Bullish Three-Line Strike
input bool DetectBearishThreeLineStrike = true;          // Bearish Three-Line Strike
input bool DetectThreeOutsideUp = true;                  // Three Outside Up
input bool DetectThreeOutsideDown = true;                // Three Outside Down
input string Comment_2b = "====================";        // Display Options
input int FontSize = 8;                                  // Font Size
input color FontColorBullish = clrGreen;                 // Font Color Bullish Patterns
input color FontColorBearish = clrRed;                   // Font Color Bearish Patterns
input color FontColorUncertain = clrBlack;               // Font Color Uncertain Patterns
input string Comment_3 = "====================";         // Notification Options
input bool EnableNotify = false;                         // Enable Notifications Feature
input bool SendAlert = true;                             // Send Alert Notification
input bool SendApp = false;                              // Send Notification to Mobile
input bool SendEmail = false;                            // Send Notification via Email
input string Comment_4 = "====================";         // Panel Position
input ENUM_BASE_CORNER ChartCorner = CORNER_LEFT_UPPER;
input int Xoff = 20;                                     // Horizontal spacing for the control panel
input int Yoff = 20;                                     // Vertical spacing for the control panel

double BufferPatternDirection[];
double BufferPatternDetected[];

bool IsNewCandle = true;

bool DetectionEnabled = true;
bool PreviousDrawn = false;
bool NotifiedThisCandle = false;

enum ENUM_TYPE_OF_PATTERN
{
    UNCERTAIN = 0, // UNCERTAIN
    BULLISH = 1,   // BULLISH
    BEARISH = 2,   // BEARISH
};

double DPIScale; // Scaling parameter for the panel based on the screen DPI.
int PanelMovX, PanelMovY, PanelLabX, PanelLabY, PanelRecX;

int OnInit()
{
    IndicatorSetString(INDICATOR_SHORTNAME, IndicatorName);

    DPIScale = (double)TerminalInfoInteger(TERMINAL_SCREEN_DPI) / 96.0;

    PanelMovX = (int)MathRound(26 * DPIScale);
    PanelMovY = (int)MathRound(26 * DPIScale);
    PanelLabX = (int)MathRound(120 * DPIScale);
    PanelLabY = PanelMovY;
    PanelRecX = (PanelMovX + 2) * 2 + PanelLabX + 2;

    CleanChart();
    InitialiseBuffers();
    CreateMiniPanel();
    
    PreviousDrawn = false;
    DetectionEnabled = true;
    return INIT_SUCCEEDED;
}

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
    if (prev_calculated == 0)
    {
        ArrayInitialize(BufferPatternDirection, 0);
        ArrayInitialize(BufferPatternDetected, 0);
    }
    IsNewCandle = IsNewCandleCheck();
    if (IsNewCandle) NotifiedThisCandle = false;
    if (DetectionEnabled) DetectPattern();
    return rates_total;
}

void OnDeinit(const int reason)
{
    CleanChart();
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        if (sparam == PanelDraw)
        {
            if (DetectionEnabled) DetectionEnabled = false;
            else DetectionEnabled = true;
            CreateMiniPanel();
        }
        else if (sparam == PanelClean)
        {
            CleanPrevious();
        }
    }
    // Redraw labels.
    else if (id == CHARTEVENT_CHART_CHANGE)
    {
    }
    else if (id == CHARTEVENT_KEYDOWN)
    {
        // Home, End, PgUp, PgDn, Arrows, F12.
        if (((TranslateKey((int)lparam) >= 33) && (TranslateKey((int)lparam) <= 40)) || (TranslateKey((int)lparam) == 123))
        {
        }
    }
}

void InitialiseBuffers()
{
    IndicatorSetInteger(INDICATOR_DIGITS, 0);
    SetIndexBuffer(0, BufferPatternDirection, INDICATOR_DATA);
    ArraySetAsSeries(BufferPatternDirection, true);
    SetIndexBuffer(1, BufferPatternDetected, INDICATOR_DATA);
    ArraySetAsSeries(BufferPatternDetected, true);
}

datetime NewCandleTime = TimeCurrent();
bool IsNewCandleCheck()
{
    if (NewCandleTime == iTime(Symbol(), 0, 0)) return false;
    else
    {
        NewCandleTime = iTime(Symbol(), 0, 0);
        return true;
    }
}

void NotifyPattern(string Pattern)
{
    if ((!SendAlert) && (!SendApp) && (!SendEmail)) return;
    string EmailSubject = IndicatorName + " " + Symbol() + " Notification ";
    string EmailBody = AccountCompany() + " - " + AccountName() + " - " + IntegerToString(AccountNumber()) + "\r\n" + IndicatorName + " Notification for " + Symbol() + "\r\n";
    EmailBody += "Detected pattern : " + Pattern;
    string AlertText = Pattern;
    string AppText = AccountCompany() + " - " + AccountName() + " - " + IntegerToString(AccountNumber()) + " - " + IndicatorName + " - " + Symbol() + " - " + Pattern;
    if (SendAlert) Alert(AlertText);
    if (SendEmail)
    {
        if (!SendMail(EmailSubject, EmailBody)) Print("Error sending email " + IntegerToString(GetLastError()));
    }
    if (SendApp)
    {
        if (!SendNotification(AppText)) Print("Error sending notification " + IntegerToString(GetLastError()));
    }
    NotifiedThisCandle = true;
}

void DetectPattern()
{
    int limit = MaxCandle + 1;
    if ((MaxCandle == 0) || (MaxCandle > iBars(Symbol(), Period()) - 2)) limit = iBars(Symbol(), Period()) - 2;
    for (int i = 1; i < limit; i++)
    {
        if ((PreviousDrawn) && (i > 1) && (!IsNewCandle)) continue;
        if (i == MaxCandle) PreviousDrawn = true;
        if (i > 1) NotifiedThisCandle = true;
        string Label = "";
        ENUM_TYPE_OF_PATTERN Type;
        ENUM_CANDLESTICK_PATTERN Pattern = PATTERN_IS_NONE;
        BufferPatternDirection[i] = 0;
        if ((DetectBullishHarami) && (IsBullishHarami(Symbol(), Period(), i)))
        {
            Label = "BULLISH HARAMI";
            Type = BULLISH;
            Pattern = PATTERN_IS_BULLISHHARAMI;
        }
        else if ((DetectBearishHarami) && (IsBearishHarami(Symbol(), Period(), i)))
        {
            Label = "BEARISH HARAMI";
            Type = BEARISH;
            Pattern = PATTERN_IS_BEARISHHARAMI;
        }
        else if ((DetectBullishThreeLineStrike) && (IsBullishThreeLineStrike(Symbol(), Period(), i)))
        {
            Label = "BULLISH THREE-LINE STRIKE";
            Type = BULLISH;
            Pattern = PATTERN_IS_BULLISHTHREELINESTRIKE;
        }
        else if ((DetectBearishThreeLineStrike) && (IsBearishThreeLineStrike(Symbol(), Period(), i)))
        {
            Label = "BEARISH THREE-LINE STRIKE";
            Type = BEARISH;
            Pattern = PATTERN_IS_BEARISHTHREELINESTRIKE;
        }
        else if ((DetectThreeOutsideUp) && (IsThreeOutsideUp(Symbol(), Period(), i)))
        {
            Label = "THREE OUTSIDE UP";
            Type = BULLISH;
            Pattern = PATTERN_IS_THREEOUTSIDEUP;
        }
        else if ((DetectThreeOutsideDown) && (IsThreeOutsideDown(Symbol(), Period(), i)))
        {
            Label = "THREE OUTSIDE DOWN";
            Type = BEARISH;
            Pattern = PATTERN_IS_THREEOUTSIDEDOWN;
        }
        else if ((DetectMorningStar) && (IsMorningStar(Symbol(), Period(), i)))
        {
            Label = "MORNING STAR";
            Type = BULLISH;
            Pattern = PATTERN_IS_MORNINGSTAR;
        }
        else if ((DetectEveningStar) && (IsEveningStar(Symbol(), Period(), i)))
        {
            Label = "EVENING STAR";
            Type = BEARISH;
            Pattern = PATTERN_IS_EVENINGSTAR;
        }
        else if ((DetectThreeInsideUp) && (IsThreeInsideUp(Symbol(), Period(), i)))
        {
            Label = "THREE INSIDE UP";
            Type = BULLISH;
            Pattern = PATTERN_IS_THREEINSIDEUP;
        }
        else if ((DetectThreeInsideDown) && (IsThreeInsideDown(Symbol(), Period(), i)))
        {
            Label = "THREE INSIDE DOWN";
            Type = BEARISH;
            Pattern = PATTERN_IS_THREEINSIDEDOWN;
        }
        else if ((DetectThreeWhiteSoldier) && (IsThreeWhiteSoldiers(Symbol(), Period(), i)))
        {
            Label = "THREE WHITE SOLDIER";
            Type = BULLISH;
            Pattern = PATTERN_IS_THREEWHITESOLDIERS;
        }
        else if ((DetectThreeBlackCrows) && (IsThreeCrows(Symbol(), Period(), i)))
        {
            Label = "THREE BLACK CROWS";
            Type = BEARISH;
            Pattern = PATTERN_IS_THREEBLACKCROWS;
        }
        else if ((DetectEngulfingBull) && (IsBullishEngulfing(Symbol(), Period(), i)))
        {
            Label = "BULLISH ENGULFING";
            Type = BULLISH;
            Pattern = PATTERN_IS_BULLISHENGULFING;
        }
        else if ((DetectEngulfingBear) && (IsBearishEngulfing(Symbol(), Period(), i)))
        {
            Label = "BEARISH ENGULFIG";
            Type = BEARISH;
            Pattern = PATTERN_IS_BEARISHENGULFING;
        }
        else if ((DetectTweezerTop) && (IsTweezerTop(Symbol(), Period(), i)))
        {
            Label = "TWEEZER TOP";
            Type = BEARISH;
            Pattern = PATTERN_IS_TWEEZERTOP;
        }
        else if ((DetectTweezerBottom) && (IsTweezerBottom(Symbol(), Period(), i)))
        {
            Label = "TWEEZER BOTTOM";
            Type = BULLISH;
            Pattern = PATTERN_IS_TWEEZERBOTTOM;
        }
        else if ((DetectInvertedHammer) && (IsInvertedHammer(Symbol(), Period(), i)))
        {
            Label = "INVERTED HAMMER";
            Type = UNCERTAIN;
            Pattern = PATTERN_IS_INVERTEDHAMMER;
        }
        else if ((DetectShootingStar) && (IsShootingStar(Symbol(), Period(), i)))
        {
            Label = "SHOOTING STAR";
            Type = BEARISH;
            Pattern = PATTERN_IS_SHOOTINGSTAR;
        }
        else if ((DetectHammer) && (IsHammer(Symbol(), Period(), i)))
        {
            Label = "HAMMER";
            Type = BULLISH;
            Pattern = PATTERN_IS_HAMMER;
        }
        else if ((DetectHangingMan) && (IsHangingMan(Symbol(), Period(), i)))
        {
            Label = "HANGING MAN";
            Type = UNCERTAIN;
            Pattern = PATTERN_IS_HANGINGMAN;
        }
        else if ((DetectMarubozuUp) && (IsMarubozuUp(Symbol(), Period(), i)))
        {
            Label = "MARUBOZU UP";
            Type = BULLISH;
            Pattern = PATTERN_IS_MARUBOZUUP;
        }
        else if ((DetectMarubozuDown) && (IsMarubozuDown(Symbol(), Period(), i)))
        {
            Label = "MARUBOZU DOWN";
            Type = BEARISH;
            Pattern = PATTERN_IS_MARUBOZUDOWN;
        }
        else if ((DetectSpinningTopBull) && (IsSpinningTopBullish(Symbol(), Period(), i)))
        {
            Label = "SPINNING TOP BULLISH";
            Type = UNCERTAIN;
            Pattern = PATTERN_IS_SPINNINGTOPBULLISH;
        }
        else if ((DetectSpinningTopBear) && (IsSpinningTopBearish(Symbol(), Period(), i)))
        {
            Label = "SPINNING TOP BEARISH";
            Type = UNCERTAIN;
            Pattern = PATTERN_IS_SPINNINGTOPBEARISH;
        }
        else if ((DetectDojiDragonfly) && (IsDojyDragonfly(Symbol(), Period(), i)))
        {
            Label = "DOJI DRAGONFLY";
            Type = UNCERTAIN;
            Pattern = PATTERN_IS_DOJIDRAGONFLY;
        }
        else if ((DetectDojiGravestone) && (IsDojiGravestone(Symbol(), Period(), i)))
        {
            Label = "DOJI GRAVESTONE";
            Type = UNCERTAIN;
            Pattern = PATTERN_IS_DOJIGRAVESTONE;
        }
        else if ((DetectDojiNeutral) && (IsDojiNeutral(Symbol(), Period(), i)))
        {
            Label = "DOJI";
            Type = UNCERTAIN;
            Pattern = PATTERN_IS_DOJI;
        }
        if (Pattern != PATTERN_IS_NONE)
        {
            DrawLabel(i, Label, Type, Pattern);
        }
    }
}

void DrawLabel(int Index, string Label, ENUM_TYPE_OF_PATTERN Type, ENUM_CANDLESTICK_PATTERN Pattern)
{
    if ((Type == BULLISH) && (!DetectBullish)) return;
    if ((Type == BEARISH) && (!DetectBearish)) return;
    if ((Type == UNCERTAIN) && (!DetectUncertain)) return;
    BufferPatternDetected[Index] = Pattern;
    string ArrowName = "";
    color Color = clrNONE;
    int ArrowAnchor = 0;
    datetime CandleTime = iTime(Symbol(), Period(), Index);
    double PriceArrow = 0;
    int ArrowCode = 0;

    if (Type == UNCERTAIN)
    {
        Color = FontColorUncertain;
        ArrowAnchor = ANCHOR_BOTTOM;
        PriceArrow = iHigh(Symbol(), Period(), Index);
        BufferPatternDirection[Index] = 0;
        ArrowCode = 234;
    }
    else if (Type == BULLISH)
    {
        Color = FontColorBullish;
        ArrowAnchor = ANCHOR_TOP;
        PriceArrow = iLow(Symbol(), Period(), Index);
        BufferPatternDirection[Index] = 1;
        ArrowCode = 233;
    }
    else if (Type == BEARISH)
    {
        Color = FontColorBearish;
        ArrowAnchor = ANCHOR_BOTTOM;
        PriceArrow = iHigh(Symbol(), Period(), Index);
        BufferPatternDirection[Index] = -1;
        ArrowCode = 234;
    }

    ArrowName = IndicatorName + "-CANDLE-ARR-" + IntegerToString(CandleTime);
    ObjectCreate(0, ArrowName, OBJ_TEXT, 0, CandleTime, PriceArrow);
    ObjectSetString(0, ArrowName, OBJPROP_TEXT, CharToString(ArrowCode));
    ObjectSetString(0, ArrowName, OBJPROP_FONT, "Wingdings");
    ObjectSetInteger(0, ArrowName, OBJPROP_FONTSIZE, FontSize);
    ObjectSetInteger(0, ArrowName, OBJPROP_ANCHOR, ArrowAnchor);
    ObjectSetInteger(0, ArrowName, OBJPROP_BACK, false);
    ObjectSetInteger(0, ArrowName, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, ArrowName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, ArrowName, OBJPROP_COLOR, Color);

    if ((EnableNotify) && (!NotifiedThisCandle)) NotifyPattern(Label);
}

void CleanChart()
{
    ObjectsDeleteAll(0, IndicatorName);
}

void CleanMiniPanel()
{
    ObjectsDeleteAll(0, IndicatorName + "-P-");
}

void CleanPrevious()
{
    ObjectsDeleteAll(0, IndicatorName + "-CANDLE-");
    PreviousDrawn = false;
    ChartRedraw();
}


string PanelBase = IndicatorName + "-P-BAS";
string PanelLabel = IndicatorName + "-P-LAB";
string PanelDraw = IndicatorName + "-P-DRAW";
string PanelClean = IndicatorName + "-P-CLEAN";
void CreateMiniPanel()
{
    CleanMiniPanel();
    ObjectCreate(0, PanelBase, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, PanelBase, OBJPROP_XDISTANCE, Xoff);
    ObjectSetInteger(0, PanelBase, OBJPROP_YDISTANCE, Yoff);
    ObjectSetInteger(0, PanelBase, OBJPROP_XSIZE, PanelRecX);
    ObjectSetInteger(0, PanelBase, OBJPROP_YSIZE, PanelMovY + 4);
    ObjectSetInteger(0, PanelBase, OBJPROP_BGCOLOR, clrWhite);
    ObjectSetInteger(0, PanelBase, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, PanelBase, OBJPROP_STATE, false);
    ObjectSetInteger(0, PanelBase, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, PanelBase, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, PanelBase, OBJPROP_COLOR, clrBlack);
    ObjectSetInteger(0, PanelBase, OBJPROP_CORNER, ChartCorner);

    int SignY = 1;
    if ((ChartCorner == CORNER_LEFT_LOWER) || (ChartCorner == CORNER_RIGHT_LOWER))
    {
        SignY = -1; // Correction for right-side panel position.
    }
    int SignX = 1;
    if ((ChartCorner == CORNER_RIGHT_UPPER) || (ChartCorner == CORNER_RIGHT_LOWER))
    {
        SignX = -1; // Correction for right-side panel position.
    }
    
    DrawEdit(PanelLabel, Xoff + 2 * SignX, Yoff + 2 * SignY, PanelLabX, PanelLabY, true, int(FontSize * 1.5), "PATTERN DETECTOR", ALIGN_CENTER, "Consolas", "DETECTOR", false, clrNavy, clrKhaki, clrBlack);
    ObjectSetInteger(0, PanelLabel, OBJPROP_CORNER, ChartCorner);
    if (DetectionEnabled)
        DrawEdit(PanelDraw, Xoff + (PanelLabX + 3) * SignX, Yoff + 2 * SignY, PanelMovX, PanelMovX, true, int(FontSize * 1.5), "Detection Enabled - Click To Pause", ALIGN_CENTER, "Wingdings", "J", false, clrNavy, clrKhaki, clrBlack);
    else
        DrawEdit(PanelDraw, Xoff + (PanelLabX + 3) * SignX, Yoff + 2 * SignY, PanelMovX, PanelMovX, true, int(FontSize * 1.5), "Detection Disabled - Click To Start", ALIGN_CENTER, "Wingdings", "K", false, clrNavy, clrKhaki, clrBlack);
    ObjectSetInteger(0, PanelDraw, OBJPROP_CORNER, ChartCorner);
    DrawEdit(PanelClean, Xoff + (PanelLabX + PanelMovX + 1 + 3) * SignX, Yoff + 2 * SignY, PanelMovX, PanelMovX, true, int(FontSize * 1.5), "Click To Clean The Chart", ALIGN_CENTER, "Wingdings", "I", false, clrNavy, clrKhaki, clrBlack);
    ObjectSetInteger(0, PanelClean, OBJPROP_CORNER, ChartCorner);
    ChartRedraw();
}

//+------------------------------------------------------------------+
