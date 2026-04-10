# OpenClaw — Home Assistant Add-on

Run the [OpenClaw](https://github.com/openclaw/openclaw) AI gateway directly on your Home Assistant OS instance.

## What is OpenClaw?

OpenClaw is an open-source AI gateway that lets you control your own personal AI assistant through the messaging apps you already use — WhatsApp, Telegram, Discord, Slack, Signal, and more. It runs on your own hardware and routes messages to the LLM provider of your choice.

The gateway is the central hub: it accepts WebSocket connections from channels (apps) and routes them to your configured AI nodes.

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

### Example

```yaml
gateway_token: ""   # leave blank → a token is auto-generated and persisted
log_level: "info"
```

## Connecting to the Gateway

After starting the add-on, check the **Log** tab to see:

```
=======================================================
  OpenClaw Gateway
  WebSocket / Web UI  →  ws://<HA-IP>:18789
  Gateway token       →  <your-token>
=======================================================
```

Use these details in:
- The OpenClaw desktop or mobile app (add a remote gateway)
- The `openclaw` CLI: `openclaw gateway connect --url ws://<HA-IP>:18789 --token <token>`

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 18789 | TCP | OpenClaw Gateway WebSocket & Web UI |

The port is exposed on your LAN so all devices on the same network can reach the gateway. Internet access is also available for outbound LLM API calls.

## Persistent Storage

All OpenClaw configuration, channel credentials, and workspace data are stored in `/data/openclaw` (the add-on's persistent data directory on your HAOS host).

The startup script redirects every path the app might write to — `HOME`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME`, npm cache, and `/root` itself — into this single directory. This means:

| Event | Configuration |
|-------|--------------|
| Add-on restart | Fully preserved |
| Add-on **update** | Fully preserved |
| Add-on **uninstall** | **Wiped** — backup first if needed |

The auto-generated gateway token is saved to `/data/openclaw/.gateway_token`.

> **Tip:** Before uninstalling, copy `/data/openclaw` to a safe location if you want to keep your channel credentials and LLM provider settings.

## Updating OpenClaw

This add-on always installs the **latest** OpenClaw release when the container is built. To pick up a new OpenClaw version:

1. Go to the add-on page in Home Assistant.
2. Click **Update** (if the add-on version was bumped) or **Rebuild** (to force a fresh image build with the latest npm package).

To pin a specific OpenClaw version, open `build.yaml` in this repository and change:

```yaml
args:
  OPENCLAW_VERSION: "2026.3.0"   # pin to a specific release
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
The token is stored in `/data/openclaw/.gateway_token`. Uninstalling the add-on wipes `/data`, so a new token is generated on the next install — update your clients with the new token printed in the logs.
