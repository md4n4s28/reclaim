"""
Reclaim Desktop Guardian - Anti-Kill Mutual Watchdog
Monitors the Reclaim Shield process. If terminated or killed, resurrects it within milliseconds.
"""

import os
import sys
import time
import subprocess
import psutil

CREATE_NO_WINDOW = 0x08000000

def is_shield_running() -> bool:
    current_pid = os.getpid()
    for p in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            if p.info['pid'] == current_pid:
                continue
            cmdline = p.info.get('cmdline') or []
            cmd_str = ' '.join(cmdline).lower()
            if 'reclaim_shield.py' in cmd_str:
                return True
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    return False

def resurrect_shield():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    shield_script = os.path.join(script_dir, 'reclaim_shield.py')
    if os.path.exists(shield_script):
        try:
            # Try running with pythonw first (invisible window)
            subprocess.Popen(['pythonw', shield_script], creationflags=CREATE_NO_WINDOW)
        except Exception:
            try:
                subprocess.Popen(['python', shield_script], creationflags=CREATE_NO_WINDOW)
            except Exception:
                pass

def main():
    while True:
        try:
            if not is_shield_running():
                resurrect_shield()
        except Exception:
            pass
        time.sleep(0.5)

if __name__ == '__main__':
    main()
