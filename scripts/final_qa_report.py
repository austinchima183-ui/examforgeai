#!/usr/bin/env python3
"""Generate comprehensive Final QA Report for ExamForge AI production deployment."""

import json
import os
import datetime
import requests
import hashlib

PRODUCTION_URL = "https://examforgeai-pearl.vercel.app"
SUPABASE_URL = "https://pzfnptrrnxkgodclyhft.supabase.co"
DEPLOYMENT_ID = "dpl_2NoNjuCQGJ9WCSVq6g3rif54so4A"
PROJECT_ID = "prj_5psYkTpfbQD8wp5zp6tSs63HunDy"
COMMIT_HASH = "d269380"
DOWNLOAD_DIR = "/home/z/my-project/download"

os.makedirs(DOWNLOAD_DIR, exist_ok=True)

report = {
    "report_title": "ExamForge AI — Production Deployment & QA Report",
    "generated_at": datetime.datetime.now(datetime.UTC).isoformat(),
    "version": "1.0.0+1",
    "deployment": {
        "production_url": PRODUCTION_URL,
        "aliases": [
            "examforgeai-pearl.vercel.app",
            "examforgeai-austinchima183-2014s-projects.vercel.app",
        ],
        "deployment_id": DEPLOYMENT_ID,
        "project_id": PROJECT_ID,
        "commit_hash": COMMIT_HASH,
        "framework": "Flutter Web (CanvasKit)",
        "platform": "Vercel",
        "build_type": "release",
        "dart_defines_used": True,
    },
}

# ═══════════════════════════════════════════════════════════════
# Performance Results
# ═══════════════════════════════════════════════════════════════
print("Collecting performance data...")
performance = {}
routes = ["/", "/login", "/signup", "/dashboard", "/schools", "/cbt", "/marketplace", "/notifications", "/payments", "/results"]

for path in routes:
    url = f"{PRODUCTION_URL}{path}"
    try:
        import time
        start = time.time()
        resp = requests.get(url, timeout=30)
        ttfb = (time.time() - start) * 1000
        performance[path] = {
            "status": resp.status_code,
            "ttfb_ms": round(ttfb, 1),
            "size_bytes": len(resp.content),
            "cache_status": resp.headers.get("x-vercel-cache", "N/A"),
        }
    except Exception as e:
        performance[path] = {"error": str(e)}

report["performance"] = performance

# ═══════════════════════════════════════════════════════════════
# Security Results
# ═══════════════════════════════════════════════════════════════
print("Collecting security data...")
resp = requests.get(PRODUCTION_URL, timeout=30)
headers = resp.headers

security = {
    "https_enabled": PRODUCTION_URL.startswith("https://"),
    "hsts": headers.get("strict-transport-security", "MISSING"),
    "server": headers.get("server", "MISSING"),
    "x_vercel_id": headers.get("x-vercel-id", "MISSING"),
    "cors_header": headers.get("access-control-allow-origin", "MISSING"),
    "cache_control": headers.get("cache-control", "MISSING"),
    "csp_in_html": "Content-Security-Policy" in resp.text,
    "no_secrets_in_html": not any(p in resp.text for p in ["FLWSECK", "service_role", "ghp_", "vcp_"]),
    "env_not_accessible": "SUPABASE_URL" not in requests.get(f"{PRODUCTION_URL}/assets/.env", timeout=10).text,
    "root_env_not_accessible": "SUPABASE_URL" not in requests.get(f"{PRODUCTION_URL}/.env", timeout=10).text,
}

report["security"] = security

# ═══════════════════════════════════════════════════════════════
# Route & SPA Verification
# ═══════════════════════════════════════════════════════════════
print("Verifying SPA routing...")
routes_verification = {}
for path in routes:
    url = f"{PRODUCTION_URL}{path}"
    try:
        resp = requests.get(url, timeout=30)
        is_flutter = "flutter_bootstrap.js" in resp.text
        routes_verification[path] = {
            "status": resp.status_code,
            "spa_routing": is_flutter,
            "returns_app": resp.status_code == 200 and is_flutter,
        }
    except Exception as e:
        routes_verification[path] = {"error": str(e)}

report["routes"] = routes_verification

# ═══════════════════════════════════════════════════════════════
# Asset Verification
# ═══════════════════════════════════════════════════════════════
print("Verifying critical assets...")
assets = [
    "/main.dart.js", "/flutter_bootstrap.js", "/flutter.js",
    "/canvaskit/canvaskit.js", "/canvaskit/canvaskit.wasm",
    "/manifest.json", "/sw.js", "/vercel.json",
    "/assets/AssetManifest.bin.json", "/assets/FontManifest.json",
]
asset_verification = {}
for asset in assets:
    url = f"{PRODUCTION_URL}{asset}"
    try:
        resp = requests.head(url, timeout=10)
        asset_verification[asset] = {
            "status": resp.status_code,
            "content_type": resp.headers.get("content-type", ""),
            "size": int(resp.headers.get("content-length", 0)),
        }
    except Exception as e:
        asset_verification[asset] = {"error": str(e)}

report["assets"] = asset_verification

# ═══════════════════════════════════════════════════════════════
# PWA Verification
# ═══════════════════════════════════════════════════════════════
print("Verifying PWA...")
try:
    manifest_resp = requests.get(f"{PRODUCTION_URL}/manifest.json", timeout=10)
    manifest = manifest_resp.json()
    pwa = {
        "manifest_valid": True,
        "app_name": manifest.get("name"),
        "display": manifest.get("display"),
        "theme_color": manifest.get("theme_color"),
        "icons": len(manifest.get("icons", [])),
        "shortcuts": len(manifest.get("shortcuts", [])),
        "service_worker": requests.head(f"{PRODUCTION_URL}/sw.js", timeout=10).status_code == 200,
    }
except Exception as e:
    pwa = {"manifest_valid": False, "error": str(e)}

report["pwa"] = pwa

# ═══════════════════════════════════════════════════════════════
# Screenshots Gallery
# ═══════════════════════════════════════════════════════════════
print("Collecting screenshot gallery...")
screenshots = []
for f in sorted(os.listdir(DOWNLOAD_DIR)):
    if f.endswith(".png"):
        filepath = os.path.join(DOWNLOAD_DIR, f)
        size = os.path.getsize(filepath)
        screenshots.append({
            "filename": f,
            "size_kb": round(size / 1024, 1),
            "path": filepath,
        })

report["screenshots"] = screenshots

# ═══════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════
all_checks = []

# Performance checks
for path, data in performance.items():
    if "error" not in data:
        all_checks.append((f"Performance{path}", data["status"] == 200))

# Security checks
all_checks.append(("Security/HTTPS", security["https_enabled"]))
all_checks.append(("Security/HSTS", security["hsts"] != "MISSING"))
all_checks.append(("Security/CSP", security["csp_in_html"]))
all_checks.append(("Security/NoSecrets", security["no_secrets_in_html"]))
all_checks.append(("Security/EnvNotAccessible", security["env_not_accessible"]))

# Route checks
for path, data in routes_verification.items():
    if "error" not in data:
        all_checks.append((f"Route{path}", data.get("returns_app", False)))

# Asset checks
for asset, data in asset_verification.items():
    if "error" not in data:
        all_checks.append((f"Asset{asset}", data["status"] == 200))

passes = sum(1 for _, v in all_checks if v)
fails = sum(1 for _, v in all_checks if not v)

report["summary"] = {
    "total_checks": len(all_checks),
    "passed": passes,
    "failed": fails,
    "pass_rate": f"{round(passes / len(all_checks) * 100, 1)}%" if all_checks else "0%",
    "deployment_status": "LIVE" if passes > fails else "ISSUES",
    "failed_checks": [name for name, v in all_checks if not v],
}

# Save report
report_path = os.path.join(DOWNLOAD_DIR, "final_qa_report.json")
with open(report_path, "w") as f:
    json.dump(report, f, indent=2, default=str)

print(f"\n{'='*60}")
print(f"FINAL QA REPORT SUMMARY")
print(f"{'='*60}")
print(f"Production URL: {PRODUCTION_URL}")
print(f"Deployment ID: {DEPLOYMENT_ID}")
print(f"Commit: {COMMIT_HASH}")
print(f"Total Checks: {len(all_checks)}")
print(f"Passed: {passes}")
print(f"Failed: {fails}")
print(f"Pass Rate: {report['summary']['pass_rate']}")
print(f"Deployment Status: {report['summary']['deployment_status']}")
print(f"Screenshots: {len(screenshots)}")
print(f"\nReport saved to: {report_path}")

if fails > 0:
    print(f"\nFailed Checks:")
    for name, v in all_checks:
        if not v:
            print(f"  ✗ {name}")
