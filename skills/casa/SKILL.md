---
name: casa
description: Control HomeKit devices via the local Casa app and API (localhost-only).
metadata: {"clawdbot":{"emoji":"🏠","requires":{"bins":["casa"]},"install":[{"id":"brew","kind":"brew","formula":"clawdbot/tap/casa","bins":["casa"],"label":"Install Casa (brew)"}]}}
---

# Casa

Use the Casa app + CLI to read and write HomeKit characteristics on this machine.
The CLI talks to the local Casa API (loopback only).

Quick start
- Ensure the Casa app is running (it should sit in the Dock even if you close the window).
- Health check: `casa health`
- If auth is enabled, set `CASA_TOKEN=...` or pass `--token`.

Read
- `casa devices` — JSON output can be large; pipe through `jq` (e.g., `casa devices | jq '.[] | {name, room}'`).
- `casa accessory <id>`
- `casa characteristics get <id>`
- `casa schema`

Write
- `casa characteristics set <id> <value>`
- `casa characteristics write <id> <value>` (legacy)

Caching for speed
- Cache `characteristicId` values per device once discovered.
- Treat ids as stable unless the accessory is removed/re-added.
- If a write returns 404, refresh via `casa schema` or `casa devices` and rebuild the mapping.

CLI
- `casa rooms`
- `casa services`
- `casa cameras list`
- `casa cameras get <id>`
- `CASA_URL=http://127.0.0.1:14663 CASA_TOKEN=token casa devices`

Camera note
- Viewing camera feeds or snapshots is not available through HomeKit in Casa.
- Use direct camera streams (RTSP/HTTP) if you need camera media.
