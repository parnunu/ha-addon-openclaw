#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH=/data/options.json
OPENCLAW_DATA=/data/openclaw

# ── Read addon options ────────────────────────────────────────────────────────
GATEWAY_TOKEN=$(jq -r '.gateway_token // ""' "${CONFIG_PATH}")
LOG_LEVEL=$(jq -r '.log_level // "info"' "${CONFIG_PATH}")

# ── Persistent data directory ─────────────────────────────────────────────────
mkdir -p \
    "${OPENCLAW_DATA}" \
    "${OPENCLAW_DATA}/.config" \
    "${OPENCLAW_DATA}/.local/share" \
    "${OPENCLAW_DATA}/.cache" \
    "${OPENCLAW_DATA}/.npm" \
    "${OPENCLAW_DATA}/workspace"

export HOME="${OPENCLAW_DATA}"
export XDG_CONFIG_HOME="${OPENCLAW_DATA}/.config"
export XDG_DATA_HOME="${OPENCLAW_DATA}/.local/share"
export XDG_CACHE_HOME="${OPENCLAW_DATA}/.cache"
export npm_config_cache="${OPENCLAW_DATA}/.npm"
export OPENCLAW_WORKSPACE="${OPENCLAW_DATA}/workspace"

# Symlink /root → persistent data dir
if [ ! -L /root ]; then
    cp -a /root/. "${OPENCLAW_DATA}/" 2>/dev/null || true
    rm -rf /root
    ln -sf "${OPENCLAW_DATA}" /root
fi

cd "${OPENCLAW_DATA}/workspace"

# ── Gateway token ─────────────────────────────────────────────────────────────
TOKEN_FILE="${OPENCLAW_DATA}/.gateway_token"

if [ -z "${GATEWAY_TOKEN}" ]; then
    if [ -f "${TOKEN_FILE}" ]; then
        GATEWAY_TOKEN=$(cat "${TOKEN_FILE}")
        echo "[openclaw] Loaded existing gateway token."
    else
        GATEWAY_TOKEN=$(openssl rand -hex 32)
        echo "${GATEWAY_TOKEN}" > "${TOKEN_FILE}"
        chmod 600 "${TOKEN_FILE}"
        echo "[openclaw] Generated new gateway token."
    fi
fi

export OPENCLAW_GATEWAY_TOKEN="${GATEWAY_TOKEN}"

# ── Bootstrap openclaw config on first run ────────────────────────────────────
# openclaw refuses to start without a config file. We write a minimal one so
# the gateway starts and serves the web UI for the user to finish setup.
# The config is written to $HOME/.openclaw/config.json (inside /data).
OC_CONFIG_DIR="${OPENCLAW_DATA}/.openclaw"
OC_CONFIG_FILE="${OC_CONFIG_DIR}/openclaw.json"

mkdir -p "${OC_CONFIG_DIR}"

if [ ! -f "${OC_CONFIG_FILE}" ]; then
    echo "[openclaw] Writing bootstrap config to ${OC_CONFIG_FILE}..."
    cat > "${OC_CONFIG_FILE}" <<EOF
{
  "gateway": {
    "mode": "local",
    "auth": {
      "token": "${GATEWAY_TOKEN}"
    },
    "controlUi": {
      "allowedOrigins": ["${GATEWAY_ORIGIN}"]
    }
  }
}
EOF
fi

# Always sync allowedOrigins to the current LAN IP.
# The browser sends Origin: http://<HA-IP>:18789 — we allow exactly that.
echo "[openclaw] Setting controlUi.allowedOrigins to [\"${GATEWAY_ORIGIN}\"]"
jq --arg origin "${GATEWAY_ORIGIN}" \
    '.gateway.controlUi.allowedOrigins = [$origin]' "${OC_CONFIG_FILE}" \
    > "${OC_CONFIG_FILE}.tmp" \
    && mv "${OC_CONFIG_FILE}.tmp" "${OC_CONFIG_FILE}"
echo "[openclaw] Config (${OC_CONFIG_FILE}):"
cat "${OC_CONFIG_FILE}"

# ── Detect LAN IP ─────────────────────────────────────────────────────────────
LAN_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -1)
LAN_IP="${LAN_IP:-127.0.0.1}"
GATEWAY_ORIGIN="http://${LAN_IP}:18789"

echo "======================================================="
echo "  OpenClaw Gateway started"
echo ""
echo "  Open in your browser:"
echo "    ${GATEWAY_ORIGIN}"
echo ""
echo "  Gateway token: ${GATEWAY_TOKEN}"
echo "======================================================="

# ── Start the gateway ─────────────────────────────────────────────────────────
exec openclaw gateway run \
    --port 18789 \
    --bind lan \
    --auth token \
    --allow-unconfigured
