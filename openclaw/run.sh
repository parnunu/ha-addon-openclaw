#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH=/data/options.json
OPENCLAW_DATA=/data/openclaw

# ── Read addon options ────────────────────────────────────────────────────────
GATEWAY_TOKEN=$(jq -r '.gateway_token // ""' "${CONFIG_PATH}")
LOG_LEVEL=$(jq -r '.log_level // "info"' "${CONFIG_PATH}")

# ── Persistent data directory ─────────────────────────────────────────────────
# All openclaw config, credentials, and workspace files live here so they
# survive add-on restarts and updates.
mkdir -p "${OPENCLAW_DATA}"
export HOME="${OPENCLAW_DATA}"

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
