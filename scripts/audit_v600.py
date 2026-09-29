#!/usr/bin/env python3
"""
v6.00 Trade Audit & Performance Analysis (With Complete Deal Reconciliation)
Reconciles position entry, dynamic exit, and broker SL/TP/Trailing fills from deals.
"""

import re
import json
from datetime import datetime
from collections import defaultdict

LOG_FILE = r"C:\Users\NV LAP\AppData\Roaming\MetaQuotes\Tester\53785E099C927DB68A545C249CDBCE06\Agent-127.0.0.1-3000\logs\20260929.log"

def parse_dt(s):
    try:
        return datetime.strptime(s.strip(), '%Y.%m.%d %H:%M:%S')
    except:
        return datetime.strptime(s.strip()[:19], '%Y.%m.%d %H:%M:%S')

def parse_full_run(target_time="04:25:"):
    with open(LOG_FILE, 'r', encoding='utf-16', errors='ignore') as f:
        raw_lines = f.readlines()
        
    run_lines = []
    for line in raw_lines:
        line = line.rstrip('\r\n')
        if line.startswith('CS\t') or line.startswith('DE\t') or line.startswith('HE\t'):
            if target_time in line:
                run_lines.append(line)
        elif run_lines:
            run_lines[-1] += ' ' + line
            
    print(f"Target run log lines ({target_time}): {len(run_lines)}")
    
    # 1. Parse all executions
    exec_pat = re.compile(
        r'(\d{4}\.\d{2}\.\d{2} \d{2}:\d{2}:\d{2})\s+'
        r'\[SCALP EXEC OK\]\s+(SCALP_[HL]2.*?)\s+pos=#(\d+)\s+deal=#(\d+)\s+'
        r'lot=([\d.]+)\s+sl=([\d.]+)\s+tp=([\d.]+)\s+retcode=(\d+)'
    )
    
    # 2. Parse dynamic exits
    exit_pat = re.compile(
        r'(\d{4}\.\d{2}\.\d{2} \d{2}:\d{2}:\d{2})\s+'
        r'\[SCALP EXIT OK\]\s+Position #(\d+) closed\.\s+Reason:\s+'
        r'(SCALP_EXIT_\w+)\s*(?:\((.+?)\))?'
    )
    
    # 3. Parse trailing stops
    trail_pat = re.compile(
        r'(\d{4}\.\d{2}\.\d{2} \d{2}:\d{2}:\d{2})\s+'
        r'\[SCALP TRAIL OK\]\s+(BUY|SELL)\s+#(\d+)\s+trailed to\s+([\d.]+)'
    )
    
    # 4. Parse deals
    deal_pat = re.compile(
        r'(\d{4}\.\d{2}\.\d{2} \d{2}:\d{2}:\d{2})\s+'
        r'deal #(\d+)\s+(buy|sell)\s+([\d.]+)\s+EURUSD at ([\d.]+)\s+done \(based on order #(\d+)\)'
    )
    
    # 5. Parse rejects
    reject_pat = re.compile(r'\[SCALP REJECT\]\s+(.+)')
    
    trades = {}
    deals = []
    trails = defaultdict(list)
    rejects = defaultdict(int)
    
    for line in run_lines:
        m = exec_pat.search(line)
        if m:
            pos_id = int(m.group(3))
            entry_deal = int(m.group(4))
            trades[pos_id] = {
                'entry_time': m.group(1),
                'setup_tag': m.group(2),
                'pos_id': pos_id,
                'entry_deal': entry_deal,
                'lot': float(m.group(5)),
                'sl': float(m.group(6)),
                'tp': float(m.group(7)),
                'exit_time': None,
                'exit_reason': 'UNKNOWN',
                'exit_detail': '',
                'exit_price': 0.0,
                'trail_events': []
            }
            continue
            
        m = exit_pat.search(line)
        if m:
            pos_id = int(m.group(2))
            if pos_id in trades:
                trades[pos_id]['exit_time'] = m.group(1)
                trades[pos_id]['exit_reason'] = m.group(3)
                trades[pos_id]['exit_detail'] = m.group(4) or ''
            continue
            
        m = trail_pat.search(line)
        if m:
            pos_id = int(m.group(3))
            trails[pos_id].append({
                'time': m.group(1),
                'dir': m.group(2),
                'sl': float(m.group(4))
            })
            continue
            
        m = deal_pat.search(line)
        if m:
            deals.append({
                'time': m.group(1),
                'deal_id': int(m.group(2)),
                'type': m.group(3),
                'lot': float(m.group(4)),
                'price': float(m.group(5)),
                'order_id': int(m.group(6))
            })
            continue
            
        m = reject_pat.search(line)
        if m:
            reason = m.group(1).split(':')[1].strip() if ':' in m.group(1) else m.group(1)
            rejects[reason] += 1

    # Attach trails
    for pos_id, tr_list in trails.items():
        if pos_id in trades:
            trades[pos_id]['trail_events'] = tr_list

    # Match closing deals to positions
    # Position pos_id enters with entry_deal. Closing deal is subsequent deal with opposite type.
    sorted_deals = sorted(deals, key=lambda d: d['deal_id'])
    deal_by_id = {d['deal_id']: d for d in sorted_deals}
    
    for pos_id, t in trades.items():
        entry_d_id = t['entry_deal']
        # Find closing deal
        close_deal = deal_by_id.get(entry_d_id + 1)
        if close_deal:
            t['exit_price'] = close_deal['price']
            if not t['exit_time']:
                t['exit_time'] = close_deal['time']
            
            # Determine reason if unknown
            if t['exit_reason'] == 'UNKNOWN':
                is_buy = 'Buy' in t['setup_tag'] or 'H2' in t['setup_tag']
                entry_deal = deal_by_id.get(entry_d_id)
                entry_price = entry_deal['price'] if entry_deal else 0.0
                
                # Check if trailed stop was hit
                if t['trail_events']:
                    last_trail_sl = t['trail_events'][-1]['sl']
                    if abs(close_deal['price'] - last_trail_sl) <= 0.00015:
                        t['exit_reason'] = 'SCALP_EXIT_TRAILING_STOP'
                        t['exit_detail'] = f"Trailed SL hit at {close_deal['price']}"
                
                # Check initial SL
                if t['exit_reason'] == 'UNKNOWN':
                    if abs(close_deal['price'] - t['sl']) <= 0.00015:
                        t['exit_reason'] = 'SCALP_EXIT_STOP_LOSS'
                        t['exit_detail'] = f"Initial SL hit at {close_deal['price']}"
                    elif abs(close_deal['price'] - t['tp']) <= 0.00015:
                        t['exit_reason'] = 'SCALP_EXIT_TAKE_PROFIT'
                        t['exit_detail'] = f"TP hit at {close_deal['price']}"
                    else:
                        # Profit or Loss?
                        if is_buy:
                            pnl_pts = (close_deal['price'] - entry_price) / 0.00001
                        else:
                            pnl_pts = (entry_price - close_deal['price']) / 0.00001
                        if pnl_pts > 0:
                            t['exit_reason'] = 'SCALP_EXIT_TRAILING_STOP'
                            t['exit_detail'] = f"Profit stop at {close_deal['price']} (+{pnl_pts:.1f} pts)"
                        else:
                            t['exit_reason'] = 'SCALP_EXIT_STOP_LOSS'
                            t['exit_detail'] = f"Stop at {close_deal['price']} ({pnl_pts:.1f} pts)"

    trade_list = sorted(trades.values(), key=lambda t: t['entry_time'])
    return trade_list, dict(rejects)

def analyze(trades, rejects):
    total = len(trades)
    print(f"\n==================================================================")
    print(f"RECONCILED V6.00 PERFORMANCE AUDIT (EURUSD M5 | 2023.01.01 - 2023.03.31)")
    print(f"==================================================================")
    print(f"Total Completed Trades: {total}")
    
    by_reason = defaultdict(int)
    hold_mins = []
    trailed_count = 0
    fast_exits_1bar = 0
    fast_exits_2bars = 0
    
    for t in trades:
        by_reason[t['exit_reason']] += 1
        if t['trail_events']:
            trailed_count += 1
        if t['exit_time']:
            e_dt = parse_dt(t['entry_time'])
            x_dt = parse_dt(t['exit_time'])
            hm = (x_dt - e_dt).total_seconds() / 60.0
            hold_mins.append(hm)
            if hm <= 5: fast_exits_1bar += 1
            if hm <= 10: fast_exits_2bars += 1
            
    print("\n--- RECONCILED EXIT REASON DISTRIBUTION ---")
    for r, c in sorted(by_reason.items(), key=lambda x: -x[1]):
        print(f"  {r:<35}: {c:>2} ({c/total*100:>5.1f}%)")
        
    sh = sorted(hold_mins)
    med_hold = sh[len(sh)//2]
    avg_hold = sum(hold_mins)/len(hold_mins)
    print("\n--- HOLD DURATION COMPARISON (v5.00 vs v6.00) ---")
    print(f"  {'Metric':<25} {'v5.00 Baseline':<20} {'v6.00 Optimized':<20}")
    print(f"  {'-'*65}")
    print(f"  {'Median Hold Duration':<25} {'15.0 min (3 bars)':<20} {med_hold:.1f} min ({med_hold/5.0:.1f} bars)")
    print(f"  {'Average Hold Duration':<25} {'17.0 min (3.4 bars)':<20} {avg_hold:.1f} min ({avg_hold/5.0:.1f} bars)")
    print(f"  {'1-Bar Exits (<=5 min)':<25} {'8/67 (11.9%)':<20} {fast_exits_1bar}/{total} ({fast_exits_1bar/total*100:.1f}%)")
    print(f"  {'<=2 Bar Exits (<=10 min)':<25} {'27/67 (40.3%)':<20} {fast_exits_2bars}/{total} ({fast_exits_2bars/total*100:.1f}%)")
    print(f"  {'Opposite PA Exits':<25} {'47/67 (70.1%)':<20} {by_reason.get('SCALP_EXIT_OPPOSITE_PA_REVERSAL',0)}/{total} ({by_reason.get('SCALP_EXIT_OPPOSITE_PA_REVERSAL',0)/total*100:.1f}%)")
    print(f"  {'Trades Trailed':<25} {'7/67 (10.4%)':<20} {trailed_count}/{total} ({trailed_count/total*100:.1f}%)")
    
    print("\n--- QUALITY FILTER METRICS ---")
    print(f"  Total Setups Evaluated: {total + sum(rejects.values())}")
    print(f"  Setups Passed: {total} ({total/(total+sum(rejects.values()))*100:.1f}%)")
    print(f"  Setups Filtered Out: {sum(rejects.values())} ({sum(rejects.values())/(total+sum(rejects.values()))*100:.1f}%)")
    for rj, count in sorted(rejects.items(), key=lambda x: -x[1])[:5]:
        print(f"    - {rj}: {count}")

if __name__ == '__main__':
    trades, rejects = parse_full_run("04:25:")
    analyze(trades, rejects)
