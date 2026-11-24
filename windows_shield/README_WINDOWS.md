# Reclaim Desktop Shield for Windows

A lightweight, multi-layered anti-relapse and content restriction engine designed specifically for Windows laptops and PCs. 

Built with the same philosophy as the mobile Reclaim application: **zero telemetry, 100% on-device enforcement, ultra-low CPU footprint, and deep anti-tamper resilience**.

---

## Key Capabilities

1. **Multi-Browser Real-Time Interception:**
   - Actively monitors open tabs and windows across **Google Chrome, Microsoft Edge, Brave, Mozilla Firefox, Opera, Opera GX, Vivaldi, Arc, Tor, Waterfox, and LibreWolf**.
   - Inspects page titles and search queries (Google, Bing, DuckDuckGo, Reddit, etc.) against 40+ strict regex word-boundary patterns.
   - Instantly transmits `Ctrl+W` / `WM_CLOSE` to terminate the offending tab or window before content finishes loading.

2. **System-Level Hosts File Hardening:**
   - Injects **11,800+ verified explicit domains** into `C:\Windows\System32\drivers\etc\hosts` mapped to `0.0.0.0`.
   - Prevents any browser, background process, webview, or incognito window from establishing TCP/UDP connections to these domains.
   - Sets Windows file protection attributes (`attrib +r +h`) so the file cannot be easily edited or deleted.

3. **CleanBrowsing Family Filter DNS Enforcement:**
   - Automatically sets network adapter DNS to CleanBrowsing Family Filter (`185.228.168.168` and `185.228.169.168`).
   - Enforces search engine SafeSearch and network-level content sanitization across all Wi-Fi and Ethernet connections.

4. **Self-Healing Dual Watchdog (Anti-Kill):**
   - **Mutual Watchdog Architecture:** `reclaim_shield.py` (the active window scanner) and `reclaim_guardian.py` (the watchdog supervisor) continuously monitor each other. If either process is terminated in Task Manager, the other process resurrects it within 200–500 milliseconds.
   - Runs silently in the background (`pythonw.exe`) with no console window, no taskbar button, and zero clutter.

5. **Automatic Boot & Logon Persistence:**
   - Configured via Windows Task Scheduler (`schtasks`) to start automatically on system boot (`ONSTART`) under `NT AUTHORITY\SYSTEM` with highest privileges (`HIGHEST`).
   - Also automatically starts upon user logon (`ONLOGON`).

---

## Installation (One-Click)

1. Open the `windows_shield` folder.
2. Right-click **`install_shield.bat`** and select **"Run as administrator"**.
3. The installer will:
   - Copy all shield components to `C:\ProgramData\ReclaimShield\`.
   - Apply the 11,800+ domain hosts blocklist.
   - Configure CleanBrowsing Family DNS on your network adapters.
   - Register the Windows Scheduled Tasks for boot and logon.
   - Launch the background shield and guardian processes immediately.

*Protection is active immediately upon installation. No PC restart is required.*

---

## File Overview

- **`install_shield.bat`**: Elevated setup installer that configures tasks, DNS, and hosts file.
- **`reclaim_shield.py`**: The real-time browser window scanner that intercepts searches and adult tabs.
- **`reclaim_guardian.py`**: The mutual watchdog supervisor that protects and resurrects the shield.
- **`apply_hosts.py`**: Generates and applies the 11,800+ domain blocklist to the Windows hosts file.
- **`domains.txt`**: Curated list of 11,800+ explicit domains.
- **`enforce_dns.ps1`**: PowerShell script enforcing CleanBrowsing Family DNS.
- **`uninstall_shield.bat`**: Uninstaller to cleanly remove the scheduled tasks, reset DNS, and restore hosts file.

---

## Uninstallation

If you ever need to remove the protection:
1. Right-click **`uninstall_shield.bat`** and select **"Run as administrator"**.
2. This stops the background processes, deletes the scheduled tasks, resets network DNS to automatic (DHCP), and clears the hosts file entries.
