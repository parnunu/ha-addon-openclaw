# Changelog

## 2026.4.9-11 — 2026-04-11

### Fixed
- **Ingress broken (`net::ERR_FAILED`):** Removed `host_network: true` which is
  incompatible with HA ingress — the Supervisor proxies via Docker's internal
  network, which `host_network` bypasses entirely. Replaced with explicit port
  mapping so direct LAN access still works.
- **Security: overly broad CORS origins.** Stopped generating origins for all
  254 hosts in the /24 subnet. Origins are now derived from the HA instance's
  configured `external_url` and `internal_url` via the Supervisor API — only
  the exact URLs that the browser will actually use.
- **Security: gateway token logged in plain text.** The token is no longer
  printed to the add-on log. It can be found in the add-on Configuration tab.
- **Security: unnecessary `host_network: true`.** The container no longer gets
  full access to the host network stack. Port 18789 is exposed via standard
  Docker port mapping instead.

### Added
- HA Supervisor API integration for automatic origin detection — ingress
  "just works" without manual `allowed_origins` configuration.

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
