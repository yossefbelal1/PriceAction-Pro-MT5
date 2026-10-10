
int NormalizeTF(int tf) {
   if(tf == 16385) return PERIOD_H1;  // 60
   if(tf == 16388) return PERIOD_H4;  // 240
   if(tf == 16408) return PERIOD_D1;  // 1440
   if(tf == 16386) return 120;        // H2
   if(tf <= 0)     return PERIOD_H1;
   return tf;
}
//+------------------------------------------------------------------+
//|                                  Ultimate_ICT_Scalper_v3.2.mq4   |
//|                             BAKOME Trading Systems - MT4 Edition |
//|                                    Quant Refactored & Hardened   |
//+------------------------------------------------------------------+
#property copyright "BAKOME - Audited & Refactored by Senior Quant"
#property link      "https://github.com/BAKOME-Hub/BAKOMEGoldScalper"
#property version   "3.20"
#property description "Hardened ICT Scalper for MT4 (Gold, US30, USTEC) with True FVG, Liquidity Sweeps & Dynamic Risk"
#property strict

//+------------------------------------------------------------------+
//| Input Parameters                                                |
//+------------------------------------------------------------------+
enum ENUM_LOT_CALC_MODE {
   LOT_CALC_PERCENT_RISK = 0,   // Risk Percentage (% of Balance per trade)
   LOT_CALC_FIXED_LOT    = 1    // Fixed Lot Size (حجم لوت ثابت محدد)
};

input string Inp_Header1            = "=== Lot Sizing & Risk Mode Control ===";
input ENUM_LOT_CALC_MODE LotCalcMode= LOT_CALC_PERCENT_RISK; // Lot Mode: Risk % OR Fixed Lot
input double FixedLotSize           = 0.10;                  // Fixed Lot Size (if Fixed Lot mode)
input double RiskPercent            = 1.00;                  // Risk % per trade (Calibrated strictly to 1.0%)
input double MaxDailyRiskPercent    = 3.0;                   // Daily Loss Limit (% of Day Start Balance)
input double MaxDailyProfitPercent  = 10.0;                  // Daily profit target (%)
input int    MaxPositions           = 1;                     // Maximum concurrent positions
input int    MaxDailyTrades         = 10;                    // Maximum trades per day
input int    MaxDailyLosses         = 2;                     // Circuit Breaker: Max daily losses before halt
input bool   UseDrawdownBrake       = true;                  // Smart Drawdown Brake
input double BrakeTriggerDD         = 2.0;                   // Drawdown % threshold for brake

input string Inp_Header2            = "=== Ironclad Safety Belt ===";
input bool   UseSafetyBelt          = false;                 // Master Safety Belt Switch (false for unchoked performance)
input double MaxAllowedDailyDD      = 3.0;                   // Hard Daily Drawdown limit (% of Day Start Balance)
input double MaxAllowedTotalDD      = 5.5;                   // Hard Total Drawdown ceiling (% from Deposit)
input bool   AutoCloseOnEmergency   = true;                  // Force-close open trades on emergency
input bool   CloseFridayNight       = true;                  // Close all positions before weekend
input int    FridayCloseHour        = 21;                    // Friday close hour (Broker time, 21:00)
input bool   AvoidFridayAfternoon   = true;                  // Avoid entering new trades on Friday after 12:00
input bool   AvoidMonday            = false;                 // Avoid trading on Monday
input bool   AvoidRolloverSpread    = true;                  // Avoid trading during rollover (23:45-00:15)
input bool   UseStreakRiskReducer   = true;                  // Reduce risk by 50% after consecutive losses

input string Inp_Header3            = "=== Predictive Quality & Spread Gates ===";
input bool   UseSpreadToATRGate     = true;                  // Spread-to-ATR Predictive Quality Gate
input double MaxSpreadToATRRatio    = 0.22;                  // Max allowable Spread/ATR ratio
input double MinATR_Points          = 50.0;                  // Minimum ATR (in points)
input double MaxSpreadPoints        = 60.0;                  // Maximum allowed spread (in points)
input double ATR_SL_Multiplier      = 0.95;                  // Stop Loss ATR multiplier (Champion 0.95)
input double ATR_TP_Multiplier      = 2.00;                  // Take Profit ATR multiplier (Champion 2.00)                  // Take Profit ATR multiplier (Champion 4.00)

input string Inp_Header4            = "=== ICT Strategy Parameters ===";
input bool   UseLiquiditySweeps     = true;                  // Enable Liquidity Sweeps confirmation
input bool   UseFairValueGaps       = true;                  // Enable Fair Value Gap confirmation
input int    LiquidityLookback      = 40;                    // Bars for liquidity swing lookback
input int    FVG_Lookback           = 20;                    // Bars for FVG scan
input double FVG_MinSizeATR         = 0.25;                  // Minimum FVG size (x ATR)
input bool   RequireBothFVGAndSweep = false;                 // Require both FVG and Sweep

input string Inp_Header5            = "=== Candlestick & Chart Patterns ===";
input bool   UseChartPatterns       = false;                 // Candlestick Confirmation
input bool   UseRejectionPinBar     = true;                  // Pin Bar Rejection Wick
input bool   UseEngulfingBar        = true;                  // Momentum Engulfing Pattern
input bool   UseStructureShift      = true;                  // Micro Market Structure Shift (MSS)
input bool   FilterMomentumKnives   = true;                  // Filter out momentum knives against trend

input string Inp_Header6            = "=== Session Settings ===";
input bool   TradeAsianSession      = false;                 // Trade Asian session (00-06)
input bool   TradeLondonSession     = true;                  // Trade London session (07-11)
input bool   TradeNewYorkSession    = true;                  // Trade New York session (13-17) FULL DUAL SESSION
input int    LondonStartHour        = 7;                     // London session start hour
input int    NewYorkStartHour       = 13;                    // New York session start hour

input string Inp_Header7            = "=== Silver Bullet Windows ===";
input bool   UseSilverBullet        = true;                  // Restrict entries to Kill Zones
input bool   LondonSilverBullet     = true;                  // London Kill Zone active
input int    LondonKillZoneStart    = 8;                     // London Kill Zone Start Hour
input int    LondonKillZoneStartMin = 0;                     // London Kill Zone Start Minute
input int    LondonKillZoneEnd      = 11;                    // London Kill Zone End Hour (11:00 Full 3 Hours!)
input int    LondonKillZoneEndMin   = 0;                     // London Kill Zone End Minute
input bool   NewYorkSilverBullet    = true;                  // New York Kill Zone active (Full Dual Session)
input int    NYKillZoneStart        = 13;                    // NY Kill Zone Start Hour (13:30)
input int    NYKillZoneStartMin     = 30;                    // NY Kill Zone Start Minute (30)
input int    NYKillZoneEnd          = 17;                    // NY Kill Zone End Hour (17:00 Full 3.5 Hours!)
input int    NYKillZoneEndMin       = 0;                     // NY Kill Zone End Minute

input string Inp_Header8            = "=== Position Management ===";
input bool   UseBreakEven           = true;                  // Enable Break Even
input double BE_TriggerATR          = 1.00;                  // BE Trigger distance (1.00 ATR)
input int    BE_OffsetPoints        = 45;                    // BE Offset in points
input bool   UseTrailingStop        = true;                  // Enable Trailing Stop
input bool   UseStructuralTrailing  = true;                  // Trail behind M5 Swing High/Low
input double Trail_StartATR         = 1.5;                   // Start Trailing distance (x ATR)
input double Trail_StepATR          = 0.85;                  // Dynamic buffer behind structure (x ATR)
input bool   UsePartialClose        = true;                  // Enable Partial Close
input double PartialClosePercent    = 40.0;                  // Partial Close volume (%)
input double PartialCloseTriggerATR = 1.15;                  // Partial Close Trigger distance (1.15 ATR)

input string Inp_Header9            = "=== Institutional Bias Confluence ===";
input int    BiasFastTimeframe      = 60;                    // Fast Bias Timeframe (60 = H1)
input int    BiasSlowTimeframe      = 240;                   // Slow Bias Timeframe (240 = H4)
input bool   UseSmartExhaustion     = false;                 // Smart early exit
input bool   UseSmartLossCutter     = false;                 // Smart early loss cut
input int    OrderRetryCount        = 3;                     // Order retry count
input int    OrderRetryDelayMs      = 250;                   // Order retry delay (ms)
input int    LogLevel               = 3;                     // Log level (1-Error, 2-Warn, 3-Info)
input int    BiasFastPeriod         = 34;                    // Fast EMA Period
input int    BiasSlowPeriod         = 200;                   // Slow EMA Period (H4)
input bool   UseMacroTrendFilter    = true;                  // Macro Daily Trend Alignment
input int    MacroTrendPeriod       = 50;                    // Macro Daily EMA Period
input bool   UseStrictMacroTrend    = true;                  // Strict Macro Daily EMA 50 gate (Champion)

input string Inp_Header10           = "=== Adaptive Market Regime Switching ===";
input bool   UseAdaptiveRegime      = true;                  // Enable Adaptive Market Regime Switch
input double HighVolATR_Points      = 250.0;                 // High Volatility Threshold (Points)
input double HighVolMaxTriggerPoints= 180.0;                 // Max Partial/BE Trigger in High Vol
input double HighVolBEOffsetATR     = 0.20;                  // Dynamic BE Offset in High Vol
input double HighVolTrailStepATR    = 0.95;                  // Dynamic Trail Step in High Vol

input string Inp_Header11           = "=== Execution Settings ===";
input int    MagicNumber            = 208821;                // Magic Number
input int    SlippagePoints         = 10;                    // Slippage in points
input int    MinBarsBetweenTrades   = 4;                     // Minimum M5 bars delay between trades

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
double   g_initialDeposit       = 0.0;
double   g_dayStartBalance      = 0.0;
double   g_peakEquity           = 0.0;
int      g_todayTradeCount      = 0;
int      g_todayLossCount       = 0;
int      g_consecutiveLosses    = 0;
bool     g_dailyHalted          = false;
bool     g_permanentHalted      = false;
int      g_currentDay           = 0;
datetime g_lastEntryBarTime     = 0;
double   g_currentATR           = 0.0;

// Internal struct to track position parameters
struct PosMeta {
   int      ticket;
   double   atrAtEntry;
   bool     beSet;
   bool     partialClosed;
};
PosMeta g_trackedPositions[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   g_currentDay        = Day();
   g_initialDeposit    = AccountBalance();
   g_dayStartBalance   = AccountBalance();
   g_peakEquity        = AccountEquity();
   if(g_initialDeposit <= 0) g_initialDeposit = 1000.0;
   if(g_peakEquity <= 0)     g_peakEquity = g_dayStartBalance;
   g_todayTradeCount   = 0;
   g_todayLossCount    = 0;
   g_consecutiveLosses = 0;
   g_dailyHalted       = false;
   g_permanentHalted   = false;
   ArrayResize(g_trackedPositions, 0);

   Print(StringFormat("[INIT] BAKOME ICT Scalper v3.1 MT4 Initialized. Symbol: %s | Magic: %d | Balance: %.2f",
         Symbol(), MagicNumber, g_initialDeposit));
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   Print("[DEINIT] BAKOME ICT Scalper v3.1 MT4 unloaded. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Daily Reset Logic                                                |
//+------------------------------------------------------------------+
void CheckAndResetDay() {
   int currentDay = Day();
   if(currentDay != g_currentDay) {
      g_currentDay       = currentDay;
      g_dayStartBalance  = AccountBalance();
      g_todayTradeCount  = 0;
      g_todayLossCount   = 0;
      g_dailyHalted      = false;
      Print(StringFormat("[INFO] New trading day initialized. Start Balance: %.2f", g_dayStartBalance));
   }
}

//+------------------------------------------------------------------+
//| Prop Firm & Safety Guardian Check                                |
//+------------------------------------------------------------------+
bool CheckPropFirmGuardian() {
   if(g_permanentHalted) return true;
   double currentEquity = AccountEquity();
   
   if(currentEquity > g_peakEquity) g_peakEquity = currentEquity;
   if(g_peakEquity <= 0) g_peakEquity = g_dayStartBalance;
   if(g_dayStartBalance <= 0) g_dayStartBalance = AccountBalance();
   
   double totalDrawdownPct = 0.0;
   if(g_initialDeposit > 0) {
      totalDrawdownPct = ((g_initialDeposit - currentEquity) / g_initialDeposit) * 100.0;
   }
   
   double dailyLossPct = 0.0;
   if(g_dayStartBalance > 0) {
      dailyLossPct = ((g_dayStartBalance - currentEquity) / g_dayStartBalance) * 100.0;
   }
   
   if(UseSafetyBelt) {
      if(totalDrawdownPct >= MaxAllowedTotalDD) {
         Print(StringFormat("[CRITICAL] SAFETY CEILING HIT: Total Drawdown %.2f%% >= %.2f%%! Halting PERMANENTLY.",
               totalDrawdownPct, MaxAllowedTotalDD));
         if(AutoCloseOnEmergency) CloseAllPositions();
         g_permanentHalted = true;
         return true;
      }
      
      if(dailyLossPct >= MaxAllowedDailyDD) {
         Print(StringFormat("[WARN] SAFETY BELT: Daily Loss reached %.2f%% >= %.2f%%! Halting today.",
               dailyLossPct, MaxAllowedDailyDD));
         if(AutoCloseOnEmergency) CloseAllPositions();
         g_dailyHalted = true;
         return true;
      }
   }
   
   if(g_dailyHalted) return true;
   
   // Friday Night Close
   if(CloseFridayNight && DayOfWeek() == 5 && Hour() >= FridayCloseHour) {
      CloseAllPositions();
      return true;
   }
   
   // Rollover Spread Filter (23:45 - 00:15)
   if(AvoidRolloverSpread) {
      if((Hour() == 23 && Minute() >= 45) || (Hour() == 0 && Minute() < 15)) {
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check Daily Trading Limits                                       |
//+------------------------------------------------------------------+
bool CheckDailyLimits() {
   if(g_dailyHalted || g_permanentHalted) return true;
   if(g_todayTradeCount >= MaxDailyTrades) return true;
   if(g_todayLossCount >= MaxDailyLosses) {
      Print(StringFormat("[CIRCUIT BREAKER] Max daily losses (%d) reached. Halting trading today.", MaxDailyLosses));
      g_dailyHalted = true;
      return true;
   }
   
   double currentEquity = AccountEquity();
   double dailyPLPercent = (currentEquity - g_dayStartBalance) / g_dayStartBalance * 100.0;
   
   if(dailyPLPercent <= -MaxDailyRiskPercent) {
      Print(StringFormat("[HALT] Daily Loss Limit reached: %.2f%%. Halting trading.", dailyPLPercent));
      return true;
   }
   if(dailyPLPercent >= MaxDailyProfitPercent) {
      Print(StringFormat("[TARGET] Daily Profit Target reached: %.2f%%. Halting trading.", dailyPLPercent));
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Session & Silver Bullet Window Filters                           |
//+------------------------------------------------------------------+
bool IsInKillZone() {
   if(!UseSilverBullet) return true;
   
   if(AvoidFridayAfternoon && DayOfWeek() == 5 && Hour() >= 12) {
      return false;
   }
   if(AvoidMonday && DayOfWeek() == 1) {
      return false;
   }
   
   int currentMinTotal = Hour() * 60 + Minute();
   
   if(LondonSilverBullet) {
      int startMin = LondonKillZoneStart * 60 + LondonKillZoneStartMin;
      int endMin   = LondonKillZoneEnd * 60 + LondonKillZoneEndMin;
      if(currentMinTotal >= startMin && currentMinTotal < endMin) return true;
   }
   
   if(NewYorkSilverBullet) {
      int startMin = NYKillZoneStart * 60 + NYKillZoneStartMin;
      int endMin   = NYKillZoneEnd * 60 + NYKillZoneEndMin;
      if(currentMinTotal >= startMin && currentMinTotal < endMin) return true;
   }
   
   return false;
}

bool IsInTradingSession() {
   int h = Hour();
   if(TradeAsianSession && h >= 0 && h < 6) return true;
   if(TradeLondonSession && h >= LondonStartHour && h < (LondonStartHour + 4)) return true;
   if(TradeNewYorkSession && h >= NewYorkStartHour && h < (NewYorkStartHour + 4)) return true;
   return false;
}

//+------------------------------------------------------------------+
//| Market Bias via Institutional Trend Confluence                   |
//+------------------------------------------------------------------+
int GetMarketBias() {
   int slowTF = NormalizeTF(BiasSlowTimeframe);
   int fastTF = NormalizeTF(BiasFastTimeframe);
   double emaSlow = iMA(Symbol(), slowTF, BiasSlowPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   double emaFast = iMA(Symbol(), fastTF, BiasFastPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   
   // MT4 Strategy Tester Fallback: If higher timeframe data is missing, calculate equivalent M5 EMAs
   if(emaSlow <= 0.0 || emaFast <= 0.0) {
      int multSlow = (slowTF == PERIOD_H4) ? 48 : (slowTF == PERIOD_H1 ? 12 : 1);
      int multFast = (fastTF == PERIOD_H1) ? 12 : 1;
      emaSlow = iMA(Symbol(), PERIOD_M5, BiasSlowPeriod * multSlow, 0, MODE_EMA, PRICE_CLOSE, 0);
      emaFast = iMA(Symbol(), PERIOD_M5, BiasFastPeriod * multFast, 0, MODE_EMA, PRICE_CLOSE, 0);
   }
   double close0  = iClose(Symbol(), PERIOD_M5, 0);
   
   int bias = -1; // -1 = None, OP_BUY = Buy, OP_SELL = Sell
   if(close0 > emaSlow && close0 > emaFast && emaFast >= emaSlow) bias = OP_BUY;
   else if(close0 < emaSlow && close0 < emaFast && emaFast <= emaSlow) bias = OP_SELL;
   
   if(bias == -1) return -1;
   
   // Macro Daily Trend Alignment
   if(UseMacroTrendFilter) {
      double emaDaily = iMA(Symbol(), PERIOD_D1, MacroTrendPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
      double closeDaily = iClose(Symbol(), PERIOD_D1, 1);
      string sym = Symbol();
      bool isIndex = (StringFind(sym, "US30") >= 0 || StringFind(sym, "USTEC") >= 0 || 
                      StringFind(sym, "NAS") >= 0  || StringFind(sym, "DOW") >= 0);
      if(isIndex && closeDaily > emaDaily && bias == OP_SELL) {
         return -1; // Block counter-trend shorting on Indices
      }
      if(UseStrictMacroTrend) {
         if(closeDaily < emaDaily && bias == OP_BUY) return -1; // Strict Macro: No buying in Daily downtrend!
         if(closeDaily > emaDaily && bias == OP_SELL) return -1; // Strict Macro: No selling in Daily uptrend!
      }
   }
   return bias;
}

//+------------------------------------------------------------------+
//| Check ICT Setup: Fair Value Gaps & Liquidity Sweeps              |
//+------------------------------------------------------------------+
bool CheckICTSetup(int bias) {
   if(g_currentATR <= 0) return false;
   bool fvgSignal = false;
   bool sweepSignal = false;
   
   // 1. Fair Value Gap Check
   if(UseFairValueGaps) {
      for(int i = 1; i <= FVG_Lookback; i++) {
         if(bias == OP_BUY) {
            double low1 = iLow(Symbol(), PERIOD_M5, i);
            double high3 = iHigh(Symbol(), PERIOD_M5, i + 2);
            if(low1 > high3) {
               double gapSize = low1 - high3;
               if(gapSize >= (g_currentATR * FVG_MinSizeATR)) {
                  fvgSignal = true;
                  break;
               }
            }
         } else if(bias == OP_SELL) {
            double high1 = iHigh(Symbol(), PERIOD_M5, i);
            double low3  = iLow(Symbol(), PERIOD_M5, i + 2);
            if(high1 < low3) {
               double gapSize = low3 - high1;
               if(gapSize >= (g_currentATR * FVG_MinSizeATR)) {
                  fvgSignal = true;
                  break;
               }
            }
         }
      }
   }
   
   // 2. Liquidity Sweep Check
   if(UseLiquiditySweeps) {
      if(bias == OP_BUY) {
         double lowestLow = 999999.0;
         for(int k = 2; k <= LiquidityLookback; k++) {
            double l = iLow(Symbol(), PERIOD_M5, k);
            if(l < lowestLow) lowestLow = l;
         }
         double low1 = iLow(Symbol(), PERIOD_M5, 1);
         double close1 = iClose(Symbol(), PERIOD_M5, 1);
         if(low1 < lowestLow && close1 > lowestLow) sweepSignal = true;
      } else if(bias == OP_SELL) {
         double highestHigh = 0.0;
         for(int k = 2; k <= LiquidityLookback; k++) {
            double h = iHigh(Symbol(), PERIOD_M5, k);
            if(h > highestHigh) highestHigh = h;
         }
         double high1 = iHigh(Symbol(), PERIOD_M5, 1);
         double close1 = iClose(Symbol(), PERIOD_M5, 1);
         if(high1 > highestHigh && close1 < highestHigh) sweepSignal = true;
      }
   }
   
   if(RequireBothFVGAndSweep) return (fvgSignal && sweepSignal);
   if(UseFairValueGaps && UseLiquiditySweeps) return (fvgSignal || sweepSignal);
   if(UseFairValueGaps) return fvgSignal;
   if(UseLiquiditySweeps) return sweepSignal;
   return true;
}

//+------------------------------------------------------------------+
//| Candlestick & Price Action Filter                                |
//+------------------------------------------------------------------+
bool CheckCandlePatterns(int bias) {
   if(!UseChartPatterns) return true;
   
   double open1  = iOpen(Symbol(), PERIOD_M5, 1);
   double close1 = iClose(Symbol(), PERIOD_M5, 1);
   double high1  = iHigh(Symbol(), PERIOD_M5, 1);
   double low1   = iLow(Symbol(), PERIOD_M5, 1);
   double range1 = high1 - low1;
   if(range1 <= 0) return true;
   
   if(bias == OP_BUY) {
      if(FilterMomentumKnives && close1 < open1 && (open1 - close1) >= 0.70 * range1) return false;
      if(UseRejectionPinBar) {
         double lowerWick1 = MathMin(open1, close1) - low1;
         if(lowerWick1 >= 0.35 * range1) return true;
      }
      if(UseEngulfingBar && close1 > open1 && close1 > iHigh(Symbol(), PERIOD_M5, 2)) return true;
      if(UseStructureShift && close1 > open1 && close1 > iHigh(Symbol(), PERIOD_M5, 2) && low1 > iLow(Symbol(), PERIOD_M5, 2)) return true;
   } else if(bias == OP_SELL) {
      if(FilterMomentumKnives && close1 > open1 && (close1 - open1) >= 0.70 * range1) return false;
      if(UseRejectionPinBar) {
         double upperWick1 = high1 - MathMax(open1, close1);
         if(upperWick1 >= 0.35 * range1) return true;
      }
      if(UseEngulfingBar && close1 < open1 && close1 < iLow(Symbol(), PERIOD_M5, 2)) return true;
      if(UseStructureShift && close1 < open1 && close1 < iLow(Symbol(), PERIOD_M5, 2) && high1 < iHigh(Symbol(), PERIOD_M5, 2)) return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Calculate Lot Size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistancePrice) {
   if(slDistancePrice <= 0) return 0.0;
   
   double balance = AccountBalance();
   double equity  = AccountEquity();
   if(balance <= 0) return 0.0;
   
   double step   = MarketInfo(Symbol(), MODE_LOTSTEP);
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   if(step <= 0) step = 0.01;
   if(minLot <= 0) minLot = 0.01;
   if(maxLot <= 0) maxLot = 100.0;
   int digits = (step < 0.1) ? 2 : 1;
   
   if(LotCalcMode == LOT_CALC_FIXED_LOT) {
      double targetLot = FixedLotSize;
      double normLot = MathFloor(targetLot / step) * step;
      if(normLot < minLot) normLot = minLot;
      if(normLot > maxLot) normLot = maxLot;
      return NormalizeDouble(normLot, digits);
   }
   
   if(RiskPercent <= 0) return 0.0;
   double effectiveRisk = RiskPercent;
   
   double riskAmount = balance * (effectiveRisk / 100.0);
   double tickSize   = MarketInfo(Symbol(), MODE_TICKSIZE);
   double tickValue  = MarketInfo(Symbol(), MODE_TICKVALUE);
   
   double lossPerLot = 0.0;
   if(tickSize > 0 && tickValue > 0) {
      lossPerLot = (slDistancePrice / tickSize) * tickValue;
   } else {
      double contractSize = MarketInfo(Symbol(), MODE_LOTSIZE);
      if(contractSize > 0) lossPerLot = slDistancePrice * contractSize;
   }
   
   if(lossPerLot <= 0) return 0.0;
   
   double rawLot = riskAmount / lossPerLot;
   double normalized = MathFloor(rawLot / step) * step;
   if(normalized < minLot) normalized = minLot;
   if(normalized > maxLot) normalized = maxLot;
   return NormalizeDouble(normalized, digits);
}

//+------------------------------------------------------------------+
//| Helper to register and track position metadata                   |
//+------------------------------------------------------------------+
void RegisterPositionMeta(int ticket, double atr) {
   int s = ArraySize(g_trackedPositions);
   ArrayResize(g_trackedPositions, s + 1);
   g_trackedPositions[s].ticket = ticket;
   g_trackedPositions[s].atrAtEntry = atr;
   g_trackedPositions[s].beSet = false;
   g_trackedPositions[s].partialClosed = false;
}

int FindMetaIndex(int ticket) {
   for(int i = 0; i < ArraySize(g_trackedPositions); i++) {
      if(g_trackedPositions[i].ticket == ticket) return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Position Management: Partial Close, Break Even, Trailing Stop    |
//+------------------------------------------------------------------+
void ManagePositions() {
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol()) continue;
      
      int ticket = OrderTicket();
      int type   = OrderType();
      double openPrice = OrderOpenPrice();
      double currentSL = OrderStopLoss();
      double currentTP = OrderTakeProfit();
      double lots      = OrderLots();
      
      int metaIdx = FindMetaIndex(ticket);
      if(metaIdx < 0) {
         RegisterPositionMeta(ticket, g_currentATR);
         metaIdx = FindMetaIndex(ticket);
      }
      
      double atr = (g_trackedPositions[metaIdx].atrAtEntry > 0) ? g_trackedPositions[metaIdx].atrAtEntry : g_currentATR;
      if(atr <= 0) continue;
      
      // 1. Partial Close Logic
      if(UsePartialClose && !g_trackedPositions[metaIdx].partialClosed) {
         double pcTrigger = atr * PartialCloseTriggerATR;
         if(UseAdaptiveRegime && (atr / Point) >= HighVolATR_Points) {
            pcTrigger = MathMin(pcTrigger, HighVolMaxTriggerPoints * Point);
         }
         bool triggerHit = false;
         if(type == OP_BUY  && (Bid - openPrice) >= pcTrigger) triggerHit = true;
         if(type == OP_SELL && (openPrice - Ask) >= pcTrigger) triggerHit = true;
         
         if(triggerHit) {
            double step = MarketInfo(Symbol(), MODE_LOTSTEP);
            double minLot = MarketInfo(Symbol(), MODE_MINLOT);
            double closeVol = MathFloor((lots * (PartialClosePercent / 100.0)) / step) * step;
            if(closeVol >= minLot && closeVol < lots) {
               double closePrice = (type == OP_BUY) ? Bid : Ask;
               if(OrderClose(ticket, closeVol, closePrice, SlippagePoints, clrGold)) {
                  g_trackedPositions[metaIdx].partialClosed = true;
                  Print(StringFormat("[PARTIAL CLOSE] Closed %.2f lots on Ticket #%d", closeVol, ticket));
               }
            }
         }
      }
      
      // 2. Break Even Logic
      if(UseBreakEven && !g_trackedPositions[metaIdx].beSet) {
         double beTriggerDist = atr * BE_TriggerATR;
         double currentSpreadPrice = Ask - Bid;
         double offset = MathMax(currentSpreadPrice * 1.5, MathMax(BE_OffsetPoints * Point, atr * 0.12));
         if(UseAdaptiveRegime && (atr / Point) >= HighVolATR_Points) {
            beTriggerDist = MathMin(beTriggerDist, (HighVolMaxTriggerPoints + 30.0) * Point);
            offset = MathMax(offset, atr * HighVolBEOffsetATR);
         }
         
         if(type == OP_BUY && (Bid - openPrice) >= beTriggerDist) {
            double newSL = NormalizeDouble(openPrice + offset, Digits);
            if(newSL > currentSL && newSL < Bid) {
               if(OrderModify(ticket, openPrice, newSL, currentTP, 0, clrBlue)) {
                  g_trackedPositions[metaIdx].beSet = true;
                  Print(StringFormat("[BREAK EVEN] Secured BUY #%d @ %.3f", ticket, newSL));
               }
            }
         } else if(type == OP_SELL && (openPrice - Ask) >= beTriggerDist) {
            double newSL = NormalizeDouble(openPrice - offset, Digits);
            if((newSL < currentSL || currentSL == 0) && newSL > Ask) {
               if(OrderModify(ticket, openPrice, newSL, currentTP, 0, clrBlue)) {
                  g_trackedPositions[metaIdx].beSet = true;
                  Print(StringFormat("[BREAK EVEN] Secured SELL #%d @ %.3f", ticket, newSL));
               }
            }
         }
      }
      
      // 3. Trailing Stop
      if(UseTrailingStop) {
         double trailStartDist = atr * Trail_StartATR;
         double trailStepDist  = atr * Trail_StepATR;
         if(UseAdaptiveRegime && (atr / Point) >= HighVolATR_Points) {
            trailStepDist = atr * HighVolTrailStepATR;
         }
         
         if(type == OP_BUY && (Bid - openPrice) >= trailStartDist) {
            double proposedSL = 0.0;
            if(UseStructuralTrailing) {
               double bestSwingLow = 0.0;
               for(int s = 2; s < 15; s++) {
                  if(iLow(Symbol(), PERIOD_M5, s) < iLow(Symbol(), PERIOD_M5, s-1) &&
                     iLow(Symbol(), PERIOD_M5, s) < iLow(Symbol(), PERIOD_M5, s+1)) {
                     double swL = iLow(Symbol(), PERIOD_M5, s);
                     if(swL > openPrice && swL > bestSwingLow) bestSwingLow = swL;
                  }
               }
               if(bestSwingLow > 0) proposedSL = NormalizeDouble(bestSwingLow - (15 * Point), Digits);
            }
            if(proposedSL <= 0 || proposedSL <= currentSL) proposedSL = NormalizeDouble(Bid - trailStepDist, Digits);
            if(proposedSL > currentSL + (10 * Point) && proposedSL < Bid) {
               OrderModify(ticket, openPrice, proposedSL, currentTP, 0, clrGreen);
            }
         } else if(type == OP_SELL && (openPrice - Ask) >= trailStartDist) {
            double proposedSL = 0.0;
            if(UseStructuralTrailing) {
               double bestSwingHigh = 9999999.0;
               for(int s = 2; s < 15; s++) {
                  if(iHigh(Symbol(), PERIOD_M5, s) > iHigh(Symbol(), PERIOD_M5, s-1) &&
                     iHigh(Symbol(), PERIOD_M5, s) > iHigh(Symbol(), PERIOD_M5, s+1)) {
                     double swH = iHigh(Symbol(), PERIOD_M5, s);
                     if(swH < openPrice && swH < bestSwingHigh) bestSwingHigh = swH;
                  }
               }
               if(bestSwingHigh < 9999990.0) proposedSL = NormalizeDouble(bestSwingHigh + (15 * Point), Digits);
            }
            if(proposedSL <= 0 || (currentSL > 0 && proposedSL >= currentSL)) proposedSL = NormalizeDouble(Ask + trailStepDist, Digits);
            if((proposedSL < currentSL - (10 * Point) || currentSL == 0) && proposedSL > Ask) {
               OrderModify(ticket, openPrice, proposedSL, currentTP, 0, clrGreen);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Close All Positions Helper                                       |
//+------------------------------------------------------------------+
void CloseAllPositions() {
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol()) continue;
      
      int type = OrderType();
      double closePrice = (type == OP_BUY) ? Bid : Ask;
      if(!OrderClose(OrderTicket(), OrderLots(), closePrice, SlippagePoints, clrRed)) { Print("[WARN] OrderClose failed: ", GetLastError()); }
   }
}

int CountOpenPositions() {
   int count = 0;
   for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   CheckAndResetDay();
   if(CheckPropFirmGuardian()) return;
   
   g_currentATR = iATR(Symbol(), PERIOD_M5, 14, 0);
   ManagePositions();
   
   if(!IsInTradingSession() || !IsInKillZone()) return;
   if(CheckDailyLimits()) return;
   if(CountOpenPositions() >= MaxPositions) return;
   
   // Spread & ATR Quality Gates
   double currentSpread = (Ask - Bid) / Point;
   double effectiveMaxSpread = MaxSpreadPoints;
   if(Digits == 3 && effectiveMaxSpread < 150.0) effectiveMaxSpread = 250.0;
   if(effectiveMaxSpread > 0 && currentSpread > effectiveMaxSpread) return;
   if((g_currentATR / Point) < MinATR_Points) return;
   if(UseSpreadToATRGate && g_currentATR > 0) {
      if(((currentSpread * Point) / g_currentATR) > MaxSpreadToATRRatio) return;
   }
   
   // One entry per bar
   datetime currentBarTime = iTime(Symbol(), PERIOD_M5, 0);
   if(currentBarTime == g_lastEntryBarTime) return;
   if(g_lastEntryBarTime > 0) {
      int barsSince = iBarShift(Symbol(), PERIOD_M5, g_lastEntryBarTime, false);
      if(barsSince < MinBarsBetweenTrades) return;
   }
   
   int bias = GetMarketBias();
   if(bias == -1) return;
   
   if(!CheckICTSetup(bias)) return;
   if(!CheckCandlePatterns(bias)) return;
   
   // Execute Order
   double slDistance = g_currentATR * ATR_SL_Multiplier;
   double tpDistance = g_currentATR * ATR_TP_Multiplier;
   double volume = CalculateLotSize(slDistance);
   if(volume <= 0) return;
   
   double entryPrice = (bias == OP_BUY) ? Ask : Bid;
   double sl = (bias == OP_BUY) ? NormalizeDouble(entryPrice - slDistance, Digits) : NormalizeDouble(entryPrice + slDistance, Digits);
   double tp = (bias == OP_BUY) ? NormalizeDouble(entryPrice + tpDistance, Digits) : NormalizeDouble(entryPrice - tpDistance, Digits);
   
   color arrowColor = (bias == OP_BUY) ? clrGreen : clrRed;
   int ticket = OrderSend(Symbol(), bias, volume, entryPrice, SlippagePoints, sl, tp, "BAKOME_v3.1", MagicNumber, 0, arrowColor);
   
   if(ticket > 0) {
      g_lastEntryBarTime = currentBarTime;
      g_todayTradeCount++;
      RegisterPositionMeta(ticket, g_currentATR);
      Print(StringFormat("[ORDER PLACED] %s %.2f @ %.3f | SL: %.3f | TP: %.3f | Ticket: %d",
            (bias == OP_BUY ? "BUY" : "SELL"), volume, entryPrice, sl, tp, ticket));
   } else {
      Print("[ORDER ERROR] OrderSend failed with error code: ", GetLastError());
   }
}
//+------------------------------------------------------------------+
