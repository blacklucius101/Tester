#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input group "=== TRADING ==="
input double   LotSize = 1;
input int      TakeProfit = 50;
input int      StopLoss = 50;
input int      Slippage = 3;
input bool     UseOneTickSL = true;

input group "=== FLAT ==="
input int      FlatTarget = 1;
input bool     ShowFlatButton = true;

input group "=== DASHBOARD ==="
input int      DashX = 30;
input int      DashY = 30;
input int      ButtonSize = 140;

input group "=== KEYBOARD HOTKEYS ==="
input bool     EnableHotkeys = true;
input string   BuyKey = "1";
input string   SellKey = "3"; 
input string   CloseKey = "2";
input string   FlatKey = "5";

input group "=== RISK ==="
input double   MaxDailyLoss = 0;
input int      MaxPositions = 3;

CTrade trade;
CPositionInfo position;

string prefix = "FutureDash_";
double dailyPL = 0;
datetime resetTime;
bool flatActive = false;

string buyBtn = prefix + "BUY";
string sellBtn = prefix + "SELL";
string closeBtn = prefix + "CLOSE";
string flatBtn = prefix + "FLAT";
string posLbl = prefix + "POS";
string plLbl = prefix + "PL";
string spreadLbl = prefix + "SPREAD";
string statusLbl = prefix + "STATUS";
string mainPanel = prefix + "PANEL";
string glowPanel = prefix + "GLOW";

int OnInit()
{
    trade.SetExpertMagicNumber(888888);
    trade.SetDeviationInPoints(Slippage);
    resetTime = TimeCurrent();
    dailyPL = GetDailyPL();
    
    Print("=== DASHBOARD INITIALIZATION ===");
    Print("Symbol: ", _Symbol);
    Print("Lot Size: ", LotSize);
    Print("Take Profit: ", TakeProfit);
    Print("Stop Loss: ", StopLoss);
    Print("Magic Number: ", 888888);
    Print("Trading allowed: ", CanTrade() ? "YES" : "NO");
    
    CreateFuturisticDashboard();
    Print("Click buttons or use NUMPAD: 1=BUY 3=SELL 2=CLOSE 5=FLAT");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
    DeleteAllObjects();
    Print("Dashboard - OFFLINE");
}

void OnTick()
{
    CheckDailyReset();
    if(flatActive) CheckFlatSystem();
    UpdateDashboard();
    
    if(MaxDailyLoss > 0 && dailyPL <= -MaxDailyLoss)
    {
        CloseAllPositions();
        SetStatus("DAILY LIMIT REACHED", C'255,50,50');
        return;
    }
}

void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        if(sparam == buyBtn)
        {
            ExecuteBuy();
            FlashButton(buyBtn, C'0,255,100');
            ObjectSetInteger(0, buyBtn, OBJPROP_STATE, false);
        }
        else if(sparam == sellBtn)
        {
            ExecuteSell();
            FlashButton(sellBtn, C'255,50,100');
            ObjectSetInteger(0, sellBtn, OBJPROP_STATE, false);
        }
        else if(sparam == closeBtn)
        {
            CloseLastPosition();
            FlashButton(closeBtn, C'255,150,0');
            ObjectSetInteger(0, closeBtn, OBJPROP_STATE, false);
        }
        else if(sparam == flatBtn && ShowFlatButton)
        {
            ToggleFlat();
            FlashButton(flatBtn, flatActive ? C'0,200,255' : C'100,100,100');
            ObjectSetInteger(0, flatBtn, OBJPROP_STATE, false);
        }
        ChartRedraw();
    }
    else if(id == CHARTEVENT_KEYDOWN && EnableHotkeys)
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
        bool isFlatKey = (key == FlatKey) || (keyCode == 53) || (keyCode == 101); 
        
        if(isBuyKey)
        {
            ExecuteBuy();
            FlashButton(buyBtn, C'0,255,100');
        }
        else if(isSellKey)
        {
            ExecuteSell();
            FlashButton(sellBtn, C'255,50,100');
        }
        else if(isCloseKey)
        {
            CloseLastPosition();
            FlashButton(closeBtn, C'255,150,0');
        }
        else if(isFlatKey && ShowFlatButton)
        {
            ToggleFlat();
            FlashButton(flatBtn, flatActive ? C'0,200,255' : C'100,100,100');
        }
        
        ChartRedraw();
    }
}

void CreateFuturisticDashboard()
{
    int x = DashX;
    int y = DashY;
    int btnW = ButtonSize;
    int btnH = 50;
    int gap = 8;
    int panelW = (btnW * 2) + gap + 40;
    int panelH = 280;
    
    CreateProPanel(glowPanel, x-20, y-20, panelW+40, panelH+40);
    CreateMainPanel(mainPanel, x-10, y-10, panelW+20, panelH+20);
    CreateHeaderPanel(prefix + "HEADER", x, y, panelW, 35);
    
    CreateHeaderLabel(prefix + "TITLE", x + panelW/2 - 60, y + 8, "SCALPING", C'0,255,255');
    
    int btnY = y + 50;
    CreateProButton(buyBtn, x + 10, btnY, btnW, btnH, "▲ BUY", C'34,139,34', C'0,255,0', C'255,255,255');
    CreateProButton(sellBtn, x + btnW + gap + 10, btnY, btnW, btnH, "▼ SELL", C'220,20,60', C'255,0,100', C'255,255,255');
    
    btnY += btnH + gap;
    CreateProButton(closeBtn, x + 10, btnY, btnW, btnH, "✕ CLOSE", C'255,140,0', C'255,165,0', C'0,0,0');
    
    if(ShowFlatButton)
        CreateProButton(flatBtn, x + btnW + gap + 10, btnY, btnW, btnH, 
                       flatActive ? "FLAT ON" : "FLAT OFF", 
                       flatActive ? C'0,191,255' : C'105,105,105', 
                       flatActive ? C'135,206,250' : C'169,169,169', C'255,255,255');
    
    CreateStatsPanel(prefix + "STATS", x + 5, btnY + btnH + 15, panelW - 10, 80);
    
    int statsY = btnY + btnH + 25;
    CreateStatsLabel(posLbl, x + 15, statsY, "POSITIONS", "0", C'0,255,255');
    CreateStatsLabel(spreadLbl, x + 15, statsY + 20, "SPREAD", "0.0", C'255,215,0');
    CreateStatsLabel(plLbl, x + 15, statsY + 40, "DAILY P&L", "$0.00", C'50,205,50');
    CreateStatsLabel(statusLbl, x + 15, statsY + 60, "STATUS", "READY", C'0,191,255');
    
    if(EnableHotkeys)
    {
        CreateHotkeyPanel(prefix + "HOTKEY_PANEL", x + 5, statsY + 85, panelW - 10, 25);
        string hotkeys = "NUMPAD: [1] BUY  [3] SELL  [2] CLOSE  [5] FLAT";
        CreateHotkeyLabel(prefix + "HOTKEYS", x + 15, statsY + 92, hotkeys, C'176,196,222');
    }
    
    ChartRedraw();
}

void CreateProPanel(string name, int x, int y, int w, int h)
{
    ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'15,15,35');
    ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'70,130,180');
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_RAISED);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void CreateMainPanel(string name, int x, int y, int w, int h)
{
    ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'25,25,45');
    ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'100,149,237');
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_RAISED);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void CreateHeaderPanel(string name, int x, int y, int w, int h)
{
    ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'35,35,65');
    ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'0,191,255');
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void CreateStatsPanel(string name, int x, int y, int w, int h)
{
    ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'20,20,40');
    ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'75,75,95');
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void CreateHotkeyPanel(string name, int x, int y, int w, int h)
{
    ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'30,30,50');
    ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'65,105,225');
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void CreateProButton(string name, int x, int y, int w, int h, string text, color bg, color hover, color textColor)
{
    ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
    ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, hover);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 14);
    ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void CreateHeaderLabel(string name, int x, int y, string text, color clr)
{
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 12);
    ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void CreateStatsLabel(string name, int x, int y, string label, string value, color clr)
{
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, name, OBJPROP_TEXT, label + ": " + value);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
    ObjectSetString(0, name, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void CreateHotkeyLabel(string name, int x, int y, string text, color clr)
{
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
    ObjectSetString(0, name, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void DeleteAllObjects()
{
    ObjectDelete(0, glowPanel);
    ObjectDelete(0, mainPanel);
    ObjectDelete(0, prefix + "HEADER");
    ObjectDelete(0, prefix + "TITLE");
    ObjectDelete(0, prefix + "STATS");
    ObjectDelete(0, buyBtn);
    ObjectDelete(0, sellBtn);
    ObjectDelete(0, closeBtn);
    if(ShowFlatButton) ObjectDelete(0, flatBtn);
    ObjectDelete(0, posLbl);
    ObjectDelete(0, spreadLbl);
    ObjectDelete(0, plLbl);
    ObjectDelete(0, statusLbl);
    if(EnableHotkeys)
    {
        ObjectDelete(0, prefix + "HOTKEY_PANEL");
        ObjectDelete(0, prefix + "HOTKEYS");
    }
}

void ExecuteBuy()
{
    if(!CanTrade()) 
    {
        Print("Cannot trade - Max positions reached or other restriction");
        return;
    }
    
    double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl = 0, tp = 0;
    
    if(StopLoss > 0)
        sl = price - StopLoss * _Point;
    else if(UseOneTickSL)
        sl = price - _Point;
    
    if(TakeProfit > 0)
        tp = price + TakeProfit * _Point;
    
    Print("Attempting BUY: Price=", price, " SL=", sl, " TP=", tp, " Lot=", LotSize);
    
    if(trade.Buy(LotSize, _Symbol, price, sl, tp, "Dashboard BUY"))
    {
        SetStatus("BUY EXECUTED", C'50,205,50');
    }
    else
    {
        Print("Error code: ", trade.ResultRetcode());
        SetStatus("BUY FAILED", C'255,69,0');
    }
}

void ExecuteSell()
{
    if(!CanTrade()) 
    {
        Print("Cannot trade - Max positions reached or other restriction");
        return;
    }
    
    double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = 0, tp = 0;
    
    if(StopLoss > 0)
        sl = price + StopLoss * _Point;
    else if(UseOneTickSL)
        sl = price + _Point;
    
    if(TakeProfit > 0)
        tp = price - TakeProfit * _Point;
    
    Print("Attempting SELL: Price=", price, " SL=", sl, " TP=", tp, " Lot=", LotSize);
    
    if(trade.Sell(LotSize, _Symbol, price, sl, tp, "Dashboard SELL"))
    {
        SetStatus("SELL EXECUTED", C'50,205,50');
    }
    else
    {
        Print("Error code: ", trade.ResultRetcode());
        SetStatus("SELL FAILED", C'255,69,0');
    }
}

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
            SetStatus("POSITION CLOSED", C'255,215,0');
        }
        else
        {
            Print("FAILED TO CLOSE: ", trade.ResultRetcodeDescription());
            SetStatus("CLOSE FAILED", C'255,69,0');
        }
    }
    else
    {
        Print("NO POSITIONS TO CLOSE");
        SetStatus("NO POSITIONS", C'255,215,0');
    }
}

void CloseAllPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i) && position.Symbol() == _Symbol)
            trade.PositionClose(position.Ticket());
    }
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
        SetStatus("MAX POSITIONS", C'255,215,0');
        return false;
    }
    
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
    {
        SetStatus("ENABLE AUTO TRADING", C'255,69,0');
        return false;
    }
    
    if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
    {
        SetStatus("ALLOW DLL IMPORTS", C'255,69,0');
        return false;
    }
    
    return true;
}

void UpdateDashboard()
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
    
    ObjectSetString(0, posLbl, OBJPROP_TEXT, StringFormat("POSITIONS: %d", positions));
    ObjectSetInteger(0, posLbl, OBJPROP_COLOR, positions > 0 ? C'255,215,0' : C'0,255,255');
    
    ObjectSetString(0, spreadLbl, OBJPROP_TEXT, StringFormat("SPREAD: %.1f", spread));
    color spreadColor = spread <= 2.0 ? C'50,205,50' : (spread <= 5.0 ? C'255,215,0' : C'255,69,0');
    ObjectSetInteger(0, spreadLbl, OBJPROP_COLOR, spreadColor);
    
    dailyPL = GetDailyPL();
    ObjectSetString(0, plLbl, OBJPROP_TEXT, StringFormat("DAILY P&L: $%.2f", dailyPL));
    ObjectSetInteger(0, plLbl, OBJPROP_COLOR, dailyPL >= 0 ? C'50,205,50' : C'255,69,0');
    
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
    
    if(ShowFlatButton)
    {
        if(flatActive)
        {
            status = "FLAT ACTIVE";
            ObjectSetString(0, flatBtn, OBJPROP_TEXT, "⚡ FLAT ON");
            ObjectSetInteger(0, flatBtn, OBJPROP_BGCOLOR, C'0,191,255');
        }
        else
        {
            ObjectSetString(0, flatBtn, OBJPROP_TEXT, "⚡ FLAT OFF");
            ObjectSetInteger(0, flatBtn, OBJPROP_BGCOLOR, C'105,105,105');
        }
    }
    
    ObjectSetString(0, statusLbl, OBJPROP_TEXT, StringFormat("STATUS: %s", status));
    ObjectSetInteger(0, statusLbl, OBJPROP_COLOR, statusColor);
}

void SetStatus(string text, color clr)
{
    ObjectSetString(0, statusLbl, OBJPROP_TEXT, text);
    ObjectSetInteger(0, statusLbl, OBJPROP_COLOR, clr);
}

void FlashButton(string btnName, color flashColor)
{
    ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, clrWhite);
    ObjectSetInteger(0, btnName, OBJPROP_BORDER_COLOR, flashColor);
    ChartRedraw();
    Sleep(150);
    
    if(btnName == buyBtn)
    {
        ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, C'34,139,34');
        ObjectSetInteger(0, btnName, OBJPROP_BORDER_COLOR, C'0,255,0');
    }
    else if(btnName == sellBtn)
    {
        ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, C'220,20,60');
        ObjectSetInteger(0, btnName, OBJPROP_BORDER_COLOR, C'255,0,100');
    }
    else if(btnName == closeBtn)
    {
        ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, C'255,140,0');
        ObjectSetInteger(0, btnName, OBJPROP_BORDER_COLOR, C'255,165,0');
    }
    else if(btnName == flatBtn)
    {
        ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, flatActive ? C'0,191,255' : C'105,105,105');
        ObjectSetInteger(0, btnName, OBJPROP_BORDER_COLOR, flatActive ? C'135,206,250' : C'169,169,169');
    }
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

void ToggleFlat()
{
    flatActive = !flatActive;
    
    if(flatActive)
    {
        Print("FLAT SYSTEM ON - Target: +", FlatTarget, " ticks");
        SetStatus("FLAT SYSTEM ON", C'0,200,255');
    }
    else
    {
        Print("FLAT SYSTEM OFF");
        SetStatus("FLAT SYSTEM OFF", C'100,100,100');
    }
}

void CheckFlatSystem()
{
    if(!flatActive) return;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i) && position.Symbol() == _Symbol)
        {
            double openPrice = position.PriceOpen();
            double currentPrice = position.Type() == POSITION_TYPE_BUY ? 
                                 SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                                 SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            
            double profitTicks = 0;
            if(position.Type() == POSITION_TYPE_BUY)
                profitTicks = (currentPrice - openPrice) / _Point;
            else
                profitTicks = (openPrice - currentPrice) / _Point;
            
            if(profitTicks >= FlatTarget)
            {
                double newSL = 0;
                if(position.Type() == POSITION_TYPE_BUY)
                    newSL = openPrice + (FlatTarget * _Point);
                else
                    newSL = openPrice - (FlatTarget * _Point);
                
                if(MathAbs(position.StopLoss() - newSL) > _Point/2)
                {
                    if(trade.PositionModify(position.Ticket(), newSL, position.TakeProfit()))
                    {
                        Print("FLAT: Profit locked at +", FlatTarget, " ticks");
                        SetStatus("PROFIT LOCKED", C'255,255,0');
                    }
                }
            }
        }
    }
}
