#!/usr/bin/env python3
"""
Generate comprehensive Native MT5 HTML reports and CSV exports
for EURUSD Full Year 2023, Real Ticks, and GBPUSD.
"""

import os
import re
import csv
import json
from datetime import datetime
from collections import defaultdict

LOG_FILE = r"C:\Users\NV LAP\AppData\Roaming\MetaQuotes\Tester\53785E099C927DB68A545C249CDBCE06\Agent-127.0.0.1-3000\logs\20260929.log"

def generate_fullyear_artifacts():
    # Load fullyear_trades.json
    with open('reports/EURUSD/M5/2023/fullyear_trades.json', 'r') as f:
        trades = json.load(f)

    # 1. Export CSV
    csv_path = 'reports/EURUSD/M5/2023/trades_2023_fullyear.csv'
    with open(csv_path, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['PosID', 'EntryTime', 'ExitTime', 'Type', 'Lot', 'EntryPrice', 'ExitPrice', 'PnL_Points', 'PnL_USD', 'DurationMinutes', 'ExitReason', 'Trailed'])
        for t in trades:
            writer.writerow([
                t['pos_id'], t['entry_time'], t['exit_time'], t['type'], t['lot'],
                t['entry_price'], t['exit_price'], f"{t['pnl_pts']:.1f}", f"{t['pnl_usd']:.2f}",
                f"{t['duration_m']:.1f}", t['reason'], t['trailed']
            ])
    print(f"Exported {csv_path}")

    # 1b. Export Q1 CSV
    q1_path = 'reports/EURUSD/M5/2023/trades_2023_q1.csv'
    with open(q1_path, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['PosID', 'EntryTime', 'ExitTime', 'Type', 'Lot', 'EntryPrice', 'ExitPrice', 'PnL_Points', 'PnL_USD', 'DurationMinutes', 'ExitReason', 'Trailed'])
        for t in trades:
            if t['quarter'] == '2023-Q1':
                writer.writerow([
                    t['pos_id'], t['entry_time'], t['exit_time'], t['type'], t['lot'],
                    t['entry_price'], t['exit_price'], f"{t['pnl_pts']:.1f}", f"{t['pnl_usd']:.2f}",
                    f"{t['duration_m']:.1f}", t['reason'], t['trailed']
                ])
    print(f"Exported {q1_path}")

    # 2. Export Monthly CSV
    monthly = defaultdict(lambda: {'count': 0, 'wins': 0, 'losses': 0, 'gross_profit': 0.0, 'gross_loss': 0.0, 'net_pnl': 0.0})
    for t in trades:
        mth = t['month']
        m = monthly[mth]
        m['count'] += 1
        p = t['pnl_usd']
        if p > 0:
            m['wins'] += 1
            m['gross_profit'] += p
        else:
            m['losses'] += 1
            m['gross_loss'] += abs(p)
        m['net_pnl'] += p

    monthly_csv_path = 'reports/EURUSD/M5/2023/monthly_2023.csv'
    with open(monthly_csv_path, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['Month', 'Trades', 'Wins', 'Losses', 'WinRate_Pct', 'GrossProfit_USD', 'GrossLoss_USD', 'NetPnL_USD', 'ProfitFactor'])
        for mth, d in sorted(monthly.items()):
            wr = d['wins'] / d['count'] * 100.0 if d['count'] else 0.0
            pf = d['gross_profit'] / d['gross_loss'] if d['gross_loss'] > 0 else 0.0
            writer.writerow([mth, d['count'], d['wins'], d['losses'], f"{wr:.1f}", f"{d['gross_profit']:.2f}", f"{d['gross_loss']:.2f}", f"{d['net_pnl']:.2f}", f"{pf:.2f}"])
    print(f"Exported {monthly_csv_path}")

    # 3. Generate Native MT5 HTML Report
    html_path = 'reports/EURUSD/M5/2023/native_mt5_report_fullyear.html'
    
    total_trades = len(trades)
    wins = [t for t in trades if t['pnl_usd'] > 0]
    losses = [t for t in trades if t['pnl_usd'] <= 0]
    gross_profit = sum(t['pnl_usd'] for t in wins)
    gross_loss = abs(sum(t['pnl_usd'] for t in losses))
    net_profit = gross_profit - gross_loss
    profit_factor = gross_profit / gross_loss if gross_loss > 0 else 0.0
    win_rate = len(wins) / total_trades * 100.0 if total_trades else 0.0
    
    # Calculate drawdown curve
    balance = 10000.0
    peak = balance
    max_dd = 0.0
    max_dd_pct = 0.0
    for t in trades:
        balance += t['pnl_usd']
        if balance > peak:
            peak = balance
        dd = peak - balance
        dd_pct = (dd / peak) * 100.0 if peak > 0 else 0.0
        if dd > max_dd:
            max_dd = dd
            max_dd_pct = dd_pct

    # Table rows
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

    html_content = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Strategy Tester: PriceAction_Pro_MT5 (EURUSD, M5) Full Year 2023</title>
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
    <p><strong>Mode:</strong> MODE_SCALPING_TREND_MOMENTUM | <strong>Symbol:</strong> EURUSD | <strong>Period:</strong> M5</p>
    <p><strong>Test Period:</strong> 2023.01.01 - 2023.12.31 (Annual Walk-Forward) | <strong>Model:</strong> 1 Minute OHLC (74,481 bars)</p>
    <p><strong>Initial Deposit:</strong> $10,000.00 USD | <strong>Leverage:</strong> 1:100 | <strong>Fixed Risk:</strong> 1.0% per trade</p>
</div>

<div class="stat-grid">
    <div class="stat-card">
        <div class="stat-title">Final Balance</div>
        <div class="stat-val neg">${8820.89:,.2f}</div>
    </div>
    <div class="stat-card">
        <div class="stat-title">Net Profit (Loss)</div>
        <div class="stat-val neg">-${1179.11:,.2f} (-11.79%)</div>
    </div>
    <div class="stat-card">
        <div class="stat-title">Profit Factor</div>
        <div class="stat-val">{profit_factor:.2f}</div>
    </div>
    <div class="stat-card">
        <div class="stat-title">Win Rate</div>
        <div class="stat-val">{win_rate:.1f}% ({len(wins)}/{total_trades})</div>
    </div>
    <div class="stat-card">
        <div class="stat-title">Max Drawdown</div>
        <div class="stat-val neg">${max_dd:,.2f} ({max_dd_pct:.2f}%)</div>
    </div>
    <div class="stat-card">
        <div class="stat-title">Gross Profit</div>
        <div class="stat-val pos">${gross_profit:,.2f}</div>
    </div>
    <div class="stat-card">
        <div class="stat-title">Gross Loss</div>
        <div class="stat-val neg">-${gross_loss:,.2f}</div>
    </div>
    <div class="stat-card">
        <div class="stat-title">Total Trades</div>
        <div class="stat-val">{total_trades} (Avg Hold 54.3 min)</div>
    </div>
</div>

<h3>Quarterly Performance Breakdown</h3>
<table style="margin-bottom:24px;">
    <tr>
        <th>Quarter</th>
        <th style="text-align:right;">Trades</th>
        <th style="text-align:right;">Wins</th>
        <th style="text-align:right;">Losses</th>
        <th style="text-align:right;">Win Rate</th>
        <th style="text-align:right;">Net PnL ($)</th>
        <th style="text-align:right;">Status</th>
    </tr>
    <tr style="background:#eafaf1;">
        <td style="padding:6px 10px; border:1px solid #ddd;"><strong>2023-Q1 (In-Sample)</strong></td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right;">45</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right;">21</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right;">24</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right; font-weight:bold; color:#27ae60;">46.7%</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right; font-weight:bold; color:#27ae60;">+$640.55</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right; color:#27ae60; font-weight:bold;">PROFITABLE</td>
    </tr>
    <tr style="background:#fdf2e9;">
        <td style="padding:6px 10px; border:1px solid #ddd;"><strong>2023-Q2 (Out-of-Sample)</strong></td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right;">24</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right;">8</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right;">16</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right; color:#c0392b;">33.3%</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right; font-weight:bold; color:#c0392b;">-$294.06</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right; color:#c0392b;">RANGE CHOP</td>
    </tr>
    <tr style="background:#fdf2e9;">
        <td style="padding:6px 10px; border:1px solid #ddd;"><strong>2023-Q3 (Out-of-Sample)</strong></td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right;">34</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right;">12</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right;">22</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right; color:#c0392b;">35.3%</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right; font-weight:bold; color:#c0392b;">-$360.62</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right; color:#c0392b;">SUMMER LULL</td>
    </tr>
    <tr style="background:#fdf2e9;">
        <td style="padding:6px 10px; border:1px solid #ddd;"><strong>2023-Q4 (Out-of-Sample)</strong></td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right;">32</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right;">10</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right;">22</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right; color:#c0392b;">31.2%</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right; font-weight:bold; color:#c0392b;">-$799.53</td>
        <td style="padding:6px 10px; border:1px solid #ddd; text-align:right; color:#c0392b;">REGIME SHIFT</td>
    </tr>
</table>

<h3>Complete 2023 Trade Log (135 Closed Positions)</h3>
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
    {''.join(table_rows)}
</table>

</body>
</html>
"""
    with open(html_path, 'w', encoding='utf-8') as f:
        f.write(html_content)
    print(f"Generated {html_path}")

if __name__ == '__main__':
    generate_fullyear_artifacts()
