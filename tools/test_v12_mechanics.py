import pandas as pd
import numpy as np

df = pd.read_csv('c:/Users/NV LAP/Documents/antigravity/cool-noether/xauusd_m5.csv.gz')
df['datetime'] = pd.to_datetime(df['datetime'])
df = df.sort_values('datetime').reset_index(drop=True)

df_idx = df.set_index('datetime')
d1 = df_idx.resample('1D').agg({'open':'first', 'high':'max', 'low':'min', 'close':'last'}).dropna()

high = df['high'].values
low = df['low'].values
close = df['close'].values
open_p = df['open'].values
times = df['datetime'].values

tr = np.zeros(len(df))
tr[0] = high[0] - low[0]
for i in range(1, len(df)):
    tr[i] = max(high[i] - low[i], abs(high[i] - close[i-1]), abs(low[i] - close[i-1]))
atr = np.zeros(len(df))
alpha = 1.0 / 14.0
atr[0] = tr[0]
for i in range(1, len(df)):
    atr[i] = (1 - alpha) * atr[i-1] + alpha * tr[i]

def run_test(start_str, end_str, label):
    start_dt = pd.to_datetime(start_str)
    end_dt = pd.to_datetime(end_str)
    indices = [i for i, t in enumerate(times) if pd.Timestamp(t) >= start_dt and pd.Timestamp(t) < end_dt]

    trades = []
    daily_trades = {}
    daily_losses = {}
    daily_pnl = {}
    active_cisd = None
    last_exit_idx = -999

    for idx in indices:
        t = pd.Timestamp(times[idx])
        day_key = t.strftime('%Y-%m-%d')
        if daily_losses.get(day_key, 0) >= 1: continue
        if daily_trades.get(day_key, 0) >= 2: continue
        if idx - last_exit_idx < 4: continue # 4 bar cooldown

        in_london = (t.hour >= 8 and t.hour < 11) or (t.hour == 11 and t.minute <= 30)
        in_ny = (t.hour >= 13 and t.hour < 17) or (t.hour == 17 and t.minute == 0)
        if not (in_london or in_ny): continue
        if t.dayofweek == 0 or (t.dayofweek == 4 and t.hour >= 12): continue

        cur_atr = atr[idx]
        tol = cur_atr * 0.30

        # 1. Bias
        d1_prior = d1[d1.index < t.floor('1D')]
        if len(d1_prior) < 2: continue
        c1_d, h2_d, l2_d, o1_d = d1_prior.iloc[-1]['close'], d1_prior.iloc[-2]['high'], d1_prior.iloc[-2]['low'], d1_prior.iloc[-1]['open']
        target_dir = 1 if (c1_d > h2_d or (c1_d >= l2_d and c1_d > o1_d)) else -1

        # Invalidate active CISD
        if active_cisd is not None:
            if active_cisd['dir'] == 1 and close[idx-1] < active_cisd['prot_swing']:
                active_cisd = None
            elif active_cisd['dir'] == -1 and close[idx-1] > active_cisd['prot_swing']:
                active_cisd = None

        # Detect fresh CISD
        lookback = 30
        if target_dir == 1:
            sub_l = low[idx-lookback:idx-1]
            if len(sub_l) > 0:
                min_l = sub_l.min()
                min_bar_rel = lookback - np.argmin(sub_l)
                highest_down_open = min_l
                for k in range(min_bar_rel, min(min_bar_rel + 7, lookback)):
                    if idx - k < 0: break
                    if close[idx - k] <= open_p[idx - k]:
                        highest_down_open = max(highest_down_open, open_p[idx - k])
                if highest_down_open <= min_l:
                    highest_down_open = high[idx - min_bar_rel]
                if any(close[idx - c] > highest_down_open for c in range(1, min_bar_rel)):
                    active_cisd = {'dir': 1, 'cisd_level': highest_down_open, 'prot_swing': min_l}
        else:
            sub_h = high[idx-lookback:idx-1]
            if len(sub_h) > 0:
                max_h = sub_h.max()
                max_bar_rel = lookback - np.argmax(sub_h)
                lowest_up_open = max_h
                for k in range(max_bar_rel, min(max_bar_rel + 7, lookback)):
                    if idx - k < 0: break
                    if close[idx - k] >= open_p[idx - k]:
                        lowest_up_open = min(lowest_up_open, open_p[idx - k])
                if lowest_up_open >= max_h:
                    lowest_up_open = low[idx - max_bar_rel]
                if any(close[idx - c] < lowest_up_open for c in range(1, max_bar_rel)):
                    active_cisd = {'dir': -1, 'cisd_level': lowest_up_open, 'prot_swing': max_h}

        if active_cisd is None or active_cisd['dir'] != target_dir: continue

        # Check Retest
        entry_found = False
        for r in range(1, 4):
            bar_r = idx - r
            if target_dir == 1:
                if low[bar_r] <= active_cisd['cisd_level'] + tol and close[bar_r] >= active_cisd['cisd_level'] - tol:
                    entry_found = True; break
            else:
                if high[bar_r] >= active_cisd['cisd_level'] - tol and close[bar_r] <= active_cisd['cisd_level'] + tol:
                    entry_found = True; break

        if not entry_found: continue

        entry_px = close[idx-1]
        prot_swing = active_cisd['prot_swing']
        sl_dist = abs(entry_px - prot_swing)
        sl_dist = max(sl_dist, cur_atr * 0.70)
        sl_dist = min(sl_dist, cur_atr * 1.60)
        
        rr = 2.40 # Solid 2.4R target
        tp_dist = sl_dist * rr
        
        if target_dir == 1:
            sl_px = entry_px - sl_dist
            tp_px = entry_px + tp_dist
            be_trigger = entry_px + cur_atr * 1.50
            be_sl = entry_px + 0.20 * cur_atr
        else:
            sl_px = entry_px + sl_dist
            tp_px = entry_px - tp_dist
            be_trigger = entry_px - cur_atr * 1.50
            be_sl = entry_px - 0.20 * cur_atr

        pnl = 0.0
        be_active = False
        cur_sl = sl_px
        exit_idx = idx

        for f in range(idx, min(idx + 120, len(df))):
            exit_idx = f
            if target_dir == 1:
                if not be_active and high[f] >= be_trigger:
                    be_active = True
                    cur_sl = max(cur_sl, be_sl)
                if low[f] <= cur_sl:
                    pnl = 0.20 if be_active else -1.0
                    break
                elif high[f] >= tp_px:
                    pnl = rr
                    break
            else:
                if not be_active and low[f] <= be_trigger:
                    be_active = True
                    cur_sl = min(cur_sl, be_sl)
                if high[f] >= cur_sl:
                    pnl = 0.20 if be_active else -1.0
                    break
                elif low[f] <= tp_px:
                    pnl = rr
                    break

        trades.append({'time': t, 'dir': 'BUY' if target_dir == 1 else 'SELL', 'pnl_r': pnl})
        daily_trades[day_key] = daily_trades.get(day_key, 0) + 1
        if pnl < 0:
            daily_losses[day_key] = daily_losses.get(day_key, 0) + 1
        daily_pnl[day_key] = daily_pnl.get(day_key, 0.0) + pnl
        active_cisd = None
        last_exit_idx = exit_idx

    tdf = pd.DataFrame(trades)
    print(f"\n================ {label} ================")
    print(f"Total Trades: {len(tdf)}")
    gp = tdf[tdf['pnl_r'] > 0]['pnl_r'].sum()
    gl = abs(tdf[tdf['pnl_r'] < 0]['pnl_r'].sum())
    pf = gp / gl if gl > 0 else 999.0
    wins = len(tdf[tdf['pnl_r'] > 1.0])
    bes = len(tdf[(tdf['pnl_r'] >= 0.0) & (tdf['pnl_r'] <= 1.0)])
    losses = len(tdf[tdf['pnl_r'] < 0])
    print(f"Wins: {wins}, BEs: {bes}, Losses: {losses}")
    print(f"Gross Profit: +{gp:.2f}R | Gross Loss: -{gl:.2f}R | Net Return: +{tdf['pnl_r'].sum():.2f}R | Profit Factor: {pf:.2f}")
    tdf['month'] = tdf['time'].dt.to_period('M')
    print(tdf.groupby('month')['pnl_r'].agg(['count', 'sum']))

run_test('2026-06-01', '2026-10-01', '4-Month Out-of-Sample')
run_test('2025-10-01', '2026-10-01', 'Full Year Oct 2025 - Oct 2026')
