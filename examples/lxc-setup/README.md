# Proxmox LXC Setup

Step-by-step guide to create a minimal LXC container that hosts the station JSON files.

## Container settings

In the Proxmox web UI, click **Create CT** and use these values:

| Setting | Value |
|---|---|
| Template | `debian-12-standard` |
| Hostname | `radio-server` |
| Disk | 2 GB (more than enough) |
| CPU | 1 core |
| RAM | 256 MB |
| Network | Bridge `vmbr0`, static IP in your LAN |
| Unprivileged | ✅ Yes |
| Start at boot | ✅ Yes |

After creation, start the container and open a shell.

## Install nginx

```bash
apt update
apt install -y nginx
mkdir -p /var/www/html/radio
```

## Drop in the station JSONs

```bash
cd /var/www/html/radio
curl -O https://raw.githubusercontent.com/<your-user>/soundtouch-preset-revival/main/examples/stations/antenne-bayern.json
curl -O https://raw.githubusercontent.com/<your-user>/soundtouch-preset-revival/main/examples/stations/bayern-3.json
curl -O https://raw.githubusercontent.com/<your-user>/soundtouch-preset-revival/main/examples/stations/absolut-hot.json
# ... add more as needed
chmod 644 *.json
```

## Verify the server is reachable

From any machine on your LAN:

```bash
curl http://<lxc-ip>/radio/bayern-3.json
```

You should get the JSON content back. If you do, the server side is done. Continue with [`../../scripts/set-presets.sh`](../../scripts/set-presets.sh) to write the presets to your speaker.

## Optional: enable HTTPS proxy

If you have streams that only offer HTTPS, drop the [`../nginx-https-proxy.conf`](../nginx-https-proxy.conf) into `/etc/nginx/sites-available/` and symlink:

```bash
cp ../nginx-https-proxy.conf /etc/nginx/sites-available/radio-proxy
ln -s /etc/nginx/sites-available/radio-proxy /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
```

## Auto-start checklist

- ✅ LXC: `Options → Start at boot: Yes`
- ✅ nginx: `systemctl is-enabled nginx` → should return `enabled`

That's it. The container survives reboots, your presets keep working.
