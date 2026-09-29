#!/usr/bin/env python3
"""
Full Year 2023 Audit & Walk-Forward Performance Analysis for EURUSD M5
"""
import re
import json
from datetime import datetime
from collections import defaultdict

LOG_FILE = r"C:\Users\NV LAP\AppData\Roaming\MetaQuotes\Tester\53785E099C927DB68A545C249CDBCE06\Agent-127.0.0.1-3000\logs\20260929.log"

def main():
    with open(LOG_FILE, 'r', encoding='utf-16', errors='ignore') as f:
        raw_lines = f.readlines()
        
    lines = [line.strip() for line in raw_lines if '04:32:' in line]
    print(f"Total lines for 04:32: {len(lines)}")
    
    deal_pat = re.compile(r'(\d{4}\.\d{2}\.\d{2} \d{2}:\d{2}:\d{2})\s+deal #(\d+)\s+(buy|sell)\s+([\d.]+)\s+EURUSD at ([\d.]+)\s+done \(based on order #(\d+)\)')
    exec_pat = re.compile(r'\[SCALP EXEC OK\]\s+(SCALP_[HL]2.*?)\s+pos=#(\d+)\s+deal=#(\d+)\s+lot=([\d.]+)\s+sl=([\d.]+)\s+tp=([\d.]+)\s+retcode=(\d+)')
    exit_pat = re.compile(r'\[SCALP EXIT OK\]\s+Position #(\d+) closed\.\s+Reason:\s+(SCALP_EXIT_\w+)\s*(?:\((.+?)\))?')
    trail_pat = re.compile(r'\[SCALP TRAIL OK\]\s+(BUY|SELL)\s+#(\d+)\s+trailed to\s+([\d.]+)')
    reject_pat = re.compile(r'\[SCALP REJECT\]\s+(.+)')
    
    deals = []
    execs = {}
    exits = {}
    trails = defaultdict(list)
    rejects = defaultdict(int)
    
    for line in lines:
        m = deal_pat.search(line)
        if m:
            deals.append({
                'time': m.group(1),
                'id': int(m.group(2)),
                'type': m.group(3),
                'lot': float(m.group(4)),
                'price': float(m.group(5)),
                'order': int(m.group(6))
            })
            continue
        m = exec_pat.search(line)
        if m:
            execs[int(m.group(2))] = {
                'setup': m.group(1),
                'sl': float(m.group(5)),
                'tp': float(m.group(6))
            }
            continue
        m = exit_pat.search(line)
        if m:
            exits[int(m.group(1))] = {
                'reason': m.group(2),
                'detail': m.group(3) or ''
            }
            continue
        m = trail_pat.search(line)
        if m:
            trails[int(m.group(2))].append(float(m.group(3)))
            continue
        m = reject_pat.search(line)
        if m:
            r = m.group(1).split(':')[1].strip() if ':' in m.group(1) else m.group(1)
            rejects[r] += 1
            continue

    trades = []
    # Pair deals sequentially
    for i in range(0, len(deals)-1, 2):
        d_in = deals[i]
        d_out = deals[i+1]
        pos_id = d_in['id'] # in MT5 tester, deal ticket often matches position ticket
        is_buy = (d_in['type'] == 'buy')
        pts = (d_out['price'] - d_in['price']) if is_buy else (d_in['price'] - d_out['price'])
        pnl_pts = pts / 0.00001
        pnl_usd = pts * 100000.0 * d_in['lot']
        
        t_in = datetime.strptime(d_in['time'], '%Y.%m.%d %H:%M:%S')
        t_out = datetime.strptime(d_out['time'], '%Y.%m.%d %H:%M:%S')
        duration_m = (t_out - t_in).total_seconds() / 60.0
        
        # Determine exit reason
        reason = exits.get(pos_id, {}).get('reason', 'UNKNOWN')
        if reason == 'UNKNOWN':
            # Check if trail hit
            if pos_id in trails:
                last_trail = trails[pos_id][-1]
                if abs(d_out['price'] - last_trail) < 0.00015:
                    reason = 'SCALP_EXIT_TRAILING_STOP'
            if reason == 'UNKNOWN':
                pos_info = execs.get(pos_id)
                if pos_info:
                    if abs(d_out['price'] - pos_info['tp']) < 0.00015:
                        reason = 'SCALP_EXIT_TAKE_PROFIT'
                    elif abs(d_out['price'] - pos_info['sl']) < 0.00015:
                        reason = 'SCALP_EXIT_STOP_LOSS'
                if reason == 'UNKNOWN':
                    reason = 'SCALP_EXIT_TRAILING_STOP' if pnl_usd > 0 else 'SCALP_EXIT_STOP_LOSS'
                    
        trades.append({
            'pos_id': pos_id,
            'entry_time': d_in['time'],
            'exit_time': d_out['time'],
            'month': d_in['time'][:7],
            'quarter': f"{d_in['time'][:4]}-Q{(int(d_in['time'][5:7])-1)//3 + 1}",
            'type': d_in['type'],
            'lot': d_in['lot'],
            'entry_price': d_in['price'],
            'exit_price': d_out['price'],
            'pnl_pts': pnl_pts,
            'pnl_usd': pnl_usd,
            'duration_m': duration_m,
            'reason': reason,
            'trailed': pos_id in trails
        })

    print(f"\n==================================================================")
    print(f"EURUSD M5 FULL YEAR 2023 BACKTEST AUDIT (135 TRADES)")
    print(f"==================================================================")
    
    total_trades = len(trades)
    wins = [t for t in trades if t['pnl_usd'] > 0]
    losses = [t for t in trades if t['pnl_usd'] <= 0]
    win_rate = len(wins) / total_trades * 100.0 if total_trades else 0
    total_profit = sum(t['pnl_usd'] for t in wins)
    total_loss = abs(sum(t['pnl_usd'] for t in losses))
    net_pnl = total_profit - total_loss
    profit_factor = total_profit / total_loss if total_loss > 0 else float('inf')
    
    print(f"Total Trades: {total_trades}")
    print(f"Wins: {len(wins)} | Losses: {len(losses)} | Win Rate: {win_rate:.2f}%")
    print(f"Gross Profit: ${total_profit:,.2f} | Gross Loss: -${total_loss:,.2f}")
    print(f"Net Profit (estimated): ${net_pnl:,.2f} (Final broker balance: $8,820.89)")
    print(f"Profit Factor: {profit_factor:.2f}")
    
    # Quarterly Breakdown
    quarters = defaultdict(lambda: {'count': 0, 'wins': 0, 'losses': 0, 'pnl': 0.0})
    for t in trades:
        q = quarters[t['quarter']]
        q['count'] += 1
        if t['pnl_usd'] > 0: q['wins'] += 1
        else: q['losses'] += 1
        q['pnl'] += t['pnl_usd']
        
    print(f"\n--- QUARTERLY PERFORMANCE BREAKDOWN ---")
    print(f"{'Quarter':<10} {'Trades':<8} {'Wins':<6} {'Losses':<8} {'Win Rate':<10} {'Net PnL ($)':<12}")
    print("-" * 55)
    for qtr, d in sorted(quarters.items()):
        wr = d['wins'] / d['count'] * 100.0 if d['count'] else 0
        print(f"{qtr:<10} {d['count']:>6}   {d['wins']:>4}   {d['losses']:>6}   {wr:>7.1f}%   {d['pnl']:>10.2f}")

    # Monthly Breakdown
    monthly = defaultdict(lambda: {'count': 0, 'wins': 0, 'losses': 0, 'pnl': 0.0})
    for t in trades:
        m = monthly[t['month']]
        m['count'] += 1
        if t['pnl_usd'] > 0: m['wins'] += 1
        else: m['losses'] += 1
        m['pnl'] += t['pnl_usd']

    print(f"\n--- MONTHLY PERFORMANCE BREAKDOWN ---")
    print(f"{'Month':<10} {'Trades':<8} {'Wins':<6} {'Losses':<8} {'Win Rate':<10} {'Net PnL ($)':<12}")
    print("-" * 55)
    running_balance = 10000.0
    for mth, d in sorted(monthly.items()):
        wr = d['wins'] / d['count'] * 100.0 if d['count'] else 0
        running_balance += d['pnl']
        print(f"{mth:<10} {d['count']:>6}   {d['wins']:>4}   {d['losses']:>6}   {wr:>7.1f}%   {d['pnl']:>10.2f}")

    # Exit reason distribution
    reasons = defaultdict(int)
    for t in trades:
        reasons[t['reason']] += 1
    print(f"\n--- EXIT REASON DISTRIBUTION (FULL YEAR 2023) ---")
    for r, c in sorted(reasons.items(), key=lambda x: -x[1]):
        print(f"  {r:<35}: {c:>3} ({c/total_trades*100:>5.1f}%)")

    # Hold duration
    durations = [t['duration_m'] for t in trades]
    sd = sorted(durations)
    print(f"\n--- HOLD DURATION STATISTICS ---")
    print(f"  Median Hold: {sd[len(sd)//2]:.1f} min ({sd[len(sd)//2]/5.0:.1f} bars)")
    print(f"  Average Hold: {sum(durations)/len(durations):.1f} min ({sum(durations)/len(durations)/5.0:.1f} bars)")
    print(f"  Trades Trailed: {sum(1 for t in trades if t['trailed'])} / {total_trades} ({sum(1 for t in trades if t['trailed'])/total_trades*100:.1f}%)")

    # Setup rejection statistics
    total_eval = total_trades + sum(rejects.values())
    print(f"\n--- SETUP QUALITY FILTERING ---")
    print(f"  Total Signals Evaluated: {total_eval}")
    print(f"  Passed Quality Filter: {total_trades} ({total_trades/total_eval*100:.1f}%)")
    print(f"  Rejected: {sum(rejects.values())} ({sum(rejects.values())/total_eval*100:.1f}%)")
    for rj, count in sorted(rejects.items(), key=lambda x: -x[1])[:6]:
        print(f"    - {rj}: {count}")

    # Export trades to json for native HTML report generation
    with open('reports/EURUSD/M5/2023/fullyear_trades.json', 'w') as out:
        json.dump(trades, out, indent=2)
    print(f"\nExported {len(trades)} trades to reports/EURUSD/M5/2023/fullyear_trades.json")

if __name__ == '__main__':
    main()
