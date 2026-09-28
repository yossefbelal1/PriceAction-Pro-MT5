//+------------------------------------------------------------------+
//|                                         PriceAction_Signals.mq5  |
//|                                  Copyright 2026, Antigravity AI  |
//|                 Nial Fuller Price Action Visual Signal Indicator |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Antigravity AI"
#property link      "https://github.com/yossefbelal1/PriceAction-Pro-MT5"
#property version   "4.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

//--- Plot 1: Bullish Price Action Signals (Arrow Up)
#property indicator_label1  "Bullish Signal"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLimeGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- Plot 2: Bearish Price Action Signals (Arrow Down)
#property indicator_label2  "Bearish Signal"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrCrimson
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- Input Parameters
input group "=== Pattern Selection ==="
input bool   InpShowPinBar         = true;   // Show Pin Bar Signals (PDF Pages 53-63)
input bool   InpShowInsideBar      = true;   // Show Inside Bar Patterns (PDF Pages 71-86)
input bool   InpShowFakey          = true;   // Show Fakey False Breaks (PDF Pages 87-97)

input group "=== Mathematical Ratios (PDF Rules) ==="
input double InpPinMinWickRatio    = 0.667;  // Minimum Tail Ratio (>= 2/3 = 66.7%)
input double InpPinMaxBodyRatio    = 0.333;  // Maximum Real Body Ratio (<= 1/3 = 33.3%)
input int    InpPinProtrudeLookback= 3;      // Protrusion Lookback Bars
input double InpFakeyMinBreakPoints= 30.0;   // Minimum Obvious Fakey False-Break (Points)

input group "=== Alert Settings ==="
input bool   InpEnableAlerts       = true;   // Enable Popup / Audio Alerts on Bar Close
input bool   InpPushNotifications  = false;  // Send Notification to Mobile MT5 App

//--- Indicator Buffers
double BufferBullish[];
double BufferBearish[];

datetime g_lastAlertTime = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, BufferBullish, INDICATOR_DATA);
   SetIndexBuffer(1, BufferBearish, INDICATOR_DATA);

   PlotIndexSetInteger(0, PLOT_ARROW, 233); // Wingdings Up Arrow
   PlotIndexSetInteger(1, PLOT_ARROW, 234); // Wingdings Down Arrow

   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   ArrayInitialize(BufferBullish, EMPTY_VALUE);
   ArrayInitialize(BufferBearish, EMPTY_VALUE);

   IndicatorSetString(INDICATOR_SHORTNAME, "Price Action Master Signals (PDF Exact)");
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

   // Explicit array orientation (non-series = index 0 is oldest bar)
   ArraySetAsSeries(time, false);
   ArraySetAsSeries(open, false);
   ArraySetAsSeries(high, false);
   ArraySetAsSeries(low, false);
   ArraySetAsSeries(close, false);
   ArraySetAsSeries(tick_volume, false);
   ArraySetAsSeries(volume, false);
   ArraySetAsSeries(spread, false);
   ArraySetAsSeries(BufferBullish, false);
   ArraySetAsSeries(BufferBearish, false);

   // Start calculation from the last calculated bar or from bar 5
   int start = prev_calculated - 1;
   if(start < 5) start = 5;

   double pipSize = (_Digits == 3 || _Digits == 5) ? _Point * 10.0 : _Point;
   double minFakeyBreak = InpFakeyMinBreakPoints * _Point;

   // Calculate up to the last closed bar (rates_total - 2)
   // Bar index (rates_total - 1) is currently forming and MUST NOT produce historical signals
   for(int i = start; i <= rates_total - 2; i++)
   {
      BufferBullish[i] = EMPTY_VALUE;
      BufferBearish[i] = EMPTY_VALUE;

      double range = high[i] - low[i];
      if(range <= 0.0) continue;

      double body      = MathAbs(close[i] - open[i]);
      double upperWick = high[i] - MathMax(open[i], close[i]);
      double lowerWick = MathMin(open[i], close[i]) - low[i];

      bool bullSignal = false;
      bool bearSignal = false;
      string signalName = "";

      // 1. PIN BAR PATTERN (PDF Pages 53-63)
      if(InpShowPinBar && (body / range) <= InpPinMaxBodyRatio)
      {
         bool protrudesLow  = true;
         bool protrudesHigh = true;

         for(int b = 1; b <= InpPinProtrudeLookback; b++)
         {
            if((i - b) >= 0)
            {
               if(low[i] >= low[i - b])   protrudesLow  = false;
               if(high[i] <= high[i - b]) protrudesHigh = false;
            }
         }

         if((lowerWick / range) >= InpPinMinWickRatio && protrudesLow)
         {
            bullSignal = true;
            signalName = "Bullish Pin Bar";
         }
         else if((upperWick / range) >= InpPinMinWickRatio && protrudesHigh)
         {
            bearSignal = true;
            signalName = "Bearish Pin Bar";
         }
      }

      // 2. FAKEY FALSE-BREAK PATTERN (PDF Pages 87-97)
      if(!bullSignal && !bearSignal && InpShowFakey && (i >= 2))
      {
         // Bar i-1 was an inside bar to Bar i-2
         bool wasInsideBar = (high[i - 1] <= high[i - 2] && low[i - 1] >= low[i - 2]);
         if(wasInsideBar)
         {
            // Bullish Fakey: Bar i pierced below Inside Bar low by minBreak, closed back above
            if(low[i] <= (low[i - 1] - minFakeyBreak) && close[i] > low[i - 1])
            {
               bullSignal = true;
               signalName = "Bullish Fakey";
            }
            // Bearish Fakey: Bar i pierced above Inside Bar high by minBreak, closed back below
            else if(high[i] >= (high[i - 1] + minFakeyBreak) && close[i] < high[i - 1])
            {
               bearSignal = true;
               signalName = "Bearish Fakey";
            }
         }
      }

      // 3. INSIDE BAR PATTERN (PDF Pages 71-86)
      if(!bullSignal && !bearSignal && InpShowInsideBar && (i >= 1))
      {
         if(high[i] <= high[i - 1] && low[i] >= low[i - 1])
         {
            // Plot neutral markers on mother/inside bar range
            BufferBullish[i] = low[i] - (3.0 * pipSize);
            BufferBearish[i] = high[i] + (3.0 * pipSize);
            continue;
         }
      }

      // Assign Buffer Values
      if(bullSignal)
      {
         BufferBullish[i] = low[i] - (5.0 * pipSize);
         // ONLY trigger live alerts on the bar that JUST CLOSED in real-time (never during backfill)
         if(prev_calculated > 0 && i == (rates_total - 2))
         {
            TriggerLiveAlert(signalName, time[i]);
         }
      }
      else if(bearSignal)
      {
         BufferBearish[i] = high[i] + (5.0 * pipSize);
         if(prev_calculated > 0 && i == (rates_total - 2))
         {
            TriggerLiveAlert(signalName, time[i]);
         }
      }
   }

   return rates_total;
}

//+------------------------------------------------------------------+
//| Trigger live alerts strictly once per newly confirmed candle     |
//+------------------------------------------------------------------+
void TriggerLiveAlert(string patternName, datetime barTime)
{
   if(!InpEnableAlerts) return;
   if(barTime <= g_lastAlertTime) return;

   g_lastAlertTime = barTime;
   string msg = StringFormat("[%s] Confirmed %s on %s (%s)", 
                             TimeToString(barTime, TIME_MINUTES), 
                             patternName, _Symbol, EnumToString(_Period));

   Alert(msg);
   if(InpPushNotifications) SendNotification(msg);
}
//+------------------------------------------------------------------+
