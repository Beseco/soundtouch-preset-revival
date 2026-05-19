#!/usr/bin/env bash
#
# verify-presets.sh — Print the currently stored presets on a SoundTouch.
#
# Usage:
#   ./verify-presets.sh 192.168.10.36

set -euo pipefail

SPEAKER_IP="${1:-}"
if [[ -z "$SPEAKER_IP" ]]; then
  echo "Usage: $0 <speaker-ip>"
  exit 1
fi

echo "Presets on $SPEAKER_IP:"
echo

curl -sf "http://$SPEAKER_IP:8090/presets" | \
  grep -oP '<preset id="\d+"[^>]*>.*?</preset>' | \
  while IFS= read -r preset; do
    id=$(echo "$preset" | grep -oP 'id="\K\d+')
    source=$(echo "$preset" | grep -oP 'source="\K[^"]+')
    name=$(echo "$preset" | grep -oP '<itemName>\K[^<]+')
    location=$(echo "$preset" | grep -oP 'location="\K[^"]+')
    printf "  [%s] %-25s source=%-22s location=%s\n" "$id" "$name" "$source" "$location"
  done
