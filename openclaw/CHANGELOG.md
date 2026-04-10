# Changelog

## 1.0.0 — 2026-04-10

### Added
- Initial release of the OpenClaw Home Assistant add-on.
- Runs the OpenClaw gateway (`openclaw gateway run`) bound to all LAN interfaces on port 18789.
- Token-based authentication; token is auto-generated on first start and persisted in `/data/openclaw/.gateway_token`.
- User-configurable `gateway_token` and `log_level` options.
- Persistent storage: all OpenClaw config and credentials survive restarts and updates.
- Supports `amd64` and `aarch64` architectures.
- Always installs the latest OpenClaw npm release; pin via `OPENCLAW_VERSION` in `build.yaml`.
