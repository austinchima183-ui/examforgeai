#!/usr/bin/env python3
"""Webhook verification for ARTIFACTS.md — raw output capture."""
import json, time, requests, sys

WEBHOOK_URL = "https://pzfnptrrnxkgodclyhft.supabase.co/functions/v1/flutterwave-webhook"
SECRET_HASH = "REDACTED_WEBHOOK_SECRET_HASH"

print("=" * 80)
print("WEBHOOK VERIFICATION LOGS")
print("=" * 80)

# Test 1: Valid Signature — verif-hash matches stored secret
print("\n--- TEST 1: Valid Signature (verif-hash matches secret) ---")
payload = {
    "event": "charge.completed",
    "data": {
        "id": 123456789,
        "tx_ref": f"examforge_verify_{int(time.time())}",
        "amount": 5000,
        "currency": "NGN",
        "status": "successful",
        "customer": {"email": "test@examforge.ai"}
    }
}
body = json.dumps(payload)
headers = {
    "Content-Type": "application/json",
    "verif-hash": SECRET_HASH
}
try:
    r = requests.post(WEBHOOK_URL, data=body, headers=headers, timeout=15)
    print(f"  Status: {r.status_code}")
    print(f"  Response: {r.text[:500]}")
except Exception as e:
    print(f"  ERROR: {e}")

# Test 2: Invalid signature — wrong hash
print("\n--- TEST 2: Invalid Signature (wrong hash — should be rejected) ---")
headers_bad = {
    "Content-Type": "application/json",
    "verif-hash": "deadbeef_invalid_hash_1234567890abcdef"
}
try:
    r = requests.post(WEBHOOK_URL, data=body, headers=headers_bad, timeout=15)
    print(f"  Status: {r.status_code}")
    print(f"  Response: {r.text[:500]}")
except Exception as e:
    print(f"  ERROR: {e}")

# Test 3: Missing signature header entirely
print("\n--- TEST 3: Missing Signature Header (should be rejected) ---")
headers_none = {"Content-Type": "application/json"}
try:
    r = requests.post(WEBHOOK_URL, data=body, headers=headers_none, timeout=15)
    print(f"  Status: {r.status_code}")
    print(f"  Response: {r.text[:500]}")
except Exception as e:
    print(f"  ERROR: {e}")

# Test 4: Idempotency — same payload with same tx_ref twice
print("\n--- TEST 4: Idempotency (same payload twice) ---")
dup_payload = {
    "event": "charge.completed",
    "data": {
        "id": 999888777,
        "tx_ref": "examforge_idempotency_artifact_001",
        "amount": 1000,
        "currency": "NGN",
        "status": "successful",
        "customer": {"email": "idempotency@examforge.ai"}
    }
}
dup_body = json.dumps(dup_payload)
dup_headers = {"Content-Type": "application/json", "verif-hash": SECRET_HASH}
try:
    r1 = requests.post(WEBHOOK_URL, data=dup_body, headers=dup_headers, timeout=15)
    print(f"  First:  Status={r1.status_code} Body={r1.text[:300]}")
    r2 = requests.post(WEBHOOK_URL, data=dup_body, headers=dup_headers, timeout=15)
    print(f"  Second: Status={r2.status_code} Body={r2.text[:300]}")
except Exception as e:
    print(f"  ERROR: {e}")

# Test 5: Replay protection — same Flutterwave ID with different tx_ref
print("\n--- TEST 5: Replay Protection (same flw ID, different tx_ref) ---")
replay_payload = {
    "event": "charge.completed",
    "data": {
        "id": 999888777,
        "tx_ref": f"examforge_replay_{int(time.time())}",
        "amount": 1000,
        "currency": "NGN",
        "status": "successful",
        "customer": {"email": "replay@examforge.ai"}
    }
}
replay_body = json.dumps(replay_payload)
replay_headers = {"Content-Type": "application/json", "verif-hash": SECRET_HASH}
try:
    r = requests.post(WEBHOOK_URL, data=replay_body, headers=replay_headers, timeout=15)
    print(f"  Status: {r.status_code}")
    print(f"  Response: {r.text[:300]}")
except Exception as e:
    print(f"  ERROR: {e}")

# Test 6: Wrong HTTP method
print("\n--- TEST 6: Wrong HTTP Method (GET — should be 405) ---")
try:
    r = requests.get(WEBHOOK_URL, timeout=15)
    print(f"  Status: {r.status_code}")
    print(f"  Response: {r.text[:300]}")
except Exception as e:
    print(f"  ERROR: {e}")

# Test 7: Malformed JSON
print("\n--- TEST 7: Malformed JSON (should be 400) ---")
try:
    r = requests.post(WEBHOOK_URL, data="not valid json{{{", headers={"Content-Type": "application/json", "verif-hash": SECRET_HASH}, timeout=15)
    print(f"  Status: {r.status_code}")
    print(f"  Response: {r.text[:300]}")
except Exception as e:
    print(f"  ERROR: {e}")

print("\n" + "=" * 80)
print("WEBHOOK VERIFICATION COMPLETE")
print("=" * 80)
