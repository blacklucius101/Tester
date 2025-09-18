//+------------------------------------------------------------------+
//|                                               KeyboardTrader.mq5 |
//|                        Copyright 2022, MetaQuotes Ltd.           |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

CTrade trade;  // Trade object
input int magicNumber = 123456; // Magic number for identifying orders

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  // Set the magic number for trading operations
  trade.SetExpertMagicNumber(magicNumber);

  // Initialization of the Expert Advisor
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  // Cleanup on deinitialization
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  // Main logic for tick data; not needed for this script
}

//+------------------------------------------------------------------+
//| Chart event function                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
  if (id == CHARTEVENT_KEYDOWN)
  {
    char key = (char)lparam;  // Convert the keycode from long to char
    switch(key)
    {
      case '1':
        // Buy order with default parameters
        trade.Buy(0.1, _Symbol, 0, 0, 0, "Buy Order");
        break;

      case '2':
        // Sell order with default parameters
        trade.Sell(0.1, _Symbol, 0, 0, 0, "Sell Order");
        break;

      case '3':
        // Close all positions
        CloseAllPositions();
        break;
    }
  }
}

//+------------------------------------------------------------------+
//| Function to close all positions                                  |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
  for (int i = PositionsTotal() - 1; i >= 0; i--)
  {
    ulong ticket = PositionGetTicket(i);
    if (PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == magicNumber)
    {
      trade.PositionClose(ticket);
    }
  }
}
