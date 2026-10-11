"""Extract round-trip trade histories from MT5 Strategy Tester HTML reports.
Parses Orders and Deals tables and exports clean CSVs with:
trade_num, entry_time, exit_time, duration_mins, type, lots, entry_px, exit_px,
sl, tp, gross_pnl, commission, swap, net_pnl, balance, exit_reason, result
"""
import os, sys, glob, csv, re
from bs4 import BeautifulSoup
from datetime import datetime

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(REPO, "reports", "phase3", "trades")
os.makedirs(OUT_DIR, exist_ok=True)

def parse_html_trades(html_path):
    with open(html_path, "r", encoding="utf-16le", errors="ignore") as f:
        soup = BeautifulSoup(f.read(), "html.parser")
    tables = soup.find_all("table")
    if len(tables) < 2:
        return []
    
    t1 = tables[1]
    rows = t1.find_all("tr")
    
    # 1. Parse Orders for SL/TP info
    orders_info = {}
    in_orders = False
    in_deals = False
    deals_rows = []
    
    for tr in rows:
        cells = [td.get_text().strip() for td in tr.find_all(["th", "td"])]
        if not cells:
            continue
        txt = cells[0]
        if txt == "Orders":
            in_orders = True
            in_deals = False
            continue
        elif txt == "Deals":
            in_orders = False
            in_deals = True
            continue
            
        if in_orders and len(cells) >= 11:
            if cells[0] == "Open Time":
                continue
            # cells: [open_time, order, symbol, type, volume, price, sl, tp, time, state, comment]
            order_id = cells[1]
            orders_info[order_id] = {
                "sl": cells[6] if len(cells) > 6 else "",
                "tp": cells[7] if len(cells) > 7 else "",
                "comment": cells[10] if len(cells) > 10 else ""
            }
            
        if in_deals and len(cells) >= 12:
            if cells[0] == "Time":
                continue
            deals_rows.append(cells)
            
    # 2. Pair Deals (in and out)
    trades = []
    open_positions = {} # symbol -> {deal, time, type, volume, price, commission}
    trade_counter = 0
    
    for d in deals_rows:
        # cells: [time, deal, symbol, type, direction, volume, price, order, commission, swap, profit, balance, comment]
        if len(d) < 12:
            continue
        d_time = d[0]
        d_ticket = d[1]
        d_sym = d[2]
        d_type = d[3]
        d_dir = d[4]
        d_vol = d[5]
        d_px = d[6]
        d_order = d[7]
        d_comm = float(d[8].replace(" ", "").replace(",", ".")) if d[8] else 0.0
        d_swap = float(d[9].replace(" ", "").replace(",", ".")) if d[9] else 0.0
        d_pnl = float(d[10].replace(" ", "").replace(",", ".")) if d[10] else 0.0
        d_bal = float(d[11].replace(" ", "").replace(",", ".")) if d[11] else 0.0
        d_comment = d[12] if len(d) > 12 else ""
        
        if d_dir == "in":
            open_positions[d_sym] = {
                "entry_time": d_time,
                "type": d_type,
                "lots": d_vol,
                "entry_px": d_px,
                "entry_comm": d_comm,
                "entry_order": d_order,
                "entry_ticket": d_ticket
            }
        elif d_dir == "out" and d_sym in open_positions:
            pos = open_positions.pop(d_sym)
            trade_counter += 1
            
            # Duration
            try:
                t_in = datetime.strptime(pos["entry_time"], "%Y.%m.%d %H:%M:%S")
                t_out = datetime.strptime(d_time, "%Y.%m.%d %H:%M:%S")
                duration_mins = round((t_out - t_in).total_seconds() / 60.0, 1)
            except:
                duration_mins = 0.0
                
            tot_comm = round(pos["entry_comm"] + d_comm, 2)
            net_pnl = round(d_pnl + tot_comm + d_swap, 2)
            
            order_data = orders_info.get(pos["entry_order"], {})
            sl = order_data.get("sl", "")
            tp = order_data.get("tp", "")
            
            # Exit reason
            reason = "EXIT"
            if "sl" in d_comment.lower():
                reason = "SL" if net_pnl < 0 else "BE_TRAIL"
            elif "tp" in d_comment.lower():
                reason = "TP"
            elif "close" in d_comment.lower():
                reason = "MANUAL_OR_SESSION"
                
            result = "WIN" if net_pnl > 5.0 else ("LOSS" if net_pnl < -5.0 else "BE_SCRATCH")
            
            trades.append({
                "trade_num": trade_counter,
                "entry_time": pos["entry_time"],
                "exit_time": d_time,
                "duration_mins": duration_mins,
                "symbol": d_sym,
                "type": pos["type"],
                "lots": pos["lots"],
                "entry_px": pos["entry_px"],
                "exit_px": d_px,
                "sl": sl,
                "tp": tp,
                "gross_pnl": round(d_pnl, 2),
                "commission": tot_comm,
                "swap": round(d_swap, 2),
                "net_pnl": net_pnl,
                "balance": d_bal,
                "exit_reason": reason,
                "result": result
            })
            
    return trades

def process_all_reports():
    reports = glob.glob(os.path.join(REPO, "reports", "phase3", "*.htm"))
    for htm in reports:
        name = os.path.splitext(os.path.basename(htm))[0]
        csv_path = os.path.join(OUT_DIR, f"{name}_trades.csv")
        trades = parse_html_trades(htm)
        if not trades:
            continue
        keys = list(trades[0].keys())
        with open(csv_path, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=keys)
            w.writeheader()
            w.writerows(trades)
        print(f"Exported {len(trades)} trades for {name} -> {csv_path}")

if __name__ == "__main__":
    process_all_reports()
