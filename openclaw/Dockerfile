ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Home Assistant add-on labels
ARG BUILD_VERSION
ARG BUILD_ARCH
LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}" \
    org.opencontainers.image.source="https://github.com/parnunu/ha-addon-openclaw"

# Install Node.js and system dependencies in one layer
# nodejs and npm are in the Alpine community repo which HA base images include
RUN apk add --no-cache \
        nodejs \
        npm \
        bash \
        curl \
        git \
        jq \
        openssl \
        ca-certificates \
    && update-ca-certificates \
    && node --version \
    && npm --version

# Install openclaw from npm
ARG OPENCLAW_VERSION=2026.4.9
RUN npm install -g --no-fund --no-audit openclaw@${OPENCLAW_VERSION}

# Startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
