#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_OUT_DIR="$ROOT_DIR/build/web"
LANDING_WEBAPP_DIR="$ROOT_DIR/landing-next/public/webapp"

echo "[1/3] Building Flutter Web with base href /webapp/ ..."
cd "$ROOT_DIR"
flutter build web --release --base-href /webapp/

echo "[2/3] Syncing web bundle to landing-next/public/webapp ..."
rm -rf "$LANDING_WEBAPP_DIR"
mkdir -p "$LANDING_WEBAPP_DIR"
cp -a "$WEB_OUT_DIR"/. "$LANDING_WEBAPP_DIR"/

echo "[3/3] Done."
echo "Web app path is now available at: /webapp/index.html"
echo "Next step:"
echo "  cd \"$ROOT_DIR/landing-next\" && npm run build"
