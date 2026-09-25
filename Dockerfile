FROM node:24-bookworm-slim

# Release channel (stable/latest) or a pinned version like 2.1.250
ARG CLAUDE_CODE_VERSION=stable

ENV LANG=C.UTF-8 \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    PATH=/home/node/.local/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
      git \
      openssh-client \
      ca-certificates \
      curl \
      ripgrep \
      less \
      jq \
      tini \
 && rm -rf /var/lib/apt/lists/*

# GitHub CLI from the official repository (amd64 + arm64)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/*

# Credentials, project trust and gh config live here
RUN mkdir -p /home/node/.claude /home/node/.config/gh \
 && touch /home/node/.claude.json \
 && chown -R node:node /home/node

USER node
WORKDIR /workspace

# Native installer (npm install is deprecated); lands in ~/.local/bin
RUN npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
 && npm cache clean --force

# Mounted repos are usually owned by another UID; git would refuse to touch them
RUN git config --global --add safe.directory '*'

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["claude", "remote-control"]
