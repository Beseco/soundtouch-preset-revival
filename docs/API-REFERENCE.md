# SoundTouch Local API — Quick Reference

The SoundTouch speaker runs an HTTP server on port **8090** that's independent of the cloud. It always worked locally and continues to work after the May 6, 2026 shutdown.

This file documents only the endpoints used by this project. The full Bose API documentation is at https://assets.bosecreative.com/m/496577402d128874/original/SoundTouch-Web-API.pdf.

---

## `GET /info`

Returns device metadata: name, type, MAC, IP, firmware version, country code.

```bash
curl http://192.168.10.36:8090/info
```

Used in this project: to verify the speaker is reachable.

---

## `GET /sources`

Lists all configured audio sources and whether they're currently available.

```bash
curl http://192.168.10.36:8090/sources
```

Used in this project: to check whether `LOCAL_INTERNET_RADIO` is `status="READY"`.

Important source types:

| Source | Description |
|---|---|
| `AUX` | Wired AUX input |
| `BLUETOOTH` | Bluetooth pairing |
| `AIRPLAY` | AirPlay receiver |
| `SPOTIFY` | Spotify Connect |
| `TUNEIN` | (Cloud-killed) TuneIn browsing |
| `LOCAL_INTERNET_RADIO` | ⭐ The one we use |
| `UPNP` | DLNA/UPnP media server source |
| `STORED_MUSIC` | NAS / DLNA mediaserver |

---

## `GET /presets`

Returns the 6 preset slots and what's stored in them.

```bash
curl http://192.168.10.36:8090/presets | xmllint --format -
```

Used in this project: to verify a `storePreset` call took effect.

---

## `POST /storePreset`

Writes a new entry to a preset slot. **This is the magic endpoint.**

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

Parameters:

| Attribute | Value |
|---|---|
| `preset id="N"` | 1-6 |
| `source` | `LOCAL_INTERNET_RADIO` |
| `type` | `stationurl` |
| `location` | HTTP URL to the station JSON file |
| `itemName` | Display name (informational only) |

Note: this endpoint is officially marked "N/A" in the Bose API docs, but it works. Credit to the SoundTouch Plus / AfterTouch communities for documenting it.

---

## `GET /now_playing`

Returns what's currently playing. Useful for debugging.

```bash
curl http://192.168.10.36:8090/now_playing
```

Watch the `playStatus` element:

- `PLAY_STATE` — actively playing
- `BUFFERING_STATE` — fetching the stream
- `STOP_STATE` — idle
- `STANDBY` — speaker in standby

---

## `GET /key` and `POST /key` — Physical button simulation

You can emulate button presses (including preset 1-6) via the API:

```bash
# Press preset 1 (note the press + release pair)
curl -X POST http://192.168.10.36:8090/key \
  -H "Content-Type: application/xml" \
  -d '<key state="press" sender="Gabbo">PRESET_1</key>'

curl -X POST http://192.168.10.36:8090/key \
  -H "Content-Type: application/xml" \
  -d '<key state="release" sender="Gabbo">PRESET_1</key>'
```

Valid key names include: `PRESET_1` … `PRESET_6`, `PLAY`, `PAUSE`, `STOP`, `PREV_TRACK`, `NEXT_TRACK`, `MUTE`, `VOLUME_UP`, `VOLUME_DOWN`, `POWER`.

This is how you'd integrate the speaker into Home Assistant automations without needing the SoundTouchPlus custom integration.

---

## `GET` / `POST /volume`

```bash
# Read current volume
curl http://192.168.10.36:8090/volume

# Set to 30
curl -X POST http://192.168.10.36:8090/volume \
  -H "Content-Type: application/xml" \
  -d '<volume>30</volume>'
```

---

## WebSocket events on port 8080

The speaker pushes real-time state changes via WebSocket (protocol name `gabbo`). Useful for Home Assistant or any reactive integration.

```javascript
const ws = new WebSocket("ws://192.168.10.36:8080", "gabbo");
ws.onmessage = (e) => console.log(e.data);
```

Out of scope for this project — see [AfterTouch](https://github.com/gesellix/Bose-SoundTouch) for a Go library that wraps this nicely.
