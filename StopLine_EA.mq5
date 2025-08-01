//+------------------------------------------------------------------+
//|                                                  StopLine_EA.mq5 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//--- Input parameters for trade levels
input group "Trade Levels (in Points)"
input int InpTakeProfit = 10600;       // Take Profit in points
input int InpStopLoss = 50000;        // Stop Loss in points
input int InpTrailingStop = 0;        // Trailing Stop in points (0 = disabled)
input int InpTrailingStep = 1;        // Trailing Step in points
input int InpStartTrailingPoint = 5001; // Start Trailing Point in points

//--- Input parameter for lot size
input group "Lot Size Management"
input double InpLotSize = 0.0;        // Lot size (0.0 = dynamic calculation)

//--- Pending Order State
enum ENUM_PENDING_ORDER_TYPE
  {
   NONE,
   BUY,
   SELL
  };

ENUM_PENDING_ORDER_TYPE pendingOrderType = NONE;

//--- Object Names
#define HLINE_NAME "StopLine"
#define STATUS_BOX_NAME "StatusBox"

CTrade trade;

//+------------------------------------------------------------------+
//| Delete Objects                                                   |
//+------------------------------------------------------------------+
void DeleteIndicatorObjects()
  {
   ObjectDelete(0, "BuyButton");
   ObjectDelete(0, "SellButton");
   ObjectDelete(0, HLINE_NAME);
   ObjectDelete(0, STATUS_BOX_NAME);
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
//| Create Stop Line                                                 |
//+------------------------------------------------------------------+
void CreateStopLine()
  {
   if(ObjectFind(0, HLINE_NAME) != 0)
     {
      if(!ObjectCreate(0, HLINE_NAME, OBJ_HLINE, 0, 0, 0))
        {
         Print("Error creating stop line: ", GetLastError());
         return;
        }
     }

   ObjectSetInteger(0, HLINE_NAME, OBJPROP_COLOR, clrGray);
   ObjectSetInteger(0, HLINE_NAME, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, HLINE_NAME, OBJPROP_WIDTH, 2);
   ObjectSetDouble(0, HLINE_NAME, OBJPROP_PRICE, 0, SymbolInfoDouble(_Symbol, SYMBOL_ASK));
   ObjectSetInteger(0, HLINE_NAME, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, HLINE_NAME, OBJPROP_SELECTED, false);
  }

//+------------------------------------------------------------------+
//| Create Status Box                                                |
//+------------------------------------------------------------------+
void CreateStatusBox()
  {
   if(ObjectFind(0, STATUS_BOX_NAME) != 0)
     {
      if(!ObjectCreate(0, STATUS_BOX_NAME, OBJ_RECTANGLE_LABEL, 0, 0, 0))
        {
         Print("Error creating status box: ", GetLastError());
         return;
        }
     }

   ObjectSetInteger(0, STATUS_BOX_NAME, OBJPROP_XDISTANCE, 280, 0);
   ObjectSetInteger(0, STATUS_BOX_NAME, OBJPROP_YDISTANCE, 50);
   ObjectSetInteger(0, STATUS_BOX_NAME, OBJPROP_XSIZE, 25);
   ObjectSetInteger(0, STATUS_BOX_NAME, OBJPROP_YSIZE, 25);
   ObjectSetInteger(0, STATUS_BOX_NAME, OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(0, STATUS_BOX_NAME, OBJPROP_BGCOLOR, clrGray);
   ObjectSetInteger(0, STATUS_BOX_NAME, OBJPROP_BORDER_TYPE, BORDER_FLAT);
  }

//+------------------------------------------------------------------+
//| Update UI State                                                  |
//+------------------------------------------------------------------+
void UpdateUIState()
  {
   color newColor = clrGray;
   switch(pendingOrderType)
     {
      case BUY:
         newColor = clrGreen;
         break;
      case SELL:
         newColor = clrRed;
         break;
     }

   ObjectSetInteger(0, HLINE_NAME, OBJPROP_COLOR, newColor);
   ObjectSetInteger(0, STATUS_BOX_NAME, OBJPROP_BGCOLOR, newColor);
   ChartRedraw();
  }


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- clean up existing objects
   DeleteIndicatorObjects();

//--- buttons
   CreateButton("BuyButton", "BUY", 200, 50, 70, 25, clrGreen, clrWhite, CORNER_LEFT_LOWER);
   CreateButton("SellButton", "SELL", 120, 50, 70, 25, clrRed, clrWhite, CORNER_LEFT_LOWER);

//--- stop line and status box
   CreateStopLine();
   CreateStatusBox();

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //--- clean up all objects created by the indicator
   DeleteIndicatorObjects();
   
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
void CheckForTradeExecution()
  {
   if(pendingOrderType == NONE)
      return;

   double linePrice = ObjectGetDouble(0, HLINE_NAME, OBJPROP_PRICE, 0);

   if(pendingOrderType == BUY)
     {
      double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(currentPrice >= linePrice)
        {
         ExecuteTrade(ORDER_TYPE_BUY);
         pendingOrderType = NONE;
         UpdateUIState();
        }
     }
   else if(pendingOrderType == SELL)
     {
      double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(currentPrice <= linePrice)
        {
         ExecuteTrade(ORDER_TYPE_SELL);
         pendingOrderType = NONE;
         UpdateUIState();
        }
     }
  }

void OnTick()
  {
   TrailingStopModifyOrders();
   CheckForTradeExecution();
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
         if(pendingOrderType == BUY)
           {
            pendingOrderType = NONE;
           }
         else
           {
            pendingOrderType = BUY;
           }
         UpdateUIState();
        }
      if(sparam == "SellButton")
        {
         if(pendingOrderType == SELL)
           {
            pendingOrderType = NONE;
           }
         else
           {
            pendingOrderType = SELL;
           }
         UpdateUIState();
        }
     }
  }
//+------------------------------------------------------------------+
