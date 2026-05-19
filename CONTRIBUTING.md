# Contributing

Thanks for considering a contribution!

## Adding a new station

The easiest and most useful contribution: a working stream URL for a station that isn't in `examples/stations/` yet.

1. Create a JSON file following the schema in [`examples/stations/README.md`](examples/stations/README.md)
2. Test it on your own speaker
3. Open a PR with the file

Naming: `station-name-lowercase-with-dashes.json` (e.g. `radio-eins.json`, not `Radio_Eins.JSON`).

## Reporting that a stream broke

Stations occasionally change their stream URLs. If a station in `examples/stations/` stops working, open an issue with:

- Station name
- Original URL (from the JSON)
- What `curl -I <streamUrl>` returns
- The current working URL if you have one

## Documenting a new firmware quirk

If you discover that a specific SoundTouch model or firmware version behaves differently, please add a note to [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) or open an issue.

## Sharing setup variations

If you got this working without nginx (e.g. on a Synology NAS, with caddy, with a Python `http.server` one-liner), a write-up in `examples/` is welcome.

## Code style

- Shell scripts: bash, `set -euo pipefail`, ShellCheck-clean
- JSON: two-space indent, no trailing comma, valid JSON only

## Scope

This project intentionally stays small. The scope is:

- ✅ Reviving the physical preset buttons 1-6
- ✅ Documentation around the `LOCAL_INTERNET_RADIO` mechanism
- ✅ Helper scripts for setup and verification

Out of scope (use other projects instead):

- ❌ Full cloud emulation — see [AfterTouch](https://github.com/gesellix/Bose-SoundTouch)
- ❌ Custom app development
- ❌ Multi-room sync features beyond what the speaker firmware natively does
