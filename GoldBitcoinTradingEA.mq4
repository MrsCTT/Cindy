//+------------------------------------------------------------------+
//|                    Gold & Bitcoin Trading EA                     |
//|                    Advanced Control Panel v1.0                   |
//|                         For MT4 Platform                         |
//+------------------------------------------------------------------+
#property copyright   "MrsCTT"
#property link        "https://github.com/MrsCTT"
#property version     "1.0"
#property strict
#property description "Advanced Trading EA with Interactive Control Panel for Gold and Bitcoin"

//+------------------------------------------------------------------+
//| Input Parameters
//+------------------------------------------------------------------+

// Trading Parameters
input double LotSize = 0.1;
input double StopLoss = 50;
input double TakeProfit = 100;
input int TrailingStopDefault = 20;

// Panel Display Parameters
input bool ShowPanel = true;
input int PanelStartX = 10;
input int PanelStartY = 10;
input int PanelWidth = 250;
input int PanelHeight = 400;

// Button Colors
input color BuyButtonColor = clrGreen;
input color SellButtonColor = clrRed;
input color CloseButtonColor = clrOrange;
input color BreakEvenColor = clrYellow;
input color TrailingStopColor = clrCyan;

// Text Colors
input color TextColor = clrWhite;
input color BackgroundColor = clrBlack;
input color ProfitColor = clrBlue;
input color LossColor = clrRed;

//+------------------------------------------------------------------+
//| Global Variables
//+------------------------------------------------------------------+

// Panel Object Names
string PanelName = "GoldBitcoin_Panel";
string BuyBtnName = "Buy_Button";
string SellBtnName = "Sell_Button";
string CloseAllBtnName = "CloseAll_Button";
string BreakEvenBtnName = "BreakEven_Button";
string Close50BtnName = "Close50_Button";
string TrailingStopBtnName = "TrailingStop_Button";
string PnLDisplayName = "PnL_Display";
string PnLValueName = "PnL_Value";

// Trading State Variables
bool AllowTrading = true;
int CurrentTrailingStop = 0;
double CurrentPnL = 0;

//+------------------------------------------------------------------+
//| Expert Initialization Function
//+------------------------------------------------------------------+

int OnInit()
{
    // Create the control panel
    CreatePanel();
    
    // Create buttons
    CreateBuyButton();
    CreateSellButton();
    CreateCloseAllButton();
    CreateBreakEvenButton();
    CreateClose50Button();
    CreateTrailingStopButton();
    
    // Create P&L display
    CreatePnLDisplay();
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert Start Function
//+------------------------------------------------------------------+

void OnTick()
{
    // Update P&L display in real-time
    UpdatePnLDisplay();
    
    // Apply trailing stop if active
    if(CurrentTrailingStop > 0)
    {
        ApplyTrailingStop(CurrentTrailingStop);
    }
}

//+------------------------------------------------------------------+
//| Expert Deinitialization Function
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
    // Delete all created objects
    DeleteAllObjects();
}

//+------------------------------------------------------------------+
//| Chart Event Handler
//+------------------------------------------------------------------+

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    // Handle button clicks
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        if(sparam == BuyBtnName)
        {
            OpenBuyPosition();
        }
        else if(sparam == SellBtnName)
        {
            OpenSellPosition();
        }
        else if(sparam == CloseAllBtnName)
        {
            CloseAllPositions();
        }
        else if(sparam == BreakEvenBtnName)
        {
            SetBreakEven();
        }
        else if(sparam == Close50BtnName)
        {
            Close50Percent();
        }
        else if(sparam == TrailingStopBtnName)
        {
            ShowTrailingStopDialog();
        }
        
        // Prevent further processing
        ObjectSetInteger(0, sparam, OBJPROP_STATE, 0);
    }
}

//+------------------------------------------------------------------+
//| Panel Creation Functions
//+------------------------------------------------------------------+

void CreatePanel()
{
    // Create background rectangle
    ObjectCreate(0, PanelName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, PanelName, OBJPROP_XDISTANCE, PanelStartX);
    ObjectSetInteger(0, PanelName, OBJPROP_YDISTANCE, PanelStartY);
    ObjectSetInteger(0, PanelName, OBJPROP_XSIZE, PanelWidth);
    ObjectSetInteger(0, PanelName, OBJPROP_YSIZE, PanelHeight);
    ObjectSetInteger(0, PanelName, OBJPROP_BGCOLOR, BackgroundColor);
    ObjectSetInteger(0, PanelName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, PanelName, OBJPROP_BORDER_COLOR, TextColor);
    ObjectSetInteger(0, PanelName, OBJPROP_BORDER_WIDTH, 2);
    ObjectSetInteger(0, PanelName, OBJPROP_ZORDER, 0);
}

void CreateBuyButton()
{
    ObjectCreate(0, BuyBtnName, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, BuyBtnName, OBJPROP_XDISTANCE, PanelStartX + 5);
    ObjectSetInteger(0, BuyBtnName, OBJPROP_YDISTANCE, PanelStartY + 30);
    ObjectSetInteger(0, BuyBtnName, OBJPROP_XSIZE, 110);
    ObjectSetInteger(0, BuyBtnName, OBJPROP_YSIZE, 30);
    ObjectSetString(0, BuyBtnName, OBJPROP_TEXT, "BUY");
    ObjectSetInteger(0, BuyBtnName, OBJPROP_BGCOLOR, BuyButtonColor);
    ObjectSetInteger(0, BuyBtnName, OBJPROP_BORDER_COLOR, clrWhite);
    ObjectSetInteger(0, BuyBtnName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, BuyBtnName, OBJPROP_FONTSIZE, 12);
    ObjectSetInteger(0, BuyBtnName, OBJPROP_ZORDER, 1);
}

void CreateSellButton()
{
    ObjectCreate(0, SellBtnName, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, SellBtnName, OBJPROP_XDISTANCE, PanelStartX + 125);
    ObjectSetInteger(0, SellBtnName, OBJPROP_YDISTANCE, PanelStartY + 30);
    ObjectSetInteger(0, SellBtnName, OBJPROP_XSIZE, 110);
    ObjectSetInteger(0, SellBtnName, OBJPROP_YSIZE, 30);
    ObjectSetString(0, SellBtnName, OBJPROP_TEXT, "SELL");
    ObjectSetInteger(0, SellBtnName, OBJPROP_BGCOLOR, SellButtonColor);
    ObjectSetInteger(0, SellBtnName, OBJPROP_BORDER_COLOR, clrWhite);
    ObjectSetInteger(0, SellBtnName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, SellBtnName, OBJPROP_FONTSIZE, 12);
    ObjectSetInteger(0, SellBtnName, OBJPROP_ZORDER, 1);
}

void CreateCloseAllButton()
{
    ObjectCreate(0, CloseAllBtnName, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, CloseAllBtnName, OBJPROP_XDISTANCE, PanelStartX + 5);
    ObjectSetInteger(0, CloseAllBtnName, OBJPROP_YDISTANCE, PanelStartY + 70);
    ObjectSetInteger(0, CloseAllBtnName, OBJPROP_XSIZE, 230);
    ObjectSetInteger(0, CloseAllBtnName, OBJPROP_YSIZE, 25);
    ObjectSetString(0, CloseAllBtnName, OBJPROP_TEXT, "CLOSE ALL");
    ObjectSetInteger(0, CloseAllBtnName, OBJPROP_BGCOLOR, CloseButtonColor);
    ObjectSetInteger(0, CloseAllBtnName, OBJPROP_BORDER_COLOR, clrWhite);
    ObjectSetInteger(0, CloseAllBtnName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, CloseAllBtnName, OBJPROP_FONTSIZE, 11);
    ObjectSetInteger(0, CloseAllBtnName, OBJPROP_ZORDER, 1);
}

void CreateBreakEvenButton()
{
    ObjectCreate(0, BreakEvenBtnName, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, BreakEvenBtnName, OBJPROP_XDISTANCE, PanelStartX + 5);
    ObjectSetInteger(0, BreakEvenBtnName, OBJPROP_YDISTANCE, PanelStartY + 105);
    ObjectSetInteger(0, BreakEvenBtnName, OBJPROP_XSIZE, 110);
    ObjectSetInteger(0, BreakEvenBtnName, OBJPROP_YSIZE, 25);
    ObjectSetString(0, BreakEvenBtnName, OBJPROP_TEXT, "BREAK EVEN");
    ObjectSetInteger(0, BreakEvenBtnName, OBJPROP_BGCOLOR, BreakEvenColor);
    ObjectSetInteger(0, BreakEvenBtnName, OBJPROP_BORDER_COLOR, clrBlack);
    ObjectSetInteger(0, BreakEvenBtnName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, BreakEvenBtnName, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, BreakEvenBtnName, OBJPROP_ZORDER, 1);
}

void CreateClose50Button()
{
    ObjectCreate(0, Close50BtnName, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, Close50BtnName, OBJPROP_XDISTANCE, PanelStartX + 125);
    ObjectSetInteger(0, Close50BtnName, OBJPROP_YDISTANCE, PanelStartY + 105);
    ObjectSetInteger(0, Close50BtnName, OBJPROP_XSIZE, 110);
    ObjectSetInteger(0, Close50BtnName, OBJPROP_YSIZE, 25);
    ObjectSetString(0, Close50BtnName, OBJPROP_TEXT, "CLOSE 50%");
    ObjectSetInteger(0, Close50BtnName, OBJPROP_BGCOLOR, clrPurple);
    ObjectSetInteger(0, Close50BtnName, OBJPROP_BORDER_COLOR, clrWhite);
    ObjectSetInteger(0, Close50BtnName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, Close50BtnName, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, Close50BtnName, OBJPROP_ZORDER, 1);
}

void CreateTrailingStopButton()
{
    ObjectCreate(0, TrailingStopBtnName, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, TrailingStopBtnName, OBJPROP_XDISTANCE, PanelStartX + 5);
    ObjectSetInteger(0, TrailingStopBtnName, OBJPROP_YDISTANCE, PanelStartY + 140);
    ObjectSetInteger(0, TrailingStopBtnName, OBJPROP_XSIZE, 230);
    ObjectSetInteger(0, TrailingStopBtnName, OBJPROP_YSIZE, 25);
    ObjectSetString(0, TrailingStopBtnName, OBJPROP_TEXT, "TRAILING STOP");
    ObjectSetInteger(0, TrailingStopBtnName, OBJPROP_BGCOLOR, TrailingStopColor);
    ObjectSetInteger(0, TrailingStopBtnName, OBJPROP_BORDER_COLOR, clrBlack);
    ObjectSetInteger(0, TrailingStopBtnName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, TrailingStopBtnName, OBJPROP_FONTSIZE, 11);
    ObjectSetInteger(0, TrailingStopBtnName, OBJPROP_ZORDER, 1);
}

void CreatePnLDisplay()
{
    // P&L Label
    ObjectCreate(0, PnLDisplayName, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, PnLDisplayName, OBJPROP_XDISTANCE, PanelStartX + 10);
    ObjectSetInteger(0, PnLDisplayName, OBJPROP_YDISTANCE, PanelStartY + 180);
    ObjectSetString(0, PnLDisplayName, OBJPROP_TEXT, "P&L:");
    ObjectSetInteger(0, PnLDisplayName, OBJPROP_FONTSIZE, 12);
    ObjectSetInteger(0, PnLDisplayName, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, PnLDisplayName, OBJPROP_COLOR, TextColor);
    ObjectSetInteger(0, PnLDisplayName, OBJPROP_ZORDER, 1);
    
    // P&L Value Display
    ObjectCreate(0, PnLValueName, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, PnLValueName, OBJPROP_XDISTANCE, PanelStartX + 100);
    ObjectSetInteger(0, PnLValueName, OBJPROP_YDISTANCE, PanelStartY + 180);
    ObjectSetString(0, PnLValueName, OBJPROP_TEXT, "0.00");
    ObjectSetInteger(0, PnLValueName, OBJPROP_FONTSIZE, 12);
    ObjectSetInteger(0, PnLValueName, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, PnLValueName, OBJPROP_COLOR, ProfitColor);
    ObjectSetInteger(0, PnLValueName, OBJPROP_ZORDER, 1);
}

//+------------------------------------------------------------------+
//| Trading Functions
//+------------------------------------------------------------------+

void OpenBuyPosition()
{
    if(!AllowTrading)
    {
        Alert("Trading is currently disabled!");
        return;
    }
    
    int ticket = OrderSend(
        Symbol(),
        OP_BUY,
        LotSize,
        Ask,
        3,
        Ask - StopLoss * Point,
        Ask + TakeProfit * Point,
        "Gold Bitcoin EA - BUY",
        0,
        0,
        BuyButtonColor
    );
    
    if(ticket > 0)
    {
        Print("Buy order opened: Ticket #", ticket);
        Alert("Buy Order Opened Successfully!");
    }
    else
    {
        Print("Buy order failed. Error: ", GetLastError());
        Alert("Buy Order Failed! Error: ", GetLastError());
    }
}

void OpenSellPosition()
{
    if(!AllowTrading)
    {
        Alert("Trading is currently disabled!");
        return;
    }
    
    int ticket = OrderSend(
        Symbol(),
        OP_SELL,
        LotSize,
        Bid,
        3,
        Bid + StopLoss * Point,
        Bid - TakeProfit * Point,
        "Gold Bitcoin EA - SELL",
        0,
        0,
        SellButtonColor
    );
    
    if(ticket > 0)
    {
        Print("Sell order opened: Ticket #", ticket);
        Alert("Sell Order Opened Successfully!");
    }
    else
    {
        Print("Sell order failed. Error: ", GetLastError());
        Alert("Sell Order Failed! Error: ", GetLastError());
    }
}

void CloseAllPositions()
{
    int closed = 0;
    int total = OrdersTotal();
    
    for(int i = total - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol())
            {
                bool result = false;
                if(OrderType() == OP_BUY)
                    result = OrderClose(OrderTicket(), OrderLots(), Bid, 3, clrWhite);
                else if(OrderType() == OP_SELL)
                    result = OrderClose(OrderTicket(), OrderLots(), Ask, 3, clrWhite);
                
                if(result)
                    closed++;
            }
        }
    }
    
    Alert("Closed ", closed, " position(s)!");
    Print("Total positions closed: ", closed);
}

void SetBreakEven()
{
    int modified = 0;
    int total = OrdersTotal();
    
    for(int i = 0; i < total; i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol())
            {
                bool result = OrderModify(
                    OrderTicket(),
                    OrderOpenPrice(),
                    OrderOpenPrice(),
                    OrderTakeProfit(),
                    0,
                    BreakEvenColor
                );
                
                if(result)
                    modified++;
                else
                    Print("OrderModify failed for ticket ", OrderTicket(), " Error: ", GetLastError());
            }
        }
    }
    
    Alert("Break Even set for ", modified, " position(s)!");
    Print("Positions moved to break even: ", modified);
}

void Close50Percent()
{
    int closed = 0;
    double totalLots = 0;
    int total = OrdersTotal();
    
    // Calculate total lots
    for(int i = 0; i < total; i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol())
            {
                totalLots += OrderLots();
            }
        }
    }
    
    double lotsToClose = totalLots / 2;
    double closedLots = 0;
    
    // Close 50% of positions
    for(int i = total - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && closedLots < lotsToClose)
            {
                double closeSize = CustomMin(OrderLots(), lotsToClose - closedLots);
                
                bool result = false;
                if(OrderType() == OP_BUY)
                    result = OrderClose(OrderTicket(), closeSize, Bid, 3, clrWhite);
                else if(OrderType() == OP_SELL)
                    result = OrderClose(OrderTicket(), closeSize, Ask, 3, clrWhite);
                
                if(result)
                {
                    closed++;
                    closedLots += closeSize;
                }
            }
        }
    }
    
    Alert("Closed 50% of positions! Closed ", closed, " order(s)!");
    Print("Close 50% executed. Orders closed: ", closed);
}

void ApplyTrailingStop(int trailingStop)
{
    int total = OrdersTotal();
    
    for(int i = 0; i < total; i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol())
            {
                if(OrderType() == OP_BUY)
                {
                    double newSL = Bid - trailingStop * Point;
                    if(newSL > OrderStopLoss())
                    {
                        bool result = OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, TrailingStopColor);
                        if(!result)
                            Print("OrderModify failed for trailing stop on ticket ", OrderTicket(), " Error: ", GetLastError());
                    }
                }
                else if(OrderType() == OP_SELL)
                {
                    double newSL = Ask + trailingStop * Point;
                    if(newSL < OrderStopLoss())
                    {
                        bool result = OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, TrailingStopColor);
                        if(!result)
                            Print("OrderModify failed for trailing stop on ticket ", OrderTicket(), " Error: ", GetLastError());
                    }
                }
            }
        }
    }
}

void ShowTrailingStopDialog()
{
    // In MQL4, we use a simple input approach
    // The user will need to modify the input parameters or use a custom dialog
    CurrentTrailingStop = CurrentTrailingStop == 0 ? TrailingStopDefault : 0;
    
    if(CurrentTrailingStop > 0)
    {
        Alert("Trailing Stop ACTIVATED: ", CurrentTrailingStop, " pips");
        Print("Trailing Stop activated with value: ", CurrentTrailingStop);
    }
    else
    {
        Alert("Trailing Stop DEACTIVATED");
        Print("Trailing Stop deactivated");
    }
}

//+------------------------------------------------------------------+
//| P&L Display Update Function
//+------------------------------------------------------------------+

void UpdatePnLDisplay()
{
    double totalPnL = 0;
    int total = OrdersTotal();
    
    // Calculate total P&L
    for(int i = 0; i < total; i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol())
            {
                totalPnL += OrderProfit();
            }
        }
    }
    
    CurrentPnL = totalPnL;
    
    // Update P&L display
    color displayColor = totalPnL >= 0 ? ProfitColor : LossColor;
    
    ObjectSetString(0, PnLValueName, OBJPROP_TEXT, DoubleToString(totalPnL, 2));
    ObjectSetInteger(0, PnLValueName, OBJPROP_COLOR, displayColor);
}

//+------------------------------------------------------------------+
//| Utility Functions
//+------------------------------------------------------------------+

void DeleteAllObjects()
{
    ObjectDelete(0, PanelName);
    ObjectDelete(0, BuyBtnName);
    ObjectDelete(0, SellBtnName);
    ObjectDelete(0, CloseAllBtnName);
    ObjectDelete(0, BreakEvenBtnName);
    ObjectDelete(0, Close50BtnName);
    ObjectDelete(0, TrailingStopBtnName);
    ObjectDelete(0, PnLDisplayName);
    ObjectDelete(0, PnLValueName);
}

// Custom Min function to avoid naming conflicts with built-in MathMin
double CustomMin(double a, double b)
{
    if(a < b)
        return a;
    else
        return b;
}

//+------------------------------------------------------------------+
//| End of Expert Advisor
//+------------------------------------------------------------------+
