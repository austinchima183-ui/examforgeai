#!/usr/bin/env python3
"""Deploy Flutter Web build to Vercel using the API - correct headers and format."""

import os
import json
import hashlib
import requests
import sys
import time

VERCEL_TOKEN = "vcp_0JCVYeIlppY7pSBMug6NQp2dsxTqOhzOPXZMNOxzcNbT5ggevZ2QJVU7"
PROJECT_ID = "prj_5psYkTpfbQD8wp5zp6tSs63HunDy"
TEAM_ID = "team_hbVXkzeMbXEmG1e6FO4tq4vB"
BASE_URL = "https://api.vercel.com"
BUILD_DIR = "/home/z/my-project/examforgeai_repo/build/web"

HEADERS = {
    "Authorization": f"Bearer {VERCEL_TOKEN}",
    "Content-Type": "application/json",
}

def get_file_sha(filepath):
    """Get SHA1 hash of a file (hex digest)."""
    h = hashlib.sha1()
    with open(filepath, "rb") as f:
        while True:
            chunk = f.read(8192)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()

def collect_files(build_dir):
    """Collect all files in the build directory."""
    files = []
    for root, dirs, filenames in os.walk(build_dir):
        dirs[:] = [d for d in dirs if d != ".vercel"]
        for filename in filenames:
            filepath = os.path.join(root, filename)
            rel_path = os.path.relpath(filepath, build_dir)
            sha = get_file_sha(filepath)
            size = os.path.getsize(filepath)
            files.append({
                "file": rel_path,
                "sha": sha,
                "size": size,
                "filepath": filepath,
            })
    return files

def upload_file(filepath, sha):
    """Upload a single file to Vercel with x-vercel-digest header."""
    with open(filepath, "rb") as f:
        content = f.read()
    
    resp = requests.post(
        f"{BASE_URL}/v2/files",
        headers={
            "Authorization": f"Bearer {VERCEL_TOKEN}",
            "Content-Type": "application/octet-stream",
            "x-vercel-digest": sha,
        },
        params={"teamId": TEAM_ID},
        data=content,
        timeout=300,
    )
    
    return resp.status_code in (200, 201), resp.text[:500]

def create_deployment(files):
    """Create a Vercel deployment using file references (files already uploaded)."""
    file_payloads = [{"file": f["file"], "sha": f["sha"], "size": f["size"]} for f in files]
    
    payload = {
        "name": "examforgeai",
        "project": PROJECT_ID,
        "target": "production",
        "files": file_payloads,
    }
    
    print(f"\nCreating deployment with {len(files)} file references...")
    
    resp = requests.post(
        f"{BASE_URL}/v13/deployments?teamId={TEAM_ID}",
        headers=HEADERS,
        json=payload,
        timeout=120,
    )
    
    if resp.status_code not in (200, 201):
        print(f"Error creating deployment: {resp.status_code}")
        error_text = resp.text[:2000]
        print(error_text)
        
        # If there are missing files, upload them and retry
        try:
            data = resp.json()
            if data.get("error", {}).get("code") == "missing_files":
                missing = data.get("error", {}).get("missing", [])
                print(f"\n{len(missing)} files are missing. Uploading them...")
                for m in missing:
                    for f in files:
                        if f["sha"] == m:
                            print(f"  Uploading {f['file']} (sha: {m[:12]}...)...")
                            success, msg = upload_file(f["filepath"], f["sha"])
                            print(f"    {'OK' if success else 'FAILED: ' + msg[:100]}")
                            break
                
                # Retry
                print("\nRetrying deployment creation...")
                resp2 = requests.post(
                    f"{BASE_URL}/v13/deployments?teamId={TEAM_ID}",
                    headers=HEADERS,
                    json=payload,
                    timeout=120,
                )
                if resp2.status_code in (200, 201):
                    return resp2.json()
                else:
                    print(f"Retry failed: {resp2.status_code}")
                    print(resp2.text[:2000])
                    return None
        except:
            pass
        return None
    
    return resp.json()

def wait_for_deployment(deployment_id):
    """Wait for deployment to complete."""
    print(f"\nWaiting for deployment {deployment_id} to complete...")
    
    for i in range(120):
        resp = requests.get(
            f"{BASE_URL}/v13/deployments/{deployment_id}",
            headers=HEADERS,
            params={"teamId": TEAM_ID},
            timeout=30,
        )
        
        if resp.status_code != 200:
            print(f"  Error checking status: {resp.status_code}")
            time.sleep(5)
            continue
        
        data = resp.json()
        state = data.get("readyState")
        url = data.get("url")
        
        if i % 6 == 0:
            print(f"  [{i}] State: {state}")
        
        if state == "READY":
            print(f"\n✓ Deployment READY!")
            print(f"  URL: https://{url}")
            return data
        elif state == "ERROR":
            print(f"\n✗ Deployment FAILED!")
            print(f"  Error: {data.get('error', {}).get('message', 'unknown')}")
            return data
        elif state == "CANCELED":
            print(f"\n✗ Deployment CANCELED!")
            return data
        
        time.sleep(5)
    
    print("Timeout waiting for deployment")
    return None

def main():
    print("=" * 60)
    print("ExamForge AI - Vercel Production Deployment")
    print("=" * 60)
    
    # Collect files
    print("\nCollecting files from build directory...")
    files = collect_files(BUILD_DIR)
    print(f"Found {len(files)} files")
    
    total_size = sum(f["size"] for f in files)
    print(f"Total size: {total_size / 1024 / 1024:.1f} MB")
    
    # Show largest files
    for f in sorted(files, key=lambda x: -x["size"])[:5]:
        print(f"  {f['file']}: {f['size'] / 1024 / 1024:.1f} MB")
    
    # Step 1: Upload all files to Vercel
    print("\n" + "=" * 60)
    print("Step 1: Uploading files to Vercel...")
    print("=" * 60)
    uploaded = 0
    failed = 0
    
    for i, f in enumerate(files):
        print(f"  [{i+1}/{len(files)}] Uploading {f['file']} ({f['size']/1024:.1f} KB)...", end=" ", flush=True)
        success, msg = upload_file(f["filepath"], f["sha"])
        if success:
            uploaded += 1
            print("OK")
        else:
            failed += 1
            print(f"FAILED: {msg[:100]}")
    
    print(f"\nUpload summary: {uploaded} uploaded, {failed} failed")
    
    # Step 2: Create deployment
    print("\n" + "=" * 60)
    print("Step 2: Creating deployment...")
    print("=" * 60)
    result = create_deployment(files)
    
    if not result:
        print("Failed to create deployment")
        sys.exit(1)
    
    deployment_id = result.get("id")
    state = result.get("readyState")
    url = result.get("url")
    
    print(f"Deployment created: {deployment_id}")
    print(f"State: {state}")
    print(f"URL: https://{url}")
    
    # Step 3: Wait for deployment
    print("\n" + "=" * 60)
    print("Step 3: Waiting for deployment...")
    print("=" * 60)
    final = wait_for_deployment(deployment_id)
    
    if final:
        print("\n" + "=" * 60)
        print("DEPLOYMENT RESULT")
        print("=" * 60)
        print(f"Deployment ID: {final.get('id')}")
        print(f"URL: https://{final.get('url')}")
        print(f"State: {final.get('readyState')}")
        print(f"Created: {final.get('createdAt')}")
        
        # Save deployment info
        os.makedirs("/home/z/my-project/download", exist_ok=True)
        with open("/home/z/my-project/download/deployment_info.json", "w") as f:
            json.dump(final, f, indent=2, default=str)
        print(f"\nDeployment info saved to /home/z/my-project/download/deployment_info.json")

if __name__ == "__main__":
    main()
