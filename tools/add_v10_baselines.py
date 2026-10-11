import os, csv, shutil, sys
sys.path.insert(0, os.path.dirname(__file__))
from phase3_runner import parse_report, sha, git_commit

MANIFEST = r"reports\phase3\manifest.csv"
base_dir = r"c:\Users\NV LAP\Documents\antigravity\cool-noether"
v10_jobs = [
    ("B3_v10_Baseline_FY", "Report_v10_Baseline.htm", "run_v10_Baseline.ini", "Aurum_Imperium_Apex_v10_TTrades_Unicorn.ex5"),
    ("B4_v10_Champion_Synthesis_FY", "Report_v10_Champion_Synthesis.htm", "run_v10_Champion_Synthesis.ini", "Aurum_Imperium_Apex_v10_TTrades_Unicorn.ex5"),
    ("B5_v10_PropFirm_Safe_FY", "Report_v10_PropFirm_Safe_Risk040.htm", "run_v10_PropFirm_Safe_Risk040.ini", "Aurum_Imperium_Apex_v10_TTrades_Unicorn.ex5")
]

fieldnames = ['id','expert','mq5_sha','ex5_sha','ini_sha','git','from','to','model','quality','net','gross_profit','gross_loss','pf','exp_payoff','rf','sharpe','bal_dd','eq_dd','eq_dd_rel','trades','secs']

for jid, htm, ini, expert in v10_jobs:
    src_htm = os.path.join(base_dir, htm)
    src_ini = os.path.join(base_dir, ini)
    dst_htm = os.path.join(r"reports\phase3", f"P3_{jid}.htm")
    dst_ini = os.path.join(r"reports\phase3", f"{jid}.ini")
    if os.path.exists(src_htm): shutil.copy2(src_htm, dst_htm)
    if os.path.exists(src_ini): shutil.copy2(src_ini, dst_ini)
    m = parse_report(dst_htm) if os.path.exists(dst_htm) else {}
    row = {
        'id': jid, 'expert': expert, 'mq5_sha': sha(expert.replace('.ex5','.mq5')), 'ex5_sha': sha(expert),
        'ini_sha': sha(dst_ini), 'git': git_commit(), 'from': '2025.10.01', 'to': '2026.10.01',
        'model': 4, 'quality': m.get('History Quality', '74% real ticks'),
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
