"""
Reclaim Desktop Shield - System Hosts File Hardener
Maps thousands of verified explicit domains to 0.0.0.0 in Windows hosts file.
Prevents any browser or application from establishing connection.
"""

import os
import sys
import subprocess

HOSTS_PATH = r"C:\Windows\System32\drivers\etc\hosts"
START_MARKER = "# === BEGIN RECLAIM SHIELD BLOCKLIST ==="
END_MARKER = "# === END RECLAIM SHIELD BLOCKLIST ==="

def load_domains():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    domains_file = os.path.join(script_dir, "domains.txt")
    if not os.path.exists(domains_file):
        # Fallback to assets
        domains_file = os.path.join(script_dir, "..", "assets", "listofsitetoblock.md")
        
    domains = set()
    if os.path.exists(domains_file):
        with open(domains_file, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                d = line.strip().lower()
                if d and not d.startswith("```") and not d.startswith("#"):
                    # remove http:// or https:// if present
                    d = d.replace("https://", "").replace("http://", "").split("/")[0]
                    if "." in d:
                        domains.add(d)
    return sorted(domains)

def apply_blocklist():
    if not os.path.exists(HOSTS_PATH):
        print(f"Error: {HOSTS_PATH} not found.")
        return False

    # Remove read-only attribute before editing
    try:
        subprocess.run(["attrib", "-r", "-h", HOSTS_PATH], capture_output=True, check=False)
    except Exception:
        pass

    with open(HOSTS_PATH, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    # Remove previous Reclaim block if present
    if START_MARKER in content and END_MARKER in content:
        start_idx = content.find(START_MARKER)
        end_idx = content.find(END_MARKER) + len(END_MARKER)
        content = content[:start_idx].rstrip() + "\n" + content[end_idx:].lstrip()

    domains = load_domains()
    if not domains:
        print("Warning: No domains loaded.")
        return False

    print(f"Loaded {len(domains)} domains from blocklist.")

    block_lines = [START_MARKER]
    for d in domains:
        block_lines.append(f"0.0.0.0 {d}")
        if not d.startswith("www."):
            block_lines.append(f"0.0.0.0 www.{d}")
    block_lines.append(END_MARKER)

    updated_content = content.rstrip() + "\n\n" + "\n".join(block_lines) + "\n"

    with open(HOSTS_PATH, "w", encoding="utf-8") as f:
        f.write(updated_content)

    # Re-apply read-only attribute
    try:
        subprocess.run(["attrib", "+r", "+h", HOSTS_PATH], capture_output=True, check=False)
    except Exception:
        pass

    # Flush Windows DNS Cache
    try:
        subprocess.run(["ipconfig", "/flushdns"], capture_output=True, check=False)
        print("Successfully flushed DNS cache.")
    except Exception:
        pass

    print(f"Successfully applied {len(domains)} blocked domains to Windows hosts file.")
    return True

if __name__ == "__main__":
    apply_blocklist()
