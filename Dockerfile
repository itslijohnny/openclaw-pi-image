# syntax=docker/dockerfile:1

# OpenClaw Gateway image for Raspberry Pi arm64.
# Build from the published npm package, then run on a small Wolfi runtime.

FROM cgr.dev/chainguard/node:latest-dev AS builder
USER root

ARG OPENCLAW_VERSION
RUN test -n "$OPENCLAW_VERSION"
RUN npm install -g --prefix /usr/local "openclaw@${OPENCLAW_VERSION}"

# Keep only linux/arm64/glibc native prebuilds where packages ship many platforms.
RUN cd /usr/local/lib/node_modules && \
    find . -depth -type d \( \
       -name "*-darwin-*" -o -name "*-darwin" \
       -o -name "*-win32-*" -o -name "*-win32" \
       -o -name "*-windows-*" -o -name "*-windows" \
       -o -name "*-android-*" -o -name "*-android" \
       -o -name "*-freebsd-*" -o -name "*-freebsd" \
       -o -name "*-riscv64-*" -o -name "*-riscv64" \
       -o -name "*-arm-gnueabihf" \
       -o -name "*-linux-x64*" -o -name "*-linux-ia32*" \
       -o -name "*-linuxmusl-*" -o -name "*-linuxmusl" \
       -o -name "*-linux-arm64-musl*" \
    \) -prune -exec rm -rf {} +

FROM cgr.dev/chainguard/wolfi-base:latest

RUN apk add --no-cache nodejs git ripgrep ca-certificates tzdata && rm -rf /var/cache/apk/*

ARG TZ=America/Los_Angeles
ENV TZ=$TZ

COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
# npm lives at /usr/lib/node_modules/npm in the node:*-dev base (not /usr/local),
# so copy it explicitly so plugin installs (e.g. openclaw plugins install) work.
COPY --from=builder /usr/lib/node_modules/npm /usr/local/lib/node_modules/npm

RUN mkdir -p /usr/local/bin /home/node \
 && printf '#!/bin/sh\nexec node /usr/local/lib/node_modules/openclaw/dist/index.js "$@"\n' > /usr/local/bin/openclaw \
 && printf '#!/bin/sh\nexec node /usr/local/lib/node_modules/npm/bin/npm-cli.js "$@"\n' > /usr/local/bin/npm \
 && printf '#!/bin/sh\nexec node /usr/local/lib/node_modules/npm/bin/npx-cli.js "$@"\n' > /usr/local/bin/npx \
 && chmod 0755 /usr/local/bin/openclaw /usr/local/bin/npm /usr/local/bin/npx \
 && chown -R 1000:1000 /home/node

ENV NODE_ENV=production \
    HOME=/home/node \
    NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt \
    OPENCLAW_GATEWAY_PORT=18789

USER 1000
WORKDIR /home/node
EXPOSE 18789

CMD ["openclaw", "gateway", "--port", "18789"]
