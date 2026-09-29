import subprocess
import time
import os
import psutil

ini_path = r"c:\Users\NV LAP\Documents\antigravity\keen-tesla\tester_integration_harness.ini"
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
max_duration = 180

while time.time() - start_time < max_duration:
    time.sleep(2)
    active_procs = []
    for proc in psutil.process_iter(['pid', 'name', 'memory_info']):
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

print("Integration run finished. Reading logs...")
log_path = r"C:\Users\NV LAP\AppData\Roaming\MetaQuotes\Tester\53785E099C927DB68A545C249CDBCE06\Agent-127.0.0.1-3000\logs\20260929.log"
if os.path.exists(log_path):
    with open(log_path, 'r', encoding='utf-16', errors='ignore') as f:
        lines = f.readlines()
    print(f"Total lines in agent log: {len(lines)}")
    harness_lines = []
    capture = False
    for l in lines:
        if 'Test_Integration_Harness' in l or 'STAGE' in l or 'TEST PASS' in l or 'TEST FAIL' in l:
            harness_lines.append(l.strip())
    print(f"Captured {len(harness_lines)} harness test lines:")
    for hl in harness_lines[-50:]:
        print(hl)
