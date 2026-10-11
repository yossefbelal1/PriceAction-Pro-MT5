import os, csv, shutil, sys
sys.path.insert(0, os.path.dirname(__file__))
from phase3_runner import parse_report, sha, git_commit

MANIFEST = r"reports\phase3\manifest.csv"
base_dir = r"c:\Users\NV LAP\Documents\antigravity\cool-noether"

repaired_jobs = [
    ("R1_v80_Repaired_FY", "Report_Repaired_v80_FullYear.htm", "run_temp_Repaired_v80_FullYear.ini", "Aurum_Imperium_Apex_v8.0_Repaired.ex5", "2025.10.01", "2026.10.01", "74% real ticks"),
    ("R2_v80_Repaired_OOS", "Report_Repaired_v80_OutOfSample.htm", "run_temp_Repaired_v80_OutOfSample.ini", "Aurum_Imperium_Apex_v8.0_Repaired.ex5", "2026.06.01", "2026.10.01", "100% real ticks"),
    ("R3_v85_Repaired_FY", "Report_Repaired_v85_FullYear.htm", "run_temp_Repaired_v85_FullYear.ini", "Aurum_Imperium_Apex_v8.5_Quant_Repaired.ex5", "2025.10.01", "2026.10.01", "74% real ticks"),
    ("R4_v85_Repaired_OOS", "Report_Repaired_v85_OutOfSample.htm", "run_temp_Repaired_v85_OutOfSample.ini", "Aurum_Imperium_Apex_v8.5_Quant_Repaired.ex5", "2026.06.01", "2026.10.01", "100% real ticks"),
    ("R5_v80_UltraSafe_Repaired_FY", "Report_Repaired_v80_UltraSafe_FullYear.htm", "run_temp_Repaired_v80_UltraSafe_FullYear.ini", "Aurum_Imperium_Apex_v8.0_Repaired.ex5", "2025.10.01", "2026.10.01", "74% real ticks"),
    ("R6_v80_UltraSafe_Repaired_OOS", "Report_Repaired_v80_UltraSafe_OutOfSample.htm", "run_temp_Repaired_v80_UltraSafe_OutOfSample.ini", "Aurum_Imperium_Apex_v8.0_Repaired.ex5", "2026.06.01", "2026.10.01", "100% real ticks"),
    ("B1_v80_original_OOS", "Report_Phase_Baseline_OutOfSample.htm", "run_fullyear_lock120.ini", "Aurum_Imperium_Apex_v8.0.ex5", "2026.06.01", "2026.10.01", "100% real ticks"),
    ("B2_v85_original_OOS", "Report_v85_OutOfSample.htm", "run_v85_OutOfSample.ini", "Aurum_Imperium_Apex_v8.5_Quant.ex5", "2026.06.01", "2026.10.01", "100% real ticks"),
]

fieldnames = ['id','expert','mq5_sha','ex5_sha','ini_sha','git','from','to','model','quality','net','gross_profit','gross_loss','pf','exp_payoff','rf','sharpe','bal_dd','eq_dd','eq_dd_rel','trades','secs']

for jid, htm, ini, expert, fdate, tdate, qual in repaired_jobs:
    src_htm = os.path.join(base_dir, htm)
    src_ini = os.path.join(base_dir, ini)
    dst_htm = os.path.join(r"reports\phase3", f"P3_{jid}.htm")
    dst_ini = os.path.join(r"reports\phase3", f"{jid}.ini")
    if os.path.exists(src_htm): shutil.copy2(src_htm, dst_htm)
    if os.path.exists(src_ini): shutil.copy2(src_ini, dst_ini)
    src_png = src_htm.replace(".htm", ".png")
    dst_png = dst_htm.replace(".htm", ".png")
    if os.path.exists(src_png): shutil.copy2(src_png, dst_png)
    
    m = parse_report(dst_htm) if os.path.exists(dst_htm) else {}
    row = {
        'id': jid, 'expert': expert, 'mq5_sha': sha(expert.replace('.ex5','.mq5')), 'ex5_sha': sha(expert),
        'ini_sha': sha(dst_ini), 'git': git_commit(), 'from': fdate, 'to': tdate,
        'model': 4, 'quality': m.get('History Quality', qual),
        'net': m.get('Total Net Profit', ''), 'gross_profit': m.get('Gross Profit', ''),
        'gross_loss': m.get('Gross Loss', ''), 'pf': m.get('Profit Factor', ''),
        'exp_payoff': m.get('Expected Payoff', ''), 'rf': m.get('Recovery Factor', ''),
        'sharpe': m.get('Sharpe Ratio', ''), 'bal_dd': m.get('Balance Drawdown Maximal', ''),
        'eq_dd': m.get('Equity Drawdown Maximal', ''), 'eq_dd_rel': m.get('Equity Drawdown Relative', ''),
        'trades': m.get('Total Trades', ''), 'secs': 0
    }
    with open(MANIFEST, 'a', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writerow(row)
    print(f"Added {jid}: net={row['net']} pf={row['pf']} eqDD={row['eq_dd']}")
