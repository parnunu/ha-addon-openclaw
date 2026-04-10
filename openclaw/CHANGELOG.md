# Changelog

## 2026.4.9-2 — 2026-04-11

### Fixed
- Gateway now starts correctly on first run. openclaw requires a config file
  before it will bind to any port; the add-on now writes a minimal bootstrap
  config automatically so the web UI is reachable immediately.
- Added `--allow-unconfigured` as a secondary safety net.

## 2026.4.9 — 2026-04-10

### Added
- Initial release of the OpenClaw Home Assistant add-on.
- Runs the OpenClaw gateway (`openclaw gateway run`) bound to all LAN
  interfaces on port 18789 using `host_network: true`.
- Token-based authentication; token is auto-generated on first start and
  persisted in `/data/openclaw/.gateway_token`.
- User-configurable `gateway_token` and `log_level` options.
- Persistent storage: all OpenClaw config, credentials, and agent workspace
  files survive restarts and updates via `/data/openclaw`.
- Supports `amd64` and `aarch64` architectures.
- OpenClaw version is **pinned** to the exact release in `build.yaml`
  (`OPENCLAW_VERSION`). A daily GitHub Action checks npm for new releases
  and bumps the version automatically — users just click **Update** in HA
  when it appears. No manual rebuild needed.
