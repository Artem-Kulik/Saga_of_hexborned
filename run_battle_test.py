#!/usr/bin/env python3
"""
MP Battle Stress-Test Launcher
Запускає два інстанси Godot (HOST + CLIENT), відіграє N боїв ботами,
збирає логи і виводить повний звіт помилок.

Використання:
    python3 run_battle_test.py [n_battles] [--headless]

    n_battles   кількість боїв (за замовчуванням: 50)
    --headless  запустити без вікна (може не працювати з деякими ефектами)

Приклади:
    python3 run_battle_test.py
    python3 run_battle_test.py 100
    python3 run_battle_test.py 30 --headless

Можна вказати шлях до Godot через змінну середовища:
    GODOT_BIN=/path/to/godot python3 run_battle_test.py
"""

import subprocess
import threading
import sys
import os
import time
import re
from pathlib import Path
from datetime import datetime

# ─── Config ──────────────────────────────────────────────────────────────────
PROJECT_PATH = Path(__file__).parent.resolve()
PORT         = 7777
HOST_IP      = "127.0.0.1"

N_BATTLES = 50
HEADLESS  = False

for arg in sys.argv[1:]:
    if arg == "--headless":
        HEADLESS = True
    elif arg.isdigit():
        N_BATTLES = int(arg)

# ─── Find Godot binary ───────────────────────────────────────────────────────
GODOT_CANDIDATES = [
    os.environ.get("GODOT_BIN", ""),
    "/Applications/Godot.app/Contents/MacOS/Godot",
    "/Applications/Godot_v4.app/Contents/MacOS/Godot",
    os.path.expanduser("~/Applications/Godot.app/Contents/MacOS/Godot"),
    os.path.expanduser("~/Applications/Godot_v4.app/Contents/MacOS/Godot"),
    "godot4",
    "godot",
]

def find_godot() -> str:
    for candidate in GODOT_CANDIDATES:
        if not candidate:
            continue
        path = Path(candidate)
        if path.exists() and os.access(str(path), os.X_OK):
            return str(path)
        # Try as a command in PATH
        result = subprocess.run(["which", candidate], capture_output=True, text=True)
        if result.returncode == 0:
            return result.stdout.strip()
    return None

# ─── Log collection ───────────────────────────────────────────────────────────
class RoleLog:
    def __init__(self, role: str):
        self.role   = role
        self.lines  = []
        self.errors = []
        self.battles: list[dict] = []   # [{result, turn_count}]
        self.skills_fail: list[str] = []
        self.report_lines: list[str] = []
        self._in_report = False
        self._battle_turns = 0

    def ingest(self, raw: str):
        line = raw.rstrip()
        if not line:
            return
        self.lines.append(line)

        if "[BOT_DONE]" in line:
            self._in_report = False

        if self._in_report:
            self.report_lines.append(line)

        if "[FINAL_REPORT]" in line:
            self._in_report = True
            self.report_lines.append(line)
            return

        if "[ERROR]" in line:
            self.errors.append(line)

        if "[BATTLE_END]" in line:
            result_m = re.search(r"result=(\w+)", line)
            result = result_m.group(1) if result_m else "?"
            self.battles.append({"result": result, "turns": self._battle_turns})
            self._battle_turns = 0

        if "[BOT_ACT]" in line or "[SKILL]" in line:
            self._battle_turns += 1

        if "[SKILL]" in line and "FAIL" in line:
            self.skills_fail.append(line)

    def summary(self) -> str:
        wins  = sum(1 for b in self.battles if b["result"] == "WIN")
        loses = sum(1 for b in self.battles if b["result"] == "LOSE")
        stuck = sum(1 for b in self.battles if b["result"] == "STUCK")
        return (f"{self.role}: {len(self.battles)} battles  "
                f"WIN={wins} LOSE={loses} STUCK={stuck}  "
                f"errors={len(self.errors)}")

# ─── Stream reader ────────────────────────────────────────────────────────────
def stream_reader(stream, role_log: RoleLog, prefix: str):
    try:
        for raw_line in iter(stream.readline, b""):
            text = raw_line.decode("utf-8", errors="replace").rstrip()
            if text:
                role_log.ingest(text)
                # Print to terminal with prefix for live monitoring
                print(f"{prefix} {text}", flush=True)
    except Exception:
        pass

# ─── Build Godot command ──────────────────────────────────────────────────────
def make_cmd(godot: str, role: str, ip: str = HOST_IP) -> list:
    base = [godot, "--path", str(PROJECT_PATH)]
    if HEADLESS:
        base += ["--headless", "--display-driver", "headless"]
    if role == "host":
        base += ["--", "--bot-host", str(N_BATTLES)]
    else:
        base += ["--", "--bot-client", ip]
    return base

# ─── Main ─────────────────────────────────────────────────────────────────────
def main():
    godot = find_godot()
    if not godot:
        print("ERROR: Godot не знайдено!")
        print("Встановіть GODOT_BIN=/path/to/godot або додайте godot до PATH.")
        print(f"Перевірені шляхи: {GODOT_CANDIDATES}")
        sys.exit(1)

    print(f"Godot    : {godot}")
    print(f"Project  : {PROJECT_PATH}")
    print(f"Battles  : {N_BATTLES}")
    print(f"Headless : {HEADLESS}")
    print(f"Time     : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)

    host_log   = RoleLog("HOST")
    client_log = RoleLog("CLIENT")

    # Launch HOST
    host_cmd = make_cmd(godot, "host")
    print(f"HOST cmd : {' '.join(host_cmd)}")
    host_proc = subprocess.Popen(
        host_cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        cwd=str(PROJECT_PATH),
    )

    # Small delay before CLIENT so HOST has time to bind the port
    time.sleep(2.0)

    client_cmd = make_cmd(godot, "client")
    print(f"CLIENT cmd: {' '.join(client_cmd)}")
    client_proc = subprocess.Popen(
        client_cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        cwd=str(PROJECT_PATH),
    )

    # Start reader threads
    t_host = threading.Thread(
        target=stream_reader,
        args=(host_proc.stdout, host_log, "[H]"),
        daemon=True,
    )
    t_client = threading.Thread(
        target=stream_reader,
        args=(client_proc.stdout, client_log, "[C]"),
        daemon=True,
    )
    t_host.start()
    t_client.start()

    # Wait for both to finish (with a safety timeout)
    max_wait_sec = N_BATTLES * 60 + 120   # generous timeout
    deadline = time.time() + max_wait_sec

    while time.time() < deadline:
        host_done   = host_proc.poll()   is not None
        client_done = client_proc.poll() is not None
        if host_done and client_done:
            break
        time.sleep(2)

    # Kill any still running
    for proc in (host_proc, client_proc):
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()

    t_host.join(timeout=3)
    t_client.join(timeout=3)

    # ─── Generate report ──────────────────────────────────────────────────
    sep  = "=" * 72
    sep2 = "-" * 72
    ts   = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    report_path = PROJECT_PATH / f"battle_test_report_{ts}.txt"

    lines = [
        sep,
        f"MP BATTLE STRESS-TEST REPORT",
        f"Date     : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"Battles  : {N_BATTLES}",
        f"Godot    : {godot}",
        sep,
        "",
        "SUMMARY",
        host_log.summary(),
        client_log.summary(),
        "",
    ]

    # Errors section
    all_errors = (
        [(f"[HOST] {e}") for e in host_log.errors]
        + [(f"[CLIENT] {e}") for e in client_log.errors]
    )
    lines += [sep2, f"ERRORS ({len(all_errors)} total)", sep2]
    if all_errors:
        lines += all_errors
    else:
        lines += ["  (no errors detected)"]
    lines.append("")

    # Per-battle breakdown
    lines += [sep2, "PER-BATTLE RESULTS", sep2]
    max_b = max(len(host_log.battles), len(client_log.battles))
    for i in range(max_b):
        h = host_log.battles[i]   if i < len(host_log.battles)   else {"result": "?", "turns": 0}
        c = client_log.battles[i] if i < len(client_log.battles) else {"result": "?", "turns": 0}
        lines.append(f"  battle {i+1:03d}  HOST={h['result']:<5}  CLIENT={c['result']:<5}  "
                     f"turns≈{max(h['turns'], c['turns'])}")
    lines.append("")

    # Skill failures
    skill_fails = host_log.skills_fail + client_log.skills_fail
    lines += [sep2, f"SKILL FAILURES ({len(skill_fails)})", sep2]
    if skill_fails:
        for sf in skill_fails:
            lines.append("  " + sf)
    else:
        lines += ["  (none)"]
    lines.append("")

    # Full godot-side final reports
    for rl in (host_log, client_log):
        if rl.report_lines:
            lines += [sep2, f"{rl.role} FINAL REPORT (from Godot)", sep2]
            lines += rl.report_lines
            lines.append("")

    # Raw logs (last 200 lines per role for context)
    for rl in (host_log, client_log):
        tail = rl.lines[-200:]
        lines += [sep2, f"{rl.role} RAW LOG (last {len(tail)} lines)", sep2]
        lines += tail
        lines.append("")

    report_text = "\n".join(lines)

    with open(report_path, "w", encoding="utf-8") as f:
        f.write(report_text)

    print("\n" + sep)
    print("TEST COMPLETE")
    print(host_log.summary())
    print(client_log.summary())
    print(f"Report saved: {report_path}")
    print(sep)

if __name__ == "__main__":
    main()
