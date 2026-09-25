FROM node:24-bookworm-slim

ARG CLAUDE_CODE_VERSION=latest

ENV LANG=C.UTF-8 \
    NPM_CONFIG_UPDATE_NOTIFIER=false

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

# Install as root, otherwise npm cannot write to /usr/local/lib/node_modules
RUN npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
 && npm cache clean --force

# Credentials, project trust and gh config live here
RUN mkdir -p /home/node/.claude /home/node/.config/gh \
 && touch /home/node/.claude.json \
 && chown -R node:node /home/node

USER node
WORKDIR /workspace

# Mounted repos are usually owned by another UID; git would refuse to touch them
RUN git config --global --add safe.directory '*'

RUN mkdir -p /home/node/.claude /home/node/.config/gh \
 && echo '{}' > /home/node/.claude.json \
 && chown -R node:node /home/node

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["claude", "remote-control"]
