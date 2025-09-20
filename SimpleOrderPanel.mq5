//+------------------------------------------------------------------+
//|                                             SimpleOrderPanel.mq5 |
//|                    Copyright 2022, Manuel Alejandro Cercós Pérez |
//|                         https://www.mql5.com/en/users/alexcercos |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Manuel Alejandro Cercós Pérez"
#property link      "https://www.mql5.com/en/users/alexcercos"
#property version   "3.0"

input group "=== TRADING ===";
input int      TakeProfit = 50;
input int      StopLoss = 50;
input int      TP_Step = 1;
input int      SL_Step = 1;
input int      Slippage = 3;

input group "=== DASHBOARD ===";
input double UIScale = 1.0;  // User adjustable scale factor
input int      DashX = 30;
input int      DashY = 30;
input int      ButtonSize = 90;

#define SX(v) (int)(v * UIScale)
#define SY(v) (int)(v * UIScale)

input group "=== KEYBOARD HOTKEYS ===";
input bool     EnableHotkeys = true;
input string   BuyKey = "1";
input string   SellKey = "3"; 
input string   CloseKey = "2";

input group "=== RISK ===";
input int      MaxPositions = 1;

// --- TP/SL UI ---
enum SLTP_MODE {
    MODE_POINTS,
    MODE_CURRENCY
};

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Label.mqh>

#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\Trade.mqh>

SLTP_MODE tpMode = MODE_POINTS;
SLTP_MODE slMode = MODE_POINTS;

double currentTakeProfit;
double currentStopLoss;

string tpDownBtn, tpUpBtn, tpModeBtn, tpLabel;
string slDownBtn, slUpBtn, slModeBtn, slLabel;

CTrade trade;
CPositionInfo position;

string prefix = "FutureDash_";
double dailyPL = 0;
datetime resetTime;

string buyBtnName = prefix + "BUY";
string sellBtnName = prefix + "SELL";
string closeBtnName = prefix + "CLOSE";
string posLblName = prefix + "POS";
string plLblName = prefix + "PL";
string spreadLblName = prefix + "SPREAD";
string statusLblName = prefix + "STATUS";
string mainPanelName = prefix + "PANEL";
string glowPanelName = prefix + "GLOW";
string lotLblName = prefix + "LOT";

#define POS_TOTAL PositionsTotal()
#define ORD_TOTAL OrdersTotal()
#define ASK_PRICE SymbolInfoDouble(_Symbol, SYMBOL_ASK)
#define BID_PRICE SymbolInfoDouble(_Symbol, SYMBOL_BID)

#define POS_SELECT_BY_INDEX(i) if (!m_position.SelectByIndex(i)) continue;
#define POS_SYMBOL m_position.Symbol()
#define POS_MAGIC m_position.Magic()
#define POS_TYPE m_position.PositionType()
#define POS_OPEN m_position.PriceOpen()
#define POS_STOP m_position.StopLoss()
#define POS_TAKE_PROFIT m_position.TakeProfit()
#define POS_TICKET m_position.Ticket()

#define ORD_SELECT_BY_INDEX(i) if (!m_order.SelectByIndex(i)) continue;
#define ORD_SYMBOL m_order.Symbol()
#define ORD_MAGIC m_order.Magic()
#define ORD_TYPE m_order.OrderType()
#define ORD_OPEN m_order.PriceOpen()
#define ORD_STOP m_order.StopLoss()
#define ORD_TAKE_PROFIT m_order.TakeProfit()
#define ORD_TICKET m_order.Ticket()

#define POS_MODIFY(ticket, stop, take) if(!trade.PositionModify(ticket, stop, take)) Print("Error modyfing position: ",GetLastError());
#define POS_CLOSE(ticket) if(!trade.PositionClose(ticket)) Print("Error closing position, ",GetLastError());

#define ORD_DELETE(ticket) if (!trade.OrderDelete(ticket)) Print("Error deleting order, ",GetLastError());
#define ORD_MODIFY(ticket, stop, take) if (!trade.OrderModify(ticket, ORD_OPEN, stop, take, ORDER_TIME_GTC, 0)) Print("Error modyfing order: ",GetLastError());

double GetLotSize()
{
   double lot = AccountInfoDouble(ACCOUNT_BALANCE) / 1000.0;
   // Ensure lot respects broker min/max requirements
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lot = MathFloor(lot / lotStep) * lotStep; // round to step
   lot = MathMax(minLot, MathMin(maxLot, lot)); // clamp to min/max

   return lot;
}

//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
//--- indents and gaps
#define INDENT_LEFT                         (11)      // indent from left (with allowance for border width)
#define INDENT_TOP                          (11)      // indent from top (with allowance for border width)
#define INDENT_RIGHT                        (11)      // indent from right (with allowance for border width)
#define INDENT_BOTTOM                       (11)      // indent from bottom (with allowance for border width)
#define CONTROLS_GAP_X                      (10)      // gap by X coordinate
#define CONTROLS_GAP_Y                      (10)      // gap by Y coordinate
//--- for buttons
#define BUTTON_WIDTH                        (100)     // size by X coordinate
#define BUTTON_HEIGHT                       (25)      // size by Y coordinate

#define GVAR_POSITION_X		"SimplePanel_positionX"
#define GVAR_POSITION_Y		"SimplePanel_positionY"

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "Trade Settings"
input int expertDeviation = 20; // Maximum slippage
input int expertMagic = 450913; // Expert Magic number

input group "Other settings"
input int fontSize = 10; //Font size

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CControlsDialog : public CAppDialog
{
private:
   CButton           m_buy_button, m_sell_button, m_close_button;
   
   // --- TP/SL UI Elements ---
   CLabel            m_tp_label, m_sl_label;
   CButton           m_tp_down_button, m_tp_up_button, m_tp_mode_button;
   CButton           m_sl_down_button, m_sl_up_button, m_sl_mode_button;

   // --- Stats Labels ---
   CLabel            m_pos_label, m_spread_label, m_pl_label, m_status_label, m_lot_label, m_hotkey_label;

public:
   //--- create
   virtual bool      Create(const string name);
   //--- chart event handler
   virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
   
   //--- Update functions
   void              UpdateTPDisplay(void);
   void              UpdateSLDisplay(void);
   void              UpdateDashboard(void);
   void              FlashButton(string btnName);
   void              SetStatus(string text, color clr);

protected:
   //--- create dependent controls
   bool              CreateButton(CButton &button, string name, int x1, int y1, int x2, int y2, string text, color clr_back=clrDarkCyan, color clr_border=clrBlack, int font_size = 10);
   bool              CreateEdit(CEdit &edit, string name, string editText, int x1, int y1, int x2, int y2);
   bool              CreateLabel(CLabel &label, string name, int x1, int y1, string text, int font_size = 10, color clr = clrWhite);
   
   //--- handlers of the dependent controls events
   void              OnClickBuyButton(void);
   void              OnClickSellButton(void);
   void              OnClickCloseButton(void);
   
   void              OnClickTPUp(void);
   void              OnClickTPDown(void);
   void              OnClickTPMode(void);
   void              OnClickSLUp(void);
   void              OnClickSLDown(void);
   void              OnClickSLMode(void);
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CControlsDialog)
   ON_EVENT(ON_CLICK, m_buy_button, OnClickBuyButton)
   ON_EVENT(ON_CLICK, m_sell_button, OnClickSellButton)
   ON_EVENT(ON_CLICK, m_close_button, OnClickCloseButton)
   
   ON_EVENT(ON_CLICK, m_tp_up_button, OnClickTPUp)
   ON_EVENT(ON_CLICK, m_tp_down_button, OnClickTPDown)
   ON_EVENT(ON_CLICK, m_tp_mode_button, OnClickTPMode)
   
   ON_EVENT(ON_CLICK, m_sl_up_button, OnClickSLUp)
   ON_EVENT(ON_CLICK, m_sl_down_button, OnClickSLDown)
   ON_EVENT(ON_CLICK, m_sl_mode_button, OnClickSLMode)
EVENT_MAP_END(CAppDialog)

void CControlsDialog::OnClickTPUp(void) { currentTakeProfit += TP_Step; UpdateTPDisplay(); }
void CControlsDialog::OnClickTPDown(void) { currentTakeProfit = MathMax(0, currentTakeProfit - TP_Step); UpdateTPDisplay(); }
void CControlsDialog::OnClickTPMode(void) { tpMode = (tpMode == MODE_POINTS) ? MODE_CURRENCY : MODE_POINTS; UpdateTPDisplay(); }
void CControlsDialog::OnClickSLUp(void) { currentStopLoss += SL_Step; UpdateSLDisplay(); }
void CControlsDialog::OnClickSLDown(void) { currentStopLoss = MathMax(0, currentStopLoss - SL_Step); UpdateSLDisplay(); }
void CControlsDialog::OnClickSLMode(void) { slMode = (slMode == MODE_POINTS) ? MODE_CURRENCY : MODE_POINTS; UpdateSLDisplay(); }

void CControlsDialog::UpdateTPDisplay()
{
    string currencySymbol = AccountInfoString(ACCOUNT_CURRENCY);
    string mode = (tpMode == MODE_POINTS) ? "points" : currencySymbol;
    string value = (tpMode == MODE_POINTS) ? IntegerToString((int)currentTakeProfit) : DoubleToString(currentTakeProfit, 2);
    m_tp_label.Text("TP: " + value + " " + mode);
    m_tp_mode_button.Text((tpMode == MODE_POINTS) ? "P" : currencySymbol);
}

void CControlsDialog::UpdateSLDisplay()
{
    string currencySymbol = AccountInfoString(ACCOUNT_CURRENCY);
    string mode = (slMode == MODE_POINTS) ? "points" : currencySymbol;
    string value = (slMode == MODE_POINTS) ? IntegerToString((int)currentStopLoss) : DoubleToString(currentStopLoss, 2);
    m_sl_label.Text("SL: " + value + " " + mode);
    m_sl_mode_button.Text((slMode == MODE_POINTS) ? "P" : currencySymbol);
}

void CControlsDialog::UpdateDashboard()
{
    int positions = 0;
    double totalPL = 0;
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i) && position.Symbol() == _Symbol)
        {
            positions++;
            totalPL += position.Profit();
        }
    }
    
    double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
    
    m_pos_label.Text(StringFormat("POSITIONS: %d", positions));
    m_pos_label.Color(positions > 0 ? C'255,215,0' : C'0,255,255');
    
    m_spread_label.Text(StringFormat("SPREAD: %.1f", spread));
    color spreadColor = spread <= 2.0 ? C'50,205,50' : (spread <= 5.0 ? C'255,215,0' : C'255,69,0');
    m_spread_label.Color(spreadColor);
    
    dailyPL = GetDailyPL();
    m_pl_label.Text(StringFormat("DAILY P&L: $%.2f", dailyPL));
    m_pl_label.Color(dailyPL >= 0 ? C'50,205,50' : C'255,69,0');
    
    string status = "READY";
    color statusColor = C'0,191,255';
    
    if(positions > 0)
    {
        if(totalPL > 0)
        {
            status = "IN PROFIT";
            statusColor = C'50,205,50';
        }
        else if(totalPL < 0)
        {
            status = "IN LOSS";
            statusColor = C'255,69,0';
        }
        else
        {
            status = "BREAKEVEN";
            statusColor = C'255,215,0';
        }
    }
    
    m_status_label.Text(StringFormat("STATUS: %s", status));
    m_status_label.Color(statusColor);
    m_lot_label.Text(StringFormat("LOT SIZE: %.2f", GetLotSize()));
}

void UpdateDashboard()
{
    ExtDialog.UpdateDashboard();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::Create(const string name)
{
   int x = SX(DashX);
   int y = SY(DashY);
   int btnW = SX(ButtonSize);
   int btnH = SY(40);
   int gap = SX(5);
   int panelW = (btnW * 3) + (gap * 2) + SX(20);
   int panelH = SY(280);

   if(!CAppDialog::Create(0, name, 0, x, y, x + panelW, y + panelH))
      return(false);
   
   CAppDialog::ColorBackground(C'25,25,45');
   CAppDialog::ColorBorder(C'100,149,237');

   int btnY = INDENT_TOP;
   int btnX = INDENT_LEFT;
   
   if(!CreateButton(m_buy_button, buyBtnName, btnX, btnY, btnX + btnW, btnY + btnH, "▲ BUY", C'34,139,34', C'0,255,0', (int)(14 * UIScale)))
      return(false);
   btnX += btnW + gap;
   if(!CreateButton(m_sell_button, sellBtnName, btnX, btnY, btnX + btnW, btnY + btnH, "▼ SELL", C'220,20,60', C'255,0,100', (int)(14 * UIScale)))
      return(false);
   btnX += btnW + gap;
   if(!CreateButton(m_close_button, closeBtnName, btnX, btnY, btnX + btnW, btnY + btnH, "✕ CLOSE", C'255,140,0', C'255,165,0', (int)(14 * UIScale)))
      return(false);

   // --- TP/SL UI Elements ---
   int controlsY = btnY + btnH + SY(15);
   int smallBtnW = SX(30);
   int smallBtnH = SY(20);
    
   // Take Profit controls
   int tpY = controlsY + SY(15);
   if(!CreateLabel(m_tp_label, tpLabel, INDENT_LEFT, tpY, "TP:", (int)(12 * UIScale), C'0,255,255')) return(false);
   int controlsX = panelW - INDENT_RIGHT - smallBtnW;
   if(!CreateButton(m_tp_mode_button, tpModeBtn, controlsX, tpY - SY(5), controlsX + SX(40), tpY - SY(5) + smallBtnH, "P", C'70,130,180', C'100,149,237', (int)(10 * UIScale))) return(false);
   controlsX -= (smallBtnW + gap);
   if(!CreateButton(m_tp_up_button, tpUpBtn, controlsX, tpY - SY(5), controlsX + smallBtnW, tpY - SY(5) + smallBtnH, "+", C'34,139,34', C'0,255,0', (int)(10 * UIScale))) return(false);
   controlsX -= (smallBtnW + gap);
   if(!CreateButton(m_tp_down_button, tpDownBtn, controlsX, tpY - SY(5), controlsX + smallBtnW, tpY - SY(5) + smallBtnH, "-", C'220,20,60', C'255,0,100', (int)(10 * UIScale))) return(false);

   // Stop Loss controls
   int slY = controlsY + SY(45);
   if(!CreateLabel(m_sl_label, slLabel, INDENT_LEFT, slY, "SL:", (int)(12 * UIScale), C'0,255,255')) return(false);
   controlsX = panelW - INDENT_RIGHT - smallBtnW;
   if(!CreateButton(m_sl_mode_button, slModeBtn, controlsX, slY - SY(5), controlsX + SX(40), slY - SY(5) + smallBtnH, "P", C'70,130,180', C'100,149,237', (int)(10 * UIScale))) return(false);
   controlsX -= (smallBtnW + gap);
   if(!CreateButton(m_sl_up_button, slUpBtn, controlsX, slY - SY(5), controlsX + smallBtnW, slY - SY(5) + smallBtnH, "+", C'34,139,34', C'0,255,0', (int)(10 * UIScale))) return(false);
   controlsX -= (smallBtnW + gap);
   if(!CreateButton(m_sl_down_button, slDownBtn, controlsX, slY - SY(5), controlsX + smallBtnW, slY - SY(5) + smallBtnH, "-", C'220,20,60', C'255,0,100', (int)(10 * UIScale))) return(false);

   // --- Stats Labels ---
   int statsY = slY + SY(35);
   if(!CreateLabel(m_pos_label, posLblName, INDENT_LEFT, statsY, "POSITIONS: 0", (int)(10 * UIScale), C'0,255,255')) return(false);
   if(!CreateLabel(m_spread_label, spreadLblName, INDENT_LEFT, statsY + SY(20), "SPREAD: 0.0", (int)(10 * UIScale), C'255,215,0')) return(false);
   if(!CreateLabel(m_pl_label, plLblName, INDENT_LEFT, statsY + SY(40), "DAILY P&L: $0.00", (int)(10 * UIScale), C'50,205,50')) return(false);
   if(!CreateLabel(m_status_label, statusLblName, INDENT_LEFT, statsY + SY(60), "STATUS: READY", (int)(10 * UIScale), C'0,191,255')) return(false);
   if(!CreateLabel(m_lot_label, lotLblName, INDENT_LEFT, statsY + SY(80), "LOT SIZE: 0.00", (int)(10 * UIScale), C'176,196,222')) return(false);

   // --- Hotkey Label ---
    if(EnableHotkeys)
    {
        string hotkeys = "NUMPAD: [1] BUY  [3] SELL  [2] CLOSE";
        if(!CreateLabel(m_hotkey_label, prefix + "HOTKEYS", INDENT_LEFT, statsY + SY(110), hotkeys, (int)(8 * UIScale), C'176,196,222')) return(false);
    }
   
   UpdateTPDisplay();
   UpdateSLDisplay();

   return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateButton(CButton &button, string name, int x1, int y1, int x2, int y2, string text, color clr_back=clrDarkCyan, color clr_border=clrBlack, int font_size = 10)
{
//--- create
   if(!button.Create(m_chart_id, m_name+name, m_subwin, x1, y1, x2, y2))
      return(false);
   if(!button.Text(text))
      return(false);
   if (!button.FontSize(font_size))
      return(false);
   button.ColorBorder(clr_border);
   button.Color(clrWhite);
   button.ColorBackground(clr_back);
   button.Font("Arial Bold");

   if(!Add(button))
      return(false);
//--- succeed
   return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateEdit(CEdit &edit, string name, string editText, int x1, int y1, int x2, int y2)
{
//--- create
   if(!edit.Create(m_chart_id,m_name+name,m_subwin,x1,y1,x2,y2))
      return(false);

   if(!edit.ReadOnly(false))
      return(false);

   if(!edit.Text(editText))
      return(false);
   if (!edit.FontSize(fontSize))
      return(false);
   if(!edit.TextAlign(ALIGN_CENTER))
      return(false);
   if(!Add(edit))
      return(false);
//--- succeed
   return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateLabel(CLabel &label, string name, int x1, int y1, string text, int font_size = 10, color clr = clrWhite)
{
//--- create
   if(!label.Create(m_chart_id, m_name+name, m_subwin, x1, y1, 0, 0))
      return(false);
   if(!label.Text(text))
      return(false);
   if (!label.FontSize(font_size))
      return(false);
   label.Color(clr);
   label.Font("Arial");
   if(!Add(label))
      return(false);
//--- succeed
   return(true);
}

#define PENDING_SETLINE "SOP_setline"

//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::SetStatus(string text, color clr)
{
    m_status_label.Text("STATUS: " + text);
    m_status_label.Color(clr);
}

bool CanTrade()
{
    int pos = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i) && position.Symbol() == _Symbol)
            pos++;
    }
    
    if(pos >= MaxPositions)
    {
        ExtDialog.SetStatus("MAX POSITIONS", C'255,215,0');
        return false;
    }
    
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
    {
        ExtDialog.SetStatus("ENABLE AUTO TRADING", C'255,69,0');
        return false;
    }
    
    if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
    {
        ExtDialog.SetStatus("ALLOW DLL IMPORTS", C'255,69,0');
        return false;
    }
    
    return true;
}

void ExecuteBuy()
{
    if(!CanTrade()) 
    {
        Print("Cannot trade - Max positions reached or other restriction");
        return;
    }
    
    double lot = GetLotSize();
    double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl = 0, tp = 0;
    
    double sl_points = 0;
    if(slMode == MODE_POINTS)
    {
        sl_points = currentStopLoss;
    }
    else // MODE_CURRENCY
    {
        double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        if(tick_value > 0 && tick_size > 0 && lot > 0)
        {
            double one_point_value = (tick_value / tick_size) * _Point * lot;
            sl_points = currentStopLoss / one_point_value;
        }
    }

    double tp_points = 0;
    if(tpMode == MODE_POINTS)
    {
        tp_points = currentTakeProfit;
    }
    else // MODE_CURRENCY
    {
        double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        if(tick_value > 0 && tick_size > 0 && lot > 0)
        {
            double one_point_value = (tick_value / tick_size) * _Point * lot;
            tp_points = currentTakeProfit / one_point_value;
        }
    }

    if(sl_points > 0)
        sl = price - sl_points * _Point;
    
    if(tp_points > 0)
        tp = price + tp_points * _Point;
    
    Print("Attempting BUY: Price=", price, " SL=", sl, " TP=", tp, " Lot=", lot);
    
    if(trade.Buy(lot, _Symbol, price, sl, tp, "Dashboard BUY"))
    {
        ExtDialog.SetStatus("BUY EXECUTED", C'50,205,50');
        PlaySound("alert2.wav");
    }
    else
    {
        Print("Error code: ", trade.ResultRetcode());
        ExtDialog.SetStatus("BUY FAILED", C'255,69,0');
    }
}

void ExecuteSell()
{
    if(!CanTrade()) 
    {
        Print("Cannot trade - Max positions reached or other restriction");
        return;
    }
    
    double lot = GetLotSize();
    double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = 0, tp = 0;
    
    double sl_points = 0;
    if(slMode == MODE_POINTS)
    {
        sl_points = currentStopLoss;
    }
    else // MODE_CURRENCY
    {
        double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        if(tick_value > 0 && tick_size > 0 && lot > 0)
        {
            double one_point_value = (tick_value / tick_size) * _Point * lot;
            sl_points = currentStopLoss / one_point_value;
        }
    }

    double tp_points = 0;
    if(tpMode == MODE_POINTS)
    {
        tp_points = currentTakeProfit;
    }
    else // MODE_CURRENCY
    {
        double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        if(tick_value > 0 && tick_size > 0 && lot > 0)
        {
            double one_point_value = (tick_value / tick_size) * _Point * lot;
            tp_points = currentTakeProfit / one_point_value;
        }
    }
    
    if(sl_points > 0)
        sl = price + sl_points * _Point;
    
    if(tp_points > 0)
        tp = price - tp_points * _Point;
    
    Print("Attempting SELL: Price=", price, " SL=", sl, " TP=", tp, " Lot=", lot);
    
    if(trade.Sell(lot, _Symbol, price, sl, tp, "Dashboard SELL"))
    {
        ExtDialog.SetStatus("SELL EXECUTED", C'50,205,50');
        PlaySound("alert2.wav");
    }
    else
    {
        Print("Error code: ", trade.ResultRetcode());
        ExtDialog.SetStatus("SELL FAILED", C'255,69,0');
    }
}


void CControlsDialog::OnClickBuyButton(void)
{
   Print("Buy pressed");
   ExecuteBuy();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickSellButton(void)
{
   Print("Sell pressed");
   ExecuteSell();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseLastPosition()
{
    ulong ticket = 0;
    datetime lastTime = 0;
    int totalPos = 0;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i) && position.Symbol() == _Symbol)
        {
            totalPos++;
            if(position.Time() > lastTime)
            {
                lastTime = position.Time();
                ticket = position.Ticket();
            }
        }
    }
    
    if(ticket > 0)
    {
        Print("Attempting to close position: ", ticket);
        if(trade.PositionClose(ticket))
        {
            Print("POSITION CLOSED: ", ticket);
            ExtDialog.SetStatus("POSITION CLOSED", C'255,215,0');
            PlaySound("alert2.wav");
        }
        else
        {
            Print("FAILED TO CLOSE: ", trade.ResultRetcodeDescription());
            ExtDialog.SetStatus("CLOSE FAILED", C'255,69,0');
        }
    }
    else
    {
        Print("NO POSITIONS TO CLOSE");
        ExtDialog.SetStatus("NO POSITIONS", C'255,215,0');
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickCloseButton(void)
{
   Print("Close pressed");
   CloseLastPosition();
}

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CControlsDialog ExtDialog;

MqlRates currentRates[2];

void UpdateDashboard();

//+------------------------------------------------------------------+
//| Event handlers                                                   |
//+------------------------------------------------------------------+
int OnInitEvent()
{
   trade.SetExpertMagicNumber(expertMagic);
   trade.SetDeviationInPoints(Slippage);
   resetTime = TimeCurrent();
   dailyPL = GetDailyPL();
    
   currentTakeProfit = TakeProfit;
   currentStopLoss = StopLoss;
    
   tpDownBtn = prefix + "TP_DOWN";
   tpUpBtn = prefix + "TP_UP";
   tpModeBtn = prefix + "TP_MODE";
   tpLabel = prefix + "TP_LABEL";
   slDownBtn = prefix + "SL_DOWN";
   slUpBtn = prefix + "SL_UP";
   slModeBtn = prefix + "SL_MODE";
   slLabel = prefix + "SL_LABEL";

   if(!ExtDialog.Create("Scalping Panel"))
      return(INIT_FAILED);

   ExtDialog.Run();

   return(INIT_SUCCEEDED);
}

void OnTick()
{
    CheckDailyReset();
    UpdateDashboard();
}

double GetDailyPL()
{
    double profit = 0;
    datetime today = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
    
    HistorySelect(today, TimeCurrent());
    for(int i = 0; i < HistoryDealsTotal(); i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol)
        {
            profit += HistoryDealGetDouble(ticket, DEAL_PROFIT);
            profit += HistoryDealGetDouble(ticket, DEAL_SWAP);
            profit += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
        }
    }
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i) && position.Symbol() == _Symbol)
        {
            profit += position.Profit() + position.Swap() + position.Commission();
        }
    }
    
    return profit;
}

void CheckDailyReset()
{
    datetime current = TimeCurrent();
    datetime currentDate = StringToTime(TimeToString(current, TIME_DATE));
    datetime lastDate = StringToTime(TimeToString(resetTime, TIME_DATE));
    
    if(currentDate > lastDate)
    {
        resetTime = current;
        Print("Daily reset");
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinitEvent(const int reason)
{
   // Save panel position
   GlobalVariableSet(GVAR_POSITION_X, ExtDialog.Left());
   GlobalVariableSet(GVAR_POSITION_Y, ExtDialog.Top());

   Comment("");
   ExtDialog.Destroy(reason);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::FlashButton(string btnName)
{
    CButton *btn = (CButton*)Control(btnName);
    if(CheckPointer(btn) == POINTER_INVALID) return;
    
    color original_bg_color = btn.ColorBackground();
    
    btn.ColorBackground(clrWhite);
    btn.ColorBorder(C'0,255,0');
    ChartRedraw();
    Sleep(150);
    
    btn.ColorBackground(original_bg_color);
    if(StringFind(btnName, "BUY") >= 0) btn.ColorBorder(C'0,255,0');
    else if(StringFind(btnName, "SELL") >= 0) btn.ColorBorder(C'255,0,100');
    else if(StringFind(btnName, "CLOSE") >= 0) btn.ColorBorder(C'255,165,0');
}

void CommonChartEvent(const int id,       // event ID
                      const long& lparam,   	// event parameter of the long type
                      const double& dparam, 	// event parameter of the double type
                      const string& sparam) 	// event parameter of the string type
{
    if(id == CHARTEVENT_KEYDOWN && EnableHotkeys)
    {
        int keyCode = (int)lparam;
        string key = "";
        
        if(keyCode >= 48 && keyCode <= 57)      
            key = CharToString((uchar)keyCode);
        else if(keyCode >= 96 && keyCode <= 105) 
            key = CharToString((uchar)(keyCode - 48));
        else
            key = CharToString((uchar)keyCode);
        
        Print("Key pressed: ", key, " (code: ", keyCode, ")");
        
        bool isBuyKey = (key == BuyKey) || (keyCode == 49) || (keyCode == 97);   
        bool isSellKey = (key == SellKey) || (keyCode == 51) || (keyCode == 99);  
        bool isCloseKey = (key == CloseKey) || (keyCode == 50) || (keyCode == 98); 
        
        if(isBuyKey)
        {
            ExecuteBuy();
            ExtDialog.FlashButton(buyBtnName);
        }
        else if(isSellKey)
        {
            ExecuteSell();
            ExtDialog.FlashButton(sellBtnName);
        }
        else if(isCloseKey)
        {
            CloseLastPosition();
            ExtDialog.FlashButton(closeBtnName);
        }
        
        ChartRedraw();
    }
}
//+------------------------------------------------------------------+


int OnInit()
{
   return OnInitEvent();
}

void OnDeinit(const int reason)
{
   OnDeinitEvent(reason);
}

void OnChartEvent(const int id,         // event ID
                  const long& lparam,   // event parameter of the long type
                  const double& dparam, // event parameter of the double type
                  const string& sparam) // event parameter of the string type
{
   ExtDialog.ChartEvent(id,lparam,dparam,sparam);
   CommonChartEvent(id,lparam,dparam,sparam);
}
