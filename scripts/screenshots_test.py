#!/usr/bin/env python3
"""Comprehensive screenshot and responsive test for ExamForge AI production."""

import subprocess
import time
import json
import os

DOWNLOAD_DIR = "/home/z/my-project/download"
PRODUCTION_URL = "https://examforgeai-pearl.vercel.app"

os.makedirs(DOWNLOAD_DIR, exist_ok=True)

def run_browser_cmd(cmd, timeout=30):
    """Run an agent-browser command."""
    try:
        result = subprocess.run(
            f"agent-browser {cmd}",
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return result.stdout.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return "TIMEOUT", -1
    except Exception as e:
        return str(e), -1

def take_screenshot(name, path=""):
    """Take a screenshot and save it."""
    filepath = os.path.join(DOWNLOAD_DIR, f"{name}.png")
    url = f"{PRODUCTION_URL}{path}"
    
    # Navigate
    run_browser_cmd(f"open \"{url}\"", timeout=30)
    time.sleep(8)  # Wait for Flutter to render
    
    # Take screenshot
    stdout, code = run_browser_cmd(f"screenshot {filepath}", timeout=15)
    
    # Check for errors
    run_browser_cmd("console", timeout=5)
    
    return filepath, code == 0

def set_viewport_and_screenshot(name, width, height, path=""):
    """Set viewport size and take screenshot."""
    filepath = os.path.join(DOWNLOAD_DIR, f"{name}.png")
    url = f"{PRODUCTION_URL}{path}"
    
    # Set viewport
    run_browser_cmd(f"set viewport {width} {height}", timeout=10)
    
    # Navigate
    run_browser_cmd(f"open \"{url}\"", timeout=30)
    time.sleep(10)  # Wait for Flutter to render
    
    # Take screenshot
    stdout, code = run_browser_cmd(f"screenshot {filepath}", timeout=15)
    
    return filepath, code == 0

# ═══════════════════════════════════════════════════════════════
# PHASE 8: Visual QA - Screenshots of all screens
# ═══════════════════════════════════════════════════════════════
print("=" * 60)
print("PHASE 8: Visual QA - Desktop Screenshots")
print("=" * 60)

# Set desktop viewport
run_browser_cmd("set viewport 1920 1080", timeout=10)

screenshots = {}

# Desktop screenshots
desktop_screenss = [
    ("11_desktop_home", "/"),
    ("12_desktop_login", "/login"),
    ("13_desktop_signup", "/signup"),
    ("14_desktop_dashboard", "/dashboard"),
    ("15_desktop_schools", "/schools"),
    ("16_desktop_cbt", "/cbt"),
    ("17_desktop_marketplace", "/marketplace"),
    ("18_desktop_notifications", "/notifications"),
    ("19_desktop_payments", "/payments"),
    ("20_desktop_results", "/results"),
]

for name, path in desktop_screenss:
    filepath, success = take_screenshot(name, path)
    screenshots[name] = {"path": path, "file": filepath, "success": success}
    status = "✓" if success else "✗"
    print(f"  {status} {name}: {path}")

# ═══════════════════════════════════════════════════════════════
# PHASE 4: Responsive Testing
# ═══════════════════════════════════════════════════════════════
print("\n" + "=" * 60)
print("PHASE 4: Responsive Testing")
print("=" * 60)

# Tablet (Portrait)
print("\n--- Tablet Portrait (768x1024) ---")
run_browser_cmd("set viewport 768 1024", timeout=10)
for name, path in [("21_tablet_portrait_home", "/"), ("22_tablet_portrait_login", "/login"), ("23_tablet_portrait_dashboard", "/dashboard")]:
    filepath, success = take_screenshot(name, path)
    screenshots[name] = {"path": path, "file": filepath, "success": success, "viewport": "768x1024"}
    status = "✓" if success else "✗"
    print(f"  {status} {name}")

# Tablet (Landscape)
print("\n--- Tablet Landscape (1024x768) ---")
run_browser_cmd("set viewport 1024 768", timeout=10)
for name, path in [("24_tablet_landscape_home", "/"), ("25_tablet_landscape_dashboard", "/dashboard")]:
    filepath, success = take_screenshot(name, path)
    screenshots[name] = {"path": path, "file": filepath, "success": success, "viewport": "1024x768"}
    status = "✓" if success else "✗"
    print(f"  {status} {name}")

# Mobile (Portrait)
print("\n--- Mobile Portrait (375x812) ---")
run_browser_cmd("set viewport 375 812", timeout=10)
for name, path in [("26_mobile_portrait_home", "/"), ("27_mobile_portrait_login", "/login"), ("28_mobile_portrait_dashboard", "/dashboard")]:
    filepath, success = take_screenshot(name, path)
    screenshots[name] = {"path": path, "file": filepath, "success": success, "viewport": "375x812"}
    status = "✓" if success else "✗"
    print(f"  {status} {name}")

# Mobile (Landscape)
print("\n--- Mobile Landscape (812x375) ---")
run_browser_cmd("set viewport 812 375", timeout=10)
for name, path in [("29_mobile_landscape_home", "/"), ("30_mobile_landscape_login", "/login")]:
    filepath, success = take_screenshot(name, path)
    screenshots[name] = {"path": path, "file": filepath, "success": success, "viewport": "812x375"}
    status = "✓" if success else "✗"
    print(f"  {status} {name}")

# Laptop
print("\n--- Laptop (1366x768) ---")
run_browser_cmd("set viewport 1366 768", timeout=10)
for name, path in [("31_laptop_home", "/"), ("32_laptop_dashboard", "/dashboard")]:
    filepath, success = take_screenshot(name, path)
    screenshots[name] = {"path": path, "file": filepath, "success": success, "viewport": "1366x768"}
    status = "✓" if success else "✗"
    print(f"  {status} {name}")

# Save screenshot results
results_path = os.path.join(DOWNLOAD_DIR, "screenshot_results.json")
with open(results_path, "w") as f:
    json.dump(screenshots, f, indent=2)

print(f"\nScreenshot results saved to {results_path}")
print(f"Total screenshots: {len(screenshots)}")
print(f"Successful: {sum(1 for v in screenshots.values() if v['success'])}")
print(f"Failed: {sum(1 for v in screenshots.values() if not v['success'])}")
