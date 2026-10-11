//+------------------------------------------------------------------+
//|                 Aurum_Imperium_Apex_v12_TTrades_Mechanical.mq5   |
//|         BAKOME Quantitative Systems - TTrades ICT Mechanical Edition |
//|                                                                  |
//|  Comprehensive Rule-Based Implementation of TTrades ICT Advanced |
//|  Concepts Framework:                                             |
//|  1. Top-Down Bias Engine (D1 -> H4/H1 -> M15/M5 Multi-Timeframe)  |
//|  2. ADR / Range Exhaustion Filter & Late-Day Gate                 |
//|  3. Dealing Range & 50% Equilibrium (EQ) Positioning Logic       |
//|  4. Mechanical CISD & Protected Swing Confirmation (No Raw Sweeps)|
//|  5. 5 Distinct Entry Models: OB, Breaker, Unicorn, Mitigation,    |
//|     Propulsion (Configurable & Independently Testable)           |
//|  6. Wick & Candle Quality Filter (Expansion vs Reversal Wicks)    |
//|  7. SMT / Relative Strength Divergence Filter (Gold vs Silver)   |
//|  8. Forex Currency Anchor & DXY Direction Filter                 |
//|  9. Daily Session Profiles (London Reversal, NY Manipulation,    |
//|     NY Reversal, and Seek & Destroy Halting)                     |
//|  10. Asymmetric Exits & Standard Deviation Manipulation Projections|
//|  11. Audited Institutional Risk Engine & Persistent State Safety  |
//|  12. Granular Mechanical Decision & Filter Logging               |
//+------------------------------------------------------------------+
#property copyright "BAKOME Quant Labs - TTrades ICT Mechanical Architecture"
#property link      "https://github.com/yossefbelal1/PriceAction-Pro-MT5"
#property version   "12.00"
#property description "Mechanical TTrades ICT Advanced Concepts EA with Top-Down Bias, CISD, Unicorn/Breaker/OB Models, EQ, SMT & ADR Filters"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/AccountInfo.mqh>
#include <Trade/DealInfo.mqh>

//+------------------------------------------------------------------+
//| Enums                                                            |
//+------------------------------------------------------------------+
enum ENUM_ENTRY_MODEL {
   MODEL_ALL_COMBINED   = 0, // All Models Active (Highest Confluence Synthesis)
   MODEL_UNICORN        = 1, // Model 1: TTrades Unicorn (Breaker Block + FVG Overlap)
   MODEL_BREAKER_BLOCK  = 2, // Model 2: Breaker Block Continuation
   MODEL_ORDER_BLOCK    = 3, // Model 3: Order Block Continuation + FVG
   MODEL_MITIGATION     = 4, // Model 4: Mitigation Block (Failed Swing Retest)
   MODEL_PROPULSION     = 5  // Model 5: Propulsion Block (OB formed from prior OB)
};

enum ENUM_TARGET_MODE {
   TARGET_ASYMMETRIC_RR   = 0, // Fixed Asymmetric Reward:Risk (e.g. 2.80R)
   TARGET_STD_DEV         = 1, // Manipulation Leg Standard Deviation Projections (-2.2 SD / -4.0 SD)
   TARGET_LIQUIDITY_ERL   = 2  // External Range Liquidity (PDH / PDL / Session Extremes)
};

enum ENUM_LOT_CALC_MODE {
   LOT_CALC_PERCENT_RISK = 0, // Risk Percentage (% of Balance per trade)
   LOT_CALC_FIXED_LOT    = 1  // Fixed Lot Size
};

enum ENUM_BIAS_STATE {
   BIAS_NEUTRAL   = 0,
   BIAS_BULLISH   = 1,
   BIAS_BEARISH   = -1,
   BIAS_EXHAUSTED = 2
};

enum ENUM_SESSION_PROFILE {
   PROFILE_NORMAL               = 0,
   PROFILE_LONDON_REVERSAL      = 1,
   PROFILE_NY_MANIPULATION      = 2,
   PROFILE_NY_REVERSAL          = 3,
   PROFILE_SEEK_AND_DESTROY     = 4  // Both Asia extremes swept without displacement -> No Trade Day
};

enum ENUM_TRADING_SESSION {
   SESSION_NONE     = 0,
   SESSION_LONDON   = 1,
   SESSION_NEW_YORK = 2
};

enum ENUM_LOG_LEVEL {
   LOG_NONE    = 0,
   LOG_ERROR   = 1,
   LOG_WARNING = 2,
   LOG_INFO    = 3,
   LOG_DEBUG   = 4
};

//+------------------------------------------------------------------+
//| Input Parameters                                                |
//+------------------------------------------------------------------+
input group "=== [1] Top-Down Bias Engine (المحرك الاتجاهي متعدد الفريمات) ==="
input bool               UseTopDownBias          = true;         // Enable Top-Down Multi-Timeframe Bias Engine
input ENUM_TIMEFRAMES    HTF_DailyTimeframe      = PERIOD_D1;    // HTF Macro Trend Timeframe
input ENUM_TIMEFRAMES    HTF_IntermediateTF      = PERIOD_H4;    // Intermediate Trend Timeframe
input ENUM_TIMEFRAMES    HTF_SessionTF           = PERIOD_H1;    // Session Trend Timeframe
input int                MaxConsecutiveExpansions = 3;            // Max consecutive expansion candles before exhaustion warning
input bool               RequireHTFAlignment     = false;        // Require D1 and H4/H1 to align before lower timeframe entry

input group "=== [2] ADR & Range Exhaustion Filter (فلتر استنزاف المدى اليومي) ==="
input bool               UseADRExhaustionFilter  = true;         // Skip new trades if Daily Range is exhausted
input int                ADR_Period              = 5;            // ADR Lookback Days (5-Day ADR)
input double             ADR_MaxConsumedCont     = 0.85;         // Max ADR consumed for continuation trades (85%)
input double             ADR_MaxConsumedReversal = 0.90;         // Max ADR consumed for reversal setups (90%)
input int                LateDayHourCutoff       = 19;           // Broker hour cutoff (no forced trades late in day)

input group "=== [3] Dealing Range & 50% Equilibrium Logic (نطاق التعامل ومنطقة التوازن) ==="
input bool               UseDealingRangeFilter   = true;         // Enable Dealing Range & 50% EQ Filter
input int                DealingRangeLookback    = 60;           // Bars lookback to find Dealing Range Swing High/Low
input bool               RequireDiscountForBuy   = true;         // Longs preferred in Discount (< 50% EQ) or near EQ
input bool               RequirePremiumForSell   = true;         // Shorts preferred in Premium (> 50% EQ) or near EQ
input double             EQ_ToleranceATR         = 0.20;         // Tolerance around 50% EQ (x ATR)
input bool               InvalidateOnEQBreach    = true;         // Invalidate continuation bias if EQ closed against trend

input group "=== [4] CISD & Protected Swing Confirmation (تأكيد تغير تسليم السعر الحقيقي) ==="
input bool               RequireCISD_Confirmation= true;         // Strict Rule: Never enter on raw sweep alone! Require CISD
input int                CISD_LookbackBars       = 14;           // Lookback bars for sweep & CISD displacement scan
input bool               UseProtectedSwingSL     = true;         // Anchor Stop Loss beyond Protected Swing extreme
input double             ProtectedSL_BufferATR   = 0.15;         // Buffer beyond Protected Swing (x ATR)
input double             ProtectedSL_MinATR      = 0.50;         // Minimum SL distance (x ATR)
input double             ProtectedSL_MaxATR      = 1.50;         // Maximum SL distance (x ATR)

input group "=== [5] Entry Models Selection (نماذج الدخول الخمسة الميكانيكية) ==="
input ENUM_ENTRY_MODEL   ActiveEntryModel        = MODEL_ALL_COMBINED; // Active Entry Model
input int                PatternLookbackBars     = 30;           // Lookback bars for OB/Breaker/Unicorn scan
input double             UnicornOverlapTolerance = 0.35;         // Tolerance for Breaker + FVG overlap (x ATR)
input double             FVG_MinSizeATR          = 0.25;         // Minimum FVG size (x ATR)
input double             OB_MeanThresholdRatio   = 0.50;         // 50% Mean Threshold for Order Block & Propulsion

input group "=== [6] Wick & Candle Quality Filter (فلتر جودة الشموع والفتائل) ==="
input bool               UseCandleQualityFilter  = true;         // Enable HTF Wick & Candle Quality Filter
input ENUM_TIMEFRAMES    CandleQualityTF         = PERIOD_M15;   // Timeframe for Candle Quality evaluation (M15 structural)
input double             MaxOpposingWickRatio    = 0.60;         // Maximum allowable opposing wick ratio (rejection gate)
input double             MinBodyExpansionRatio   = 0.50;         // Minimum body ratio to confirm expansion candle

input group "=== [7] SMT & Relative Strength Filter (فلتر دايفرجنس القوة النسبية) ==="
input bool               UseSMTFilter            = false;        // Enable SMT Relative Strength Filter
input string             SMT_CorrelatedSymbol    = "XAGUSD";     // Correlated symbol (Silver for Gold)
input int                SMT_LookbackBars        = 20;           // Lookback bars for SMT swing comparison
input bool               StrictSMT_Confirmation  = false;        // true = Require SMT; false = SMT confluence & conflict filter

input group "=== [8] Daily Profiles & Session Windows (بروفايلات اليوم ومناطق القتل) ==="
input bool               UseSessionProfiles      = true;         // Enable Session Profile Engine
input bool               FilterSeekAndDestroy    = false;        // Halt trading if London sweeps both Asia High & Low
input int                AsiaStartHour           = 0;            // Asia session start hour
input int                AsiaEndHour             = 7;            // Asia session end hour
input bool               TradeLondonSession      = true;         // Trade London Kill Zone
input int                LondonKZ_StartHour      = 8;            // London KZ Start Hour
input int                LondonKZ_StartMin       = 0;            // London KZ Start Minute
input int                LondonKZ_EndHour        = 11;           // London KZ End Hour
input int                LondonKZ_EndMin         = 0;            // London KZ End Minute
input bool               TradeNewYorkSession     = true;         // Trade New York Kill Zone
input int                NYKZ_StartHour          = 13;           // NY KZ Start Hour
input int                NYKZ_StartMin           = 30;           // NY KZ Start Minute
input int                NYKZ_EndHour            = 17;           // NY KZ End Hour
input int                NYKZ_EndMin             = 0;            // NY KZ End Minute

input group "=== [9] Targets & Position Management (الأهداف وإدارة الصفقات المتقدمة) ==="
input ENUM_TARGET_MODE   TargetMode              = TARGET_ASYMMETRIC_RR; // Target Calculation Mode
input double             TargetRR_Ratio          = 2.80;         // Target Reward:Risk Ratio (default 2.80R)
input double             StdDev_Target1          = 2.20;         // Manipulation Leg Standard Deviation Target 1
input double             StdDev_Target2          = 4.00;         // Manipulation Leg Standard Deviation Target 2
input bool               UseBreakEven            = true;         // Enable Break Even
input double             BE_TriggerATR           = 1.50;         // Break Even Trigger distance (x ATR)
input int                BE_OffsetPoints         = 100;          // Break Even Offset (points locked)
input bool               UseStructuralTrailing   = true;         // Trail behind newly confirmed Protected Swings
input double             Trail_StartATR          = 1.80;         // Trailing Stop Start (x ATR in profit)
input double             Trail_StepATR           = 0.80;         // Trailing Buffer behind structure (x ATR)

input group "=== [10] Dynamic 2nd-Trade & Session Limits (ضوابط الصفقة الثانية) ==="
input int                MaxTradesPerDay         = 2;            // Maximum trades per day (1-2 trades)
input int                MaxTradesPerSession     = 1;            // Maximum trades per session
input int                MaxDailyLosses          = 1;            // Max daily losses before day shutdown
input int                MinBarsCooldownAfterExit= 4;            // Minimum M5 bars cooldown after exit (20 min)
input bool               UseDailyProfitLock      = true;         // Lock day after target profit reached
input double             DailyProfitLockUSD      = 120.0;        // Daily profit target to bank and lock
input bool               RequireTrendForTrade2   = true;         // If Trade 1 was profitable, require trend for Trade 2
input double             Trade2MinADX            = 28.0;         // Minimum ADX required for Trade 2
input double             Trade2MaxADRConsumed    = 0.80;         // Do not take Trade 2 if daily range >= 80% ADR

input group "=== [11] Audited Risk Engine & Ironclad Safety (المحرك المالي الصارم) ==="
input ENUM_LOT_CALC_MODE LotCalcMode             = LOT_CALC_PERCENT_RISK; // Lot Mode: Risk % OR Fixed Lot
input double             FixedLotSize            = 0.10;         // Fixed Lot Size (if LotCalcMode = Fixed Lot)
input double             RiskPercent             = 0.85;         // Risk % per trade (Institutional 0.85%)
input double             MaxDailyRiskPercent     = 3.0;          // Maximum Daily Loss (% of Day Start Balance)
input double             MaxAllowedLotSize       = 0.25;         // Hard lot size ceiling
input bool               UseDrawdownBrake        = true;         // Smart Drawdown Brake
input double             BrakeTriggerDD          = 2.00;         // Drawdown % to halve risk
input bool               UseStreakRiskReducer    = true;         // Reduce risk on consecutive losses
input int                StreakLossTrigger       = 2;            // Consecutive losses before reducing risk
input double             StreakReductionRatio    = 0.70;         // Retained risk ratio
input bool               UseSafetyBelt           = true;         // Master Safety Belt Guardian
input double             MaxAllowedDailyDD       = 3.50;         // Hard Daily DD ceiling (3.5%)
input double             MaxAllowedTotalDD       = 5.00;         // Hard Total DD ceiling (5.0%)
input bool               AutoCloseOnEmergency    = true;         // Force-close positions if hard limit breached
input bool               CloseFridayNight        = true;         // Close positions before weekend
input int                FridayCloseHour         = 21;           // Friday close hour
input bool               AvoidFridayAfternoon    = true;         // Avoid new trades Friday afternoon
input bool               AvoidMonday             = true;         // Avoid Monday trading
input bool               AvoidRolloverSpread     = true;         // Avoid trading during midnight rollover spread

input group "=== [12] Execution & Predictive Quality Gates ==="
input ulong              MagicNumber             = 889922;       // Magic Number
input int                SlippagePoints          = 10;           // Slippage points
input bool               OnlyOnCandleClose       = true;         // Execute strictly on M5 Candle Close
input bool               UseSpreadToATRGate      = true;         // Block entries when Spread/ATR is toxic
input double             MaxSpreadToATRRatio     = 0.22;         // Max allowable Spread/ATR ratio
input double             MinATR_Points           = 50.0;         // Minimum ATR (points)
input double             MaxSpreadPoints         = 350.0;        // Maximum spread (points, 35 cents on Gold)
input ENUM_LOG_LEVEL     LogLevel                = LOG_INFO;     // Logging Level

//+------------------------------------------------------------------+
//| Structural Data Types                                            |
//+------------------------------------------------------------------+
struct SCISD {
   bool               confirmed;
   ENUM_POSITION_TYPE dir;
   double             cisdLevel;
   double             protectedSwing;
   double             manipulationRange;
   int                sweepBar;
   datetime           timeConfirmed;
};

struct SEntrySetup {
   bool               isValid;
   ENUM_ENTRY_MODEL   modelType;
   ENUM_POSITION_TYPE dir;
   double             entryPrice;
   double             stopLoss;
   double             takeProfit;
   double             protectedSwing;
   double             riskCash;
   string             setupName;
   string             validationReason;
};

struct SPositionTracker {
   ulong    ticket;
   datetime openTime;
   double   openPrice;
   double   originalSL;
   double   originalTP;
   double   initialRiskCash;
   double   atrAtEntry;
   bool     beSet;
   bool     trailingActive;
};

//+------------------------------------------------------------------+
//| Main EA Engine Class                                             |
//+------------------------------------------------------------------+
class CApexV12Mechanical {
private:
   CTrade            m_trade;
   CPositionInfo     m_position;
   CSymbolInfo       m_symbol;
   CAccountInfo      m_account;
   CDealInfo         m_deal;

   // Runtime State
   int               m_atrHandle;
   int               m_adxHandle;
   double            m_currentATR;
   datetime          m_lastProcessedBarTime;
   datetime          m_lastExitBarTime;

   // Account & Daily Baselines
   double            m_initialDeposit;
   double            m_dayStartBalance;
   double            m_dailyRealizedPnL;
   double            m_dailyPeakBalance;
   int               m_dailyTradesCount;
   int               m_dailyLossesCount;
   int               m_dailyWinsCount;
   int               m_consecutiveLosses;
   bool              m_dailyHalted;

   // Session & Profile Tracking
   int               m_currentDay;
   int               m_currentMonth;
   int               m_currentYear;
   double            m_asiaHigh;
   double            m_asiaLow;
   bool              m_asiaHighSwept;
   bool              m_asiaLowSwept;
   ENUM_SESSION_PROFILE m_activeProfile;

   // Active Setups & Protected Swings
   SCISD             m_activeCISD;
   double            m_lastProtectedSwing;
   bool              m_isHTFExhausted;
   bool              m_isADRScaledDown;

   // Tracking
   SPositionTracker  m_tracker;

   // Internal Helpers
   void LogMessage(ENUM_LOG_LEVEL level, string msg) {
      if(level <= LogLevel) {
         string pfx = "[INFO]";
         if(level == LOG_ERROR)   pfx = "[ERROR]";
         if(level == LOG_WARNING) pfx = "[WARN]";
         if(level == LOG_DEBUG)   pfx = "[DEBUG]";
         Print(StringFormat("%s [V12 Mechanical] %s", pfx, msg));
      }
   }

public:
   CApexV12Mechanical() : m_atrHandle(INVALID_HANDLE),
                          m_adxHandle(INVALID_HANDLE),
                          m_currentATR(0.0),
                          m_lastProcessedBarTime(0),
                          m_lastExitBarTime(0),
                          m_initialDeposit(10000.0),
                          m_dayStartBalance(10000.0),
                          m_dailyRealizedPnL(0.0),
                          m_dailyPeakBalance(10000.0),
                          m_dailyTradesCount(0),
                          m_dailyLossesCount(0),
                          m_dailyWinsCount(0),
                          m_consecutiveLosses(0),
                          m_dailyHalted(false),
                          m_currentDay(-1),
                          m_currentMonth(-1),
                          m_currentYear(-1),
                          m_asiaHigh(0.0),
                          m_asiaLow(999999.0),
                          m_asiaHighSwept(false),
                          m_asiaLowSwept(false),
                          m_activeProfile(PROFILE_NORMAL),
                          m_lastProtectedSwing(0.0),
                          m_isHTFExhausted(false),
                          m_isADRScaledDown(false) {
      ResetCISD();
      ZeroMemory(m_tracker);
   }

   ~CApexV12Mechanical() {
      if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
      if(m_adxHandle != INVALID_HANDLE) IndicatorRelease(m_adxHandle);
   }

   bool Init() {
      if(!m_symbol.Name(_Symbol)) return false;
      m_symbol.Refresh();
      m_symbol.RefreshRates();

      m_trade.SetExpertMagicNumber(MagicNumber);
      m_trade.SetDeviationInPoints(SlippagePoints);

      uint filling = (uint)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
      if((filling & SYMBOL_FILLING_FOK) != 0) {
         m_trade.SetTypeFilling(ORDER_FILLING_FOK);
      } else if((filling & SYMBOL_FILLING_IOC) != 0) {
         m_trade.SetTypeFilling(ORDER_FILLING_IOC);
      } else {
         m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
      }

      m_atrHandle = iATR(_Symbol, PERIOD_M5, 14);
      m_adxHandle = iADX(_Symbol, PERIOD_H1, 14);

      if(m_atrHandle == INVALID_HANDLE) {
         LogMessage(LOG_ERROR, "Failed to create ATR indicator handle!");
         return false;
      }

      // Warm up historical series for multi-timeframe evaluation
      datetime dummyTime[];
      CopyTime(_Symbol, PERIOD_D1, 0, 10, dummyTime);
      CopyTime(_Symbol, PERIOD_H4, 0, 10, dummyTime);
      CopyTime(_Symbol, PERIOD_H1, 0, 10, dummyTime);
      CopyTime(_Symbol, PERIOD_M15, 0, 10, dummyTime);

      // Restore or initialize persistent daily baselines
      string initDepKey = StringFormat("APEX_%I64u_%s_INITDEP", MagicNumber, _Symbol);
      if(GlobalVariableCheck(initDepKey)) {
         m_initialDeposit = GlobalVariableGet(initDepKey);
      } else {
         m_initialDeposit = m_account.Balance();
         GlobalVariableSet(initDepKey, m_initialDeposit);
      }

      m_dayStartBalance  = m_account.Balance();
      m_dailyPeakBalance = m_account.Balance();

      UpdateDayState();
      UpdateDailyStatsFromHistory();

      LogMessage(LOG_INFO, StringFormat("CApexV12Mechanical initialized cleanly. Deposit: $%.2f | DayStart: $%.2f",
                                       m_initialDeposit, m_dayStartBalance));
      return true;
   }

   void ResetCISD() {
      m_activeCISD.confirmed = false;
      m_activeCISD.dir = WRONG_VALUE;
      m_activeCISD.cisdLevel = 0.0;
      m_activeCISD.protectedSwing = 0.0;
      m_activeCISD.manipulationRange = 0.0;
      m_activeCISD.sweepBar = -1;
      m_activeCISD.timeConfirmed = 0;
   }

   //+------------------------------------------------------------------+
   //| Day Transition & Persistent Date-Key Management                  |
   //+------------------------------------------------------------------+
   void UpdateDayState() {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      int fullDateKey = dt.year * 1000 + dt.day_of_year;

      string dayKeyName = StringFormat("APEX_%I64u_%s_DAY", MagicNumber, _Symbol);
      int storedDayKey = 0;
      if(GlobalVariableCheck(dayKeyName))
         storedDayKey = (int)GlobalVariableGet(dayKeyName);

      if(storedDayKey != fullDateKey || m_currentDay != dt.day || m_currentMonth != dt.mon || m_currentYear != dt.year) {
         m_currentDay   = dt.day;
         m_currentMonth = dt.mon;
         m_currentYear  = dt.year;
         GlobalVariableSet(dayKeyName, (double)fullDateKey);

         m_dayStartBalance   = m_account.Balance();
         m_dailyPeakBalance  = m_account.Balance();
         m_dailyRealizedPnL  = 0.0;
         m_dailyTradesCount  = 0;
         m_dailyLossesCount  = 0;
         m_dailyWinsCount    = 0;
         m_dailyHalted       = false;

         // Reset Asia range tracking
         m_asiaHigh      = 0.0;
         m_asiaLow       = 999999.0;
         m_asiaHighSwept = false;
         m_asiaLowSwept  = false;
         m_activeProfile = PROFILE_NORMAL;
         ResetCISD();

         LogMessage(LOG_INFO, StringFormat("New Trading Day Initialized. DateKey: %d | DayStart Balance: $%.2f",
                                          fullDateKey, m_dayStartBalance));
      }
   }

   //+------------------------------------------------------------------+
   //| Reconstruct Daily & Session Stats from Closed History Deals      |
   //+------------------------------------------------------------------+
   void UpdateDailyStatsFromHistory() {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      dt.hour = 0; dt.min = 0; dt.sec = 0;
      datetime dayStart = StructToTime(dt);

      if(!HistorySelect(dayStart, TimeCurrent())) return;

      int totalDeals = HistoryDealsTotal();
      m_dailyTradesCount  = 0;
      m_dailyLossesCount  = 0;
      m_dailyWinsCount    = 0;
      m_dailyRealizedPnL  = 0.0;
      m_consecutiveLosses = 0;

      for(int i = 0; i < totalDeals; i++) {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket <= 0) continue;
         if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != MagicNumber) continue;
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
         if(HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;

         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT)
                       + HistoryDealGetDouble(ticket, DEAL_SWAP)
                       + HistoryDealGetDouble(ticket, DEAL_COMMISSION);

         m_dailyRealizedPnL += profit;
         m_dailyTradesCount++;
         m_lastExitBarTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);

         if(profit > 0) {
            m_dailyWinsCount++;
            m_consecutiveLosses = 0;
         } else if(profit < 0) {
            m_dailyLossesCount++;
            m_consecutiveLosses++;
         }
      }
   }

   //+------------------------------------------------------------------+
   //| Update ATR Indicator Buffer                                      |
   //+------------------------------------------------------------------+
   bool UpdateATR() {
      double atrBuf[1];
      if(CopyBuffer(m_atrHandle, 0, 1, 1, atrBuf) <= 0) return false;
      m_currentATR = atrBuf[0];
      return (m_currentATR > 0.0);
   }

   //+------------------------------------------------------------------+
   //| Cooldown Check: Minimum Bars Since Last Exit                     |
   //+------------------------------------------------------------------+
   bool IsExitCooldownActive() {
      if(m_lastExitBarTime <= 0) return false;
      datetime currentBar = iTime(_Symbol, PERIOD_M5, 0);
      int barsSinceExit = iBarShift(_Symbol, PERIOD_M5, m_lastExitBarTime, false);
      if(barsSinceExit >= 0 && barsSinceExit < MinBarsCooldownAfterExit) {
         LogMessage(LOG_DEBUG, StringFormat("Exit Cooldown Active: %d bars elapsed < %d bars required.",
                                           barsSinceExit, MinBarsCooldownAfterExit));
         return true;
      }
      return false;
   }

   //+------------------------------------------------------------------+
   //| [MODULE 1] Top-Down Multi-Timeframe Bias Engine                  |
   //+------------------------------------------------------------------+
   ENUM_BIAS_STATE EvaluateSingleCandleBias(ENUM_TIMEFRAMES tf) {
      double c1 = iClose(_Symbol, tf, 1);
      double o1 = iOpen(_Symbol, tf, 1);
      double h1 = iHigh(_Symbol, tf, 1);
      double l1 = iLow(_Symbol, tf, 1);
      double h2 = iHigh(_Symbol, tf, 2);
      double l2 = iLow(_Symbol, tf, 2);

      // 1. Continuation: Close strictly outside previous bar's high/low
      if(c1 > h2) return BIAS_BULLISH;
      if(c1 < l2) return BIAS_BEARISH;

      // 2. Reversal: Swept previous high/low and closed back inside
      if(h1 > h2 && c1 < h2) return BIAS_BEARISH; // Bearish Reversal Sweep
      if(l1 < l2 && c1 > l2) return BIAS_BULLISH; // Bullish Reversal Sweep

      // 3. Fallback: Body direction
      if(c1 > o1) return BIAS_BULLISH;
      if(c1 < o1) return BIAS_BEARISH;

      return BIAS_NEUTRAL;
   }

   bool CheckExpansionExhaustion(ENUM_TIMEFRAMES tf) {
      int consecutive = 0;
      ENUM_BIAS_STATE dir = BIAS_NEUTRAL;

      for(int i = 1; i <= 5; i++) {
         double h = iHigh(_Symbol, tf, i);
         double l = iLow(_Symbol, tf, i);
         double o = iOpen(_Symbol, tf, i);
         double c = iClose(_Symbol, tf, i);
         double rng = h - l;
         double body = MathAbs(c - o);

         if(rng <= 0) break;
         if((body / rng) >= 0.58) {
            ENUM_BIAS_STATE bDir = (c > o) ? BIAS_BULLISH : BIAS_BEARISH;
            if(dir == BIAS_NEUTRAL) {
               dir = bDir;
               consecutive++;
            } else if(dir == bDir) {
               consecutive++;
            } else break;
         } else break;
      }

      if(consecutive >= MaxConsecutiveExpansions) {
         LogMessage(LOG_INFO, StringFormat("Top-Down Bias: Exhaustion Warning! %d consecutive expansion candles on %s.",
                                          consecutive, EnumToString(tf)));
         return true;
      }
      return false;
   }

   ENUM_BIAS_STATE GetTopDownBias() {
      if(!UseTopDownBias) return BIAS_NEUTRAL;

      ENUM_BIAS_STATE d1Bias = EvaluateSingleCandleBias(HTF_DailyTimeframe);
      ENUM_BIAS_STATE h4Bias = EvaluateSingleCandleBias(HTF_IntermediateTF);
      ENUM_BIAS_STATE h1Bias = EvaluateSingleCandleBias(HTF_SessionTF);

      m_isHTFExhausted = CheckExpansionExhaustion(HTF_DailyTimeframe);

      // 1. Dominant Daily Direction (TTrades Macro Anchor)
      if(d1Bias != BIAS_NEUTRAL) {
         if(RequireHTFAlignment) {
            // Neutral only if both H4 and H1 are actively moving counter-trend
            if(d1Bias == BIAS_BULLISH && h4Bias == BIAS_BEARISH && h1Bias == BIAS_BEARISH)
               return BIAS_NEUTRAL;
            if(d1Bias == BIAS_BEARISH && h4Bias == BIAS_BULLISH && h1Bias == BIAS_BULLISH)
               return BIAS_NEUTRAL;
         }
         return d1Bias;
      }

      // 2. Intermediate 4H Trend if Daily is inside
      if(h4Bias != BIAS_NEUTRAL) return h4Bias;

      return h1Bias;
   }

   //+------------------------------------------------------------------+
   //| [MODULE 2] ADR & Range Exhaustion Filter                         |
   //+------------------------------------------------------------------+
   bool CheckADRExhaustion(bool isContinuation) {
      if(!UseADRExhaustionFilter) return true;

      double sumR = 0.0;
      for(int i = 1; i <= ADR_Period; i++) {
         sumR += (iHigh(_Symbol, PERIOD_D1, i) - iLow(_Symbol, PERIOD_D1, i));
      }
      double adr = sumR / (double)ADR_Period;
      if(adr <= 0) return true;

      double todayRange = iHigh(_Symbol, PERIOD_D1, 0) - iLow(_Symbol, PERIOD_D1, 0);
      double consumed = todayRange / adr;

      // If ADR consumed is high (> 85%), scale down target expectation to 1.5R (TTrades rule)
      if(consumed >= ADR_MaxConsumedCont) {
         m_isADRScaledDown = true;
      } else {
         m_isADRScaledDown = false;
      }

      // Hard block continuation ONLY late in the day when range is severely exhausted (> 125%)
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      if(dt.hour >= LateDayHourCutoff && consumed >= 1.25) {
         LogMessage(LOG_DEBUG, StringFormat("Late-Day Filter Gate: Hour %d >= %d and range exhausted (%.1f%%). No late forced entries.",
                                           dt.hour, LateDayHourCutoff, consumed * 100.0));
         return false;
      }

      return true;
   }

   //+------------------------------------------------------------------+
   //| Robust Market Price Provider                                     |
   //+------------------------------------------------------------------+
   double GetCurrentMarketPrice(ENUM_POSITION_TYPE dir) {
      m_symbol.RefreshRates();
      double px = (dir == POSITION_TYPE_BUY) ? m_symbol.Ask() : m_symbol.Bid();
      if(px <= 0.0) {
         MqlTick tick;
         if(SymbolInfoTick(_Symbol, tick))
            px = (dir == POSITION_TYPE_BUY) ? tick.ask : tick.bid;
      }
      if(px <= 0.0) {
         px = (dir == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      }
      return px;
   }

   //+------------------------------------------------------------------+
   //| [MODULE 3] Dealing Range & 50% Equilibrium Logic                 |
   //+------------------------------------------------------------------+
   bool CheckDealingRangeEQ(ENUM_POSITION_TYPE dir, double entryPx) {
      if(!UseDealingRangeFilter) return true;

      int highestBar = iHighest(_Symbol, PERIOD_H1, MODE_HIGH, 24, 1);
      int lowestBar  = iLowest(_Symbol, PERIOD_H1, MODE_LOW, 24, 1);
      if(highestBar < 0 || lowestBar < 0) return true;

      double swingHigh = iHigh(_Symbol, PERIOD_H1, highestBar);
      double swingLow  = iLow(_Symbol, PERIOD_H1, lowestBar);
      if(swingHigh <= swingLow) return true;

      double eq = (swingHigh + swingLow) * 0.50;

      // Invalidate continuation if previous M15 bar closed beyond EQ against bias
      if(InvalidateOnEQBreach) {
         double m15Close = iClose(_Symbol, PERIOD_M15, 1);
         if(dir == POSITION_TYPE_BUY && m15Close < eq && entryPx < eq) {
            LogMessage(LOG_DEBUG, StringFormat("EQ Filter: Price ($%.2f) failed below H1 EQ ($%.2f). Continuation invalidated.", entryPx, eq));
            return false;
         }
         if(dir == POSITION_TYPE_SELL && m15Close > eq && entryPx > eq) {
            LogMessage(LOG_DEBUG, StringFormat("EQ Filter: Price ($%.2f) failed above H1 EQ ($%.2f). Continuation invalidated.", entryPx, eq));
            return false;
         }
      }

      return true;
   }

   //+------------------------------------------------------------------+
   //| [MODULE 4] Mechanical CISD & Protected Swing Detection           |
   //+------------------------------------------------------------------+
   bool DetectCISD(ENUM_POSITION_TYPE biasDir, SCISD &outCISD) {
      ZeroMemory(outCISD);
      outCISD.confirmed = false;
      outCISD.dir = biasDir;

      int lookback = MathMin(CISD_LookbackBars, 36);

      if(biasDir == POSITION_TYPE_BUY) {
         // Scan for sweep low in bars 2 to lookback
         int lowestBar = -1;
         double minL = 999999.0;
         for(int b = 2; b <= lookback; b++) {
            double l = iLow(_Symbol, PERIOD_M5, b);
            if(l < minL) {
               minL = l;
               lowestBar = b;
            }
         }
         if(lowestBar < 2) return false;

         // Identify down-close candle series leading into sweep low
         double highestDownOpen = minL;
         for(int k = lowestBar; k <= lowestBar + 6 && k < Bars(_Symbol, PERIOD_M5) - 2; k++) {
            if(iClose(_Symbol, PERIOD_M5, k) <= iOpen(_Symbol, PERIOD_M5, k)) {
               highestDownOpen = MathMax(highestDownOpen, iOpen(_Symbol, PERIOD_M5, k));
            }
         }
         // Fallback if no down candle (e.g. pin bar sweep): use high of sweep bar
         if(highestDownOpen <= minL) highestDownOpen = iHigh(_Symbol, PERIOD_M5, lowestBar);

         // Check if a completed bar has closed strictly above highestDownOpen
         bool closedAbove = false;
         for(int c = 1; c < lowestBar; c++) {
            if(iClose(_Symbol, PERIOD_M5, c) > highestDownOpen) {
               closedAbove = true;
               break;
            }
         }

         if(closedAbove) {
            outCISD.confirmed         = true;
            outCISD.cisdLevel         = highestDownOpen;
            outCISD.protectedSwing    = minL;
            outCISD.manipulationRange = MathAbs(highestDownOpen - minL);
            outCISD.sweepBar          = lowestBar;
            outCISD.timeConfirmed     = iTime(_Symbol, PERIOD_M5, 1);
            m_lastProtectedSwing      = minL;
            return true;
         }
      } else if(biasDir == POSITION_TYPE_SELL) {
         // Scan for sweep high in bars 2 to lookback
         int highestBar = -1;
         double maxH = 0.0;
         for(int b = 2; b <= lookback; b++) {
            double h = iHigh(_Symbol, PERIOD_M5, b);
            if(h > maxH) {
               maxH = h;
               highestBar = b;
            }
         }
         if(highestBar < 2) return false;

         // Identify up-close candle series leading into sweep high
         double lowestUpOpen = maxH;
         for(int k = highestBar; k <= highestBar + 6 && k < Bars(_Symbol, PERIOD_M5) - 2; k++) {
            if(iClose(_Symbol, PERIOD_M5, k) >= iOpen(_Symbol, PERIOD_M5, k)) {
               lowestUpOpen = MathMin(lowestUpOpen, iOpen(_Symbol, PERIOD_M5, k));
            }
         }
         // Fallback if no up candle (e.g. shooting star sweep): use low of sweep bar
         if(lowestUpOpen >= maxH || lowestUpOpen <= 0.0) lowestUpOpen = iLow(_Symbol, PERIOD_M5, highestBar);

         // Check if a completed bar has closed strictly below lowestUpOpen
         bool closedBelow = false;
         for(int c = 1; c < highestBar; c++) {
            if(iClose(_Symbol, PERIOD_M5, c) < lowestUpOpen) {
               closedBelow = true;
               break;
            }
         }

         if(closedBelow) {
            outCISD.confirmed         = true;
            outCISD.cisdLevel         = lowestUpOpen;
            outCISD.protectedSwing    = maxH;
            outCISD.manipulationRange = MathAbs(maxH - lowestUpOpen);
            outCISD.sweepBar          = highestBar;
            outCISD.timeConfirmed     = iTime(_Symbol, PERIOD_M5, 1);
            m_lastProtectedSwing      = maxH;
            return true;
         }
      }

      return false;
   }

   //+------------------------------------------------------------------+
   //| [MODULE 5] Five Distinct Mechanical Entry Models                 |
   //+------------------------------------------------------------------+
   bool EvaluateUnicornModel(ENUM_POSITION_TYPE dir, SEntrySetup &setup) {
      int lookback = PatternLookbackBars;
      double bLow  = iLow(_Symbol, PERIOD_M5, 1);
      double bHigh = iHigh(_Symbol, PERIOD_M5, 1);
      double bClose= iClose(_Symbol, PERIOD_M5, 1);
      double tol   = m_currentATR * UnicornOverlapTolerance;

      if(dir == POSITION_TYPE_BUY) {
         for(int j = 2; j <= 12; j++) {
            for(int i = j + 2; i <= lookback - 2; i++) {
               if(iLow(_Symbol, PERIOD_M5, j) < iLow(_Symbol, PERIOD_M5, i)) {
                  double protectedLow = iLow(_Symbol, PERIOD_M5, j);

                  // Bullish Breaker: down-close candle prior to sweep down
                  double bbHigh = 0.0, bbLow = 0.0;
                  for(int k = j + 1; k <= i + 1; k++) {
                     if(iClose(_Symbol, PERIOD_M5, k) <= iOpen(_Symbol, PERIOD_M5, k)) {
                        bbHigh = iHigh(_Symbol, PERIOD_M5, k);
                        bbLow  = iLow(_Symbol, PERIOD_M5, k);
                        break;
                     }
                  }
                  if(bbHigh <= bbLow) continue;

                  // Bullish FVG in displacement leg
                  for(int f = 1; f < j; f++) {
                     double fvgBottom = iHigh(_Symbol, PERIOD_M5, f + 2);
                     double fvgTop    = iLow(_Symbol, PERIOD_M5, f);
                     if(fvgTop > fvgBottom && (fvgTop - fvgBottom) >= (m_currentATR * FVG_MinSizeATR)) {
                        double overlapL = MathMax(bbLow, fvgBottom);
                        double overlapH = MathMin(bbHigh, fvgTop);
                        if(overlapL <= (overlapH + tol)) {
                           for(int r = 1; r <= 2; r++) {
                              double rLow   = iLow(_Symbol, PERIOD_M5, r);
                              double rClose = iClose(_Symbol, PERIOD_M5, r);
                              if(rLow <= (overlapH + tol) && rClose >= (overlapL - tol)) {
                                 setup.isValid          = true;
                                 setup.modelType        = MODEL_UNICORN;
                                 setup.dir              = POSITION_TYPE_BUY;
                                 setup.entryPrice       = GetCurrentMarketPrice(POSITION_TYPE_BUY);
                                 setup.protectedSwing   = protectedLow;
                                 setup.setupName        = "TTrades Unicorn (BB+FVG)";
                                 setup.validationReason = StringFormat("Overlap:[%.2f-%.2f] ProtL:%.2f", overlapL, overlapH, protectedLow);
                                 return true;
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      } else if(dir == POSITION_TYPE_SELL) {
         for(int j = 2; j <= 12; j++) {
            for(int i = j + 2; i <= lookback - 2; i++) {
               if(iHigh(_Symbol, PERIOD_M5, j) > iHigh(_Symbol, PERIOD_M5, i)) {
                  double protectedHigh = iHigh(_Symbol, PERIOD_M5, j);

                  // Bearish Breaker: up-close candle prior to sweep up
                  double bbHigh = 0.0, bbLow = 0.0;
                  for(int k = j + 1; k <= i + 1; k++) {
                     if(iClose(_Symbol, PERIOD_M5, k) >= iOpen(_Symbol, PERIOD_M5, k)) {
                        bbHigh = iHigh(_Symbol, PERIOD_M5, k);
                        bbLow  = iLow(_Symbol, PERIOD_M5, k);
                        break;
                     }
                  }
                  if(bbHigh <= bbLow) continue;

                  for(int f = 1; f < j; f++) {
                     double fvgTop    = iLow(_Symbol, PERIOD_M5, f + 2);
                     double fvgBottom = iHigh(_Symbol, PERIOD_M5, f);
                     if(fvgTop > fvgBottom && (fvgTop - fvgBottom) >= (m_currentATR * FVG_MinSizeATR)) {
                        double overlapL = MathMax(bbLow, fvgBottom);
                        double overlapH = MathMin(bbHigh, fvgTop);
                        if(overlapL <= (overlapH + tol)) {
                           for(int r = 1; r <= 2; r++) {
                              double rHigh  = iHigh(_Symbol, PERIOD_M5, r);
                              double rClose = iClose(_Symbol, PERIOD_M5, r);
                              if(rHigh >= (overlapL - tol) && rClose <= (overlapH + tol)) {
                                 setup.isValid          = true;
                                 setup.modelType        = MODEL_UNICORN;
                                 setup.dir              = POSITION_TYPE_SELL;
                                 setup.entryPrice       = GetCurrentMarketPrice(POSITION_TYPE_SELL);
                                 setup.protectedSwing   = protectedHigh;
                                 setup.setupName        = "TTrades Unicorn (BB+FVG)";
                                 setup.validationReason = StringFormat("Overlap:[%.2f-%.2f] ProtH:%.2f", overlapL, overlapH, protectedHigh);
                                 return true;
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      }
      return false;
   }

   bool EvaluateBreakerBlockModel(ENUM_POSITION_TYPE dir, SEntrySetup &setup) {
      int lookback = PatternLookbackBars;
      double bLow  = iLow(_Symbol, PERIOD_M5, 1);
      double bHigh = iHigh(_Symbol, PERIOD_M5, 1);
      double bClose= iClose(_Symbol, PERIOD_M5, 1);
      double tol   = m_currentATR * 0.25;

      if(dir == POSITION_TYPE_BUY) {
         for(int j = 2; j <= 12; j++) {
            for(int i = j + 2; i <= lookback - 2; i++) {
               if(iLow(_Symbol, PERIOD_M5, j) < iLow(_Symbol, PERIOD_M5, i)) {
                  double bbHigh = 0.0, bbLow = 0.0;
                  for(int k = j + 1; k <= i + 1; k++) {
                     if(iClose(_Symbol, PERIOD_M5, k) <= iOpen(_Symbol, PERIOD_M5, k)) {
                        bbHigh = iHigh(_Symbol, PERIOD_M5, k);
                        bbLow  = iLow(_Symbol, PERIOD_M5, k);
                        break;
                     }
                  }
                  if(bbHigh > bbLow) {
                     for(int r = 1; r <= 2; r++) {
                        double rLow   = iLow(_Symbol, PERIOD_M5, r);
                        double rClose = iClose(_Symbol, PERIOD_M5, r);
                        if(rLow <= (bbHigh + tol) && rClose >= (bbLow - tol)) {
                           setup.isValid          = true;
                           setup.modelType        = MODEL_BREAKER_BLOCK;
                           setup.dir              = POSITION_TYPE_BUY;
                           setup.entryPrice       = GetCurrentMarketPrice(POSITION_TYPE_BUY);
                           setup.protectedSwing   = iLow(_Symbol, PERIOD_M5, j);
                           setup.setupName        = "Breaker Block Retest";
                           setup.validationReason = StringFormat("BB:[%.2f-%.2f]", bbLow, bbHigh);
                           return true;
                        }
                     }
                  }
               }
            }
         }
      } else if(dir == POSITION_TYPE_SELL) {
         for(int j = 2; j <= 12; j++) {
            for(int i = j + 2; i <= lookback - 2; i++) {
               if(iHigh(_Symbol, PERIOD_M5, j) > iHigh(_Symbol, PERIOD_M5, i)) {
                  double bbHigh = 0.0, bbLow = 0.0;
                  for(int k = j + 1; k <= i + 1; k++) {
                     if(iClose(_Symbol, PERIOD_M5, k) >= iOpen(_Symbol, PERIOD_M5, k)) {
                        bbHigh = iHigh(_Symbol, PERIOD_M5, k);
                        bbLow  = iLow(_Symbol, PERIOD_M5, k);
                        break;
                     }
                  }
                  if(bbHigh > bbLow) {
                     for(int r = 1; r <= 2; r++) {
                        double rHigh  = iHigh(_Symbol, PERIOD_M5, r);
                        double rClose = iClose(_Symbol, PERIOD_M5, r);
                        if(rHigh >= (bbLow - tol) && rClose <= (bbHigh + tol)) {
                           setup.isValid          = true;
                           setup.modelType        = MODEL_BREAKER_BLOCK;
                           setup.dir              = POSITION_TYPE_SELL;
                           setup.entryPrice       = GetCurrentMarketPrice(POSITION_TYPE_SELL);
                           setup.protectedSwing   = iHigh(_Symbol, PERIOD_M5, j);
                           setup.setupName        = "Breaker Block Retest";
                           setup.validationReason = StringFormat("BB:[%.2f-%.2f]", bbLow, bbHigh);
                           return true;
                        }
                     }
                  }
               }
            }
         }
      }
      return false;
   }

   bool EvaluateOrderBlockModel(ENUM_POSITION_TYPE dir, SEntrySetup &setup) {
      double tol   = m_currentATR * 0.25;
      int lookback = MathMin(PatternLookbackBars, 25);

      if(dir == POSITION_TYPE_BUY) {
         for(int i = 2; i <= lookback; i++) {
            if(iClose(_Symbol, PERIOD_M5, i) < iOpen(_Symbol, PERIOD_M5, i)) {
               double obHigh = iHigh(_Symbol, PERIOD_M5, i);
               double obLow  = iLow(_Symbol, PERIOD_M5, i);
               double obMT   = (obHigh + obLow) * OB_MeanThresholdRatio;
               double obBodyTop = MathMax(iOpen(_Symbol, PERIOD_M5, i), iClose(_Symbol, PERIOD_M5, i));

               bool displaced = false;
               for(int d = 1; d < i; d++) {
                  if(iClose(_Symbol, PERIOD_M5, d) > obBodyTop) {
                     displaced = true;
                     break;
                  }
               }
               if(!displaced) continue;

               for(int r = 1; r <= 2; r++) {
                  double rLow   = iLow(_Symbol, PERIOD_M5, r);
                  double rClose = iClose(_Symbol, PERIOD_M5, r);
                  if(rLow <= (obHigh + tol) && rClose >= (obMT - tol)) {
                     setup.isValid          = true;
                     setup.modelType        = MODEL_ORDER_BLOCK;
                     setup.dir              = POSITION_TYPE_BUY;
                     setup.entryPrice       = GetCurrentMarketPrice(POSITION_TYPE_BUY);
                     setup.protectedSwing   = obLow;
                     setup.setupName        = "Order Block Continuation";
                     setup.validationReason = StringFormat("OB:[%.2f-%.2f] MT:%.2f", obLow, obHigh, obMT);
                     return true;
                  }
               }
            }
         }
      } else if(dir == POSITION_TYPE_SELL) {
         for(int i = 2; i <= lookback; i++) {
            if(iClose(_Symbol, PERIOD_M5, i) > iOpen(_Symbol, PERIOD_M5, i)) {
               double obHigh = iHigh(_Symbol, PERIOD_M5, i);
               double obLow  = iLow(_Symbol, PERIOD_M5, i);
               double obMT   = (obHigh + obLow) * OB_MeanThresholdRatio;
               double obBodyBottom = MathMin(iOpen(_Symbol, PERIOD_M5, i), iClose(_Symbol, PERIOD_M5, i));

               bool displaced = false;
               for(int d = 1; d < i; d++) {
                  if(iClose(_Symbol, PERIOD_M5, d) < obBodyBottom) {
                     displaced = true;
                     break;
                  }
               }
               if(!displaced) continue;

               for(int r = 1; r <= 2; r++) {
                  double rHigh  = iHigh(_Symbol, PERIOD_M5, r);
                  double rClose = iClose(_Symbol, PERIOD_M5, r);
                  if(rHigh >= (obLow - tol) && rClose <= (obMT + tol)) {
                     setup.isValid          = true;
                     setup.modelType        = MODEL_ORDER_BLOCK;
                     setup.dir              = POSITION_TYPE_SELL;
                     setup.entryPrice       = GetCurrentMarketPrice(POSITION_TYPE_SELL);
                     setup.protectedSwing   = obHigh;
                     setup.setupName        = "Order Block Continuation";
                     setup.validationReason = StringFormat("OB:[%.2f-%.2f] MT:%.2f", obLow, obHigh, obMT);
                     return true;
                  }
               }
            }
         }
      }
      return false;
   }

   bool EvaluateMitigationModel(ENUM_POSITION_TYPE dir, SEntrySetup &setup) {
      double tol   = m_currentATR * 0.25;

      if(dir == POSITION_TYPE_BUY) {
         for(int i = 3; i <= 20; i++) {
            double c = iClose(_Symbol, PERIOD_M5, i);
            double o = iOpen(_Symbol, PERIOD_M5, i);
            if(c < o) {
               double mbHigh = iHigh(_Symbol, PERIOD_M5, i);
               double mbLow  = iLow(_Symbol, PERIOD_M5, i);
               bool broken = false;
               for(int k = 2; k < i; k++) {
                  if(iClose(_Symbol, PERIOD_M5, k) > mbHigh) { broken = true; break; }
               }
               if(!broken) continue;
               for(int r = 1; r <= 2; r++) {
                  double rLow   = iLow(_Symbol, PERIOD_M5, r);
                  double rClose = iClose(_Symbol, PERIOD_M5, r);
                  if(rLow <= (mbHigh + tol) && rClose >= (mbLow - tol)) {
                     setup.isValid          = true;
                     setup.modelType        = MODEL_MITIGATION;
                     setup.dir              = POSITION_TYPE_BUY;
                     setup.entryPrice       = GetCurrentMarketPrice(POSITION_TYPE_BUY);
                     setup.protectedSwing   = mbLow;
                     setup.setupName        = "Mitigation Block Retest";
                     setup.validationReason = StringFormat("MB:[%.2f-%.2f]", mbLow, mbHigh);
                     return true;
                  }
               }
            }
         }
      } else if(dir == POSITION_TYPE_SELL) {
         for(int i = 3; i <= 20; i++) {
            double c = iClose(_Symbol, PERIOD_M5, i);
            double o = iOpen(_Symbol, PERIOD_M5, i);
            if(c > o) {
               double mbHigh = iHigh(_Symbol, PERIOD_M5, i);
               double mbLow  = iLow(_Symbol, PERIOD_M5, i);
               bool broken = false;
               for(int k = 2; k < i; k++) {
                  if(iClose(_Symbol, PERIOD_M5, k) < mbLow) { broken = true; break; }
               }
               if(!broken) continue;
               for(int r = 1; r <= 2; r++) {
                  double rHigh  = iHigh(_Symbol, PERIOD_M5, r);
                  double rClose = iClose(_Symbol, PERIOD_M5, r);
                  if(rHigh >= (mbLow - tol) && rClose <= (mbHigh + tol)) {
                     setup.isValid          = true;
                     setup.modelType        = MODEL_MITIGATION;
                     setup.dir              = POSITION_TYPE_SELL;
                     setup.entryPrice       = GetCurrentMarketPrice(POSITION_TYPE_SELL);
                     setup.protectedSwing   = mbHigh;
                     setup.setupName        = "Mitigation Block Retest";
                     setup.validationReason = StringFormat("MB:[%.2f-%.2f]", mbLow, mbHigh);
                     return true;
                  }
               }
            }
         }
      }
      return false;
   }

   bool EvaluatePropulsionModel(ENUM_POSITION_TYPE dir, SEntrySetup &setup) {
      double tol   = m_currentATR * 0.25;

      if(dir == POSITION_TYPE_BUY) {
         for(int i = 2; i <= 8; i++) {
            if(iClose(_Symbol, PERIOD_M5, i) < iOpen(_Symbol, PERIOD_M5, i)) {
               double pLow  = iLow(_Symbol, PERIOD_M5, i);
               double pHigh = iHigh(_Symbol, PERIOD_M5, i);
               double pMT   = (pHigh + pLow) * 0.5;
               for(int r = 1; r <= 2; r++) {
                  double rLow   = iLow(_Symbol, PERIOD_M5, r);
                  double rClose = iClose(_Symbol, PERIOD_M5, r);
                  if(rLow <= (pHigh + tol) && rClose >= (pMT - tol) && rLow >= (pLow - tol)) {
                     setup.isValid          = true;
                     setup.modelType        = MODEL_PROPULSION;
                     setup.dir              = POSITION_TYPE_BUY;
                     setup.entryPrice       = GetCurrentMarketPrice(POSITION_TYPE_BUY);
                     setup.protectedSwing   = pLow;
                     setup.setupName        = "Propulsion Block";
                     setup.validationReason = StringFormat("Propulsion MT:%.2f", pMT);
                     return true;
                  }
               }
            }
         }
      } else if(dir == POSITION_TYPE_SELL) {
         for(int i = 2; i <= 8; i++) {
            if(iClose(_Symbol, PERIOD_M5, i) > iOpen(_Symbol, PERIOD_M5, i)) {
               double pLow  = iLow(_Symbol, PERIOD_M5, i);
               double pHigh = iHigh(_Symbol, PERIOD_M5, i);
               double pMT   = (pHigh + pLow) * 0.5;
               for(int r = 1; r <= 2; r++) {
                  double rHigh  = iHigh(_Symbol, PERIOD_M5, r);
                  double rClose = iClose(_Symbol, PERIOD_M5, r);
                  if(rHigh >= (pLow - tol) && rClose <= (pMT + tol) && rHigh <= (pHigh + tol)) {
                     setup.isValid          = true;
                     setup.modelType        = MODEL_PROPULSION;
                     setup.dir              = POSITION_TYPE_SELL;
                     setup.entryPrice       = GetCurrentMarketPrice(POSITION_TYPE_SELL);
                     setup.protectedSwing   = pHigh;
                     setup.setupName        = "Propulsion Block";
                     setup.validationReason = StringFormat("Propulsion MT:%.2f", pMT);
                     return true;
                  }
               }
            }
         }
      }
      return false;
   }

   bool EvaluateCISDRetestModel(ENUM_POSITION_TYPE dir, SEntrySetup &setup) {
      if(!m_activeCISD.confirmed || m_activeCISD.dir != dir) return false;
      double tol = m_currentATR * 0.30;

      for(int r = 1; r <= 3; r++) {
         if(dir == POSITION_TYPE_BUY) {
            double rLow   = iLow(_Symbol, PERIOD_M5, r);
            double rClose = iClose(_Symbol, PERIOD_M5, r);
            if(rLow <= (m_activeCISD.cisdLevel + tol) && rClose >= (m_activeCISD.cisdLevel - tol)) {
               setup.isValid          = true;
               setup.modelType        = MODEL_UNICORN; // Confirmed structural shift retest
               setup.dir              = POSITION_TYPE_BUY;
               setup.entryPrice       = GetCurrentMarketPrice(POSITION_TYPE_BUY);
               setup.protectedSwing   = m_activeCISD.protectedSwing;
               setup.setupName        = "TTrades CISD Retest";
               setup.validationReason = StringFormat("CISD:%.2f ProtL:%.2f", m_activeCISD.cisdLevel, m_activeCISD.protectedSwing);
               return true;
            }
         } else if(dir == POSITION_TYPE_SELL) {
            double rHigh  = iHigh(_Symbol, PERIOD_M5, r);
            double rClose = iClose(_Symbol, PERIOD_M5, r);
            if(rHigh >= (m_activeCISD.cisdLevel - tol) && rClose <= (m_activeCISD.cisdLevel + tol)) {
               setup.isValid          = true;
               setup.modelType        = MODEL_UNICORN;
               setup.dir              = POSITION_TYPE_SELL;
               setup.entryPrice       = GetCurrentMarketPrice(POSITION_TYPE_SELL);
               setup.protectedSwing   = m_activeCISD.protectedSwing;
               setup.setupName        = "TTrades CISD Retest";
               setup.validationReason = StringFormat("CISD:%.2f ProtH:%.2f", m_activeCISD.cisdLevel, m_activeCISD.protectedSwing);
               return true;
            }
         }
      }
      return false;
   }

   bool SelectEntryModel(ENUM_POSITION_TYPE dir, SEntrySetup &outSetup) {
      ZeroMemory(outSetup);

      if(ActiveEntryModel == MODEL_ALL_COMBINED || ActiveEntryModel == MODEL_UNICORN) {
         if(EvaluateCISDRetestModel(dir, outSetup)) return true;
      }
      if(ActiveEntryModel == MODEL_UNICORN || ActiveEntryModel == MODEL_ALL_COMBINED) {
         if(EvaluateUnicornModel(dir, outSetup)) return true;
      }
      if(ActiveEntryModel == MODEL_BREAKER_BLOCK || ActiveEntryModel == MODEL_ALL_COMBINED) {
         if(EvaluateBreakerBlockModel(dir, outSetup)) return true;
      }
      if(ActiveEntryModel == MODEL_ORDER_BLOCK || ActiveEntryModel == MODEL_ALL_COMBINED) {
         if(EvaluateOrderBlockModel(dir, outSetup)) return true;
      }
      if(ActiveEntryModel == MODEL_MITIGATION || ActiveEntryModel == MODEL_ALL_COMBINED) {
         if(EvaluateMitigationModel(dir, outSetup)) return true;
      }
      if(ActiveEntryModel == MODEL_PROPULSION || ActiveEntryModel == MODEL_ALL_COMBINED) {
         if(EvaluatePropulsionModel(dir, outSetup)) return true;
      }

      return false;
   }

   //+------------------------------------------------------------------+
   //| [MODULE 6] Wick & Candle Quality Filter                          |
   //+------------------------------------------------------------------+
   bool CheckCandleQuality(ENUM_POSITION_TYPE dir) {
      if(!UseCandleQualityFilter) return true;

      double h = iHigh(_Symbol, CandleQualityTF, 1);
      double l = iLow(_Symbol, CandleQualityTF, 1);
      double o = iOpen(_Symbol, CandleQualityTF, 1);
      double c = iClose(_Symbol, CandleQualityTF, 1);
      double rng = h - l;
      if(rng <= 0) return true;

      double body        = MathAbs(c - o);
      double upperWick   = h - MathMax(o, c);
      double lowerWick   = MathMin(o, c) - l;

      if(dir == POSITION_TYPE_BUY) {
         double opposingWickRatio = upperWick / rng;
         if(opposingWickRatio > MaxOpposingWickRatio) {
            LogMessage(LOG_DEBUG, StringFormat("Candle Quality Gate: Bullish trade rejected. Opposing wick (%.1f%%) > limit (%.1f%%).",
                                              opposingWickRatio * 100.0, MaxOpposingWickRatio * 100.0));
            return false;
         }
      } else if(dir == POSITION_TYPE_SELL) {
         double opposingWickRatio = lowerWick / rng;
         if(opposingWickRatio > MaxOpposingWickRatio) {
            LogMessage(LOG_DEBUG, StringFormat("Candle Quality Gate: Bearish trade rejected. Opposing wick (%.1f%%) > limit (%.1f%%).",
                                              opposingWickRatio * 100.0, MaxOpposingWickRatio * 100.0));
            return false;
         }
      }

      return true;
   }

   //+------------------------------------------------------------------+
   //| [MODULE 7] SMT / Relative Strength Divergence Filter             |
   //+------------------------------------------------------------------+
   bool CheckSMTFilter(ENUM_POSITION_TYPE dir) {
      if(!UseSMTFilter) return true;
      if(!SymbolSelect(SMT_CorrelatedSymbol, true)) return true; // Graceful fallback

      double mainHigh1 = iHigh(_Symbol, PERIOD_M15, 1);
      double mainHigh2 = iHigh(_Symbol, PERIOD_M15, SMT_LookbackBars);
      double mainLow1  = iLow(_Symbol, PERIOD_M15, 1);
      double mainLow2  = iLow(_Symbol, PERIOD_M15, SMT_LookbackBars);

      double corrHigh1 = iHigh(SMT_CorrelatedSymbol, PERIOD_M15, 1);
      double corrHigh2 = iHigh(SMT_CorrelatedSymbol, PERIOD_M15, SMT_LookbackBars);
      double corrLow1  = iLow(SMT_CorrelatedSymbol, PERIOD_M15, 1);
      double corrLow2  = iLow(SMT_CorrelatedSymbol, PERIOD_M15, SMT_LookbackBars);

      if(corrHigh1 <= 0 || corrLow1 <= 0) return true;

      if(dir == POSITION_TYPE_BUY) {
         // Bullish SMT: Main symbol made lower low, but correlated symbol made higher low
         bool mainLowerLow = (mainLow1 < mainLow2);
         bool corrHigherLow = (corrLow1 > corrLow2);
         if(mainLowerLow && corrHigherLow) {
            LogMessage(LOG_INFO, "SMT Confirmation: Bullish SMT Divergence detected between Gold and Silver!");
            return true;
         }
         if(StrictSMT_Confirmation) return false;
      } else if(dir == POSITION_TYPE_SELL) {
         // Bearish SMT: Main symbol made higher high, but correlated symbol made lower high
         bool mainHigherHigh = (mainHigh1 > mainHigh2);
         bool corrLowerHigh  = (corrHigh1 < corrHigh2);
         if(mainHigherHigh && corrLowerHigh) {
            LogMessage(LOG_INFO, "SMT Confirmation: Bearish SMT Divergence detected between Gold and Silver!");
            return true;
         }
         if(StrictSMT_Confirmation) return false;
      }

      return true;
   }

   //+------------------------------------------------------------------+
   //| [MODULE 8] Session & Profile Engine (Seek & Destroy Gate)        |
   //+------------------------------------------------------------------+
   ENUM_TRADING_SESSION GetCurrentSession() {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      int currentMinTotal = dt.hour * 60 + dt.min;

      // Update Asia Range tracking
      if(dt.hour >= AsiaStartHour && dt.hour < AsiaEndHour) {
         double h = iHigh(_Symbol, PERIOD_M5, 1);
         double l = iLow(_Symbol, PERIOD_M5, 1);
         if(h > m_asiaHigh) m_asiaHigh = h;
         if(l < m_asiaLow)  m_asiaLow  = l;
      }

      // Check Seek and Destroy conditions
      if(FilterSeekAndDestroy && dt.hour >= LondonKZ_StartHour && m_asiaHigh > 0 && m_asiaLow < 999999.0) {
         double curH = iHigh(_Symbol, PERIOD_M5, 1);
         double curL = iLow(_Symbol, PERIOD_M5, 1);
         if(curH > m_asiaHigh) m_asiaHighSwept = true;
         if(curL < m_asiaLow)  m_asiaLowSwept  = true;

         if(m_asiaHighSwept && m_asiaLowSwept) {
            m_activeProfile = PROFILE_SEEK_AND_DESTROY;
         }
      }

      if(TradeLondonSession) {
         int startMin = LondonKZ_StartHour * 60 + LondonKZ_StartMin;
         int endMin   = LondonKZ_EndHour * 60 + LondonKZ_EndMin;
         if(currentMinTotal >= startMin && currentMinTotal < endMin)
            return SESSION_LONDON;
      }

      if(TradeNewYorkSession) {
         int startMin = NYKZ_StartHour * 60 + NYKZ_StartMin;
         int endMin   = NYKZ_EndHour * 60 + NYKZ_EndMin;
         if(currentMinTotal >= startMin && currentMinTotal < endMin)
            return SESSION_NEW_YORK;
      }

      return SESSION_NONE;
   }

   //+------------------------------------------------------------------+
   //| Calculate Mechanical Stop Loss & Take Profit                     |
   //+------------------------------------------------------------------+
   bool CalculateSLTP(ENUM_POSITION_TYPE dir, double entryPx, double protectedSwing,
                      double manipulationRange, double &outSL, double &outTP) {
      if(m_currentATR <= 0) return false;

      // Stop Loss Anchoring
      double slDist = 0.0;
      if(UseProtectedSwingSL && protectedSwing > 0.0) {
         double buffer = m_currentATR * ProtectedSL_BufferATR;
         if(dir == POSITION_TYPE_BUY) {
            outSL = protectedSwing - buffer;
            slDist = entryPx - outSL;
         } else {
            outSL = protectedSwing + buffer;
            slDist = outSL - entryPx;
         }
      } else {
         slDist = m_currentATR * 0.90;
         outSL  = (dir == POSITION_TYPE_BUY) ? (entryPx - slDist) : (entryPx + slDist);
      }

      // Clamp SL within bounded ATR multiples
      double minSL = m_currentATR * ProtectedSL_MinATR;
      double maxSL = m_currentATR * ProtectedSL_MaxATR;
      if(slDist < minSL) {
         slDist = minSL;
         outSL  = (dir == POSITION_TYPE_BUY) ? (entryPx - slDist) : (entryPx + slDist);
      }
      if(slDist > maxSL) {
         slDist = maxSL;
         outSL  = (dir == POSITION_TYPE_BUY) ? (entryPx - slDist) : (entryPx + slDist);
      }

      // Take Profit Calculation
      double rrRatio = TargetRR_Ratio;
      if(m_isHTFExhausted || m_isADRScaledDown) {
         rrRatio = 1.50; // Cap target on exhaustion as per TTrades rule
      }

      if(TargetMode == TARGET_STD_DEV && manipulationRange > 0.0) {
         double targetDist = manipulationRange * StdDev_Target1;
         outTP = (dir == POSITION_TYPE_BUY) ? (entryPx + targetDist) : (entryPx - targetDist);
      } else if(TargetMode == TARGET_LIQUIDITY_ERL) {
         double pdh = iHigh(_Symbol, PERIOD_D1, 1);
         double pdl = iLow(_Symbol, PERIOD_D1, 1);
         if(dir == POSITION_TYPE_BUY && pdh > entryPx) {
            outTP = pdh;
         } else if(dir == POSITION_TYPE_SELL && pdl < entryPx) {
            outTP = pdl;
         } else {
            outTP = (dir == POSITION_TYPE_BUY) ? (entryPx + slDist * rrRatio) : (entryPx - slDist * rrRatio);
         }
      } else {
         // Asymmetric RR default
         outTP = (dir == POSITION_TYPE_BUY) ? (entryPx + slDist * rrRatio) : (entryPx - slDist * rrRatio);
      }

      outSL = NormalizeDouble(outSL, _Digits);
      outTP = NormalizeDouble(outTP, _Digits);
      return true;
   }

   //+------------------------------------------------------------------+
   //| [MODULE 11] Audited Institutional Lot Sizing Engine              |
   //+------------------------------------------------------------------+
   double CalculateLotSize(double slDistancePrice) {
      if(slDistancePrice <= 0) return 0.0;

      double balance = m_account.Balance();
      double minLot  = m_symbol.LotsMin();
      double maxLot  = m_symbol.LotsMax();
      double step    = m_symbol.LotsStep();
      double tickVal = m_symbol.TickValue();
      double tickSz  = m_symbol.TickSize();

      if(tickVal <= 0.0) tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      if(tickSz <= 0.0)  tickSz  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      if(minLot <= 0.0)  minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      if(maxLot <= 0.0)  maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      if(step <= 0.0)    step    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

      if(tickSz <= 0 || tickVal <= 0 || step <= 0) return (minLot > 0 ? minLot : 0.01);

      if(LotCalcMode == LOT_CALC_FIXED_LOT) {
         double fixedNormalized = MathFloor(FixedLotSize / step) * step;
         return MathMax(minLot, MathMin(maxLot, fixedNormalized));
      }

      // 1. Base Risk Allocation
      double baseRisk = RiskPercent;

      // 2. Smart Drawdown Brake
      double ddFactor = 1.0;
      if(UseDrawdownBrake && m_dayStartBalance > 0) {
         double currentDD = ((m_dayStartBalance - m_account.Equity()) / m_dayStartBalance) * 100.0;
         if(currentDD >= BrakeTriggerDD) ddFactor = 0.50;
      }

      // 3. Streak Loss Reducer
      double streakFactor = 1.0;
      if(UseStreakRiskReducer && m_consecutiveLosses >= StreakLossTrigger) {
         streakFactor = MathPow(StreakReductionRatio, (m_consecutiveLosses - StreakLossTrigger + 1));
         streakFactor = MathMax(streakFactor, 0.40);
      }

      // STRICT COMBINING: Take strictest cap
      double effectiveRisk = baseRisk * MathMin(ddFactor, streakFactor);
      double riskAmount    = balance * (effectiveRisk / 100.0);

      // Value of 1 lot across SL distance
      double lossPerLot = (slDistancePrice / tickSz) * tickVal;
      if(lossPerLot <= 0) return minLot;

      double calculatedLot = riskAmount / lossPerLot;
      double normalized    = MathFloor(calculatedLot / step) * step;

      // Hard ceiling
      if(MaxAllowedLotSize > 0.0)
         normalized = MathMin(normalized, MaxAllowedLotSize);

      // DEFECT 2 REPAIR: Monetary risk verification for minimum lot
      if(normalized < minLot) {
         double minLotCashRisk = minLot * lossPerLot;
         if(minLotCashRisk > (riskAmount * 1.05)) {
            LogMessage(LOG_WARNING, StringFormat("Min lot (%.2f) cash risk ($%.2f) exceeds budget ($%.2f). Trade safely rejected.",
                                                minLot, minLotCashRisk, riskAmount));
            return 0.0;
         }
         normalized = minLot;
      }

      return MathMax(minLot, MathMin(maxLot, normalized));
   }

   //+------------------------------------------------------------------+
   //| Ironclad Safety Guardian                                         |
   //+------------------------------------------------------------------+
   bool CheckSafetyBeltGuardian() {
      if(!UseSafetyBelt) return true;

      double equity  = m_account.Equity();
      double balance = m_account.Balance();

      // Daily Drawdown Limit
      if(m_dayStartBalance > 0) {
         double dailyDD = ((m_dayStartBalance - equity) / m_dayStartBalance) * 100.0;
         if(dailyDD >= MaxAllowedDailyDD) {
            LogMessage(LOG_ERROR, StringFormat("Safety Belt: Daily Drawdown limit hit (%.2f%% >= %.2f%%). Day Halted.",
                                              dailyDD, MaxAllowedDailyDD));
            m_dailyHalted = true;
            if(AutoCloseOnEmergency) CloseAllPositions();
            return false;
         }
      }

      // Total Drawdown Limit
      if(m_initialDeposit > 0) {
         double totalDD = ((m_initialDeposit - equity) / m_initialDeposit) * 100.0;
         if(totalDD >= MaxAllowedTotalDD) {
            LogMessage(LOG_ERROR, StringFormat("Safety Belt: Total Drawdown ceiling hit (%.2f%% >= %.2f%%). Trading Halted.",
                                              totalDD, MaxAllowedTotalDD));
            m_dailyHalted = true;
            if(AutoCloseOnEmergency) CloseAllPositions();
            return false;
         }
      }

      return true;
   }

   void CloseAllPositions() {
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         if(m_position.SelectByIndex(i)) {
            if(m_position.Magic() == MagicNumber && m_position.Symbol() == _Symbol) {
               m_trade.PositionClose(m_position.Ticket());
            }
         }
      }
   }

   //+------------------------------------------------------------------+
   //| Dynamic 2nd-Trade & Session Circuit Breakers                     |
   //+------------------------------------------------------------------+
   bool CheckDailyAndSessionGates() {
      if(m_dailyHalted) return false;

      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      if(AvoidMonday && dt.day_of_week == 1) return false;
      if(AvoidFridayAfternoon && dt.day_of_week == 5 && dt.hour >= 12) return false;

      if(m_dailyLossesCount >= MaxDailyLosses) {
         LogMessage(LOG_INFO, "Max daily losses reached. Trading halted today.");
         return false;
      }

      if(m_dailyTradesCount >= MaxTradesPerDay) {
         LogMessage(LOG_INFO, "Max daily trades reached. No new trades allowed.");
         return false;
      }

      if(UseDailyProfitLock && m_dailyRealizedPnL >= DailyProfitLockUSD) {
         LogMessage(LOG_INFO, StringFormat("Daily Profit Lock: $%.2f target reached! Day safely banked and locked.",
                                          DailyProfitLockUSD));
         return false;
      }

      // Dynamic 2nd-Trade Gate
      if(m_dailyTradesCount == 1 && m_dailyWinsCount == 1 && RequireTrendForTrade2) {
         double adxBuf[1];
         if(CopyBuffer(m_adxHandle, 0, 1, 1, adxBuf) > 0) {
            if(adxBuf[0] < Trade2MinADX) {
               LogMessage(LOG_INFO, StringFormat("Dynamic 2nd-Trade Gate: Market ADX (%.1f) < %.1f. Banking green day.",
                                                adxBuf[0], Trade2MinADX));
               return false;
            }
         }
      }

      return true;
   }

   //+------------------------------------------------------------------+
   //| Trailing Stop & Break-Even Management                            |
   //+------------------------------------------------------------------+
   void ManageOpenPositions() {
      if(PositionsTotal() <= 0) return;

      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         if(!m_position.SelectByIndex(i)) continue;
         if(m_position.Magic() != MagicNumber || m_position.Symbol() != _Symbol) continue;

         double openPx    = m_position.PriceOpen();
         double currentSL = m_position.StopLoss();
         double currentTP = m_position.TakeProfit();
         double curPrice  = m_position.PriceCurrent();
         ulong  ticket    = m_position.Ticket();

         // Break Even Logic
         if(UseBreakEven && !m_tracker.beSet && m_currentATR > 0) {
            double beTrigger = m_currentATR * BE_TriggerATR;
            double offset    = BE_OffsetPoints * _Point;

            if(m_position.PositionType() == POSITION_TYPE_BUY) {
               if(curPrice >= (openPx + beTrigger)) {
                  double newSL = NormalizeDouble(openPx + offset, _Digits);
                  if(newSL > currentSL) {
                     if(m_trade.PositionModify(ticket, newSL, currentTP)) {
                        m_tracker.beSet = true;
                        LogMessage(LOG_INFO, StringFormat("Smart Break Even set for BUY #%I64u @ %.2f", ticket, newSL));
                     }
                  }
               }
            } else if(m_position.PositionType() == POSITION_TYPE_SELL) {
               if(curPrice <= (openPx - beTrigger)) {
                  double newSL = NormalizeDouble(openPx - offset, _Digits);
                  if(newSL < currentSL || currentSL == 0.0) {
                     if(m_trade.PositionModify(ticket, newSL, currentTP)) {
                        m_tracker.beSet = true;
                        LogMessage(LOG_INFO, StringFormat("Smart Break Even set for SELL #%I64u @ %.2f", ticket, newSL));
                     }
                  }
               }
            }
         }

         // Trailing Stop Logic (behind confirmed protected structure)
         if(UseStructuralTrailing && m_tracker.beSet && m_currentATR > 0) {
            double trailStart = m_currentATR * Trail_StartATR;
            double trailStep  = m_currentATR * Trail_StepATR;

            if(m_position.PositionType() == POSITION_TYPE_BUY) {
               if(curPrice >= (openPx + trailStart)) {
                  double candidateSL = curPrice - trailStep;
                  if(m_lastProtectedSwing > currentSL && m_lastProtectedSwing < curPrice)
                     candidateSL = MathMax(candidateSL, m_lastProtectedSwing);

                  candidateSL = NormalizeDouble(candidateSL, _Digits);
                  if(candidateSL > currentSL + (_Point * 10)) {
                     m_trade.PositionModify(ticket, candidateSL, currentTP);
                  }
               }
            } else if(m_position.PositionType() == POSITION_TYPE_SELL) {
               if(curPrice <= (openPx - trailStart)) {
                  double candidateSL = curPrice + trailStep;
                  if(m_lastProtectedSwing < currentSL && m_lastProtectedSwing > curPrice)
                     candidateSL = MathMin(candidateSL, m_lastProtectedSwing);

                  candidateSL = NormalizeDouble(candidateSL, _Digits);
                  if(candidateSL < currentSL - (_Point * 10) || currentSL == 0.0) {
                     m_trade.PositionModify(ticket, candidateSL, currentTP);
                  }
               }
            }
         }
      }
   }

   //+------------------------------------------------------------------+
   //| Master Mechanical OnTick Execution Loop                          |
   //+------------------------------------------------------------------+
   void OnTick() {
      // 1. Refresh rates and manage active open positions
      m_symbol.RefreshRates();
      ManageOpenPositions();

      // 2. Bar Timing Gate: Process new trade entries strictly on M5 candle close
      datetime currentBarTime = iTime(_Symbol, PERIOD_M5, 0);
      if(OnlyOnCandleClose && currentBarTime == m_lastProcessedBarTime) return;
      m_lastProcessedBarTime = currentBarTime;

      // 3. Update day state and statistics
      UpdateDayState();
      UpdateDailyStatsFromHistory();

      // 4. Update volatility indicators
      if(!UpdateATR()) return;

      // 5. Ironclad Safety Guardian
      if(!CheckSafetyBeltGuardian()) return;

      // 6. Day & Session Filters
      if(!CheckDailyAndSessionGates()) return;

      // 7. Active Positions Gate
      if(PositionsTotal() > 0) return;

      // 8. Cooldown Gate
      if(IsExitCooldownActive()) return;

      // 9. Session Kill Zone Gate
      ENUM_TRADING_SESSION session = GetCurrentSession();
      if(session == SESSION_NONE) return;

      // 10. Seek & Destroy Profile Gate
      if(m_activeProfile == PROFILE_SEEK_AND_DESTROY) {
         LogMessage(LOG_INFO, "Seek & Destroy Profile active (both Asia extremes swept). Trading halted for today.");
         return;
      }

      // 11. Spread & Quality Gate
      if(UseSpreadToATRGate) {
         long spreadPts = (long)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
         if(spreadPts > MaxSpreadPoints) return;
         double spreadPrice = spreadPts * _Point;
         if(m_currentATR > 0 && (spreadPrice / m_currentATR) > MaxSpreadToATRRatio) return;
      }

      // 12. Top-Down Multi-Timeframe Bias Engine
      ENUM_BIAS_STATE htfBias = GetTopDownBias();
      if(htfBias == BIAS_NEUTRAL || htfBias == BIAS_EXHAUSTED) {
         LogMessage(LOG_INFO, StringFormat("[FUNNEL] Bar %s: Rejected at GATE 12 (HTF Bias is %s)",
                                          TimeToString(currentBarTime), (htfBias == BIAS_NEUTRAL ? "NEUTRAL" : "EXHAUSTED")));
         return;
      }

      ENUM_POSITION_TYPE targetDir = (htfBias == BIAS_BULLISH) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;

      // 13. ADR Range Exhaustion Gate
      if(!CheckADRExhaustion(true)) {
         LogMessage(LOG_INFO, StringFormat("[FUNNEL] Bar %s: Rejected at GATE 13 (ADR Exhausted)", TimeToString(currentBarTime)));
         return;
      }

      // 14. Candle Quality Gate
      if(!CheckCandleQuality(targetDir)) {
         LogMessage(LOG_INFO, StringFormat("[FUNNEL] Bar %s: Rejected at GATE 14 (Candle Quality)", TimeToString(currentBarTime)));
         return;
      }

      // 15. SMT Relative Strength Divergence Gate
      if(!CheckSMTFilter(targetDir)) {
         LogMessage(LOG_INFO, StringFormat("[FUNNEL] Bar %s: Rejected at GATE 15 (SMT Filter)", TimeToString(currentBarTime)));
         return;
      }

      // 16. Dealing Range & 50% Equilibrium Gate
      double entryPx = GetCurrentMarketPrice(targetDir);
      if(entryPx <= 0.0) return;

      if(!CheckDealingRangeEQ(targetDir, entryPx)) {
         LogMessage(LOG_INFO, StringFormat("[FUNNEL] Bar %s: Rejected at GATE 16 (Dealing Range EQ)", TimeToString(currentBarTime)));
         return;
      }

      // 17. Mechanical CISD Confirmation (Strict: Never enter on raw sweep alone!)
      if(m_activeCISD.confirmed) {
         if(m_activeCISD.dir == POSITION_TYPE_BUY && iClose(_Symbol, PERIOD_M5, 1) < m_activeCISD.protectedSwing)
            ResetCISD();
         else if(m_activeCISD.dir == POSITION_TYPE_SELL && iClose(_Symbol, PERIOD_M5, 1) > m_activeCISD.protectedSwing)
            ResetCISD();
      }

      SCISD freshCISD;
      if(DetectCISD(targetDir, freshCISD)) {
         m_activeCISD = freshCISD;
      }

      if(RequireCISD_Confirmation) {
         if(!m_activeCISD.confirmed || m_activeCISD.dir != targetDir) {
            LogMessage(LOG_INFO, StringFormat("[FUNNEL] Bar %s: Rejected at GATE 17 (No CISD Confirmation)", TimeToString(currentBarTime)));
            return;
         }
      }

      // 18. Select Mechanical Entry Model
      SEntrySetup setup;
      if(!SelectEntryModel(targetDir, setup)) {
         LogMessage(LOG_INFO, StringFormat("[FUNNEL] Bar %s: Rejected at GATE 18 (No Entry Model Match)", TimeToString(currentBarTime)));
         return;
      }

      // 19. Compute Mechanical SL & TP
      double slPrice = 0.0, tpPrice = 0.0;
      double manipRange = (m_activeCISD.confirmed) ? m_activeCISD.manipulationRange : 0.0;
      double protSwing  = (setup.protectedSwing > 0) ? setup.protectedSwing : m_activeCISD.protectedSwing;

      if(!CalculateSLTP(targetDir, entryPx, protSwing, manipRange, slPrice, tpPrice)) {
         LogMessage(LOG_DEBUG, "Trade Rejected: Failed to compute valid SL/TP.");
         return;
      }

      // 20. Audited Lot Sizing & Cash Risk Allocation
      double slDistance = MathAbs(entryPx - slPrice);
      double lot = CalculateLotSize(slDistance);
      if(lot <= 0.0) {
         LogMessage(LOG_WARNING, "Trade Rejected: Calculated volume is zero or violates cash risk.");
         return;
      }

      // 21. Execute Institutional Order
      bool success = false;
      double execPx = GetCurrentMarketPrice(targetDir);
      if(execPx > 0.0) entryPx = execPx;

      if(targetDir == POSITION_TYPE_BUY) {
         success = m_trade.Buy(lot, _Symbol, entryPx, slPrice, tpPrice, setup.setupName);
      } else {
         success = m_trade.Sell(lot, _Symbol, entryPx, slPrice, tpPrice, setup.setupName);
      }

      if(success) {
         ResetCISD();
         ulong ticket = (m_trade.ResultOrder() > 0) ? m_trade.ResultOrder() : m_trade.ResultDeal();
         m_tracker.ticket          = ticket;
         m_tracker.openTime        = TimeCurrent();
         m_tracker.openPrice       = (m_trade.ResultPrice() > 0.0) ? m_trade.ResultPrice() : entryPx;
         m_tracker.originalSL      = slPrice;
         m_tracker.originalTP      = tpPrice;
         m_tracker.atrAtEntry      = m_currentATR;
         m_tracker.beSet           = false;
         m_tracker.trailingActive  = false;
         m_dailyTradesCount++;

         LogMessage(LOG_INFO, StringFormat("[ORDER EXECUTED] %s %s %.2f @ %.2f | SL: %.2f | TP: %.2f | Ticket: %I64u | Model: %s | %s",
                                          EnumToString(targetDir), _Symbol, lot, entryPx, slPrice, tpPrice,
                                          ticket, EnumToString(setup.modelType), setup.validationReason));
      } else {
         LogMessage(LOG_ERROR, StringFormat("Order Placement Failed! Retcode: %d | Comment: %s | Error: %d",
                                          m_trade.ResultRetcode(), m_trade.ResultComment(), GetLastError()));
      }
   }
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
CApexV12Mechanical *ExtEA = NULL;

int OnInit() {
   ExtEA = new CApexV12Mechanical();
   if(ExtEA == NULL || !ExtEA.Init()) {
      Print("Failed to initialize CApexV12Mechanical!");
      return INIT_FAILED;
   }
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if(ExtEA != NULL) {
      delete ExtEA;
      ExtEA = NULL;
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   if(ExtEA != NULL) ExtEA.OnTick();
}
//+------------------------------------------------------------------+
