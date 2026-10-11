import pandas as pd
import numpy as np

df = pd.read_csv('c:/Users/NV LAP/Documents/antigravity/cool-noether/xauusd_m5.csv.gz')
df['datetime'] = pd.to_datetime(df['datetime'])
df = df.sort_values('datetime').reset_index(drop=True)

start_dt = pd.to_datetime('2025-10-01')
end_dt = pd.to_datetime('2026-10-01')

high = df['high'].values
low = df['low'].values
close = df['close'].values
open_p = df['open'].values
times = df['datetime'].values

df_idx = df.set_index('datetime')
d1 = df_idx.resample('1D').agg({'open':'first', 'high':'max', 'low':'min', 'close':'last'}).dropna()
h4 = df_idx.resample('4h').agg({'open':'first', 'high':'max', 'low':'min', 'close':'last'}).dropna()
h1 = df_idx.resample('1h').agg({'open':'first', 'high':'max', 'low':'min', 'close':'last'}).dropna()
m15 = df_idx.resample('15min').agg({'open':'first', 'high':'max', 'low':'min', 'close':'last'}).dropna()

d1['range'] = d1['high'] - d1['low']
d1['adr5'] = d1['range'].rolling(5).mean().shift(1)

tr = np.zeros(len(df))
tr[0] = high[0] - low[0]
for i in range(1, len(df)):
    tr[i] = max(high[i] - low[i], abs(high[i] - close[i-1]), abs(low[i] - close[i-1]))
atr = np.zeros(len(df))
alpha = 1.0 / 14.0
atr[0] = tr[0]
for i in range(1, len(df)):
    atr[i] = (1 - alpha) * atr[i-1] + alpha * tr[i]

fy_indices = [i for i, t in enumerate(times) if pd.Timestamp(t) >= start_dt and pd.Timestamp(t) < end_dt]

trades = []
daily_trades = {}
daily_losses = {}
daily_pnl = {}

for idx in fy_indices:
    t = pd.Timestamp(times[idx])
    day_key = t.strftime('%Y-%m-%d')
    
    if daily_losses.get(day_key, 0) >= 1: continue
    if daily_trades.get(day_key, 0) >= 1: continue # 1 trade per day London KZ
    if t.dayofweek == 0: continue
    if t.dayofweek == 4 and t.hour >= 12: continue
    
    # LONDON KILL ZONE ONLY (08:00 - 11:30)
    in_london = (t.hour >= 8 and t.hour < 11) or (t.hour == 11 and t.minute <= 30)
    if not in_london: continue

    cur_atr = atr[idx]
    tol = cur_atr * 0.25

    # 1. Bias
    d1_prior = d1[d1.index < t.floor('1D')]
    if len(d1_prior) < 2: continue
    c1_d = d1_prior.iloc[-1]['close']
    h2_d = d1_prior.iloc[-2]['high']
    l2_d = d1_prior.iloc[-2]['low']
    o1_d = d1_prior.iloc[-1]['open']
    
    d1_bias = 0
    if c1_d > h2_d: d1_bias = 1
    elif c1_d < l2_d: d1_bias = -1
    elif c1_d > o1_d: d1_bias = 1
    elif c1_d < o1_d: d1_bias = -1
    if d1_bias == 0: continue
    target_dir = d1_bias

    # 2. ADR
    today_bars = df[(df['datetime'] >= t.floor('1D')) & (df['datetime'] <= t)]
    today_range = today_bars['high'].max() - today_bars['low'].min()
    adr_val = d1_prior.iloc[-1]['adr5']
    if pd.isna(adr_val) or adr_val <= 0: adr_val = 30.0
    consumed = today_range / adr_val
    if consumed >= 1.0: continue # In London, range shouldn't already be > 100% ADR

    # 3. Candle Quality (M15)
    m15_prior = m15[m15.index < t.floor('15min')]
    if len(m15_prior) > 0:
        m15_bar = m15_prior.iloc[-1]
        m15_rng = m15_bar['high'] - m15_bar['low']
        if m15_rng > 0:
            if target_dir == 1:
                opp_wick = (m15_bar['high'] - max(m15_bar['open'], m15_bar['close'])) / m15_rng
            else:
                opp_wick = (min(m15_bar['open'], m15_bar['close']) - m15_bar['low']) / m15_rng
            if opp_wick > 0.48: continue

    # 4. Dealing Range EQ
    lb = 180
    if idx - lb < 0: continue
    dr_high = high[idx-lb:idx].max()
    dr_low = low[idx-lb:idx].min()
    if target_dir == 1 and close[idx-1] > (dr_high - tol): continue
    if target_dir == -1 and close[idx-1] < (dr_low + tol): continue

    # 5. CISD
    cisd_confirmed = False
    prot_swing = 0.0
    cisd_level = 0.0

    if target_dir == 1:
        sub_l = low[idx-14:idx-1]
        if len(sub_l) > 0:
            min_l = sub_l.min()
            min_bar_rel = 14 - np.argmin(sub_l)
            highest_down_open = min_l
            for k in range(min_bar_rel, min(min_bar_rel + 7, 20)):
                if idx - k < 0: break
                if close[idx - k] <= open_p[idx - k]:
                    highest_down_open = max(highest_down_open, open_p[idx - k])
            if highest_down_open <= min_l:
                highest_down_open = high[idx - min_bar_rel]
            if any(close[idx - c] > highest_down_open for c in range(1, min_bar_rel)):
                cisd_confirmed = True
                prot_swing = min_l
                cisd_level = highest_down_open
    else:
        sub_h = high[idx-14:idx-1]
        if len(sub_h) > 0:
            max_h = sub_h.max()
            max_bar_rel = 14 - np.argmax(sub_h)
            lowest_up_open = max_h
            for k in range(max_bar_rel, min(max_bar_rel + 7, 20)):
                if idx - k < 0: break
                if close[idx - k] >= open_p[idx - k]:
                    lowest_up_open = min(lowest_up_open, open_p[idx - k])
            if lowest_up_open >= max_h:
                lowest_up_open = low[idx - max_bar_rel]
            if any(close[idx - c] < lowest_up_open for c in range(1, max_bar_rel)):
                cisd_confirmed = True
                prot_swing = max_h
                cisd_level = lowest_up_open

    if not cisd_confirmed: continue

    # 6. Entry Model
    entry_found = False
    model_name = ""
    entry_px = close[idx-1]
    
    if target_dir == 1:
        for r in [1, 2]:
            bar_r = idx - r
            if low[bar_r] <= cisd_level + tol and close[bar_r] >= cisd_level - tol:
                entry_found = True; model_name = "CISD_Retest"; break
        if not entry_found:
            for j in range(2, 13):
                bar_j = idx - j
                if bar_j < 0: break
                for i in range(j + 2, 30):
                    bar_i = idx - i
                    if bar_i < 0: break
                    if low[bar_j] < low[bar_i]:
                        bbH, bbL = 0.0, 0.0
                        for k in range(j + 1, i + 2):
                            bar_k = idx - k
                            if close[bar_k] <= open_p[bar_k]:
                                bbH = high[bar_k]; bbL = low[bar_k]; break
                        if bbH > bbL:
                            for r in [1, 2]:
                                bar_r = idx - r
                                if low[bar_r] <= bbH + tol and close[bar_r] >= bbL - tol:
                                    entry_found = True; model_name = "Breaker"; break
                    if entry_found: break
                if entry_found: break
        if not entry_found:
            for i in range(2, 25):
                bar_i = idx - i
                if bar_i < 0: break
                if close[bar_i] < open_p[bar_i]:
                    obH, obL = high[bar_i], low[bar_i]
                    obMT = (obH + obL) * 0.5
                    obBodyTop = max(open_p[bar_i], close[bar_i])
                    if any(close[idx - d] > obBodyTop for d in range(1, i)):
                        for r in [1, 2]:
                            bar_r = idx - r
                            if low[bar_r] <= obH + tol and close[bar_r] >= obMT - tol:
                                entry_found = True; model_name = "OrderBlock"; break
                if entry_found: break
    else: # SELL
        for r in [1, 2]:
            bar_r = idx - r
            if high[bar_r] >= cisd_level - tol and close[bar_r] <= cisd_level + tol:
                entry_found = True; model_name = "CISD_Retest"; break
        if not entry_found:
            for j in range(2, 13):
                bar_j = idx - j
                if bar_j < 0: break
                for i in range(j + 2, 30):
                    bar_i = idx - i
                    if bar_i < 0: break
                    if high[bar_j] > high[bar_i]:
                        bbH, bbL = 0.0, 0.0
                        for k in range(j + 1, i + 2):
                            bar_k = idx - k
                            if close[bar_k] >= open_p[bar_k]:
                                bbH = high[bar_k]; bbL = low[bar_k]; break
                        if bbH > bbL:
                            for r in [1, 2]:
                                bar_r = idx - r
                                if high[bar_r] >= bbL - tol and close[bar_r] <= bbH + tol:
                                    entry_found = True; model_name = "Breaker"; break
                    if entry_found: break
                if entry_found: break
        if not entry_found:
            for i in range(2, 25):
                bar_i = idx - i
                if bar_i < 0: break
                if close[bar_i] > open_p[bar_i]:
                    obH, obL = high[bar_i], low[bar_i]
                    obMT = (obH + obL) * 0.5
                    obBodyBottom = min(open_p[bar_i], close[bar_i])
                    if any(close[idx - d] < obBodyBottom for d in range(1, i)):
                        for r in [1, 2]:
                            bar_r = idx - r
                            if high[bar_r] >= obL - tol and close[bar_r] <= obMT + tol:
                                entry_found = True; model_name = "OrderBlock"; break
                if entry_found: break

    if not entry_found: continue

    sl_dist = abs(entry_px - prot_swing)
    sl_dist = max(sl_dist, cur_atr * 0.50)
    sl_dist = min(sl_dist, cur_atr * 1.50)
    
    rr = 2.8
    tp_dist = sl_dist * rr
    
    if target_dir == 1:
        sl_px = entry_px - sl_dist
        tp_px = entry_px + tp_dist
        be_trigger = entry_px + cur_atr * 1.35
        be_sl = entry_px + 0.15 * cur_atr
    else:
        sl_px = entry_px + sl_dist
        tp_px = entry_px - tp_dist
        be_trigger = entry_px - cur_atr * 1.35
        be_sl = entry_px - 0.15 * cur_atr

    pnl = 0.0
    be_active = False
    cur_sl = sl_px

    for f in range(idx, min(idx + 120, len(df))):
        if target_dir == 1:
            if not be_active and high[f] >= be_trigger:
                be_active = True
                cur_sl = max(cur_sl, be_sl)
            if low[f] <= cur_sl:
                pnl = 0.15 if be_active else -1.0
                break
            elif high[f] >= tp_px:
                pnl = rr
                break
        else:
            if not be_active and low[f] <= be_trigger:
                be_active = True
                cur_sl = min(cur_sl, be_sl)
            if high[f] >= cur_sl:
                pnl = 0.15 if be_active else -1.0
                break
            elif low[f] <= tp_px:
                pnl = rr
                break

    trades.append({
        'time': t,
        'dir': 'BUY' if target_dir == 1 else 'SELL',
        'model': model_name,
        'pnl_r': pnl
    })
    daily_trades[day_key] = daily_trades.get(day_key, 0) + 1
    if pnl < 0:
        daily_losses[day_key] = daily_losses.get(day_key, 0) + 1
    daily_pnl[day_key] = daily_pnl.get(day_key, 0.0) + pnl

tdf = pd.DataFrame(trades)
print(f"Full Year London KZ Trades: {len(tdf)}")
wins = len(tdf[tdf['pnl_r'] > 0.5])
scratches = len(tdf[(tdf['pnl_r'] >= 0.0) & (tdf['pnl_r'] <= 0.5)])
losses = len(tdf[tdf['pnl_r'] < 0])
gp = tdf[tdf['pnl_r'] > 0]['pnl_r'].sum()
gl = abs(tdf[tdf['pnl_r'] < 0]['pnl_r'].sum())
pf = gp / gl if gl > 0 else 999.0
print(f"Wins: {wins}, Scratches (BE): {scratches}, Full Losses: {losses}")
print(f"Gross Profit: +{gp:.2f}R, Gross Loss: -{gl:.2f}R, Net Return: +{tdf['pnl_r'].sum():.2f}R")
print(f"Profit Factor: {pf:.2f}")

tdf['month'] = tdf['time'].dt.to_period('M')
monthly = tdf.groupby('month')['pnl_r'].agg(['count', 'sum']).reset_index()
print("\nMonthly Performance Breakdown:")
print(monthly)
