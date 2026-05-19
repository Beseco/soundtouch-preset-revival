#!/usr/bin/env bash
#
# discover-speakers.sh — Scan your LAN for Bose SoundTouch speakers
#
# Usage:
#   ./discover-speakers.sh 192.168.10
#
# This scans the /24 subnet and reports devices that answer on port 8090
# with valid SoundTouch info. Pure curl, no nmap/etc. required.

set -euo pipefail

SUBNET="${1:-192.168.1}"
TIMEOUT="${2:-1}"

echo "Scanning $SUBNET.0/24 for SoundTouch devices (this takes ~30 seconds)..."
echo

for i in $(seq 1 254); do
  ip="$SUBNET.$i"
  # Run in background, gather results
  (
    response=$(curl -sf --max-time "$TIMEOUT" "http://$ip:8090/info" 2>/dev/null || true)
    if [[ -n "$response" ]] && echo "$response" | grep -q "<info"; then
      name=$(echo "$response" | grep -oP '(?<=<name>)[^<]+' || echo "?")
      type=$(echo "$response" | grep -oP '(?<=<type>)[^<]+' || echo "?")
      printf "  %s\t%s (%s)\n" "$ip" "$name" "$type"
    fi
  ) &
done

wait
echo
echo "Done."
