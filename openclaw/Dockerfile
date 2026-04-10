ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Home Assistant add-on labels
ARG BUILD_VERSION
ARG BUILD_ARCH
LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

# Install Node.js + system dependencies
# nodejs/npm come from the Alpine edge/community repo bundled in HA base images
RUN apk add --no-cache \
    nodejs \
    npm \
    bash \
    curl \
    git \
    jq \
    openssl \
    ca-certificates \
    && update-ca-certificates

# Install openclaw from npm
# --no-fund --no-audit suppress extra network calls during install
ARG OPENCLAW_VERSION=2026.4.9
RUN npm install -g --no-fund --no-audit openclaw@${OPENCLAW_VERSION}

# Startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
