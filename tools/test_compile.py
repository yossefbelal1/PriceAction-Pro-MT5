import subprocess, time, os, shutil

editor = r"C:\Program Files\MetaTrader 5 EXNESS\metaeditor64.exe"
repo_mq5 = r"c:\Users\NV LAP\Documents\antigravity\keen-tesla\Aurum_Imperium_Apex_v12_TTrades_Mechanical.mq5"
term_mq5 = r"C:\Users\NV LAP\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Experts\Aurum_Imperium_Apex_v12_TTrades_Mechanical.mq5"
term_ex5 = term_mq5.replace(".mq5", ".ex5")
log_file = r"C:\Users\NV LAP\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Experts\comp.log"

shutil.copyfile(repo_mq5, term_mq5)

if os.path.exists(term_ex5):
    os.remove(term_ex5)
if os.path.exists(log_file):
    os.remove(log_file)

cmd = f'"{editor}" /compile:"{term_mq5}" /log:"{log_file}"'
print("Executing:", cmd)
p = subprocess.run(cmd, shell=True)
print("Subprocess returned:", p.returncode)

for _ in range(10):
    time.sleep(1)
    if os.path.exists(log_file) or os.path.exists(term_ex5):
        break

if os.path.exists(log_file):
    with open(log_file, "r", encoding="utf-16le", errors="ignore") as f:
        text = f.read()
        print("LOG CONTENTS:\n", text.encode("ascii", errors="replace").decode("ascii"))
else:
    print("NO LOG FILE FOUND!")

print("EX5 created:", os.path.exists(term_ex5))
if os.path.exists(term_ex5):
    print("EX5 size:", os.path.getsize(term_ex5))
    shutil.copyfile(term_ex5, repo_mq5.replace(".mq5", ".ex5"))
