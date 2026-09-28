//+------------------------------------------------------------------+
//|                                           PriceAction_Pro_MT5.mq5 |
//|                                  Copyright 2026, Antigravity AI  |
//|               The Complete Institutional Price Action + VSA + POI|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Antigravity AI"
#property link      "https://github.com"
#property version   "2.00"
#property description "Complete Institutional Trading System:"
#property description "1. Multi-Timeframe POI (Order Blocks / Imbalance / Supply & Demand)"
#property description "2. Volume Spread Analysis (VSA: Stopping Volume, Climax, No-Supply/Demand)"
#property description "3. Naked Price Action Triggers (Pin Bar with 50% Limit, Inside Bar, Fakey)"
#property description "4. Dynamic Risk & Money Management (R:R, Break-Even, Trailing Stop)"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- Enums
enum ENUM_ENTRY_MODE_PINBAR
{
   ENTRY_MARKET_ON_CLOSE = 0, // Market Entry (On Candle Close)
   ENTRY_LIMIT_50_RETRACE = 1  // 50% Limit Entry (Page 62 of Book)
};

enum ENUM_TREND_FILTER
{
   TREND_NONE = 0,            // No Trend Filter
   TREND_CURRENT_TF_EMA = 1,  // EMA Filter on Current Timeframe
   TREND_HIGHER_TF_EMA = 2    // EMA Filter on Higher Timeframe
};

enum ENUM_LOT_MODE
{
   LOT_FIXED = 0,             // Fixed Lot Size
   LOT_RISK_PERCENT = 1       // Dynamic Risk Percentage per Trade
};

enum ENUM_VSA_MODE
{
   VSA_DISABLED = 0,          // Disable VSA Filter
   VSA_CLIMAX_ONLY = 1,       // Require Stopping / Climactic Volume (Institutional Footprint)
   VSA_FULL_ENGINE = 2        // Full VSA (Climax or Low-Volume Test Confirmation)
};

//--- Structure for Multi-Timeframe POI (Points of Interest)
struct SPointOfInterest
{
   double   top;
   double   bottom;
   datetime time;
   bool     isBullish;   // true = Demand / Bullish OB, false = Supply / Bearish OB
   bool     isMitigated; // true if price already tapped or broken through
   string   objName;
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
//--- 1. Multi-Timeframe POI Engine
input group "=== 1. Multi-Timeframe POI (Supply & Demand / OB) ==="
input bool             InpUseHTF_POI        = true;         // Enable HTF Points of Interest (POI)
input ENUM_TIMEFRAMES  InpPOITimeframe      = PERIOD_D1;    // POI Higher Timeframe (e.g. Daily / H4)
input int              InpPOILookbackBars   = 60;           // Lookback Bars on HTF for POI Detection
input double           InpMinImbalanceAtr   = 1.2;          // Min Impulse Imbalance Multiplier (x HTF ATR)
input bool             InpDrawPOIZones      = true;         // Draw POI Boxes on Chart
input color            InpDemandColor       = clrMediumSeaGreen; // Demand Zone Color
input color            InpSupplyColor       = clrIndianRed;      // Supply Zone Color

//--- 2. Volume Spread Analysis (VSA) Engine
input group "=== 2. Volume Spread Analysis (VSA) Engine ==="
input ENUM_VSA_MODE    InpVsaMode           = VSA_FULL_ENGINE; // VSA Confirmation Mode
input int              InpVolumeMaPeriod    = 20;           // Volume Moving Average Period
input double           InpHighVolMultiplier = 1.6;          // High Volume Threshold (x Average Volume)
input double           InpLowVolMultiplier  = 0.8;          // Low Volume Test Threshold (x Average Volume)

//--- 3. Price Action Setups (From the 97-Page Book)
input group "=== 3. Price Action Setups (Book Rules) ==="
input bool             InpEnablePinBar      = true;         // Enable Pin Bar Strategy
input ENUM_ENTRY_MODE_PINBAR InpPinEntryMode= ENTRY_LIMIT_50_RETRACE; // Pin Bar Entry Mode
input double           InpPinMinWickRatio   = 0.667;        // Min Wick Ratio (Default: 2/3 = 66.7%)
input double           InpPinMaxBodyRatio   = 0.333;        // Max Body Ratio (Default: 1/3 = 33.3%)
input int              InpPinProtrudeBars   = 2;            // Wick Protrusion Lookback
input int              InpLimitOrderExpiryBars = 6;         // 50% Limit Expiry (Bars to cancel)
input bool             InpEnableInsideBar   = true;         // Enable Inside Bar Breakout
input double           InpIBBreakoutBufferPips = 1.0;       // Buffer Above/Below Mother Bar (Pips)
input int              InpIBOrderExpiryBars = 8;            // Inside Bar Order Expiry (Bars)
input bool             InpEnableFakey       = true;         // Enable Fakey Setup (False Break)

//--- 4. Trend & Momentum (RSI) Confluence
input group "=== 4. Trend & RSI Confluence ==="
input ENUM_TREND_FILTER InpTrendFilter      = TREND_CURRENT_TF_EMA; // Trend Filter Mode
input ENUM_TIMEFRAMES  InpHTFTrendTimeframe = PERIOD_H4;    // Trend Filter Higher Timeframe
input int              InpFastEmaPeriod     = 21;           // Fast EMA Period
input int              InpSlowEmaPeriod     = 50;           // Slow EMA Period
input bool             InpUseRsiFilter      = true;         // Use RSI Filter
input int              InpRsiPeriod         = 14;           // RSI Period
input double           InpRsiOverbought     = 70.0;         // RSI Overbought Level
input double           InpRsiOversold       = 30.0;         // RSI Oversold Level

//--- 5. Risk & Money Management
input group "=== 5. Risk & Money Management ==="
input ENUM_LOT_MODE    InpLotMode           = LOT_RISK_PERCENT; // Lot Sizing Mode
input double           InpRiskPercent       = 1.0;          // Risk Percentage per Trade (% of Balance)
input double           InpFixedLotSize      = 0.10;         // Fixed Lot Size (if Fixed mode)
input double           InpRiskRewardRatio   = 2.5;          // Take Profit Risk:Reward Multiple
input double           InpStopLossBufferPips= 2.0;          // Extra SL Buffer beyond wick/high/low (Pips)
input bool             InpUseBreakEven      = true;         // Move SL to Break-Even at 1:1 R:R
input bool             InpUseTrailingStop   = false;        // Use Trailing Stop
input double           InpTrailingStartRR   = 1.5;          // Trailing Start at R:R Multiple
input double           InpTrailingDistanceRR= 1.0;          // Trailing Distance in R:R Multiple

//--- 6. System & Chart Settings
input group "=== 6. System Settings ==="
input ulong            InpMagicNumber       = 20260929;     // EA Magic Number
input int              InpSlippagePips      = 3;            // Max Slippage (Pips)
input bool             InpDrawVisualSignals = true;         // Draw Arrows & Labels on Chart

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                 |
//+------------------------------------------------------------------+
CTrade            m_trade;
CPositionInfo     m_position;
COrderInfo        m_order;

int               m_handleFastEma   = INVALID_HANDLE;
int               m_handleSlowEma   = INVALID_HANDLE;
int               m_handleRsi       = INVALID_HANDLE;
int               m_handleHTF_ATR   = INVALID_HANDLE;

datetime          m_lastBarTime     = 0;
datetime          m_lastPoiScanTime = 0;
double            m_pipSize         = 0.0;
double            m_point           = 0.0;

SPointOfInterest  m_poiList[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   m_trade.SetExpertMagicNumber(InpMagicNumber);
   m_trade.SetDeviationInPoints(InpSlippagePips * 10);
   m_trade.SetTypeFilling(ORDER_FILLING_FOK);

   m_point = _Point;
   m_pipSize = (_Digits == 3 || _Digits == 5) ? _Point * 10.0 : _Point;

   // 1. Initialize EMA Handles
   ENUM_TIMEFRAMES trendTf = (InpTrendFilter == TREND_HIGHER_TF_EMA) ? InpHTFTrendTimeframe : _Period;
   if(InpTrendFilter != TREND_NONE)
   {
      m_handleFastEma = iMA(_Symbol, trendTf, InpFastEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      m_handleSlowEma = iMA(_Symbol, trendTf, InpSlowEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   }

   // 2. Initialize RSI Handle
   if(InpUseRsiFilter)
   {
      m_handleRsi = iRSI(_Symbol, _Period, InpRsiPeriod, PRICE_CLOSE);
   }

   // 3. Initialize HTF ATR Handle (for POI Imbalance calculation)
   if(InpUseHTF_POI)
   {
      m_handleHTF_ATR = iATR(_Symbol, InpPOITimeframe, 14);
   }

   // Initial scan for Points of Interest
   if(InpUseHTF_POI)
   {
      ScanHTF_POIs();
   }

   Print("PriceAction_Pro_MT5 v2.0 Initialized successfully on ", _Symbol, " Period: ", EnumToString(_Period));
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(m_handleFastEma != INVALID_HANDLE) IndicatorRelease(m_handleFastEma);
   if(m_handleSlowEma != INVALID_HANDLE) IndicatorRelease(m_handleSlowEma);
   if(m_handleRsi != INVALID_HANDLE)     IndicatorRelease(m_handleRsi);
   if(m_handleHTF_ATR != INVALID_HANDLE) IndicatorRelease(m_handleHTF_ATR);

   // Clean Chart Objects
   ObjectsDeleteAll(0, "PA_");
   ObjectsDeleteAll(0, "POI_");
}

//+------------------------------------------------------------------+
//| Check if a new bar has just opened (Zero Repainting)             |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime != m_lastBarTime)
   {
      m_lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Manage Open Positions on every tick (Break-Even & Trailing)
   ManagePositions();

   // Only evaluate new trading decisions once per candle open
   if(!IsNewBar()) return;

   // Cancel expired pending orders
   CleanExpiredPendingOrders();

   // Periodic Refresh of HTF POIs (e.g. at each new bar)
   if(InpUseHTF_POI)
   {
      ScanHTF_POIs();
   }

   // Prevent multiple concurrent positions for this EA
   if(HasOpenPosition()) return;

   // Fetch Candle Data on current execution timeframe
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 0, 15, rates) < 15) return;

   // 1. Confluence Check: Trend
   int trendDirection = GetTrendDirection();

   // 2. Confluence Check: RSI
   double rsiVal = 50.0;
   if(InpUseRsiFilter && !GetRsiValue(1, rsiVal)) return;

   // 3. Confluence Check: POI (Is price currently inside a Demand or Supply Zone?)
   bool inDemandPOI = false;
   bool inSupplyPOI = false;
   if(InpUseHTF_POI)
   {
      CheckPriceInPOI(rates[1].close, inDemandPOI, inSupplyPOI);
   }
   else
   {
      // If POI is disabled, allow both directions
      inDemandPOI = true;
      inSupplyPOI = true;
   }

   // 4. Confluence Check: VSA (Volume Spread Analysis)
   bool vsaBullish = CheckVsaConfirmation(rates, 1, true);
   bool vsaBearish = CheckVsaConfirmation(rates, 1, false);

   // ===============================================================
   // 1. PIN BAR SETUP EVALUATION
   // ===============================================================
   if(InpEnablePinBar)
   {
      bool isBullPin = false, isBearPin = false;
      if(CheckPinBar(rates, 1, isBullPin, isBearPin))
      {
         // Bullish Pin Bar Entry
         if(isBullPin && inDemandPOI && vsaBullish && (trendDirection >= 0) && 
            (!InpUseRsiFilter || rsiVal < InpRsiOverbought))
         {
            ExecutePinBarBuy(rates[1]);
            if(InpDrawVisualSignals) DrawSignal(rates[1].time, rates[1].low, "Bullish Pin [POI+VSA]", true);
            return;
         }

         // Bearish Pin Bar Entry
         if(isBearPin && inSupplyPOI && vsaBearish && (trendDirection <= 0) && 
            (!InpUseRsiFilter || rsiVal > InpRsiOversold))
         {
            ExecutePinBarSell(rates[1]);
            if(InpDrawVisualSignals) DrawSignal(rates[1].time, rates[1].high, "Bearish Pin [POI+VSA]", false);
            return;
         }
      }
   }

   // ===============================================================
   // 2. FAKEY SETUP EVALUATION (False Breakout)
   // ===============================================================
   if(InpEnableFakey)
   {
      bool isBullFakey = false, isBearFakey = false;
      double extremePrice = 0.0;
      if(CheckFakey(rates, 1, isBullFakey, isBearFakey, extremePrice))
      {
         if(isBullFakey && inDemandPOI && vsaBullish && (trendDirection >= 0))
         {
            ExecuteFakeyBuy(rates[1], extremePrice);
            if(InpDrawVisualSignals) DrawSignal(rates[1].time, rates[1].low, "Bullish Fakey [POI+VSA]", true);
            return;
         }
         if(isBearFakey && inSupplyPOI && vsaBearish && (trendDirection <= 0))
         {
            ExecuteFakeySell(rates[1], extremePrice);
            if(InpDrawVisualSignals) DrawSignal(rates[1].time, rates[1].high, "Bearish Fakey [POI+VSA]", false);
            return;
         }
      }
   }

   // ===============================================================
   // 3. INSIDE BAR BREAKOUT EVALUATION
   // ===============================================================
   if(InpEnableInsideBar)
   {
      if(CheckInsideBar(rates, 1))
      {
         if(!HasPendingOrders())
         {
            // Inside bars can be continuation or POI bounce
            bool canBuy  = inDemandPOI && (trendDirection >= 0);
            bool canSell = inSupplyPOI && (trendDirection <= 0);

            if(canBuy || canSell)
            {
               ExecuteInsideBarBreakout(rates[2], rates[1], canBuy, canSell);
               if(InpDrawVisualSignals) DrawSignal(rates[1].time, rates[1].high, "Inside Bar", true);
               return;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| VSA (Volume Spread Analysis) Evaluation                          |
//+------------------------------------------------------------------+
bool CheckVsaConfirmation(const MqlRates &rates[], int i, bool forBullish)
{
   if(InpVsaMode == VSA_DISABLED) return true;

   // Calculate Volume Moving Average
   long sumVolume = 0;
   int count = 0;
   for(int k = 1; k <= InpVolumeMaPeriod; k++)
   {
      if((i + k) < ArraySize(rates))
      {
         sumVolume += rates[i + k].tick_volume;
         count++;
      }
   }
   if(count == 0) return true;
   double avgVolume = (double)sumVolume / count;
   double currentVolume = (double)rates[i].tick_volume;

   double currentSpread = rates[i].high - rates[i].low;

   // 1. Stopping Volume / Climactic Volume:
   // Ultra-high volume indicating institutional absorption at support or resistance
   bool isClimacticVolume = (currentVolume >= avgVolume * InpHighVolMultiplier);

   // 2. Low-Volume Test (No Supply / No Demand):
   // Price is testing a level with significantly lower volume than average (less seller interest)
   bool isLowVolumeTest = (currentVolume <= avgVolume * InpLowVolMultiplier);

   if(InpVsaMode == VSA_CLIMAX_ONLY)
   {
      return isClimacticVolume;
   }
   else if(InpVsaMode == VSA_FULL_ENGINE)
   {
      // Valid if it's either an institutional climax/absorption OR a successful low-volume test
      return (isClimacticVolume || isLowVolumeTest);
   }

   return true;
}

//+------------------------------------------------------------------+
//| Multi-Timeframe POI Scanner (Order Blocks & Imbalance)           |
//+------------------------------------------------------------------+
void ScanHTF_POIs()
{
   MqlRates htfRates[];
   ArraySetAsSeries(htfRates, true);
   int copied = CopyRates(_Symbol, InpPOITimeframe, 0, InpPOILookbackBars, htfRates);
   if(copied < 20) return;

   // Fetch HTF ATR
   double atrArr[1];
   if(CopyBuffer(m_handleHTF_ATR, 0, 1, 1, atrArr) < 1) return;
   double htfAtr = atrArr[0];

   ArrayResize(m_poiList, 0);

   // Scan for Order Blocks with displacement
   for(int i = 2; i < copied - 2; i++)
   {
      // 1. BULLISH ORDER BLOCK (Demand POI):
      // Bearish candle followed by explosive upward movement creating an imbalance
      bool isBearishCandle = (htfRates[i].close < htfRates[i].open);
      double impulseMove   = htfRates[i - 1].close - htfRates[i].open;
      bool hasDisplacement = (impulseMove >= htfAtr * InpMinImbalanceAtr);
      // Fair Value Gap (Imbalance): Low of candle (i-2) is higher than High of candle i
      bool hasFVG = (htfRates[i - 2].low > htfRates[i].high);

      if(isBearishCandle && hasDisplacement && hasFVG)
      {
         int newSize = ArraySize(m_poiList) + 1;
         ArrayResize(m_poiList, newSize);
         int idx = newSize - 1;

         m_poiList[idx].top         = htfRates[i].high;
         m_poiList[idx].bottom      = htfRates[i].low;
         m_poiList[idx].time        = htfRates[i].time;
         m_poiList[idx].isBullish   = true;
         m_poiList[idx].isMitigated = false;
         m_poiList[idx].objName     = "POI_Demand_" + TimeToString(htfRates[i].time);

         // Check if already mitigated by subsequent candles
         for(int j = i - 1; j >= 0; j--)
         {
            if(htfRates[j].close < m_poiList[idx].bottom)
            {
               m_poiList[idx].isMitigated = true;
               break;
            }
         }
      }

      // 2. BEARISH ORDER BLOCK (Supply POI):
      // Bullish candle followed by explosive downward movement creating an imbalance
      bool isBullishCandle   = (htfRates[i].close > htfRates[i].open);
      double dropMove        = htfRates[i].open - htfRates[i - 1].close;
      bool hasDropDisplace   = (dropMove >= htfAtr * InpMinImbalanceAtr);
      bool hasBearishFVG     = (htfRates[i - 2].high < htfRates[i].low);

      if(isBullishCandle && hasDropDisplace && hasBearishFVG)
      {
         int newSize = ArraySize(m_poiList) + 1;
         ArrayResize(m_poiList, newSize);
         int idx = newSize - 1;

         m_poiList[idx].top         = htfRates[i].high;
         m_poiList[idx].bottom      = htfRates[i].low;
         m_poiList[idx].time        = htfRates[i].time;
         m_poiList[idx].isBullish   = false;
         m_poiList[idx].isMitigated = false;
         m_poiList[idx].objName     = "POI_Supply_" + TimeToString(htfRates[i].time);

         // Check if already mitigated
         for(int j = i - 1; j >= 0; j--)
         {
            if(htfRates[j].close > m_poiList[idx].top)
            {
               m_poiList[idx].isMitigated = true;
               break;
            }
         }
      }
   }

   // Draw POI Boxes on Chart
   if(InpDrawPOIZones)
   {
      DrawPOIZonesOnChart();
   }
}

//+------------------------------------------------------------------+
//| Check if current price is inside an active POI Zone              |
//+------------------------------------------------------------------+
void CheckPriceInPOI(double price, bool &inDemand, bool &inSupply)
{
   inDemand = false;
   inSupply = false;

   int total = ArraySize(m_poiList);
   for(int i = 0; i < total; i++)
   {
      if(m_poiList[i].isMitigated) continue;

      if(m_poiList[i].isBullish)
      {
         // Price is within the Demand Zone
         if(price >= m_poiList[i].bottom && price <= (m_poiList[i].top + (5.0 * m_pipSize)))
         {
            inDemand = true;
         }
      }
      else
      {
         // Price is within the Supply Zone
         if(price <= m_poiList[i].top && price >= (m_poiList[i].bottom - (5.0 * m_pipSize)))
         {
            inSupply = true;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Draw POI Rectangles on MT5 Chart                                 |
//+------------------------------------------------------------------+
void DrawPOIZonesOnChart()
{
   datetime now = TimeCurrent();
   int total = ArraySize(m_poiList);

   for(int i = 0; i < total; i++)
   {
      if(m_poiList[i].isMitigated)
      {
         ObjectDelete(0, m_poiList[i].objName);
         continue;
      }

      if(ObjectFind(0, m_poiList[i].objName) < 0)
      {
         ObjectCreate(0, m_poiList[i].objName, OBJ_RECTANGLE, 0, 
                      m_poiList[i].time, m_poiList[i].top, 
                      now + (10 * PeriodSeconds(_Period)), m_poiList[i].bottom);
         
         color zoneColor = m_poiList[i].isBullish ? InpDemandColor : InpSupplyColor;
         ObjectSetInteger(0, m_poiList[i].objName, OBJPROP_COLOR, zoneColor);
         ObjectSetInteger(0, m_poiList[i].objName, OBJPROP_FILL, true);
         ObjectSetInteger(0, m_poiList[i].objName, OBJPROP_BACK, true);
      }
      else
      {
         // Extend the rectangle forward
         ObjectSetInteger(0, m_poiList[i].objName, OBJPROP_TIME, 1, now + (10 * PeriodSeconds(_Period)));
      }
   }
}

//+------------------------------------------------------------------+
//| Check Pin Bar Mathematical Conditions (PDF Pages 53-63)          |
//+------------------------------------------------------------------+
bool CheckPinBar(const MqlRates &rates[], int i, bool &isBullish, bool &isBearish)
{
   isBullish = false;
   isBearish = false;

   double range = rates[i].high - rates[i].low;
   if(range <= 0.0) return false;

   double body = MathAbs(rates[i].close - rates[i].open);
   double upperWick = rates[i].high - MathMax(rates[i].open, rates[i].close);
   double lowerWick = MathMin(rates[i].open, rates[i].close) - rates[i].low;

   // 1. Strict Ratio: Tail >= 2/3 of Range, Body <= 1/3 of Range
   bool validBodyRatio = (body / range) <= InpPinMaxBodyRatio;
   if(!validBodyRatio) return false;

   // 2. Protrusion Check (Wick must stick out beyond previous bars)
   bool protrudesLow = true;
   bool protrudesHigh = true;
   for(int b = 1; b <= InpPinProtrudeBars; b++)
   {
      if(rates[i].low >= rates[i + b].low)   protrudesLow = false;
      if(rates[i].high <= rates[i + b].high) protrudesHigh = false;
   }

   // Bullish Pin Bar
   if((lowerWick / range) >= InpPinMinWickRatio && protrudesLow)
   {
      isBullish = true;
      return true;
   }

   // Bearish Pin Bar
   if((upperWick / range) >= InpPinMinWickRatio && protrudesHigh)
   {
      isBearish = true;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check Inside Bar Setup (PDF Pages 71-86)                         |
//+------------------------------------------------------------------+
bool CheckInsideBar(const MqlRates &rates[], int i)
{
   return (rates[i].high <= rates[i + 1].high && rates[i].low >= rates[i + 1].low);
}

//+------------------------------------------------------------------+
//| Check Fakey Setup (PDF Pages 87-97)                              |
//+------------------------------------------------------------------+
bool CheckFakey(const MqlRates &rates[], int i, bool &isBullFakey, bool &isBearFakey, double &extremePrice)
{
   isBullFakey = false;
   isBearFakey = false;
   extremePrice = 0.0;

   // Check if Bar 2 is an Inside Bar to Bar 3
   if(rates[i + 1].high > rates[i + 2].high || rates[i + 1].low < rates[i + 2].low)
      return false;

   // Bullish Fakey: Bar 1 poked below Inside Bar Low, closed higher
   if(rates[i].low < rates[i + 1].low && rates[i].close > rates[i + 1].low)
   {
      isBullFakey = true;
      extremePrice = rates[i].low;
      return true;
   }

   // Bearish Fakey: Bar 1 poked above Inside Bar High, closed lower
   if(rates[i].high > rates[i + 1].high && rates[i].close < rates[i + 1].high)
   {
      isBearFakey = true;
      extremePrice = rates[i].high;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Get Trend Direction via EMA Filter                               |
//+------------------------------------------------------------------+
int GetTrendDirection()
{
   if(InpTrendFilter == TREND_NONE) return 0;

   double fastEma[2], slowEma[2];
   if(CopyBuffer(m_handleFastEma, 0, 1, 2, fastEma) < 2) return 0;
   if(CopyBuffer(m_handleSlowEma, 0, 1, 2, slowEma) < 2) return 0;

   if(fastEma[1] > slowEma[1]) return 1;  // Bullish
   if(fastEma[1] < slowEma[1]) return -1; // Bearish

   return 0;
}

//+------------------------------------------------------------------+
//| Get RSI Value                                                    |
//+------------------------------------------------------------------+
bool GetRsiValue(int shift, double &value)
{
   double rsiArr[1];
   if(CopyBuffer(m_handleRsi, 0, shift, 1, rsiArr) < 1) return false;
   value = rsiArr[0];
   return true;
}

//+------------------------------------------------------------------+
//| Calculate Dynamic Lot Size based on Account Balance & Risk %     |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistancePips)
{
   if(InpLotMode == LOT_FIXED) return InpFixedLotSize;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * (InpRiskPercent / 100.0);

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tickSize <= 0.0 || tickValue <= 0.0 || slDistancePips <= 0.0) return InpFixedLotSize;

   double slDistancePoints = slDistancePips * (m_pipSize / m_point);
   double slRiskPerLot = (slDistancePoints * m_point / tickSize) * tickValue;

   if(slRiskPerLot <= 0.0) return InpFixedLotSize;

   double calculatedLot = riskAmount / slRiskPerLot;

   // Normalize Lot Size
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   calculatedLot = MathFloor(calculatedLot / lotStep) * lotStep;
   calculatedLot = MathMax(minLot, MathMin(maxLot, calculatedLot));

   return NormalizeDouble(calculatedLot, 2);
}

//+------------------------------------------------------------------+
//| Execution: Pin Bar Buy                                           |
//+------------------------------------------------------------------+
void ExecutePinBarBuy(const MqlRates &pin)
{
   double slPrice = pin.low - (InpStopLossBufferPips * m_pipSize);
   double slPips  = (pin.close - slPrice) / m_pipSize;
   double lot     = CalculateLotSize(slPips);

   if(InpPinEntryMode == ENTRY_MARKET_ON_CLOSE)
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double tpPrice = ask + (slPips * InpRiskRewardRatio * m_pipSize);
      m_trade.Buy(lot, _Symbol, ask, slPrice, tpPrice, "PinBar_Buy");
   }
   else // 50% Limit Entry
   {
      double limitPrice = pin.low + (pin.high - pin.low) * 0.50;
      double slLimitPips = (limitPrice - slPrice) / m_pipSize;
      double tpPrice = limitPrice + (slLimitPips * InpRiskRewardRatio * m_pipSize);
      datetime expiry = TimeCurrent() + (InpLimitOrderExpiryBars * PeriodSeconds(_Period));
      
      m_trade.BuyLimit(lot, limitPrice, _Symbol, slPrice, tpPrice, ORDER_TIME_SPECIFIED, expiry, "PinBar_50_BuyLimit");
   }
}

//+------------------------------------------------------------------+
//| Execution: Pin Bar Sell                                          |
//+------------------------------------------------------------------+
void ExecutePinBarSell(const MqlRates &pin)
{
   double slPrice = pin.high + (InpStopLossBufferPips * m_pipSize);
   double slPips  = (slPrice - pin.close) / m_pipSize;
   double lot     = CalculateLotSize(slPips);

   if(InpPinEntryMode == ENTRY_MARKET_ON_CLOSE)
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double tpPrice = bid - (slPips * InpRiskRewardRatio * m_pipSize);
      m_trade.Sell(lot, _Symbol, bid, slPrice, tpPrice, "PinBar_Sell");
   }
   else // 50% Limit Entry
   {
      double limitPrice = pin.high - (pin.high - pin.low) * 0.50;
      double slLimitPips = (slPrice - limitPrice) / m_pipSize;
      double tpPrice = limitPrice - (slLimitPips * InpRiskRewardRatio * m_pipSize);
      datetime expiry = TimeCurrent() + (InpLimitOrderExpiryBars * PeriodSeconds(_Period));
      
      m_trade.SellLimit(lot, limitPrice, _Symbol, slPrice, tpPrice, ORDER_TIME_SPECIFIED, expiry, "PinBar_50_SellLimit");
   }
}

//+------------------------------------------------------------------+
//| Execution: Inside Bar Breakout                                   |
//+------------------------------------------------------------------+
void ExecuteInsideBarBreakout(const MqlRates &mother, const MqlRates &ib, bool canBuy, bool canSell)
{
   datetime expiry = TimeCurrent() + (InpIBOrderExpiryBars * PeriodSeconds(_Period));

   if(canBuy)
   {
      double buyPrice = mother.high + (InpIBBreakoutBufferPips * m_pipSize);
      double slPrice  = mother.low - (InpStopLossBufferPips * m_pipSize);
      double slPips   = (buyPrice - slPrice) / m_pipSize;
      double tpPrice  = buyPrice + (slPips * InpRiskRewardRatio * m_pipSize);
      double lot      = CalculateLotSize(slPips);

      m_trade.BuyStop(lot, buyPrice, _Symbol, slPrice, tpPrice, ORDER_TIME_SPECIFIED, expiry, "IB_BuyStop");
   }

   if(canSell)
   {
      double sellPrice = mother.low - (InpIBBreakoutBufferPips * m_pipSize);
      double slPrice   = mother.high + (InpStopLossBufferPips * m_pipSize);
      double slPips    = (slPrice - sellPrice) / m_pipSize;
      double tpPrice   = sellPrice - (slPips * InpRiskRewardRatio * m_pipSize);
      double lot       = CalculateLotSize(slPips);

      m_trade.SellStop(lot, sellPrice, _Symbol, slPrice, tpPrice, ORDER_TIME_SPECIFIED, expiry, "IB_SellStop");
   }
}

//+------------------------------------------------------------------+
//| Execution: Fakey Reversal                                        |
//+------------------------------------------------------------------+
void ExecuteFakeyBuy(const MqlRates &bar, double falseBreakLow)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double slPrice = falseBreakLow - (InpStopLossBufferPips * m_pipSize);
   double slPips = (ask - slPrice) / m_pipSize;
   double tpPrice = ask + (slPips * InpRiskRewardRatio * m_pipSize);
   double lot = CalculateLotSize(slPips);

   m_trade.Buy(lot, _Symbol, ask, slPrice, tpPrice, "Fakey_Buy");
}

void ExecuteFakeySell(const MqlRates &bar, double falseBreakHigh)
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double slPrice = falseBreakHigh + (InpStopLossBufferPips * m_pipSize);
   double slPips = (slPrice - bid) / m_pipSize;
   double tpPrice = bid - (slPips * InpRiskRewardRatio * m_pipSize);
   double lot = CalculateLotSize(slPips);

   m_trade.Sell(lot, _Symbol, bid, slPrice, tpPrice, "Fakey_Sell");
}

//+------------------------------------------------------------------+
//| Manage Active Positions (Break-Even & Trailing Stop)             |
//+------------------------------------------------------------------+
void ManagePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;

      double openPrice = m_position.PriceOpen();
      double currentSL = m_position.StopLoss();
      double currentTP = m_position.TakeProfit();
      double currentPrice = m_position.PriceCurrent();
      ENUM_POSITION_TYPE type = m_position.PositionType();

      double initialRiskPips = MathAbs(openPrice - currentSL) / m_pipSize;
      if(initialRiskPips <= 0) continue;

      // 1. Break-Even at 1:1 R:R
      if(InpUseBreakEven)
      {
         if(type == POSITION_TYPE_BUY)
         {
            if(currentPrice >= (openPrice + initialRiskPips * m_pipSize))
            {
               if(currentSL < openPrice)
               {
                  m_trade.PositionModify(m_position.Ticket(), openPrice + (1.0 * m_pipSize), currentTP);
                  Print("Break-Even triggered for Buy Ticket: ", m_position.Ticket());
               }
            }
         }
         else if(type == POSITION_TYPE_SELL)
         {
            if(currentPrice <= (openPrice - initialRiskPips * m_pipSize))
            {
               if(currentSL > openPrice || currentSL == 0.0)
               {
                  m_trade.PositionModify(m_position.Ticket(), openPrice - (1.0 * m_pipSize), currentTP);
                  Print("Break-Even triggered for Sell Ticket: ", m_position.Ticket());
               }
            }
         }
      }

      // 2. Trailing Stop
      if(InpUseTrailingStop)
      {
         double triggerDist = initialRiskPips * InpTrailingStartRR * m_pipSize;
         double trailDist   = initialRiskPips * InpTrailingDistanceRR * m_pipSize;

         if(type == POSITION_TYPE_BUY)
         {
            if(currentPrice >= openPrice + triggerDist)
            {
               double newSL = currentPrice - trailDist;
               if(newSL > currentSL)
               {
                  m_trade.PositionModify(m_position.Ticket(), newSL, currentTP);
               }
            }
         }
         else if(type == POSITION_TYPE_SELL)
         {
            if(currentPrice <= openPrice - triggerDist)
            {
               double newSL = currentPrice + trailDist;
               if(newSL < currentSL || currentSL == 0.0)
               {
                  m_trade.PositionModify(m_position.Ticket(), newSL, currentTP);
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check if open positions exist                                    |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check if pending orders exist                                    |
//+------------------------------------------------------------------+
bool HasPendingOrders()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(m_order.SelectByIndex(i))
      {
         if(m_order.Symbol() == _Symbol && m_order.Magic() == InpMagicNumber)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Clean expired pending orders                                     |
//+------------------------------------------------------------------+
void CleanExpiredPendingOrders()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(m_order.SelectByIndex(i))
      {
         if(m_order.Symbol() == _Symbol && m_order.Magic() == InpMagicNumber)
         {
            datetime exp = (datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);
            if(exp > 0 && TimeCurrent() >= exp)
            {
               m_trade.OrderDelete(m_order.Ticket());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Draw visual chart annotations                                    |
//+------------------------------------------------------------------+
void DrawSignal(datetime time, double price, string label, bool isBullish)
{
   string arrowName = "PA_Arrow_" + TimeToString(time);
   string textName  = "PA_Text_" + TimeToString(time);

   if(isBullish)
   {
      ObjectCreate(0, arrowName, OBJ_ARROW_BUY, 0, time, price - (10.0 * m_pipSize));
      ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clrLimeGreen);
      ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 2);

      ObjectCreate(0, textName, OBJ_TEXT, 0, time, price - (25.0 * m_pipSize));
      ObjectSetString(0, textName, OBJPROP_TEXT, label);
      ObjectSetInteger(0, textName, OBJPROP_COLOR, clrLimeGreen);
      ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 9);
   }
   else
   {
      ObjectCreate(0, arrowName, OBJ_ARROW_SELL, 0, time, price + (10.0 * m_pipSize));
      ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clrCrimson);
      ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 2);

      ObjectCreate(0, textName, OBJ_TEXT, 0, time, price + (25.0 * m_pipSize));
      ObjectSetString(0, textName, OBJPROP_TEXT, label);
      ObjectSetInteger(0, textName, OBJPROP_COLOR, clrCrimson);
      ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 9);
   }
}
//+------------------------------------------------------------------+
