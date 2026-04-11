#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH=/data/options.json
OPENCLAW_DATA=/data/openclaw

# ── Read addon options ────────────────────────────────────────────────────────
GATEWAY_TOKEN=$(jq -r '.gateway_token // ""' "${CONFIG_PATH}")
LOG_LEVEL=$(jq -r '.log_level // "info"' "${CONFIG_PATH}")
ALLOWED_ORIGINS_JSON=$(jq -c '.allowed_origins // []' "${CONFIG_PATH}")

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

# ── Build allowed origins ────────────────────────────────────────────────────
ORIGINS="[]"
GATEWAY_URL=""

if [ -n "${SUPERVISOR_TOKEN:-}" ]; then
    # Running inside HA — query Supervisor API for instance URLs
    HA_CONFIG=$(curl -sSf -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
        http://supervisor/core/api/config 2>/dev/null || echo "{}")

    HA_EXTERNAL=$(echo "${HA_CONFIG}" | jq -r '.external_url // empty' | sed 's|/$||')
    HA_INTERNAL=$(echo "${HA_CONFIG}" | jq -r '.internal_url // empty' | sed 's|/$||')

    # Add HA instance URLs — required for ingress (browser sends these as Origin)
    if [ -n "${HA_EXTERNAL}" ]; then
        ORIGINS=$(echo "${ORIGINS}" | jq --arg o "${HA_EXTERNAL}" '. + [$o]')
    fi
    if [ -n "${HA_INTERNAL}" ]; then
        ORIGINS=$(echo "${ORIGINS}" | jq --arg o "${HA_INTERNAL}" '. + [$o]')
    fi

    # Derive host IP for direct LAN access origin
    if [ -n "${HA_INTERNAL}" ]; then
        HOST_IP=$(echo "${HA_INTERNAL}" | sed -E 's|https?://([^:/]+).*|\1|')
        GATEWAY_URL="http://${HOST_IP}:18789"
    elif [ -n "${HA_EXTERNAL}" ]; then
        HOST_NAME=$(echo "${HA_EXTERNAL}" | sed -E 's|https?://([^:/]+).*|\1|')
        GATEWAY_URL="http://${HOST_NAME}:18789"
    fi

    if [ -n "${GATEWAY_URL}" ]; then
        ORIGINS=$(echo "${ORIGINS}" | jq --arg o "${GATEWAY_URL}" '. + [$o]')
    fi

    echo "[openclaw] HA external_url: ${HA_EXTERNAL:-<not configured>}"
    echo "[openclaw] HA internal_url: ${HA_INTERNAL:-<not configured>}"
fi

# Fallback: detect LAN IP if Supervisor API unavailable or returned no URLs
if [ -z "${GATEWAY_URL}" ]; then
    LAN_IP=$(ip route get 1.1.1.1 2>/dev/null \
        | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' \
        | head -1 || true)
    LAN_IP="${LAN_IP:-127.0.0.1}"
    GATEWAY_URL="http://${LAN_IP}:18789"
    ORIGINS=$(echo "${ORIGINS}" | jq --arg o "${GATEWAY_URL}" '. + [$o]')
fi

# Merge user-configured origins (if any)
if [ "$(echo "${ALLOWED_ORIGINS_JSON}" | jq 'length')" -gt 0 ]; then
    ORIGINS=$(echo "${ORIGINS}" | jq --argjson user "${ALLOWED_ORIGINS_JSON}" '. + $user')
    echo "[openclaw] Added user-configured allowed origins."
fi

# De-duplicate
FINAL_ORIGINS=$(echo "${ORIGINS}" | jq 'unique')
echo "[openclaw] Allowed origins: ${FINAL_ORIGINS}"

# ── Bootstrap openclaw config ─────────────────────────────────────────────────
OC_CONFIG_DIR="${OPENCLAW_DATA}/.openclaw"
OC_CONFIG_FILE="${OC_CONFIG_DIR}/openclaw.json"

mkdir -p "${OC_CONFIG_DIR}"

if [ ! -f "${OC_CONFIG_FILE}" ]; then
    echo "[openclaw] Writing bootstrap config..."
    cat > "${OC_CONFIG_FILE}" <<EOF
{
  "gateway": {
    "mode": "local",
    "auth": {
      "token": "${GATEWAY_TOKEN}"
    },
    "controlUi": {
      "allowedOrigins": []
    }
  }
}
EOF
fi

# Sync allowedOrigins from HA config (or auto-detected) into openclaw
jq --argjson origins "${FINAL_ORIGINS}" \
    '.gateway.controlUi.allowedOrigins = $origins' "${OC_CONFIG_FILE}" \
    > "${OC_CONFIG_FILE}.tmp" \
    && mv "${OC_CONFIG_FILE}.tmp" "${OC_CONFIG_FILE}"

# ── Print connection info ─────────────────────────────────────────────────────
echo "======================================================="
echo "  OpenClaw Gateway starting"
echo ""
echo "  Direct access:  ${GATEWAY_URL}"
echo "  HA Sidebar:     Use the OpenClaw panel in Home Assistant"
echo ""
echo "  Token: see add-on configuration page"
echo "======================================================="

# ── Start the gateway ─────────────────────────────────────────────────────────
exec openclaw gateway run \
    --port 18789 \
    --auth token \
    --allow-unconfigured
