# Quantitative Trading & Price Action Research Log

## 1. Al Brooks Price Action Concepts

### Entry 1: High 2 / Low 2 Setups (H2/L2)
* **SOURCE**: Brooks Trading Course / Price Action Fundamentals
* **AUTHOR**: Al Brooks
* **URL**: https://brookstradingcourse.com
* **CONCEPT**: High 2 (H2) and Low 2 (L2) Setups
* **WHAT IT MEANS**: The market generally moves in two-legged waves. In a bull trend, a pullback often has two small legs down. The first attempt to resume the trend is a High 1. If it fails and pulls back again, the second attempt to resume the trend is a High 2. H2s are higher probability because counter-trend traders give up after two failed attempts to reverse the market.
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: 
  - Define trend: Close > 20 EMA for N bars. 
  - Define Leg 1 down: A bar with a lower low than the prior bar. 
  - Define High 1: A bar whose high is broken by the next bar. 
  - Define Leg 2 down: Subsequent lower low after High 1. 
  - Rule: Buy stop 1 tick above the high of the signal bar that forms the second localized bottom.
* **RISKS / LIMITATIONS**: Context is critical. Buying an H2 at the top of a trading range or directly into major resistance is a low-probability trade (a trap).

### Entry 2: Two-Legged Pullbacks
* **SOURCE**: Trading Setups Review / Al Brooks Methodology
* **AUTHOR**: Galen Woods / Al Brooks
* **URL**: https://www.tradingsetupsreview.com
* **CONCEPT**: Two-legged pullbacks (M2B / M2S)
* **WHAT IT MEANS**: Similar to H2/L2, a two-legged pullback relies on the exhaustion of counter-trend traders. A classic setup occurs when price retreats to the 20-period EMA in two distinct waves.
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: Measure the swing high to the EMA. Identify a zig-zag pattern (ABC correction) using a ZigZag indicator with a very small threshold. Enter when the C leg touches the 20 EMA and price closes back in the direction of the main trend.
* **RISKS / LIMITATIONS**: Defining a "leg" algorithmically can be difficult due to market noise. Small inside bars can artificially reset or confuse programmatic leg counts.

### Entry 3: Strong Trends vs Trading Ranges
* **SOURCE**: Brooks Trading Course
* **AUTHOR**: Al Brooks
* **URL**: https://brookstradingcourse.com
* **CONCEPT**: Market Context (Trend vs. Range)
* **WHAT IT MEANS**: The market is either trending (moving directionally with strong momentum) or ranging (moving sideways, testing extremes). Strategies that work in trends (buying pullbacks) fail in ranges, where the correct approach is to "buy low, sell high, and scalp."
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: 
  - Trend: ADX > 25, or moving averages (e.g., 20 EMA, 50 SMA) are fanned out and sloping. 
  - Range: ADX < 20, or price frequently crosses back and forth over a flat 20 EMA.
* **RISKS / LIMITATIONS**: Transitions are lagging. By the time a strong trend is algorithmically confirmed, it may be entering a late-stage climax or transitioning into a trading range.

### Entry 4: Signal Bars and Trend Bar Characteristics
* **SOURCE**: Trading Price Action Trends (Book)
* **AUTHOR**: Al Brooks
* **URL**: https://www.amazon.com/Trading-Price-Action-Trends-Technical/dp/1118046714
* **CONCEPT**: Signal bar quality and trend bar bodies
* **WHAT IT MEANS**: A setup is only as valid as its signal bar. A strong bullish signal bar closes near its high (little to no upper wick) and has a body that is larger than the preceding bars. This indicates strong conviction from buyers.
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: 
  - Bull Signal Bar: `(Close - Low) / (High - Low) > 0.8` (closes in top 20% of range). 
  - Trend Bar: `Body Size > ATR(14) * 0.5`.
* **RISKS / LIMITATIONS**: High-quality signal bars are often very large, which requires a wider stop loss (placed below the signal bar), inherently reducing the risk-to-reward ratio.

## 2. Bob Volman Scalping Concepts

### Entry 5: 20/25 EMA Behavior and Orderly Pullbacks
* **SOURCE**: Forex Price Action Scalping
* **AUTHOR**: Bob Volman
* **URL**: https://moecapital.com / Bob Volman Books
* **CONCEPT**: 25 EMA as a directional filter
* **WHAT IT MEANS**: Volman uses a 25 EMA on a 5-minute chart. An "orderly pullback" is a slow, multi-bar drift toward the EMA without strong counter-trend momentum bars. The EMA acts as a dynamic level where trend traders reload.
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: 
  - Uptrend: Price > 25 EMA. 
  - Orderly Pullback: 3 to 5 consecutive bars with small bodies making lower highs/lows, moving toward the 25 EMA. 
  - Trigger: A bar breaking the high of the previous bar near the EMA.
* **RISKS / LIMITATIONS**: If the pullback bars are large/strong, it signifies institutional counter-trend selling, making the EMA test dangerous. Algorithms must filter out high-volatility pullbacks.

### Entry 6: Compression Before Breakout (Build-up)
* **SOURCE**: Forex Price Action Scalping
* **AUTHOR**: Bob Volman
* **URL**: https://www.forexfactory.com/thread/volman-price-action
* **CONCEPT**: Pre-breakout tension/compression
* **WHAT IT MEANS**: Before a genuine breakout, price often consolidates in a very tight range against a support/resistance level. This "build-up" indicates absorption of limit orders. 
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: Look for the Bollinger Band width (or ATR) over a 5-10 bar window to drop to the lowest 10th percentile of the last 100 bars, sitting right below a local max (resistance).
* **RISKS / LIMITATIONS**: Breakouts are notoriously prone to false triggers (bull traps/bear traps). Pre-breakout compression reduces this risk but doesn't eliminate it entirely.

### Entry 7: Block Break Setup
* **SOURCE**: Understanding Price Action
* **AUTHOR**: Bob Volman
* **URL**: Primary literature
* **CONCEPT**: Block Break Setup
* **WHAT IT MEANS**: A "block" is a tight cluster of bars (consolidation). A block break occurs when price violently exits this cluster in the direction of the prevailing trend, often catching counter-trend scalpers off guard.
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: 
  - Define Block: 4+ bars where `High_max - Low_min <= 1.5 * AverageBarSize`.
  - Trigger: Close > `High_max` of the block.
* **RISKS / LIMITATIONS**: Spread widening during sudden volatility (which causes the block break) can ruin the risk-to-reward ratio for an automated market order entry.

### Entry 8: Trade Management & Tipping Point
* **SOURCE**: Forex Price Action Scalping
* **AUTHOR**: Bob Volman
* **URL**: Primary literature
* **CONCEPT**: The Tipping Point Technique
* **WHAT IT MEANS**: A point on the chart where, if price reaches it, the original premise of the trade is completely invalidated. Stops are placed exactly there, and traders do not exit early out of fear.
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: Hard stop-loss placed 1 pip below the low of the signal bar or the pullback swing low. No trailing stops or early exits unless a clearly defined opposing setup forms.
* **RISKS / LIMITATIONS**: Psychologically difficult for manual traders; for algos, this means accepting a fixed 1R loss without attempting to minimize it during chop.

## 3. PATs / Second Entry Concepts

### Entry 9: Second Entry Mechanics & Higher Probability
* **SOURCE**: Price Action Trading System (PATs)
* **AUTHOR**: Mack
* **URL**: https://priceactiontradingsystem.com
* **CONCEPT**: Second Entry as a trap for early entrants
* **WHAT IT MEANS**: The market traps impatient traders. The first attempt to reverse a trend traps counter-trend traders, and its failure stops them out. Entering on the second attempt leverages the momentum of those trapped traders being forced to cover.
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: Identify a swing high. Wait for a pullback (lower lows). Track the first bar to break a previous bar's high (First Entry Long). Wait for price to drop below that bar's low again. The next bar to break a previous bar's high is the Second Entry Long.
* **RISKS / LIMITATIONS**: Over-reliance on tick charts (commonly used in PATs) means data feeds must be incredibly accurate. Tick charts do not align perfectly across different brokers.

### Entry 10: Failed First Attempt Definition
* **SOURCE**: PATs Community / Reddit Daytrading
* **AUTHOR**: PATs community
* **URL**: https://www.reddit.com/r/Daytrading/
* **CONCEPT**: The "Trap" / Failed 2nd Entry
* **WHAT IT MEANS**: If a valid Second Entry triggers but immediately fails and reverses, it is a high-probability setup to trade in the *opposite* direction.
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: If a Long H2 condition triggers, but price hits the H2 stop-loss (bottom of the signal bar) before hitting a 1R target, automatically execute a Short market order.
* **RISKS / LIMITATIONS**: Double whipsaws. In tight trading ranges, both the second entry and the trap can fail sequentially, causing back-to-back losses.

## 4. Quantitative Research

### Entry 11: Volatility Contraction Pattern (VCP)
* **SOURCE**: Trade Like a Stock Market Wizard
* **AUTHOR**: Mark Minervini
* **URL**: https://traderlion.com/
* **CONCEPT**: Volatility Contraction Pattern (VCP)
* **WHAT IT MEANS**: A geometric pattern where pullbacks become progressively shallower (e.g., -20%, then -10%, then -4%) accompanied by decreasing volume. It signifies the absorption of floating supply by institutional buyers.
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: Look for 2 to 4 consecutive swing lows in a consolidation period where the percentage depth of each swing (from the local high) is strictly less than the previous swing depth. Volume on the final swing must be < 50% of the 50-day average.
* **RISKS / LIMITATIONS**: Extremely complex to programmatically detect due to the subjective nature of what constitutes a "swing." Highly prone to curve-fitting.

### Entry 12: Trend Persistence Measurement (Hurst Exponent)
* **SOURCE**: Quantitative trading academic papers / Aimspress
* **AUTHOR**: H.E. Hurst / Quant Researchers
* **URL**: https://www.quantifiedstrategies.com
* **CONCEPT**: Hurst Exponent (H)
* **WHAT IT MEANS**: A statistical measure of time series memory. H = 0.5 implies a random walk. H > 0.5 implies trending (persistence). H < 0.5 implies mean-reversion (anti-persistence).
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: Calculate Hurst Exponent over a rolling 100-period window. If `H > 0.6`, enable momentum/breakout strategies. If `H < 0.4`, enable RSI divergence / Bollinger Band mean-reversion strategies.
* **RISKS / LIMITATIONS**: The Hurst Exponent is highly sensitive to the lookback period and computationally expensive. It is also backward-looking and may lag regime shifts.

### Entry 13: ATR-Normalized Momentum
* **SOURCE**: Systematic Trading
* **AUTHOR**: Robert Carver
* **URL**: Primary literature / Quant blogs
* **CONCEPT**: Volatility-adjusted momentum
* **WHAT IT MEANS**: Raw price momentum isn't comparable across different volatility regimes. Dividing momentum (e.g., Price - Price 20 periods ago) by the Average True Range standardizes the metric, allowing for apples-to-apples comparison.
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: Signal = `(Close - Close[20]) / ATR(20)`. Go long if Signal > 1.5; short if Signal < -1.5. 
* **RISKS / LIMITATIONS**: Can keep you out of explosive moves if volatility scales up simultaneously with momentum, as the denominator (ATR) will suppress the signal value.

### Entry 14: Mean Reversion vs Momentum in Market Phases
* **SOURCE**: Advances in Financial Machine Learning
* **AUTHOR**: Marcos Lopez de Prado
* **URL**: https://www.wiley.com
* **CONCEPT**: Regime-switching models
* **WHAT IT MEANS**: Markets transition between mean-reverting and trending phases. Applying a single strategy across all phases guarantees drawdown. Strategies must adapt dynamically or turn off during hostile regimes.
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: Implement a Hidden Markov Model (HMM) or use a combination of ADX + Hurst Exponent to classify the current regime. Route capital to sub-strategies dynamically based on the active regime state.
* **RISKS / LIMITATIONS**: Regime classification often suffers from lag. Entering a "trending" regime might only be detected exactly as the trend climaxes.

## 5. MetaTrader 5 Strategy Tester

### Entry 15: Every Tick vs Every Tick Based on Real Ticks
* **SOURCE**: MetaTrader 5 Official Documentation
* **AUTHOR**: MetaQuotes
* **URL**: https://www.metatrader5.com/
* **CONCEPT**: Backtesting Data Models
* **WHAT IT MEANS**: "Every tick" interpolates data using 1-minute OHLC bars. "Real ticks" downloads exact historical bid/ask paths from the broker. Real ticks reflect exact market conditions (including spread widening and gaps).
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: When validating any scalping EA, strictly enforce testing on "Every tick based on real ticks." Reject any equity curve generated solely on "Every tick" if the average trade duration is < 15 minutes.
* **RISKS / LIMITATIONS**: Real tick testing is exceptionally slow and requires vast amounts of disk space. Missing broker data can still cause synthetic gaps.

### Entry 16: Drawdown Statistics (Absolute, Maximal, Relative)
* **SOURCE**: MQL5 Community / Documentation
* **AUTHOR**: MetaQuotes
* **URL**: https://www.mql5.com/
* **CONCEPT**: Evaluating Strategy Risk
* **WHAT IT MEANS**: 
  - Absolute DD: Initial deposit down to the lowest point. 
  - Maximal DD: The largest monetary drop from a peak to a trough. 
  - Relative DD: The largest percentage drop from peak to trough.
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: In MT5 optimization, set a custom fitness function to maximize `Net Profit / Maximal Drawdown (Recovery Factor)` while filtering out any pass where `Relative Drawdown > 15%`.
* **RISKS / LIMITATIONS**: Backtested drawdown often underestimates live drawdown due to slippage and psychological intervention.

### Entry 17: Forward Testing & Walk-Forward Validation
* **SOURCE**: MQL5 Articles / Algo Trading methodologies
* **AUTHOR**: MQL5 Community Authors
* **URL**: https://www.mql5.com/
* **CONCEPT**: Walk-Forward Optimization
* **WHAT IT MEANS**: Dividing historical data into an in-sample (optimization) period and an out-of-sample (forward test) period. It tests if the parameters found during optimization actually hold up on unseen data.
* **HOW IT COULD BE TRANSLATED INTO A TESTABLE RULE**: Use MT5's built-in "Forward Testing" tab. Set it to 1/2 or 1/3. Optimize over 2022-2023. Automatically run the best results over 2024. If the forward result is negative, discard the parameters as curve-fitted.
* **RISKS / LIMITATIONS**: Can still lead to "meta-overfitting" if a trader continuously tweaks the strategy logic just to pass the walk-forward test.
