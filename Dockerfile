# ─────────────────────────────────────────────────────────────────────────────
# Base image for manual OpenClaw installation
# OpenClaw: https://github.com/openclaw/openclaw
# Personal AI assistant — TypeScript / Node 24 / pnpm
# ─────────────────────────────────────────────────────────────────────────────
FROM node:24-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# ── System tools ──────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    ca-certificates \
    nano \
    vim \
    htop \
    tree \
    procps \
    # Chromium deps (needed for openclaw browser tool)
    chromium \
    && rm -rf /var/lib/apt/lists/*

# ── pnpm (preferred package manager for openclaw) ─────────────────────────────
RUN corepack enable && corepack prepare pnpm@latest --activate

# ── Working directory ─────────────────────────────────────────────────────────
WORKDIR /openclaw

# ── Default interactive shell ─────────────────────────────────────────────────
CMD ["/bin/bash"]
