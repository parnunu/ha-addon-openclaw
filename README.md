# ha-addon-openclaw

Source repository for the [OpenClaw](https://github.com/openclaw/openclaw) Home Assistant add-on.

## Add-ons

| Add-on | Description |
|--------|-------------|
| [OpenClaw](./openclaw) | Run the OpenClaw AI gateway on your HAOS instance |

## Installation (2 steps)

1. **Add the central repository** in Home Assistant:

   [![Add Repository](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fparnunu%2Fhome-assistant-addons)

   Or manually: **Settings → Add-ons → Add-on Store → ⋮ → Repositories**
   and paste `https://github.com/parnunu/home-assistant-addons`.

2. **Search for "OpenClaw"** in the add-on store and click **Install**.

The gateway will be available on your LAN at `ws://<HA-IP>:18789`.

## What is OpenClaw?

OpenClaw lets you run your own AI assistant that answers you on the messaging apps you already use — WhatsApp, Telegram, Discord, Slack, Signal, and more. It routes messages to your chosen LLM (OpenAI, Anthropic, Ollama, etc.) and runs entirely on your own hardware.

## Requirements

- Home Assistant OS (HAOS) or Supervised
- At least 512 MB free RAM
- Outbound internet access (for LLM API calls)
- Port 18789 reachable from your LAN

## Support

- [Add-on documentation](./openclaw/DOCS.md)
- [OpenClaw upstream project](https://github.com/openclaw/openclaw)
- [Issues](https://github.com/parnunu/ha-addon-openclaw/issues)

## Publishing

This repository is the source of truth for the OpenClaw add-on. A GitHub Actions workflow publishes the installable `openclaw/` folder into the central Home Assistant repository:

- `https://github.com/parnunu/home-assistant-addons`
