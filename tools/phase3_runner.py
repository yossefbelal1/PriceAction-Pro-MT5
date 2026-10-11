"""Phase 3 reproducible MT5 Strategy Tester runner.

Every run writes: the exact .ini used, the native HTML report, the chart PNG, and a
manifest row (expert, source sha256, ex5 sha256, ini sha256, git commit, period,
modeling, parsed metrics, history quality) so every reported number is traceable.

Usage:  python tools/phase3_runner.py <jobs.json>
jobs.json = [{"id","expert","base_ini","from","to","overrides":{...},"model":4}, ...]
Original reports are NEVER overwritten: reports go to reports/phase3/<id>.htm
"""
import os, sys, json, time, shutil, hashlib, subprocess, csv
from bs4 import BeautifulSoup

TERMINAL_EXE = r"C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe"
TERMINAL_DATA = r"C:\Users\NV LAP\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06"
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, "reports", "phase3")
SRC_DIR = REPO
MANIFEST = os.path.join(OUT, "manifest.csv")


def sha(path):
    if not os.path.exists(path):
        return ""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        h.update(f.read())
    return h.hexdigest()[:16]


def git_commit():
    r = subprocess.run(["git", "-C", REPO, "rev-parse", "--short", "HEAD"], capture_output=True, text=True)
    d = subprocess.run(["git", "-C", REPO, "status", "--porcelain"], capture_output=True, text=True)
    return r.stdout.strip() + ("+dirty" if d.stdout.strip() else "")


def read_inputs(ini_path):
    inputs, cap = {}, False
    with open(ini_path, "r", encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if s == "[TesterInputs]":
                cap = True
                continue
            if cap and "=" in s and not s.startswith("["):
                k, v = s.split("=", 1)
                inputs[k] = v
    return inputs


def parse_report(path):
    with open(path, "r", encoding="utf-16le", errors="ignore") as f:
        soup = BeautifulSoup(f.read(), "html.parser")
    d = {}
    for tr in soup.find_all("tr"):
        tds = [td.get_text().strip() for td in tr.find_all("td")]
        for i in range(0, len(tds) - 1, 2):
            k = tds[i].replace(":", "").strip()
            if k and tds[i + 1].strip():
                d[k] = tds[i + 1].strip()
    return d


def run_job(job, timeout=1500):
    os.makedirs(OUT, exist_ok=True)
    jid = job["id"]
    inputs = read_inputs(os.path.join(REPO, job["base_ini"]))
    inputs.update({k: str(v) for k, v in job.get("overrides", {}).items()})
    rep_name = f"P3_{jid}.htm"
    ini_path = os.path.join(OUT, f"{jid}.ini")
    term_rep = os.path.join(TERMINAL_DATA, rep_name)
    for p in (term_rep, term_rep.replace(".htm", ".png")):
        if os.path.exists(p):
            os.remove(p)
    ini = (f"[Tester]\nExpert={job['expert']}\nSymbol={job.get('symbol','XAUUSD')}\n"
           f"Period={job.get('period','M5')}\nDeposit=10000\nCurrency=USD\nLeverage=500\n"
           f"Model={job.get('model',4)}\nOptimization=0\nFromDate={job['from']}\nToDate={job['to']}\n"
           f"ForwardMode=0\nReport={rep_name}\nReplaceReport=1\nShutdownTerminal=1\n\n[TesterInputs]\n")
    ini += "".join(f"{k}={v}\n" for k, v in inputs.items())
    with open(ini_path, "w", encoding="utf-8") as f:
        f.write(ini)
    subprocess.run(["taskkill", "/F", "/IM", "terminal64.exe"], capture_output=True)
    time.sleep(1)
    t0 = time.time()
    subprocess.Popen(f'"{TERMINAL_EXE}" /config:"{ini_path}"', shell=True)
    # Wait until terminal64.exe actually appears
    for _ in range(30):
        time.sleep(1)
        out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq terminal64.exe"], capture_output=True, text=True).stdout
        if "terminal64.exe" in out:
            break
    # Now wait for it to finish and exit
    while True:
        out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq terminal64.exe"], capture_output=True, text=True).stdout
        if "terminal64.exe" not in out:
            break
        if time.time() - t0 > timeout:
            subprocess.run(["taskkill", "/F", "/IM", "terminal64.exe"], capture_output=True)
            print(f"[{jid}] TIMEOUT", flush=True)
            break
        time.sleep(3)
    time.sleep(3)
    if not os.path.exists(term_rep) or os.path.getsize(term_rep) < 1000:
        print(f"[{jid}] NO REPORT", flush=True)
        return None
    shutil.copy2(term_rep, os.path.join(OUT, rep_name))
    png = term_rep.replace(".htm", ".png")
    if os.path.exists(png):
        shutil.copy2(png, os.path.join(OUT, rep_name.replace(".htm", ".png")))
    m = parse_report(os.path.join(OUT, rep_name))
    ex5 = os.path.join(TERMINAL_DATA, "MQL5", "Experts", job["expert"])
    mq5 = os.path.join(SRC_DIR, job["expert"].replace(".ex5", ".mq5"))
    row = {
        "id": jid, "expert": job["expert"], "mq5_sha": sha(mq5), "ex5_sha": sha(ex5),
        "ini_sha": sha(ini_path), "git": git_commit(), "from": job["from"], "to": job["to"],
        "model": job.get("model", 4), "quality": m.get("History Quality", ""),
        "net": m.get("Total Net Profit", ""), "gross_profit": m.get("Gross Profit", ""),
        "gross_loss": m.get("Gross Loss", ""), "pf": m.get("Profit Factor", ""),
        "exp_payoff": m.get("Expected Payoff", ""), "rf": m.get("Recovery Factor", ""),
        "sharpe": m.get("Sharpe Ratio", ""), "bal_dd": m.get("Balance Drawdown Maximal", ""),
        "eq_dd": m.get("Equity Drawdown Maximal", ""), "eq_dd_rel": m.get("Equity Drawdown Relative", ""),
        "trades": m.get("Total Trades", ""), "secs": int(time.time() - t0),
    }
    new = not os.path.exists(MANIFEST)
    with open(MANIFEST, "a", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(row.keys()))
        if new:
            w.writeheader()
        w.writerow(row)
    print(f"[{jid}] net={row['net']} pf={row['pf']} eqDD={row['eq_dd']} trades={row['trades']} q={row['quality']} ({row['secs']}s)", flush=True)
    return row


if __name__ == "__main__":
    jobs = json.load(open(sys.argv[1], encoding="utf-8-sig"))
    for j in jobs:
        run_job(j)

