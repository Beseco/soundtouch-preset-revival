# Troubleshooting

## "I press the preset button and nothing happens"

### Check 1: Is the speaker reachable?

```bash
curl http://<speaker-ip>:8090/info
```

You should get an XML blob. If you get connection refused or timeout, the speaker is off, on a different network, or the IP changed.

### Check 2: Is the preset actually stored?

```bash
curl http://<speaker-ip>:8090/presets
```

Look for `<preset id="1">` (or whichever slot you wrote). If your preset isn't there, the `storePreset` call didn't take.

### Check 3: Is the JSON server reachable from the SoundTouch?

The speaker must be able to reach your HTTP server. Test from a machine on the **same VLAN** as the speaker:

```bash
curl http://<http-server-ip>/radio/your-station.json
```

If this fails or returns 404, fix the server side first.

### Check 4: Is the stream URL valid?

```bash
curl -I "<the streamUrl from your JSON>"
```

Expect `200 OK` or a `302 Found` redirect (the SoundTouch follows redirects).

### Check 5: now_playing right after pressing the button

```bash
# Press preset, then immediately:
curl http://<speaker-ip>:8090/now_playing
```

What you see tells you where it broke:

| `now_playing` shows | What it means |
|---|---|
| `<ContentItem source="LOCAL_INTERNET_RADIO" ...>` with your station name and `playStatus = PLAY_STATE` | ✅ Works |
| Same content item but `playStatus = BUFFERING_STATE` for >10 seconds | Stream URL bad, or stream needs HTTP not HTTPS |
| `source="STANDBY"` | Speaker didn't even pick up the press, or preset slot is empty |
| `source="LOCAL_INTERNET_RADIO"` but error attribute set | JSON couldn't be parsed (check syntax) |

## "Otvoreni works but Bayern 3 doesn't"

The BR streams use SSL with a CDN dispatcher. Some firmware versions handle the redirect well, others don't. Workaround: use the nginx HTTPS proxy and point the JSON's `streamUrl` to `http://<lxc-ip>/stream/bayern3`.

## "It worked yesterday, today it doesn't"

Most common causes (in order):

1. **HTTP server is down** — Restart nginx in the LXC: `systemctl restart nginx`
2. **LXC didn't auto-start after a Proxmox reboot** — Enable "Start at boot" in Proxmox
3. **Stream URL became invalid** — Stations occasionally change their stream endpoints. Test with `curl -I` and update the JSON.
4. **Speaker lost WLAN** — Power-cycle the speaker

## "Spotify Connect stopped working too"

That's unrelated to this project. Spotify Connect uses a different mechanism (mDNS + Spotify's own authentication) and should keep working independently. If it doesn't, the speaker's WLAN connection may be flaky.

## "Can I use this for a Bose Wave SoundTouch or older models?"

Untested. The `/storePreset` endpoint is documented for SoundTouch 10/20/30. Older models with different firmware may or may not behave the same way. Try `curl http://<your-ip>:8090/sources` and look for `LOCAL_INTERNET_RADIO` — if it's there with `status="READY"`, this method should work.

## "I want to use HTTPS for the JSON server too"

You can, but make sure your speaker accepts the certificate. Bose's CA store is unknown — using HTTP for the JSON itself is the path of least resistance. The JSON contains no secrets, only a stream URL.

## "Where do I find more stream URLs?"

- [Radio Browser](https://www.radio-browser.info/) — best general-purpose directory, API available
- Most stations have a "How to stream us" page with direct URLs; search for `"<station name>" stream URL`
- For German stations: search the [Rundfunkforum stream thread](https://www.rundfunkforum.de/)
