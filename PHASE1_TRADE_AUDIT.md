# PHASE 1 — QUANTITATIVE TRADE AUDIT

**v5.00 EURUSD M5 | 2023.01.01 – 2023.03.31 | 67 trades (expected)**

## 1. Overview

| Metric | Value |
|---|---|
| Total Trades | 67 |
| Date Range | 2023.01.04 10:50:00 → 2023.03.28 11:00:00 |
| Trading Days | 40 |
| Avg Trades/Day | 1.7 |

## 2. Setup Distribution

| Setup | Count | % |
|---|---|---|
| SCALP_H2 | 38 | 56.7% |
| SCALP_L2 | 29 | 43.3% |

## 3. Direction Distribution

| Direction | Count | % |
|---|---|---|
| Buy | 38 | 56.7% |
| Sell | 29 | 43.3% |

## 4. Exit Reason Distribution ⚠️ KEY

| Exit Reason | Count | % |
|---|---|---|
| SCALP_EXIT_OPPOSITE_PA_REVERSAL | 47 | 70.1% |
| SCALP_EXIT_MOMENTUM_STALL | 14 | 20.9% |
| UNKNOWN | 4 | 6.0% |
| SCALP_EXIT_SESSION_END | 1 | 1.5% |
| SCALP_EXIT_SR_WALL_REACHED | 1 | 1.5% |

## 5. Hold Duration Analysis ⚠️ CRITICAL

| Metric | Minutes | M5 Bars |
|---|---|---|
| Min Hold | 5 | 1.0 |
| Max Hold | 45 | 9.0 |
| Average Hold | 17 | 3.4 |
| Median Hold | 15 | 3.0 |

### Hold Distribution

| Hold Category | Count | % |
|---|---|---|
| 1-bar exits (≤5 min) | 8 | 11.9% |
| 2-bar exits (5-10 min) | 19 | 28.4% |
| 3+ bar exits (>10 min) | 36 | 53.7% |

### Hold Duration Histogram (5-min buckets)
```
    5- 10 min: █████████ (9)
   10- 15 min: ██████████████████ (18)
   15- 20 min: █████████ (9)
   20- 25 min: ██████████████ (14)
   25- 30 min: ████ (4)
   30- 35 min: ████ (4)
   35- 40 min: ██ (2)
   40- 45 min: ██ (2)
   45- 50 min: █ (1)
```

## 6. R-Multiple at Exit

Trades with reported R at exit: 15/67

| Metric | Value |
|---|---|
| Min R | 0.50 |
| Max R | 1.51 |
| Avg R | 0.86 |
| Median R | 0.80 |

| Exit Reason | Count | Avg R | Min R | Max R |
|---|---|---|---|---|
| SCALP_EXIT_MOMENTUM_STALL | 14 | 0.88 | 0.50 | 1.51 |
| SCALP_EXIT_SR_WALL_REACHED | 1 | 0.61 | 0.61 | 0.61 |

## 7. Trailing Activity

Trades that triggered trailing: **7/67** (10.4%)

| Pos# | Setup | Dir | Trails | Exit Reason | R at Exit |
|---|---|---|---|---|---|
| #14 | SCALP_H2 | Buy | 2 | SCALP_EXIT_MOMENTUM_STALL | 1.51 |
| #26 | SCALP_H2 | Buy | 1 | SCALP_EXIT_MOMENTUM_STALL | 0.96 |
| #44 | SCALP_L2 | Sell | 3 | SCALP_EXIT_MOMENTUM_STALL | 0.97 |
| #54 | SCALP_L2 | Sell | 2 | SCALP_EXIT_MOMENTUM_STALL | 1.28 |
| #56 | SCALP_L2 | Sell | 4 | SCALP_EXIT_MOMENTUM_STALL | 1.19 |
| #86 | SCALP_H2 | Buy | 2 | SCALP_EXIT_MOMENTUM_STALL | 1.05 |
| #126 | SCALP_L2 | Sell | 1 | UNKNOWN | N/A |

## 8. Monthly Distribution

| Month | Trades |
|---|---|
| 2023-01 | 22 |
| 2023-02 | 22 |
| 2023-03 | 23 |

## 9. Fast Exit Analysis ⚠️ ROOT CAUSE

**27/67 (40.3%)** trades exited within 2 bars (≤10 min)

| Exit Reason (Fast Exits) | Count |
|---|---|
| SCALP_EXIT_OPPOSITE_PA_REVERSAL | 25 |
| SCALP_EXIT_SESSION_END | 1 |
| SCALP_EXIT_SR_WALL_REACHED | 1 |

### Individual Fast Exits

| # | Entry | Setup | Dir | Hold(min) | Exit Reason |
|---|---|---|---|---|---|
| #2 | 2023.01.04 10:50:00 | SCALP_H2 | Buy | 5 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #8 | 2023.01.06 08:30:00 | SCALP_L2 | Sell | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #16 | 2023.01.11 10:50:00 | SCALP_H2 | Buy | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #18 | 2023.01.11 11:45:00 | SCALP_H2 | Buy | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #20 | 2023.01.16 18:50:30 | SCALP_L2 | Sell | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #24 | 2023.01.17 13:00:00 | SCALP_H2 | Buy | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #28 | 2023.01.17 18:20:00 | SCALP_L2 | Sell | 5 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #30 | 2023.01.18 14:25:00 | SCALP_H2 | Buy | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #34 | 2023.01.23 17:00:00 | SCALP_H2 | Buy | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #38 | 2023.01.25 19:15:00 | SCALP_H2 | Buy | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #42 | 2023.01.30 09:25:00 | SCALP_H2 | Buy | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #48 | 2023.02.01 11:20:00 | SCALP_H2 | Buy | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #50 | 2023.02.01 16:35:00 | SCALP_H2 | Buy | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #68 | 2023.02.14 19:00:00 | SCALP_H2 | Buy | 5 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #70 | 2023.02.17 18:45:00 | SCALP_H2 | Buy | 5 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #72 | 2023.02.17 19:50:00 | SCALP_H2 | Buy | 10 | SCALP_EXIT_SESSION_END |
| #78 | 2023.02.22 10:00:00 | SCALP_L2 | Sell | 5 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #88 | 2023.02.28 17:00:00 | SCALP_L2 | Sell | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #90 | 2023.03.02 15:55:00 | SCALP_H2 | Buy | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #94 | 2023.03.07 17:35:00 | SCALP_L2 | Sell | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #100 | 2023.03.13 11:15:00 | SCALP_L2 | Sell | 5 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #106 | 2023.03.16 08:45:00 | SCALP_H2 | Buy | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #110 | 2023.03.21 09:15:00 | SCALP_H2 | Buy | 5 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #116 | 2023.03.22 09:15:00 | SCALP_H2 | Buy | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #120 | 2023.03.22 14:35:00 | SCALP_L2 | Sell | 6 | SCALP_EXIT_SR_WALL_REACHED |
| #130 | 2023.03.24 19:30:00 | SCALP_H2 | Buy | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |
| #132 | 2023.03.27 14:25:00 | SCALP_H2 | Buy | 10 | SCALP_EXIT_OPPOSITE_PA_REVERSAL |

## 10. Lot Size Analysis

| Metric | Value |
|---|---|
| Avg Lot | 0.76 |
| Min Lot | 0.18 |
| Max Lot | 1.45 |
| Std Dev | 0.27 |

> [!NOTE]
> Wide lot variation (0.18 to 1.45) suggests SL distances vary significantly,
> which means pivot detection is producing very different risk profiles per trade.

## 11. Complete Trade Log

<details>
<summary>Click to expand all 67 trades</summary>

| # | Entry Time | Setup | Dir | Lot | SL | TP | Exit Time | Exit Reason | Hold(min) | R |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 2023.01.04 10:50:00 | SCALP_H2 | Buy | 0.59 | 1.06059 | 1.06566 | 2023.01.04 10:55:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 5 |  |
| 2 | 2023.01.04 14:55:00 | SCALP_H2 | Buy | 0.39 | 1.06002 | 1.06749 | None | UNKNOWN |  |  |
| 3 | 2023.01.05 16:40:00 | SCALP_L2 | Sell | 0.68 | 1.05366 | 1.04934 | 2023.01.05 17:00:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 20 |  |
| 4 | 2023.01.06 08:30:00 | SCALP_L2 | Sell | 0.58 | 1.05357 | 1.04847 | 2023.01.06 08:40:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 5 | 2023.01.06 13:05:00 | SCALP_L2 | Sell | 0.98 | 1.05011 | 1.04711 | None | UNKNOWN |  |  |
| 6 | 2023.01.06 17:35:00 | SCALP_H2 | Buy | 0.64 | 1.06114 | 1.06570 | 2023.01.06 17:50:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 15 |  |
| 7 | 2023.01.09 13:10:00 | SCALP_H2 | Buy | 0.62 | 1.06790 | 1.07258 | 2023.01.09 13:30:00 | SCALP_EXIT_MOMENTUM_STALL | 20 | 1.51 |
| 8 | 2023.01.11 10:50:00 | SCALP_H2 | Buy | 0.68 | 1.07356 | 1.07791 | 2023.01.11 11:00:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 9 | 2023.01.11 11:45:00 | SCALP_H2 | Buy | 0.68 | 1.07384 | 1.07816 | 2023.01.11 11:55:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 10 | 2023.01.16 18:50:30 | SCALP_L2 | Sell | 1.33 | 1.08194 | 1.07972 | 2023.01.16 19:00:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 11 | 2023.01.17 09:40:00 | SCALP_L2 | Sell | 0.73 | 1.08298 | 1.07893 | 2023.01.17 10:00:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 20 |  |
| 12 | 2023.01.17 13:00:00 | SCALP_H2 | Buy | 0.42 | 1.08295 | 1.08997 | 2023.01.17 13:10:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 13 | 2023.01.17 14:05:00 | SCALP_H2 | Buy | 0.63 | 1.08345 | 1.08813 | 2023.01.17 14:25:00 | SCALP_EXIT_MOMENTUM_STALL | 20 | 0.96 |
| 14 | 2023.01.17 18:20:00 | SCALP_L2 | Sell | 1.10 | 1.07913 | 1.07643 | 2023.01.17 18:25:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 5 |  |
| 15 | 2023.01.18 14:25:00 | SCALP_H2 | Buy | 0.27 | 1.08471 | 1.09554 | 2023.01.18 14:35:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 16 | 2023.01.18 18:10:00 | SCALP_L2 | Sell | 0.78 | 1.08040 | 1.07665 | 2023.01.18 18:50:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 40 |  |
| 17 | 2023.01.23 17:00:00 | SCALP_H2 | Buy | 1.04 | 1.08547 | 1.08829 | 2023.01.23 17:10:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 18 | 2023.01.25 15:50:00 | SCALP_H2 | Buy | 0.68 | 1.08857 | 1.09286 | 2023.01.25 16:05:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 15 |  |
| 19 | 2023.01.25 19:15:00 | SCALP_H2 | Buy | 0.94 | 1.09015 | 1.09324 | 2023.01.25 19:25:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 20 | 2023.01.26 13:00:00 | SCALP_L2 | Sell | 0.82 | 1.09044 | 1.08690 | 2023.01.26 13:25:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 25 |  |
| 21 | 2023.01.30 09:25:00 | SCALP_H2 | Buy | 0.41 | 1.08714 | 1.09407 | 2023.01.30 09:35:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 22 | 2023.01.31 08:05:00 | SCALP_L2 | Sell | 0.62 | 1.08534 | 1.08069 | 2023.01.31 08:25:00 | SCALP_EXIT_MOMENTUM_STALL | 20 | 0.97 |
| 23 | 2023.02.01 08:30:00 | SCALP_H2 | Buy | 0.66 | 1.08646 | 1.09084 | 2023.02.01 08:45:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 15 |  |
| 24 | 2023.02.01 11:20:00 | SCALP_H2 | Buy | 0.88 | 1.08833 | 1.09163 | 2023.02.01 11:30:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 25 | 2023.02.01 16:35:00 | SCALP_H2 | Buy | 0.89 | 1.09108 | 1.09435 | 2023.02.01 16:45:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 26 | 2023.02.02 09:15:00 | SCALP_L2 | Sell | 0.56 | 1.10109 | 1.09587 | 2023.02.02 09:35:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 20 |  |
| 27 | 2023.02.03 16:20:30 | SCALP_L2 | Sell | 0.64 | 1.08659 | 1.08203 | 2023.02.03 16:40:00 | SCALP_EXIT_MOMENTUM_STALL | 20 | 1.28 |
| 28 | 2023.02.06 16:30:00 | SCALP_L2 | Sell | 1.02 | 1.07441 | 1.07153 | 2023.02.06 16:50:00 | SCALP_EXIT_MOMENTUM_STALL | 20 | 1.19 |
| 29 | 2023.02.08 19:15:00 | SCALP_L2 | Sell | 1.13 | 1.07393 | 1.07129 | 2023.02.08 19:45:00 | SCALP_EXIT_MOMENTUM_STALL | 30 | 0.80 |
| 30 | 2023.02.09 10:00:00 | SCALP_H2 | Buy | 0.59 | 1.07469 | 1.07976 | 2023.02.09 10:35:00 | SCALP_EXIT_MOMENTUM_STALL | 35 | 0.50 |
| 31 | 2023.02.09 13:10:00 | SCALP_H2 | Buy | 0.83 | 1.07575 | 1.07938 | 2023.02.09 13:45:00 | SCALP_EXIT_MOMENTUM_STALL | 35 | 0.79 |
| 32 | 2023.02.10 11:05:00 | SCALP_L2 | Sell | 1.08 | 1.07160 | 1.06878 | 2023.02.10 11:25:00 | SCALP_EXIT_MOMENTUM_STALL | 20 | 0.91 |
| 33 | 2023.02.14 16:30:00 | SCALP_L2 | Sell | 0.46 | 1.07386 | 1.06717 | 2023.02.14 16:55:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 25 |  |
| 34 | 2023.02.14 19:00:00 | SCALP_H2 | Buy | 1.40 | 1.07248 | 1.07467 | 2023.02.14 19:05:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 5 |  |
| 35 | 2023.02.17 18:45:00 | SCALP_H2 | Buy | 1.02 | 1.06778 | 1.07078 | 2023.02.17 18:50:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 5 |  |
| 36 | 2023.02.17 19:50:00 | SCALP_H2 | Buy | 0.96 | 1.06842 | 1.07160 | 2023.02.17 20:00:00 | SCALP_EXIT_SESSION_END | 10 |  |
| 37 | 2023.02.21 10:50:00 | SCALP_L2 | Sell | 0.65 | 1.06688 | 1.06223 | 2023.02.21 11:10:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 20 |  |
| 38 | 2023.02.21 12:05:00 | SCALP_L2 | Sell | 0.72 | 1.06655 | 1.06229 | 2023.02.21 12:35:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 30 |  |
| 39 | 2023.02.22 10:00:00 | SCALP_L2 | Sell | 0.56 | 1.06553 | 1.06016 | 2023.02.22 10:05:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 5 |  |
| 40 | 2023.02.22 10:55:00 | SCALP_L2 | Sell | 0.84 | 1.06436 | 1.06073 | 2023.02.22 11:10:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 15 |  |
| 41 | 2023.02.23 16:40:00 | SCALP_L2 | Sell | 0.89 | 1.06006 | 1.05667 | 2023.02.23 17:00:00 | SCALP_EXIT_MOMENTUM_STALL | 20 | 0.64 |
| 42 | 2023.02.27 12:55:00 | SCALP_L2 | Sell | 1.05 | 1.05656 | 1.05365 | 2023.02.27 13:35:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 40 |  |
| 43 | 2023.02.28 13:40:00 | SCALP_H2 | Buy | 0.92 | 1.06085 | 1.06415 | 2023.02.28 14:00:00 | SCALP_EXIT_MOMENTUM_STALL | 20 | 1.05 |
| 44 | 2023.02.28 17:00:00 | SCALP_L2 | Sell | 0.53 | 1.06195 | 1.05619 | 2023.02.28 17:10:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 45 | 2023.03.02 15:55:00 | SCALP_H2 | Buy | 0.42 | 1.05884 | 1.06607 | 2023.03.02 16:05:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 46 | 2023.03.03 18:45:00 | SCALP_H2 | Buy | 1.30 | 1.06149 | 1.06383 | 2023.03.03 19:10:00 | SCALP_EXIT_MOMENTUM_STALL | 25 | 0.64 |
| 47 | 2023.03.07 17:35:00 | SCALP_L2 | Sell | 0.68 | 1.05929 | 1.05479 | 2023.03.07 17:45:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 48 | 2023.03.07 19:25:00 | SCALP_L2 | Sell | 0.76 | 1.05647 | 1.05245 | 2023.03.07 19:55:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 30 |  |
| 49 | 2023.03.09 14:35:00 | SCALP_H2 | Buy | 0.65 | 1.05612 | 1.06083 | 2023.03.09 15:00:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 25 |  |
| 50 | 2023.03.13 11:15:00 | SCALP_L2 | Sell | 0.48 | 1.06814 | 1.06178 | 2023.03.13 11:20:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 5 |  |
| 51 | 2023.03.13 17:10:00 | SCALP_H2 | Buy | 0.43 | 1.07243 | 1.07951 | 2023.03.13 17:25:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 15 |  |
| 52 | 2023.03.15 09:05:00 | SCALP_L2 | Sell | 0.65 | 1.07425 | 1.06951 | 2023.03.15 09:25:00 | SCALP_EXIT_MOMENTUM_STALL | 20 | 0.51 |
| 53 | 2023.03.16 08:45:00 | SCALP_H2 | Buy | 0.72 | 1.06125 | 1.06554 | 2023.03.16 08:55:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 54 | 2023.03.17 17:10:00 | SCALP_H2 | Buy | 1.03 | 1.06599 | 1.06896 | 2023.03.17 17:55:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 45 |  |
| 55 | 2023.03.21 09:15:00 | SCALP_H2 | Buy | 0.72 | 1.07195 | 1.07618 | 2023.03.21 09:20:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 5 |  |
| 56 | 2023.03.21 10:40:00 | SCALP_H2 | Buy | 0.51 | 1.07347 | 1.07950 | 2023.03.21 10:55:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 15 |  |
| 57 | 2023.03.21 12:35:00 | SCALP_H2 | Buy | 1.28 | 1.07711 | 1.07951 | 2023.03.21 12:50:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 15 |  |
| 58 | 2023.03.22 09:15:00 | SCALP_H2 | Buy | 0.51 | 1.07705 | 1.08296 | 2023.03.22 09:25:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 59 | 2023.03.22 10:15:00 | SCALP_H2 | Buy | 0.83 | 1.07745 | 1.08114 | 2023.03.22 10:30:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 15 |  |
| 60 | 2023.03.22 14:35:00 | SCALP_L2 | Sell | 1.45 | 1.07914 | 1.07704 | 2023.03.22 14:40:40 | SCALP_EXIT_SR_WALL_REACHED | 6 | 0.61 |
| 61 | 2023.03.22 17:35:00 | SCALP_H2 | Buy | 1.09 | 1.07851 | 1.08133 | None | UNKNOWN |  |  |
| 62 | 2023.03.24 08:10:00 | SCALP_L2 | Sell | 0.18 | 1.08467 | 1.06781 | 2023.03.24 08:30:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 20 |  |
| 63 | 2023.03.24 09:35:00 | SCALP_L2 | Sell | 0.55 | 1.07954 | 1.07393 | None | UNKNOWN |  |  |
| 64 | 2023.03.24 13:30:00 | SCALP_H2 | Buy | 0.39 | 1.07363 | 1.08167 | 2023.03.24 13:50:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 20 |  |
| 65 | 2023.03.24 19:30:00 | SCALP_H2 | Buy | 0.82 | 1.07528 | 1.07915 | 2023.03.24 19:40:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 66 | 2023.03.27 14:25:00 | SCALP_H2 | Buy | 0.78 | 1.07735 | 1.08137 | 2023.03.27 14:35:00 | SCALP_EXIT_OPPOSITE_PA_REVERSAL | 10 |  |
| 67 | 2023.03.28 11:00:00 | SCALP_H2 | Buy | 0.93 | 1.08115 | 1.08454 | 2023.03.28 11:30:00 | SCALP_EXIT_MOMENTUM_STALL | 30 | 0.53 |

</details>

---

## 12. DIAGNOSIS & RECOMMENDATIONS

### Problem 1: Opposite PA Reversal is too aggressive

**47/67 (70.1%)** of trades exit because of a single opposing candle.

The current logic treats EVERY bearish candle (close < open, close in bottom 35%, or >40% rejection wick)
as a reason to immediately exit a long trade. This doesn't distinguish between:
- A minor 3-pip doji (noise)
- A medium inside bar (pullback within trend)
- A strong engulfing bar closing below prior support (actual reversal)

### Problem 2: Median hold time is too short

Median hold = **15 minutes** (3.0 M5 bars)

For a trend-following scalping strategy, holding for only 1-2 bars means the EA
almost never captures the actual trend continuation move it's designed for.

### Problem 3: Very few trades develop enough to trail

Only **7/67** trades (10.4%) triggered trailing.
The trailing mechanism (BE at +1R, then bar-by-bar trail) rarely activates because
trades are killed by the PA Reversal exit before they reach +1R.

### Recommended Fixes (Phase 8+)

1. **Context-Aware PA Exit**: Don't exit on ANY opposing candle. Classify counter-trend moves:
   - MINOR: Small body, within ATR noise → HOLD
   - MODERATE: Medium body, breaks minor structure → TIGHTEN stops
   - STRONG: Large engulfing, breaks key structure → EXIT

2. **Minimum Hold Rule**: Don't trigger PA exit until bar 3+ (give the trade 15 min to develop)

3. **R-Based Exit Logic**:
   - If trade is -0.5R to 0R: Let SL handle it, don't exit on PA
   - If trade is 0 to +0.5R: Only exit on STRONG reversal
   - If trade is +0.5R to +1R: Exit on MODERATE or STRONG reversal
   - If trade is > +1R: Trail with structure, exit on any structure break

4. **Momentum Context**: Before exiting on PA reversal, check:
   - Is the M15 trend still intact?
   - Is the EMA slope still favorable?
   - Is tick activity declining (trend exhaustion) or just a normal pullback?

5. **Signal Bar Quality Filter**: Don't enter on weak signal bars. Add:
   - Body size relative to ATR
   - Close position within candle (top/bottom 25% for strong, not 35%)
   - Overlap with prior bars (indicates indecision)
