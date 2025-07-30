//+------------------------------------------------------------------+
//|                                                       VAR_EA.mq5 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//--- Input parameters for trade levels
input group "Trade Levels (in Points)"
input int InpTakeProfit = 5000;       // Take Profit in points
input int InpStopLoss = 70000;         // Stop Loss in points
input int InpTrailingStop = 0;       // Trailing Stop in points (0 = disabled)
input int InpTrailingStep = 1;        // Trailing Step in points
input int InpStartTrailingPoint = 5001; // Start Trailing Point in points

//--- Input parameter for lot size
input group "Lot Size Management"
input double InpLotSize = 0.0;        // Lot size (0.0 = dynamic calculation)

//--- pending trade status
enum ENUM_PENDING_TRADE
  {
   PENDING_NONE,
   PENDING_BUY,
   PENDING_SELL
  };

ENUM_PENDING_TRADE pending_trade = PENDING_NONE;

CTrade trade;

//+------------------------------------------------------------------+
//| Delete Objects                                                   |
//+------------------------------------------------------------------+
void DeleteIndicatorObjects()
  {
   ObjectDelete(0, "BuyButton");
   ObjectDelete(0, "SellButton");
   ObjectDelete(0, "PendingStatusBox");
   ObjectDelete(0, "TakeProfitBuy");
   ObjectDelete(0, "TakeProfitSell");
  }

//+------------------------------------------------------------------+
//| Create Button Object                                             |
//+------------------------------------------------------------------+
void CreateButton(string name, string text, int x, int y, int width, int height, color bgColor, color textColor, int corner = 0, int fontSize = 8)
  {
   if(ObjectFind(0, name) != 0)
     {
      if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0))
        {
         Print("Error creating button ", name, ": ", GetLastError());
         return;
        }
     }

   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_STATE, 0);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, 0);
   ObjectSetInteger(0, name, OBJPROP_BACK, 0);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- clean up existing objects
   DeleteIndicatorObjects();

//--- pending status box
   ObjectCreate(0, "PendingStatusBox", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0,"PendingStatusBox",OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(0,"PendingStatusBox",OBJPROP_XDISTANCE,280);
   ObjectSetInteger(0,"PendingStatusBox",OBJPROP_YDISTANCE,50);
   ObjectSetInteger(0,"PendingStatusBox",OBJPROP_XSIZE,15);
   ObjectSetInteger(0,"PendingStatusBox",OBJPROP_YSIZE,15);
   ObjectSetInteger(0,"PendingStatusBox",OBJPROP_BGCOLOR,clrLightGray);
   ObjectSetInteger(0,"PendingStatusBox",OBJPROP_BACK,false);

//--- buttons
   CreateButton("BuyButton", "BUY", 200, 50, 70, 25, clrGreen, clrWhite, CORNER_LEFT_LOWER);
   CreateButton("SellButton", "SELL", 120, 50, 70, 25, clrRed, clrWhite, CORNER_LEFT_LOWER);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //--- clean up all objects created by the indicator
   DeleteIndicatorObjects();
   ObjectDelete(0, "IdentifiedCandleLine");
   ObjectDelete(0, "AskLine");
   
   //--- clear comment
   Comment("");
  }
//+------------------------------------------------------------------+
//| Trailing Stop Logic                                              |
//+------------------------------------------------------------------+
void TrailingStopModifyOrders()
  {
   if(InpTrailingStop <= 0) 
      return;

   for(int i = PositionsTotal() - 1; i >= 0; i--) 
     {
      if(PositionGetSymbol(i) == _Symbol) 
        {
         long positionTicket = PositionGetInteger(POSITION_TICKET);
         ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentSl = PositionGetDouble(POSITION_SL);
         double currentTp = PositionGetDouble(POSITION_TP); 
         double currentPrice = 0;

         if(positionType == POSITION_TYPE_BUY)
           {
            currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            if(currentPrice == 0) 
              {
               continue; 
              }

            if(currentPrice >= openPrice + InpStartTrailingPoint * _Point)
              {
               double proposed_sl = currentPrice - InpTrailingStop * _Point;

               if(proposed_sl > openPrice &&
                  (currentSl == 0 || proposed_sl > currentSl) &&
                  (currentSl == 0 || (proposed_sl - currentSl) >= InpTrailingStep * _Point || InpTrailingStep == 0) ) 
                 {
                  if(trade.PositionModify(positionTicket, proposed_sl, currentTp))
                    {
                     Print("Trailing stop updated for BUY #", positionTicket, " to ", DoubleToString(proposed_sl, _Digits));
                    }
                  else
                    {
                     Print("Error modifying trailing stop for BUY position #", positionTicket, ": ", trade.ResultRetcode(), " (", trade.ResultRetcodeDescription(), ")");
                    }
                 }
              }
           }
         else if(positionType == POSITION_TYPE_SELL)
           {
            currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK); 
            if(currentPrice == 0) 
              { 
               Print("TrailingStopModifyOrders: Could not get ASK price for SELL position #", positionTicket); 
               continue; 
              }

            if(currentPrice <= openPrice - InpStartTrailingPoint * _Point)
              {
               double proposed_sl = currentPrice + InpTrailingStop * _Point;

               if(proposed_sl < openPrice && 
                  (currentSl == 0 || proposed_sl < currentSl) && 
                  (currentSl == 0 || (currentSl - proposed_sl) >= InpTrailingStep * _Point || InpTrailingStep == 0) ) 
                 {
                  if(trade.PositionModify(positionTicket, proposed_sl, currentTp))
                    {
                     Print("Trailing stop updated for SELL position #", positionTicket, " to ", DoubleToString(proposed_sl, _Digits));
                    }
                  else
                    {
                     Print("Error modifying trailing stop for SELL position #", positionTicket, ": ", trade.ResultRetcode(), " (", trade.ResultRetcodeDescription(), ")");
                    }
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    TrailingStopModifyOrders();

    // Draw Take Profit Lines
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    DrawTakeProfitLines(ask, bid);
}
//+------------------------------------------------------------------+
//| Calculate Lot Size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize()
  {
   if(InpLotSize > 0.0)
     {
      double userLotSize = InpLotSize;
      double volumeMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double volumeMax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      double volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

      if(userLotSize < volumeMin) userLotSize = volumeMin;
      if(userLotSize > volumeMax) userLotSize = volumeMax;
      
      userLotSize = MathFloor(userLotSize / volumeStep) * volumeStep;
      if (userLotSize < volumeMin) userLotSize = volumeMin; 

      return(NormalizeDouble(userLotSize, 2)); 
     }

   double calculatedLotSize = AccountInfoDouble(ACCOUNT_BALANCE) / 1000.0;

   double volumeMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double volumeMax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(calculatedLotSize < volumeMin)
     {
      calculatedLotSize = volumeMin;
     }
   else if(calculatedLotSize > volumeMax)
     {
      calculatedLotSize = volumeMax;
     }
   else
     {
      calculatedLotSize = MathRound(calculatedLotSize / volumeStep) * volumeStep;
      if(calculatedLotSize < volumeMin) calculatedLotSize = volumeMin;
      if(calculatedLotSize > volumeMax) calculatedLotSize = volumeMax;
     }
   
   return(NormalizeDouble(calculatedLotSize, 2));
  }

//+------------------------------------------------------------------+
//| Execute Trade Operation                                          |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_ORDER_TYPE orderType)
  {
   double lot = CalculateLotSize();
   if(lot <= 0)
     {
      Print("ExecuteTrade: Invalid lot size calculated: ", lot);
      return;
     }
   double currentPrice = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double slPrice = 0.0;
   double tpPrice = 0.0;
   if(orderType == ORDER_TYPE_BUY)
     {
      slPrice = (InpStopLoss > 0) ? currentPrice - InpStopLoss * _Point : 0.0;
      tpPrice = (InpTakeProfit > 0) ? currentPrice + InpTakeProfit * _Point : 0.0;
      trade.Buy(lot, _Symbol, currentPrice, slPrice, tpPrice);
     }
   else if(orderType == ORDER_TYPE_SELL)
     {
      slPrice = (InpStopLoss > 0) ? currentPrice + InpStopLoss * _Point : 0.0;
      tpPrice = (InpTakeProfit > 0) ? currentPrice - InpTakeProfit * _Point : 0.0;
      trade.Sell(lot, _Symbol, currentPrice, slPrice, tpPrice);
     }
   pending_trade = PENDING_NONE;
   ObjectSetInteger(0, "PendingStatusBox", OBJPROP_BGCOLOR, clrLightGray);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//--- check if the event is a click on a graphical object
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam == "BuyButton")
        {
         if(pending_trade == PENDING_BUY)
           {
            pending_trade = PENDING_NONE;
            ObjectSetInteger(0, "PendingStatusBox", OBJPROP_BGCOLOR, clrLightGray);
           }
         else
           {
            ExecuteTrade(ORDER_TYPE_BUY);
           }
        }
      if(sparam == "SellButton")
        {
         if(pending_trade == PENDING_SELL)
           {
            pending_trade = PENDING_NONE;
            ObjectSetInteger(0, "PendingStatusBox", OBJPROP_BGCOLOR, clrLightGray);
           }
         else
           {
            ExecuteTrade(ORDER_TYPE_SELL);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Draw Take Profit Lines                                           |
//+------------------------------------------------------------------+
void DrawTakeProfitLines(double ask, double bid)
{
    if (InpTakeProfit <= 0)
    {
        ObjectDelete(0, "TakeProfitBuy");
        ObjectDelete(0, "TakeProfitSell");
        ObjectDelete(0, "AskLine");
        return;
    }

    // Calculate Take Profit levels
    double tp_buy_level = ask + InpTakeProfit * _Point;
    double tp_sell_level = bid - InpTakeProfit * _Point;

    // Line names
    string buy_line_name = "TakeProfitBuy";
    string sell_line_name = "TakeProfitSell";
    string ask_line_name = "AskLine";

    // Get start time at current bar (shift 0)
    datetime start_time = iTime(_Symbol, _Period, 0);

    // TP lines: Get end time 3 bars ahead
    int bars_total = Bars(_Symbol, _Period);
    datetime end_time_tp;
    if (bars_total >= 4)
        end_time_tp = iTime(_Symbol, _Period, 0) + (iTime(_Symbol, _Period, 0) - iTime(_Symbol, _Period, 1)) * 3;
    else
        end_time_tp = TimeCurrent() + 3 * PeriodSeconds();  // fallback

    // Ask line: Shorter span (e.g., 1 bar ahead)
    datetime end_time_ask;
    if (bars_total >= 2)
        end_time_ask = iTime(_Symbol, _Period, 0) + (iTime(_Symbol, _Period, 0) - iTime(_Symbol, _Period, 1));
    else
        end_time_ask = TimeCurrent() + PeriodSeconds();  // fallback

    // Draw Buy TP Line
    if (ObjectFind(0, buy_line_name) < 0)
    {
        ObjectCreate(0, buy_line_name, OBJ_TREND, 0, start_time, tp_buy_level, end_time_tp, tp_buy_level);
        ObjectSetInteger(0, buy_line_name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, buy_line_name, OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(0, buy_line_name, OBJPROP_RAY_RIGHT, false);
        ObjectSetInteger(0, buy_line_name, OBJPROP_SELECTABLE, false);
    }
    else
    {
        ObjectMove(0, buy_line_name, 0, start_time, tp_buy_level);
        ObjectMove(0, buy_line_name, 1, end_time_tp, tp_buy_level);
    }
    ObjectSetInteger(0, buy_line_name, OBJPROP_COLOR, clrGreen);

    // Draw Sell TP Line
    if (ObjectFind(0, sell_line_name) < 0)
    {
        ObjectCreate(0, sell_line_name, OBJ_TREND, 0, start_time, tp_sell_level, end_time_tp, tp_sell_level);
        ObjectSetInteger(0, sell_line_name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, sell_line_name, OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(0, sell_line_name, OBJPROP_RAY_RIGHT, false);
        ObjectSetInteger(0, sell_line_name, OBJPROP_SELECTABLE, false);
    }
    else
    {
        ObjectMove(0, sell_line_name, 0, start_time, tp_sell_level);
        ObjectMove(0, sell_line_name, 1, end_time_tp, tp_sell_level);
    }
    ObjectSetInteger(0, sell_line_name, OBJPROP_COLOR, clrRed);

    // Draw Ask Line (shorter length)
    if (ObjectFind(0, ask_line_name) < 0)
    {
        ObjectCreate(0, ask_line_name, OBJ_TREND, 0, start_time, ask, end_time_ask, ask);
        ObjectSetInteger(0, ask_line_name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, ask_line_name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, ask_line_name, OBJPROP_RAY_RIGHT, false);
        ObjectSetInteger(0, ask_line_name, OBJPROP_SELECTABLE, false);
    }
    else
    {
        ObjectMove(0, ask_line_name, 0, start_time, ask);
        ObjectMove(0, ask_line_name, 1, end_time_ask, ask);
    }
    ObjectSetInteger(0, ask_line_name, OBJPROP_COLOR, clrBlue);
}
//+------------------------------------------------------------------+
