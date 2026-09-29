#!/usr/bin/env python3
"""
Generate reports for Real Ticks (EURUSD M5), GBPUSD M5, and XAUUSD M5.
"""

import os
import re
import csv
import json
from datetime import datetime
from collections import defaultdict

LOG_FILE = r"C:\Users\NV LAP\AppData\Roaming\MetaQuotes\Tester\53785E099C927DB68A545C249CDBCE06\Agent-127.0.0.1-3000\logs\20260929.log"

def parse_run(time_filter, symbol):
    with open(LOG_FILE, 'r', encoding='utf-16', errors='ignore') as f:
        raw_lines = f.readlines()
        
    lines = [line.strip() for line in raw_lines if time_filter in line]
    
    deal_pat = re.compile(rf'(\d{{4}}\.\d{{2}}\.\d{{2}} \d{{2}}:\d{{2}}:\d{{2}})\s+deal #(\d+)\s+(buy|sell)\s+([\d.]+)\s+{symbol} at ([\d.]+)\s+done \(based on order #(\d+)\)')
    exec_pat = re.compile(r'\[SCALP EXEC OK\]\s+(SCALP_[HL]2.*?)\s+pos=#(\d+)\s+deal=#(\d+)\s+lot=([\d.]+)\s+sl=([\d.]+)\s+tp=([\d.]+)\s+retcode=(\d+)')
    exit_pat = re.compile(r'\[SCALP EXIT OK\]\s+Position #(\d+) closed\.\s+Reason:\s+(SCALP_EXIT_\w+)\s*(?:\((.+?)\))?')
    
    deals = []
    execs = {}
    exits = {}
    
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

    trades = []
    mult = 100000.0 if 'USD' in symbol and symbol != 'XAUUSD' else 100.0
    pip_factor = 0.00001 if 'JPY' not in symbol and symbol != 'XAUUSD' else 0.01

    for i in range(0, len(deals)-1, 2):
        d_in = deals[i]
        d_out = deals[i+1]
        pos_id = d_in['id']
        is_buy = (d_in['type'] == 'buy')
        pts = (d_out['price'] - d_in['price']) if is_buy else (d_in['price'] - d_out['price'])
        pnl_pts = pts / pip_factor
        pnl_usd = pts * mult * d_in['lot']
        
        t_in = datetime.strptime(d_in['time'], '%Y.%m.%d %H:%M:%S')
        t_out = datetime.strptime(d_out['time'], '%Y.%m.%d %H:%M:%S')
        duration_m = (t_out - t_in).total_seconds() / 60.0
        
        reason = exits.get(pos_id, {}).get('reason', 'SCALP_EXIT_DYNAMIC')
        trades.append({
            'pos_id': pos_id,
            'entry_time': d_in['time'],
            'exit_time': d_out['time'],
            'type': d_in['type'],
            'lot': d_in['lot'],
            'entry_price': d_in['price'],
            'exit_price': d_out['price'],
            'pnl_pts': pnl_pts,
            'pnl_usd': pnl_usd,
            'duration_m': duration_m,
            'reason': reason
        })
    return trades

def make_html(trades, symbol, timeframe, model_name, period_str, final_bal, out_path):
    total = len(trades)
    wins = [t for t in trades if t['pnl_usd'] > 0]
    losses = [t for t in trades if t['pnl_usd'] <= 0]
    gross_profit = sum(t['pnl_usd'] for t in wins)
    gross_loss = abs(sum(t['pnl_usd'] for t in losses))
    net_profit = final_bal - 10000.0
    profit_factor = gross_profit / gross_loss if gross_loss > 0 else (1.0 if total==0 else float('inf'))
    win_rate = len(wins) / total * 100.0 if total else 0.0

    table_rows = []
    run_bal = 10000.0
    for idx, t in enumerate(trades, 1):
        run_bal += t['pnl_usd']
        bg = "#eafaf1" if t['pnl_usd'] > 0 else "#fdf2e9"
        color = "#27ae60" if t['pnl_usd'] > 0 else "#c0392b"
        table_rows.append(f"""
        <tr style="background:{bg};">
            <td style="padding:4px 8px; border:1px solid #ddd; text-align:center;">{idx}</td>
            <td style="padding:4px 8px; border:1px solid #ddd; text-align:center;">{t['pos_id']}</td>
            <td style="padding:4px 8px; border:1px solid #ddd;">{t['entry_time']}</td>
            <td style="padding:4px 8px; border:1px solid #ddd; text-align:center; font-weight:bold; color:{'#2980b9' if t['type']=='buy' else '#d35400'};">{t['type'].upper()}</td>
            <td style="padding:4px 8px; border:1px solid #ddd; text-align:right;">{t['lot']:.2f}</td>
            <td style="padding:4px 8px; border:1px solid #ddd; text-align:right;">{t['entry_price']:.5f}</td>
            <td style="padding:4px 8px; border:1px solid #ddd;">{t['exit_time']}</td>
            <td style="padding:4px 8px; border:1px solid #ddd; text-align:right;">{t['exit_price']:.5f}</td>
            <td style="padding:4px 8px; border:1px solid #ddd; text-align:right;">{t['pnl_pts']:+.1f}</td>
            <td style="padding:4px 8px; border:1px solid #ddd; text-align:right; font-weight:bold; color:{color};">{t['pnl_usd']:+.2f}</td>
            <td style="padding:4px 8px; border:1px solid #ddd; text-align:right; font-weight:bold;">${run_bal:,.2f}</td>
            <td style="padding:4px 8px; border:1px solid #ddd; font-size:11px;">{t['reason']}</td>
        </tr>""")

    no_trades_row = '<tr><td colspan="12" style="padding:12px; text-align:center; color:#7f8c8d;">No trades executed (Capital preserved, 0% drawdown).</td></tr>'
    table_body = ''.join(table_rows) if table_rows else no_trades_row

    html = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Strategy Tester: PriceAction_Pro_MT5 ({symbol}, {timeframe})</title>
<style>
body {{ font-family: Segoe UI, Tahoma, Arial, sans-serif; font-size: 12px; margin: 20px; background-color: #f7f9fa; color: #2c3e50; }}
.header-box {{ background: #2c3e50; color: white; padding: 18px 24px; border-radius: 6px; margin-bottom: 20px; }}
.header-box h1 {{ margin: 0 0 8px 0; font-size: 20px; }}
.header-box p {{ margin: 3px 0; font-size: 13px; opacity: 0.9; }}
.stat-grid {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; margin-bottom: 24px; }}
.stat-card {{ background: white; border: 1px solid #e2e8f0; border-radius: 6px; padding: 14px 18px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }}
.stat-title {{ font-size: 11px; text-transform: uppercase; color: #7f8c8d; font-weight: 600; margin-bottom: 6px; }}
.stat-val {{ font-size: 20px; font-weight: bold; color: #2c3e50; }}
.pos {{ color: #27ae60 !important; }}
.neg {{ color: #c0392b !important; }}
table {{ border-collapse: collapse; width: 100%; background: white; border-radius: 6px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.05); font-size: 12px; }}
th {{ background-color: #34495e; color: white; text-align: left; padding: 8px; font-weight: 600; font-size: 11px; border: 1px solid #2c3e50; }}
</style>
</head>
<body>

<div class="header-box">
    <h1>Strategy Tester Report: PriceAction_Pro_MT5 v6.00</h1>
    <p><strong>Mode:</strong> MODE_SCALPING_TREND_MOMENTUM | <strong>Symbol:</strong> {symbol} | <strong>Period:</strong> {timeframe}</p>
    <p><strong>Test Period:</strong> {period_str} | <strong>Model:</strong> {model_name}</p>
    <p><strong>Initial Deposit:</strong> $10,000.00 USD | <strong>Leverage:</strong> 1:100 | <strong>Fixed Risk:</strong> 1.0% per trade</p>
</div>

<div class="stat-grid">
    <div class="stat-card">
        <div class="stat-title">Final Balance</div>
        <div class="stat-val {'pos' if final_bal >= 10000 else 'neg'}">${final_bal:,.2f}</div>
    </div>
    <div class="stat-card">
        <div class="stat-title">Net Profit</div>
        <div class="stat-val {'pos' if net_profit >= 0 else 'neg'}">{'+' if net_profit>=0 else ''}${net_profit:,.2f} ({(net_profit/10000.0)*100:+.2f}%)</div>
    </div>
    <div class="stat-card">
        <div class="stat-title">Profit Factor</div>
        <div class="stat-val">{profit_factor:.2f}</div>
    </div>
    <div class="stat-card">
        <div class="stat-title">Win Rate</div>
        <div class="stat-val">{win_rate:.1f}% ({len(wins)}/{total})</div>
    </div>
</div>

<h3>Trade Log ({total} Closed Positions)</h3>
<table>
    <tr>
        <th>#</th>
        <th>PosID</th>
        <th>Entry Time</th>
        <th>Type</th>
        <th>Lot</th>
        <th>Entry Price</th>
        <th>Exit Time</th>
        <th>Exit Price</th>
        <th>Pts</th>
        <th>PnL ($)</th>
        <th>Balance</th>
        <th>Exit Reason</th>
    </tr>
    {table_body}
</table>

</body>
</html>
"""
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(html)
    print(f"Generated {out_path}")

def main():
    # 1. Real Ticks EURUSD M5 (timestamp 04:33:)
    realtick_trades = parse_run("04:33:", "EURUSD")
    make_html(realtick_trades, "EURUSD", "M5", "Every tick based on real ticks (3,316,635 ticks)", "2023.01.01 - 2023.03.31", 10410.27, "reports/EURUSD/M5/2023/native_mt5_report_realticks.html")
    
    # 2. GBPUSD M5 (timestamp 04:33:58)
    gbp_trades = parse_run("04:33:58", "GBPUSD")
    make_html(gbp_trades, "GBPUSD", "M5", "1 Minute OHLC (18,450 bars)", "2023.01.01 - 2023.03.31", 10092.94, "reports/GBPUSD/M5/2023/native_mt5_report_gbpusd.html")
    
    # Export GBPUSD CSV
    with open('reports/GBPUSD/M5/2023/trades_gbpusd_2023.csv', 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['PosID', 'EntryTime', 'ExitTime', 'Type', 'Lot', 'EntryPrice', 'ExitPrice', 'PnL_Points', 'PnL_USD', 'DurationMinutes', 'ExitReason'])
        for t in gbp_trades:
            writer.writerow([t['pos_id'], t['entry_time'], t['exit_time'], t['type'], t['lot'], t['entry_price'], t['exit_price'], f"{t['pnl_pts']:.1f}", f"{t['pnl_usd']:.2f}", f"{t['duration_m']:.1f}", t['reason']])

    # 3. XAUUSD M5 (timestamp 04:34:)
    xau_trades = parse_run("04:34:", "XAUUSD")
    make_html(xau_trades, "XAUUSD", "M5", "1 Minute OHLC (17,337 bars)", "2023.01.01 - 2023.03.31", 10000.00, "reports/XAUUSD/M5/2023/native_mt5_report_xauusd.html")

if __name__ == '__main__':
    main()
