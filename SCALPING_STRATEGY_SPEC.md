# SCALPING_STRATEGY_SPEC.md
# Technical Specification: Scalping Trend-Momentum Strategy Mode (v6.00 Second-Generation Optimization)
**Mode Identifier:** `MODE_SCALPING_TREND_MOMENTUM`  
**System Version:** 6.00  
**Target Platform:** MetaTrader 5 (MQL5)  
**Execution Timeframe:** M5 (Default) / M1 (Optional Experimental)  
**Context Timeframe:** M15 (Default) / M5 (For M1 execution)  
**Conceptual Lineage:** Al Brooks (H2 / L2 Price Action), Mack PATs (Second Entry), Bob Volman (Second Break / Trend Pullback / 20 EMA Build-Up)

---

## 1. Executive Summary & Strategy Philosophy

`MODE_SCALPING_TREND_MOMENTUM` is a dedicated, higher-frequency intraday price-action trading mode engineered to operate completely independently from the original daily/swing `MODE_BOOK_EXACT`.

### The Core Premise:
In trending markets, counter-trend participants attempt to initiate a correction or reversal. The first counter-trend resumption attempt (High 1 or Low 1) frequently fails because dominant institutional trend momentum remains intact. When this first attempt fails and a second continuation attempt triggers (High 2 or Low 2 / Second Break), trapped counter-trend traders are forced to cover their positions, providing explosive directional fuel for rapid trend continuation.

In v6.00, this setup is guarded by strict **Pressure / Compression** metrics and **Contextual Exit Intelligence**:
1. Price must build up pressure (tight consolidation, range compression, EMA clinging, directional wick tests) before explosion.
2. The exit engine eliminates premature 1-candle noise cuts via a 2-bar maturation hold buffer, counter-trend severity filtering, and intelligent trailing.

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
[Pressure & Setup Quality Filter: Grade >= B, Pressure >= 0.40]
          │
          ▼
[Price Action Confirmation Bar]
          │
          ▼
      [Entry] ───► [Intelligent Dynamic Management] ───► [Intelligent Exit]
```

### Strict Non-Negotiable Constraints:
- `MODE_BOOK_EXACT` and `MODE_ENHANCED` remain 100% untouched, intact, and reproducible.
- Fixed 1.0% risk per trade. No Martingale, no grid, no risk inflation.
- Zero look-ahead bias, zero repainting, bar-close execution.

---

## 2. Priority Hierarchy (Anti-"Indicator Soup")

To preserve institutional-grade price-action purity, decisions are governed by a strict hierarchy:

| Priority | Dimension | Core Metric / Evaluation Engine |
|:---:|:---|:---|
| **1** | **Market Structure** | Confirmed micro-pivots (HH+HL or LH+LL), structural invalidation levels. |
| **2** | **Trend Regime Engine** | 7-state regime (`STRONG_BULL` to `STRONG_BEAR`) based on 20/50 EMA fan, slope, price location, and consecutive closes. |
| **3** | **Pullback Engine** | Retracement classification: `SHALLOW`, `NORMAL`, `DEEP`, `EXHAUSTED` based on depth relative to impulse and bar count. |
| **4** | **Pressure Engine** | Volatility contraction, 3-bar range compression relative to ATR, EMA proximity cling, body overlap, directional wick tests. |
| **5** | **H2 / L2 State Machine** | Explicit finite state transitions tracking failure of Attempt 1 and formation of Attempt 2. |
| **6** | **Setup Quality Scoring** | 100-point composite scoring: Requires `GRADE_B` (>=65.0) and `PressureScore >= 0.40`. |
| **7** | **Support / Resistance** | Room to nearest opposing confirmed level ($\ge 1.0R$). |
| **8** | **Exit Intelligence Engine** | 2-bar thesis maturation buffer, counter-trend severity classification, context-aware momentum stall, trailing stop with cushion. |

---

## 3. Finite State Machine (FSM) Specification

The scalping engine is modeled as an explicit, deterministic Finite State Machine (`ENUM_SCALP_STATE`):

```
                     ┌──────────────────┐
                     │ SCALP_STATE_IDLE │
                     └────────┬─────────┘
                              │ Trend Confirmed (HH+HL / LH+LL + Regime)
                              ▼
                ┌────────────────────────────┐
                │ SCALP_STATE_TREND_DETECTED │
                └─────────────┬──────────────┘
                              │ Orderly Pullback Commences (2 to 8 bars)
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
                              │ Breakout Buffer Crossed + Grade >= B + Pressure >= 0.40
                              ▼
                 ┌───────────────────────┐
                 │ SCALP_STATE_TRIGGERED │
                 └────────────┬──────────┘
                              │ Order Sent to Broker via CTrade
                              ▼
                 ┌───────────────────────┐
                 │ SCALP_STATE_IN_TRADE  │
                 └────────────┬──────────┘
                              │ Exit Condition Triggered (Exit Intelligence)
                              ▼
                     ┌──────────────────┐
                     │ SCALP_STATE_IDLE │
                     └──────────────────┘
```

---

## 4. The 6 Sub-Engines (v6.00 Core Innovation)

### 4.1 SCALP_TREND_REGIME_ENGINE
Classifies market trend into 7 discrete states:
- `REGIME_STRONG_BULL`: EMA20 > EMA50, EMA20 slope > 0.05 pips/bar, price > EMA20, $\ge 3$ consecutive closes above EMA20.
- `REGIME_BULL`: EMA20 > EMA50, price generally above EMA20.
- `REGIME_WEAK_BULL`: EMA20 > EMA50, but price choppy around EMA20.
- `REGIME_RANGE`: EMAs flat, intertwined, no directional slope.
- `REGIME_WEAK_BEAR`: EMA20 < EMA50, but choppy.
- `REGIME_BEAR`: EMA20 < EMA50, price generally below EMA20.
- `REGIME_STRONG_BEAR`: EMA20 < EMA50, EMA20 slope < -0.05 pips/bar, price < EMA20, $\ge 3$ consecutive closes below EMA20.

### 4.2 SCALP_PULLBACK_ENGINE
Measures the retracement depth against the prior directional impulse:
$$\text{Depth} = \frac{|\text{ImpulseExtreme} - \text{PullbackExtreme}|}{|\text{ImpulseExtreme} - \text{ImpulseStart}|}$$
- `PULLBACK_SHALLOW`: Depth $< 0.382$ and $\le 2$ bars.
- `PULLBACK_NORMAL`: Depth $0.382 - 0.618$ and $3 - 6$ bars (Optimal Brooks/Volman pullback).
- `PULLBACK_DEEP`: Depth $0.618 - 0.786$ (Must not breach invalidation level).
- `PULLBACK_EXHAUSTED`: Depth $> 0.786$ or duration $> 8$ bars (Trend momentum compromised).

### 4.3 SCALP_PRESSURE_ENGINE
Evaluates pre-breakout build-up and compression. Computes `PressureScore` ($0.0$ to $1.0$):
$$\text{PressureScore} = 0.30 \cdot C_{\text{range}} + 0.25 \cdot C_{\text{EMA}} + 0.25 \cdot C_{\text{overlap}} + 0.20 \cdot C_{\text{wick}}$$

1. **Range Compression ($C_{\text{range}}$)**:
   $$\text{Avg3BarRange} = \frac{1}{3}\sum_{i=1}^3 (\text{High}_i - \text{Low}_i)$$
   If $\text{Avg3BarRange} < 0.60 \cdot \text{ATR}$, $C_{\text{range}} = 1.0$; if $< 0.85 \cdot \text{ATR}$, $C_{\text{range}} = 0.60$; else $0.10$.
2. **EMA Clinging ($C_{\text{EMA}}$)**:
   Proximity of the last 3 bar closes to EMA20 within $0.5 \cdot \text{ATR}$. Clinging represents absorption of selling/buying pressure.
3. **Body Overlap ($C_{\text{overlap}}$)**:
   Measures intersection of candle bodies: $> 50\%$ overlap indicates horizontal spring compression.
4. **Directional Wick Tests ($C_{\text{wick}}$)**:
   In a bull setup, repeated lower shadows testing EMA20 and being bought up indicate aggressive limit bids absorbing supply.

### 4.4 SCALP_EXPANSION_ENGINE
Detects the transition from compression to explosive continuation:
- Bar range $> 1.1 \cdot \text{ATR}$.
- Close in extreme $25\%$ of the candle range.
- Tick volume $> 1.15 \times$ 5-bar average volume.
- Breakout beyond the H2/L2 trigger price.

### 4.5 SCALP_SETUP_SCORING
Computes composite setup quality ($0$ to $100$):
$$\text{Score} = S_{\text{regime}} (25) + S_{\text{pullback}} (20) + S_{\text{pressure}} (20) + S_{\text{signal}} (15) + S_{\text{SR}} (10) + S_{\text{macro}} (10)$$

- **`GRADE_A_PLUS`** ($\ge 85$): Pristine trend, perfect 20 EMA touch, extreme compression, $>2.5R$ room.
- **`GRADE_A`** ($75 - 84$): Strong trend, normal pullback, good pressure, $>2.0R$ room.
- **`GRADE_B`** ($65 - 74$): Acceptable trend, valid H2/L2, pressure score $\ge 0.40$, $>1.0R$ room. (Minimum execution threshold).
- **`GRADE_C`** ($50 - 64$): Weak trend or shallow pressure. **REJECTED**.
- **`GRADE_REJECT`** ($< 50$): Counter-trend or choppy range. **REJECTED**.

### 4.6 SCALP_EXIT_INTELLIGENCE_ENGINE
Replaces naive single-candle exit (`InpScalpExitOnOppositeBar`) with 4-pillar intelligence:
1. **2-Bar Maturation Hold Buffer**: Trade is protected from noise exits for the first 2 completed bars after fill unless hard SL is hit.
2. **Counter-Trend Severity Classification**:
   - `COUNTER_MINOR`: Retracement $< 0.4 \cdot \text{ATR}$ with weak close. Held as normal trend noise.
   - `COUNTER_MODERATE`: Retracement $0.4 - 0.8 \cdot \text{ATR}$. Tightens SL if profit $> 0.8R$.
   - `COUNTER_STRONG`: Strong engulfing candle $> 1.0 \cdot \text{ATR}$ closing in extreme 20%. Closes position to preserve profit.
   - `STRUCTURE_BREAK`: Close beyond recent micro-swing pivot. Immediate structural exit.
3. **Context-Aware Momentum Stall**:
   Only triggers if trade is already in profit ($R \ge 0.8$) AND price loses EMA20 or prints 2 consecutive opposing candles. Tight consolidation above EMA20 is classified as continuation accumulation and held.
4. **Trailing Stop with Cushion**:
   Trails behind swing lows (buys) or highs (sells) with a 2-bar lag buffer, accelerating to 1-bar trail once profit reaches $2.5R - 3.0R$.

---

## 5. Verification & Performance Ledger

| Symbol / Timeframe | Period | Model | Trades | Net PnL | Max DD | Win Rate | Profit Factor | Status |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **EURUSD M5** | 2023 Q1 (In-Sample) | 1 Min OHLC | 45 | **+$640.55 (+6.41%)** | $251.74 (2.52%) | 46.7% | **1.34** | Verified |
| **EURUSD M5** | 2023 Q1 (Real Ticks) | Real Ticks (3.3M ticks) | 45 | **+$410.27 (+4.10%)** | $328.10 (3.28%) | 44.4% | **1.21** | Verified |
| **GBPUSD M5** | 2023 Q1 (Cross-Asset) | 1 Min OHLC | 30 | **+$92.94 (+0.93%)** | $184.20 (1.84%) | 43.3% | **1.08** | Verified |
| **XAUUSD M5** | 2023 Q1 (Cross-Asset) | 1 Min OHLC | 0 | **$0.00 (0.00%)** | $0.00 (0.00%) | N/A | N/A | Capital Preserved |
| **EURUSD M5** | 2023 Q2 (Out-of-Sample) | 1 Min OHLC | 24 | -$294.06 (-2.94%) | $346.00 (3.46%) | 33.3% | 0.81 | Range Chop |
| **EURUSD M5** | 2023 Full Year | 1 Min OHLC | 135 | -$1,179.11 (-11.79%) | $1,280.00 (12.80%) | 37.8% | 0.87 | Annual Walk-Forward |
