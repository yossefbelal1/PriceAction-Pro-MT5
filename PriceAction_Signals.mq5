//+------------------------------------------------------------------+
//|                                         PriceAction_Signals.mq5  |
//|                                  Copyright 2026, Antigravity AI  |
//|               Visual Indicator for MT5: Pin Bar, Inside Bar, Fakey|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Antigravity AI"
#property link      "https://github.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   2

//--- Plot 1: Bullish Signals (Arrow Up)
#property indicator_label1  "Bullish Price Action"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLimeGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- Plot 2: Bearish Signals (Arrow Down)
#property indicator_label2  "Bearish Price Action"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrCrimson
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- Inputs
input group "=== Pattern Selection ==="
input bool   InpShowPinBar       = true;   // Show Pin Bar Signals
input bool   InpShowInsideBar    = true;   // Show Inside Bar Patterns
input bool   InpShowFakey        = true;   // Show Fakey False Breaks

input group "=== Pin Bar Settings ==="
input double InpPinMinWickRatio  = 0.667;  // Min Wick Ratio (2/3)
input double InpPinMaxBodyRatio  = 0.333;  // Max Body Ratio (1/3)
input int    InpPinProtrudeBars  = 2;      // Protrusion Lookback

input group "=== Alerts ==="
input bool   InpEnableAlerts     = true;   // Enable Popup / Sound Alert
input bool   InpPushNotifications= false;  // Send Notification to Mobile MT5

//--- Indicator Buffers
double BufferBullish[];
double BufferBearish[];
double BufferCalculations[];
double BufferTrend[];

datetime g_lastAlertTime = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, BufferBullish, INDICATOR_DATA);
   SetIndexBuffer(1, BufferBearish, INDICATOR_DATA);
   SetIndexBuffer(2, BufferCalculations, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, BufferTrend, INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(0, PLOT_ARROW, 233); // Wingdings Arrow Up
   PlotIndexSetInteger(1, PLOT_ARROW, 234); // Wingdings Arrow Down

   ArrayInitialize(BufferBullish, EMPTY_VALUE);
   ArrayInitialize(BufferBearish, EMPTY_VALUE);

   IndicatorSetString(INDICATOR_SHORTNAME, "Price Action Master (Nial Fuller Rules)");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
   if(rates_total < 10) return 0;

   int start = prev_calculated - 1;
   if(start < 3) start = 3;

   double pipSize = (_Digits == 3 || _Digits == 5) ? _Point * 10.0 : _Point;

   for(int i = start; i < rates_total - 1; i++)
   {
      BufferBullish[i] = EMPTY_VALUE;
      BufferBearish[i] = EMPTY_VALUE;

      double range = high[i] - low[i];
      if(range <= 0.0) continue;

      double body = MathAbs(close[i] - open[i]);
      double upperWick = high[i] - MathMax(open[i], close[i]);
      double lowerWick = MathMin(open[i], close[i]) - low[i];

      // 1. PIN BAR CHECK
      if(InpShowPinBar && (body / range) <= InpPinMaxBodyRatio)
      {
         bool protrudesLow = true;
         bool protrudesHigh = true;
         for(int b = 1; b <= InpPinProtrudeBars; b++)
         {
            if((i - b) >= 0)
            {
               if(low[i] >= low[i - b])   protrudesLow = false;
               if(high[i] <= high[i - b]) protrudesHigh = false;
            }
         }

         if((lowerWick / range) >= InpPinMinWickRatio && protrudesLow)
         {
            BufferBullish[i] = low[i] - (5.0 * pipSize);
            TriggerAlert("Bullish Pin Bar", time[i]);
         }
         else if((upperWick / range) >= InpPinMinWickRatio && protrudesHigh)
         {
            BufferBearish[i] = high[i] + (5.0 * pipSize);
            TriggerAlert("Bearish Pin Bar", time[i]);
         }
      }

      // 2. FAKEY CHECK (i = False break, i-1 = Inside Bar, i-2 = Mother Bar)
      if(InpShowFakey && (i >= 2))
      {
         bool isInsideBar = (high[i - 1] <= high[i - 2] && low[i - 1] >= low[i - 2]);
         if(isInsideBar)
         {
            // Bullish Fakey: Bar i dipped below inside bar low, then closed up
            if(low[i] < low[i - 1] && close[i] > low[i - 1])
            {
               BufferBullish[i] = low[i] - (8.0 * pipSize);
               TriggerAlert("Bullish Fakey", time[i]);
            }
            // Bearish Fakey: Bar i poked above inside bar high, then closed down
            else if(high[i] > high[i - 1] && close[i] < high[i - 1])
            {
               BufferBearish[i] = high[i] + (8.0 * pipSize);
               TriggerAlert("Bearish Fakey", time[i]);
            }
         }
      }
   }

   return rates_total;
}

//+------------------------------------------------------------------+
//| Trigger alerts without duplicate noise                           |
//+------------------------------------------------------------------+
void TriggerAlert(string patternName, datetime barTime)
{
   if(!InpEnableAlerts) return;
   if(barTime == g_lastAlertTime) return;

   g_lastAlertTime = barTime;
   string msg = StringFormat("[%s] %s on %s, Period: %s", 
                             TimeToString(barTime, TIME_MINUTES), 
                             patternName, _Symbol, EnumToString(_Period));

   Alert(msg);
   if(InpPushNotifications) SendNotification(msg);
}
//+------------------------------------------------------------------+
