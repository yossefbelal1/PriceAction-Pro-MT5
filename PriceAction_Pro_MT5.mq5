//+------------------------------------------------------------------+
//|                                           PriceAction_Pro_MT5.mq5 |
//|                                  Copyright 2026, Antigravity AI  |
//|               Nial Fuller Price Action + Optional Enhanced Suite |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Antigravity AI"
#property link      "https://github.com/yossefbelal1/PriceAction-Pro-MT5"
#property version   "4.00"
#property description "Professional Price Action Trading System with Strict Mode Separation:"
#property description "MODE A: BOOK_EXACT (Pure Price Action from 97-Page Course: Swings, S/R, Flips, 50% Confluence)"
#property description "MODE B: ENHANCED (Optional Overlays: EMA, RSI, VSA, HTF Order Blocks/FVG)"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//+------------------------------------------------------------------+
//| ENUMERATIONS                                                     |
//+------------------------------------------------------------------+
enum ENUM_STRATEGY_MODE
{
   MODE_BOOK_EXACT = 0, // Mode A: Pure PDF Book Strategy (No EMA, RSI, VSA, or OB/FVG)
   MODE_ENHANCED   = 1  // Mode B: Enhanced Strategy (Optional Technical Filters Layered On Top)
};

enum ENUM_MARKET_TREND
{
   TREND_RANGE    = 0,  // Range-bound / Consolidation / Horizontal
   TREND_BULLISH  = 1,  // Bullish Structure (Higher Highs & Higher Lows)
   TREND_BEARISH  = -1  // Bearish Structure (Lower Highs & Lower Lows)
};

enum ENUM_PINBAR_ENTRY_MODE
{
   PIN_ENTRY_MARKET_ON_CLOSE = 0, // Market Entry on Pin Bar Close
   PIN_ENTRY_LIMIT_50_RETRACE = 1 // 50% Limit Entry (PDF Page 62)
};

enum ENUM_EXIT_MODE
{
   EXIT_FIXED_RR         = 0, // Fixed Risk:Reward Multiple
   EXIT_NEXT_SWING_LEVEL = 1, // Target Next Confirmed Market Structure Level
   EXIT_TRAILING_ONLY    = 2  // No Fixed TP, Trailing Stop Management Only
};

enum ENUM_LOT_SIZING_MODE
{
   LOT_STRICT_RISK_PERCENT = 0, // Strict Risk % of Account Balance (Rejects if Invalid)
   LOT_FIXED_SIZE          = 1  // Fixed Lot Size
};

enum ENUM_VSA_FILTER_MODE
{
   VSA_OFF             = 0, // Disabled
   VSA_CLIMAX_STOPPING = 1, // Require Climactic / Stopping Volume at Extremes
   VSA_TEST_AND_CLIMAX = 2  // Allow Climax OR Low-Volume Test Confirmation
};

enum ENUM_POI_INTERACTION
{
   POI_INTERACT_WICK  = 0, // Candle Wick enters or pierces the zone
   POI_INTERACT_BODY  = 1, // Candle Body overlaps the zone
   POI_INTERACT_CLOSE = 2  // Candle Close is inside the zone
};

//+------------------------------------------------------------------+
//| INTERNAL STRUCTURES                                              |
//+------------------------------------------------------------------+
struct SSwingPivot
{
   double   price;
   datetime time;
   int      barShift;
   bool     isHigh; // true = High, false = Low
};

struct SSRZone
{
   double   priceTop;
   double   priceBottom;
   double   midPrice;
   int      touchCount;
   bool     isSupport;
   bool     isResistance;
   bool     isFlipped;
   datetime lastTouchTime;
   string   objName;
};

struct SPositionTracker
{
   ulong    ticket;
   datetime openTime;
   double   openPrice;
   double   initialSL;
   double   initialTP;
   double   initialRiskPoints;
   ENUM_POSITION_TYPE type;
   string   setupName;
   bool     breakEvenApplied;
};

struct SOCOPendingPair
{
   ulong    buyStopTicket;
   ulong    sellStopTicket;
   datetime placedTime;
   bool     isActive;
   string   pairTag;
};

struct SProcessedSignal
{
   datetime candleTime;
   string   signalKey;
};

struct SPointOfInterest
{
   double   top;
   double   bottom;
   datetime time;
   bool     isBullish;
   bool     isMitigated;
   string   objName;
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
//--- 0. STRATEGY MODE
input group "=== 0. Strategy Mode Selector ==="
input ENUM_STRATEGY_MODE InpStrategyMode = MODE_BOOK_EXACT; // Strategy Mode (BOOK_EXACT vs ENHANCED)

//--- 1. MARKET STRUCTURE (SWINGS & TREND)
input group "=== 1. Market Structure & Trend (PDF Pages 10-16) ==="
input int    InpSwingConfirmBars   = 3;      // Pivot Confirmation Bars on Both Sides (N Left, N Right)
input int    InpSwingScanBars      = 120;    // Lookback Bars to Detect Confirmed Swings
input bool   InpRequireTrend       = true;   // Require Trend Alignment for Continuation Setups

//--- 2. HORIZONTAL SUPPORT & RESISTANCE (PDF Pages 17-34)
input group "=== 2. Key Support & Resistance & Flips (PDF Pages 17-34) ==="
input bool   InpEnableSRZones      = true;   // Enable Horizontal S/R Level Engine
input double InpSRZoneBandPips     = 8.0;    // S/R Zone Width / Clustering Tolerance (Pips)
input int    InpSRMinTouches       = 2;      // Minimum Touches to Confirm Key Level
input bool   InpEnableLevelFlips   = true;   // Enable Level Flip Logic (Prev Resistance -> Support)
input int    InpSRLookbackBars     = 300;    // S/R Historical Lookback Bars

//--- 3. 50% SWING RETRACEMENT CONFLUENCE (PDF Pages 61, 66)
input group "=== 3. 50% Swing Retracement Confluence (PDF Pages 61, 66) ==="
input bool   InpUse50SwingRetrace  = true;   // Require or Use 50% Swing Midpoint as Confluence
input double InpSwing50TolerancePips = 10.0; // 50% Swing Tolerance (Pips)

//--- 4. PIN BAR STRATEGY (PDF Pages 53-63)
input group "=== 4. Pin Bar Strategy (PDF Pages 53-63) ==="
input bool   InpEnablePinBar       = true;   // Enable Pin Bar Trades
input ENUM_PINBAR_ENTRY_MODE InpPinEntryMode = PIN_ENTRY_LIMIT_50_RETRACE; // Pin Bar Entry (Market vs 50% Limit)
input double InpPinMinWickRatio    = 0.667;  // Minimum Tail Ratio (PDF: >= 2/3 = 66.7%)
input double InpPinMaxBodyRatio    = 0.333;  // Maximum Real Body Ratio (PDF: <= 1/3 = 33.3%)
input int    InpPinProtrudeLookback= 3;      // Protrusion Lookback Bars (Tail sticks out)
input int    InpPinLimitExpiryBars = 6;      // 50% Limit Order Expiry (Candle Bars)

//--- 5. INSIDE BAR STRATEGY (PDF Pages 71-86)
input group "=== 5. Inside Bar Strategy (PDF Pages 71-86) ==="
input bool   InpEnableInsideBar    = true;   // Enable Inside Bar Trades
input bool   InpIBContinuationOnly = true;   // Inside Bar Continuation (With Trend)
input bool   InpIBReversalAtLevels = true;   // Inside Bar Reversals at Key S/R Levels
input int    InpIBMaxNestingBars   = 4;      // Max Consecutive Inside Bars (Coiling Support)
input double InpIBBreakoutBufferPips = 1.0;  // Breakout Order Buffer Beyond Mother Bar (Pips)
input int    InpIBOrderExpiryBars  = 8;      // Inside Bar Pending Order Expiry (Candle Bars)

//--- 6. FAKEY STRATEGY (PDF Pages 87-97)
input group "=== 6. Fakey False-Break Strategy (PDF Pages 87-97) ==="
input bool   InpEnableFakey        = true;   // Enable Fakey Strategy
input double InpFakeyMinBreakPoints= 30.0;   // Minimum Obvious False-Break Penetration (Points)
input bool   InpFakeyRequireKeyLevel= true;  // Require Key S/R Level for Counter-Trend / Range Fakeys

//--- 7. EXITS & TAKE PROFIT
input group "=== 7. Take Profit & Exits ==="
input ENUM_EXIT_MODE InpExitMode   = EXIT_FIXED_RR; // Exit Method
input double InpRiskRewardRatio    = 2.5;    // Risk:Reward Multiple (For Fixed RR mode)
input double InpStopLossBufferPips = 2.0;    // Structural SL Extra Buffer (Pips)

//--- 8. RISK & POSITION SIZING
input group "=== 8. Risk Management & Position Sizing ==="
input ENUM_LOT_SIZING_MODE InpLotMode = LOT_STRICT_RISK_PERCENT; // Lot Sizing Mode
input double InpRiskPercent        = 1.0;    // Risk Percentage per Trade (% of Account Balance)
input double InpFixedLotSize       = 0.10;   // Fixed Lot Size (if Fixed mode selected)
input double InpMaxRiskPercentCap  = 1.25;   // Max Allowed Risk % if Broker Min-Lot Causes Round-Up

//--- 9. TRADE MANAGEMENT (BREAK-EVEN & TRAILING)
input group "=== 9. Trade Management ==="
input bool   InpUseBreakEven       = true;   // Enable Break-Even Protection
input double InpBreakEvenTriggerRR = 1.0;    // Break-Even Trigger (Multiples of Initial Risk R)
input double InpBreakEvenLockPips  = 1.0;    // Profit Lock Pips at Break-Even (0 = Exact Open Price)
input bool   InpUseTrailingStop    = false;  // Enable Trailing Stop
input double InpTrailingStartRR    = 1.5;    // Trailing Stop Start (Multiples of Initial Risk R)
input double InpTrailingDistanceRR = 1.0;    // Trailing Distance (Multiples of Initial Risk R)

//--- 10. ENHANCED OVERLAYS (ONLY ACTIVE IN MODE_ENHANCED)
input group "=== 10. Enhanced Overlays (Active ONLY in ENHANCED Mode) ==="
input bool   InpUseEmaFilter       = true;   // Layer EMA Trend Filter
input ENUM_TIMEFRAMES InpEmaTimeframe = PERIOD_CURRENT; // EMA Timeframe
input int    InpFastEmaPeriod      = 21;     // Fast EMA
input int    InpSlowEmaPeriod      = 50;     // Slow EMA
input bool   InpUseRsiFilter       = true;   // Layer RSI Filter
input int    InpRsiPeriod          = 14;     // RSI Period
input double InpRsiOverbought      = 70.0;   // RSI Overbought Level
input double InpRsiOversold        = 30.0;   // RSI Oversold Level
input ENUM_VSA_FILTER_MODE InpVsaFilter = VSA_TEST_AND_CLIMAX; // Volume Spread Analysis Mode
input int    InpVsaMaPeriod        = 20;     // VSA Volume Moving Average Lookback
input double InpVsaHighMultiplier  = 1.7;    // VSA High Volume Multiplier
input double InpVsaLowMultiplier   = 0.8;    // VSA Low Volume Multiplier
input bool   InpUseHtfPoi          = true;   // Layer HTF Order Blocks / Imbalance POI
input ENUM_TIMEFRAMES InpHtfPoiTf  = PERIOD_D1; // HTF POI Timeframe
input double InpPoiMinImbalanceAtr = 1.2;    // Min Impulse Imbalance Multiplier (x HTF ATR)
input ENUM_POI_INTERACTION InpPoiInteractMode = POI_INTERACT_WICK; // POI Interaction Mode

//--- 11. BROKER CONSTRAINTS & SYSTEM
input group "=== 11. Execution & Broker Constraints ==="
input ulong  InpMagicNumber        = 20260929; // EA Magic Number
input int    InpMaxSpreadPoints    = 40;       // Max Allowed Spread (Points)
input int    InpSlippagePoints     = 30;       // Max Slippage (Points)
input bool   InpEnableDebugLog     = true;     // Detailed Diagnostic Logging
input bool   InpDrawChartObjects   = true;     // Draw Visual Swings, S/R Zones, & Setup Markers

//+------------------------------------------------------------------+
//| GLOBAL SYSTEM VARIABLES                                          |
//+------------------------------------------------------------------+
CTrade            m_trade;
CPositionInfo     m_position;
COrderInfo        m_order;

double            m_point;
double            m_pipSize;
datetime          m_lastBarTime = 0;

// Indicators (Enhanced Mode Only)
int               m_hFastEma  = INVALID_HANDLE;
int               m_hSlowEma  = INVALID_HANDLE;
int               m_hRsi      = INVALID_HANDLE;
int               m_hHtfAtr   = INVALID_HANDLE;

// Persistent Arrays
SSwingPivot       m_swings[];
SSRZone           m_srZones[];
SPositionTracker  m_trackedPositions[];
SOCOPendingPair   m_ocoPairs[];
SProcessedSignal  m_processedSignals[];
SPointOfInterest  m_htfPois[];

//+------------------------------------------------------------------+
//| Forward Declarations                                             |
//+------------------------------------------------------------------+
void              UpdateSwingsAndStructure();
void              UpdateSRZones();
ENUM_MARKET_TREND DetectMarketTrend();
bool              IsCandleInteractingWithSR(const MqlRates &candle, bool forBuy, bool &isFlippedLevel);
bool              IsTesting50PercentSwingRetrace(const MqlRates &candle, bool forBuy);
bool              ValidateConfluence(const MqlRates &candle, bool forBuy, ENUM_MARKET_TREND trend, bool isFakey = false);
bool              EvaluatePinBar(const MqlRates &rates[], int i, bool &isBullish, bool &isBearish);
bool              EvaluateInsideBarStructure(const MqlRates &rates[], int i, int &motherShift, int &insideCount);
bool              EvaluateFakey(const MqlRates &rates[], int i, bool &isBullFakey, bool &isBearFakey, double &extremePrice);
bool              CalculateStrictLotSize(double entryPrice, double slPrice, double &outLotSize);
bool              ValidateBrokerDistance(double orderPrice, double slPrice, double tpPrice);
double            CalculateTakeProfit(double entryPrice, double slPrice, bool isBuy);
bool              ExecutePinBarOrder(const MqlRates &pin, bool isBuy);
bool              ExecuteFakeyOrder(const MqlRates &bar, double falseBreakExtreme, bool isBuy);
bool              ExecuteInsideBarSetup(const MqlRates &rates[], int motherShift, int insideCount, ENUM_MARKET_TREND trend);
void              ManageActivePositions();
void              ManageOCOPendingPairs();
void              RegisterPositionTrack(ulong ticket, double openPrice, double slPrice, double tpPrice, ENUM_POSITION_TYPE type, string setup);
int               FindTrackedPositionIndex(ulong ticket);
bool              IsSignalProcessed(datetime barTime, string key);
void              RecordSignalProcessed(datetime barTime, string key);
void              CleanExpiredPendingOrders();
bool              HasOpenPosition();
bool              ValidateVsaCondition(int shift, bool forBuy);
void              ScanHtfPois();
bool              IsCandleInteractingWithHtfPoi(const MqlRates &candle, bool forBuy);
void              DrawSignalMarker(datetime time, double price, string label, color clr, bool isBuy);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   m_trade.SetExpertMagicNumber(InpMagicNumber);
   m_trade.SetDeviationInPoints(InpSlippagePoints);
   // Symbol-aware filling mode detection (never hard-code FOK)
   {
      int fillingMode = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
      if((fillingMode & SYMBOL_FILLING_FOK) != 0)
         m_trade.SetTypeFilling(ORDER_FILLING_FOK);
      else if((fillingMode & SYMBOL_FILLING_IOC) != 0)
         m_trade.SetTypeFilling(ORDER_FILLING_IOC);
      else
         m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
      PrintFormat("[Init] Filling mode set based on SYMBOL_FILLING_MODE bitmask: %d", fillingMode);
   }

   m_point = _Point;
   m_pipSize = (_Digits == 3 || _Digits == 5) ? _Point * 10.0 : _Point;

   // Mode Validation
   if(InpStrategyMode == MODE_BOOK_EXACT)
   {
      Print("==========================================================");
      Print("[PriceAction_Pro] MODE: BOOK_EXACT (Pure Price Action)");
      Print("Indicators disabled: EMA=OFF, RSI=OFF, VSA=OFF, HTF_POI=OFF");
      Print("Foundation: Confirmed Swings, Horizontal S/R, Level Flips");
      Print("==========================================================");
   }
   else
   {
      Print("==========================================================");
      Print("[PriceAction_Pro] MODE: ENHANCED (Price Action + Overlays)");
      Print("Layering optional technical filters on top of PA framework");
      Print("==========================================================");

      if(InpUseEmaFilter)
      {
         m_hFastEma = iMA(_Symbol, InpEmaTimeframe, InpFastEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
         m_hSlowEma = iMA(_Symbol, InpEmaTimeframe, InpSlowEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      }
      if(InpUseRsiFilter)
      {
         m_hRsi = iRSI(_Symbol, _Period, InpRsiPeriod, PRICE_CLOSE);
      }
      if(InpUseHtfPoi)
      {
         m_hHtfAtr = iATR(_Symbol, InpHtfPoiTf, 14);
      }
   }

   // Initialize Swings and S/R on Historical Data
   UpdateSwingsAndStructure();
   UpdateSRZones();
   if(InpStrategyMode == MODE_ENHANCED && InpUseHtfPoi)
   {
      ScanHtfPois();
   }

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(m_hFastEma != INVALID_HANDLE) IndicatorRelease(m_hFastEma);
   if(m_hSlowEma != INVALID_HANDLE) IndicatorRelease(m_hSlowEma);
   if(m_hRsi != INVALID_HANDLE)     IndicatorRelease(m_hRsi);
   if(m_hHtfAtr != INVALID_HANDLE)  IndicatorRelease(m_hHtfAtr);

   if(InpDrawChartObjects)
   {
      ObjectsDeleteAll(0, "PA_");
      ObjectsDeleteAll(0, "SR_");
      ObjectsDeleteAll(0, "POI_");
      ObjectsDeleteAll(0, "SWING_");
   }
}

//+------------------------------------------------------------------+
//| Check if a new closed bar has appeared (Zero Repaint Enforcement)|
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
   // 1. Manage Active Positions on every tick (Break-Even & Trailing Stop)
   ManageActivePositions();

   // 2. Manage OCO Pending Pairs (Cancel opposite order if one executes)
   ManageOCOPendingPairs();

   // 3. New-Bar Gate: Trade Generation logic executes STRICTLY on closed bars
   if(!IsNewBar()) return;

   // 4. Cancel expired pending orders
   CleanExpiredPendingOrders();

   // 5. Update Swings, Structure, and S/R Levels using confirmed closed candles
   UpdateSwingsAndStructure();
   UpdateSRZones();
   if(InpStrategyMode == MODE_ENHANCED && InpUseHtfPoi)
   {
      ScanHtfPois();
   }

   // 6. Check Spread Constraints
   long currentSpread = 0;
   SymbolInfoInteger(_Symbol, SYMBOL_SPREAD, currentSpread);
   if(currentSpread > InpMaxSpreadPoints)
   {
      if(InpEnableDebugLog) PrintFormat("[Filter] Trade rejected: Current spread (%d pts) > Max allowed (%d pts)", currentSpread, InpMaxSpreadPoints);
      return;
   }

   // 7. Check if active position already exists
   if(HasOpenPosition()) return;

   // 8. Fetch Execution Timeframe Rates (Closed candles shift 1 to 15)
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, _Period, 0, MathMax(MathMax(InpSwingScanBars, InpSRLookbackBars) + InpSwingConfirmBars + 10, 200), rates);
   if(copied < 50) return;

   // Determine Current Market Trend Context (Strict Swings in Book Exact)
   ENUM_MARKET_TREND trend = DetectMarketTrend();

   // ===============================================================
   // EVALUATE PRICE ACTION SETUPS (Evaluated strictly on Bar 1)
   // ===============================================================
   datetime signalBarTime = rates[1].time;

   // SETUP 1: PIN BAR (PDF Pages 53-63)
   if(InpEnablePinBar)
   {
      bool isBullPin = false, isBearPin = false;
      if(EvaluatePinBar(rates, 1, isBullPin, isBearPin))
      {
         string sigKey = StringFormat("%s_PINBAR_%s", TimeToString(signalBarTime), isBullPin ? "BUY" : "SELL");
         if(!IsSignalProcessed(signalBarTime, sigKey))
         {
            if(isBullPin && ValidateConfluence(rates[1], true, trend, false))
            {
               if(ExecutePinBarOrder(rates[1], true))
               {
                  RecordSignalProcessed(signalBarTime, sigKey);
                  return;
               }
            }
            else if(isBearPin && ValidateConfluence(rates[1], false, trend, false))
            {
               if(ExecutePinBarOrder(rates[1], false))
               {
                  RecordSignalProcessed(signalBarTime, sigKey);
                  return;
               }
            }
         }
      }
   }

   // SETUP 2: FAKEY FALSE-BREAKOUT (PDF Pages 87-97)
   if(InpEnableFakey)
   {
      bool isBullFakey = false, isBearFakey = false;
      double extremePrice = 0.0;
      if(EvaluateFakey(rates, 1, isBullFakey, isBearFakey, extremePrice))
      {
         string sigKey = StringFormat("%s_FAKEY_%s", TimeToString(signalBarTime), isBullFakey ? "BUY" : "SELL");
         if(!IsSignalProcessed(signalBarTime, sigKey))
         {
            if(isBullFakey && ValidateConfluence(rates[1], true, trend, true))
            {
               if(ExecuteFakeyOrder(rates[1], extremePrice, true))
               {
                  RecordSignalProcessed(signalBarTime, sigKey);
                  return;
               }
            }
            else if(isBearFakey && ValidateConfluence(rates[1], false, trend, true))
            {
               if(ExecuteFakeyOrder(rates[1], extremePrice, false))
               {
                  RecordSignalProcessed(signalBarTime, sigKey);
                  return;
               }
            }
         }
      }
   }

   // SETUP 3: INSIDE BAR BREAKOUT (PDF Pages 71-86)
   if(InpEnableInsideBar)
   {
      int motherShift = -1;
      int insideCount = 0;
      if(EvaluateInsideBarStructure(rates, 1, motherShift, insideCount))
      {
         string sigKey = StringFormat("%s_INSIDEBAR_M%s", TimeToString(signalBarTime), TimeToString(rates[motherShift].time));
         if(!IsSignalProcessed(signalBarTime, sigKey))
         {
            if(ExecuteInsideBarSetup(rates, motherShift, insideCount, trend))
            {
               RecordSignalProcessed(signalBarTime, sigKey);
               return;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| SWING DETECTION & MARKET STRUCTURE (PDF Pages 10-16)             |
//| N-bars Left, N-bars Right Confirmed Pivots (Zero Repaint)        |
//+------------------------------------------------------------------+
void UpdateSwingsAndStructure()
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int lookback = MathMax(MathMax(InpSwingScanBars, InpSRLookbackBars) + InpSwingConfirmBars + 10, 200);
   int copied = CopyRates(_Symbol, _Period, 0, lookback, rates);
   if(copied < (InpSwingConfirmBars * 2 + 10)) return;

   ArrayResize(m_swings, 0);

   // A candidate bar 'k' can ONLY be confirmed as a pivot after 'k - InpSwingConfirmBars' has closed
   // Therefore, the most recent candidate bar we can check is: shift = InpSwingConfirmBars + 1
   int startShift = InpSwingConfirmBars + 1;
   int endShift   = copied - InpSwingConfirmBars - 1;

   for(int k = startShift; k <= endShift; k++)
   {
      bool isPivotHigh = true;
      bool isPivotLow  = true;

      // Check Left and Right confirmation windows
      for(int w = 1; w <= InpSwingConfirmBars; w++)
      {
         if(rates[k].high <= rates[k + w].high || rates[k].high <= rates[k - w].high)
            isPivotHigh = false;

         if(rates[k].low >= rates[k + w].low || rates[k].low >= rates[k - w].low)
            isPivotLow = false;
      }

      if(isPivotHigh)
      {
         int sz = ArraySize(m_swings);
         ArrayResize(m_swings, sz + 1);
         m_swings[sz].price    = rates[k].high;
         m_swings[sz].time     = rates[k].time;
         m_swings[sz].barShift = k;
         m_swings[sz].isHigh   = true;

         if(InpDrawChartObjects)
         {
            string name = "SWING_H_" + TimeToString(rates[k].time);
            ObjectCreate(0, name, OBJ_TEXT, 0, rates[k].time, rates[k].high + (5.0 * m_pipSize));
            ObjectSetString(0, name, OBJPROP_TEXT, "SH");
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrSilver);
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
         }
      }
      else if(isPivotLow)
      {
         int sz = ArraySize(m_swings);
         ArrayResize(m_swings, sz + 1);
         m_swings[sz].price    = rates[k].low;
         m_swings[sz].time     = rates[k].time;
         m_swings[sz].barShift = k;
         m_swings[sz].isHigh   = false;

         if(InpDrawChartObjects)
         {
            string name = "SWING_L_" + TimeToString(rates[k].time);
            ObjectCreate(0, name, OBJ_TEXT, 0, rates[k].time, rates[k].low - (5.0 * m_pipSize));
            ObjectSetString(0, name, OBJPROP_TEXT, "SL");
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrSilver);
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| DETERMINE TREND CONTEXT VIA CONFIRMED SWINGS (PDF Pages 10-16)   |
//| Bullish: HH -> HL | Bearish: LH -> LL | Range: Neither           |
//+------------------------------------------------------------------+
ENUM_MARKET_TREND DetectMarketTrend()
{
   if(!InpRequireTrend) return TREND_RANGE; // Treat as all-market

   // 1. In BOOK_EXACT mode: Trend MUST be determined from swing structure
   if(InpStrategyMode == MODE_BOOK_EXACT)
   {
      int total = ArraySize(m_swings);
      if(total < 4) return TREND_RANGE;

      // Extract the 2 most recent confirmed highs and 2 most recent confirmed lows
      SSwingPivot high0 = {}, high1 = {}, low0 = {}, low1 = {};
      bool h0 = false, h1 = false, l0 = false, l1 = false;

      for(int i = 0; i < total; i++)
      {
         if(m_swings[i].isHigh)
         {
            if(!h0)      { high0 = m_swings[i]; h0 = true; }
            else if(!h1) { high1 = m_swings[i]; h1 = true; }
         }
         else
         {
            if(!l0)      { low0 = m_swings[i]; l0 = true; }
            else if(!l1) { low1 = m_swings[i]; l1 = true; }
         }
         if(h0 && h1 && l0 && l1) break;
      }

      if(!h0 || !h1 || !l0 || !l1) return TREND_RANGE;

      bool isHigherHigh = (high0.price > high1.price);
      bool isHigherLow  = (low0.price > low1.price);
      bool isLowerHigh  = (high0.price < high1.price);
      bool isLowerLow   = (low0.price < low1.price);

      if(isHigherHigh && isHigherLow) return TREND_BULLISH;
      if(isLowerHigh && isLowerLow)   return TREND_BEARISH;

      return TREND_RANGE; // Horizontal / Sideways / Mixed
   }

   // 2. In ENHANCED mode: Can optionally combine Market Structure with EMA
   if(InpStrategyMode == MODE_ENHANCED && InpUseEmaFilter)
   {
      double fastVal[2], slowVal[2];
      if(CopyBuffer(m_hFastEma, 0, 1, 2, fastVal) >= 2 && CopyBuffer(m_hSlowEma, 0, 1, 2, slowVal) >= 2)
      {
         if(fastVal[1] > slowVal[1]) return TREND_BULLISH;
         if(fastVal[1] < slowVal[1]) return TREND_BEARISH;
      }
   }

   return TREND_RANGE;
}

//+------------------------------------------------------------------+
//| HORIZONTAL SUPPORT & RESISTANCE CLUSTERING (PDF Pages 17-34)     |
//+------------------------------------------------------------------+
void UpdateSRZones()
{
   if(!InpEnableSRZones) return;

   int totalSwings = ArraySize(m_swings);
   if(totalSwings < 2) return;

   ArrayResize(m_srZones, 0);
   double zoneBand = InpSRZoneBandPips * m_pipSize;

   // Cluster nearby swing pivots into horizontal price bands
   for(int i = 0; i < totalSwings; i++)
   {
      // Respect configured historical S/R lookback bars
      if(InpSRLookbackBars > 0 && m_swings[i].barShift > InpSRLookbackBars) continue;

      double refPrice = m_swings[i].price;
      bool matched = false;

      // Check if price fits into an existing zone
      int currentZones = ArraySize(m_srZones);
      for(int z = 0; z < currentZones; z++)
      {
         if(MathAbs(refPrice - m_srZones[z].midPrice) <= zoneBand)
         {
            m_srZones[z].touchCount++;
            m_srZones[z].priceTop    = MathMax(m_srZones[z].priceTop, refPrice + (zoneBand * 0.5));
            m_srZones[z].priceBottom = MathMin(m_srZones[z].priceBottom, refPrice - (zoneBand * 0.5));
            m_srZones[z].midPrice    = (m_srZones[z].priceTop + m_srZones[z].priceBottom) * 0.5;
            m_srZones[z].lastTouchTime = MathMax(m_srZones[z].lastTouchTime, m_swings[i].time);
            matched = true;
            break;
         }
      }

      if(!matched)
      {
         ArrayResize(m_srZones, currentZones + 1);
         m_srZones[currentZones].priceTop    = refPrice + (zoneBand * 0.5);
         m_srZones[currentZones].priceBottom = refPrice - (zoneBand * 0.5);
         m_srZones[currentZones].midPrice    = refPrice;
         m_srZones[currentZones].touchCount  = 1;
         m_srZones[currentZones].isSupport   = !m_swings[i].isHigh;
         m_srZones[currentZones].isResistance= m_swings[i].isHigh;
         m_srZones[currentZones].isFlipped   = false;
         m_srZones[currentZones].lastTouchTime = m_swings[i].time;
         m_srZones[currentZones].objName     = "SR_Zone_" + TimeToString(m_swings[i].time);
      }
   }

   // Evaluate Level Flips based on current price interaction
   double currentClose = iClose(_Symbol, _Period, 1);
   int totalZones = ArraySize(m_srZones);
   for(int z = 0; z < totalZones; z++)
   {
      if(m_srZones[z].touchCount < InpSRMinTouches) continue;

      if(InpEnableLevelFlips)
      {
         // Resistance becomes Support (Price broke above and now holds above)
         if(m_srZones[z].isResistance && currentClose > m_srZones[z].priceTop)
         {
            m_srZones[z].isSupport    = true;
            m_srZones[z].isResistance = false;
            m_srZones[z].isFlipped    = true;
         }
         // Support becomes Resistance (Price broke below and now holds below)
         else if(m_srZones[z].isSupport && currentClose < m_srZones[z].priceBottom)
         {
            m_srZones[z].isResistance = true;
            m_srZones[z].isSupport    = false;
            m_srZones[z].isFlipped    = true;
         }
      }

      // Draw Zones on Chart
      if(InpDrawChartObjects)
      {
         datetime tStart = m_srZones[z].lastTouchTime;
         datetime tEnd   = TimeCurrent() + (PeriodSeconds(_Period) * 15);
         color zColor    = m_srZones[z].isSupport ? clrDodgerBlue : clrOrangeRed;

         if(ObjectFind(0, m_srZones[z].objName) < 0)
         {
            ObjectCreate(0, m_srZones[z].objName, OBJ_RECTANGLE, 0, tStart, m_srZones[z].priceTop, tEnd, m_srZones[z].priceBottom);
            ObjectSetInteger(0, m_srZones[z].objName, OBJPROP_COLOR, zColor);
            ObjectSetInteger(0, m_srZones[z].objName, OBJPROP_FILL, false);
            ObjectSetInteger(0, m_srZones[z].objName, OBJPROP_WIDTH, 1);
         }
         else
         {
            ObjectSetInteger(0, m_srZones[z].objName, OBJPROP_TIME, 1, tEnd);
            ObjectSetInteger(0, m_srZones[z].objName, OBJPROP_COLOR, zColor);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| CHECK CANDLE INTERACTION WITH KEY S/R LEVELS                     |
//+------------------------------------------------------------------+
bool IsCandleInteractingWithSR(const MqlRates &candle, bool forBuy, bool &isFlippedLevel)
{
   if(!InpEnableSRZones) return true;

   isFlippedLevel = false;
   int total = ArraySize(m_srZones);

   for(int z = 0; z < total; z++)
   {
      if(m_srZones[z].touchCount < InpSRMinTouches) continue;

      if(forBuy && m_srZones[z].isSupport)
      {
         if(candle.low <= m_srZones[z].priceTop && candle.high >= m_srZones[z].priceBottom)
         {
            isFlippedLevel = m_srZones[z].isFlipped;
            return true;
         }
      }
      else if(!forBuy && m_srZones[z].isResistance)
      {
         if(candle.high >= m_srZones[z].priceBottom && candle.low <= m_srZones[z].priceTop)
         {
            isFlippedLevel = m_srZones[z].isFlipped;
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| 50% SWING RETRACEMENT CONFLUENCE (PDF Pages 61, 66)              |
//| Calculates midpoint of the dominant confirmed impulse swing      |
//+------------------------------------------------------------------+
bool IsTesting50PercentSwingRetrace(const MqlRates &candle, bool forBuy)
{
   if(!InpUse50SwingRetrace) return true; // Confluence not required by configuration

   int total = ArraySize(m_swings);
   if(total < 2) return false; // CRITICAL: Insufficient swings = NO confluence

   // Find the most recent opposing swing pair
   SSwingPivot lastHigh = {}, lastLow = {};
   bool foundHigh = false, foundLow = false;

   for(int i = 0; i < total; i++)
   {
      if(m_swings[i].isHigh && !foundHigh) { lastHigh = m_swings[i]; foundHigh = true; }
      if(!m_swings[i].isHigh && !foundLow)  { lastLow  = m_swings[i]; foundLow  = true; }
      if(foundHigh && foundLow) break;
   }

   if(!foundHigh || !foundLow) return false; // Insufficient data = reject

   // CRITICAL: Chronological direction verification
   // Bullish impulse: Low occurred first (older, lower time), High occurred second (newer, higher time)
   if(forBuy && (lastLow.time >= lastHigh.time))
   {
      return false; // Not a valid upward impulse wave
   }
   // Bearish impulse: High occurred first (older, lower time), Low occurred second (newer, higher time)
   if(!forBuy && (lastHigh.time >= lastLow.time))
   {
      return false; // Not a valid downward impulse wave
   }

   double swingRange = MathAbs(lastHigh.price - lastLow.price);
   if(swingRange <= (5.0 * m_pipSize)) return false;

   double mid50Price = (lastHigh.price + lastLow.price) * 0.5;
   double tolerance  = InpSwing50TolerancePips * m_pipSize;

   // Check if candle range overlaps the 50% midpoint
   if(candle.high >= (mid50Price - tolerance) && candle.low <= (mid50Price + tolerance))
   {
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| CONFLUENCE ENGINE VALIDATION (PDF Pages 64-70)                   |
//| T.T.L.F: Trend, Level, Signal, 50% Retracement                   |
//+------------------------------------------------------------------+
bool ValidateConfluence(const MqlRates &candle, bool forBuy, ENUM_MARKET_TREND trend, bool isFakey)
{
   // 1. Horizontal S/R Level Interaction Check
   bool isFlipped = false;
   bool levelValid = IsCandleInteractingWithSR(candle, forBuy, isFlipped);

   // 2. Trend Alignment Check
   bool trendValid = false;
   if(forBuy)  trendValid = (trend == TREND_BULLISH || trend == TREND_RANGE);
   if(!forBuy) trendValid = (trend == TREND_BEARISH || trend == TREND_RANGE);

   // Special PDF Rule (Page 92): Counter-trend Fakeys are valid ONLY at confirmed Key Levels
   if(isFakey)
   {
      bool isCounterTrend = (forBuy && trend == TREND_BEARISH) || (!forBuy && trend == TREND_BULLISH);
      if((isCounterTrend || trend == TREND_RANGE) && InpFakeyRequireKeyLevel)
      {
         if(!levelValid)
         {
            if(InpEnableDebugLog) Print("[Fakey Rejected] Counter-trend or range fakey requires a confirmed Key S/R level.");
            return false;
         }
         trendValid = true; // Key level satisfies confluence for Fakey reversal
      }
   }

   if(!trendValid)
   {
      if(InpEnableDebugLog) Print("[Confluence Failed] Setup against dominant market structure.");
      return false;
   }

   // 3. 50% Swing Retracement Confluence Check
   bool swing50Valid = IsTesting50PercentSwingRetrace(candle, forBuy);

   // In BOOK_EXACT mode: We require Trend + (Level OR 50% Retracement)
   if(InpStrategyMode == MODE_BOOK_EXACT)
   {
      if(!levelValid && !swing50Valid)
      {
         if(InpEnableDebugLog) Print("[Confluence Failed] No Key S/R level or 50% swing retrace confluence.");
         return false;
      }
      return true;
   }

   // 4. In ENHANCED mode: Layer Optional RSI, VSA, and HTF POI
   if(InpStrategyMode == MODE_ENHANCED)
   {
      // Optional RSI Filter
      if(InpUseRsiFilter)
      {
         double rsiVal = 50.0;
         double rsiBuf[1];
         if(CopyBuffer(m_hRsi, 0, 1, 1, rsiBuf) > 0)
         {
            rsiVal = rsiBuf[0];
            if(forBuy && rsiVal >= InpRsiOverbought) return false;
            if(!forBuy && rsiVal <= InpRsiOversold)   return false;
         }
      }

      // Optional VSA Filter
      if(!ValidateVsaCondition(1, forBuy))
      {
         if(InpEnableDebugLog) Print("[Enhanced VSA Failed] Volume conditions did not confirm setup.");
         return false;
      }

      // Optional HTF POI Interaction
      if(InpUseHtfPoi && !IsCandleInteractingWithHtfPoi(candle, forBuy))
      {
         if(InpEnableDebugLog) Print("[Enhanced POI Failed] Candle did not interact with HTF Order Block.");
         return false;
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| PIN BAR EVALUATION (PDF Pages 53-63)                             |
//+------------------------------------------------------------------+
bool EvaluatePinBar(const MqlRates &rates[], int i, bool &isBullish, bool &isBearish)
{
   isBullish = false;
   isBearish = false;

   double range = rates[i].high - rates[i].low;
   if(range <= (2.0 * m_point)) return false;

   double body      = MathAbs(rates[i].close - rates[i].open);
   double upperWick = rates[i].high - MathMax(rates[i].open, rates[i].close);
   double lowerWick = MathMin(rates[i].open, rates[i].close) - rates[i].low;

   // 1. Ratio Test: Tail >= 2/3 (66.7%), Real Body <= 1/3 (33.3%)
   if((body / range) > InpPinMaxBodyRatio) return false;

   // 2. Protrusion Test: Tail must protrude beyond surrounding bars
   bool protrudesLow  = true;
   bool protrudesHigh = true;

   for(int b = 1; b <= InpPinProtrudeLookback; b++)
   {
      if((i + b) < ArraySize(rates))
      {
         if(rates[i].low >= rates[i + b].low)   protrudesLow  = false;
         if(rates[i].high <= rates[i + b].high) protrudesHigh = false;
      }
   }

   if((lowerWick / range) >= InpPinMinWickRatio && protrudesLow)
   {
      isBullish = true;
      return true;
   }
   if((upperWick / range) >= InpPinMinWickRatio && protrudesHigh)
   {
      isBearish = true;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| INSIDE BAR EVALUATION & COILING SUPPORT (PDF Pages 71-86)        |
//+------------------------------------------------------------------+
bool EvaluateInsideBarStructure(const MqlRates &rates[], int i, int &motherShift, int &insideCount)
{
   motherShift = -1;
   insideCount = 0;

   // Bar i must be contained within Bar i+1
   if(rates[i].high > rates[i + 1].high || rates[i].low < rates[i + 1].low)
      return false;

   // Count consecutive coiled inside bars
   insideCount = 1;
   int currentMother = i + 1;

   for(int b = 1; b < InpIBMaxNestingBars; b++)
   {
      int candidateShift = currentMother + 1;
      if(candidateShift >= ArraySize(rates)) break;

      // Check if current mother was also inside a larger mother
      if(rates[currentMother].high <= rates[candidateShift].high && 
         rates[currentMother].low >= rates[candidateShift].low)
      {
         currentMother = candidateShift;
         insideCount++;
      }
      else break;
   }

   motherShift = currentMother;
   return true;
}

//+------------------------------------------------------------------+
//| FAKEY EVALUATION & CLEAR FALSE-BREAK THRESHOLD (PDF Pages 87-97) |
//+------------------------------------------------------------------+
bool EvaluateFakey(const MqlRates &rates[], int i, bool &isBullFakey, bool &isBearFakey, double &extremePrice)
{
   isBullFakey = false;
   isBearFakey = false;
   extremePrice = 0.0;

   // Bar i = False-break candle
   // Bar i+1 = Inside bar (or last of coiling inside bars)
   // Bar i+2 = Mother bar
   if(rates[i + 1].high > rates[i + 2].high || rates[i + 1].low < rates[i + 2].low)
      return false;

   double minBreak = InpFakeyMinBreakPoints * m_point;

   // Bullish Fakey: Penetrated below Inside Bar Low by at least minBreak, closed back above
   if(rates[i].low <= (rates[i + 1].low - minBreak) && rates[i].close > rates[i + 1].low)
   {
      isBullFakey  = true;
      extremePrice = rates[i].low;
      return true;
   }

   // Bearish Fakey: Penetrated above Inside Bar High by at least minBreak, closed back below
   if(rates[i].high >= (rates[i + 1].high + minBreak) && rates[i].close < rates[i + 1].high)
   {
      isBearFakey  = true;
      extremePrice = rates[i].high;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| STRICT POSITION SIZING & RISK MANAGEMENT                         |
//| Rejects trade cleanly if risk calculation fails or exceeds cap   |
//+------------------------------------------------------------------+
bool CalculateStrictLotSize(double entryPrice, double slPrice, double &outLotSize)
{
   outLotSize = 0.0;

   if(InpLotMode == LOT_FIXED_SIZE)
   {
      outLotSize = InpFixedLotSize;
      return true;
   }

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance <= 0.0) return false;

   double targetRiskCash = balance * (InpRiskPercent / 100.0);
   double slDistancePoints = MathAbs(entryPrice - slPrice) / m_point;

   if(slDistancePoints <= 0.0) return false;

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tickSize <= 0.0 || tickValue <= 0.0) return false;

   double riskPerLot = (slDistancePoints * m_point / tickSize) * tickValue;
   if(riskPerLot <= 0.0) return false;

   double rawLot = targetRiskCash / riskPerLot;

   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   double normalizedLot = MathFloor(rawLot / stepLot) * stepLot;

   // If normalized lot is less than broker minLot
   if(normalizedLot < minLot)
   {
      double actualCashRiskAtMinLot = minLot * riskPerLot;
      double actualRiskPercent = (actualCashRiskAtMinLot / balance) * 100.0;

      // Reject if forced minLot exceeds our risk tolerance cap
      if(actualRiskPercent > (InpRiskPercent * InpMaxRiskPercentCap))
      {
         PrintFormat("[Risk Rejected] Balance $%.2f too small for SL distance (%.1f pts). Risk would be %.2f%% > Cap %.2f%%",
                     balance, slDistancePoints, actualRiskPercent, InpRiskPercent * InpMaxRiskPercentCap);
         return false;
      }
      normalizedLot = minLot;
   }

   normalizedLot = MathMin(maxLot, normalizedLot);
   outLotSize    = NormalizeDouble(normalizedLot, 2);
   return true;
}

//+------------------------------------------------------------------+
//| BROKER STOP LEVEL & FREEZE LEVEL VALIDATION                      |
//+------------------------------------------------------------------+
bool ValidateBrokerDistance(double orderPrice, double slPrice, double tpPrice)
{
   long stopsLevel = 0;
   SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL, stopsLevel);
   double minStopsDist = stopsLevel * m_point;

   long freezeLevel = 0;
   SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL, freezeLevel);
   double minFreezeDist = freezeLevel * m_point;

   // Use the larger of stops-level and freeze-level
   double minDistance = MathMax(minStopsDist, minFreezeDist);

   if(MathAbs(orderPrice - slPrice) < minDistance)
   {
      if(InpEnableDebugLog) PrintFormat("[Broker Validation Failed] SL distance (%f) < MinDistance (%f) [Stops=%d, Freeze=%d]",
         MathAbs(orderPrice - slPrice), minDistance, stopsLevel, freezeLevel);
      return false;
   }
   if(tpPrice > 0.0 && MathAbs(orderPrice - tpPrice) < minDistance)
   {
      if(InpEnableDebugLog) PrintFormat("[Broker Validation Failed] TP distance (%f) < MinDistance (%f) [Stops=%d, Freeze=%d]",
         MathAbs(orderPrice - tpPrice), minDistance, stopsLevel, freezeLevel);
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| EXECUTION: PIN BAR ORDER                                         |
//+------------------------------------------------------------------+
bool ExecutePinBarOrder(const MqlRates &pin, bool isBuy)
{
   double slPrice = 0.0;
   double entryPrice = 0.0;
   double tpPrice = 0.0;
   double lot = 0.0;
   string modeTag = (InpStrategyMode == MODE_BOOK_EXACT) ? "[BOOK_EXACT]" : "[ENHANCED]";

   if(isBuy)
   {
      slPrice = pin.low - (InpStopLossBufferPips * m_pipSize);

      if(InpPinEntryMode == PIN_ENTRY_MARKET_ON_CLOSE)
      {
         entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if(!CalculateStrictLotSize(entryPrice, slPrice, lot)) return false;
         tpPrice = CalculateTakeProfit(entryPrice, slPrice, true);

         if(!ValidateBrokerDistance(entryPrice, slPrice, tpPrice)) return false;
         if(m_trade.Buy(lot, _Symbol, entryPrice, slPrice, tpPrice, modeTag + " PinBar_Buy"))
         {
            uint retcode = m_trade.ResultRetcode();
            if(retcode != TRADE_RETCODE_DONE && retcode != TRADE_RETCODE_PLACED)
            {
               PrintFormat("[EXEC FAILED] Buy PinBar retcode=%u desc=%s", retcode, m_trade.ResultRetcodeDescription());
               return false;
            }
            // Get actual position ticket via deal→position mapping
            ulong dealTicket = m_trade.ResultDeal();
            ulong posTicket = 0;
            if(dealTicket > 0 && HistoryDealSelect(dealTicket))
               posTicket = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
            if(posTicket == 0) posTicket = m_trade.ResultOrder(); // fallback for pending
            if(posTicket == 0) { PrintFormat("[EXEC WARNING] Buy PinBar: no position ticket obtained"); return false; }
            PrintFormat("[EXEC OK] Buy PinBar deal=%I64u pos=%I64u retcode=%u", dealTicket, posTicket, retcode);
            RegisterPositionTrack(posTicket, entryPrice, slPrice, tpPrice, POSITION_TYPE_BUY, "PinBar_Buy");
            if(InpDrawChartObjects) DrawSignalMarker(pin.time, pin.low, "Pin Buy", clrLimeGreen, true);
            return true;
         }
         else
         {
            PrintFormat("[EXEC FAILED] Buy PinBar m_trade.Buy returned false. retcode=%u desc=%s",
               m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
         }
      }
      else // 50% Limit Entry (PDF Page 62)
      {
         entryPrice = pin.low + ((pin.high - pin.low) * 0.50);
         double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

         // CRITICAL: Reject order if price has already crossed past 50% level
         // Never silently modify entry away from 50% (Prompt Section 11)
         if(entryPrice >= currentAsk)
         {
            if(InpEnableDebugLog) PrintFormat("[PinBar 50%% Rejected] Current Ask (%f) is at/below 50%% entry (%f). Strategy rejects modified price.", currentAsk, entryPrice);
            return false;
         }

         if(!CalculateStrictLotSize(entryPrice, slPrice, lot)) return false;
         tpPrice = CalculateTakeProfit(entryPrice, slPrice, true);

         if(!ValidateBrokerDistance(entryPrice, slPrice, tpPrice)) return false;
         // Check symbol expiration support
         int expMode = (int)SymbolInfoInteger(_Symbol, SYMBOL_EXPIRATION_MODE);
         ENUM_ORDER_TYPE_TIME orderTimeType = ORDER_TIME_GTC;
         datetime expiry = 0;
         if((expMode & SYMBOL_EXPIRATION_SPECIFIED) != 0)
         {
            orderTimeType = ORDER_TIME_SPECIFIED;
            expiry = TimeCurrent() + (InpPinLimitExpiryBars * PeriodSeconds(_Period));
         }

         if(m_trade.BuyLimit(lot, entryPrice, _Symbol, slPrice, tpPrice, orderTimeType, expiry, modeTag + " Pin_50_Limit"))
         {
            uint retcode = m_trade.ResultRetcode();
            if(retcode != TRADE_RETCODE_DONE && retcode != TRADE_RETCODE_PLACED)
            {
               PrintFormat("[EXEC FAILED] BuyLimit PinBar retcode=%u desc=%s", retcode, m_trade.ResultRetcodeDescription());
               return false;
            }
            PrintFormat("[EXEC OK] BuyLimit PinBar order=%I64u retcode=%u", m_trade.ResultOrder(), retcode);
            if(InpDrawChartObjects) DrawSignalMarker(pin.time, entryPrice, "50% BuyLimit", clrLimeGreen, true);
            return true;
         }
         else
         {
            PrintFormat("[EXEC FAILED] BuyLimit PinBar m_trade.BuyLimit returned false. retcode=%u desc=%s",
               m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
         }
      }
   }
   else // Sell Pin Bar
   {
      slPrice = pin.high + (InpStopLossBufferPips * m_pipSize);

      if(InpPinEntryMode == PIN_ENTRY_MARKET_ON_CLOSE)
      {
         entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         if(!CalculateStrictLotSize(entryPrice, slPrice, lot)) return false;
         tpPrice = CalculateTakeProfit(entryPrice, slPrice, false);

         if(!ValidateBrokerDistance(entryPrice, slPrice, tpPrice)) return false;
         if(m_trade.Sell(lot, _Symbol, entryPrice, slPrice, tpPrice, modeTag + " PinBar_Sell"))
         {
            uint retcode = m_trade.ResultRetcode();
            if(retcode != TRADE_RETCODE_DONE && retcode != TRADE_RETCODE_PLACED)
            {
               PrintFormat("[EXEC FAILED] Sell PinBar retcode=%u desc=%s", retcode, m_trade.ResultRetcodeDescription());
               return false;
            }
            ulong dealTicket = m_trade.ResultDeal();
            ulong posTicket = 0;
            if(dealTicket > 0 && HistoryDealSelect(dealTicket))
               posTicket = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
            if(posTicket == 0) posTicket = m_trade.ResultOrder();
            if(posTicket == 0) { PrintFormat("[EXEC WARNING] Sell PinBar: no position ticket obtained"); return false; }
            PrintFormat("[EXEC OK] Sell PinBar deal=%I64u pos=%I64u retcode=%u", dealTicket, posTicket, retcode);
            RegisterPositionTrack(posTicket, entryPrice, slPrice, tpPrice, POSITION_TYPE_SELL, "PinBar_Sell");
            if(InpDrawChartObjects) DrawSignalMarker(pin.time, pin.high, "Pin Sell", clrCrimson, false);
            return true;
         }
         else
         {
            PrintFormat("[EXEC FAILED] Sell PinBar m_trade.Sell returned false. retcode=%u desc=%s",
               m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
         }
      }
      else // 50% Limit Entry (PDF Page 62)
      {
         entryPrice = pin.high - ((pin.high - pin.low) * 0.50);
         double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

         // CRITICAL: Reject order if price has already crossed past 50% level
         if(entryPrice <= currentBid)
         {
            if(InpEnableDebugLog) PrintFormat("[PinBar 50%% Rejected] Current Bid (%f) is at/above 50%% entry (%f). Strategy rejects modified price.", currentBid, entryPrice);
            return false;
         }

         if(!CalculateStrictLotSize(entryPrice, slPrice, lot)) return false;
         tpPrice = CalculateTakeProfit(entryPrice, slPrice, false);

         if(!ValidateBrokerDistance(entryPrice, slPrice, tpPrice)) return false;
         int expMode = (int)SymbolInfoInteger(_Symbol, SYMBOL_EXPIRATION_MODE);
         ENUM_ORDER_TYPE_TIME orderTimeType = ORDER_TIME_GTC;
         datetime expiry = 0;
         if((expMode & SYMBOL_EXPIRATION_SPECIFIED) != 0)
         {
            orderTimeType = ORDER_TIME_SPECIFIED;
            expiry = TimeCurrent() + (InpPinLimitExpiryBars * PeriodSeconds(_Period));
         }

         if(m_trade.SellLimit(lot, entryPrice, _Symbol, slPrice, tpPrice, orderTimeType, expiry, modeTag + " Pin_50_Limit"))
         {
            uint retcode = m_trade.ResultRetcode();
            if(retcode != TRADE_RETCODE_DONE && retcode != TRADE_RETCODE_PLACED)
            {
               PrintFormat("[EXEC FAILED] SellLimit PinBar retcode=%u desc=%s", retcode, m_trade.ResultRetcodeDescription());
               return false;
            }
            PrintFormat("[EXEC OK] SellLimit PinBar order=%I64u retcode=%u", m_trade.ResultOrder(), retcode);
            if(InpDrawChartObjects) DrawSignalMarker(pin.time, entryPrice, "50% SellLimit", clrCrimson, false);
            return true;
         }
         else
         {
            PrintFormat("[EXEC FAILED] SellLimit PinBar m_trade.SellLimit returned false. retcode=%u desc=%s",
               m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| EXECUTION: FAKEY ORDER                                           |
//+------------------------------------------------------------------+
bool ExecuteFakeyOrder(const MqlRates &bar, double falseBreakExtreme, bool isBuy)
{
   double lot = 0.0;
   string modeTag = (InpStrategyMode == MODE_BOOK_EXACT) ? "[BOOK_EXACT]" : "[ENHANCED]";

   if(isBuy)
   {
      double entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double slPrice    = falseBreakExtreme - (InpStopLossBufferPips * m_pipSize);
      if(!CalculateStrictLotSize(entryPrice, slPrice, lot)) return false;
      double tpPrice    = CalculateTakeProfit(entryPrice, slPrice, true);

      if(!ValidateBrokerDistance(entryPrice, slPrice, tpPrice)) return false;
      if(m_trade.Buy(lot, _Symbol, entryPrice, slPrice, tpPrice, modeTag + " Fakey_Buy"))
      {
         uint retcode = m_trade.ResultRetcode();
         if(retcode != TRADE_RETCODE_DONE && retcode != TRADE_RETCODE_PLACED)
         {
            PrintFormat("[EXEC FAILED] Buy Fakey retcode=%u desc=%s", retcode, m_trade.ResultRetcodeDescription());
            return false;
         }
         ulong dealTicket = m_trade.ResultDeal();
         ulong posTicket = 0;
         if(dealTicket > 0 && HistoryDealSelect(dealTicket))
            posTicket = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
         if(posTicket == 0) posTicket = m_trade.ResultOrder();
         if(posTicket == 0) { PrintFormat("[EXEC WARNING] Buy Fakey: no position ticket"); return false; }
         PrintFormat("[EXEC OK] Buy Fakey deal=%I64u pos=%I64u retcode=%u", dealTicket, posTicket, retcode);
         RegisterPositionTrack(posTicket, entryPrice, slPrice, tpPrice, POSITION_TYPE_BUY, "Fakey_Buy");
         if(InpDrawChartObjects) DrawSignalMarker(bar.time, bar.low, "Fakey Buy", clrLimeGreen, true);
         return true;
      }
      else
      {
         PrintFormat("[EXEC FAILED] Buy Fakey m_trade.Buy returned false. retcode=%u desc=%s",
            m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
      }
   }
   else
   {
      double entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double slPrice    = falseBreakExtreme + (InpStopLossBufferPips * m_pipSize);
      if(!CalculateStrictLotSize(entryPrice, slPrice, lot)) return false;
      double tpPrice    = CalculateTakeProfit(entryPrice, slPrice, false);

      if(!ValidateBrokerDistance(entryPrice, slPrice, tpPrice)) return false;
      if(m_trade.Sell(lot, _Symbol, entryPrice, slPrice, tpPrice, modeTag + " Fakey_Sell"))
      {
         uint retcode = m_trade.ResultRetcode();
         if(retcode != TRADE_RETCODE_DONE && retcode != TRADE_RETCODE_PLACED)
         {
            PrintFormat("[EXEC FAILED] Sell Fakey retcode=%u desc=%s", retcode, m_trade.ResultRetcodeDescription());
            return false;
         }
         ulong dealTicket = m_trade.ResultDeal();
         ulong posTicket = 0;
         if(dealTicket > 0 && HistoryDealSelect(dealTicket))
            posTicket = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
         if(posTicket == 0) posTicket = m_trade.ResultOrder();
         if(posTicket == 0) { PrintFormat("[EXEC WARNING] Sell Fakey: no position ticket"); return false; }
         PrintFormat("[EXEC OK] Sell Fakey deal=%I64u pos=%I64u retcode=%u", dealTicket, posTicket, retcode);
         RegisterPositionTrack(posTicket, entryPrice, slPrice, tpPrice, POSITION_TYPE_SELL, "Fakey_Sell");
         if(InpDrawChartObjects) DrawSignalMarker(bar.time, bar.high, "Fakey Sell", clrCrimson, false);
         return true;
      }
      else
      {
         PrintFormat("[EXEC FAILED] Sell Fakey m_trade.Sell returned false. retcode=%u desc=%s",
            m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| EXECUTION: INSIDE BAR SETUP WITH RESTART-SAFE OCO MANAGEMENT     |
//+------------------------------------------------------------------+
bool ExecuteInsideBarSetup(const MqlRates &rates[], int motherShift, int insideCount, ENUM_MARKET_TREND trend)
{
   const MqlRates mother = rates[motherShift];
   int expMode = (int)SymbolInfoInteger(_Symbol, SYMBOL_EXPIRATION_MODE);
   ENUM_ORDER_TYPE_TIME orderTimeType = ORDER_TIME_GTC;
   datetime expiry = 0;
   if((expMode & SYMBOL_EXPIRATION_SPECIFIED) != 0)
   {
      orderTimeType = ORDER_TIME_SPECIFIED;
      expiry = TimeCurrent() + (InpIBOrderExpiryBars * PeriodSeconds(_Period));
   }
   double buffer = InpIBBreakoutBufferPips * m_pipSize;
   string modeTag = (InpStrategyMode == MODE_BOOK_EXACT) ? "[BOOK_EXACT]" : "[ENHANCED]";

   bool allowBuy  = false;
   bool allowSell = false;

   // 1. Continuation Mode (Evaluated independently)
   if(InpIBContinuationOnly)
   {
      if(trend == TREND_BULLISH) allowBuy  = true;
      if(trend == TREND_BEARISH) allowSell = true;
   }

   // 2. Reversal Mode (Evaluated independently - Prompt Section 14)
   if(InpIBReversalAtLevels)
   {
      bool isFlipped = false;
      if(IsCandleInteractingWithSR(mother, true, isFlipped))  allowBuy  = true;
      if(IsCandleInteractingWithSR(mother, false, isFlipped)) allowSell = true;
   }

   // 3. Fallback if both modes disabled: allow dual breakout
   if(!InpIBContinuationOnly && !InpIBReversalAtLevels)
   {
      allowBuy  = true;
      allowSell = true;
   }

   if(!allowBuy && !allowSell) return false;

   string pairTag = StringFormat("IB_OCO_%I64d", (long)mother.time);
   ulong buyTicket = 0, sellTicket = 0;

   // 1. Buy Stop Order
   if(allowBuy)
   {
      double buyPrice = mother.high + buffer;
      double slPrice  = mother.low - (InpStopLossBufferPips * m_pipSize);
      double lot = 0.0;
      if(CalculateStrictLotSize(buyPrice, slPrice, lot))
      {
         double tpPrice = CalculateTakeProfit(buyPrice, slPrice, true);
         if(ValidateBrokerDistance(buyPrice, slPrice, tpPrice))
         {
            string comment = StringFormat("%s IB_BuyStop [%s]", modeTag, pairTag);
            if(m_trade.BuyStop(lot, buyPrice, _Symbol, slPrice, tpPrice, orderTimeType, expiry, comment))
            {
               uint retcode = m_trade.ResultRetcode();
               if(retcode == TRADE_RETCODE_DONE || retcode == TRADE_RETCODE_PLACED)
               {
                  buyTicket = m_trade.ResultOrder();
                  PrintFormat("[EXEC OK] BuyStop IB order=%I64u retcode=%u", buyTicket, retcode);
               }
               else
                  PrintFormat("[EXEC FAILED] BuyStop IB retcode=%u desc=%s", retcode, m_trade.ResultRetcodeDescription());
            }
            else
               PrintFormat("[EXEC FAILED] BuyStop IB returned false. retcode=%u desc=%s", m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
         }
      }
   }

   // 2. Sell Stop Order
   if(allowSell)
   {
      double sellPrice = mother.low - buffer;
      double slPrice   = mother.high + (InpStopLossBufferPips * m_pipSize);
      double lot = 0.0;
      if(CalculateStrictLotSize(sellPrice, slPrice, lot))
      {
         double tpPrice = CalculateTakeProfit(sellPrice, slPrice, false);
         if(ValidateBrokerDistance(sellPrice, slPrice, tpPrice))
         {
            string comment = StringFormat("%s IB_SellStop [%s]", modeTag, pairTag);
            if(m_trade.SellStop(lot, sellPrice, _Symbol, slPrice, tpPrice, orderTimeType, expiry, comment))
            {
               uint retcode = m_trade.ResultRetcode();
               if(retcode == TRADE_RETCODE_DONE || retcode == TRADE_RETCODE_PLACED)
               {
                  sellTicket = m_trade.ResultOrder();
                  PrintFormat("[EXEC OK] SellStop IB order=%I64u retcode=%u", sellTicket, retcode);
               }
               else
                  PrintFormat("[EXEC FAILED] SellStop IB retcode=%u desc=%s", retcode, m_trade.ResultRetcodeDescription());
            }
            else
               PrintFormat("[EXEC FAILED] SellStop IB returned false. retcode=%u desc=%s", m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
         }
      }
   }

   // Register into RAM pair tracker
   if(buyTicket > 0 || sellTicket > 0)
   {
      if(buyTicket > 0 && sellTicket > 0)
      {
         int ocoSz = ArraySize(m_ocoPairs);
         ArrayResize(m_ocoPairs, ocoSz + 1);
         m_ocoPairs[ocoSz].buyStopTicket  = buyTicket;
         m_ocoPairs[ocoSz].sellStopTicket = sellTicket;
         m_ocoPairs[ocoSz].placedTime     = TimeCurrent();
         m_ocoPairs[ocoSz].isActive       = true;
         m_ocoPairs[ocoSz].pairTag        = pairTag;
      }
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| TAKE PROFIT CALCULATION ENGINE                                   |
//+------------------------------------------------------------------+
double CalculateTakeProfit(double entryPrice, double slPrice, bool isBuy)
{
   double riskDist = MathAbs(entryPrice - slPrice);

   if(InpExitMode == EXIT_FIXED_RR)
   {
      return isBuy ? (entryPrice + riskDist * InpRiskRewardRatio)
                   : (entryPrice - riskDist * InpRiskRewardRatio);
   }
   else if(InpExitMode == EXIT_NEXT_SWING_LEVEL)
   {
      // Target the nearest opposing confirmed swing point
      int total = ArraySize(m_swings);
      for(int i = 0; i < total; i++)
      {
         if(isBuy && m_swings[i].isHigh && m_swings[i].price > (entryPrice + riskDist))
            return m_swings[i].price;

         if(!isBuy && !m_swings[i].isHigh && m_swings[i].price < (entryPrice - riskDist))
            return m_swings[i].price;
      }
      // Fallback to fixed RR if no structural swing target found
      return isBuy ? (entryPrice + riskDist * InpRiskRewardRatio)
                   : (entryPrice - riskDist * InpRiskRewardRatio);
   }
   else if(InpExitMode == EXIT_TRAILING_ONLY)
   {
      return 0.0; // Open-ended target, managed exclusively via trailing stop
   }

   return isBuy ? (entryPrice + riskDist * InpRiskRewardRatio)
                : (entryPrice - riskDist * InpRiskRewardRatio);
}

//+------------------------------------------------------------------+
//| POSITION MANAGEMENT: BREAK-EVEN & TRAILING STOP                  |
//| Preserves Initial Risk Constant via Persistent Global Variables  |
//+------------------------------------------------------------------+
void ManageActivePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;

      ulong ticket = m_position.Ticket();
      int trackIdx = FindTrackedPositionIndex(ticket);

      // Persistent Storage Retrieval (Survives EA Restarts)
      string gvName = StringFormat("PA_INIT_SL_%I64u", ticket);
      double initialSL = 0.0;

      if(trackIdx >= 0)
      {
         initialSL = m_trackedPositions[trackIdx].initialSL;
      }
      else
      {
         if(GlobalVariableCheck(gvName))
         {
            initialSL = GlobalVariableGet(gvName);
         }
         else
         {
            initialSL = m_position.StopLoss();
            GlobalVariableSet(gvName, initialSL);
         }
         RegisterPositionTrack(ticket, m_position.PriceOpen(), initialSL, 
                               m_position.TakeProfit(), m_position.PositionType(), m_position.Comment());
         trackIdx = FindTrackedPositionIndex(ticket);
         if(trackIdx < 0) continue;
      }

      double initialRiskPts = m_trackedPositions[trackIdx].initialRiskPoints;
      if(initialRiskPts <= 0.0) continue;

      double currentPrice = m_position.PriceCurrent();
      double currentSL    = m_position.StopLoss();
      double currentTP    = m_position.TakeProfit();
      double openPrice    = m_trackedPositions[trackIdx].openPrice;
      ENUM_POSITION_TYPE type = m_position.PositionType();

      // 1. BREAK-EVEN PROTECTION
      if(InpUseBreakEven && !m_trackedPositions[trackIdx].breakEvenApplied)
      {
         double beTriggerDist = initialRiskPts * InpBreakEvenTriggerRR * m_point;

         if(type == POSITION_TYPE_BUY)
         {
            if(currentPrice >= (openPrice + beTriggerDist))
            {
               double newSL = openPrice + (InpBreakEvenLockPips * m_pipSize);
               if(newSL > currentSL)
               {
                  if(m_trade.PositionModify(ticket, newSL, currentTP))
                  {
                     uint retcode = m_trade.ResultRetcode();
                     if(retcode == TRADE_RETCODE_DONE)
                     {
                        m_trackedPositions[trackIdx].breakEvenApplied = true;
                        PrintFormat("[Break-Even OK] Position #%I64u moved to BE at %f retcode=%u", ticket, newSL, retcode);
                     }
                     else
                        PrintFormat("[Break-Even WARN] Position #%I64u modify retcode=%u desc=%s", ticket, retcode, m_trade.ResultRetcodeDescription());
                  }
                  else
                     PrintFormat("[Break-Even FAILED] Position #%I64u PositionModify returned false. retcode=%u desc=%s", ticket, m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
               }
            }
         }
         else if(type == POSITION_TYPE_SELL)
         {
            if(currentPrice <= (openPrice - beTriggerDist))
            {
               double newSL = openPrice - (InpBreakEvenLockPips * m_pipSize);
               if(newSL < currentSL || currentSL == 0.0)
               {
                  if(m_trade.PositionModify(ticket, newSL, currentTP))
                  {
                     uint retcode = m_trade.ResultRetcode();
                     if(retcode == TRADE_RETCODE_DONE)
                     {
                        m_trackedPositions[trackIdx].breakEvenApplied = true;
                        PrintFormat("[Break-Even OK] Position #%I64u moved to BE at %f retcode=%u", ticket, newSL, retcode);
                     }
                     else
                        PrintFormat("[Break-Even WARN] Position #%I64u modify retcode=%u desc=%s", ticket, retcode, m_trade.ResultRetcodeDescription());
                  }
                  else
                     PrintFormat("[Break-Even FAILED] Position #%I64u PositionModify returned false. retcode=%u desc=%s", ticket, m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
               }
            }
         }
      }

      // 2. DETERMINISTIC TRAILING STOP
      if(InpUseTrailingStop)
      {
         double trailStartDist = initialRiskPts * InpTrailingStartRR * m_point;
         double trailStepDist  = initialRiskPts * InpTrailingDistanceRR * m_point;

         if(type == POSITION_TYPE_BUY)
         {
            if(currentPrice >= (openPrice + trailStartDist))
            {
               double newSL = currentPrice - trailStepDist;
               if(newSL > currentSL && (newSL - currentSL) >= (m_pipSize * 1.0))
               {
                  if(m_trade.PositionModify(ticket, newSL, currentTP))
                  {
                     uint retcode = m_trade.ResultRetcode();
                     if(retcode == TRADE_RETCODE_DONE)
                        PrintFormat("[Trailing OK] BUY Position #%I64u trailed to SL=%f retcode=%u", ticket, newSL, retcode);
                     else
                        PrintFormat("[Trailing WARN] BUY Position #%I64u retcode=%u desc=%s", ticket, retcode, m_trade.ResultRetcodeDescription());
                  }
               }
            }
         }
         else if(type == POSITION_TYPE_SELL)
         {
            if(currentPrice <= (openPrice - trailStartDist))
            {
               double newSL = currentPrice + trailStepDist;
               if((currentSL == 0.0 || newSL < currentSL) && (currentSL == 0.0 || (currentSL - newSL) >= (m_pipSize * 1.0)))
               {
                  if(m_trade.PositionModify(ticket, newSL, currentTP))
                  {
                     uint retcode = m_trade.ResultRetcode();
                     if(retcode == TRADE_RETCODE_DONE)
                        PrintFormat("[Trailing OK] SELL Position #%I64u trailed to SL=%f retcode=%u", ticket, newSL, retcode);
                     else
                        PrintFormat("[Trailing WARN] SELL Position #%I64u retcode=%u desc=%s", ticket, retcode, m_trade.ResultRetcodeDescription());
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| MANAGE OCO PENDING ORDERS (Survives Restarts via Tag Search)     |
//+------------------------------------------------------------------+
void ManageOCOPendingPairs()
{
   // 1. In-Memory Pairs Scan
   int total = ArraySize(m_ocoPairs);
   for(int i = total - 1; i >= 0; i--)
   {
      if(!m_ocoPairs[i].isActive) continue;

      bool buyFilled  = PositionSelectByTicket(m_ocoPairs[i].buyStopTicket);
      bool sellFilled = PositionSelectByTicket(m_ocoPairs[i].sellStopTicket);

      if(buyFilled)
      {
         if(OrderSelect(m_ocoPairs[i].sellStopTicket))
         {
            if(m_trade.OrderDelete(m_ocoPairs[i].sellStopTicket))
            {
               uint retcode = m_trade.ResultRetcode();
               PrintFormat("[OCO OK] Buy #%I64u filled. Deleted SellStop #%I64u retcode=%u", 
                           m_ocoPairs[i].buyStopTicket, m_ocoPairs[i].sellStopTicket, retcode);
            }
            else
               PrintFormat("[OCO FAILED] OrderDelete SellStop #%I64u retcode=%u desc=%s",
                  m_ocoPairs[i].sellStopTicket, m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
         }
         m_ocoPairs[i].isActive = false;
      }
      else if(sellFilled)
      {
         if(OrderSelect(m_ocoPairs[i].buyStopTicket))
         {
            if(m_trade.OrderDelete(m_ocoPairs[i].buyStopTicket))
            {
               uint retcode = m_trade.ResultRetcode();
               PrintFormat("[OCO OK] Sell #%I64u filled. Deleted BuyStop #%I64u retcode=%u",
                           m_ocoPairs[i].sellStopTicket, m_ocoPairs[i].buyStopTicket, retcode);
            }
            else
               PrintFormat("[OCO FAILED] OrderDelete BuyStop #%I64u retcode=%u desc=%s",
                  m_ocoPairs[i].buyStopTicket, m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
         }
         m_ocoPairs[i].isActive = false;
      }
   }

   // 2. Terminal State Recovery Scan (Across Restarts)
   for(int p = PositionsTotal() - 1; p >= 0; p--)
   {
      if(!m_position.SelectByIndex(p)) continue;
      if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;

      string posComment = m_position.Comment();
      int tagPos = StringFind(posComment, "IB_OCO_");
      if(tagPos < 0) continue;

      // Extract OCO tag
      string ocoTag = StringSubstr(posComment, tagPos, 20);

      // Check if an opposing pending order with this OCO tag is still open
      for(int o = OrdersTotal() - 1; o >= 0; o--)
      {
         if(!m_order.SelectByIndex(o)) continue;
         if(m_order.Symbol() == _Symbol && m_order.Magic() == InpMagicNumber)
         {
            if(StringFind(m_order.Comment(), ocoTag) >= 0)
            {
               ulong ocoOrderTicket = m_order.Ticket();
               if(m_trade.OrderDelete(ocoOrderTicket))
               {
                  uint retcode = m_trade.ResultRetcode();
                  PrintFormat("[OCO Recovery OK] Tag %s. Deleted pending #%I64u retcode=%u", ocoTag, ocoOrderTicket, retcode);
               }
               else
                  PrintFormat("[OCO Recovery FAILED] Tag %s. OrderDelete #%I64u retcode=%u desc=%s",
                     ocoTag, ocoOrderTicket, m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| TRACKED POSITIONS DATA STRUCTURE UTILITIES                       |
//+------------------------------------------------------------------+
void RegisterPositionTrack(ulong ticket, double openPrice, double slPrice, double tpPrice, ENUM_POSITION_TYPE type, string setup)
{
   // Prevent duplicate tracker entries
   if(FindTrackedPositionIndex(ticket) >= 0) return;

   int sz = ArraySize(m_trackedPositions);
   ArrayResize(m_trackedPositions, sz + 1);

   m_trackedPositions[sz].ticket            = ticket;
   m_trackedPositions[sz].openTime          = TimeCurrent();
   m_trackedPositions[sz].openPrice         = openPrice;
   m_trackedPositions[sz].initialSL         = slPrice;
   m_trackedPositions[sz].initialTP         = tpPrice;
   m_trackedPositions[sz].initialRiskPoints = MathAbs(openPrice - slPrice) / m_point;
   m_trackedPositions[sz].type              = type;
   m_trackedPositions[sz].setupName         = setup;
   m_trackedPositions[sz].breakEvenApplied  = false;

   // Persist to Terminal Global Variable
   string gvName = StringFormat("PA_INIT_SL_%I64u", ticket);
   GlobalVariableSet(gvName, slPrice);
}

int FindTrackedPositionIndex(ulong ticket)
{
   int total = ArraySize(m_trackedPositions);
   for(int i = 0; i < total; i++)
   {
      if(m_trackedPositions[i].ticket == ticket) return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| SIGNAL IDEMPOTENCY TRACKING                                      |
//+------------------------------------------------------------------+
bool IsSignalProcessed(datetime barTime, string key)
{
   int total = ArraySize(m_processedSignals);
   for(int i = 0; i < total; i++)
   {
      if(m_processedSignals[i].candleTime == barTime && m_processedSignals[i].signalKey == key)
         return true;
   }
   return false;
}

void RecordSignalProcessed(datetime barTime, string key)
{
   int sz = ArraySize(m_processedSignals);
   ArrayResize(m_processedSignals, sz + 1);
   m_processedSignals[sz].candleTime = barTime;
   m_processedSignals[sz].signalKey  = key;
}

//+------------------------------------------------------------------+
//| CLEAN EXPIRED PENDING ORDERS                                     |
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
               ulong expTicket = m_order.Ticket();
               if(m_trade.OrderDelete(expTicket))
                  PrintFormat("[CleanExpired OK] Deleted expired order #%I64u retcode=%u", expTicket, m_trade.ResultRetcode());
               else
                  PrintFormat("[CleanExpired FAILED] Order #%I64u retcode=%u desc=%s", expTicket, m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| CHECK OPEN POSITIONS FOR THIS SYMBOL AND MAGIC                   |
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
//| ENHANCED MODE: VSA CONDITION VALIDATION                          |
//+------------------------------------------------------------------+
bool ValidateVsaCondition(int shift, bool forBuy)
{
   if(InpVsaFilter == VSA_OFF) return true;

   long volumes[];
   ArraySetAsSeries(volumes, true);
   int needed = InpVsaMaPeriod + shift + 10;
   if(CopyTickVolume(_Symbol, _Period, 0, needed, volumes) < needed) return true;

   long sum = 0;
   for(int k = 1; k <= InpVsaMaPeriod; k++)
      sum += volumes[shift + k];

   double avgVolume = (double)sum / InpVsaMaPeriod;
   double currentVol = (double)volumes[shift];

   bool isClimax = (currentVol >= (avgVolume * InpVsaHighMultiplier));
   bool isLowVol = (currentVol <= (avgVolume * InpVsaLowMultiplier));

   if(InpVsaFilter == VSA_CLIMAX_STOPPING) return isClimax;
   if(InpVsaFilter == VSA_TEST_AND_CLIMAX)  return (isClimax || isLowVol);

   return true;
}

//+------------------------------------------------------------------+
//| ENHANCED MODE: HTF POI SCANNER & INTERACTION                     |
//+------------------------------------------------------------------+
void ScanHtfPois()
{
   MqlRates htfRates[];
   ArraySetAsSeries(htfRates, true);
   // STRICT COMPLIANCE: Offset to closed HTF candles (start from shift 1)
   int copied = CopyRates(_Symbol, InpHtfPoiTf, 1, 60, htfRates);
   if(copied < 20) return;

   double atrBuf[1];
   if(CopyBuffer(m_hHtfAtr, 0, 1, 1, atrBuf) < 1) return;
   double htfAtr = atrBuf[0];

   ArrayResize(m_htfPois, 0);

   for(int i = 2; i < copied - 2; i++)
   {
      // Bullish Order Block (Demand POI)
      bool isBearish = (htfRates[i].close < htfRates[i].open);
      double moveUp  = htfRates[i - 1].close - htfRates[i].open;
      bool hasFVG    = (htfRates[i - 2].low > htfRates[i].high);

      if(isBearish && moveUp >= (htfAtr * InpPoiMinImbalanceAtr) && hasFVG)
      {
         int sz = ArraySize(m_htfPois);
         ArrayResize(m_htfPois, sz + 1);
         m_htfPois[sz].top         = htfRates[i].high;
         m_htfPois[sz].bottom      = htfRates[i].low;
         m_htfPois[sz].time        = htfRates[i].time;
         m_htfPois[sz].isBullish   = true;
         m_htfPois[sz].isMitigated = false;
         m_htfPois[sz].objName     = "POI_Demand_" + TimeToString(htfRates[i].time);
      }

      // Bearish Order Block (Supply POI)
      bool isBullish = (htfRates[i].close > htfRates[i].open);
      double moveDn  = htfRates[i].open - htfRates[i - 1].close;
      bool hasBearFVG= (htfRates[i - 2].high < htfRates[i].low);

      if(isBullish && moveDn >= (htfAtr * InpPoiMinImbalanceAtr) && hasBearFVG)
      {
         int sz = ArraySize(m_htfPois);
         ArrayResize(m_htfPois, sz + 1);
         m_htfPois[sz].top         = htfRates[i].high;
         m_htfPois[sz].bottom      = htfRates[i].low;
         m_htfPois[sz].time        = htfRates[i].time;
         m_htfPois[sz].isBullish   = false;
         m_htfPois[sz].isMitigated = false;
         m_htfPois[sz].objName     = "POI_Supply_" + TimeToString(htfRates[i].time);
      }
   }
}

bool IsCandleInteractingWithHtfPoi(const MqlRates &candle, bool forBuy)
{
   int total = ArraySize(m_htfPois);
   for(int i = 0; i < total; i++)
   {
      if(m_htfPois[i].isMitigated) continue;

      if(forBuy && m_htfPois[i].isBullish)
      {
         if(InpPoiInteractMode == POI_INTERACT_WICK)
            if(candle.low <= m_htfPois[i].top && candle.high >= m_htfPois[i].bottom) return true;
         if(InpPoiInteractMode == POI_INTERACT_BODY)
            if(MathMin(candle.open, candle.close) <= m_htfPois[i].top && MathMax(candle.open, candle.close) >= m_htfPois[i].bottom) return true;
         if(InpPoiInteractMode == POI_INTERACT_CLOSE)
            if(candle.close <= m_htfPois[i].top && candle.close >= m_htfPois[i].bottom) return true;
      }
      else if(!forBuy && !m_htfPois[i].isBullish)
      {
         if(InpPoiInteractMode == POI_INTERACT_WICK)
            if(candle.high >= m_htfPois[i].bottom && candle.low <= m_htfPois[i].top) return true;
         if(InpPoiInteractMode == POI_INTERACT_BODY)
            if(MathMax(candle.open, candle.close) >= m_htfPois[i].bottom && MathMin(candle.open, candle.close) <= m_htfPois[i].top) return true;
         if(InpPoiInteractMode == POI_INTERACT_CLOSE)
            if(candle.close >= m_htfPois[i].bottom && candle.close <= m_htfPois[i].top) return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| DRAW VISUAL MARKERS ON CHART                                     |
//+------------------------------------------------------------------+
void DrawSignalMarker(datetime time, double price, string label, color clr, bool isBuy)
{
   if(!InpDrawChartObjects) return;

   string arrowName = "PA_Arrow_" + TimeToString(time);
   string textName  = "PA_Text_" + TimeToString(time);

   if(isBuy)
   {
      ObjectCreate(0, arrowName, OBJ_ARROW_BUY, 0, time, price - (10.0 * m_pipSize));
      ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 2);

      ObjectCreate(0, textName, OBJ_TEXT, 0, time, price - (25.0 * m_pipSize));
      ObjectSetString(0, textName, OBJPROP_TEXT, label);
      ObjectSetInteger(0, textName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 9);
   }
   else
   {
      ObjectCreate(0, arrowName, OBJ_ARROW_SELL, 0, time, price + (10.0 * m_pipSize));
      ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 2);

      ObjectCreate(0, textName, OBJ_TEXT, 0, time, price + (25.0 * m_pipSize));
      ObjectSetString(0, textName, OBJPROP_TEXT, label);
      ObjectSetInteger(0, textName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 9);
   }
}
//+------------------------------------------------------------------+
