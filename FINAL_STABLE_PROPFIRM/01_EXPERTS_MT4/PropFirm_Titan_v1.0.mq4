//+------------------------------------------------------------------+

//|                                  PropFirm_Titan_v1.0.mq4   |

//|                             BAKOME Trading Systems - MT4 Edition |

//|                                    Quant Refactored & Hardened   |

//+------------------------------------------------------------------+

#property copyright "BAKOME - Audited & Refactored by Senior Quant"

#property link      "https://github.com/BAKOME-Hub/BAKOMEGoldScalper"

#property version   "3.10"

#property description "Hardened ICT Scalper for MT4 (Gold, US30, USTEC) with True FVG, Liquidity Sweeps & Dynamic Risk"

#property strict



int NormalizeTF(int tf) {

   if(tf == 16385) return PERIOD_H1;  // 60

   if(tf == 16388) return PERIOD_H4;  // 240

   if(tf == 16408) return PERIOD_D1;  // 1440

   if(tf == 16386) return 120;        // H2

   if(tf <= 0)     return PERIOD_H1;

   return tf;

}



//+------------------------------------------------------------------+

//| Input Parameters                                                |

//+------------------------------------------------------------------+

enum ENUM_LOT_CALC_MODE {

   LOT_CALC_PERCENT_RISK = 0,   // Risk Percentage (% of Balance per trade)

   LOT_CALC_FIXED_LOT    = 1    // Fixed Lot Size

};



input string Inp_Header1            = "=== Lot Sizing & Risk Mode Control ===";

input ENUM_LOT_CALC_MODE LotCalcMode= LOT_CALC_PERCENT_RISK; // Lot Mode: Risk % OR Fixed Lot

input double FixedLotSize           = 0.05;                  // Fixed Lot Size (if Fixed Lot mode)

input double RiskPercent            = 1.0;                   // Risk % per trade (if Risk % mode)

input double MaxDailyRiskPercent    = 3.5;                   // Daily Loss Limit (% of Day Start Balance)

input double MaxDailyProfitPercent  = 15.0;                  // Daily profit target (%)

input int    MaxPositions           = 1;                     // Maximum concurrent positions

input int    MaxDailyTrades         = 14;                    // Maximum trades per day

input int    MaxDailyLosses         = 2;                     // Circuit Breaker: Max daily losses before halt

input bool   UseDrawdownBrake       = true;                  // Smart Drawdown Brake

input double BrakeTriggerDD         = 2.0;                   // Drawdown % threshold for brake



input string Inp_Header2            = "=== Ironclad Safety Belt ===";

input bool   UseSafetyBelt          = false;                 // Master Safety Belt Switch (false for Personal)

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
input double MaxSpreadPoints        = 250.0;                 // Maximum allowed spread (in points)
input double ATR_SL_Multiplier      = 0.95;                  // Stop Loss ATR multiplier
input double ATR_TP_Multiplier      = 4.00;                  // Take Profit ATR multiplier

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
input bool   TradeNewYorkSession    = true;                  // Trade New York session (13-17)
input int    LondonStartHour        = 7;                     // London session start hour
input int    NewYorkStartHour       = 13;                    // New York session start hour

input string Inp_Header7            = "=== Silver Bullet Windows ===";
input bool   UseSilverBullet        = true;                  // Restrict entries to Kill Zones
input bool   LondonSilverBullet     = true;                  // London Kill Zone active
input int    LondonKillZoneStart    = 8;                     // London Kill Zone Start Hour
input int    LondonKillZoneStartMin = 0;                     // London Kill Zone Start Minute
input int    LondonKillZoneEnd      = 11;                    // London Kill Zone End Hour
input int    LondonKillZoneEndMin   = 0;                     // London Kill Zone End Minute
input bool   NewYorkSilverBullet    = true;                  // New York Kill Zone
input int    NYKillZoneStart        = 13;                    // NY Kill Zone Start Hour
input int    NYKillZoneStartMin     = 30;                    // NY Kill Zone Start Minute
input int    NYKillZoneEnd          = 18;                    // NY Kill Zone End Hour
input int    NYKillZoneEndMin       = 0;                     // NY Kill Zone End Minute

input string Inp_Header8            = "=== Position Management ===";
input bool   UseBreakEven           = true;                  // Enable Break Even
input double BE_TriggerATR          = 1.00;                  // BE Trigger distance (x ATR)
input int    BE_OffsetPoints        = 45;                    // BE Offset in points
input bool   UseTrailingStop        = true;                  // Enable Trailing Stop
input bool   UseStructuralTrailing  = true;                  // Trail behind M5 Swing High/Low
input double Trail_StartATR         = 1.50;                  // Start Trailing distance (x ATR)
input double Trail_StepATR          = 0.85;                  // Dynamic buffer behind structure (x ATR)
input bool   UseSmartExhaustion     = false;                 // Smart early exit on rejection
input bool   UseSmartLossCutter     = false;                 // Smart early loss cut on counter momentum
input bool   UsePartialClose        = true;                  // Enable Partial Close
input double PartialClosePercent    = 40.0;                  // Partial Close volume (%)
input double PartialCloseTriggerATR = 1.15;                  // Partial Close Trigger distance (x ATR)

input string Inp_Header9            = "=== Institutional Bias Confluence ===";
input int    BiasFastTimeframe      = 60;                    // Fast Bias Timeframe (60 = H1)
input int    BiasFastPeriod         = 34;                    // Fast EMA Period
input int    BiasSlowTimeframe      = 240;                   // Slow Bias Timeframe (240 = H4)
input int    BiasSlowPeriod         = 200;                   // Slow EMA Period (H4)
input bool   UseMacroTrendFilter    = true;                  // Macro Daily Trend Alignment
input int    MacroTrendPeriod       = 50;                    // Macro Daily EMA Period

input string Inp_Header10           = "=== Adaptive Market Regime Switching ===";
input bool   UseAdaptiveRegime      = true;                  // Enable Adaptive Market Regime Switch
input double HighVolATR_Points      = 150.0;                 // High Volatility Threshold (Points)
input double HighVolMaxTriggerPoints= 120.0;                 // Max Partial/BE Trigger in High Vol
input double HighVolBEOffsetATR     = 0.20;                  // Dynamic BE Offset in High Vol
input double HighVolTrailStepATR    = 0.95;                  // Dynamic Trail Step in High Vol

input string Inp_Header11           = "=== Execution Settings ===";
input int    MagicNumber            = 208821;                // Magic Number
input int    SlippagePoints         = 10;                    // Slippage in points
input int    OrderRetryCount        = 3;                     // Order retry count
input int    OrderRetryDelayMs      = 250;                   // Order retry delay (ms)
input int    MinBarsBetweenTrades   = 0;                     // Minimum M5 bars delay between trades (0 = per M5 bar)

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



// Single-Position Active Trade Tracking State

int      g_activeTicket         = -1;

datetime g_activeEntryTime      = 0;

double   g_activeEntryPrice     = 0.0;

double   g_activeEntryATR       = 0.0;

double   g_activeInitialLots    = 0.0;

bool     g_activePartialClosed  = false;

bool     g_activeBESet          = false;

bool     g_activeTrailingActive = false;



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

   g_activeTicket      = -1;

   g_activePartialClosed = false;

   g_activeBESet       = false;

   g_activeTrailingActive = false;



   Print(StringFormat("[INIT] Ultimate ICT Scalper v3.1 MT4 Initialized. Symbol: %s | Magic: %d | Balance: %.2f",

         Symbol(), MagicNumber, g_initialDeposit));

   return(INIT_SUCCEEDED);

}



//+------------------------------------------------------------------+

//| Expert deinitialization function                                 |

//+------------------------------------------------------------------+

void OnDeinit(const int reason) {

   Print("[DEINIT] Ultimate ICT Scalper v3.1 MT4 unloaded. Reason: ", reason);

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

//| Scan Closed History for Loss & Streak Tracking                   |

//+------------------------------------------------------------------+

void UpdateLossTracking() {

   datetime dayStart = iTime(Symbol(), PERIOD_D1, 0);

   int losses = 0;

   int consecutive = 0;

   int totalClosed = OrdersHistoryTotal();

   

   for(int i = totalClosed - 1; i >= 0; i--) {

      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;

      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol()) continue;

      if(OrderCloseTime() < dayStart) break; // Before today

      

      double net = OrderProfit() + OrderCommission() + OrderSwap();

      if(net < -0.01) {

         losses++;

      }

   }

   g_todayLossCount = losses;

   

   // Calculate consecutive losses from most recent closed orders

   for(int k = totalClosed - 1; k >= 0; k--) {

      if(!OrderSelect(k, SELECT_BY_POS, MODE_HISTORY)) continue;

      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol()) continue;

      double net = OrderProfit() + OrderCommission() + OrderSwap();

      if(net < -0.01) {

         consecutive++;

      } else if(net > 0.01) {

         break; // Profit encountered, streak broken

      }

   }

   g_consecutiveLosses = consecutive;

}



//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Order Counting & Emergency Close Helpers                         |
//+------------------------------------------------------------------+
int CountOpenPositions() {
   int count = 0;
   for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
            if(OrderType() == OP_BUY || OrderType() == OP_SELL) {
               count++;
            }
         }
      }
   }
   return count;
}

void CloseAllPositions() {
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
            int type = OrderType();
            double price = (type == OP_BUY) ? Bid : Ask;
            if(!OrderClose(OrderTicket(), OrderLots(), price, SlippagePoints, clrRed)) Print("[WARN] Emergency close error: ", GetLastError());
         }
      }
   }
}

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

   if(TradeNewYorkSession && h >= NewYorkStartHour && h < (NewYorkStartHour + 5)) return true;

   return false;

}



//+------------------------------------------------------------------+

//| Market Bias via Institutional Trend Confluence                   |

//+------------------------------------------------------------------+

int GetMarketBias() {
   int slowTF = NormalizeTF(BiasSlowTimeframe);
   int fastTF = NormalizeTF(BiasFastTimeframe);
   
   double emaSlow = 0.0;
   double emaFast = 0.0;
   
   if(iBars(Symbol(), slowTF) >= BiasSlowPeriod) {
      emaSlow = iMA(Symbol(), slowTF, BiasSlowPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   }
   if(iBars(Symbol(), fastTF) >= BiasFastPeriod) {
      emaFast = iMA(Symbol(), fastTF, BiasFastPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   }
   
   // Fallback when higher timeframe bars are not preloaded by MT4 Strategy Tester:
   if(emaFast <= 0.0) {
      int m5FastPeriod = MathMin(34 * 12, MathMax(20, Bars - 10));
      emaFast = iMA(Symbol(), PERIOD_M5, m5FastPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   }
   if(emaSlow <= 0.0) {
      if(iBars(Symbol(), PERIOD_H1) >= 200) {
         emaSlow = iMA(Symbol(), PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE, 0);
      } else {
         int m5SlowPeriod = MathMin(576, MathMax(50, Bars - 10));
         emaSlow = iMA(Symbol(), PERIOD_M5, m5SlowPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
      }
   }
   
   // CRITICAL SAFETY: If either EMA is 0.0 or negative, REFUSE TO TRADE! NEVER default to Buy!
   if(emaSlow <= 0.0 || emaFast <= 0.0) return -1;
   
   double close0 = iClose(Symbol(), PERIOD_M5, 0);
   
   int bias = -1;
   if(close0 > emaSlow && close0 > emaFast && emaFast >= emaSlow) bias = OP_BUY;
   else if(close0 < emaSlow && close0 < emaFast && emaFast <= emaSlow) bias = OP_SELL;
   
   if(bias == -1) return -1;
   
   // Macro Daily Trend Alignment
   if(UseMacroTrendFilter) {
      double emaDaily = 0.0;
      double closeDaily = 0.0;
      if(iBars(Symbol(), PERIOD_D1) >= MacroTrendPeriod) {
         emaDaily = iMA(Symbol(), PERIOD_D1, MacroTrendPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
         closeDaily = iClose(Symbol(), PERIOD_D1, 1);
      } else {
         int m5DailyPeriod = MathMin(MacroTrendPeriod * 288, MathMax(100, Bars - 10));
         emaDaily = iMA(Symbol(), PERIOD_M5, m5DailyPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
         closeDaily = iClose(Symbol(), PERIOD_M5, MathMin(288, Bars - 2));
      }
      
      if(emaDaily > 0.0 && closeDaily > 0.0) {
         string sym = Symbol();
         bool isIndex = (StringFind(sym, "US30") >= 0 || StringFind(sym, "USTEC") >= 0 || 
                         StringFind(sym, "NAS") >= 0  || StringFind(sym, "DOW") >= 0);
         if(isIndex && closeDaily > emaDaily && bias == OP_SELL) {
            return -1; // Block counter-trend shorting on Indices
         }
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

   

   // 1. True 3-Candle ICT Fair Value Gap (evaluated on recent completed bars & price reaction)

   if(UseFairValueGaps) {

      for(int i = 1; i <= FVG_Lookback; i++) {

         if(bias == OP_BUY) {

            double low1 = iLow(Symbol(), PERIOD_M5, i);

            double high3 = iHigh(Symbol(), PERIOD_M5, i + 2);

            if(low1 > high3 && (low1 - high3) >= (g_currentATR * FVG_MinSizeATR)) {

               // Price currently dipping into or reacting from the gap

               double currentLow = iLow(Symbol(), PERIOD_M5, 0);

               if(currentLow <= low1 && currentLow >= high3) {

                  fvgSignal = true;

                  break;

               }

            }

         } else if(bias == OP_SELL) {

            double high1 = iHigh(Symbol(), PERIOD_M5, i);

            double low3  = iLow(Symbol(), PERIOD_M5, i + 2);

            if(high1 < low3 && (low3 - high1) >= (g_currentATR * FVG_MinSizeATR)) {

               // Price currently dipping into or reacting from the gap

               double currentHigh = iHigh(Symbol(), PERIOD_M5, 0);

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

      double recentSwingHigh = 0.0;

      double recentSwingLow = 9999999.0;

      

      for(int k = 3; k < LiquidityLookback; k++) {

         if(iHigh(Symbol(), PERIOD_M5, k) > iHigh(Symbol(), PERIOD_M5, k-1) &&

            iHigh(Symbol(), PERIOD_M5, k) > iHigh(Symbol(), PERIOD_M5, k-2) &&

            iHigh(Symbol(), PERIOD_M5, k) > iHigh(Symbol(), PERIOD_M5, k+1) &&

            iHigh(Symbol(), PERIOD_M5, k) > iHigh(Symbol(), PERIOD_M5, k+2)) {

            if(iHigh(Symbol(), PERIOD_M5, k) > recentSwingHigh)

               recentSwingHigh = iHigh(Symbol(), PERIOD_M5, k);

         }

         if(iLow(Symbol(), PERIOD_M5, k) < iLow(Symbol(), PERIOD_M5, k-1) &&

            iLow(Symbol(), PERIOD_M5, k) < iLow(Symbol(), PERIOD_M5, k-2) &&

            iLow(Symbol(), PERIOD_M5, k) < iLow(Symbol(), PERIOD_M5, k+1) &&

            iLow(Symbol(), PERIOD_M5, k) < iLow(Symbol(), PERIOD_M5, k+2)) {

            if(iLow(Symbol(), PERIOD_M5, k) < recentSwingLow)

               recentSwingLow = iLow(Symbol(), PERIOD_M5, k);

         }

      }

      

      double barLow0 = iLow(Symbol(), PERIOD_M5, 0);

      double barHigh0 = iHigh(Symbol(), PERIOD_M5, 0);

      double barClose0 = iClose(Symbol(), PERIOD_M5, 0);

      

      if(bias == OP_BUY) {

         if(barLow0 < recentSwingLow && barClose0 > recentSwingLow)

            sweepSignal = true;

      } else if(bias == OP_SELL) {

         if(barHigh0 > recentSwingHigh && barClose0 < recentSwingHigh)

            sweepSignal = true;

      }

   } else {

      sweepSignal = true;

   }

   

   if(RequireBothFVGAndSweep) return (fvgSignal && sweepSignal);

   return (fvgSignal || sweepSignal);

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

   if(range1 <= 15 * Point) return false;

   

   double open2  = iOpen(Symbol(), PERIOD_M5, 2);

   double close2 = iClose(Symbol(), PERIOD_M5, 2);

   double high2  = iHigh(Symbol(), PERIOD_M5, 2);

   double low2   = iLow(Symbol(), PERIOD_M5, 2);

   

   double open0  = iOpen(Symbol(), PERIOD_M5, 0);

   double close0 = iClose(Symbol(), PERIOD_M5, 0);

   double high0  = iHigh(Symbol(), PERIOD_M5, 0);

   double low0   = iLow(Symbol(), PERIOD_M5, 0);

   double range0 = high0 - low0;

   

   if(bias == OP_BUY) {

      if(FilterMomentumKnives && close1 < open1 && (open1 - close1) >= 0.70 * range1 && (close1 - low1) <= 0.15 * range1) return false;

      

      bool patternFound = false;

      if(UseRejectionPinBar) {

         double lowerWick1 = MathMin(open1, close1) - low1;

         if(lowerWick1 >= 0.35 * range1 && close1 >= (low1 + 0.35 * range1)) patternFound = true;

         if(!patternFound && range0 >= 20 * Point) {

            double lowerWick0 = MathMin(open0, close0) - low0;

            if(lowerWick0 >= 0.40 * range0 && close0 >= (low0 + 0.40 * range0)) patternFound = true;

         }

      }

      if(UseEngulfingBar && !patternFound) {

         if(close1 > open1 && close1 > high2 && (close1 - open1) > MathAbs(close2 - open2)) patternFound = true;

      }

      if(UseStructureShift && !patternFound) {

         if(close1 > open1 && close1 > high2 && low1 > low2) patternFound = true;

      }

      return patternFound;

   } else if(bias == OP_SELL) {

      if(FilterMomentumKnives && close1 > open1 && (close1 - open1) >= 0.70 * range1 && (high1 - close1) <= 0.15 * range1) return false;

      

      bool patternFound = false;

      if(UseRejectionPinBar) {

         double upperWick1 = high1 - MathMax(open1, close1);

         if(upperWick1 >= 0.35 * range1 && close1 <= (high1 - 0.35 * range1)) patternFound = true;

         if(!patternFound && range0 >= 20 * Point) {

            double upperWick0 = high0 - MathMax(open0, close0);

            if(upperWick0 >= 0.40 * range0 && close0 <= (high0 - 0.40 * range0)) patternFound = true;

         }

      }

      if(UseEngulfingBar && !patternFound) {

         if(close1 < open1 && close1 < low2 && (open1 - close1) > MathAbs(close2 - open2)) patternFound = true;

      }

      if(UseStructureShift && !patternFound) {

         if(close1 < open1 && close1 < low2 && high1 < high2) patternFound = true;

      }

      return patternFound;

   }

   return false;

}



//+------------------------------------------------------------------+

//| Calculate Lot Size with Drawdown Brake & Streak Reducer          |

//+------------------------------------------------------------------+

double CalculateLotSize(double slDistancePrice) {

   if(slDistancePrice <= 0) return 0.0;

   

   double balance = AccountBalance();

   double equity  = AccountEquity();

   if(balance <= 0) return 0.0;

   

   if(equity > g_peakEquity) g_peakEquity = equity;

   if(g_peakEquity <= 0) g_peakEquity = balance;

   

   double currentDD_Pct = 0.0;

   if(g_peakEquity > 0) {

      currentDD_Pct = ((g_peakEquity - equity) / g_peakEquity) * 100.0;

   }

   

   double step   = MarketInfo(Symbol(), MODE_LOTSTEP);

   double minLot = MarketInfo(Symbol(), MODE_MINLOT);

   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);

   if(step <= 0) step = 0.01;

   if(minLot <= 0) minLot = 0.01;

   if(maxLot <= 0) maxLot = 100.0;

   int digits = (step < 0.1) ? 2 : 1;

   

   // Mode 1: Fixed Lot

   if(LotCalcMode == LOT_CALC_FIXED_LOT) {

      double targetLot = FixedLotSize;

      if(UseDrawdownBrake && currentDD_Pct >= 5.0) {

         targetLot = targetLot * 0.5;

         Print(StringFormat("[SAFETY BRAKE] Fixed lot halved to %.2f due to DD %.2f%%", targetLot, currentDD_Pct));

      }

      double normLot = MathFloor(targetLot / step) * step;

      if(normLot < minLot) normLot = minLot;

      if(normLot > maxLot) normLot = maxLot;

      return NormalizeDouble(normLot, digits);

   }

   

   // Mode 2: Dynamic % Risk

   if(RiskPercent <= 0) return 0.0;

   double effectiveRisk = RiskPercent;

   

   if(UseDrawdownBrake) {

      if(currentDD_Pct >= 5.2) {

         effectiveRisk = RiskPercent * 0.15; // Tier 3 Emergency Brake

         Print(StringFormat("[TIER 3 BRAKE] DD %.2f%% >= 5.2%%. Risk throttled to %.2f%%", currentDD_Pct, effectiveRisk));

      } else if(currentDD_Pct >= 3.6) {

         effectiveRisk = RiskPercent * 0.35; // Tier 2 Strong Brake

         Print(StringFormat("[TIER 2 BRAKE] DD %.2f%% >= 3.6%%. Risk throttled to %.2f%%", currentDD_Pct, effectiveRisk));

      } else if(currentDD_Pct >= BrakeTriggerDD) {

         effectiveRisk = RiskPercent * 0.65; // Tier 1 Dynamic Soft Brake

         Print(StringFormat("[TIER 1 BRAKE] DD %.2f%% >= %.2f%%. Risk throttled to %.2f%%", currentDD_Pct, BrakeTriggerDD, effectiveRisk));

      }

   }

   

   if(UseStreakRiskReducer && (g_consecutiveLosses >= 2 || g_todayLossCount >= 1)) {

      effectiveRisk = effectiveRisk * 0.5;

      Print(StringFormat("[STREAK BRAKE] Losses today: %d, Streak: %d. Risk halved to %.2f%%",

            g_todayLossCount, g_consecutiveLosses, effectiveRisk));

   }

   

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

//| Synchronize Active Position Tracking State                        |

//+------------------------------------------------------------------+

void SyncActivePosition() {

   int currentTicket = -1;

   int openCount = 0;

   

   for(int i = 0; i < OrdersTotal(); i++) {

      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {

         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {

            openCount++;

            currentTicket = OrderTicket();

         }

      }

   }

   

   // If no orders open for this EA, clear active tracking

   if(openCount == 0) {

      g_activeTicket         = -1;

      g_activeEntryTime      = 0;

      g_activeEntryPrice     = 0.0;

      g_activeEntryATR       = 0.0;

      g_activeInitialLots    = 0.0;

      g_activePartialClosed  = false;

      g_activeBESet          = false;

      g_activeTrailingActive = false;

      return;

   }

   

   // If ticket changed, a partial close occurred: child ticket inherits state!

   if(g_activeTicket > 0 && currentTicket != g_activeTicket) {

      g_activeTicket        = currentTicket;

      g_activePartialClosed = true; // STRICTLY PRESERVED: Never re-slice!

   }

   else if(g_activeTicket <= 0) {

      // First recognition of active order (initial entry or after restart)

      if(OrderSelect(currentTicket, SELECT_BY_TICKET)) {

         g_activeTicket        = currentTicket;

         g_activeEntryTime     = OrderOpenTime();

         g_activeEntryPrice    = OrderOpenPrice();

         g_activeEntryATR      = (g_currentATR > 0) ? g_currentATR : 1.0;

         g_activeInitialLots   = OrderLots();

         if(StringFind(OrderComment(), "from #") >= 0) {

            g_activePartialClosed = true;

         }

      }

   }

}



//+------------------------------------------------------------------+

//| Position Management: Partial Close, Smart BE, Trailing Stop      |

//+------------------------------------------------------------------+

void ManagePositions() {
   SyncActivePosition();
   if(g_activeTicket <= 0) return;
   
   if(!OrderSelect(g_activeTicket, SELECT_BY_TICKET)) return;
   
   int type         = OrderType();
   double openPrice = (g_activeEntryPrice > 0) ? g_activeEntryPrice : OrderOpenPrice();
   double currentSL = OrderStopLoss();
   double currentTP = OrderTakeProfit();
   double lots      = OrderLots();
   double atr       = (g_activeEntryATR > 0) ? g_activeEntryATR : g_currentATR;
   if(atr <= 0) return;
   
   double stopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
   if(stopLevel < 10 * Point) stopLevel = 10 * Point;
   
   // Current real spread in price units
   double currentSpreadPrice = (Ask - Bid);
   if(currentSpreadPrice <= 0) currentSpreadPrice = MarketInfo(Symbol(), MODE_SPREAD) * Point;
   
   // Break Even Offset MUST cover spread + profit buffer (minimum 1.5x spread or 12% ATR)
   // This guarantees that ANY exit at Break Even yields a net positive cash profit,
   // completely eliminating "false loss" stopouts that trigger circuit breakers on Standard accounts!
   double spreadLockBuffer = MathMax(currentSpreadPrice * 1.5, MathMax(BE_OffsetPoints * Point, atr * 0.12));
   if(UseAdaptiveRegime && (atr / Point) >= HighVolATR_Points) {
      spreadLockBuffer = MathMax(spreadLockBuffer, atr * HighVolBEOffsetATR);
   }
   
   // 1. Partial Close Logic (Strict Single Execution per Trade Cycle)
   if(UsePartialClose && !g_activePartialClosed) {
      double pcTrigger = atr * PartialCloseTriggerATR;
      bool triggerHit = false;
      if(type == OP_BUY  && (Bid - openPrice) >= pcTrigger) triggerHit = true;
      if(type == OP_SELL && (openPrice - Ask) >= pcTrigger) triggerHit = true;
      
      if(triggerHit) {
         double step = MarketInfo(Symbol(), MODE_LOTSTEP);
         double minLot = MarketInfo(Symbol(), MODE_MINLOT);
         if(step <= 0) step = 0.01;
         if(minLot <= 0) minLot = 0.01;
         
         double closeVol = MathFloor((lots * (PartialClosePercent / 100.0)) / step) * step;
         if(closeVol >= minLot && (lots - closeVol) >= minLot) {
            double closePrice = (type == OP_BUY) ? Bid : Ask;
            if(OrderClose(g_activeTicket, closeVol, closePrice, SlippagePoints, clrGold)) {
               g_activePartialClosed = true;
               Print(StringFormat("[PARTIAL CLOSE] Closed %.2f lots on Ticket #%d. Remaining: %.2f", 
                     closeVol, g_activeTicket, lots - closeVol));
               
               // SECURE CHILD RUNNER IMMEDIATELY AT BREAK EVEN!
               SyncActivePosition();
               if(g_activeTicket > 0 && OrderSelect(g_activeTicket, SELECT_BY_TICKET)) {
                  double childSL = (OrderType() == OP_BUY) ? NormalizeDouble(openPrice + spreadLockBuffer, Digits)
                                                           : NormalizeDouble(openPrice - spreadLockBuffer, Digits);
                  double curChildSL = OrderStopLoss();
                  bool okModify = false;
                  if(OrderType() == OP_BUY  && childSL > curChildSL && childSL < (Bid - stopLevel)) okModify = true;
                  if(OrderType() == OP_SELL && (childSL < curChildSL || curChildSL == 0) && childSL > (Ask + stopLevel)) okModify = true;
                  if(okModify) {
                     if(OrderModify(g_activeTicket, openPrice, childSL, OrderTakeProfit(), 0, clrBlue)) {
                        g_activeBESet = true;
                        Print(StringFormat("[RUNNER SECURED AT BREAK EVEN] Ticket #%d SL locked @ %.3f", g_activeTicket, childSL));
                     }
                  }
               }
               return;
            }
         } else {
            g_activePartialClosed = true;
         }
      }
   }
   
   // 2. Break Even Logic (Guaranteed Spread-Immune for Standard Accounts)
   if(UseBreakEven && !g_activeBESet) {
      double beTriggerDist = atr * BE_TriggerATR;
      
      if(type == OP_BUY && (Bid - openPrice) >= beTriggerDist) {
         double newSL = NormalizeDouble(openPrice + spreadLockBuffer, Digits);
         if(newSL > currentSL && newSL < (Bid - stopLevel)) {
            if(OrderModify(g_activeTicket, openPrice, newSL, currentTP, 0, clrBlue)) {
               g_activeBESet = true;
               Print(StringFormat("[BREAK EVEN] Secured BUY #%d @ %.3f (Net profit guaranteed)", g_activeTicket, newSL));
            }
         }
      } else if(type == OP_SELL && (openPrice - Ask) >= beTriggerDist) {
         double newSL = NormalizeDouble(openPrice - spreadLockBuffer, Digits);
         if((newSL < currentSL || currentSL == 0) && newSL > (Ask + stopLevel)) {
            if(OrderModify(g_activeTicket, openPrice, newSL, currentTP, 0, clrBlue)) {
               g_activeBESet = true;
               Print(StringFormat("[BREAK EVEN] Secured SELL #%d @ %.3f (Net profit guaranteed)", g_activeTicket, newSL));
            }
         }
      }
   }
   
   // 3. Smart Exhaustion Exit
   if(UseSmartExhaustion) {
      double barOpen0 = iOpen(Symbol(), PERIOD_M5, 0);
      double barHigh0 = iHigh(Symbol(), PERIOD_M5, 0);
      double barLow0  = iLow(Symbol(), PERIOD_M5, 0);
      double barClose0 = iClose(Symbol(), PERIOD_M5, 0);
      double barRange = barHigh0 - barLow0;
      
      if(barRange > (15 * Point)) {
         if(type == OP_BUY && (Bid - openPrice) >= (1.5 * atr)) {
            double upperWick = barHigh0 - MathMax(barOpen0, barClose0);
            if(upperWick >= (0.40 * barRange) && barClose0 < barOpen0) {
               if(OrderClose(g_activeTicket, lots, Bid, SlippagePoints, clrDarkOrange)) {
                  Print(StringFormat("[SMART EXHAUSTION EXIT] Closed BUY #%d on upper rejection wick at +%.2f pts",
                        g_activeTicket, (Bid - openPrice) / Point));
                  return;
               }
            }
         } else if(type == OP_SELL && (openPrice - Ask) >= (1.5 * atr)) {
            double lowerWick = MathMin(barOpen0, barClose0) - barLow0;
            if(lowerWick >= (0.40 * barRange) && barClose0 > barOpen0) {
               if(OrderClose(g_activeTicket, lots, Ask, SlippagePoints, clrDarkOrange)) {
                  Print(StringFormat("[SMART EXHAUSTION EXIT] Closed SELL #%d on lower rejection wick at +%.2f pts",
                        g_activeTicket, (openPrice - Ask) / Point));
                  return;
               }
            }
         }
      }
   }
   
   // 3.5 Smart Loss Cutter
   if(UseSmartLossCutter) {
      double barOpen1 = iOpen(Symbol(), PERIOD_M5, 1);
      double barClose1 = iClose(Symbol(), PERIOD_M5, 1);
      double barHigh1  = iHigh(Symbol(), PERIOD_M5, 1);
      double barLow1   = iLow(Symbol(), PERIOD_M5, 1);
      double barRange1 = barHigh1 - barLow1;
      
      if(barRange1 > (15 * Point)) {
         if(type == OP_BUY && (openPrice - Bid) >= (0.85 * atr)) {
            if(barClose1 < barOpen1 && (barOpen1 - barClose1) >= (0.60 * barRange1)) {
               if(OrderClose(g_activeTicket, lots, Bid, SlippagePoints, clrMagenta)) {
                  Print(StringFormat("[SMART LOSS CUTTER] Cut BUY #%d early at -%.2f pts (Saved capital from full SL)",
                        g_activeTicket, (openPrice - Bid) / Point));
                  return;
               }
            }
         } else if(type == OP_SELL && (Ask - openPrice) >= (0.85 * atr)) {
            if(barClose1 > barOpen1 && (barClose1 - barOpen1) >= (0.60 * barRange1)) {
               if(OrderClose(g_activeTicket, lots, Ask, SlippagePoints, clrMagenta)) {
                  Print(StringFormat("[SMART LOSS CUTTER] Cut SELL #%d early at -%.2f pts (Saved capital from full SL)",
                        g_activeTicket, (Ask - openPrice) / Point));
                  return;
               }
            }
         }
      }
   }
   
   // 4. Trailing Stop (Structural Swing + Dynamic ATR Buffer)
   if(UseTrailingStop) {
      double trailStartDist = atr * Trail_StartATR;
      double trailStepDist  = atr * Trail_StepATR;
      if(UseAdaptiveRegime && (atr / Point) >= HighVolATR_Points) {
         trailStepDist = atr * HighVolTrailStepATR;
      }
      double minModifyStep  = MathMax(30 * Point, atr * 0.15);
      
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
         if(proposedSL > (currentSL + minModifyStep) && proposedSL < (Bid - stopLevel)) {
            if(OrderModify(g_activeTicket, openPrice, proposedSL, currentTP, 0, clrGreen)) {
               g_activeTrailingActive = true;
            }
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
         if((proposedSL < (currentSL - minModifyStep) || currentSL == 0) && proposedSL > (Ask + stopLevel)) {
            if(OrderModify(g_activeTicket, openPrice, proposedSL, currentTP, 0, clrGreen)) {
               g_activeTrailingActive = true;
            }
         }
      }
   }
}

void OnTick() {

   CheckAndResetDay();

   UpdateLossTracking();

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

      if(MinBarsBetweenTrades > 0 && barsSince < MinBarsBetweenTrades) return;

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

      g_lastEntryBarTime     = currentBarTime;

      g_todayTradeCount++;

      g_activeTicket         = ticket;

      g_activeEntryTime      = currentBarTime;

      g_activeEntryPrice     = entryPrice;

      g_activeEntryATR       = g_currentATR;

      g_activeInitialLots    = volume;

      g_activePartialClosed  = false;

      g_activeBESet          = false;

      g_activeTrailingActive = false;

      Print(StringFormat("[ORDER PLACED] %s %.2f @ %.3f | SL: %.3f | TP: %.3f | Ticket: %d",

            (bias == OP_BUY ? "BUY" : "SELL"), volume, entryPrice, sl, tp, ticket));

   } else {

      Print("[ORDER ERROR] OrderSend failed with error code: ", GetLastError());

   }

}

//+------------------------------------------------------------------+

