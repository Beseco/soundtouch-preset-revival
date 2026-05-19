#!/usr/bin/env bash
#
# set-presets.sh — Write all 6 preset slots on a SoundTouch speaker.
#
# Usage:
#   1. Edit the SPEAKER_IP and HTTP_BASE variables below
#   2. Edit the PRESETS array (preset_id|station_name|json_filename)
#   3. Run: ./set-presets.sh
#
# Requires: curl

set -euo pipefail

# ── CONFIG ──────────────────────────────────────────────────────────────
SPEAKER_IP="192.168.10.36"                       # Your SoundTouch IP
HTTP_BASE="http://192.168.10.175/radio"          # Where your JSON files are hosted

# Format: "preset_id|display name|json filename"
PRESETS=(
  "1|Antenne Bayern|antenne-bayern.json"
  "2|Absolut HOT|absolut-hot.json"
  "3|Bayern 3|bayern-3.json"
  "4|Otvoreni Radio|otvoreni-radio.json"
  "5|Bayern 1|bayern-1.json"
  "6|SWR3|swr3.json"
)
# ────────────────────────────────────────────────────────────────────────

echo "==> Verifying speaker at $SPEAKER_IP"
if ! curl -sf "http://$SPEAKER_IP:8090/info" > /dev/null; then
  echo "ERROR: Cannot reach SoundTouch at $SPEAKER_IP"
  exit 1
fi

echo "==> Verifying HTTP server at $HTTP_BASE"
for entry in "${PRESETS[@]}"; do
  IFS='|' read -r _ _ json_file <<< "$entry"
  url="$HTTP_BASE/$json_file"
  if ! curl -sf "$url" > /dev/null; then
    echo "WARNING: $url is not reachable — preset may not work"
  fi
done

echo "==> Writing presets..."
for entry in "${PRESETS[@]}"; do
  IFS='|' read -r preset_id name json_file <<< "$entry"
  url="$HTTP_BASE/$json_file"
  echo "  [$preset_id] $name → $url"

  curl -sS -X POST "http://$SPEAKER_IP:8090/storePreset" \
    -H "Content-Type: application/xml" \
    -d "<preset id=\"$preset_id\">
  <ContentItem source=\"LOCAL_INTERNET_RADIO\" type=\"stationurl\"
               location=\"$url\">
    <itemName>$name</itemName>
  </ContentItem>
</preset>" > /dev/null
done

echo "==> Done. Verify with:"
echo "    curl http://$SPEAKER_IP:8090/presets | xmllint --format -"
