#!/usr/bin/env python3
"""Verify whether the live Supabase project is on New SYP scale.

Usage:
  python3 tools/verify_new_syp_scale.py \
    --admin-email anis@sport.com \
    --admin-password password
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any
from urllib import error, request


def load_env(path: Path) -> dict[str, str]:
    data: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        data[k.strip()] = v.strip()
    return data


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
            with request.urlopen(req_obj, timeout=30) as resp:
                return resp.status, resp.read().decode("utf-8", "ignore")
        except error.HTTPError as exc:
            return exc.code, exc.read().decode("utf-8", "ignore")

    def login(self, email: str, password: str) -> tuple[str, str]:
        status, raw = self.req(
            "POST",
            "/auth/v1/token?grant_type=password",
            body={"email": email, "password": password},
        )
        if status != 200:
            raise RuntimeError(f"Auth failed ({status}): {raw[:240]}")
        data = json.loads(raw)
        return data["access_token"], data["user"]["id"]


def _fetch_max_value(
    client: SbClient,
    token: str,
    table: str,
    column: str,
) -> float:
    status, raw = client.req(
        "GET",
        f"/rest/v1/{table}?select={column}&order={column}.desc&limit=1",
        token=token,
    )
    if status != 200:
        return 0.0
    rows = json.loads(raw)
    if not rows:
        return 0.0
    value = rows[0].get(column)
    try:
        return float(value or 0.0)
    except (TypeError, ValueError):
        return 0.0


def detect_scale(
    max_base_price: float,
    max_final_price: float,
    max_topup_amount: float,
) -> str:
    signal = max(max_base_price, max_final_price)
    if signal >= 2000:
        return "LEGACY"
    if signal >= 500:
        # Could be mixed/manual values; keep as warning bucket.
        return "MIXED"
    # topup can be large in production; we do not use it as primary signal.
    if max_topup_amount >= 100000 and signal < 100:
        return "POSSIBLY_NEW_WITH_HIGH_TOPUPS"
    return "NEW"


def check_migration_marker(client: SbClient, token: str) -> tuple[bool, str]:
    status, raw = client.req(
        "GET",
        "/rest/v1/system_migrations?select=migration_key,applied_at,metadata"
        "&migration_key=eq.syp_redenomination_2026_03_04&limit=1",
        token=token,
    )
    if status == 404:
        return False, "system_migrations table not found"
    if status != 200:
        return False, f"query failed ({status})"
    rows = json.loads(raw)
    if not rows:
        return False, "marker row missing"
    return True, f"marker found @ {rows[0].get('applied_at')}"


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify New SYP cutover status.")
    parser.add_argument(
        "--env-file",
        default=".env",
        help="Path to env file with SUPABASE_URL and SUPABASE_ANON_KEY (default: .env)",
    )
    parser.add_argument("--admin-email", required=True, help="Admin account email")
    parser.add_argument("--admin-password", required=True, help="Admin account password")
    args = parser.parse_args()

    env = load_env(Path(args.env_file))
    missing = [k for k in ("SUPABASE_URL", "SUPABASE_ANON_KEY") if k not in env]
    if missing:
        print(f"[ERROR] Missing env keys: {', '.join(missing)}")
        return 1

    client = SbClient(env["SUPABASE_URL"], env["SUPABASE_ANON_KEY"])
    try:
        token, admin_uid = client.login(args.admin_email, args.admin_password)
    except RuntimeError as exc:
        print(f"[ERROR] {exc}")
        return 1

    max_base_price = _fetch_max_value(client, token, "partner_locations", "base_price")
    max_final_price = _fetch_max_value(client, token, "checkins", "final_price")
    max_topup_amount = _fetch_max_value(client, token, "topup_requests", "amount")
    scale = detect_scale(max_base_price, max_final_price, max_topup_amount)
    marker_ok, marker_msg = check_migration_marker(client, token)

    print("=== SportPass New SYP Scale Audit ===")
    print(f"admin_uid: {admin_uid}")
    print(f"max partner_locations.base_price: {max_base_price}")
    print(f"max checkins.final_price: {max_final_price}")
    print(f"max topup_requests.amount: {max_topup_amount}")
    print(f"detected scale: {scale}")
    print(f"migration marker: {marker_msg}")

    if scale in ("LEGACY", "MIXED"):
        print("")
        print("ACTION REQUIRED:")
        print("Run: supabase/2026_03_04_syp_new_currency_cutover.sql in Supabase SQL Editor.")
        return 2

    if not marker_ok:
        print("")
        print("WARNING:")
        print("Data looks new-scale, but migration marker is missing.")
        print(
            "If your project was already manually converted, "
            "insert a marker row to prevent accidental re-conversion."
        )
        return 3

    print("")
    print("OK: database appears to be on New SYP scale.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
