# SCALPING_STRATEGY_SPEC.md
# Technical Specification: Scalping Trend-Momentum Strategy Mode
**Mode Identifier:** `MODE_SCALPING_TREND_MOMENTUM`  
**System Version:** 5.00  
**Target Platform:** MetaTrader 5 (MQL5)  
**Execution Timeframe:** M5 (Default) / M1 (Optional Experimental)  
**Context Timeframe:** M15 (Default) / M5 (For M1 execution)  
**Conceptual Lineage:** Al Brooks (H2 / L2 Price Action), Mack PATs (Second Entry), Bob Volman (Second Break / Trend Pullback)

---

## 1. Executive Summary & Strategy Philosophy

`MODE_SCALPING_TREND_MOMENTUM` is a dedicated, higher-frequency intraday price-action trading mode engineered to operate completely independently from the original daily/swing `MODE_BOOK_EXACT`. 

### The Core Premise:
In trending markets, counter-trend participants attempt to initiate a correction or reversal. The first counter-trend resumption attempt (High 1 or Low 1) frequently fails because the dominant trend momentum remains intact. When this first attempt fails and a second continuation attempt triggers (High 2 or Low 2 / Second Break), trapped counter-trend traders are forced to cover their positions, providing explosive directional fuel for rapid trend continuation.

```
[Trend Established: HH+HL or LH+LL]
          │
          ▼
   [Orderly Pullback]
          │
          ▼
[First Counter-Trend Attempt: H1 / L1]
          │
          ▼
     [H1/L1 Fails]
          │
          ▼
[Second Continuation Attempt: H2 / L2 / Second Break]
          │
          ▼
 [Price Action Confirmation Bar]
          │
          ▼
      [Entry] ───► [Dynamic Position Management] ───► [Dynamic Exit: Trailing / Structural / Reversal]
```

### Strict Non-Negotiable Constraint:
`MODE_BOOK_EXACT` must remain 100% untouched, intact, and reproducible. All scalping logic, variables, and handlers are isolated in dedicated modules and activated only when `InpStrategyMode == MODE_SCALPING_TREND_MOMENTUM`.

---

## 2. Priority Hierarchy (Anti-"Indicator Soup")

To preserve institutional-grade price-action purity, decisions are governed by a strict hierarchy:

| Priority | Dimension | Core Metric / Evaluation Engine |
|:---:|:---|:---|
| **1** | **Market Structure** | Confirmed micro-pivots (HH+HL or LH+LL), structural invalidation levels. |
| **2** | **Trend Momentum** | Directional impulse size, structural separation, EMA20 slope context. |
| **3** | **Pullback Containment** | Orderly retracement (2 to 8 bars) contained above/below invalidation level. |
| **4** | **H2 / L2 State Machine** | Explicit finite state transitions tracking failure of Attempt 1 and formation of Attempt 2. |
| **5** | **Price Action Confirmation** | Signal bar closing geometry (top/bottom 33%, rejection wick). |
| **6** | **Support / Resistance** | Room to nearest opposing confirmed level ($\ge 1.0R$). |
| **7** | **Volume Behavior** | Secondary layer: contracting volume during pullback, expanding trigger volume. |
| **8** | **Execution & Risk** | Strict risk lot sizing, spread filter, session hours, stops/freeze levels. |

---

## 3. Finite State Machine (FSM) Specification

The scalping engine is modeled as an explicit, deterministic Finite State Machine (`ENUM_SCALP_STATE`):

```
                     ┌──────────────────┐
                     │ SCALP_STATE_IDLE │
                     └────────┬─────────┘
                              │ Trend Confirmed (HH+HL / LH+LL)
                              ▼
                ┌────────────────────────────┐
                │ SCALP_STATE_TREND_DETECTED │
                └─────────────┬──────────────┘
                              │ Orderly Pullback Commences (>= 2 bars)
                              ▼
                  ┌──────────────────────┐
                  │ SCALP_STATE_PULLBACK │
                  └───────────┬──────────┘
                              │ First Attempt (H1 / L1) Triggers
                              ▼
               ┌───────────────────────────┐
               │ SCALP_STATE_FIRST_ATTEMPT │
               └──────────────┬────────────┘
                              │ Attempt Fails (New pullback extreme)
                              ▼
            ┌──────────────────────────────────┐
            │ SCALP_STATE_FIRST_ATTEMPT_FAILED │
            └─────────────────┬────────────────┘
                              │ Second Setup Forms (H2 / L2 candle)
                              ▼
             ┌────────────────────────────────┐
             │ SCALP_STATE_SECOND_ENTRY_READY │
             └────────────────┬───────────────┘
                              │ Breakout Buffer Crossed + Signal Confirmation
                              ▼
                 ┌───────────────────────┐
                 │ SCALP_STATE_TRIGGERED │
                 └────────────┬──────────┘
                              │ Order Sent & Filled (retcode=10009)
                              ▼
               ┌─────────────────────────┐
               │ SCALP_STATE_IN_POSITION │
               └──────────────┬──────────┘
                              │ Dynamic Management & Exit Rules
                              ▼
              ┌─────────────────────────────┐
              │ SCALP_STATE_EXIT_MANAGEMENT │
              └─────────────────────────────┘
```

### State Transition & Invalidation Conditions:
1. **`SCALP_STATE_IDLE` $\rightarrow$ `SCALP_STATE_TREND_DETECTED`:**
   - **Bullish:** Latest confirmed micro swing high > previous confirmed swing high (HH) AND latest confirmed micro swing low > previous confirmed swing low (HL). If `InpScalpUseEmaContext`, closed bar 1 close > EMA20 and EMA20 slope $\ge 0$.
   - **Bearish:** Latest confirmed micro swing high < previous confirmed swing high (LH) AND latest confirmed micro swing low < previous confirmed swing low (LL). If `InpScalpUseEmaContext`, closed bar 1 close < EMA20 and EMA20 slope $\le 0$.
   - **Range:** Mixed pivots $\rightarrow$ stay `IDLE`.

2. **`SCALP_STATE_TREND_DETECTED` $\rightarrow$ `SCALP_STATE_PULLBACK`:**
   - Price retreats counter-trend from the impulse extreme for at least `InpScalpMinPullbackBars` (default: 2 bars).
   - Invalidation check: If price crosses the structural invalidation level (the prior HL for bulls or prior LH for bears) $\rightarrow$ state transitions to `SCALP_STATE_INVALIDATED`.

3. **`SCALP_STATE_PULLBACK` $\rightarrow$ `SCALP_STATE_FIRST_ATTEMPT` (H1 / L1):**
   - **Bullish (H1):** Candle high exceeds the high of the prior candle (`rates[i].high > rates[i+1].high`). First attempt to resume trend.
   - **Bearish (L1):** Candle low drops below the low of the prior candle (`rates[i].low < rates[i+1].low`). First attempt to resume trend.

4. **`SCALP_STATE_FIRST_ATTEMPT` $\rightarrow$ `SCALP_STATE_FIRST_ATTEMPT_FAILED`:**
   - **Bullish Failure:** H1 fails to make a new impulse high; sellers push price back down, making a new lower low within the pullback (`low < H1_bar.low`).
   - **Bearish Failure:** L1 fails to make a new impulse low; buyers push price back up, making a new higher high within the pullback (`high > L1_bar.high`).

5. **`SCALP_STATE_FIRST_ATTEMPT_FAILED` $\rightarrow$ `SCALP_STATE_SECOND_ENTRY_READY` (H2 / L2):**
   - **Bullish (H2):** While remaining above structural invalidation, buyers form a second attempt to turn price upward (second bar exceeding prior bar high, or bullish rejection at pullback base).
   - **Bearish (L2):** While remaining below structural invalidation, sellers form a second attempt to turn price downward.

6. **`SCALP_STATE_SECOND_ENTRY_READY` $\rightarrow$ `SCALP_STATE_TRIGGERED`:**
   - Second Break confirmation: Price crosses the trigger level by at least `InpScalpBreakBufferPoints` (e.g. 10 points on 5-digit broker).
   - Signal bar closing geometry: Top 33% close for Buy, Bottom 33% close for Sell.
   - S/R proximity: Minimum distance to next opposing major S/R $\ge 1.0R$.
   - Volume filter (if enabled): Pullback volume < Impulse volume.

---

## 4. Timeframe & Micro Market-Structure Architecture

1. **Timeframe Roles:**
   - **Execution Timeframe (`InpScalpExecutionTF`, default M5):** Where micro-structure, pullbacks, H2/L2 candle triggers, entries, and trailing stops are executed.
   - **Context Timeframe (`InpScalpContextTF`, default M15):** Where higher-timeframe trend alignment, major swing pivots, and overarching S/R levels are measured.
   - **Strict Zero Look-Ahead:** All calculations evaluate closed bars exclusively (`shift >= 1`). Bar 0 is never used for signal generation.

2. **Micro-Pivot Detection Engine:**
   - A Pivot High at bar `k` requires `InpScalpPivotStrength` (default: 2) closed bars to the left with lower highs, and `InpScalpPivotStrength` closed bars to the right with lower highs.
   - When evaluating at the close of Bar 1:
     $$\text{Candidate Pivot Shift} = 1 + \text{InpScalpPivotStrength}$$
   - This guarantees that no future bar is ever inspected. The pivot is immutable and will never repaint.

---

## 5. Stop Loss & Position Sizing Engine

1. **Structural Stop Loss:**
   - **Buy Orders:** Placed below the lowest low of the entire pullback sequence (or below the signal bar low), minus a configurable buffer (`InpStopLossBufferPips`).
   - **Sell Orders:** Placed above the highest high of the entire pullback sequence (or above the signal bar high), plus a configurable buffer (`InpStopLossBufferPips`).

2. **Strict Risk Calculation:**
   $$\text{Risk Points} = \frac{|\text{EntryPrice} - \text{StopLossPrice}|}{\text{Point}}$$
   $$\text{Risk Per Lot} = \left(\frac{\text{Risk Points} \times \text{Point}}{\text{Tick Size}}\right) \times \text{Tick Value}$$
   $$\text{Target Monetary Risk} = \text{Account Balance} \times \left(\frac{\text{InpRiskPercent}}{100.0}\right)$$
   $$\text{Raw Lots} = \frac{\text{Target Monetary Risk}}{\text{Risk Per Lot}}$$
   - Normalized strictly to broker `LOT_STEP`, `LOT_MIN`, and `LOT_MAX`.
   - If resulting risk exceeds `InpMaxRiskPercentCap`, the trade is **REJECTED** (`[SCALP REJECT] Risk sizing invalid`). No fallback to arbitrary lots.

---

## 6. Dynamic Exit Engine (No Mechanical RR Mandate)

Rather than enforcing an arbitrary universal $2.5R$ target on fast M5 scalping trades, `MODE_SCALPING_TREND_MOMENTUM` implements an event-driven dynamic exit engine:

| Exit Rule ID | Trigger Condition | Rationale | Action |
|:---|:---|:---|:---|
| **EXIT-BE** | Profit reaches $+1.0R$ | Lock capital protection | Move SL to Entry + `InpScalpBreakEvenLockPips` (`retcode=10009`) |
| **EXIT-OPP-PA** | Strong opposite reversal candle (Engulfing / Pin) | Counter-trend momentum returning | Close position immediately at market |
| **EXIT-STRUCT** | Prior micro swing low (buys) or high (sells) broken | Market structure invalidated | Close position immediately at market |
| **EXIT-STALL** | Position in profit $\ge 0.5R$ but fails to make new extreme for $N$ bars | Momentum exhausted / consolidation trap | Close position at market to preserve gains |
| **EXIT-SR-WALL**| Price reaches within 3 pips of major opposing S/R | Strong barrier risk | Take profit at market |
| **EXIT-TRAILING**| Bar-by-bar trailing after $+1.0R$ | Trend ride with tight lock | SL trailed behind prior closed bar low/high |
| **EXIT-TARGET** | Fallback fixed target (e.g. $+2.0R$) | Climax profit capture | TP limit order hit |

Every exit records its exact reason in the log (e.g. `[SCALP EXIT] Momentum Stall at +1.42R`).

---

## 7. Scalping Protections & Session Filters

1. **Session Hours Filter:**
   - `InpScalpUseSessionFilter = true`: Trades only during high-liquidity sessions (Default: 08:00 to 20:00 broker time, covering London and New York sessions).
   - Avoids low-liquidity rollover hours where wide spreads erode scalping edge.

2. **Daily Risk & Cooldown Guards:**
   - `InpScalpMaxTradesPerDay` (Default: 10).
   - `InpScalpCooldownBars` (Default: 3 bars cooldown after position close).
   - `InpScalpDailyLossLimitPct` (Default: 3.0% maximum daily drawdown cutoff).
   - `InpScalpDailyProfitLockPct` (Default: 5.0% daily target lock).

3. **Broker Execution Checks:**
   - Spread filter: Blocks entry if `currentSpread > InpMaxSpreadPoints`.
   - Stops & Freeze level validation before order dispatch.
   - Symbol-aware filling mode (`SYMBOL_FILLING_MODE`).

---

## 8. Empirical Verification & Acceptance Framework

The implementation is validated across three testing rings:
1. **Compilation Gate:** 0 errors, 0 warnings with official MetaEditor64 CLI.
2. **Unit / Synthetic Logic Suite (`unit_synthetic_tests.py`):** Pure Python verification of micro-structure, H1/H2 transitions, L1/L2 transitions, second-break detection, and dynamic exits.
3. **Strategy Tester Live Runs:**
   - EURUSD M5 (M15 Context)
   - GBPUSD M5 (M15 Context)
   - XAUUSD M5 (M15 Context)
   - Every Tick / Real Ticks mode.
4. **Fidelity Guard:** Verification that `MODE_BOOK_EXACT` remains 100% reproducible and identical to prior baseline.
