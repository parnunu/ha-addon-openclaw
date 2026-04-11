# OpenClaw — Home Assistant Add-on

Run the [OpenClaw](https://github.com/openclaw/openclaw) AI gateway directly on your Home Assistant OS instance.

## What is OpenClaw?

OpenClaw is an open-source AI gateway that lets you control your own personal AI assistant through the messaging apps you already use — WhatsApp, Telegram, Discord, Slack, Signal, and more. It runs on your own hardware and routes messages to the LLM provider of your choice.

The gateway is the central hub: it accepts WebSocket connections from channels (apps) and routes them to your configured AI nodes.

## Recommended: configure a system prompt

After starting the add-on, paste the **[system prompt](https://github.com/parnunu/ha-addon-openclaw/blob/main/openclaw/SYSTEM_PROMPT.md)** into OpenClaw (Settings → Agent → System Prompt). It tells the agent it is running inside Docker, which paths are safe, and what rules to follow when writing files — preventing accidental data loss from agent actions.

## Installation (2 steps)

1. **Add this repository** to Home Assistant:
   - Go to **Settings → Add-ons → Add-on Store** → three-dot menu → **Repositories**
   - Paste: `https://github.com/parnunu/ha-addon-openclaw`

2. **Install "OpenClaw"** from the add-on store and click **Start**.

That's it. The gateway is now running on your local network.

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `gateway_token` | *(auto)* | Authentication token for the gateway. Leave blank to auto-generate one (recommended). |
| `log_level` | `info` | Log verbosity: `debug`, `info`, `warning`, or `error`. |
| `allowed_origins` | *(auto)* | List of allowed CORS origins for the Control UI. Leave empty for auto-detection (recommended). |

### Example

```yaml
gateway_token: ""          # leave blank → a token is auto-generated and persisted
log_level: "info"
allowed_origins: []        # auto-detects HA URLs; add custom origins if needed
```

## Connecting to the Gateway

> **Important:** OpenClaw's Control UI requires a **secure context** (HTTPS or localhost). You must access Home Assistant over HTTPS for the sidebar panel to work. Set up HTTPS using [Nabu Casa](https://www.nabucasa.com/), the DuckDNS add-on, or your own reverse proxy with TLS.

There are two ways to access the OpenClaw Control UI:

1. **HA Sidebar (recommended):** Access Home Assistant over **HTTPS** (e.g., `https://your-ha.duckdns.org`), then click the **OpenClaw** panel in the sidebar. The gateway token and WebSocket URL are auto-filled — just click **Connect**.

2. **Direct LAN access:** Open `http://<HA-IP>:18789` in any browser on your network. Note: the Control UI's device identity features require HTTPS, so some functionality may be limited over plain HTTP.

The gateway token is shown in the add-on **Configuration** tab. It's only needed if you're connecting via the `openclaw` CLI from another machine:
```
openclaw gateway connect --url ws://<HA-IP>:18789 --token <token>
```

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 18789 | TCP | OpenClaw Gateway WebSocket & Web UI |

Port 18789 is mapped from the container to your host, so all devices on the same network can reach the gateway directly. The port can be changed in the add-on **Network** configuration. Internet access is also available for outbound LLM API calls.

> **Note:** The HA sidebar panel (ingress) works independently of the port mapping — it proxies through Home Assistant's built-in reverse proxy.

## Persistent Storage

Everything that matters lives in `/data/openclaw` on your HAOS host — the add-on's dedicated persistent volume. The startup script redirects all relevant paths there:

| What | Path inside `/data/openclaw` | Survives update? |
|------|------------------------------|-----------------|
| Gateway config & token | `.openclaw/` (via `HOME`) | Yes |
| LLM provider API keys | `.config/openclaw/` (via `XDG_CONFIG_HOME`) | Yes |
| Channel credentials | `.local/share/openclaw/` (via `XDG_DATA_HOME`) | Yes |
| Agent workspace files | `workspace/` (via `OPENCLAW_WORKSPACE`) | Yes |
| Any `~/` or `/root/` path | symlinked → `/data/openclaw/` | Yes |
| Add-on **uninstalled** | — | **No — all wiped** |

### Agent file writes

OpenClaw's agent can run shell commands, write files, clone git repos, etc. The add-on protects against accidental data loss with two layers:

1. **Working directory is set to `/data/openclaw/workspace`** — relative paths (e.g. `touch notes.txt`, `git clone …`) land there automatically.
2. **`OPENCLAW_WORKSPACE` env var** is set to the same path — openclaw uses this as its default file-creation root.

**What is NOT protected:** if you explicitly ask the agent to write to an absolute path outside `/data` (e.g. `write to /tmp/myfile` or `save to /opt/project`), that path is inside the ephemeral container layer and will be gone after an update. This is unavoidable without a full filesystem overlay — just keep agent work inside `~/` or relative paths and it will always be safe.

> **Tip:** Before uninstalling, back up `/data/openclaw` if you want to keep your channel credentials and LLM provider settings.

## Updating OpenClaw

The add-on version number matches the OpenClaw version (e.g. `2026.4.9`).
A GitHub Action runs **daily**, checks the `openclaw` npm package, and automatically commits a version bump when a new release is detected. Home Assistant then shows the familiar **Update** badge — just click it.

**No manual work is required** to keep the add-on current.

To manually force a specific version, edit `build.yaml` in the repository:

```yaml
args:
  OPENCLAW_VERSION: "2026.4.9"   # pin to a specific release
```

## Troubleshooting

**Gateway won't start**
Check the **Log** tab. Common causes:
- Port 18789 is already in use by another service.
- Not enough memory (openclaw needs at least 512 MB).

**Can't connect from another device**
- Make sure the port 18789 is not blocked by your router or HA firewall.
- Confirm you're using the correct HA host IP (visible in **Settings → System → Network**).

**Token lost after reinstall**
The token is stored in `/data/openclaw/.gateway_token`. Uninstalling the add-on wipes `/data`, so a new token is generated on the next install — find the new token in the add-on **Configuration** tab.
