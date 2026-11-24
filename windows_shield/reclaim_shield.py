"""
Reclaim Desktop Shield - Real-Time Smart Browser & Web Watchdog
Monitors open browser windows, tab titles, and search queries across all browsers.
Instantly intercepts explicit content and closes unauthorized tabs.
"""

import os
import sys
import time
import re
import ctypes
from typing import Set

# Win32 Constants
WM_CLOSE = 0x0010
VK_CONTROL = 0x11
VK_W = 0x57
KEYEVENTF_KEYUP = 0x0002

user32 = ctypes.windll.user32
kernel32 = ctypes.windll.kernel32

# Comprehensive adult search terms & domain keyword patterns
BLOCKED_PATTERNS = [
    r'\bporn\b',
    r'\bporno\b',
    r'\bpornography\b',
    r'\bpornhub\b',
    r'\bxvideos\b',
    r'\bxnxx\b',
    r'\bxhamster\b',
    r'\bhentai\b',
    r'\bbrazzers\b',
    r'\bbangbros\b',
    r'\bredtube\b',
    r'\byouporn\b',
    r'\bspankbang\b',
    r'\be-hentai\b',
    r'\bnhentai\b',
    r'\brule34\b',
    r'\beporner\b',
    r'\bchaturbate\b',
    r'\bstripchat\b',
    r'\bbongacams\b',
    r'\blivejasmin\b',
    r'\bcam4\b',
    r'\bcamsoda\b',
    r'\bmyfreecams\b',
    r'\bjav\b',
    r'\bxxx\b',
    r'\badult video\b',
    r'\bfree porn\b',
    r'\bsex video\b',
    r'\bhardcore\b',
    r'\bnsfw\b',
    r'\bonlyfans\b',
    r'\bdrtuber\b',
    r'\bmotherless\b',
    r'\byoujizz\b',
    r'\btube8\b',
    r'\btxxx\b',
    r'\bporntrex\b',
    r'\bpornpics\b',
    r'\bsxyprn\b',
    r'\bclips4sale\b',
    r'\bsexcam\b',
    r'\bcamgirl\b'
]

COMPILED_PATTERNS = [re.compile(p, re.IGNORECASE) for p in BLOCKED_PATTERNS]

# Supported web browser processes
TARGET_BROWSERS: Set[str] = {
    'chrome.exe',
    'msedge.exe',
    'brave.exe',
    'firefox.exe',
    'opera.exe',
    'opera_gx.exe',
    'vivaldi.exe',
    'arc.exe',
    'tor.exe',
    'waterfox.exe',
    'librewolf.exe',
    'browser.exe'
}

def is_text_blocked(text: str) -> bool:
    if not text:
        return False
    lower = text.lower()
    for pattern in COMPILED_PATTERNS:
        if pattern.search(lower):
            return True
    return False

def close_tab_or_window(hwnd: int):
    """Closes the detected offending tab using Ctrl+W and WM_CLOSE."""
    try:
        # First send Ctrl+W keystroke to close the specific active tab
        user32.SetForegroundWindow(hwnd)
        user32.keybd_event(VK_CONTROL, 0, 0, 0)
        user32.keybd_event(VK_W, 0, 0, 0)
        time.sleep(0.05)
        user32.keybd_event(VK_W, 0, KEYEVENTF_KEYUP, 0)
        user32.keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0)
    except Exception:
        pass
    
    # Also post WM_CLOSE to ensure the window/tab terminates
    try:
        user32.PostMessageW(hwnd, WM_CLOSE, 0, 0)
    except Exception:
        pass

def inspect_windows():
    EnumWindowsProc = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_int, ctypes.c_int)
    
    def callback(hwnd, extra):
        if not user32.IsWindowVisible(hwnd):
            return True
        
        length = user32.GetWindowTextLengthW(hwnd)
        if length == 0:
            return True
        
        buff = ctypes.create_unicode_buffer(length + 1)
        user32.GetWindowTextW(hwnd, buff, length + 1)
        title = buff.value
        
        # Get process ID of window
        pid = ctypes.c_ulong()
        user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
        
        # Query process image executable name
        h_process = kernel32.OpenProcess(0x0400 | 0x0010, False, pid.value)
        if h_process:
            exe_buf = ctypes.create_unicode_buffer(1024)
            size = ctypes.c_ulong(1024)
            try:
                if kernel32.QueryFullProcessImageNameW(h_process, 0, exe_buf, ctypes.byref(size)):
                    exe_name = os.path.basename(exe_buf.value).lower()
                    if exe_name in TARGET_BROWSERS:
                        if is_text_blocked(title):
                            close_tab_or_window(hwnd)
            finally:
                kernel32.CloseHandle(h_process)
                
        return True

    user32.EnumWindows(EnumWindowsProc(callback), 0)

def ensure_guardian_alive():
    """Mutual watchdog check: ensure reclaim_guardian.py is running."""
    try:
        import psutil
        current_pid = os.getpid()
        guardian_found = False
        for p in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                if p.info['pid'] == current_pid:
                    continue
                cmdline = p.info.get('cmdline') or []
                cmd_str = ' '.join(cmdline).lower()
                if 'reclaim_guardian.py' in cmd_str:
                    guardian_found = True
                    break
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
                
        if not guardian_found:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            guardian_path = os.path.join(script_dir, 'reclaim_guardian.py')
            if os.path.exists(guardian_path):
                import subprocess
                subprocess.Popen(['pythonw', guardian_path], creationflags=0x08000000)
    except Exception:
        pass

def main():
    guardian_check_counter = 0
    while True:
        try:
            inspect_windows()
            
            # Check mutual guardian heartbeat every 3 seconds
            guardian_check_counter += 1
            if guardian_check_counter >= 15:
                guardian_check_counter = 0
                ensure_guardian_alive()
        except Exception:
            pass
        time.sleep(0.2)

if __name__ == '__main__':
    main()
