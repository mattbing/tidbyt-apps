#!/usr/bin/env bash
# upload_app.sh - upload a Tidbyt app directory to Tronbyt
# Usage: ./upload_app.sh [app-dir]  (defaults to current directory)
set -euo pipefail

TRONBYT_URL="$(op read "op://Private/Tronbyt/api endpoint")"
TRONBYT_API_KEY="$(op read "op://Private/Tronbyt/api key")"
APP_DIR="${1:-.}"

if [[ ! -d "$APP_DIR" ]]; then
  echo "error: directory not found: $APP_DIR" >&2
  exit 1
fi

APP_NAME=$(basename "$(realpath "$APP_DIR")")
ZIP="/tmp/${APP_NAME}.zip"

rm -f "$ZIP"
(cd "$APP_DIR" && zip -r "$ZIP" . -x '.git/*' '*.DS_Store')
trap 'rm -f "$ZIP"' EXIT

curl -v -f -X POST \
  -H "Authorization: Bearer $TRONBYT_API_KEY" \
  -F "file=@${ZIP}" \
  "${TRONBYT_URL}/v0/apps/upload"

echo "pushed $APP_NAME"
