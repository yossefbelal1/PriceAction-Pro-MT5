//+------------------------------------------------------------------+
//|                                  Ultimate_ICT_Gold_Scalper_v3.1.mq5 |
//|                             BAKOME Trading Systems - Audited v3.1 |
//|                                    Quant Refactored & Hardened   |
//+------------------------------------------------------------------+
#property copyright "BAKOME - Audited & Refactored by Senior Quant"
#property link      "https://github.com/BAKOME-Hub/BAKOMEGoldScalper"
#property version   "3.10"
#property description "Hardened ICT Gold Scalper with True FVG, Liquidity Sweeps, Dynamic Risk & Full Symbol Specs"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/AccountInfo.mqh>
#include <Trade/DealInfo.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                |
//+------------------------------------------------------------------+
enum ENUM_LOT_CALC_MODE {
   LOT_CALC_PERCENT_RISK = 0,   // Risk Percentage (% of Balance per trade)
   LOT_CALC_FIXED_LOT    = 1    // Fixed Lot Size (حجم لوت ثابت محدد)
};

input group "=== Lot Sizing & Risk Mode Control (التحكم في اللوت والمخاطرة) ==="
input ENUM_LOT_CALC_MODE LotCalcMode       = LOT_CALC_PERCENT_RISK; // Lot Mode: Risk % OR Fixed Lot
input double             FixedLotSize      = 0.10;                  // Fixed Lot Size (if LotCalcMode = Fixed Lot)
input double             RiskPercent       = 1.00;                  // Risk % per trade (Calibrated strictly to 1.0%)
input double             MaxDailyRiskPercent    = 3.0;              // Daily Loss Limit (% of Day Start Balance)
input double             MaxDailyProfitPercent  = 10.0;             // Daily profit target (%)
input int                MaxPositions           = 1;                // Maximum concurrent positions (1 eliminates double losses)
input int                MaxDailyTrades         = 10;               // Maximum trades per day (Full session exploitation)
input int                MaxDailyLosses         = 2;                // Circuit Breaker: Max losing trades per day before halt
input bool               UseDrawdownBrake       = true;             // Smart Drawdown Brake (Protects Prop Firm accounts)
input double             BrakeTriggerDD         = 2.00;             // Drawdown % threshold to cut risk in half

input group "=== Ironclad Safety Belt (حزام أمان الحسابات الممولة الصارم) ==="
input bool   UseSafetyBelt          = false;    // Master Safety Belt Switch (false for unchoked performance)
input double MaxAllowedDailyDD      = 3.00;     // Hard Daily Drawdown limit (% of Day Start Balance, Max 3.0%)
input double MaxAllowedTotalDD      = 5.50;     // Hard Total Drawdown ceiling (% from Initial Deposit, Max 5.5%)
input bool   AutoCloseOnEmergency   = true;     // Force-close open trades immediately if emergency thresholds hit
input bool   CloseFridayNight       = true;     // Close all positions before weekend to prevent gap risk
input int    FridayCloseHour        = 21;       // Friday close hour (Broker time, 21:00)
input bool   AvoidFridayAfternoon   = true;     // Avoid entering new trades on Friday after 12:00
input bool   AvoidMonday            = false;    // Avoid trading on Monday
input bool   AvoidRolloverSpread    = true;     // Avoid trading & trailing during midnight spread widening (23:45-00:15)
input bool   UseStreakRiskReducer   = true;     // Reduce risk by 50% after 2 consecutive losses

input group "=== Predictive Quality & Spread Gates ==="
input bool   UseSpreadToATRGate     = true;     // Spread-to-ATR Predictive Quality Gate (Blocks toxic broker spread expansion)
input double MaxSpreadToATRRatio    = 0.22;     // Max allowable Spread/ATR ratio (spread must not exceed 22% of ATR)
input double MinATR_Points          = 50.0;     // Minimum ATR (in points)
input double MaxSpreadPoints        = 60.0;     // Maximum allowed spread (in points)
input double ATR_SL_Multiplier      = 0.95;     // Stop Loss ATR multiplier (Champion 0.95 ATR)
input double ATR_TP_Multiplier      = 4.00;     // Take Profit ATR multiplier (Champion 4.00 ATR High-Payoff)

input group "=== ICT Strategy Parameters ==="
input bool   UseLiquiditySweeps     = true;     // Enable Liquidity Sweeps confirmation
input bool   UseFairValueGaps       = true;     // Enable Fair Value Gap confirmation
input int    LiquidityLookback      = 40;       // Bars for liquidity swing lookback
input int    FVG_Lookback           = 20;       // Bars for FVG scan
input double FVG_MinSizeATR         = 0.25;     // Minimum FVG size (x ATR, optimized for Gold micro-gaps)
input bool   RequireBothFVGAndSweep = false;    // Require both FVG and Liquidity Sweep (High-Conviction Filter)

input group "=== Candlestick & Chart Patterns (تأكيد النماذج الفنية والبرايس أكشن) ==="
input bool   UseChartPatterns       = false;    // Candlestick Confirmation (Optional filter)
input bool   UseRejectionPinBar     = true;     // Pin Bar / Hammer / Shooting Star Rejection Wick
input bool   UseEngulfingBar        = true;     // Momentum Engulfing Pattern
input bool   UseStructureShift      = true;     // Micro Market Structure Shift (MSS) breakout
input bool   FilterMomentumKnives   = true;     // Filter out momentum candles against trend (falling knife filter)

input group "=== Session Settings ==="
input bool   TradeAsianSession      = false;    // Trade Asian session (00-06)
input bool   TradeLondonSession     = true;     // Trade London session (07-11)
input bool   TradeNewYorkSession    = true;     // Trade New York session (13:30 - 17:00) FULL DUAL SESSION
input int    LondonStartHour        = 7;        // London session start hour
input int    NewYorkStartHour       = 13;       // New York session start hour

input group "=== Silver Bullet Windows ==="
input bool   UseSilverBullet        = true;     // Restrict entries to Kill Zones
input bool   LondonSilverBullet     = true;     // London Kill Zone active (Prime Profit Engine)
input int    LondonKillZoneStart    = 8;        // London Kill Zone Start Hour (Broker Hour: 08)
input int    LondonKillZoneStartMin = 0;        // London Kill Zone Start Minute (0-59)
input int    LondonKillZoneEnd      = 11;       // London Kill Zone End Hour (Broker Hour: 11:00 Full 3 Hours!)
input int    LondonKillZoneEndMin   = 0;        // London Kill Zone End Minute (0-59)
input bool   NewYorkSilverBullet    = true;     // New York Kill Zone active (Full Dual Session Engine)
input int    NYKillZoneStart        = 13;       // NY Kill Zone Start (Broker Hour: 13:30)
input int    NYKillZoneStartMin     = 30;       // NY Kill Zone Start Minute (30)
input int    NYKillZoneEnd          = 17;       // NY Kill Zone End Hour (17:00 Full 3.5 Hours!)
input int    NYKillZoneEndMin       = 0;        // NY Kill Zone End Minute (0-59)

input group "=== Position Management (Smart Structural Tracking) ==="
input bool   UseBreakEven           = true;     // Enable Break Even
input double BE_TriggerATR          = 1.00;     // BE Trigger distance (1.00 ATR, fast risk elimination)
input int    BE_OffsetPoints        = 45;       // BE Offset in points (locks guaranteed profit)
input bool   UseTrailingStop        = true;     // Enable Trailing Stop
input bool   UseStructuralTrailing  = true;     // Trail behind M5 Swing High/Low Structure
input double Trail_StartATR         = 1.5;      // Start Trailing distance (x ATR)
input double Trail_StepATR          = 0.85;     // Dynamic buffer behind price/structure (x ATR, calibrated for London trend)
input bool   UseSmartExhaustion     = false;    // Smart early exit (disabled to let runners hit full target)
input bool   UseSmartLossCutter     = false;    // Smart early loss cut (disabled to prevent premature noise exits)
input bool   UsePartialClose        = true;     // Enable Partial Close
input double PartialClosePercent    = 40.0;     // Partial Close volume (%) - leaving 60% on runner
input double PartialCloseTriggerATR = 1.15;     // Partial Close Trigger distance (1.15 ATR, rapid profit lock)

input group "=== Institutional Bias Confluence ==="
input ENUM_TIMEFRAMES BiasFastTimeframe      = PERIOD_H1;  // Fast EMA Timeframe
input int              BiasFastPeriod         = 34;         // Fast EMA Period
input ENUM_TIMEFRAMES BiasSlowTimeframe      = PERIOD_H4;  // Slow EMA Timeframe
input int              BiasSlowPeriod         = 200;        // Slow EMA Period
input bool             UseMacroTrendFilter    = true;       // Macro Daily Trend Alignment
input int              MacroTrendPeriod       = 50;         // Macro Daily EMA Period

input group "=== Adaptive Market Regime Switching (نظام التكيف الذكي مع حركة الذهب) ==="
input bool   UseAdaptiveRegime               = true;       // Enable Adaptive Market Regime Switch
input double HighVolATR_Points               = 150.0;      // High Volatility Threshold (Points)
input double HighVolMaxTriggerPoints         = 120.0;      // Max Partial/BE Trigger distance in High Vol
input double HighVolBEOffsetATR              = 0.20;       // Dynamic BE Offset in High Vol (x ATR breathing room)
input double HighVolTrailStepATR             = 0.95;       // Dynamic Trail Step in High Vol (prevents noise stopout)

input group "=== Execution Settings ==="
input ulong  MagicNumber            = 778855;   // Magic Number
input int    SlippagePoints         = 10;       // Slippage in points
input int    OrderRetryCount        = 3;        // Order Retry attempts
input int    OrderRetryDelayMs      = 250;      // Delay between retries (ms)

enum ENUM_LOG_LEVEL {
   LOG_NONE = 0,
   LOG_ERROR = 1,
   LOG_WARNING = 2,
   LOG_INFO = 3,
   LOG_DEBUG = 4
};
input ENUM_LOG_LEVEL LogLevel       = LOG_INFO;

//+------------------------------------------------------------------+
//| Structures                                                       |
//+------------------------------------------------------------------+
struct PositionTracker {
   ulong    ticket;
   datetime openTime;
   double   openPrice;
   double   originalSL;
   double   originalTP;
   double   initialRiskCash;
   double   atrAtEntry;
   bool     beSet;
   bool     partialClosed;
   bool     trailingActive;
};

//+------------------------------------------------------------------+
//| Main EA Class                                                    |
//+------------------------------------------------------------------+
class CUltimateICTGoldScalper {
private:
   CTrade            m_trade;
   CPositionInfo     m_position;
   CSymbolInfo       m_symbol;
   CAccountInfo      m_account;
   
   int               m_atrHandle;
   int               m_emaFastHandle;
   int               m_emaSlowHandle;
   int               m_emaDailyHandle;
   
   PositionTracker   m_trackedPositions[];
   
   double            m_initialDeposit;
   double            m_dayStartBalance;
   double            m_peakEquity;
   int               m_todayTradeCount;
   int               m_todayLossCount;
   int               m_consecutiveLosses;
   bool              m_dailyHalted;
   bool              m_permanentHalted;
   int               m_currentDay;
   datetime          m_lastEntryBarTime;
   double            m_currentATR;
   bool              m_initialized;
   
   void LogError(string msg)   { if(LogLevel >= LOG_ERROR)   Print("[ERROR] ", msg); }
   void LogWarning(string msg) { if(LogLevel >= LOG_WARNING) Print("[WARN] ",  msg); }
   void LogInfo(string msg)    { if(LogLevel >= LOG_INFO)    Print("[INFO] ",  msg); }
   void LogDebug(string msg)   { if(LogLevel >= LOG_DEBUG)   Print("[DEBUG] ", msg); }
   
   void CheckAndResetDay() {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      if(dt.day != m_currentDay) {
         m_currentDay = dt.day;
         m_todayTradeCount = 0;
         m_todayLossCount = 0;
         m_dailyHalted = false;
         m_dayStartBalance = m_account.Balance();
         LogInfo(StringFormat("New trading day initialized. Start Balance: %.2f", m_dayStartBalance));
      }
   }
   
   void CloseAllPositions(string reason) {
      m_symbol.RefreshRates();
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         if(m_position.SelectByIndex(i) && m_position.Magic() == MagicNumber && m_position.Symbol() == _Symbol) {
            ulong ticket = m_position.Ticket();
            if(m_trade.PositionClose(ticket)) {
               LogWarning(StringFormat("Prop Firm Guardian: Emergency close on #%I64u | Reason: %s", ticket, reason));
            }
         }
      }
      ArrayResize(m_trackedPositions, 0);
   }
   
   bool CheckPropFirmGuardian() {
      if(!UseSafetyBelt) return false;
      
      if(m_permanentHalted) {
         return true;
      }
      
      double equity = m_account.Equity();
      double balance = m_account.Balance();
      if(m_initialDeposit <= 0) m_initialDeposit = balance;
      if(m_dayStartBalance <= 0) m_dayStartBalance = balance;
      if(m_peakEquity <= 0) m_peakEquity = balance;
      if(equity > m_peakEquity) m_peakEquity = equity;
      
      // 1. Check Total Drawdown from Initial Deposit (Prop Firm Overall Maximum Loss Rule: MaxAllowedTotalDD)
      // Standard Prop Firms (FTMO, FundedNext, etc.) calculate the 8-10% max loss from Starting Balance.
      // An account at +30% profit should never be permanently halted due to a normal peak retracement.
      double totalDDFromInitial = 0.0;
      if(m_initialDeposit > 0 && equity < m_initialDeposit) {
         totalDDFromInitial = ((m_initialDeposit - equity) / m_initialDeposit) * 100.0;
      }
      
      if(totalDDFromInitial >= MaxAllowedTotalDD) {
         LogError(StringFormat("CRITICAL SAFETY BELT: Total Drawdown reached %.2f%% >= %.2f%% ceiling! Halting PERMANENTLY to protect account!",
                              totalDDFromInitial, MaxAllowedTotalDD));
         if(AutoCloseOnEmergency && CountOpenPositions() > 0) {
            CloseAllPositions("Emergency Max DD Ceiling reached: " + DoubleToString(totalDDFromInitial, 2) + "%");
         }
         m_permanentHalted = true;
         return true;
      }
      
      // 2. Check Daily Equity Loss Limit (MaxAllowedDailyDD)
      double dailyLossPct = 0.0;
      if(m_dayStartBalance > 0) {
         dailyLossPct = ((m_dayStartBalance - equity) / m_dayStartBalance) * 100.0;
      }
      
      if(dailyLossPct >= MaxAllowedDailyDD) {
         LogWarning(StringFormat("SAFETY BELT: Daily Loss reached %.2f%% >= %.2f%% limit! Halting today to protect account!",
                                dailyLossPct, MaxAllowedDailyDD));
         if(AutoCloseOnEmergency && CountOpenPositions() > 0) {
            CloseAllPositions("Emergency Daily Loss Limit reached: " + DoubleToString(dailyLossPct, 2) + "%");
         }
         m_dailyHalted = true;
         return true;
      }
      
      if(m_dailyHalted) {
         return true;
      }
      
      // 3. Check Friday Night Weekend Close
      if(CloseFridayNight) {
         MqlDateTime dt;
         TimeToStruct(TimeCurrent(), dt);
         if(dt.day_of_week == 5 && dt.hour >= FridayCloseHour) {
            if(CountOpenPositions() > 0) {
               CloseAllPositions("Friday Night Safety: Pre-empting weekend gap risk on Gold");
            }
            return true;
         }
      }
      
      // 4. Midnight Rollover Spread Filter
      if(AvoidRolloverSpread) {
         MqlDateTime dt;
         TimeToStruct(TimeCurrent(), dt);
         if((dt.hour == 23 && dt.min >= 45) || (dt.hour == 0 && dt.min < 15)) {
            return true;
         }
      }
      
      return false;
   }
   
   bool CheckDailyLimits() {
      if(m_dailyHalted || m_permanentHalted) return true;
      if(m_todayTradeCount >= MaxDailyTrades) return true;
      if(m_todayLossCount >= MaxDailyLosses) {
         LogWarning(StringFormat("Circuit Breaker: Max daily losses (%d) reached. Halting trading today to protect Prop Firm account.", MaxDailyLosses));
         m_dailyHalted = true;
         return true;
      }
      if(m_dayStartBalance <= 0) m_dayStartBalance = m_account.Balance();
      
      double currentEquity = m_account.Equity();
      double dailyPLPercent = (currentEquity - m_dayStartBalance) / m_dayStartBalance * 100.0;
      
      if(dailyPLPercent <= -MaxDailyRiskPercent) {
         LogWarning(StringFormat("Daily Loss Limit reached: %.2f%% <= -%.2f%%. Halting trading.", dailyPLPercent, MaxDailyRiskPercent));
         return true;
      }
      if(dailyPLPercent >= MaxDailyProfitPercent) {
         LogInfo(StringFormat("Daily Profit Target reached: %.2f%% >= %.2f%%. Halting trading.", dailyPLPercent, MaxDailyProfitPercent));
         return true;
      }
      return false;
   }
   
   bool IsInKillZone() {
      if(!UseSilverBullet) return true;
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      
      // Friday Afternoon Risk Gate: No new entries on Friday afternoon (NFP / weekend chop avoidance)
      if(AvoidFridayAfternoon && dt.day_of_week == 5 && dt.hour >= 12) {
         return false;
      }
      
      // Monday Filter: Avoid low-liquidity Monday manipulation chop
      if(AvoidMonday && dt.day_of_week == 1) {
         return false;
      }
      
      int currentMinTotal = dt.hour * 60 + dt.min;
      
      if(LondonSilverBullet) {
         int startMinTotal = LondonKillZoneStart * 60 + LondonKillZoneStartMin;
         int endMinTotal   = LondonKillZoneEnd * 60 + LondonKillZoneEndMin;
         if(currentMinTotal >= startMinTotal && currentMinTotal < endMinTotal) return true;
      }
      
      if(NewYorkSilverBullet) {
         int startMinTotal = NYKillZoneStart * 60 + NYKillZoneStartMin;
         int endMinTotal   = NYKillZoneEnd * 60 + NYKillZoneEndMin;
         if(currentMinTotal >= startMinTotal && currentMinTotal < endMinTotal) return true;
      }
      
      return false;
   }
   
   bool IsInTradingSession() {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      int hour = dt.hour;
      if(TradeAsianSession && hour >= 0 && hour < 6) return true;
      if(TradeLondonSession && hour >= LondonStartHour && hour < (LondonStartHour + 4)) return true;
      if(TradeNewYorkSession && hour >= NewYorkStartHour && hour < (NewYorkStartHour + 4)) return true;
      return false;
   }
   
   ENUM_POSITION_TYPE GetMarketBias() {
      double emaSlow[];
      ArraySetAsSeries(emaSlow, true);
      if(CopyBuffer(m_emaSlowHandle, 0, 0, 2, emaSlow) <= 0) return WRONG_VALUE;
      
      double emaFast[];
      ArraySetAsSeries(emaFast, true);
      if(CopyBuffer(m_emaFastHandle, 0, 0, 2, emaFast) <= 0) return WRONG_VALUE;
      
      double close0 = iClose(_Symbol, PERIOD_M5, 0);
      
      ENUM_POSITION_TYPE bias = WRONG_VALUE;
      // Confluence: Higher Timeframe H4 Trend & H1 Momentum
      if(close0 > emaSlow[0] && close0 > emaFast[0] && emaFast[0] >= emaSlow[0]) bias = POSITION_TYPE_BUY;
      else if(close0 < emaSlow[0] && close0 < emaFast[0] && emaFast[0] <= emaSlow[0]) bias = POSITION_TYPE_SELL;
      
      if(bias == WRONG_VALUE) return WRONG_VALUE;
      
      // Macro Daily Trend Alignment: Prevent shorting equity indices during macro bull regimes
      if(UseMacroTrendFilter && m_emaDailyHandle != INVALID_HANDLE) {
         double emaDaily[];
         ArraySetAsSeries(emaDaily, true);
         if(CopyBuffer(m_emaDailyHandle, 0, 0, 2, emaDaily) > 0) {
            double closeDaily = iClose(_Symbol, PERIOD_D1, 1);
            string sym = _Symbol;
            bool isIndex = (StringFind(sym, "US30") >= 0 || StringFind(sym, "USTEC") >= 0 || StringFind(sym, "NAS") >= 0 || StringFind(sym, "DOW") >= 0);
            if(isIndex && closeDaily > emaDaily[0] && bias == POSITION_TYPE_SELL) {
               return WRONG_VALUE; // Eliminate counter-trend shorting on Indices!
            }
         }
      }
      
      return bias;
   }
   
   bool CheckICTSetup(ENUM_POSITION_TYPE bias) {
      if(m_currentATR <= 0) return false;
      
      bool fvgSignal = false;
      bool sweepSignal = false;
      
      // 1. True 3-Candle ICT Fair Value Gap (evaluated on recent completed bars)
      if(UseFairValueGaps) {
         for(int i = 1; i <= FVG_Lookback; i++) {
            if(bias == POSITION_TYPE_BUY) {
               double low1 = iLow(_Symbol, PERIOD_M5, i);
               double high3 = iHigh(_Symbol, PERIOD_M5, i + 2);
               if(low1 > high3 && (low1 - high3) >= (m_currentATR * FVG_MinSizeATR)) {
                  // Price currently dipping into or reacting from the gap
                  double currentLow = iLow(_Symbol, PERIOD_M5, 0);
                  if(currentLow <= low1 && currentLow >= high3) {
                     fvgSignal = true;
                     break;
                  }
               }
            } else if(bias == POSITION_TYPE_SELL) {
               double high1 = iHigh(_Symbol, PERIOD_M5, i);
               double low3 = iLow(_Symbol, PERIOD_M5, i + 2);
               if(high1 < low3 && (low3 - high1) >= (m_currentATR * FVG_MinSizeATR)) {
                  double currentHigh = iHigh(_Symbol, PERIOD_M5, 0);
                  if(currentHigh >= high1 && currentHigh <= low3) {
                     fvgSignal = true;
                     break;
                  }
               }
            }
         }
      } else {
         fvgSignal = true;
      }
      
      // 2. Liquidity Sweeps
      if(UseLiquiditySweeps) {
         double recentSwingHigh = 0;
         double recentSwingLow = 9999999;
         
         for(int i = 3; i < LiquidityLookback; i++) {
            if(iHigh(_Symbol, PERIOD_M5, i) > iHigh(_Symbol, PERIOD_M5, i-1) &&
               iHigh(_Symbol, PERIOD_M5, i) > iHigh(_Symbol, PERIOD_M5, i-2) &&
               iHigh(_Symbol, PERIOD_M5, i) > iHigh(_Symbol, PERIOD_M5, i+1) &&
               iHigh(_Symbol, PERIOD_M5, i) > iHigh(_Symbol, PERIOD_M5, i+2)) {
               if(iHigh(_Symbol, PERIOD_M5, i) > recentSwingHigh)
                  recentSwingHigh = iHigh(_Symbol, PERIOD_M5, i);
            }
            if(iLow(_Symbol, PERIOD_M5, i) < iLow(_Symbol, PERIOD_M5, i-1) &&
               iLow(_Symbol, PERIOD_M5, i) < iLow(_Symbol, PERIOD_M5, i-2) &&
               iLow(_Symbol, PERIOD_M5, i) < iLow(_Symbol, PERIOD_M5, i+1) &&
               iLow(_Symbol, PERIOD_M5, i) < iLow(_Symbol, PERIOD_M5, i+2)) {
               if(iLow(_Symbol, PERIOD_M5, i) < recentSwingLow)
                  recentSwingLow = iLow(_Symbol, PERIOD_M5, i);
            }
         }
         
         double barLow0 = iLow(_Symbol, PERIOD_M5, 0);
         double barHigh0 = iHigh(_Symbol, PERIOD_M5, 0);
         double barClose0 = iClose(_Symbol, PERIOD_M5, 0);
         
         if(bias == POSITION_TYPE_BUY) {
            // Swept below swing low and closed back above it (liquidity grab)
            if(barLow0 < recentSwingLow && barClose0 > recentSwingLow)
               sweepSignal = true;
         } else if(bias == POSITION_TYPE_SELL) {
            // Swept above swing high and closed back below it
            if(barHigh0 > recentSwingHigh && barClose0 < recentSwingHigh)
               sweepSignal = true;
         }
      } else {
         sweepSignal = true;
      }
      
      bool ictBase = false;
      if(RequireBothFVGAndSweep) {
         ictBase = (fvgSignal && sweepSignal);
      } else {
         ictBase = (fvgSignal || sweepSignal);
      }
      if(!ictBase) return false;
      
      if(UseChartPatterns) {
         if(!CheckCandlePattern(bias)) return false;
      }
      
      return true;
   }
   
   bool CheckCandlePattern(ENUM_POSITION_TYPE bias) {
      if(!UseChartPatterns) return true;
      
      double open1  = iOpen(_Symbol, PERIOD_M5, 1);
      double high1  = iHigh(_Symbol, PERIOD_M5, 1);
      double low1   = iLow(_Symbol, PERIOD_M5, 1);
      double close1 = iClose(_Symbol, PERIOD_M5, 1);
      double range1 = high1 - low1;
      
      if(range1 <= 15 * m_symbol.Point()) return false;
      
      double open2  = iOpen(_Symbol, PERIOD_M5, 2);
      double high2  = iHigh(_Symbol, PERIOD_M5, 2);
      double low2   = iLow(_Symbol, PERIOD_M5, 2);
      double close2 = iClose(_Symbol, PERIOD_M5, 2);
      
      // Also inspect current forming bar 0
      double open0  = iOpen(_Symbol, PERIOD_M5, 0);
      double high0  = iHigh(_Symbol, PERIOD_M5, 0);
      double low0   = iLow(_Symbol, PERIOD_M5, 0);
      double close0 = iClose(_Symbol, PERIOD_M5, 0);
      double range0 = high0 - low0;
      
      if(bias == POSITION_TYPE_BUY) {
         // Filter out falling knives (massive bearish momentum bar crashing down)
         if(FilterMomentumKnives) {
            if(close1 < open1 && (open1 - close1) >= 0.70 * range1 && (close1 - low1) <= 0.15 * range1) {
               LogDebug("Candle Filter: Falling knife detected on BUY bias. Entry blocked.");
               return false;
            }
         }
         
         bool patternFound = false;
         
         // 1. Bullish Pin Bar / Hammer (Rejection wick on Bar 1)
         if(UseRejectionPinBar) {
            double lowerWick1 = MathMin(open1, close1) - low1;
            if(lowerWick1 >= 0.35 * range1 && close1 >= (low1 + 0.35 * range1)) {
               patternFound = true;
            }
            // Or Bar 0 rejection wick
            if(!patternFound && range0 >= 20 * m_symbol.Point()) {
               double lowerWick0 = MathMin(open0, close0) - low0;
               if(lowerWick0 >= 0.40 * range0 && close0 >= (low0 + 0.40 * range0)) {
                  patternFound = true;
               }
            }
         }
         
         // 2. Bullish Engulfing
         if(UseEngulfingBar && !patternFound) {
            if(close1 > open1 && close1 > high2 && (close1 - open1) > MathAbs(close2 - open2)) {
               patternFound = true;
            }
         }
         
         // 3. Market Structure Shift (MSS) / Bullish Breakout
         if(UseStructureShift && !patternFound) {
            if(close1 > open1 && close1 > high2 && low1 > low2) {
               patternFound = true;
            }
         }
         
         return patternFound;
      }
      else if(bias == POSITION_TYPE_SELL) {
         // Filter out momentum rockets (massive bullish momentum bar exploding up)
         if(FilterMomentumKnives) {
            if(close1 > open1 && (close1 - open1) >= 0.70 * range1 && (high1 - close1) <= 0.15 * range1) {
               LogDebug("Candle Filter: Momentum rocket detected on SELL bias. Entry blocked.");
               return false;
            }
         }
         
         bool patternFound = false;
         
         // 1. Bearish Pin Bar / Shooting Star (Rejection wick on Bar 1)
         if(UseRejectionPinBar) {
            double upperWick1 = high1 - MathMax(open1, close1);
            if(upperWick1 >= 0.35 * range1 && close1 <= (high1 - 0.35 * range1)) {
               patternFound = true;
            }
            // Or Bar 0 rejection wick
            if(!patternFound && range0 >= 20 * m_symbol.Point()) {
               double upperWick0 = high0 - MathMax(open0, close0);
               if(upperWick0 >= 0.40 * range0 && close0 <= (high0 - 0.40 * range0)) {
                  patternFound = true;
               }
            }
         }
         
         // 2. Bearish Engulfing
         if(UseEngulfingBar && !patternFound) {
            if(close1 < open1 && close1 < low2 && (open1 - close1) > MathAbs(close2 - open2)) {
               patternFound = true;
            }
         }
         
         // 3. Market Structure Shift (MSS) / Bearish Breakdown
         if(UseStructureShift && !patternFound) {
            if(close1 < open1 && close1 < low2 && high1 < high2) {
               patternFound = true;
            }
         }
         
         return patternFound;
      }
      
      return false;
   }
   
   double CalculateLotSize(double slDistancePrice) {
      if(slDistancePrice <= 0) return 0.0;
      
      m_symbol.Refresh();
      double balance = m_account.Balance();
      double equity = m_account.Equity();
      if(balance <= 0) return 0.0;
      
      if(equity > m_peakEquity) m_peakEquity = equity;
      if(m_peakEquity <= 0) m_peakEquity = balance;
      
      double currentDD_Pct = 0.0;
      if(m_peakEquity > 0) {
         currentDD_Pct = ((m_peakEquity - equity) / m_peakEquity) * 100.0;
      }
      
      double step = m_symbol.LotsStep();
      double minLot = m_symbol.LotsMin();
      double maxLot = m_symbol.LotsMax();
      if(step <= 0) step = 0.01;
      if(minLot <= 0) minLot = 0.01;
      if(maxLot <= 0) maxLot = 100.0;
      int digits = (step < 0.1) ? 2 : 1;
      
      // Mode 1: Fixed Lot Size (لوت ثابت يحدده المستخدم يدوياً)
      if(LotCalcMode == LOT_CALC_FIXED_LOT) {
         double targetLot = FixedLotSize;
         // Apply safety brake if drawdown is active
         if(UseDrawdownBrake && currentDD_Pct >= 5.0) {
            targetLot = targetLot * 0.5; // Cut fixed lot in half if DD exceeds 5%
            LogWarning(StringFormat("Safety Brake: Fixed lot reduced by 50%% due to DD %.2f%%", currentDD_Pct));
         }
         double normLot = MathFloor(targetLot / step) * step;
         if(normLot < minLot) normLot = minLot;
         if(normLot > maxLot) normLot = maxLot;
         return NormalizeDouble(normLot, digits);
      }
      
      // Mode 2: Dynamic Percentage Risk Mode (نسبة مخاطرة مئوية ذكية)
      if(RiskPercent <= 0) return 0.0;
      
      double effectiveRisk = RiskPercent;
      if(UseDrawdownBrake) {
         if(currentDD_Pct >= 5.2) {
            effectiveRisk = RiskPercent * 0.15; // Tier 3 Emergency Brake
            LogWarning(StringFormat("Tier 3 Brake: DD %.2f%% >= 5.2%%. Risk throttled to %.2f%%", currentDD_Pct, effectiveRisk));
         } else if(currentDD_Pct >= 3.6) {
            effectiveRisk = RiskPercent * 0.35; // Tier 2 Strong Brake
            LogWarning(StringFormat("Tier 2 Brake: DD %.2f%% >= 3.6%%. Risk throttled to %.2f%%", currentDD_Pct, effectiveRisk));
         } else if(currentDD_Pct >= 2.0) {
            effectiveRisk = RiskPercent * 0.65; // Tier 1 Dynamic Soft Brake
            LogWarning(StringFormat("Tier 1 Brake: DD %.2f%% >= 2.0%%. Risk throttled to %.2f%%", currentDD_Pct, effectiveRisk));
         }
      }
      
      if(UseStreakRiskReducer && (m_consecutiveLosses >= 2 || m_todayLossCount >= 1)) {
         effectiveRisk = effectiveRisk * 0.5;
         LogWarning(StringFormat("Streak Risk Reducer Active! Losses today: %d, Streak: %d. Risk throttled to %.2f%%",
                                m_todayLossCount, m_consecutiveLosses, effectiveRisk));
      }
      
      double riskAmount = balance * (effectiveRisk / 100.0);
      
      double tickSize = m_symbol.TickSize();
      double tickValue = m_symbol.TickValue(); // Value of 1 tick for 1.0 lot in account currency
      
      double lossPerLot = 0.0;
      if(tickSize > 0 && tickValue > 0) {
         lossPerLot = (slDistancePrice / tickSize) * tickValue;
      } else {
         // Fallback via contract size
         double contractSize = m_symbol.ContractSize();
         if(contractSize > 0) lossPerLot = slDistancePrice * contractSize;
      }
      
      if(lossPerLot <= 0) return 0.0;
      
      double rawLot = riskAmount / lossPerLot;
      double normalized = MathFloor(rawLot / step) * step;
      if(normalized < minLot) normalized = minLot;
      if(normalized > maxLot) normalized = maxLot;
      
      return NormalizeDouble(normalized, digits);
   }
   
   void ConfigureFillingMode(MqlTradeRequest &request) {
      uint filling = (uint)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
      if((filling & SYMBOL_FILLING_FOK) != 0) {
         request.type_filling = ORDER_FILLING_FOK;
      } else if((filling & SYMBOL_FILLING_IOC) != 0) {
         request.type_filling = ORDER_FILLING_IOC;
      } else {
         request.type_filling = ORDER_FILLING_RETURN;
      }
   }
   
   bool ExecuteOrder(ENUM_ORDER_TYPE orderType, double volume, double price, double sl, double tp) {
      MqlTradeRequest request = {};
      MqlTradeResult result = {};
      
      request.action       = TRADE_ACTION_DEAL;
      request.symbol       = _Symbol;
      request.volume       = volume;
      request.type         = orderType;
      request.price        = price;
      request.sl           = sl;
      request.tp           = tp;
      request.deviation    = SlippagePoints;
      request.magic        = MagicNumber;
      request.comment      = "BAKOME_v3.1";
      ConfigureFillingMode(request);
      
      for(int attempt = 0; attempt < OrderRetryCount; attempt++) {
         ZeroMemory(result);
         if(OrderSend(request, result)) {
            if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED) {
               ulong posTicket = result.order;
               if(result.deal > 0) posTicket = result.deal;
               
               RegisterPosition(posTicket, price, sl, tp, volume, m_currentATR);
               m_todayTradeCount++;
               LogInfo(StringFormat("Order Placed: %s %.2f @ %.3f | SL: %.3f | TP: %.3f | Ticket: %I64u",
                                    EnumToString(orderType), volume, price, sl, tp, posTicket));
               return true;
            }
         }
         LogWarning(StringFormat("OrderSend retry %d/%d failed with code %d: %s", 
                                attempt + 1, OrderRetryCount, result.retcode, result.comment));
         Sleep(OrderRetryDelayMs * (attempt + 1));
         // Refresh price
         m_symbol.RefreshRates();
         if(orderType == ORDER_TYPE_BUY) {
            request.price = m_symbol.Ask();
            request.sl    = request.price - (m_currentATR * ATR_SL_Multiplier);
            request.tp    = request.price + (m_currentATR * ATR_TP_Multiplier);
         } else {
            request.price = m_symbol.Bid();
            request.sl    = request.price + (m_currentATR * ATR_SL_Multiplier);
            request.tp    = request.price - (m_currentATR * ATR_TP_Multiplier);
         }
      }
      LogError(StringFormat("Order Execution failed completely. Retcode: %d", result.retcode));
      return false;
   }
   
   void RegisterPosition(ulong ticket, double entry, double sl, double tp, double volume, double atr) {
      int size = ArraySize(m_trackedPositions);
      ArrayResize(m_trackedPositions, size + 1);
      m_trackedPositions[size].ticket = ticket;
      m_trackedPositions[size].openTime = TimeCurrent();
      m_trackedPositions[size].openPrice = entry;
      m_trackedPositions[size].originalSL = sl;
      m_trackedPositions[size].originalTP = tp;
      m_trackedPositions[size].atrAtEntry = atr;
      m_trackedPositions[size].initialRiskCash = MathAbs(entry - sl) * m_symbol.ContractSize() * volume;
      m_trackedPositions[size].beSet = false;
      m_trackedPositions[size].partialClosed = false;
      m_trackedPositions[size].trailingActive = false;
   }
   
   void ManagePositions() {
      m_symbol.RefreshRates();
      double bid = m_symbol.Bid();
      double ask = m_symbol.Ask();
      
      for(int i = ArraySize(m_trackedPositions) - 1; i >= 0; i--) {
         ulong ticket = m_trackedPositions[i].ticket;
         
         // Verify position is still open in MT5
         bool positionFound = false;
         for(int p = 0; p < PositionsTotal(); p++) {
            if(m_position.SelectByIndex(p) && m_position.Magic() == MagicNumber && m_position.Symbol() == _Symbol) {
               if(m_position.Ticket() == ticket || m_position.Identifier() == ticket) {
                  positionFound = true;
                  break;
               }
            }
         }
         
         if(!positionFound) {
            // Check if closed with loss for daily circuit breaker & streak tracking
            if(HistorySelect(TimeCurrent() - 86400, TimeCurrent())) {
               int totalDeals = HistoryDealsTotal();
               for(int d = totalDeals - 1; d >= 0; d--) {
                  ulong dealTicket = HistoryDealGetTicket(d);
                  if(dealTicket > 0 && HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == ticket) {
                     double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                     double dealComm   = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                     double dealSwap   = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
                     double netDeal    = dealProfit + dealComm + dealSwap;
                     
                     if(netDeal < 0) {
                        m_todayLossCount++;
                        m_consecutiveLosses++;
                        LogWarning(StringFormat("Position #%I64u closed at loss (Net: $%.2f). Today losses: %d/%d | Streak: %d",
                                               ticket, netDeal, m_todayLossCount, MaxDailyLosses, m_consecutiveLosses));
                     } else if(netDeal > 0) {
                        m_consecutiveLosses = 0;
                        LogInfo(StringFormat("Position #%I64u closed in profit (Net: +$%.2f). Loss streak reset.", ticket, netDeal));
                     }
                     break;
                  }
               }
            }
            ArrayRemove(m_trackedPositions, i, 1);
            continue;
         }
         
         ENUM_POSITION_TYPE pType = m_position.PositionType();
         double openPrice = m_position.PriceOpen();
         double currentSL = m_position.StopLoss();
         double currentTP = m_position.TakeProfit();
         double atr = (m_trackedPositions[i].atrAtEntry > 0) ? m_trackedPositions[i].atrAtEntry : m_currentATR;
         
         // 1. Partial Close Logic
         if(UsePartialClose && !m_trackedPositions[i].partialClosed && atr > 0) {
            double pcTrigger = atr * PartialCloseTriggerATR;
            if(UseAdaptiveRegime && (atr / m_symbol.Point()) >= HighVolATR_Points) {
               pcTrigger = MathMin(pcTrigger, HighVolMaxTriggerPoints * m_symbol.Point());
            }
            bool triggerHit = false;
            if(pType == POSITION_TYPE_BUY && (bid - openPrice) >= pcTrigger) triggerHit = true;
            if(pType == POSITION_TYPE_SELL && (openPrice - ask) >= pcTrigger) triggerHit = true;
            
            if(triggerHit) {
               double closeVol = m_position.Volume() * (PartialClosePercent / 100.0);
               double step = m_symbol.LotsStep();
               closeVol = MathFloor(closeVol / step) * step;
               if(closeVol >= m_symbol.LotsMin() && closeVol < m_position.Volume()) {
                  if(m_trade.PositionClosePartial(ticket, closeVol)) {
                     m_trackedPositions[i].partialClosed = true;
                     LogInfo(StringFormat("Partial Close of %.2f lots on Ticket %I64u", closeVol, ticket));
                  }
               }
            }
         }
         
         // 2. Smart Break Even Logic (Comparing Price Distance with ATR)
         if(UseBreakEven && !m_trackedPositions[i].beSet && atr > 0) {
            double beTriggerDist = atr * BE_TriggerATR;
            double currentSpreadPrice = ask - bid;
            double offset = MathMax(currentSpreadPrice * 1.5, MathMax(BE_OffsetPoints * m_symbol.Point(), atr * 0.12));
            if(UseAdaptiveRegime && (atr / m_symbol.Point()) >= HighVolATR_Points) {
               beTriggerDist = MathMin(beTriggerDist, (HighVolMaxTriggerPoints + 30.0) * m_symbol.Point());
               offset = MathMax(offset, atr * HighVolBEOffsetATR);
            }
            
            if(pType == POSITION_TYPE_BUY) {
               if((bid - openPrice) >= beTriggerDist) {
                  double newSL = NormalizeDouble(openPrice + offset, (int)m_symbol.Digits());
                  if(newSL > currentSL && newSL < bid) {
                     if(m_trade.PositionModify(ticket, newSL, currentTP)) {
                        m_trackedPositions[i].beSet = true;
                        LogInfo(StringFormat("Smart Break Even set for BUY #%I64u @ %.3f (Net Profit Locked)", ticket, newSL));
                     }
                  }
               }
            } else if(pType == POSITION_TYPE_SELL) {
               if((openPrice - ask) >= beTriggerDist) {
                  double newSL = NormalizeDouble(openPrice - offset, (int)m_symbol.Digits());
                  if((newSL < currentSL || currentSL == 0) && newSL > ask) {
                     if(m_trade.PositionModify(ticket, newSL, currentTP)) {
                        m_trackedPositions[i].beSet = true;
                        LogInfo(StringFormat("Smart Break Even set for SELL #%I64u @ %.3f (Net Profit Locked)", ticket, newSL));
                     }
                  }
               }
            }
         }
         
         // 3. Smart Exhaustion Exit (Lock in profit on momentum rejection wicks)
         if(UseSmartExhaustion && atr > 0) {
            double barOpen0 = iOpen(_Symbol, PERIOD_M5, 0);
            double barHigh0 = iHigh(_Symbol, PERIOD_M5, 0);
            double barLow0  = iLow(_Symbol, PERIOD_M5, 0);
            double barClose0 = iClose(_Symbol, PERIOD_M5, 0);
            double barRange = barHigh0 - barLow0;
            
            if(barRange > (15 * m_symbol.Point())) {
               if(pType == POSITION_TYPE_BUY && (bid - openPrice) >= (1.5 * atr)) {
                  // Upper rejection wick against BUY
                  double upperWick = barHigh0 - MathMax(barOpen0, barClose0);
                  if(upperWick >= (0.40 * barRange) && barClose0 < barOpen0) {
                     if(m_trade.PositionClose(ticket)) {
                        LogInfo(StringFormat("Smart Exhaustion Exit on BUY #%I64u (Upper rejection wick, banking +%.3f pts)",
                                             ticket, (bid - openPrice) / m_symbol.Point()));
                        continue;
                     }
                  }
               } else if(pType == POSITION_TYPE_SELL && (openPrice - ask) >= (1.5 * atr)) {
                  // Lower rejection wick against SELL
                  double lowerWick = MathMin(barOpen0, barClose0) - barLow0;
                  if(lowerWick >= (0.40 * barRange) && barClose0 > barOpen0) {
                     if(m_trade.PositionClose(ticket)) {
                        LogInfo(StringFormat("Smart Exhaustion Exit on SELL #%I64u (Lower rejection wick, banking +%.3f pts)",
                                             ticket, (openPrice - ask) / m_symbol.Point()));
                        continue;
                     }
                  }
               }
            }
         }
         
         // 3.5 Smart Loss Cutter (Early Invalidation on opposing momentum)
         if(UseSmartLossCutter && atr > 0) {
            double barOpen1 = iOpen(_Symbol, PERIOD_M5, 1);
            double barClose1 = iClose(_Symbol, PERIOD_M5, 1);
            double barHigh1 = iHigh(_Symbol, PERIOD_M5, 1);
            double barLow1  = iLow(_Symbol, PERIOD_M5, 1);
            double barRange1 = barHigh1 - barLow1;
            
            if(barRange1 > (15 * m_symbol.Point())) {
               if(pType == POSITION_TYPE_BUY && (openPrice - bid) >= (0.85 * atr)) {
                  // Bearish momentum against BUY
                  if(barClose1 < barOpen1 && (barOpen1 - barClose1) >= (0.60 * barRange1)) {
                     if(m_trade.PositionClose(ticket)) {
                        LogInfo(StringFormat("Smart Loss Cutter: Early invalidation on BUY #%I64u (Cut at -%.2f pts, saving capital)",
                                             ticket, (openPrice - bid) / m_symbol.Point()));
                        continue;
                     }
                  }
               } else if(pType == POSITION_TYPE_SELL && (ask - openPrice) >= (0.85 * atr)) {
                  // Bullish momentum against SELL
                  if(barClose1 > barOpen1 && (barClose1 - barOpen1) >= (0.60 * barRange1)) {
                     if(m_trade.PositionClose(ticket)) {
                        LogInfo(StringFormat("Smart Loss Cutter: Early invalidation on SELL #%I64u (Cut at -%.2f pts, saving capital)",
                                             ticket, (ask - openPrice) / m_symbol.Point()));
                        continue;
                     }
                  }
               }
            }
         }
         
         // 4. Smart Structural & Dynamic Trailing Stop
         if(UseTrailingStop && atr > 0) {
            double trailStartDist = atr * Trail_StartATR;
            double trailStepDist  = atr * Trail_StepATR;
            if(UseAdaptiveRegime && (atr / m_symbol.Point()) >= HighVolATR_Points) {
               trailStepDist = atr * HighVolTrailStepATR;
            }
            
            if(pType == POSITION_TYPE_BUY && (bid - openPrice) >= trailStartDist) {
               double proposedSL = 0.0;
               
               if(UseStructuralTrailing) {
                  // Find most recent completed M5 swing low formed above entry price
                  double bestSwingLow = 0.0;
                  for(int s = 2; s < 15; s++) {
                     if(iLow(_Symbol, PERIOD_M5, s) < iLow(_Symbol, PERIOD_M5, s-1) &&
                        iLow(_Symbol, PERIOD_M5, s) < iLow(_Symbol, PERIOD_M5, s+1)) {
                        double swL = iLow(_Symbol, PERIOD_M5, s);
                        if(swL > openPrice && swL > bestSwingLow) {
                           bestSwingLow = swL;
                        }
                     }
                  }
                  if(bestSwingLow > 0) {
                     proposedSL = NormalizeDouble(bestSwingLow - (15 * m_symbol.Point()), (int)m_symbol.Digits());
                  }
               }
               
               // Fallback to dynamic ATR buffer
               if(proposedSL <= 0 || proposedSL <= currentSL) {
                  proposedSL = NormalizeDouble(bid - trailStepDist, (int)m_symbol.Digits());
               }
               
               if(proposedSL > currentSL + (10 * m_symbol.Point()) && proposedSL < bid) {
                  if(m_trade.PositionModify(ticket, proposedSL, currentTP)) {
                     m_trackedPositions[i].trailingActive = true;
                     LogDebug(StringFormat("Structural Trailing SL updated for BUY #%I64u -> %.3f", ticket, proposedSL));
                  }
               }
            } else if(pType == POSITION_TYPE_SELL && (openPrice - ask) >= trailStartDist) {
               double proposedSL = 0.0;
               
               if(UseStructuralTrailing) {
                  // Find most recent completed M5 swing high formed below entry price
                  double bestSwingHigh = 9999999.0;
                  for(int s = 2; s < 15; s++) {
                     if(iHigh(_Symbol, PERIOD_M5, s) > iHigh(_Symbol, PERIOD_M5, s-1) &&
                        iHigh(_Symbol, PERIOD_M5, s) > iHigh(_Symbol, PERIOD_M5, s+1)) {
                        double swH = iHigh(_Symbol, PERIOD_M5, s);
                        if(swH < openPrice && swH < bestSwingHigh) {
                           bestSwingHigh = swH;
                        }
                     }
                  }
                  if(bestSwingHigh < 9999990.0) {
                     proposedSL = NormalizeDouble(bestSwingHigh + (15 * m_symbol.Point()), (int)m_symbol.Digits());
                  }
               }
               
               if(proposedSL <= 0 || (currentSL > 0 && proposedSL >= currentSL)) {
                  proposedSL = NormalizeDouble(ask + trailStepDist, (int)m_symbol.Digits());
               }
               
               if((proposedSL < currentSL - (10 * m_symbol.Point()) || currentSL == 0) && proposedSL > ask) {
                  if(m_trade.PositionModify(ticket, proposedSL, currentTP)) {
                     m_trackedPositions[i].trailingActive = true;
                     LogDebug(StringFormat("Structural Trailing SL updated for SELL #%I64u -> %.3f", ticket, proposedSL));
                  }
               }
            }
         }
      }
   }
   
   int CountOpenPositions() {
      int count = 0;
      for(int i = 0; i < PositionsTotal(); i++) {
         if(m_position.SelectByIndex(i) && m_position.Magic() == MagicNumber && m_position.Symbol() == _Symbol)
            count++;
      }
      return count;
   }

public:
   CUltimateICTGoldScalper() : m_initialDeposit(0), m_dayStartBalance(0), m_peakEquity(0), m_todayTradeCount(0),
                              m_todayLossCount(0), m_consecutiveLosses(0), m_dailyHalted(false),
                              m_permanentHalted(false), m_currentDay(0), m_lastEntryBarTime(0),
                              m_currentATR(0), m_initialized(false) {}
                              
   ~CUltimateICTGoldScalper() {
      IndicatorRelease(m_atrHandle);
      IndicatorRelease(m_emaFastHandle);
      IndicatorRelease(m_emaSlowHandle);
      if(m_emaDailyHandle != INVALID_HANDLE) IndicatorRelease(m_emaDailyHandle);
   }
   
   bool Init() {
      if(!m_symbol.Name(_Symbol)) {
         LogError("Symbol initialization failed for: " + _Symbol);
         return false;
      }
      m_symbol.Refresh();
      
      m_atrHandle = iATR(_Symbol, PERIOD_M5, 14);
      m_emaFastHandle = iMA(_Symbol, BiasFastTimeframe, BiasFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
      m_emaSlowHandle = iMA(_Symbol, BiasSlowTimeframe, BiasSlowPeriod, 0, MODE_EMA, PRICE_CLOSE);
      m_emaDailyHandle = iMA(_Symbol, PERIOD_D1, MacroTrendPeriod, 0, MODE_EMA, PRICE_CLOSE);
      
      if(m_atrHandle == INVALID_HANDLE || m_emaFastHandle == INVALID_HANDLE || m_emaSlowHandle == INVALID_HANDLE) {
         LogError("Failed to initialize indicator handles");
         return false;
      }
      
      m_trade.SetExpertMagicNumber(MagicNumber);
      m_trade.SetDeviationInPoints(SlippagePoints);
      
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      m_currentDay = dt.day;
      m_initialDeposit = m_account.Balance();
      m_dayStartBalance = m_account.Balance();
      m_peakEquity = m_account.Equity();
      if(m_initialDeposit <= 0) m_initialDeposit = 10000.0;
      if(m_peakEquity <= 0) m_peakEquity = m_dayStartBalance;
      m_todayTradeCount = 0;
      m_todayLossCount = 0;
      m_consecutiveLosses = 0;
      m_dailyHalted = false;
      m_permanentHalted = false;
      m_initialized = true;
      
      LogInfo(StringFormat("BAKOME ICT Gold Scalper v3.1 successfully initialized. Symbol: %s | Magic: %I64u | Deposit: %.2f", _Symbol, MagicNumber, m_initialDeposit));
      return true;
   }
   
   void OnTick() {
      if(!m_initialized) return;
      
      CheckAndResetDay();
      
      // 1. First Priority: Prop Firm Guardian Check (Emergency Ceiling, Daily Loss, Friday Close, Rollover)
      if(CheckPropFirmGuardian()) return;
      
      // Update ATR
      double atrBuffer[];
      ArraySetAsSeries(atrBuffer, true);
      if(CopyBuffer(m_atrHandle, 0, 0, 1, atrBuffer) > 0)
         m_currentATR = atrBuffer[0];
         
      // Manage active positions (Trailing, Break Even, Partial Close)
      ManagePositions();
      
      // Check Filters
      if(!IsInTradingSession() || !IsInKillZone()) return;
      if(CheckDailyLimits()) return;
      if(CountOpenPositions() >= MaxPositions) return;
      
      // Spread and ATR sanity checks
      double currentSpread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      if(currentSpread > MaxSpreadPoints) return;
      if((m_currentATR / m_symbol.Point()) < MinATR_Points) return;
      
      // Predictive Spread-to-ATR Gate: Blocks entries if broker spread consumes > MaxSpreadToATRRatio of ATR
      if(UseSpreadToATRGate && m_currentATR > 0) {
         double spreadDist = currentSpread * m_symbol.Point();
         if((spreadDist / m_currentATR) > MaxSpreadToATRRatio) return;
      }
      
      // Prevent multiple entries on the same bar
      datetime currentBarTime = iTime(_Symbol, PERIOD_M5, 0);
      if(currentBarTime == m_lastEntryBarTime) return;
      
      // Strategy Decision
      ENUM_POSITION_TYPE bias = GetMarketBias();
      if(bias == WRONG_VALUE) return;
      
      if(!CheckICTSetup(bias)) return;
      
      m_symbol.RefreshRates();
      double slDist = m_currentATR * ATR_SL_Multiplier;
      double tpDist = m_currentATR * ATR_TP_Multiplier;
      double lot = CalculateLotSize(slDist);
      
      if(lot <= 0) {
         LogWarning("Calculated lot size is 0 or exceeds broker constraints");
         return;
      }
      
      if(bias == POSITION_TYPE_BUY) {
         double ask = m_symbol.Ask();
         double sl = NormalizeDouble(ask - slDist, (int)m_symbol.Digits());
         double tp = NormalizeDouble(ask + tpDist, (int)m_symbol.Digits());
         if(ExecuteOrder(ORDER_TYPE_BUY, lot, ask, sl, tp)) {
            m_lastEntryBarTime = currentBarTime;
         }
      } else if(bias == POSITION_TYPE_SELL) {
         double bid = m_symbol.Bid();
         double sl = NormalizeDouble(bid + slDist, (int)m_symbol.Digits());
         double tp = NormalizeDouble(bid - tpDist, (int)m_symbol.Digits());
         if(ExecuteOrder(ORDER_TYPE_SELL, lot, bid, sl, tp)) {
            m_lastEntryBarTime = currentBarTime;
         }
      }
   }
};

//+------------------------------------------------------------------+
//| Global Instance & Event Handlers                                 |
//+------------------------------------------------------------------+
CUltimateICTGoldScalper ExtEA;

int OnInit() {
   if(!ExtEA.Init()) return INIT_FAILED;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   Print("BAKOME EA deinitialized with reason code: ", reason);
}

void OnTick() {
   ExtEA.OnTick();
}
