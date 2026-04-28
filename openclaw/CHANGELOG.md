## 2026.4.26 - 2026-04-28

### Changed
- Updated OpenClaw to 2026.4.26.

## 2026.4.24 - 2026-04-26

### Changed
- Updated OpenClaw to 2026.4.24.

## 2026.4.23 - 2026-04-25

### Changed
- Updated OpenClaw to 2026.4.23.

## 2026.4.22 - 2026-04-24

### Changed
- Updated OpenClaw to 2026.4.22.

## 2026.4.21 - 2026-04-22

### Changed
- Updated OpenClaw to 2026.4.21.

## 2026.4.15 - 2026-04-17

### Changed
- Updated OpenClaw to 2026.4.15.

## 2026.4.14 — 2026-04-16

### Changed
- Updated OpenClaw to 2026.4.14.

## 2026.4.14 — 2026-04-15

### Changed
- Updated OpenClaw to 2026.4.14.

## 2026.4.12 — 2026-04-14

### Changed
- Updated OpenClaw to 2026.4.12.

## 2026.4.11 — 2026-04-13

### Changed
- Updated OpenClaw to 2026.4.11.

## 2026.4.11 — 2026-04-12

### Changed
- Updated OpenClaw to 2026.4.11.

## 2026.4.10 — 2026-04-11

### Changed
- Updated OpenClaw to 2026.4.10.

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
  printed to the add-on log on every restart. It is shown once on first
  generation and written back to the add-on Configuration tab via Supervisor API.
- **Security: unnecessary `host_network: true`.** The container no longer gets
  full access to the host network stack. Port 18789 is exposed via standard
  Docker port mapping instead.

### Added
- HA Supervisor API integration for automatic origin detection — ingress
  "just works" without manual `allowed_origins` configuration.
- **Pre-built Docker images.** A GitHub Actions workflow now builds and pushes
  multi-arch images (amd64, aarch64) to GHCR on every push to main. Users
  pull ready-made images instead of building locally — faster installs and
  updates, no more build button.
- Auto-generated gateway token is written back to HA options via Supervisor API
  so it appears in the add-on Configuration tab.

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
