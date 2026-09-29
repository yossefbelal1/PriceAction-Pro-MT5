import subprocess
import time
import os
import psutil

ini_path = r"c:\Users\NV LAP\Documents\antigravity\keen-tesla\tester_XAUUSD_D1.ini"
terminal_exe = r"C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe"

# 1. Kill any existing instances
for proc in psutil.process_iter(['name']):
    if proc.info['name'] and proc.info['name'].lower() in ['terminal64.exe', 'metatester64.exe']:
        try:
            proc.kill()
        except Exception:
            pass

time.sleep(2)

print(f"Launching MT5 terminal with config: {ini_path}")
term_proc = subprocess.Popen([terminal_exe, f"/config:{ini_path}"])
print(f"Terminal PID: {term_proc.pid}")

start_time = time.time()
max_duration = 300 # 5 minutes max

while time.time() - start_time < max_duration:
    time.sleep(3)
    active_procs = []
    for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_info']):
        try:
            name = proc.info['name']
            if name and name.lower() in ['terminal64.exe', 'metatester64.exe']:
                mem_mb = proc.info['memory_info'].rss / (1024 * 1024)
                active_procs.append(f"{name}(PID={proc.info['pid']}, Mem={mem_mb:.1f}MB)")
        except Exception:
            pass
    
    elapsed = int(time.time() - start_time)
    if active_procs:
        print(f"[{elapsed}s] Active: {', '.join(active_procs)}")
    else:
        print(f"[{elapsed}s] All MT5 processes finished.")
        break

print("Testing run complete. Checking outputs...")
report_path = r"C:\Users\NV LAP\Documents\antigravity\keen-tesla\PriceAction_XAUUSD_D1_Report.htm"
if os.path.exists(report_path):
    print(f"Report generated successfully: {report_path} ({os.path.getsize(report_path)} bytes)")
else:
    print(f"Report not found at {report_path}")
