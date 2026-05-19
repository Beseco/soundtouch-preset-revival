# SoundTouch Preset Revival

> Bring the **physical preset buttons 1-6** of your Bose SoundTouch speakers back to life — after the cloud shutdown on May 6, 2026.

No DNS hijacking, no CA-certificate installation, no SoundTouch app needed.
Just a tiny HTTP server in your LAN and a few `curl` commands.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status: working](https://img.shields.io/badge/Status-working-brightgreen.svg)]()

---

## The Problem

On May 6, 2026, Bose shut down the SoundTouch cloud service. What stopped working:

- ❌ Internet radio browsing inside the SoundTouch app
- ❌ TuneIn, Pandora, Deezer presets
- ❌ Adding new presets via the app
- ❌ The convenient 1-6 buttons on the speaker and remote

What **still works** (good news):

- ✅ Bluetooth, AirPlay, Spotify Connect, AUX
- ✅ The local HTTP API on port 8090 (was never cloud-dependent)
- ✅ The `LOCAL_INTERNET_RADIO` source type built into the firmware

This project exploits the third point to restore preset buttons without complex setups like DNS hijacking or CA-cert installation.

---

## How It Works

The SoundTouch firmware has a built-in source type called `LOCAL_INTERNET_RADIO`. It expects:

1. A **JSON descriptor** hosted on any HTTP server in your LAN
2. The JSON points to the actual stream URL

When you press preset button 1, the speaker:
1. Reads the stored preset (`source="LOCAL_INTERNET_RADIO"`, `location="http://<your-server>/station.json"`)
2. Fetches the JSON from your local HTTP server
3. Extracts the `streamUrl` and starts playing

```
┌──────────────┐  press [1]  ┌───────────────┐  GET station.json  ┌────────────┐
│ SoundTouch   │ ──────────► │ Local HTTP    │ ─────────────────► │ This repo's│
│ Speaker      │             │ Server        │ ◄───── JSON ────── │ /server    │
└──────────────┘             └───────────────┘                    └────────────┘
       │
       │ GET streamUrl from JSON
       ▼
┌──────────────┐
│  Radio       │
│  Station     │
└──────────────┘
```

The **station server is included in this repo** — a tiny Docker container or a 4-line nginx setup. Runs on anything: Raspberry Pi, NAS, LXC, your existing homelab.

---

## Prerequisites

- A Bose SoundTouch 10/20/30 (confirmed on SoundTouch 20)
- A device on the same LAN that can run Docker or nginx (Pi/NAS/LXC/VM/Mac — anything)
- `curl` from any machine
- Your SoundTouch's IP address

---

## Quick Start

### Step 1: Start the station server

```bash
git clone https://github.com/Beseco/soundtouch-preset-revival.git
cd soundtouch-preset-revival/server
docker compose up -d
```

The server now serves the included example stations at `http://<your-host-ip>/radio/`.

Don't have Docker? See [`server/README.md`](server/README.md) for the bare-metal nginx alternative.

### Step 2: Find your speaker's IP

If you don't know it, scan your subnet:

```bash
./scripts/discover-speakers.sh 192.168.1
```

Or check your router's DHCP lease list.

### Step 3: Verify `LOCAL_INTERNET_RADIO` is available on your speaker

```bash
curl http://<speaker-ip>:8090/sources | grep -o 'source="LOCAL_INTERNET_RADIO"[^/]*'
```

Expected: `source="LOCAL_INTERNET_RADIO" status="READY"`

If you don't see this, this method won't work for your model — look at [AfterTouch](https://github.com/gesellix/Bose-SoundTouch) instead.

### Step 4: Write a preset

```bash
curl -X POST http://<speaker-ip>:8090/storePreset \
  -H "Content-Type: application/xml" \
  -d '<preset id="1">
  <ContentItem source="LOCAL_INTERNET_RADIO" type="stationurl"
               location="http://<your-server-ip>/radio/bayern-3.json">
    <itemName>Bayern 3</itemName>
  </ContentItem>
</preset>'
```

Or bulk-write all 6 presets at once: edit `scripts/set-presets.sh` and run it.

### Step 5: Press button 1 on your speaker

🎉 Music plays.

---

## Repository Structure

```
soundtouch-preset-revival/
├── server/                    ← The HTTP server bundle (start here!)
│   ├── docker-compose.yml         One-command Docker setup
│   ├── nginx/default.conf         nginx config with stream proxies
│   └── stations/                  Ready-to-use station JSONs
├── scripts/                   ← Helper scripts
│   ├── discover-speakers.sh       Scan LAN for SoundTouch devices
│   ├── set-presets.sh             Write all 6 presets at once
│   └── verify-presets.sh          Show current presets readably
├── examples/                  ← Additional station JSONs + nginx examples
│   ├── stations/                  Library of working station configs
│   └── lxc-setup/                 Proxmox LXC step-by-step
└── docs/
    ├── API-REFERENCE.md           SoundTouch HTTP API quick-ref
    └── TROUBLESHOOTING.md         Troubleshooting and diagnostics
```

---

## Important Notes

### HTTP vs HTTPS streams

The `LOCAL_INTERNET_RADIO` source works most reliably with **plain HTTP streams**. The included server has a reverse-proxy that converts HTTPS streams to HTTP — see `server/nginx/default.conf` for the pattern.

### Preset slots

Each speaker has 6 preset slots (`id="1"` through `id="6"`). Existing presets get overwritten without warning. See current state:

```bash
curl http://<speaker-ip>:8090/presets
```

### The HTTP server must stay online

If the server is down, the preset button does nothing — the speaker can't fetch the JSON. The Docker compose file uses `restart: unless-stopped` to handle this.

### No firmware updates after May 6, 2026

This is actually good news: the SoundTouch firmware is frozen. The behavior described here won't be killed by a future update.

---

## Comparison with Other Approaches

| Approach | Difficulty | Replaces App? | Risk |
|---|---|---|---|
| **This repo** (LOCAL_INTERNET_RADIO) | ⭐ Easy | No — preset buttons only | None |
| [Music Assistant](https://music-assistant.io/) + AirPlay/DLNA | ⭐⭐ Medium | Yes — but no physical buttons | Low |
| [sandervg/homeassistant-bose-soundtouch-bridge](https://github.com/sandervg/homeassistant-bose-soundtouch-bridge) | ⭐⭐ Medium | Partial — needs HA + Mosquitto | Low |
| [AfterTouch](https://github.com/gesellix/Bose-SoundTouch) | ⭐⭐⭐⭐ Advanced | Yes — full cloud emulation | DNS hijack + CA cert |
| [SoundTouch-Hybrid-2026](https://github.com/TJGigs/Bose-SoundTouch-Hybrid-2026) | ⭐⭐⭐⭐ Advanced | Yes — full feature parity | OverrideSdkPrivateCfg.xml injection |

This project is intentionally the **simplest possible solution**.

---

## Troubleshooting

See [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). Station JSON contributions especially welcome!

---

## Credits & Related Projects

- [gesellix/Bose-SoundTouch](https://github.com/gesellix/Bose-SoundTouch) — AfterTouch, the full cloud-emulation toolkit
- [thlucas1/homeassistantcomponent_soundtouchplus](https://github.com/thlucas1/homeassistantcomponent_soundtouchplus) — Home Assistant integration
- [sandervg/homeassistant-bose-soundtouch-bridge](https://github.com/sandervg/homeassistant-bose-soundtouch-bridge) — HA add-on, WebSocket→UPnP bridge
- [TJGigs/Bose-SoundTouch-Hybrid-2026](https://github.com/TJGigs/Bose-SoundTouch-Hybrid-2026) — Private Cloud emulation
- The Bose community on Reddit, ifun.de, borncity.com, and Stereo-Guide for documenting workarounds in the weeks after the shutdown
- Discovered through the [SoundTouch Plus Wiki](https://github.com/thlucas1/bosesoundtouchapi) and a [gist by rody64](https://gist.github.com/rody64/98a59990ff60ea962cac72cbe93edf56) — credit to user `gmuth` for the HTTP-JSON simplification

## Disclaimer

This is an independent project. Bose and SoundTouch are registered trademarks of Bose Corporation. This project is not affiliated with, endorsed by, sponsored by, or otherwise connected to Bose Corporation.

The SoundTouch local Web API (port 8090) is officially documented by Bose: [SoundTouch Web API Documentation](https://assets.bosecreative.com/m/496577402d128874/original/SoundTouch-Web-API.pdf).

## License

MIT — see [LICENSE](LICENSE).
