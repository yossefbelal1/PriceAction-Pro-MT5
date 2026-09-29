#!/usr/bin/env python3
"""
Phase 1 — Quantitative Trade Audit
Analyzes v5.00 EURUSD M5 scalping trades from MT5 agent log.
Reads raw log file, joins multi-line entries, parses all SCALP events.
"""

import re
import json
from datetime import datetime, timedelta
from collections import defaultdict

LOG_FILE = r"C:\Users\NV LAP\AppData\Roaming\MetaQuotes\Tester\53785E099C927DB68A545C249CDBCE06\Agent-127.0.0.1-3000\logs\20260929.log"

def parse_log():
    """Parse the MT5 agent log and extract all scalp trade data."""
    
    # Read entire file, join lines that are continuations
    with open(LOG_FILE, 'r', encoding='utf-16', errors='ignore') as f:
        raw_lines = f.readlines()
    
    # Join continuation lines (lines not starting with CS\t are continuations)
    joined_lines = []
    for line in raw_lines:
        line = line.rstrip('\r\n')
        if line.startswith('CS\t') or line.startswith('DE\t') or line.startswith('HE\t'):
            joined_lines.append(line)
        elif joined_lines:
            joined_lines[-1] += ' ' + line
    
    print(f"Total joined log lines: {len(joined_lines)}")
    
    # Filter for SCALP-related lines
    scalp_lines = [l for l in joined_lines if '[SCALP' in l]
    print(f"SCALP-related lines: {len(scalp_lines)}")
    
    # Debug: print first 3 SCALP lines
    for i, l in enumerate(scalp_lines[:3]):
        print(f"  Line {i}: {l[:200]}")
    
    trades = {}  # pos_id -> trade dict
    trails = defaultdict(list)  # pos_id -> list of trail events
    
    # Patterns - work on joined lines
    exec_pat = re.compile(
        r'(\d{4}\.\d{2}\.\d{2} \d{2}:\d{2}:\d{2})\s+'
        r'\[SCALP EXEC OK\]\s+(SCALP_[HL]2)\s+M5\s+(Buy|Sell)\s+'
        r'pos=#(\d+)\s+deal=#(\d+)\s+'
        r'lot=([\d.]+)\s+sl=([\d.]+)\s+tp=([\d.]+)\s+retcode=(\d+)'
    )
    
    exit_pat = re.compile(
        r'(\d{4}\.\d{2}\.\d{2} \d{2}:\d{2}:\d{2})\s+'
        r'\[SCALP EXIT OK\]\s+Position #(\d+) closed\.\s+Reason:\s+'
        r'(SCALP_EXIT_\w+)\s+\((.+?)\)\s+retcode=(\d+)'
    )
    
    exit_session_pat = re.compile(
        r'(\d{4}\.\d{2}\.\d{2} \d{2}:\d{2}:\d{2})\s+'
        r'\[SCALP EXIT OK\]\s+Position #(\d+) closed\.\s+Reason:\s+'
        r'(SCALP_EXIT_SESSION_END)\s+retcode=(\d+)'
    )
    
    trail_pat = re.compile(
        r'(\d{4}\.\d{2}\.\d{2} \d{2}:\d{2}:\d{2})\s+'
        r'\[SCALP TRAIL OK\]\s+(BUY|SELL)\s+#(\d+)\s+trailed to\s+([\d.]+)\s+retcode=(\d+)'
    )
    
    for line in scalp_lines:
        # Try EXEC match
        m = exec_pat.search(line)
        if m:
            pos_id = int(m.group(4))
            trades[pos_id] = {
                'entry_time': m.group(1),
                'setup': m.group(2),
                'direction': m.group(3),
                'pos_id': pos_id,
                'deal_id': int(m.group(5)),
                'lot': float(m.group(6)),
                'sl': float(m.group(7)),
                'tp': float(m.group(8)),
                'retcode': int(m.group(9)),
                'exit_time': None,
                'exit_reason': 'UNKNOWN',
                'exit_detail': '',
                'trail_events': []
            }
            continue
        
        # Try EXIT match (with detail)
        m = exit_pat.search(line)
        if m:
            pos_id = int(m.group(2))
            if pos_id in trades:
                trades[pos_id]['exit_time'] = m.group(1)
                trades[pos_id]['exit_reason'] = m.group(3)
                trades[pos_id]['exit_detail'] = m.group(4)
            continue
        
        # Try session end exit
        m = exit_session_pat.search(line)
        if m:
            pos_id = int(m.group(2))
            if pos_id in trades:
                trades[pos_id]['exit_time'] = m.group(1)
                trades[pos_id]['exit_reason'] = m.group(3)
                trades[pos_id]['exit_detail'] = 'Session End'
            continue
        
        # Try TRAIL match
        m = trail_pat.search(line)
        if m:
            pos_id = int(m.group(3))
            trails[pos_id].append({
                'trail_time': m.group(1),
                'trail_dir': m.group(2),
                'new_sl': float(m.group(4)),
                'retcode': int(m.group(5))
            })
    
    # Attach trails to trades
    for pos_id, trail_list in trails.items():
        if pos_id in trades:
            trades[pos_id]['trail_events'] = trail_list
    
    trade_list = sorted(trades.values(), key=lambda t: t['entry_time'])
    return trade_list


def parse_dt(s):
    """Parse MT5 datetime string."""
    try:
        return datetime.strptime(s.strip(), '%Y.%m.%d %H:%M:%S')
    except:
        return datetime.strptime(s.strip()[:19], '%Y.%m.%d %H:%M:%S')


def extract_r_from_detail(detail):
    """Extract R-multiple from exit detail string."""
    m = re.search(r'R=([\d.]+)', detail)
    if m:
        return float(m.group(1))
    return None


def analyze_trades(trades):
    """Perform comprehensive quantitative analysis."""
    
    total = len(trades)
    results = {
        'total_trades': total,
        'by_setup': defaultdict(int),
        'by_direction': defaultdict(int),
        'by_exit_reason': defaultdict(int),
        'hold_durations_minutes': [],
        'r_at_exit': [],
        'one_bar_exits': 0,
        'two_bar_exits': 0,
        'three_plus_bar_exits': 0,
        'trailed_trades': 0,
        'monthly_distribution': defaultdict(int),
        'exit_detail_distribution': defaultdict(int),
    }
    
    for t in trades:
        results['by_setup'][t['setup']] += 1
        results['by_direction'][t['direction']] += 1
        results['by_exit_reason'][t.get('exit_reason', 'UNKNOWN')] += 1
        results['exit_detail_distribution'][t.get('exit_detail', 'UNKNOWN')] += 1
        
        if t['trail_events']:
            results['trailed_trades'] += 1
        
        entry_dt = parse_dt(t['entry_time'])
        entry_month = entry_dt.strftime('%Y-%m')
        results['monthly_distribution'][entry_month] += 1
        
        if t.get('exit_time'):
            exit_dt = parse_dt(t['exit_time'])
            hold_minutes = (exit_dt - entry_dt).total_seconds() / 60
            results['hold_durations_minutes'].append(hold_minutes)
            
            bars_held = hold_minutes / 5
            if bars_held <= 1.5:
                results['one_bar_exits'] += 1
            elif bars_held <= 2.5:
                results['two_bar_exits'] += 1
            else:
                results['three_plus_bar_exits'] += 1
        
        r_val = extract_r_from_detail(t.get('exit_detail', ''))
        if r_val is not None:
            results['r_at_exit'].append((t['exit_reason'], r_val, t['entry_time']))
    
    return results


def generate_report(trades, results):
    """Generate Phase 1 audit report."""
    
    total = results['total_trades']
    if total == 0:
        return "ERROR: No trades found!"
    
    lines = []
    lines.append("# PHASE 1 — QUANTITATIVE TRADE AUDIT")
    lines.append("")
    lines.append("**v5.00 EURUSD M5 | 2023.01.01 – 2023.03.31 | 67 trades (expected)**")
    lines.append("")
    
    # 1. OVERVIEW
    lines.append("## 1. Overview")
    lines.append("")
    trading_days = len(set(parse_dt(t['entry_time']).date() for t in trades))
    lines.append(f"| Metric | Value |")
    lines.append(f"|---|---|")
    lines.append(f"| Total Trades | {total} |")
    lines.append(f"| Date Range | {trades[0]['entry_time']} → {trades[-1]['entry_time']} |")
    lines.append(f"| Trading Days | {trading_days} |")
    lines.append(f"| Avg Trades/Day | {total/trading_days:.1f} |")
    lines.append("")
    
    # 2. SETUP DISTRIBUTION
    lines.append("## 2. Setup Distribution")
    lines.append("")
    lines.append("| Setup | Count | % |")
    lines.append("|---|---|---|")
    for setup, count in sorted(results['by_setup'].items()):
        lines.append(f"| {setup} | {count} | {count/total*100:.1f}% |")
    lines.append("")
    
    # 3. DIRECTION
    lines.append("## 3. Direction Distribution")
    lines.append("")
    lines.append("| Direction | Count | % |")
    lines.append("|---|---|---|")
    for direction, count in sorted(results['by_direction'].items()):
        lines.append(f"| {direction} | {count} | {count/total*100:.1f}% |")
    lines.append("")
    
    # 4. EXIT REASON (THE KEY METRIC)
    lines.append("## 4. Exit Reason Distribution ⚠️ KEY")
    lines.append("")
    lines.append("| Exit Reason | Count | % |")
    lines.append("|---|---|---|")
    for reason, count in sorted(results['by_exit_reason'].items(), key=lambda x: -x[1]):
        lines.append(f"| {reason} | {count} | {count/total*100:.1f}% |")
    lines.append("")
    
    # 5. HOLD DURATION
    lines.append("## 5. Hold Duration Analysis ⚠️ CRITICAL")
    lines.append("")
    durations = results['hold_durations_minutes']
    if durations:
        sorted_d = sorted(durations)
        median_d = sorted_d[len(sorted_d)//2]
        avg_d = sum(durations) / len(durations)
        
        lines.append("| Metric | Minutes | M5 Bars |")
        lines.append("|---|---|---|")
        lines.append(f"| Min Hold | {min(durations):.0f} | {min(durations)/5:.1f} |")
        lines.append(f"| Max Hold | {max(durations):.0f} | {max(durations)/5:.1f} |")
        lines.append(f"| Average Hold | {avg_d:.0f} | {avg_d/5:.1f} |")
        lines.append(f"| Median Hold | {median_d:.0f} | {median_d/5:.1f} |")
        lines.append("")
        
        lines.append("### Hold Distribution")
        lines.append("")
        lines.append("| Hold Category | Count | % |")
        lines.append("|---|---|---|")
        lines.append(f"| 1-bar exits (≤5 min) | {results['one_bar_exits']} | {results['one_bar_exits']/total*100:.1f}% |")
        lines.append(f"| 2-bar exits (5-10 min) | {results['two_bar_exits']} | {results['two_bar_exits']/total*100:.1f}% |")
        lines.append(f"| 3+ bar exits (>10 min) | {results['three_plus_bar_exits']} | {results['three_plus_bar_exits']/total*100:.1f}% |")
        lines.append("")
        
        # Distribution histogram
        lines.append("### Hold Duration Histogram (5-min buckets)")
        lines.append("```")
        buckets = defaultdict(int)
        for d in durations:
            bucket = int(d // 5) * 5
            buckets[bucket] += 1
        for bucket in sorted(buckets.keys()):
            bar = '█' * buckets[bucket]
            lines.append(f"  {bucket:3d}-{bucket+5:3d} min: {bar} ({buckets[bucket]})")
        lines.append("```")
        lines.append("")
    
    # 6. R AT EXIT
    lines.append("## 6. R-Multiple at Exit")
    lines.append("")
    if results['r_at_exit']:
        r_vals = [r for _, r, _ in results['r_at_exit']]
        lines.append(f"Trades with reported R at exit: {len(r_vals)}/{total}")
        lines.append("")
        lines.append("| Metric | Value |")
        lines.append("|---|---|")
        lines.append(f"| Min R | {min(r_vals):.2f} |")
        lines.append(f"| Max R | {max(r_vals):.2f} |")
        lines.append(f"| Avg R | {sum(r_vals)/len(r_vals):.2f} |")
        lines.append(f"| Median R | {sorted(r_vals)[len(r_vals)//2]:.2f} |")
        lines.append("")
        
        by_reason = defaultdict(list)
        for reason, r, _ in results['r_at_exit']:
            by_reason[reason].append(r)
        lines.append("| Exit Reason | Count | Avg R | Min R | Max R |")
        lines.append("|---|---|---|---|---|")
        for reason, rs in by_reason.items():
            lines.append(f"| {reason} | {len(rs)} | {sum(rs)/len(rs):.2f} | {min(rs):.2f} | {max(rs):.2f} |")
        lines.append("")
    else:
        lines.append("No R-values found in exit details.")
        lines.append("")
    
    # 7. TRAILING
    lines.append("## 7. Trailing Activity")
    lines.append("")
    lines.append(f"Trades that triggered trailing: **{results['trailed_trades']}/{total}** ({results['trailed_trades']/total*100:.1f}%)")
    lines.append("")
    trail_trades = [t for t in trades if t['trail_events']]
    if trail_trades:
        lines.append("| Pos# | Setup | Dir | Trails | Exit Reason | R at Exit |")
        lines.append("|---|---|---|---|---|---|")
        for t in trail_trades:
            r_val = extract_r_from_detail(t.get('exit_detail', ''))
            r_str = f"{r_val:.2f}" if r_val else 'N/A'
            lines.append(f"| #{t['pos_id']} | {t['setup']} | {t['direction']} | {len(t['trail_events'])} | {t['exit_reason']} | {r_str} |")
        lines.append("")
    
    # 8. MONTHLY
    lines.append("## 8. Monthly Distribution")
    lines.append("")
    lines.append("| Month | Trades |")
    lines.append("|---|---|")
    for month, count in sorted(results['monthly_distribution'].items()):
        lines.append(f"| {month} | {count} |")
    lines.append("")
    
    # 9. FAST EXIT ANALYSIS
    lines.append("## 9. Fast Exit Analysis ⚠️ ROOT CAUSE")
    lines.append("")
    fast_exits = []
    for t in trades:
        if t.get('exit_time'):
            hold = (parse_dt(t['exit_time']) - parse_dt(t['entry_time'])).total_seconds() / 60
            if hold <= 10:
                fast_exits.append((t, hold))
    
    lines.append(f"**{len(fast_exits)}/{total} ({len(fast_exits)/total*100:.1f}%)** trades exited within 2 bars (≤10 min)")
    lines.append("")
    
    if fast_exits:
        fast_by_reason = defaultdict(int)
        for t, _ in fast_exits:
            fast_by_reason[t.get('exit_reason', 'UNKNOWN')] += 1
        lines.append("| Exit Reason (Fast Exits) | Count |")
        lines.append("|---|---|")
        for reason, count in sorted(fast_by_reason.items(), key=lambda x: -x[1]):
            lines.append(f"| {reason} | {count} |")
        lines.append("")
        
        lines.append("### Individual Fast Exits")
        lines.append("")
        lines.append("| # | Entry | Setup | Dir | Hold(min) | Exit Reason |")
        lines.append("|---|---|---|---|---|---|")
        for t, hold_min in fast_exits:
            lines.append(f"| #{t['pos_id']} | {t['entry_time']} | {t['setup']} | {t['direction']} | {hold_min:.0f} | {t['exit_reason']} |")
        lines.append("")
    
    # 10. LOT SIZE
    lines.append("## 10. Lot Size Analysis")
    lines.append("")
    lots = [t['lot'] for t in trades]
    lines.append(f"| Metric | Value |")
    lines.append(f"|---|---|")
    lines.append(f"| Avg Lot | {sum(lots)/len(lots):.2f} |")
    lines.append(f"| Min Lot | {min(lots):.2f} |")
    lines.append(f"| Max Lot | {max(lots):.2f} |")
    lines.append(f"| Std Dev | {(sum((l - sum(lots)/len(lots))**2 for l in lots)/len(lots))**0.5:.2f} |")
    lines.append("")
    lines.append("> [!NOTE]")
    lines.append("> Wide lot variation (0.18 to 1.45) suggests SL distances vary significantly,")
    lines.append("> which means pivot detection is producing very different risk profiles per trade.")
    lines.append("")
    
    # 11. ALL TRADES TABLE
    lines.append("## 11. Complete Trade Log")
    lines.append("")
    lines.append("<details>")
    lines.append("<summary>Click to expand all 67 trades</summary>")
    lines.append("")
    lines.append("| # | Entry Time | Setup | Dir | Lot | SL | TP | Exit Time | Exit Reason | Hold(min) | R |")
    lines.append("|---|---|---|---|---|---|---|---|---|---|---|")
    for i, t in enumerate(trades, 1):
        hold = ''
        if t.get('exit_time'):
            hold_min = (parse_dt(t['exit_time']) - parse_dt(t['entry_time'])).total_seconds() / 60
            hold = f"{hold_min:.0f}"
        r_val = extract_r_from_detail(t.get('exit_detail', ''))
        r_str = f"{r_val:.2f}" if r_val else ''
        lines.append(f"| {i} | {t['entry_time']} | {t['setup']} | {t['direction']} | {t['lot']:.2f} | {t['sl']:.5f} | {t['tp']:.5f} | {t.get('exit_time', 'N/A')} | {t['exit_reason']} | {hold} | {r_str} |")
    lines.append("")
    lines.append("</details>")
    lines.append("")
    
    # 12. DIAGNOSIS & RECOMMENDATIONS
    lines.append("---")
    lines.append("")
    lines.append("## 12. DIAGNOSIS & RECOMMENDATIONS")
    lines.append("")
    
    opp_pa = results['by_exit_reason'].get('SCALP_EXIT_OPPOSITE_PA_REVERSAL', 0)
    mom_stall = results['by_exit_reason'].get('SCALP_EXIT_MOMENTUM_STALL', 0)
    
    lines.append("### Problem 1: Opposite PA Reversal is too aggressive")
    lines.append("")
    lines.append(f"**{opp_pa}/{total} ({opp_pa/total*100:.1f}%)** of trades exit because of a single opposing candle.")
    lines.append("")
    lines.append("The current logic treats EVERY bearish candle (close < open, close in bottom 35%, or >40% rejection wick)")
    lines.append("as a reason to immediately exit a long trade. This doesn't distinguish between:")
    lines.append("- A minor 3-pip doji (noise)")
    lines.append("- A medium inside bar (pullback within trend)")
    lines.append("- A strong engulfing bar closing below prior support (actual reversal)")
    lines.append("")
    
    if durations:
        median_d = sorted(durations)[len(durations)//2]
        lines.append("### Problem 2: Median hold time is too short")
        lines.append("")
        lines.append(f"Median hold = **{median_d:.0f} minutes** ({median_d/5:.1f} M5 bars)")
        lines.append("")
        lines.append("For a trend-following scalping strategy, holding for only 1-2 bars means the EA")
        lines.append("almost never captures the actual trend continuation move it's designed for.")
        lines.append("")
    
    lines.append("### Problem 3: Very few trades develop enough to trail")
    lines.append("")
    lines.append(f"Only **{results['trailed_trades']}/{total}** trades ({results['trailed_trades']/total*100:.1f}%) triggered trailing.")
    lines.append("The trailing mechanism (BE at +1R, then bar-by-bar trail) rarely activates because")
    lines.append("trades are killed by the PA Reversal exit before they reach +1R.")
    lines.append("")
    
    lines.append("### Recommended Fixes (Phase 8+)")
    lines.append("")
    lines.append("1. **Context-Aware PA Exit**: Don't exit on ANY opposing candle. Classify counter-trend moves:")
    lines.append("   - MINOR: Small body, within ATR noise → HOLD")
    lines.append("   - MODERATE: Medium body, breaks minor structure → TIGHTEN stops")
    lines.append("   - STRONG: Large engulfing, breaks key structure → EXIT")
    lines.append("")
    lines.append("2. **Minimum Hold Rule**: Don't trigger PA exit until bar 3+ (give the trade 15 min to develop)")
    lines.append("")
    lines.append("3. **R-Based Exit Logic**:")
    lines.append("   - If trade is -0.5R to 0R: Let SL handle it, don't exit on PA")
    lines.append("   - If trade is 0 to +0.5R: Only exit on STRONG reversal")
    lines.append("   - If trade is +0.5R to +1R: Exit on MODERATE or STRONG reversal")
    lines.append("   - If trade is > +1R: Trail with structure, exit on any structure break")
    lines.append("")
    lines.append("4. **Momentum Context**: Before exiting on PA reversal, check:")
    lines.append("   - Is the M15 trend still intact?")
    lines.append("   - Is the EMA slope still favorable?")
    lines.append("   - Is tick activity declining (trend exhaustion) or just a normal pullback?")
    lines.append("")
    lines.append("5. **Signal Bar Quality Filter**: Don't enter on weak signal bars. Add:")
    lines.append("   - Body size relative to ATR")
    lines.append("   - Close position within candle (top/bottom 25% for strong, not 35%)")
    lines.append("   - Overlap with prior bars (indicates indecision)")
    lines.append("")
    
    return "\n".join(lines)


def main():
    print("=" * 60)
    print("PHASE 1 — QUANTITATIVE TRADE AUDIT")
    print("=" * 60)
    
    print("\nParsing MT5 agent log...")
    trades = parse_log()
    print(f"\nFound {len(trades)} trades")
    
    if len(trades) == 0:
        print("ERROR: No trades found! Check log file path and format.")
        return
    
    print("Analyzing trades...")
    results = analyze_trades(trades)
    
    print("Generating report...")
    report = generate_report(trades, results)
    
    # Write report
    output_path = r"c:\Users\NV LAP\Documents\antigravity\keen-tesla\PHASE1_TRADE_AUDIT.md"
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(report)
    print(f"\nReport written to: {output_path}")
    
    # Write trades as JSON
    json_path = r"c:\Users\NV LAP\Documents\antigravity\keen-tesla\scripts\v500_trades.json"
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(trades, f, indent=2, default=str)
    print(f"Trade data JSON written to: {json_path}")
    
    # Print summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"Total Trades: {results['total_trades']}")
    for reason, count in sorted(results['by_exit_reason'].items(), key=lambda x: -x[1]):
        print(f"  {reason}: {count}")
    if results['hold_durations_minutes']:
        d = sorted(results['hold_durations_minutes'])
        print(f"Median Hold: {d[len(d)//2]:.0f} min ({d[len(d)//2]/5:.1f} bars)")
        print(f"Average Hold: {sum(d)/len(d):.0f} min ({sum(d)/len(d)/5:.1f} bars)")
    print(f"Trailed: {results['trailed_trades']}/{results['total_trades']}")


if __name__ == '__main__':
    main()
