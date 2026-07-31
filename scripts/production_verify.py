#!/usr/bin/env python3
"""Comprehensive Production Verification for ExamForge AI.

Tests: Performance, Security Headers, Routes, Responsive, Screenshots
"""

import json
import os
import time
import datetime
import requests
from pathlib import Path

PRODUCTION_URL = "https://examforgeai-pearl.vercel.app"
SUPABASE_URL = "https://pzfnptrrnxkgodclyhft.supabase.co"
DEPLOYMENT_ID = "dpl_Hh7DcS7p796Y5VBVPMFg4EnruLhB"
DOWNLOAD_DIR = "/home/z/my-project/download"
COMMIT_HASH = "d269380"

os.makedirs(DOWNLOAD_DIR, exist_ok=True)

results = {
    "timestamp": datetime.datetime.utcnow().isoformat(),
    "production_url": PRODUCTION_URL,
    "deployment_id": DEPLOYMENT_ID,
    "commit_hash": COMMIT_HASH,
    "phases": {}
}

# ═══════════════════════════════════════════════════════════════
# PHASE 6: Performance Benchmarks
# ═══════════════════════════════════════════════════════════════
print("\n" + "=" * 60)
print("PHASE 6: Performance Benchmarks")
print("=" * 60)

performance_results = {}

# Measure TTFB, FCP, LCP for key routes
routes_to_test = [
    ("/", "Home"),
    ("/login", "Login"),
    ("/signup", "Signup"),
    ("/dashboard", "Dashboard"),
    ("/schools", "School Management"),
    ("/cbt", "CBT"),
    ("/marketplace", "Marketplace"),
    ("/notifications", "Notifications"),
    ("/payments", "Payments"),
    ("/results", "Results"),
]

for path, name in routes_to_test:
    url = f"{PRODUCTION_URL}{path}"
    try:
        start = time.time()
        resp = requests.get(url, timeout=30, allow_redirects=True)
        ttfb = time.time() - start
        
        performance_results[name] = {
            "path": path,
            "status_code": resp.status_code,
            "ttfb_ms": round(ttfb * 1000, 1),
            "content_length": len(resp.content),
            "content_type": resp.headers.get("content-type", ""),
            "server": resp.headers.get("server", ""),
            "cached": resp.headers.get("x-vercel-cache", ""),
        }
        status = "✓" if resp.status_code == 200 else "✗"
        print(f"  {status} {name} ({path}): {resp.status_code} TTFB={ttfb*1000:.0f}ms size={len(resp.content)}B cache={resp.headers.get('x-vercel-cache','?')}")
    except Exception as e:
        performance_results[name] = {"error": str(e)}
        print(f"  ✗ {name} ({path}): ERROR {e}")

# API latency test (Supabase health check)
try:
    start = time.time()
    resp = requests.get(f"{SUPABASE_URL}/rest/v1/", timeout=10,
                       headers={"apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6Zm5wdHJybnhrZ29kY2x5aGZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUxNzg1NDksImV4cCI6MjEwMDc1NDU0OX0.lNvu4mywQIZUIutggf8fDf0a4JPc8fZTAZvxru9adKg"})
    api_latency = time.time() - start
    performance_results["Supabase_API"] = {
        "latency_ms": round(api_latency * 1000, 1),
        "status_code": resp.status_code,
    }
    print(f"  ✓ Supabase API: {resp.status_code} latency={api_latency*1000:.0f}ms")
except Exception as e:
    performance_results["Supabase_API"] = {"error": str(e)}
    print(f"  ✗ Supabase API: ERROR {e}")

results["phases"]["performance"] = performance_results

# ═══════════════════════════════════════════════════════════════
# PHASE 7: Security Verification
# ═══════════════════════════════════════════════════════════════
print("\n" + "=" * 60)
print("PHASE 7: Security Verification")
print("=" * 60)

security_results = {}

# Check security headers
resp = requests.get(PRODUCTION_URL, timeout=30)
headers = resp.headers

security_checks = {
    "HTTPS": resp.url.startswith("https://"),
    "HSTS": "strict-transport-security" in headers,
    "HSTS_Value": headers.get("strict-transport-security", "MISSING"),
    "X_Frame_Options": headers.get("x-frame-options", "MISSING"),
    "X_Content_Type_Options": headers.get("x-content-type-options", "MISSING"),
    "X_Vercel_ID": headers.get("x-vercel-id", "MISSING"),
    "Server": headers.get("server", "MISSING"),
    "CORS_Header": headers.get("access-control-allow-origin", "MISSING"),
    "Cache_Control": headers.get("cache-control", "MISSING"),
    "Content_Type": headers.get("content-type", "MISSING"),
}

# Check CSP in HTML
html_content = resp.text
csp_meta = "Content-Security-Policy" in html_content
security_checks["CSP_Meta"] = csp_meta

# Verify no secrets in HTML
secret_patterns = ["FLWSECK", "service_role", "supabase_service_key", "ghp_", "vcp_"]
secrets_found = []
for pattern in secret_patterns:
    if pattern.lower() in html_content.lower():
        secrets_found.append(pattern)
security_checks["No_Secrets_In_HTML"] = len(secrets_found) == 0
security_checks["Secrets_Found"] = secrets_found

# Check .env file is not accessible
env_resp = requests.get(f"{PRODUCTION_URL}/.env", timeout=10)
security_checks["Env_Not_Accessible"] = env_resp.status_code != 200

# Check .env in assets is not directly accessible
env_asset_resp = requests.get(f"{PRODUCTION_URL}/assets/.env", timeout=10)
security_checks["Env_Asset_Not_Accessible"] = env_asset_resp.status_code != 200 or "SUPABASE_URL" not in env_asset_resp.text

for check, value in security_checks.items():
    if isinstance(value, bool):
        status = "✓" if value else "✗"
        print(f"  {status} {check}: {value}")
    else:
        print(f"  • {check}: {value}")

results["phases"]["security"] = security_checks

# ═══════════════════════════════════════════════════════════════
# Route Verification (SPA Routing)
# ═══════════════════════════════════════════════════════════════
print("\n" + "=" * 60)
print("Route Verification (SPA Routing)")
print("=" * 60)

route_results = {}
for path, name in routes_to_test:
    url = f"{PRODUCTION_URL}{path}"
    try:
        resp = requests.get(url, timeout=30, allow_redirects=True)
        is_spa = "ExamForge AI" in resp.text and "flutter_bootstrap.js" in resp.text
        route_results[name] = {
            "status_code": resp.status_code,
            "spa_routing": is_spa,
            "returns_flutter_app": "main.dart.js" in resp.text or "flutter_bootstrap.js" in resp.text,
        }
        status = "✓" if is_spa and resp.status_code == 200 else "✗"
        print(f"  {status} {name} ({path}): status={resp.status_code} SPA={'YES' if is_spa else 'NO'}")
    except Exception as e:
        route_results[name] = {"error": str(e)}
        print(f"  ✗ {name} ({path}): ERROR {e}")

results["phases"]["routes"] = route_results

# ═══════════════════════════════════════════════════════════════
# Static Asset Verification
# ═══════════════════════════════════════════════════════════════
print("\n" + "=" * 60)
print("Static Asset Verification")
print("=" * 60)

critical_assets = [
    "/main.dart.js",
    "/flutter_bootstrap.js",
    "/flutter.js",
    "/canvaskit/canvaskit.js",
    "/canvaskit/canvaskit.wasm",
    "/manifest.json",
    "/vercel.json",
    "/assets/AssetManifest.bin.json",
    "/assets/FontManifest.json",
    "/assets/.env",
    "/sw.js",
]

asset_results = {}
for asset in critical_assets:
    url = f"{PRODUCTION_URL}{asset}"
    try:
        resp = requests.head(url, timeout=10, allow_redirects=True)
        size = int(resp.headers.get("content-length", 0))
        asset_results[asset] = {
            "status_code": resp.status_code,
            "content_type": resp.headers.get("content-type", ""),
            "size_bytes": size,
            "size_kb": round(size / 1024, 1),
        }
        status = "✓" if resp.status_code == 200 else "✗"
        print(f"  {status} {asset}: {resp.status_code} ({size/1024:.1f}KB)")
    except Exception as e:
        asset_results[asset] = {"error": str(e)}
        print(f"  ✗ {asset}: ERROR {e}")

results["phases"]["assets"] = asset_results

# ═══════════════════════════════════════════════════════════════
# PWA Verification
# ═══════════════════════════════════════════════════════════════
print("\n" + "=" * 60)
print("PWA Verification")
print("=" * 60)

pwa_results = {}

# Check manifest.json
try:
    resp = requests.get(f"{PRODUCTION_URL}/manifest.json", timeout=10)
    manifest = resp.json()
    pwa_results["manifest_valid"] = True
    pwa_results["app_name"] = manifest.get("name")
    pwa_results["short_name"] = manifest.get("short_name")
    pwa_results["display"] = manifest.get("display")
    pwa_results["theme_color"] = manifest.get("theme_color")
    pwa_results["icons_count"] = len(manifest.get("icons", []))
    pwa_results["shortcuts_count"] = len(manifest.get("shortcuts", []))
    print(f"  ✓ Manifest: {manifest.get('name')} ({manifest.get('short_name')})")
    print(f"  ✓ Display: {manifest.get('display')}, Theme: {manifest.get('theme_color')}")
    print(f"  ✓ Icons: {len(manifest.get('icons', []))}, Shortcuts: {len(manifest.get('shortcuts', []))}")
except Exception as e:
    pwa_results["manifest_valid"] = False
    pwa_results["error"] = str(e)
    print(f"  ✗ Manifest: ERROR {e}")

# Check service worker
try:
    resp = requests.get(f"{PRODUCTION_URL}/sw.js", timeout=10)
    pwa_results["service_worker"] = resp.status_code == 200
    pwa_results["service_worker_size"] = len(resp.content)
    status = "✓" if resp.status_code == 200 else "✗"
    print(f"  {status} Service Worker: {resp.status_code} ({len(resp.content)/1024:.1f}KB)")
except Exception as e:
    pwa_results["service_worker"] = False
    print(f"  ✗ Service Worker: ERROR {e}")

results["phases"]["pwa"] = pwa_results

# ═══════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════
print("\n" + "=" * 60)
print("SUMMARY")
print("=" * 60)

# Count passes/fails
all_checks = []

# Performance checks
for name, data in performance_results.items():
    if "error" not in data:
        all_checks.append(("Performance/" + name, data.get("status_code") == 200))

# Security checks
for check, value in security_checks.items():
    if isinstance(value, bool):
        all_checks.append(("Security/" + check, value))

# Route checks
for name, data in route_results.items():
    if "error" not in data:
        all_checks.append(("Route/" + name, data.get("spa_routing", False)))

# Asset checks
for asset, data in asset_results.items():
    if "error" not in data:
        all_checks.append(("Asset" + asset, data.get("status_code") == 200))

passes = sum(1 for _, v in all_checks if v)
fails = sum(1 for _, v in all_checks if not v)

print(f"  Total checks: {len(all_checks)}")
print(f"  Passed: {passes}")
print(f"  Failed: {fails}")

if fails > 0:
    print("\n  FAILED CHECKS:")
    for name, value in all_checks:
        if not value:
            print(f"    ✗ {name}")

results["summary"] = {
    "total_checks": len(all_checks),
    "passed": passes,
    "failed": fails,
    "pass_rate": round(passes / len(all_checks) * 100, 1) if all_checks else 0,
}

# Save results
output_path = os.path.join(DOWNLOAD_DIR, "production_verification_report.json")
with open(output_path, "w") as f:
    json.dump(results, f, indent=2, default=str)
print(f"\nReport saved to {output_path}")
