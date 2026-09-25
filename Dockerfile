FROM node:24-bookworm-slim

# Version der Claude Code CLI, per --build-arg überschreibbar
ARG CLAUDE_CODE_VERSION=latest

RUN apt-get update && apt-get install -y --no-install-recommends \
      git \
      ca-certificates \
      curl \
      ripgrep \
      less \
      jq \
      tini \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
 && npm cache clean --force

# Verzeichnisse für Credentials und Projekt-Trust vorbereiten
RUN mkdir -p /home/node/.claude \
 && touch /home/node/.claude.json \
 && chown -R node:node /home/node

USER node
WORKDIR /workspace

# Node-Entrypoint abschalten, sonst wird "node claude ..." daraus
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["claude", "remote-control"]
