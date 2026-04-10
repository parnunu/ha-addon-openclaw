#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH=/data/options.json
OPENCLAW_DATA=/data/openclaw

# ── Read addon options ────────────────────────────────────────────────────────
GATEWAY_TOKEN=$(jq -r '.gateway_token // ""' "${CONFIG_PATH}")
LOG_LEVEL=$(jq -r '.log_level // "info"' "${CONFIG_PATH}")

# ── Persistent data directory ─────────────────────────────────────────────────
# All openclaw config, credentials, and workspace files must live in /data so
# they survive add-on updates (the container image is replaced on every update;
# only /data is preserved by HAOS).
#
# We redirect every place a Node.js / XDG-compliant app might write config:
#   HOME              → openclaw uses os.homedir() for its own config
#   XDG_CONFIG_HOME   → ~/.config equivalent
#   XDG_DATA_HOME     → ~/.local/share equivalent
#   XDG_CACHE_HOME    → ~/.cache (can be ephemeral, but keep for faster restarts)
#   npm_config_cache  → npm cache directory
#
# We also symlink /root → /data/openclaw so any code that hardcodes /root/*
# paths (e.g. /root/.openclaw) transparently lands in persistent storage.
mkdir -p \
    "${OPENCLAW_DATA}" \
    "${OPENCLAW_DATA}/.config" \
    "${OPENCLAW_DATA}/.local/share" \
    "${OPENCLAW_DATA}/.cache" \
    "${OPENCLAW_DATA}/.npm"

export HOME="${OPENCLAW_DATA}"
export XDG_CONFIG_HOME="${OPENCLAW_DATA}/.config"
export XDG_DATA_HOME="${OPENCLAW_DATA}/.local/share"
export XDG_CACHE_HOME="${OPENCLAW_DATA}/.cache"
export npm_config_cache="${OPENCLAW_DATA}/.npm"

# Symlink /root → persistent data dir so any hardcoded /root/* paths also persist
if [ ! -L /root ]; then
    # Copy anything already in /root (e.g. from image build) into data dir first
    cp -a /root/. "${OPENCLAW_DATA}/" 2>/dev/null || true
    rm -rf /root
    ln -sf "${OPENCLAW_DATA}" /root
fi

# ── Gateway token ─────────────────────────────────────────────────────────────
# If the user left gateway_token blank in the add-on config, auto-generate one
# and persist it so it stays the same across restarts.
TOKEN_FILE="${OPENCLAW_DATA}/.gateway_token"

if [ -z "${GATEWAY_TOKEN}" ]; then
    if [ -f "${TOKEN_FILE}" ]; then
        GATEWAY_TOKEN=$(cat "${TOKEN_FILE}")
        echo "[openclaw] Loaded existing gateway token."
    else
        GATEWAY_TOKEN=$(openssl rand -hex 32)
        echo "${GATEWAY_TOKEN}" > "${TOKEN_FILE}"
        chmod 600 "${TOKEN_FILE}"
        echo "[openclaw] Generated new gateway token (saved to /data/openclaw/.gateway_token)."
    fi
fi

export OPENCLAW_GATEWAY_TOKEN="${GATEWAY_TOKEN}"

# ── Print connection info ─────────────────────────────────────────────────────
echo "======================================================="
echo "  OpenClaw Gateway"
echo "  WebSocket / Web UI  →  ws://<HA-IP>:18789"
echo "  Gateway token       →  ${GATEWAY_TOKEN}"
echo "  Log level           →  ${LOG_LEVEL}"
echo "======================================================="
echo ""
echo "  Add this gateway in the OpenClaw desktop/mobile app:"
echo "    URL:   ws://<HA-IP>:18789"
echo "    Token: ${GATEWAY_TOKEN}"
echo "======================================================="

# ── Start the gateway ─────────────────────────────────────────────────────────
# --bind lan   → listen on all LAN interfaces (not just loopback) so other
#               devices on the network can connect
# --auth token → require the OPENCLAW_GATEWAY_TOKEN for every connection
exec openclaw gateway run \
    --port 18789 \
    --bind lan \
    --auth token
