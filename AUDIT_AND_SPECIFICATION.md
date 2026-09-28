# Comprehensive Technical Audit & Specification Document
**Project:** Price Action Trading System (MetaTrader 5)  
**Author:** Quantitative Systems Engineering Audit  
**Date:** September 2026  
**Primary Source of Truth:** 97-Page "Price Action Trading" Course (Nial Fuller)

---

## 1. Executive Summary & Audit Scope

This document provides a thorough, rigorous technical audit of the codebase (`PriceAction_Pro_MT5.mq5`, `PriceAction_Signals.mq5`, and documentation) against the 97-page Price Action Trading reference material.

The primary finding of this audit is that while the initial implementation captured the basic candle geometry of Pin Bars and Inside Bars, it suffered from:
1. **Critical Strategy Deviations:** The original Price Action framework (which relies strictly on Naked Price Action, Confirmed Swing Market Structure, Horizontal Reaction Levels, and Level Flips) was replaced with modern institutional indicators (EMA trend, RSI, Volume Spread Analysis, HTF Order Blocks, and Fair Value Gaps).
2. **Critical Mathematical & Algorithmic Bugs:**
   - Position Management Bug: Recalculating initial risk from `currentSL` after Break-Even or Trailing Stop was triggered, resulting in immediate collapse of the risk distance.
   - Sizing Fallback Bug: Silently falling back to `FixedLot` when risk calculations encountered edge cases.
   - Execution Price Discrepancy: Calculating stop loss distances from candle closes instead of the actual execution prices (`Ask` / `Bid`).
   - Indicator Indexing & Alert Spam: Triggering live popup alerts during historical backfill loops and mishandling series direction.
   - Missing OCO (One-Cancels-the-Other) on dual Inside Bar breakout orders.
   - Missing Broker Stop Level / Freeze Level validation.

Below is the detailed point-by-point audit across all requested engineering areas.

---

## 2. Comprehensive Codebase Audit (Section-by-Section)

### A. Market Structure Detection
* **Previous Status:** Non-existent. The EA completely lacked swing detection and market structure tracking.
* **Audit Finding:** The PDF (Pages 10–16, 25–34) defines market structure as the sequence of successive waves with peaks and troughs:
  - **Uptrend:** Higher Highs (HH) and Higher Lows (HL).
  - **Downtrend:** Lower Highs (LH) and Lower Lows (LL).
  - **Range:** Horizontal peaks and troughs without clear directional progression.
* **Fix Implemented:** A non-repainting pivot swing algorithm ($N$-bars left, $N$-bars right). A swing high at bar $k$ is confirmed only when bar $k+N$ closes. The sequence of confirmed swing highs and lows is tracked deterministically to establish true market structure.

### B. Trend Detection
* **Previous Status:** Used an EMA crossover (`fastEma > slowEma`).
* **Audit Finding:** The PDF explicitly rejects indicators on Pages 3–9 ("Price action uses dynamic S/R, trend momentum... no lagging indicators or cloudy charts"). Using EMA crossover violates the foundational premise in `BOOK_EXACT` mode.
* **Fix Implemented:** In `BOOK_EXACT`, trend is determined strictly by the state of confirmed swings:
  - Uptrend = Most recent swing high > previous swing high AND most recent swing low > previous swing low.
  - Downtrend = Most recent swing high < previous swing high AND most recent swing low < previous swing low.
  - Range = Mixed or horizontal swing relationships.
  In `ENHANCED` mode, EMA filtering is preserved as an optional layer.

### C. Support & Resistance Detection & Level Flips
* **Previous Status:** No horizontal support and resistance was calculated. Replaced entirely by Order Blocks in v2.0.
* **Audit Finding:** Pages 17–34 define horizontal levels as reaction highs (peaks = resistance/supply) and reaction lows (troughs = support/demand). Pages 25–28 explicitly define level flips ("Previous Resistance becomes Support" and "Previous Support becomes Resistance").
* **Fix Implemented:** A clustering algorithm groups confirmed swing points within a configurable price band (`InpSRZonePips`). Zones with at least `InpSRMinTouches` touches are registered as Key Levels. If price closes above a resistance zone, the zone is flipped to a support zone; if price closes below a support zone, it is flipped to resistance.

### D. 50% Retracement Logic Separation
* **Previous Status:** Conflated swing retracement with Pin Bar limit entry.
* **Audit Finding:** The PDF presents two distinct 50% concepts:
  1. **50% Swing Retracement (Page 61, 66):** Midpoint of a major impulse swing:
     $$\text{Mid}_{\text{swing}} = \frac{\text{Swing High} + \text{Swing Low}}{2}$$
     Serves as a confluence factor when price pulls back to this area.
  2. **50% Pin Bar Limit Entry (Page 62):** Placing a limit order at the exact midpoint of the Pin Bar itself:
     $$\text{Entry}_{\text{limit}} = \text{Low}_{\text{pin}} + 0.5 \times (\text{High}_{\text{pin}} - \text{Low}_{\text{pin}})$$
* **Fix Implemented:** Explicitly separated into two distinct components:
  - Confluence: Checks if the signal candle tests the 50% retracement of the dominant impulse wave.
  - Execution: Places `Buy Limit` or `Sell Limit` at 50% of the Pin Bar range.

### E. Pin Bar Detection & Entry Logic
* **Previous Status:** Implemented basic wick ratios, but lacked contextual validation (traded naked anywhere).
* **Audit Finding:** Pages 53–63 define Pin Bar geometry:
  - Total Range = $\text{High} - \text{Low}$
  - Body = $|\text{Close} - \text{Open}| \le \frac{1}{3} \text{Range}$
  - Tail $\ge \frac{2}{3} \text{Range}$
  - Tail must protrude from surrounding price bars.
  - Crucial Rule (Page 61): "Try to only take pin bars that are displaying confluence with another factor (trend, strong support/resistance, 50% retrace)".
* **Fix Implemented:** Strict 2/3 and 1/3 ratio checks, protrusion lookback, and mandatory confluence verification before an order can be emitted in `BOOK_EXACT`.

### F. Inside Bar Detection & Multiple Inside Bars (Coiling)
* **Previous Status:** Checked only 1 inside bar and immediately placed dual breakout stop orders.
* **Audit Finding:** Pages 71–86 allow multiple inside bars ("coiling inside bars", Page 73, 84). Also, Page 76 & 81 distinguish between **Inside Bar Continuation** (with trend) and **Inside Bar Reversal** (at key S/R levels).
* **Fix Implemented:** 
  - Iterative scanning of up to `InpIBMaxNesting` consecutive bars contained within the original Mother Bar range.
  - Separate toggles for Continuation vs Reversal setups.
  - Breakout Stop orders placed at Mother Bar High + buffer (Buy Stop) and Mother Bar Low - buffer (Sell Stop).

### G. Fakey Detection & Obvious False Break Threshold
* **Previous Status:** Triggered if a candle simply penetrated the Inside Bar low/high by even 1 fractional pip.
* **Audit Finding:** Pages 87–97, especially Page 96: "The KEY defining characteristic of a good fakey signal is a CLEAR false break... dead obvious and won't require a lot of deciphering."
* **Fix Implemented:** Added `InpFakeyMinBreakPoints` (or ATR fraction) requiring the false-break bar to penetrate beyond the Inside Bar/Mother Bar structure by a verifiable, minimum distance before closing back inside. Supported single-bar Pin Bar false breaks and two-bar reversal false breaks.

### H. Risk Management, Position Sizing, & Break-Even Bug Fix
* **Previous Status:** 
  1. Recalculated `initialRiskPips = MathAbs(openPrice - currentSL)` on every tick. When Break-Even moved `currentSL` to `openPrice`, `initialRiskPips` collapsed to 0 or 1 point, corrupting trailing stop triggers.
  2. Fallback to `FixedLot` when risk calculation failed.
  3. Calculated risk from `rates[1].close` rather than `Ask` / `Bid`.
* **Fix Implemented:**
  1. **Persistent Position Tracking:** Created a struct `SPositionTracker` storing `ticket`, `initialEntryPrice`, `initialSLPrice`, `initialRiskPoints`. Once set at trade creation, `initialRiskPoints` is immutable.
  2. **Strict Risk Sizing:** Calculates lot size using `Ask` for Buys, `Bid` for Sells, considering `SYMBOL_TRADE_TICK_SIZE` and `SYMBOL_TRADE_TICK_VALUE`. If calculation fails or if minimum lot exceeds requested risk, the trade is rejected with a full diagnostic log. No silent fallback to `FixedLot`.
  3. **Break-Even & Trailing:** Break-Even triggers when current profit $\ge \text{initialRiskPoints} \times \text{InpBreakEvenTriggerRR}$. Trailing Stop triggers at $\text{InpTrailingStartRR}$ and maintains a distance of $\text{InpTrailingDistanceRR} \times \text{initialRiskPoints}$.

### I. Broker Constraints & Order Placement Validation
* **Previous Status:** No validation for stop levels, freeze levels, or spread limits.
* **Audit Finding:** In live and real-tick backtesting, placing pending orders or SL/TP closer than `SYMBOL_TRADE_STOPS_LEVEL` results in broker rejection error `10016 (TRADE_RETCODE_INVALID_STOPS)`.
* **Fix Implemented:** Added pre-trade validation checking:
  - Spread $\le$ `InpMaxSpreadPoints`
  - Distance from market $\ge$ `SYMBOL_TRADE_STOPS_LEVEL`
  - Order retcode verification (`TRADE_RETCODE_DONE` or `TRADE_RETCODE_PLACED`). If rejected, full diagnostic details are logged and chart markers are withheld.

### J. One-Cancels-the-Other (OCO) Engine
* **Previous Status:** If an Inside Bar created both Buy Stop and Sell Stop orders, filling one left the other active indefinitely.
* **Audit Finding:** When trading an Inside Bar breakout, the trader commits to the direction of the break. Leaving the opposite pending order active results in accidental double execution or unintended counter-trades.
* **Fix Implemented:** An OCO tracking system pairs the orders using trade comments/magic numbers. On every tick, if one side of the pair transitions into an active position, the opposite pending order is instantly canceled.

### K. No-Repainting & HTF Candle Synchronization
* **Previous Status:** In v2.0, HTF POI scanning copied HTF rates without explicitly skipping forming candle 0, risking forward-looking leakage.
* **Audit Finding:** A historical signal must only use completed information.
* **Fix Implemented:**
  - EA executes logic strictly on `IsNewBar()`.
  - HTF data copying strictly offsets to completed closed bars (`shift >= 1`).
  - Swings require $N$ closed candles to the right before being confirmed and timestamped.
  - Zero repainting guaranteed for both "Open prices only" and "Every tick based on real ticks".

### L. Indicator (`PriceAction_Signals.mq5`) Audit & Fixes
* **Previous Status:**
  - Alert function called inside historical calculation loop, spamming alerts on chart load.
  - Inconsistent index direction between buffers and rate arrays.
* **Fix Implemented:**
  - Set buffers and arrays to matching series orientation.
  - Alerts restricted strictly to bar index 1 on the arrival of a new bar (`time[1] > g_lastAlertTime`).
  - Added visual markers for confirmed Swings, S/R zones, Pin Bars, Inside Bars, and Fakeys.

---

## 3. Clear Strategy Separation: Mode A vs Mode B

```
+-------------------------------------------------------------------------------+
|                             STRATEGY MODE SELECTOR                            |
|                          InpStrategyMode (Enum)                               |
+---------------------------------------+---------------------------------------+
|        MODE A: BOOK_EXACT             |           MODE B: ENHANCED            |
+---------------------------------------+---------------------------------------+
| 1. Pure Market Structure (HH/HL/LH/LL)| 1. Market Structure + Optional EMA    |
| 2. Horizontal S/R Reaction Levels    | 2. Horizontal S/R + HTF Order Blocks  |
| 3. Dynamic Level Flips (S->R, R->S)   | 3. Fair Value Gaps (FVG / Imbalance)  |
| 4. 50% Swing Retracement Confluence   | 4. Volume Spread Analysis (VSA Climax)|
| 5. Pin Bar (Market or 50% Limit Entry)| 5. Low-Volume Tests (No Supply/Demand)|
| 6. Inside Bar Breakout (Single/Coil)  | 6. RSI Momentum / Extremes Filter     |
| 7. Fakey Reversals (Clear False Break)| 7. All Book Setups layered with above |
| 8. Strict Risk, SL, BE, Trailing      | 8. Strict Risk, SL, BE, Trailing      |
|                                       |                                       |
| * EMA: FORCED OFF                     | * All indicators & POIs are optional  |
| * RSI: FORCED OFF                     |   and toggleable individually.        |
| * VSA: FORCED OFF                     |                                       |
| * Order Blocks / FVG: FORCED OFF      |                                       |
+---------------------------------------+---------------------------------------+
```

---

## 4. Technical Answers to Verification Questions (A through J)

### A. What Was Wrong
1. Trend was defined solely by EMA, which directly contradicted the book's core premise of naked price action and swing structure.
2. Horizontal S/R was absent; the code traded in mid-air or relied on SMC concepts not in the book.
3. Conflation of 50% swing retracement with 50% pin bar limit entry.
4. Severe Break-Even bug resetting `initialRiskPips` to 1 point upon moving SL.
5. Sizing algorithm silently reverted to `FixedLot` when risk calculations failed.
6. Execution price discrepancy: SL pips calculated from `close` instead of `Ask`/`Bid`.
7. Inside Bar lacked multi-bar coiling and lacked OCO cancellation of the opposite order upon fill.
8. Fakey lacked a minimum false break distance filter.
9. Indicator triggered alerts during historical loops on initialization.
10. Broker stop level and freeze level checks were omitted.

### B. What Was Fixed
1. Implemented a non-repainting pivot swing model (HH/HL/LH/LL) for trend detection in `BOOK_EXACT`.
2. Implemented reaction-based horizontal S/R zone clustering and level flip tracking.
3. Separated 50% swing retracement confluence from 50% pin bar entry.
4. Built persistent position risk tracking preserving original risk across Break-Even and Trailing Stop.
5. Strict risk sizing: rejects trades if risk exceeds threshold or calculation fails; no silent fallback.
6. Exact `Ask`/`Bid` and pending price calculations.
7. Full Inside Bar coiling support and automated OCO pending order cancellation.
8. Minimum false-break threshold for Fakey setups.
9. Indicator alerts restricted strictly to confirmed closed candles on live ticks.
10. Added pre-trade spread, stop-level, and freeze-level validation.

### C. What Is Directly Supported by the PDF
- Pin Bar geometry: $\ge 2/3$ tail, $\le 1/3$ body, protrusion beyond adjacent bars (Pages 53–63).
- 50% Pin Bar limit entry with stop loss at the tail extreme (Page 62).
- Inside Bar: fully contained in Mother Bar range, breakout entry via Buy Stop / Sell Stop (Pages 71–86).
- Multiple inside bars ("coiling", Page 73, 84).
- Fakey: false breakout of an inside bar structure snapping back (Pages 87–97).
- Trend defined as ascending/descending peaks and troughs (HH/HL and LH/LL, Pages 10–16).
- Support/Resistance as reaction lows and peaks, and level flips (Pages 17–28).
- Confluence factors (T.T.L.F: Trend, Level, Signal, 50% retrace, Pages 64–70).

### D. What Is Implementation-Specific (Assumptions for Automation)
- Pivot swing lookback ($N$ left, $N$ right bars, default $N=3$): The book visually identifies peaks and troughs without giving a numerical lookback.
- S/R clustering tolerance (`InpSRZonePips` or ATR fraction): The book draws horizontal bands; clustering requires an explicit width.
- Minimum false break threshold (`InpFakeyMinBreakPoints`): The book states the false break must be "clear and obvious", which requires a quantifiable point/ATR threshold.
- Fixed Take Profit multiples ($1:2$, $1:2.5$, $1:3$): The book discusses targeting the next resistance or swing point, but does not prescribe a universal mathematical formula.

### E. What Is Enhanced-Only
- Exponential Moving Averages (EMA 21, EMA 50, EMA 200).
- Relative Strength Index (RSI 14).
- Volume Spread Analysis (Stopping Volume, Climactic Volume, Low-Volume Test).
- Multi-Timeframe Order Blocks (Bullish/Bearish Demand/Supply Zones).
- Fair Value Gaps (FVG) and Imbalance filters.

### F. Remaining Limitations
- Tick volume in Spot Forex reflects broker tick activity, not centralized exchange volume (relevant only for Enhanced VSA mode).
- On small timeframes (M1), spread and execution slippage represent a higher proportion of trade distance.
- Complex subjective chart patterns shown in the PDF (e.g., discretionary double tops spanning weeks) are approximated algorithmically through swing pairs.

### G. Backtest Methodology
- **Platform:** MetaTrader 5 Strategy Tester.
- **Model:** "Every tick based on real ticks" for realistic limit/stop execution and slippage modeling.
- **Verification Model:** "Open prices only" can be used for initial screening because signal logic evaluates strictly on bar close (`IsNewBar`).
- **Instruments:** EURUSD, GBPUSD, XAUUSD.
- **Timeframes:** H1, H4, D1 (recommended by the book on Pages 63 and 83).

### H. Known Assumptions
- Confirmed swings require $N$ closed bars to the right before being recognized. Signals never backdate to the unconfirmed candle.
- Pending orders expire after a configurable number of bars if not filled.
- Slippage and commission are accounted for via configurable buffers.

### I. No-Repainting Verification
- All pattern evaluations are executed on shift index 1 (the just-closed bar) inside an `IsNewBar()` gate.
- Shift 0 (the live forming candle) is NEVER used for pattern classification or swing confirmation.
- HTF scanning uses completed historical candles only (`shift >= 1`).

### J. Risk-Management Verification
- Risk percentage calculation:
  $$\text{Lots} = \frac{\text{Account Balance} \times \text{Risk}\%}{\text{SL Distance in Points} \times \frac{\text{Tick Value}}{\text{Tick Size} / \text{Point}}}$$
- Normalized to broker volume step and clamped to min/max.
- If the normalized lot size results in a monetary risk exceeding $\text{Risk}\% \times 1.25$, the trade is safely aborted.
