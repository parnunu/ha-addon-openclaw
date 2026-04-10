ARG BUILD_FROM=node:22-alpine
FROM $BUILD_FROM

# Home Assistant add-on labels
ARG BUILD_VERSION
ARG BUILD_ARCH
LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

# Install system dependencies
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    openssl \
    ca-certificates \
    && update-ca-certificates

# Install openclaw — change OPENCLAW_VERSION in build.yaml to pin a release
ARG OPENCLAW_VERSION=latest
RUN npm install -g openclaw@${OPENCLAW_VERSION} \
    && openclaw --version

# Startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
