# Station Server

The HTTP server that hosts the station JSON files. Two ways to run it:

## Option A — Docker (recommended, fastest)

Prerequisites: Docker + Docker Compose

```bash
# Clone or download this repo
git clone https://github.com/Beseco/soundtouch-preset-revival.git
cd soundtouch-preset-revival/server

# Start the server
docker compose up -d
```

That's it. The server is now reachable at `http://<your-host-ip>/radio/`.

Test it:

```bash
curl http://<your-host-ip>/radio/bayern-3.json
```

To stop:

```bash
docker compose down
```

To update station files after editing:

```bash
docker compose restart
```

## Option B — Bare Linux (LXC, VM, Pi, anything)

Prerequisites: nginx

```bash
# 1. Install nginx
apt update && apt install -y nginx

# 2. Copy station JSONs to the document root
mkdir -p /var/www/html/radio
cp stations/*.json /var/www/html/radio/
chmod 644 /var/www/html/radio/*.json

# 3. Drop in the nginx config
cp nginx/default.conf /etc/nginx/sites-available/soundtouch-station
ln -sf /etc/nginx/sites-available/soundtouch-station /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 4. Reload nginx
nginx -t && systemctl reload nginx
```

Verify:

```bash
curl http://localhost/radio/bayern-3.json
```

## What the server serves

| Path | What |
|---|---|
| `/` | Plain-text health/info page |
| `/radio/` | Directory listing of station JSONs (JSON format) |
| `/radio/<station>.json` | A specific station descriptor |
| `/stream/<name>` | HTTPS→HTTP reverse-proxy for stations that only offer HTTPS |

## Adding your own stations

1. Drop a new JSON into `stations/` following the schema in [`../examples/stations/README.md`](../examples/stations/README.md)
2. Restart the server: `docker compose restart` (or reload nginx for bare-metal)
3. Reference it from a preset: `http://<your-host-ip>/radio/your-station.json`

## Adding an HTTPS-stream proxy

If a station only offers HTTPS and direct playback doesn't work on your SoundTouch, add a `location` block to `nginx/default.conf`:

```nginx
location /stream/my-station {
    proxy_pass https://stream.example.com/path;
    proxy_ssl_server_name on;
    proxy_set_header Host stream.example.com;
    proxy_buffering off;
    proxy_read_timeout 3600s;
    proxy_send_timeout 3600s;
}
```

Then point your station JSON's `streamUrl` to `http://<your-host-ip>/stream/my-station` instead of the original HTTPS URL.

## Resource usage

- **Image size**: ~50 MB (Alpine-based nginx)
- **Memory**: ~5 MB idle, ~20 MB under load
- **CPU**: Negligible — it's serving static JSON + an occasional stream proxy

Easily runs on a Raspberry Pi Zero, an NAS, or any LXC container with 128 MB RAM.

## Auto-start

**Docker**: `restart: unless-stopped` is already in the compose file — it survives reboots automatically.

**Bare-metal**: `systemctl enable nginx` (usually default on Debian/Ubuntu).

## Network requirements

The SoundTouch must be able to reach the server on **port 80** of the configured IP. Keep both on the same subnet/VLAN, or open the firewall accordingly.

If you use `network_mode: host` in Docker (default in this compose file), the server binds directly to the host's LAN IP — no extra configuration needed.
