# SoundTouch Preset Revival

> Bring the **physical preset buttons 1-6** of your Bose SoundTouch speakers back to life — after the cloud shutdown on May 6, 2026.

No DNS hijacking, no CA-certificate installation, no SoundTouch app needed.
Just a tiny HTTP server in your LAN and a few `curl` commands.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status: working](https://img.shields.io/badge/Status-working-brightgreen.svg)]()

---

## The Problem

On May 6, 2026, Bose shut down the SoundTouch cloud service. What worked before stopped working:

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
│ SoundTouch   │ ──────────► │ Local HTTP    │ ─────────────────► │ Your nginx │
│ Speaker      │             │ Stream Server │ ◄───── JSON ────── │ (LXC/VM)   │
└──────────────┘             └───────────────┘                    └────────────┘
       │                                                                  
       │ GET streamUrl from JSON                                           
       ▼                                                                  
┌──────────────┐                                                          
│  Radio       │                                                          
│  Station     │                                                          
└──────────────┘                                                          
```

---

## Prerequisites

- A Bose SoundTouch 10/20/30 with firmware that pre-dates the cloud-off update (most should work — confirmed on SoundTouch 20)
- A device on the same LAN to host a tiny HTTP server (any Linux box, LXC, NAS, Raspberry Pi works)
- `curl` from any machine to send the configuration
- Your SoundTouch's IP address (find it on your router or via `curl http://<guess>:8090/info`)

---

## Quick Start

### 1. Find your speaker

```bash
# Replace 192.168.10.36 with your speaker's IP
curl http://192.168.10.36:8090/info
```

You should get an XML blob with device info. Note your speaker's IP.

### 2. Check that LOCAL_INTERNET_RADIO is available

```bash
curl http://192.168.10.36:8090/sources | grep -o 'source="LOCAL_INTERNET_RADIO"[^/]*'
```

Expected: `source="LOCAL_INTERNET_RADIO" status="READY"`

If the status is anything else, this method won't work and you should look at [AfterTouch](https://github.com/gesellix/Bose-SoundTouch) for a heavier cloud-emulation approach.

### 3. Set up the HTTP server

On any Linux box in your LAN (here: `192.168.10.175`):

```bash
apt install -y nginx
mkdir -p /var/www/html/radio
```

### 4. Create a station JSON

```bash
cat > /var/www/html/radio/bayern3.json << 'EOF'
{
  "audio": {
    "hasPlaylist": false,
    "isRealtime": true,
    "streamUrl": "http://dispatcher.rndfnk.com/br/br3/live/mp3/mid"
  },
  "imageUrl": "",
  "name": "Bayern 3",
  "streamType": "liveRadio"
}
EOF
```

### 5. Store the preset on the speaker

```bash
curl -X POST http://192.168.10.36:8090/storePreset \
  -H "Content-Type: application/xml" \
  -d '<preset id="1">
  <ContentItem source="LOCAL_INTERNET_RADIO" type="stationurl"
               location="http://192.168.10.175/radio/bayern3.json">
    <itemName>Bayern 3</itemName>
  </ContentItem>
</preset>'
```

### 6. Press button 1 on your speaker

🎉 Music plays.

---

## Important Notes

### HTTP vs HTTPS streams

The `LOCAL_INTERNET_RADIO` source works most reliably with **plain HTTP streams**. Many radio stations only offer HTTPS — if a stream doesn't play, add an nginx reverse-proxy in front of it. See [`examples/nginx-https-proxy.conf`](examples/nginx-https-proxy.conf).

### Preset slots

Each speaker has 6 preset slots (`id="1"` through `id="6"`). Existing presets get overwritten without warning. To see your current presets:

```bash
curl http://192.168.10.36:8090/presets
```

### The HTTP server must stay online

If your nginx/LXC is down, the preset button does nothing — the speaker can't fetch the JSON. Set the LXC and nginx to auto-start.

### No firmware updates after May 6, 2026

This is actually good news: the SoundTouch firmware is frozen. The behavior described here won't be killed by a future update.

---

## Examples

Ready-to-use JSON descriptors for common stations are in [`examples/stations/`](examples/stations/).

Helper scripts to bulk-configure all 6 presets in [`scripts/`](scripts/).

---

## Comparison with Other Approaches

| Approach | Difficulty | Replaces App? | Risk |
|---|---|---|---|
| **This repo** (LOCAL_INTERNET_RADIO) | ⭐ Easy | No — preset buttons only | None |
| Music Assistant + AirPlay/DLNA | ⭐⭐ Medium | Yes — but no physical buttons | Low |
| [AfterTouch](https://github.com/gesellix/Bose-SoundTouch) | ⭐⭐⭐⭐ Advanced | Yes — full cloud emulation | DNS hijack + CA cert |
| [SoundTouch-Hybrid-2026](https://github.com/TJGigs/Bose-SoundTouch-Hybrid-2026) | ⭐⭐⭐⭐ Advanced | Yes — full feature parity | OverrideSdkPrivateCfg.xml injection |

This project is intentionally the **simplest possible solution**. If you want the full app experience back, look at AfterTouch.

---

## Troubleshooting

See [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

---

## Contributing

Found a station that doesn't play? Got a working stream URL for a regional station? Open a PR adding a JSON to `examples/stations/`.

---

## Credits & Related Projects

- [gesellix/Bose-SoundTouch](https://github.com/gesellix/Bose-SoundTouch) — AfterTouch, the full cloud-emulation toolkit
- [thlucas1/homeassistantcomponent_soundtouchplus](https://github.com/thlucas1/homeassistantcomponent_soundtouchplus) — Home Assistant integration
- [TJGigs/Bose-SoundTouch-Hybrid-2026](https://github.com/TJGigs/Bose-SoundTouch-Hybrid-2026) — Private Cloud emulation
- The Bose community on Reddit, ifun.de, borncity.com, and Stereo-Guide for documenting workarounds in the weeks after the shutdown

## Disclaimer

This is an independent project. Bose and SoundTouch are registered trademarks of Bose Corporation. This project is not affiliated with, endorsed by, sponsored by, or otherwise connected to Bose Corporation.

The SoundTouch local Web API (port 8090) is officially documented by Bose: [SoundTouch Web API Documentation](https://assets.bosecreative.com/m/496577402d128874/original/SoundTouch-Web-API.pdf).

## License

MIT — see [LICENSE](LICENSE).
