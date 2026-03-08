#!/usr/bin/env python3
"""Run an end-to-end money flow test:

1) Create temporary athlete
2) Try check-in (expected LOW_BALANCE)
3) Create topup request as athlete
4) Approve topup as admin
5) Retry check-in (expected success)
"""

from __future__ import annotations

import argparse
import json
import random
import sys
import time
from pathlib import Path
from typing import Any
from urllib import error, request


def load_env(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        out[k.strip()] = v.strip()
    return out


class SbClient:
    def __init__(self, base_url: str, anon_key: str) -> None:
        self.base_url = base_url.rstrip("/")
        self.anon_key = anon_key

    def req(
        self,
        method: str,
        path: str,
        token: str | None = None,
        body: dict[str, Any] | None = None,
    ) -> tuple[int, str]:
        headers = {
            "apikey": self.anon_key,
            "Content-Type": "application/json",
        }
        if token:
            headers["Authorization"] = f"Bearer {token}"
        payload = None if body is None else json.dumps(body).encode("utf-8")
        req_obj = request.Request(
            self.base_url + path,
            data=payload,
            headers=headers,
            method=method,
        )
        try:
            with request.urlopen(req_obj, timeout=45) as resp:
                return resp.status, resp.read().decode("utf-8", "ignore")
        except error.HTTPError as exc:
            return exc.code, exc.read().decode("utf-8", "ignore")

    def login(self, email: str, password: str) -> tuple[str, str]:
        st, raw = self.req(
            "POST",
            "/auth/v1/token?grant_type=password",
            body={"email": email, "password": password},
        )
        if st != 200:
            raise RuntimeError(f"Login failed ({email}): {st} {raw[:220]}")
        data = json.loads(raw)
        return data["access_token"], data["user"]["id"]


def main() -> int:
    parser = argparse.ArgumentParser(description="E2E wallet/checkin test")
    parser.add_argument("--env-file", default=".env")
    parser.add_argument("--admin-email", required=True)
    parser.add_argument("--admin-password", required=True)
    parser.add_argument("--topup-amount", type=float, default=2000.0)
    args = parser.parse_args()

    env = load_env(Path(args.env_file))
    for k in ("SUPABASE_URL", "SUPABASE_ANON_KEY"):
        if k not in env:
            print(f"[ERROR] Missing {k} in {args.env_file}")
            return 1

    client = SbClient(env["SUPABASE_URL"], env["SUPABASE_ANON_KEY"])
    admin_token, _ = client.login(args.admin_email, args.admin_password)

    # Pick active QR token + location coords
    st, raw = client.req(
        "GET",
        "/rest/v1/qr_tokens?select=token,partner_location_id,is_active,created_at"
        "&is_active=eq.true&order=created_at.desc&limit=20",
        token=admin_token,
    )
    if st != 200:
        print(f"[ERROR] Could not fetch qr tokens: {st} {raw[:300]}")
        return 1
    qr_rows = json.loads(raw)
    if not qr_rows:
        print("[ERROR] No active QR token found.")
        return 1

    selected_token = None
    selected_location = None
    for row in qr_rows:
        lid = row["partner_location_id"]
        st_loc, raw_loc = client.req(
            "GET",
            f"/rest/v1/partner_locations?select=id,lat,lng,name,is_active,base_price"
            f"&id=eq.{lid}&limit=1",
            token=admin_token,
        )
        if st_loc != 200:
            continue
        loc_rows = json.loads(raw_loc)
        if loc_rows:
            selected_token = row
            selected_location = loc_rows[0]
            break

    if not selected_token or not selected_location:
        print("[ERROR] Could not match any active token to a location.")
        return 1

    qr_token = selected_token["token"]
    lat = float(selected_location.get("lat") or 33.5138)
    lng = float(selected_location.get("lng") or 36.2765)
    print(f"[INFO] Using QR token: {qr_token}")
    print(f"[INFO] Location: {selected_location}")

    # Create temp athlete
    athlete_email = f"athlete.e2e.{int(time.time())}.{random.randint(100,999)}@sportpass.app"
    athlete_password = "password"
    client.req(
        "POST",
        "/auth/v1/signup",
        body={
            "email": athlete_email,
            "password": athlete_password,
            "data": {"name": "E2E Athlete"},
        },
    )
    athlete_token, athlete_uid = client.login(athlete_email, athlete_password)
    print(f"[INFO] Temp athlete: {athlete_email} ({athlete_uid})")

    # Attempt checkin before topup
    pre_idem = f"checkin:{athlete_uid}:{int(time.time())}:pre"
    st_pre, raw_pre = client.req(
        "POST",
        "/rest/v1/rpc/perform_checkin",
        token=athlete_token,
        body={
            "p_qr_token": qr_token,
            "p_lat": lat,
            "p_lng": lng,
            "p_device_hash": f"DEVICE-{int(time.time()*1000)}",
            "p_idempotency_key": pre_idem,
        },
    )
    print(f"[STEP] pre-checkin: {st_pre} {raw_pre[:500]}")

    # Topup request
    st_tu, raw_tu = client.req(
        "POST",
        "/rest/v1/topup_requests",
        token=athlete_token,
        body={
            "user_id": athlete_uid,
            "amount": args.topup_amount,
            "proof_url": None,
            "notes": "e2e auto topup",
        },
    )
    if st_tu not in (200, 201):
        print(f"[ERROR] topup create failed: {st_tu} {raw_tu[:400]}")
        return 1

    st_pending, raw_pending = client.req(
        "GET",
        f"/rest/v1/topup_requests?select=id,status,amount&user_id=eq.{athlete_uid}"
        "&status=eq.pending&order=created_at.desc&limit=1",
        token=admin_token,
    )
    if st_pending != 200:
        print(f"[ERROR] pending topup fetch failed: {st_pending} {raw_pending[:300]}")
        return 1
    pending_rows = json.loads(raw_pending)
    if not pending_rows:
        print("[ERROR] Pending topup row not found.")
        return 1
    request_id = pending_rows[0]["id"]
    print(f"[INFO] Pending topup id: {request_id}")

    st_ap, raw_ap = client.req(
        "POST",
        "/rest/v1/rpc/approve_topup",
        token=admin_token,
        body={"p_request_id": request_id},
    )
    if st_ap != 200:
        print(f"[ERROR] approve_topup failed: {st_ap} {raw_ap[:400]}")
        return 1
    print(f"[STEP] approve_topup: {st_ap} {raw_ap[:500]}")

    # Checkin after topup
    post_idem = f"checkin:{athlete_uid}:{int(time.time())}:post"
    st_post, raw_post = client.req(
        "POST",
        "/rest/v1/rpc/perform_checkin",
        token=athlete_token,
        body={
            "p_qr_token": qr_token,
            "p_lat": lat,
            "p_lng": lng,
            "p_device_hash": f"DEVICE-{int(time.time()*1000)}",
            "p_idempotency_key": post_idem,
        },
    )
    print(f"[STEP] post-checkin: {st_post} {raw_post[:700]}")

    st_chk, raw_chk = client.req(
        "GET",
        f"/rest/v1/checkins?select=id,final_price,created_at&user_id=eq.{athlete_uid}"
        "&order=created_at.desc&limit=1",
        token=athlete_token,
    )
    print(f"[STEP] checkins verify: {st_chk} {raw_chk[:400]}")

    # Final outcome
    if st_post == 200:
        try:
            result = json.loads(raw_post)
            if result.get("success") is True:
                print("[OK] E2E flow completed successfully.")
                return 0
        except json.JSONDecodeError:
            pass

    print("[WARN] E2E finished but final check-in did not return success=true.")
    return 2


if __name__ == "__main__":
    sys.exit(main())
