//+------------------------------------------------------------------+
//|                    Multi-TimeZone Digital Clock                 |
//|                           v1.0                                   |
//|                      For MT4 Platform                            |
//+------------------------------------------------------------------+
#property copyright   "MrsCTT"
#property link        "https://github.com/MrsCTT"
#property version     "1.0"
#property strict
#property description "Digital Clock displaying current time in multiple time zones"

//+------------------------------------------------------------------+
//| Input Parameters
//+------------------------------------------------------------------+

input bool ShowClock = true;
input int ClockX = 10;
input int ClockY = 10;
input int ClockWidth = 300;
input color ClockBackground = clrBlack;
input color ClockBorderColor = clrWhite;
input color ClockTextColor = clrWhite;
input color TimeTextColor = clrYellow;
input int FontSize = 11;

// TimeZone Settings
input bool ShowGMT = true;
input bool ShowEST = true;
input bool ShowCST = true;
input bool ShowMST = true;
input bool ShowPST = true;
input bool ShowJST = true;
input bool ShowCET = true;
input bool ShowAUST = true;

//+------------------------------------------------------------------+
//| Global Variables
//+------------------------------------------------------------------+

string ClockPanelName = "Clock_Panel";

// TimeZone offset from GMT (in hours)
int GMT_Offset = 0;      // UTC/GMT
int EST_Offset = -5;     // Eastern Standard Time
int CST_Offset = -6;     // Central Standard Time
int MST_Offset = -7;     // Mountain Standard Time
int PST_Offset = -8;     // Pacific Standard Time
int JST_Offset = 9;      // Japan Standard Time
int CET_Offset = 1;      // Central European Time
int AUST_Offset = 10;    // Australian Eastern Time

// Label names for each timezone
string GMTLabelName = "GMT_Label";
string ESTLabelName = "EST_Label";
string CSTLabelName = "CST_Label";
string MSTLabelName = "MST_Label";
string PSTLabelName = "PST_Label";
string JSTLabelName = "JST_Label";
string CETLabelName = "CET_Label";
string AUSTLabelName = "AUST_Label";

string GMTTimeName = "GMT_Time";
string ESTTimeName = "EST_Time";
string CSTTimeName = "CST_Time";
string MSTTimeName = "MST_Time";
string PSTTimeName = "PST_Time";
string JSTTimeName = "JST_Time";
string CETTimeName = "CET_Time";
string AUSTTimeName = "AUST_Time";

//+------------------------------------------------------------------+
//| Expert Initialization Function
//+------------------------------------------------------------------+

int OnInit()
{
    if(!ShowClock)
        return(INIT_SUCCEEDED);
    
    // Create clock panel background
    CreateClockPanel();
    
    // Create timezone labels and time displays
    if(ShowGMT)   CreateTimeZoneDisplay(GMTLabelName, GMTTimeName, "GMT/UTC", 30);
    if(ShowEST)   CreateTimeZoneDisplay(ESTLabelName, ESTTimeName, "EST (New York)", 60);
    if(ShowCST)   CreateTimeZoneDisplay(CSTLabelName, CSTTimeName, "CST (Chicago)", 90);
    if(ShowMST)   CreateTimeZoneDisplay(MSTLabelName, MSTTimeName, "MST (Denver)", 120);
    if(ShowPST)   CreateTimeZoneDisplay(PSTLabelName, PSTTimeName, "PST (LA)", 150);
    if(ShowJST)   CreateTimeZoneDisplay(JSTLabelName, JSTTimeName, "JST (Tokyo)", 180);
    if(ShowCET)   CreateTimeZoneDisplay(CETLabelName, CETTimeName, "CET (Europe)", 210);
    if(ShowAUST)  CreateTimeZoneDisplay(AUSTLabelName, AUSTTimeName, "AUST (Sydney)", 240);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert Start Function
//+------------------------------------------------------------------+

void OnTick()
{
    if(!ShowClock)
        return;
    
    // Update all timezone displays
    if(ShowGMT)   UpdateTimeDisplay(GMTTimeName, GMT_Offset);
    if(ShowEST)   UpdateTimeDisplay(ESTTimeName, EST_Offset);
    if(ShowCST)   UpdateTimeDisplay(CSTTimeName, CST_Offset);
    if(ShowMST)   UpdateTimeDisplay(MSTTimeName, MST_Offset);
    if(ShowPST)   UpdateTimeDisplay(PSTTimeName, PST_Offset);
    if(ShowJST)   UpdateTimeDisplay(JSTTimeName, JST_Offset);
    if(ShowCET)   UpdateTimeDisplay(CETTimeName, CET_Offset);
    if(ShowAUST)  UpdateTimeDisplay(AUSTTimeName, AUST_Offset);
}

//+------------------------------------------------------------------+
//| Expert Deinitialization Function
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
    if(!ShowClock)
        return;
    
    // Delete all created objects
    ObjectDelete(0, ClockPanelName);
    ObjectDelete(0, GMTLabelName);
    ObjectDelete(0, GMTTimeName);
    ObjectDelete(0, ESTLabelName);
    ObjectDelete(0, ESTTimeName);
    ObjectDelete(0, CSTLabelName);
    ObjectDelete(0, CSTTimeName);
    ObjectDelete(0, MSTLabelName);
    ObjectDelete(0, MSTTimeName);
    ObjectDelete(0, PSTLabelName);
    ObjectDelete(0, PSTTimeName);
    ObjectDelete(0, JSTLabelName);
    ObjectDelete(0, JSTTimeName);
    ObjectDelete(0, CETLabelName);
    ObjectDelete(0, CETTimeName);
    ObjectDelete(0, AUSTLabelName);
    ObjectDelete(0, AUSTTimeName);
}

//+------------------------------------------------------------------+
//| Create Clock Panel
//+------------------------------------------------------------------+

void CreateClockPanel()
{
    // Calculate panel height based on active timezones
    int activeZones = 0;
    if(ShowGMT)   activeZones++;
    if(ShowEST)   activeZones++;
    if(ShowCST)   activeZones++;
    if(ShowMST)   activeZones++;
    if(ShowPST)   activeZones++;
    if(ShowJST)   activeZones++;
    if(ShowCET)   activeZones++;
    if(ShowAUST)  activeZones++;
    
    int panelHeight = 40 + (activeZones * 30);
    
    // Create background rectangle
    ObjectCreate(0, ClockPanelName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, ClockPanelName, OBJPROP_XDISTANCE, ClockX);
    ObjectSetInteger(0, ClockPanelName, OBJPROP_YDISTANCE, ClockY);
    ObjectSetInteger(0, ClockPanelName, OBJPROP_XSIZE, ClockWidth);
    ObjectSetInteger(0, ClockPanelName, OBJPROP_YSIZE, panelHeight);
    ObjectSetInteger(0, ClockPanelName, OBJPROP_BGCOLOR, ClockBackground);
    ObjectSetInteger(0, ClockPanelName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, ClockPanelName, OBJPROP_BORDER_COLOR, ClockBorderColor);
    ObjectSetInteger(0, ClockPanelName, OBJPROP_ZORDER, 0);
    
    // Create title
    string titleName = "Clock_Title";
    ObjectCreate(0, titleName, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, titleName, OBJPROP_XDISTANCE, ClockX + 10);
    ObjectSetInteger(0, titleName, OBJPROP_YDISTANCE, ClockY + 8);
    ObjectSetString(0, titleName, OBJPROP_TEXT, "WORLD CLOCK");
    ObjectSetInteger(0, titleName, OBJPROP_FONTSIZE, FontSize + 2);
    ObjectSetInteger(0, titleName, OBJPROP_COLOR, TimeTextColor);
    ObjectSetInteger(0, titleName, OBJPROP_ZORDER, 1);
}

//+------------------------------------------------------------------+
//| Create TimeZone Display
//+------------------------------------------------------------------+

void CreateTimeZoneDisplay(string labelName, string timeName, string zoneLabel, int yOffset)
{
    // Create timezone label
    ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, ClockX + 10);
    ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, ClockY + yOffset);
    ObjectSetString(0, labelName, OBJPROP_TEXT, zoneLabel + ":");
    ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, FontSize);
    ObjectSetInteger(0, labelName, OBJPROP_COLOR, ClockTextColor);
    ObjectSetInteger(0, labelName, OBJPROP_ZORDER, 1);
    
    // Create time display
    ObjectCreate(0, timeName, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, timeName, OBJPROP_XDISTANCE, ClockX + 150);
    ObjectSetInteger(0, timeName, OBJPROP_YDISTANCE, ClockY + yOffset);
    ObjectSetString(0, timeName, OBJPROP_TEXT, "00:00:00");
    ObjectSetInteger(0, timeName, OBJPROP_FONTSIZE, FontSize);
    ObjectSetInteger(0, timeName, OBJPROP_COLOR, TimeTextColor);
    ObjectSetInteger(0, timeName, OBJPROP_ZORDER, 1);
}

//+------------------------------------------------------------------+
//| Update Time Display for TimeZone
//+------------------------------------------------------------------+

void UpdateTimeDisplay(string timeLabelName, int timezoneOffset)
{
    // Get current server time
    datetime currentTime = TimeCurrent();
    
    // Calculate timezone time by adding offset
    datetime tzTime = currentTime + (timezoneOffset * 3600);
    
    // Extract time components
    int hour = GetHour(tzTime);
    int minute = GetMinute(tzTime);
    int second = GetSecond(tzTime);
    
    // Format time string HH:MM:SS
    string timeString = FormatTimeString(hour, minute, second);
    
    // Update the label
    ObjectSetString(0, timeLabelName, OBJPROP_TEXT, timeString);
}

//+------------------------------------------------------------------+
//| Format Time String HH:MM:SS
//+------------------------------------------------------------------+

string FormatTimeString(int hour, int minute, int second)
{
    string result = "";
    
    // Hour
    if(hour < 10)
        result += "0";
    result += IntegerToString(hour);
    
    result += ":";
    
    // Minute
    if(minute < 10)
        result += "0";
    result += IntegerToString(minute);
    
    result += ":";
    
    // Second
    if(second < 10)
        result += "0";
    result += IntegerToString(second);
    
    return result;
}

//+------------------------------------------------------------------+
//| Get Hour from datetime
//+------------------------------------------------------------------+

int GetHour(datetime time)
{
    int hour = (int)((time / 3600) % 24);
    if(hour < 0)
        hour += 24;
    return hour;
}

//+------------------------------------------------------------------+
//| Get Minute from datetime
//+------------------------------------------------------------------+

int GetMinute(datetime time)
{
    return (int)((time / 60) % 60);
}

//+------------------------------------------------------------------+
//| Get Second from datetime
//+------------------------------------------------------------------+

int GetSecond(datetime time)
{
    return (int)(time % 60);
}

//+------------------------------------------------------------------+
//| End of Expert Advisor
//+------------------------------------------------------------------+
