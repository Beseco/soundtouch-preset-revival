# Station JSON Files

Each file describes one radio station. Place these on your local HTTP server (e.g. `/var/www/html/radio/`) and reference them from preset entries.

## Schema

```json
{
  "audio": {
    "hasPlaylist": false,
    "isRealtime": true,
    "streamUrl": "http://example.com/stream"
  },
  "imageUrl": "",
  "name": "Station Display Name",
  "streamType": "liveRadio"
}
```

| Field | Description |
|---|---|
| `audio.hasPlaylist` | Always `false` for live radio streams |
| `audio.isRealtime` | Always `true` for live radio streams |
| `audio.streamUrl` | The actual audio stream URL (HTTP preferred, HTTPS often works) |
| `imageUrl` | Optional station logo URL (can be empty) |
| `name` | Display name shown by the SoundTouch (informational only) |
| `streamType` | Use `liveRadio` for radio streams |

## HTTP vs HTTPS

The SoundTouch firmware is happiest with plain `http://` stream URLs. HTTPS streams **sometimes** work, but if a preset stays silent, that's the first thing to check. The fallback is an nginx reverse proxy that converts HTTPS to HTTP — see [`../nginx-https-proxy.conf`](../nginx-https-proxy.conf).

## Adding more stations

Submit a PR with the JSON file. Naming: `station-name-lowercase-with-dashes.json`.

A great source for stream URLs is the [Radio Browser](https://www.radio-browser.info/) — community-maintained, free, well-curated.
