# Scripts

Helper scripts for bulk-managing presets and discovering speakers.

## `discover-speakers.sh`

Scans your LAN for SoundTouch devices.

```bash
./discover-speakers.sh 192.168.10        # scans 192.168.10.0/24
./discover-speakers.sh 192.168.1 2       # scans 192.168.1.0/24 with 2-second timeout
```

Output:
```
Scanning 192.168.10.0/24 for SoundTouch devices...

  192.168.10.36    Wohnzimmer (SoundTouch 20)
  192.168.10.47    Küche (SoundTouch 30)

Done.
```

## `set-presets.sh`

Writes all 6 preset slots at once. Edit the `SPEAKER_IP`, `HTTP_BASE`, and `PRESETS` array at the top of the file before running.

```bash
./set-presets.sh
```

## `verify-presets.sh`

Prints the currently stored presets on a speaker in a readable format.

```bash
./verify-presets.sh 192.168.10.36
```
