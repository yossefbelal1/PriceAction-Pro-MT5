import pandas as pd

df = pd.read_csv('c:/Users/NV LAP/Documents/antigravity/cool-noether/xauusd_m5.csv.gz')
df['datetime'] = pd.to_datetime(df['datetime'])
sub = df[(df['datetime'] >= '2026-06-04 12:00:00') & (df['datetime'] <= '2026-06-04 15:30:00')].reset_index(drop=True)

idx = sub[sub['datetime'] == '2026-06-04 15:10:00'].index[0]
bars = [sub.iloc[idx - i] for i in range(idx + 1)]
atr = 3.5
tol = atr * 0.25

print("Testing Breaker on June 4 15:10:")
for j in range(2, 13):
    for i in range(j + 2, 30):
        if bars[j]['low'] < bars[i]['low']:
            bbH, bbL = 0.0, 0.0
            for k in range(j + 1, i + 2):
                if bars[k]['close'] <= bars[k]['open']:
                    bbH = bars[k]['high']
                    bbL = bars[k]['low']
                    break
            if bbH > bbL:
                print(f"Breaker zone: [{bbL:.2f}, {bbH:.2f}] at j={j} ({bars[j]['datetime']})")
                for r in [1, 2]:
                    cond = (bars[r]['low'] <= bbH + tol) and (bars[r]['close'] >= bbL - tol)
                    print(f"  r={r} ({bars[r]['datetime']}) low={bars[r]['low']:.2f} close={bars[r]['close']:.2f} cond={cond}")
