//------------------------------------------------------------------
#property copyright   "© mladen, 2018"
#property link        "mladenfx@gmail.com"
#property description "Ergodic True Strength Index (William Blau)"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2
#property indicator_label1  "TSI"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrDeepSkyBlue,clrSandyBrown
#property indicator_width1  2
#property indicator_label2  "TSI signal line"
#property indicator_type2   DRAW_LINE
#property indicator_color3  clrDarkGray
#property indicator_style2  STYLE_DOT

//
//--- input parameters
//

enum enColorOn
{
   col_onSignalCross, // Change color on signal line cross
   col_onZeroCross,   // Change color on zero line cross
   col_onSlopeChange  // Change color TSI slope change
};
input int                inpPeriod1      = 25;                // TSI smoothing period ("s" period)
input int                inpPeriod2      = 13;                // TSI momentum smoothing period  ("r" period)
input int                inpSignalPeriod = 5;                 // Signal period
input ENUM_APPLIED_PRICE inpPrice        = PRICE_CLOSE;       // Price
input enColorOn          inpColorOn      = col_onSignalCross; // Color change type
input bool               AlertEnabled    = true;              // Enable pop-up alert and sound

//--- Buffers and global variables
double val[], valc[], signal[], prices[];
double _signalAlpha;  
int lastAlertedColor = -1;
datetime lastAlertTime = 0;

//------------------------------------------------------------------
// Custom indicator initialization function
//------------------------------------------------------------------
int OnInit()
{
   //--- Indicator buffers mapping
   SetIndexBuffer(0, val, INDICATOR_DATA);
   SetIndexBuffer(1, valc, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, signal, INDICATOR_DATA);
   SetIndexBuffer(3, prices, INDICATOR_CALCULATIONS);
   
   _signalAlpha = 2.0 / (1.0 + (inpSignalPeriod > 1 ? inpSignalPeriod : 1));

   //--- Indicator name
   IndicatorSetString(INDICATOR_SHORTNAME, 
      (inpPeriod1 == 5 || inpPeriod2 == 5 ? "Ergodic t" : "T") +
      "rue strength index (" + IntegerToString(inpPeriod1) + "," + 
      IntegerToString(inpPeriod2) + "," + IntegerToString(inpSignalPeriod) + ")");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
}

//------------------------------------------------------------------
// Custom indicator iteration function
//------------------------------------------------------------------
#define _setPrice(_priceType, _where, _index) { \
   switch (_priceType) \
   { \
      case PRICE_CLOSE:    _where = close[_index]; break; \
      case PRICE_OPEN:     _where = open[_index]; break; \
      case PRICE_HIGH:     _where = high[_index]; break; \
      case PRICE_LOW:      _where = low[_index]; break; \
      case PRICE_MEDIAN:   _where = (high[_index] + low[_index]) / 2.0; break; \
      case PRICE_TYPICAL:  _where = (high[_index] + low[_index] + close[_index]) / 3.0; break; \
      case PRICE_WEIGHTED: _where = (high[_index] + low[_index] + close[_index] + close[_index]) / 4.0; break; \
      default: _where = 0; \
   }}

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
   int i = (prev_calculated > 0 ? prev_calculated - 1 : 0);
   for (; i < rates_total && !_StopFlag; i++)
   {
      _setPrice(inpPrice, prices[i], i);
      // Calculate TSI value scaled to 100
      val[i] = 100 * iTsi((i > 0 ? prices[i] - prices[i - 1] : 0), inpPeriod2, inpPeriod1, i);
      // Signal line: EMA on TSI
      signal[i] = (i > 0) ? signal[i - 1] + _signalAlpha * (val[i] - signal[i - 1]) : val[i];

      // Determine the color index based on chosen method
      switch (inpColorOn)
      {
         case col_onSignalCross:
            valc[i] = (val[i] > signal[i]) ? 1 : (val[i] < signal[i]) ? 2 : (i > 0) ? valc[i - 1] : 0;
            break;
         case col_onSlopeChange:
            valc[i] = (i > 0) ? (val[i] > val[i - 1]) ? 1 : (val[i] < val[i - 1]) ? 2 : valc[i - 1] : 0;
            break;
         default:
            valc[i] = (val[i] > 0) ? 1 : (val[i] < 0) ? 2 : (i > 0) ? valc[i - 1] : 0;
            break;
      }

      //--- Optimized Alert System
      if (AlertEnabled && i == rates_total - 1 && valc[i] != lastAlertedColor && time[i] > lastAlertTime)
      {
         lastAlertedColor = (int)valc[i];
         lastAlertTime = time[i];

         string msg = "TSI color changed: " + (valc[i] == 1 ? "Bullish" : (valc[i] == 2 ? "Bearish" : "Neutral"));
         Alert(msg);           
         PlaySound("alert.wav");
      }
   }
   return i;
}

//------------------------------------------------------------------
// Custom function(s)
//------------------------------------------------------------------

double iTsi(double value, double period1, double period2, int i, int _instance = 0)
{
   #define _functionArrayRingSize 6
   static double _workArray[_functionArrayRingSize][4];

   int    _indC = (i) % _functionArrayRingSize;
   int    _indP = (i - 1) % _functionArrayRingSize;
   double valua = fabs(value);

   if (i > 0 && period1 > 1)
   {  
      _workArray[_indC][0] = _workArray[_indP][0] + (2.0 / (1.0 + period1)) * (value - _workArray[_indP][0]);
      _workArray[_indC][2] = _workArray[_indP][2] + (2.0 / (1.0 + period1)) * (valua - _workArray[_indP][2]);
   }            
   else  
   {  
      _workArray[_indC][0] = _workArray[_indC][2] = value; 
   }

   if (i > 0 && period2 > 1)
   {  
      _workArray[_indC][1] = _workArray[_indP][1] + (2.0 / (1.0 + period2)) * (_workArray[_indC][0] - _workArray[_indP][1]);
      _workArray[_indC][3] = _workArray[_indP][3] + (2.0 / (1.0 + period2)) * (_workArray[_indC][2] - _workArray[_indP][3]);
   }            
   else  
   {  
      _workArray[_indC][1] = _workArray[_indC][3] = value; 
   }
   return (_workArray[_indC][3] != 0 ? _workArray[_indC][1] / _workArray[_indC][3] : 0);
}
