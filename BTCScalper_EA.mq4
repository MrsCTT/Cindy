//+------------------------------------------------------------------+
//|  BTCScalper_EA.mq4                                               |
//|  BTC/USD scalping EA (MQ4 version)                               |
//|                                                                  |
//|  Entry logic:                                                    |
//|    - Supertrend flip is the TRIGGER                              |
//|    - VWAP, ASH, WAE, OsMA must ALL confirm on the crossover bar |
//|    - If they don't, one extra bar is given to confirm            |
//|    - If still no confirmation, setup is discarded                |
//+------------------------------------------------------------------+
#property copyright "(c) 2026"
#property version   "1.00"

//===================================================================
//  INPUTS
//===================================================================
extern double InpRisk         = 1.0;    // Risk % per trade
extern double InpSLMult       = 1.5;    // SL = ATR x this
extern double InpTPMult       = 2.5;    // TP = ATR x this
extern int    InpATRPeriod    = 14;     // ATR period for SL/TP
extern int    InpMaxTrades    = 3;      // Max simultaneous trades
extern int    InpMaxSpread    = 2000;   // Max spread (points)
extern int    InpMagic        = 88888;

extern int    InpSTPeriod     = 10;
extern double InpSTMult       = 1.4;

extern int    InpASHLen       = 9;
extern int    InpASHSmooth    = 3;

extern int    InpWAEFast      = 20;
extern int    InpWAESlow      = 40;
extern int    InpWAEBBPer     = 20;
extern double InpWAEBBDev     = 2.0;
extern double InpWAESens      = 150;
extern int    InpWAEDeadPip   = 400;
extern double InpWAEExpPow    = 15;

extern int    InpOsMAFast     = 12;
extern int    InpOsMASlow     = 26;
extern int    InpOsMASig      = 9;

extern double InpDailyLimit   = 5.0;   // Stop today if daily loss >= %
extern double InpMaxDD        = 20.0;  // Stop permanently if drawdown >= %

extern int    InpCooldownMin  = 30;    // Minutes to wait after any trade closes
extern bool   InpUseH1Filter  = true;  // Require H1 Supertrend to agree with entry

//===================================================================
//  GLOBALS
//===================================================================
// Cooldown tracking
datetime g_lastTradeClose = 0;

// Supertrend crossover pending state
bool     g_pendingCross   = false;
int      g_pendingDir     = 0;
datetime g_pendingBarTime = 0;

// Risk tracking
double   g_startBalance;
double   g_dailyBalance;
datetime g_lastBar;
int      g_lastDay;
bool     g_stopped;

// Trade journal
int g_journal = -1;

// Tracked positions for journal
ulong    g_tickets[1000];
datetime g_openTimes[1000];
int      g_nTracked = 0;

//===================================================================
//  MATH HELPERS
//===================================================================
void _lwma(double &src[], double &dst[], int period, int len)
{
    double wsum = period * (period + 1) / 2.0;
    for(int i = 0; i < len; i++)
    {
        if(i < period - 1) { dst[i] = 0; continue; }
        double s = 0;
        for(int j = 0; j < period; j++)
            s += src[i - j] * (period - j);
        dst[i] = s / wsum;
    }
}

void _toFwd(double &series[], double &fwd[], int n)
{
    for(int i = 0; i < n; i++)
        fwd[i] = series[n - 1 - i];
}

//===================================================================
//  SUPERTREND STATE
//  Returns direction of last closed bar.
//  Sets dir_prev to the bar before that so crossovers can be detected
//===================================================================
int SupertrendState(int &dir_prev)
{
    int n = 300;
    double high[300], low[300], close[300], atr_s[300];

    for(int i = 0; i < n; i++)
    {
        high[i]  = iHigh(Symbol(), 0, i);
        low[i]   = iLow(Symbol(), 0, i);
        close[i] = iClose(Symbol(), 0, i);
        atr_s[i] = iATR(Symbol(), 0, InpSTPeriod, i);
    }

    double h[300], l[300], c[300], atr[300];
    _toFwd(high,  h,   n);
    _toFwd(low,   l,   n);
    _toFwd(close, c,   n);
    _toFwd(atr_s, atr, n);

    double fu[300], fl[300], st[300];
    int    dir[300];

    double hl2 = (h[0] + l[0]) / 2.0;
    fu[0]  = hl2 + InpSTMult * atr[0];
    fl[0]  = hl2 - InpSTMult * atr[0];
    st[0]  = fu[0];
    dir[0] = -1;

    for(int i = 1; i < n; i++)
    {
        hl2 = (h[i] + l[i]) / 2.0;
        double bu = hl2 + InpSTMult * atr[i];
        double bl = hl2 - InpSTMult * atr[i];

        fu[i] = (bu < fu[i-1] || c[i-1] > fu[i-1]) ? bu : fu[i-1];
        fl[i] = (bl > fl[i-1] || c[i-1] < fl[i-1]) ? bl : fl[i-1];

        if(st[i-1] == fu[i-1])
        {
            if(c[i] > fu[i]) { dir[i] =  1; st[i] = fl[i]; }
            else             { dir[i] = -1; st[i] = fu[i]; }
        }
        else
        {
            if(c[i] < fl[i]) { dir[i] = -1; st[i] = fu[i]; }
            else             { dir[i] =  1; st[i] = fl[i]; }
        }
    }

    dir_prev = dir[n - 3];
    return   dir[n - 2];
}

//===================================================================
//  H1 TREND FILTER
//===================================================================
int H1TrendFilter()
{
    int n = 300;
    double high[300], low[300], close[300], atr_s[300];

    for(int i = 0; i < n; i++)
    {
        high[i]  = iHigh(Symbol(), 60, i);
        low[i]   = iLow(Symbol(), 60, i);
        close[i] = iClose(Symbol(), 60, i);
        atr_s[i] = iATR(Symbol(), 60, InpSTPeriod, i);
    }

    double h[300], l[300], c[300], atr[300];
    _toFwd(high,  h,   n);
    _toFwd(low,   l,   n);
    _toFwd(close, c,   n);
    _toFwd(atr_s, atr, n);

    double fu[300], fl[300], st[300];
    int    dir[300];

    double hl2 = (h[0] + l[0]) / 2.0;
    fu[0] = hl2 + InpSTMult * atr[0];
    fl[0] = hl2 - InpSTMult * atr[0];
    st[0] = fu[0];
    dir[0] = -1;

    for(int i = 1; i < n; i++)
    {
        hl2 = (h[i] + l[i]) / 2.0;
        double bu = hl2 + InpSTMult * atr[i];
        double bl = hl2 - InpSTMult * atr[i];
        fu[i] = (bu < fu[i-1] || c[i-1] > fu[i-1]) ? bu : fu[i-1];
        fl[i] = (bl > fl[i-1] || c[i-1] < fl[i-1]) ? bl : fl[i-1];
        if(st[i-1] == fu[i-1])
        { if(c[i] > fu[i]) { dir[i]=1; st[i]=fl[i]; } else { dir[i]=-1; st[i]=fu[i]; } }
        else
        { if(c[i] < fl[i]) { dir[i]=-1; st[i]=fu[i]; } else { dir[i]=1; st[i]=fl[i]; } }
    }
    return dir[n - 2];
}

//===================================================================
//  SIGNAL 2 — FULL VWAP  (daily anchor, typical price)
//===================================================================
int SignalVWAP()
{
    datetime t1 = iTime(Symbol(), 0, 1);
    MqlDateTime d1;
    TimeToStruct(t1, d1);

    double cum_tpvol = 0, cum_vol = 0;

    for(int i = 1; i <= 1440; i++)
    {
        datetime t = iTime(Symbol(), 0, i);
        if(t == 0) break;
        MqlDateTime dt;
        TimeToStruct(t, dt);
        if(dt.day != d1.day || dt.mon != d1.mon || dt.year != d1.year) break;

        double tp = (iHigh(Symbol(), 0, i) + iLow(Symbol(), 0, i) + iClose(Symbol(), 0, i)) / 3.0;
        double v  = (double)iVolume(Symbol(), 0, i);

        cum_tpvol += tp * v;
        cum_vol   += v;
    }

    if(cum_vol <= 0) return 0;
    double vwap  = cum_tpvol / cum_vol;
    double close = iClose(Symbol(), 0, 1);

    if(close > vwap) return  1;
    if(close < vwap) return -1;
    return 0;
}

//===================================================================
//  SIGNAL 3 — ASH RSI  (RSI 9, LWMA smooth 3)
//===================================================================
int SignalASH()
{
    int n = 150;
    double rsi[150];

    for(int i = 0; i < n; i++)
        rsi[i] = iRSI(Symbol(), 0, InpASHLen, PRICE_CLOSE, i);

    double fwd[150];
    _toFwd(rsi, fwd, n);

    double braw[150], braw2[150];
    braw[0] = braw2[0] = 0;
    for(int i = 1; i < n; i++)
    {
        double d = fwd[i] - fwd[i - 1];
        braw[i]  = d > 0 ?  d : 0;
        braw2[i] = d < 0 ? -d : 0;
    }

    double bulls[150], bears[150];
    _lwma(braw,  bulls, InpASHSmooth, n);
    _lwma(braw2, bears, InpASHSmooth, n);

    double b = bulls[n - 2];
    double r = bears[n - 2];

    if(b > r) return  1;
    if(r > b) return -1;
    return 0;
}

//===================================================================
//  SIGNAL 4 — WAE  (sustained: fires while histogram > dead zone)
//===================================================================
int SignalWAE()
{
    double fast1  = iMA(Symbol(), 0, InpWAEFast, 0, MODE_EMA, PRICE_CLOSE, 1);
    double fast2  = iMA(Symbol(), 0, InpWAEFast, 0, MODE_EMA, PRICE_CLOSE, 2);
    double slow1  = iMA(Symbol(), 0, InpWAESlow, 0, MODE_EMA, PRICE_CLOSE, 1);
    double slow2  = iMA(Symbol(), 0, InpWAESlow, 0, MODE_EMA, PRICE_CLOSE, 2);

    double macd1 = fast1 - slow1;
    double macd2 = fast2 - slow2;
    double t1    = (macd1 - macd2) * InpWAESens;

    double bb_upper1 = iBands(Symbol(), 0, InpWAEBBPer, InpWAEBBDev, 0, PRICE_CLOSE, 1, 1);
    double bb_lower1 = iBands(Symbol(), 0, InpWAEBBPer, InpWAEBBDev, 0, PRICE_CLOSE, 1, 2);

    double explosion = bb_upper1 - bb_lower1;

    double dead_zone = InpWAEDeadPip * Point;
    double up   = t1 > 0 ?  t1 : 0;
    double down = t1 < 0 ? -t1 : 0;

    if(up   > dead_zone && explosion > InpWAEExpPow) return  1;
    if(down > dead_zone && explosion > InpWAEExpPow) return -1;
    return 0;
}

//===================================================================
//  SIGNAL 5 — OsMA  (12/26/9, median price)
//===================================================================
int SignalOsMA()
{
    double osma = iOsMA(Symbol(), 0, InpOsMAFast, InpOsMASlow, InpOsMASig, PRICE_MEDIAN, 1);

    if(osma > 0) return  1;
    if(osma < 0) return -1;
    return 0;
}

//===================================================================
//  CONFIRMATION — all 4 non-ST indicators must agree with dir
//===================================================================
bool CheckOtherSignals(int dir)
{
    int s_vwap = SignalVWAP();
    int s_ash  = SignalASH();
    int s_wae  = SignalWAE();
    int s_osma = SignalOsMA();
    
    if(s_vwap == 0 || s_ash == 0 || s_wae == 0 || s_osma == 0)
        return false;
    
    PrintFormat("Confirmation | VWAP=%+d  ASH=%+d  WAE=%+d  OsMA=%+d  (need all=%+d)",
                s_vwap, s_ash, s_wae, s_osma, dir);
    return (s_vwap == dir && s_ash == dir && s_wae == dir && s_osma == dir);
}

//===================================================================
//  TRADE MANAGEMENT
//===================================================================
int CountMyTrades()
{
    int count = 0;
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        if(OrderSymbol() == Symbol() && OrderMagicNumber() == InpMagic && 
           (OrderType() == OP_BUY || OrderType() == OP_SELL))
            count++;
    }
    return count;
}

double CalcLotSize(double sl_dist)
{
    if(sl_dist <= 0) return 0;
    double balance   = AccountBalance();
    double risk_amt  = balance * InpRisk / 100.0;
    double tick_size = MarketInfo(Symbol(), MODE_TICKSIZE);
    double tick_val  = MarketInfo(Symbol(), MODE_TICKVALUE);
    double sl_ticks  = sl_dist / tick_size;
    double risk_lot  = sl_ticks * tick_val;
    
    if(risk_lot <= 0) return 0;

    double lots     = risk_amt / risk_lot;
    double lot_step = MarketInfo(Symbol(), MODE_LOTSTEP);
    lots = MathFloor(lots / lot_step) * lot_step;
    
    double lot_min = MarketInfo(Symbol(), MODE_MINLOT);
    double lot_max = MarketInfo(Symbol(), MODE_MAXLOT);
    lots = MathMax(lot_min, MathMin(lot_max, lots));
    
    return NormalizeDouble(lots, 2);
}

bool OpenTrade(int direction, double sl_dist, double tp_dist)
{
    if(MarketInfo(Symbol(), MODE_SPREAD) > InpMaxSpread)
    {
        Print("Spread too wide — skipping");
        return false;
    }

    int    digits  = (int)MarketInfo(Symbol(), MODE_DIGITS);
    double min_stp = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
    sl_dist = MathMax(sl_dist, min_stp + Point);
    tp_dist = MathMax(tp_dist, min_stp + Point);

    double lots = CalcLotSize(sl_dist);
    if(lots <= 0) { Print("Lot size = 0"); return false; }

    double price, sl, tp;
    int otype;

    if(direction == 1)
    {
        price = Ask;
        sl    = NormalizeDouble(price - sl_dist, digits);
        tp    = NormalizeDouble(price + tp_dist, digits);
        otype = OP_BUY;
    }
    else
    {
        price = Bid;
        sl    = NormalizeDouble(price + sl_dist, digits);
        tp    = NormalizeDouble(price - tp_dist, digits);
        otype = OP_SELL;
    }

    int ticket = OrderSend(Symbol(), otype, lots, price, 10, sl, tp, "BTCScalperEA", InpMagic, 0, 
                          direction == 1 ? Blue : Red);

    if(ticket > 0)
    {
        PrintFormat("Opened %s #%d  Lots:%.2f  Entry:%.2f  SL:%.2f  TP:%.2f",
                    direction == 1 ? "BUY" : "SELL", ticket, lots, price, sl, tp);

        g_tickets[g_nTracked]   = ticket;
        g_openTimes[g_nTracked] = TimeCurrent();
        g_nTracked++;
    }
    else
        PrintFormat("Order failed: %d", GetLastError());

    return (ticket > 0);
}

//===================================================================
//  RISK LIMIT CHECK
//===================================================================
bool CheckLimits()
{
    double balance = AccountBalance();

    double dd = (g_startBalance - balance) / g_startBalance * 100.0;
    if(dd >= InpMaxDD)
    {
        if(!g_stopped)
        {
            PrintFormat("MAX DRAWDOWN %.1f%% reached — bot permanently stopped.", dd);
            g_stopped = true;
        }
        return false;
    }

    double daily_pnl = (balance - g_dailyBalance) / g_dailyBalance * 100.0;
    if(daily_pnl <= -InpDailyLimit)
    {
        PrintFormat("Daily loss limit hit: %.1f%% today — skipping until tomorrow.", daily_pnl);
        return false;
    }

    return true;
}

//===================================================================
//  TRADE JOURNAL
//===================================================================
void InitJournal()
{
    string path = "BTCScalper_journal.csv";
    g_journal = FileOpen(path, FILE_READ | FILE_WRITE | FILE_CSV);
    
    if(g_journal == -1)
    {
        g_journal = FileOpen(path, FILE_WRITE | FILE_CSV);
        if(g_journal == -1) { Print("Cannot open journal file."); return; }
        
        FileWrite(g_journal,
                  "Open Time", "Close Time", "Symbol", "Direction",
                  "Entry", "SL", "TP", "Lots", "Risk ($)",
                  "Exit", "Gross P/L ($)", "Duration (min)", "Close Reason");
    }
}

void LogClosedTrade(int ticket, datetime open_time)
{
    if(g_journal == -1) return;
    if(!HistorySelect(open_time - 3600, TimeCurrent())) return;

    int total = HistoryTotal();
    double entry_price = 0, exit_price = 0, sl = 0, tp = 0, lots = 0, profit = 0;
    datetime open_dt = 0, close_dt = 0;
    string direction = "";

    for(int i = 0; i < total; i++)
    {
        int h_ticket = HistoryGetTicket(i);
        if(HistorySelectByTicket(h_ticket))
        {
            if(HistoryGetInteger(ORDER_TICKET) == ticket)
            {
                if(HistoryGetInteger(ORDER_TYPE) == OP_BUY)
                {
                    direction = "BUY";
                    entry_price = HistoryGetDouble(ORDER_PRICE_OPEN);
                    exit_price = HistoryGetDouble(ORDER_PRICE_CLOSE);
                    sl = HistoryGetDouble(ORDER_SL);
                    tp = HistoryGetDouble(ORDER_TP);
                    lots = HistoryGetDouble(ORDER_VOLUME);
                    profit = HistoryGetDouble(ORDER_PROFIT);
                    open_dt = (datetime)HistoryGetInteger(ORDER_OPEN_TIME);
                    close_dt = (datetime)HistoryGetInteger(ORDER_CLOSE_TIME);
                }
                else if(HistoryGetInteger(ORDER_TYPE) == OP_SELL)
                {
                    direction = "SELL";
                    entry_price = HistoryGetDouble(ORDER_PRICE_OPEN);
                    exit_price = HistoryGetDouble(ORDER_PRICE_CLOSE);
                    sl = HistoryGetDouble(ORDER_SL);
                    tp = HistoryGetDouble(ORDER_TP);
                    lots = HistoryGetDouble(ORDER_VOLUME);
                    profit = HistoryGetDouble(ORDER_PROFIT);
                    open_dt = (datetime)HistoryGetInteger(ORDER_OPEN_TIME);
                    close_dt = (datetime)HistoryGetInteger(ORDER_CLOSE_TIME);
                }
            }
        }
    }

    string reason = "Manual";
    double pt = Point * 5;
    if(direction == "BUY")
    {
        if(exit_price >= tp - pt) reason = "TP";
        else if(exit_price <= sl + pt) reason = "SL";
    }
    else
    {
        if(exit_price <= tp + pt) reason = "TP";
        else if(exit_price >= sl - pt) reason = "SL";
    }

    double duration = (close_dt - open_dt) / 60.0;
    double risk_amt = AccountBalance() * InpRisk / 100.0;

    FileWrite(g_journal,
              TimeToStr(open_dt,  TIME_DATE | TIME_MINUTES),
              TimeToStr(close_dt, TIME_DATE | TIME_MINUTES),
              Symbol(), direction,
              DoubleToStr(entry_price, Digits),
              DoubleToStr(sl,          Digits),
              DoubleToStr(tp,          Digits),
              DoubleToStr(lots,        2),
              DoubleToStr(risk_amt,    2),
              DoubleToStr(exit_price,  Digits),
              DoubleToStr(profit,      2),
              DoubleToStr(duration,    1),
              reason);

    PrintFormat("Journal | #%d %s %s  P/L: $%.2f  %.0fmin",
                ticket, direction, reason, profit, duration);
}

//===================================================================
//  MONITOR CLOSED POSITIONS
//===================================================================
void CheckClosedPositions()
{
    for(int i = g_nTracked - 1; i >= 0; i--)
    {
        bool still_open = false;
        for(int j = 0; j < OrdersTotal(); j++)
        {
            if(!OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) continue;
            if(OrderTicket() == g_tickets[i]) { still_open = true; break; }
        }

        if(!still_open)
        {
            LogClosedTrade(g_tickets[i], g_openTimes[i]);
            g_lastTradeClose = TimeCurrent();

            for(int k = i; k < g_nTracked - 1; k++)
            {
                g_tickets[k]   = g_tickets[k + 1];
                g_openTimes[k] = g_openTimes[k + 1];
            }
            g_nTracked--;
        }
    }
}

//===================================================================
//  EA LIFECYCLE
//===================================================================
int init()
{
    g_startBalance  = AccountBalance();
    g_dailyBalance  = g_startBalance;
    g_lastBar       = 0;
    g_lastDay       = -1;
    g_stopped       = false;
    g_nTracked      = 0;
    g_pendingCross  = false;
    g_pendingDir    = 0;
    g_pendingBarTime= 0;

    InitJournal();

    PrintFormat("BTCScalper EA started | Balance: $%.2f | Risk: %.1f%% | Cooldown: %dmin | H1filter: %s",
                g_startBalance, InpRisk, InpCooldownMin, InpUseH1Filter ? "ON" : "OFF");
    return(0);
}

int deinit()
{
    if(g_journal != -1) FileClose(g_journal);
    Print("BTCScalper EA stopped.");
    return(0);
}

int start()
{
    CheckClosedPositions();

    datetime current_bar = iTime(Symbol(), 0, 0);
    if(current_bar == g_lastBar) return(0);
    g_lastBar = current_bar;

    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    if(dt.day != g_lastDay)
    {
        g_dailyBalance = AccountBalance();
        g_lastDay      = dt.day;
        PrintFormat("New day — daily limit reset. Balance: $%.2f", g_dailyBalance);
    }

    if(g_stopped) { Print("Bot halted — max drawdown reached."); return(0); }
    if(!CheckLimits())  return(0);
    if(CountMyTrades() >= InpMaxTrades) { Print("Max trades open."); return(0); }

    if(g_lastTradeClose > 0)
    {
        int elapsed = (int)(TimeCurrent() - g_lastTradeClose) / 60;
        if(elapsed < InpCooldownMin)
        {
            PrintFormat("Cooldown: %d / %d min elapsed — waiting.", elapsed, InpCooldownMin);
            return(0);
        }
    }

    // ── Supertrend crossover detection ──────────────────────────────
    int dir_prev;
    int dir_curr  = SupertrendState(dir_prev);
    bool new_cross = (dir_curr != 0 && dir_prev != 0 && dir_curr != dir_prev);

    // Any new crossover cancels a stale pending setup
    if(new_cross && g_pendingCross)
    {
        Print("New ST crossover — cancelling previous pending setup.");
        g_pendingCross = false;
    }

    int active_dir = 0;

    // ── Pending window: bar+1 after a crossover ──────────────────────
    if(g_pendingCross)
    {
        datetime bar2_time = iTime(Symbol(), 0, 2);
        if(bar2_time == g_pendingBarTime)
        {
            PrintFormat("Crossover window bar+1 (dir=%+d) — checking confirmation.", g_pendingDir);
            if(CheckOtherSignals(g_pendingDir))
                active_dir = g_pendingDir;
            else
                Print("Window closed — indicators still not aligned. Waiting for next ST crossover.");
        }
        else
        {
            Print("Pending crossover timed out (>1 bar elapsed).");
        }
        g_pendingCross = false;
    }
    // ── New crossover ────────────────────────────────────────────────
    else if(new_cross)
    {
        PrintFormat("ST crossover: %s", dir_curr == 1 ? "BUY" : "SELL");

        // H1 trend filter is checked once at crossover time
        if(InpUseH1Filter)
        {
            int h1 = H1TrendFilter();
            if(h1 != 0 && h1 != dir_curr)
            {
                PrintFormat("H1 trend (%+d) disagrees with crossover (%+d) — skipping.", h1, dir_curr);
                return(0);
            }
        }

        if(CheckOtherSignals(dir_curr))
        {
            active_dir = dir_curr;
        }
        else
        {
            g_pendingCross   = true;
            g_pendingDir     = dir_curr;
            g_pendingBarTime = iTime(Symbol(), 0, 1);
            Print("Indicators not aligned on crossover bar — waiting 1 more bar.");
        }
    }
    else
    {
        Print("No ST crossover.");
    }

    if(active_dir == 0) return(0);

    // ── Enter trade ──────────────────────────────────────────────────
    double atr = iATR(Symbol(), 0, InpATRPeriod, 1);
    if(atr <= 0) return(0);

    double sl_dist = NormalizeDouble(InpSLMult * atr, Digits);
    double tp_dist = NormalizeDouble(InpTPMult * atr, Digits);

    OpenTrade(active_dir, sl_dist, tp_dist);
    
    return(0);
}
