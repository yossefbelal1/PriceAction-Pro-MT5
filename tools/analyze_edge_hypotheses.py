import os, sys, csv
from bs4 import BeautifulSoup
from collections import defaultdict

def parse_report_deals(report_path):
    if not os.path.exists(report_path): return []
    with open(report_path, "r", encoding="utf-16le", errors="ignore") as f:
        soup = BeautifulSoup(f.read(), "html.parser")
    tables = soup.find_all("table")
    if len(tables) < 2: return []
    rows = tables[1].find_all("tr")
    deals_idx = -1
    for idx, r in enumerate(rows):
        if "Deals" in r.get_text().strip():
            deals_idx = idx
            break
    if deals_idx == -1 or deals_idx + 1 >= len(rows): return []
    headers = [th.get_text().strip() for th in rows[deals_idx+1].find_all(["th", "td"])]
    deals = []
    for r in rows[deals_idx+2:]:
        cols = [c.get_text().strip() for c in r.find_all(["td", "th"])]
        if len(cols) == len(headers):
            deals.append(dict(zip(headers, cols)))
    return deals

def analyze_trade_flow(deals):
    # Group in and out deals into trades
    open_deals = {}
    trades = []
    
    for d in deals:
        direction = d.get("Direction", "").lower()
        deal_type = d.get("Type", "").lower()
        if deal_type == "balance": continue
        
        order = d.get("Order", "")
        time_str = d.get("Time", "")
        price = float(d.get("Price", "0").replace(" ", "").replace(",", "")) if d.get("Price") else 0.0
        vol = float(d.get("Volume", "0").replace(" ", "").replace(",", "")) if d.get("Volume") else 0.0
        profit = float(d.get("Profit", "0").replace(" ", "").replace(",", "")) if d.get("Profit") else 0.0
        comm = float(d.get("Commission", "0").replace(" ", "").replace(",", "")) if d.get("Commission") else 0.0
        swap = float(d.get("Swap", "0").replace(" ", "").replace(",", "")) if d.get("Swap") else 0.0
        comment = d.get("Comment", "")
        symbol = d.get("Symbol", "")
        
        if direction == "in":
            open_deals[order] = {
                "in_time": time_str,
                "in_price": price,
                "in_vol": vol,
                "in_type": deal_type,
                "in_comm": comm
            }
        elif direction == "out":
            # Match exit with entry
            in_info = open_deals.get(order, {})
            net = profit + comm + in_info.get("in_comm", 0.0) + swap
            trades.append({
                "order": order,
                "in_time": in_info.get("in_time", time_str),
                "out_time": time_str,
                "type": in_info.get("in_type", ""),
                "volume": vol,
                "in_price": in_info.get("in_price", 0.0),
                "out_price": price,
                "gross_profit": profit,
                "net_profit": net,
                "comment": comment
            })
            
    print(f"Total Completed Trades Analyzed: {len(trades)}")
    
    # 1. Scratch Trades (Break-even exits where profit is between -$5 and +$15)
    scratches = [t for t in trades if -5.0 <= t["net_profit"] <= 15.0]
    wins = [t for t in trades if t["net_profit"] > 15.0]
    losses = [t for t in trades if t["net_profit"] < -5.0]
    
    print(f"Wins: {len(wins)} (Avg Net: ${sum(t['net_profit'] for t in wins)/len(wins) if wins else 0:.2f})")
    print(f"Losses: {len(losses)} (Avg Net: ${sum(t['net_profit'] for t in losses)/len(losses) if losses else 0:.2f})")
    print(f"Scratches/BE: {len(scratches)} (Avg Net: ${sum(t['net_profit'] for t in scratches)/len(scratches) if scratches else 0:.2f})")
    
    # 2. Hourly Distribution
    hour_stats = defaultdict(lambda: {"trades": 0, "net": 0.0, "wins": 0, "losses": 0})
    for t in trades:
        h = int(t["in_time"].split()[1].split(":")[0]) if " " in t["in_time"] else 0
        hour_stats[h]["trades"] += 1
        hour_stats[h]["net"] += t["net_profit"]
        if t["net_profit"] > 0: hour_stats[h]["wins"] += 1
        else: hour_stats[h]["losses"] += 1
        
    print("\n--- Performance by Entry Hour (Broker Time) ---")
    for h in sorted(hour_stats.keys()):
        st = hour_stats[h]
        wr = st["wins"]/st["trades"]*100 if st["trades"]>0 else 0
        print(f"Hour {h:02d}:00 - {st['trades']:>2} trades | Net: ${st['net']:>8.2f} | WinRate: {wr:>5.1f}%")
        
    # 3. Daily Trade Sequence: Trade 1 vs Trade 2
    day_trades = defaultdict(list)
    for t in trades:
        day = t["in_time"].split()[0] if " " in t["in_time"] else ""
        day_trades[day].append(t)
        
    t1_wins, t1_net = 0, 0.0
    t2_wins, t2_net, t2_count = 0, 0.0, 0
    whip_days = 0 # Won T1, Lost T2
    
    for day, t_list in day_trades.items():
        if len(t_list) >= 1:
            t1 = t_list[0]
            t1_net += t1["net_profit"]
            if t1["net_profit"] > 0: t1_wins += 1
        if len(t_list) >= 2:
            t2 = t_list[1]
            t2_count += 1
            t2_net += t2["net_profit"]
            if t2["net_profit"] > 0: t2_wins += 1
            if t_list[0]["net_profit"] > 0 and t2["net_profit"] < 0:
                whip_days += 1
                
    print(f"\n--- Trade 1 vs Trade 2 Sequence Analysis ---")
    print(f"Trade 1 Total: {len(day_trades)} trades | Net: ${t1_net:.2f} | WinRate: {t1_wins/len(day_trades)*100:.1f}%")
    if t2_count > 0:
        print(f"Trade 2 Total: {t2_count} trades | Net: ${t2_net:.2f} | WinRate: {t2_wins/t2_count*100:.1f}%")
        print(f"Whipsaw Days (Won Trade 1, Wiped Out by Trade 2): {whip_days} days ({whip_days/t2_count*100:.1f}% of Trade 2 days)")

if __name__ == "__main__":
    rep = r"c:\Users\NV LAP\Documents\antigravity\cool-noether\Report_London_Lock120_Risk095_FullYear.htm"
    if len(sys.argv) > 1: rep = sys.argv[1]
    deals = parse_report_deals(rep)
    analyze_trade_flow(deals)
