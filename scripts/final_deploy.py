#!/usr/bin/env python3
"""Final deployment to Vercel with .env removed."""
import requests, json, hashlib, os

VERCEL_TOKEN = 'vcp_0JCVYeIlppY7pSBMug6NQp2dsxTqOhzOPXZMNOxzcNbT5ggevZ2QJVU7'
PROJECT_ID = 'prj_5psYkTpfbQD8wp5zp6tSs63HunDy'
TEAM_ID = 'team_hbVXkzeMbXEmG1e6FO4tq4vB'
BASE_URL = 'https://api.vercel.com'
BUILD_DIR = '/home/z/my-project/examforgeai_repo/build/web'

headers = {'Authorization': f'Bearer {VERCEL_TOKEN}', 'Content-Type': 'application/json'}

# Collect files
files = []
for root, dirs, filenames in os.walk(BUILD_DIR):
    dirs[:] = [d for d in dirs if d != '.vercel']
    for filename in filenames:
        filepath = os.path.join(root, filename)
        rel_path = os.path.relpath(filepath, BUILD_DIR)
        h = hashlib.sha1()
        with open(filepath, 'rb') as f:
            while True:
                chunk = f.read(8192)
                if not chunk: break
                h.update(chunk)
        files.append({'file': rel_path, 'sha': h.hexdigest(), 'size': os.path.getsize(filepath)})

print(f'Uploading {len(files)} files...')
for i, f in enumerate(files):
    filepath = os.path.join(BUILD_DIR, f['file'])
    with open(filepath, 'rb') as fh:
        content = fh.read()
    resp = requests.post(
        f'{BASE_URL}/v2/files',
        headers={'Authorization': f'Bearer {VERCEL_TOKEN}', 'Content-Type': 'application/octet-stream', 'x-vercel-digest': f['sha']},
        params={'teamId': TEAM_ID},
        data=content,
        timeout=300,
    )
    if resp.status_code not in (200, 201):
        print(f'  FAIL: {f["file"]} ({resp.status_code})')

# Create deployment
payload = {'name': 'examforgeai', 'project': PROJECT_ID, 'target': 'production', 'files': files}
resp = requests.post(f'{BASE_URL}/v13/deployments?teamId={TEAM_ID}', headers=headers, json=payload, timeout=120)
if resp.status_code in (200, 201):
    data = resp.json()
    print(f'Deployment ID: {data.get("id")}')
    print(f'URL: https://{data.get("url")}')
    with open('/home/z/my-project/download/deployment_info_final.json', 'w') as f:
        json.dump(data, f, indent=2, default=str)
else:
    print(f'Error: {resp.status_code} {resp.text[:1000]}')
