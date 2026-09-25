# docker-claude-environment

Run Claude Code 24/7 on a server and drive it from the Claude app or claude.ai/code via [Remote Control](https://code.claude.com/docs/en/remote-control).

Unofficial project, not affiliated with Anthropic. Requires a Claude subscription (Pro, Max, Team or Enterprise) — Remote Control does not support API keys.

## Quick start

```yaml
# compose.yaml
services:
  claude:
    image: ghcr.io/raphaelmue/docker-claude-environment:latest
    command: claude remote-control --name "VPS"
    working_dir: /workspace
    volumes:
      - ~/workspace:/workspace
      - claude-config:/home/node/.claude
      - claude-json:/home/node/.claude.json
    tty: true
    restart: unless-stopped

volumes:
  claude-config:
  claude-json:
```

Log in once and accept the workspace trust prompt:

```bash
docker compose run --rm claude claude auth login
docker compose run --rm claude claude   # accept trust prompt, then /exit
docker compose up -d
```

The session then shows up under **Code** in the Claude app or at [claude.ai/code](https://claude.ai/code) — computer icon, green dot.

<details>
<summary><b>One container per project</b></summary>

A single container already serves up to 32 concurrent sessions, so you don't need one per session. But one container per project keeps each project's `CLAUDE.md` and `.claude/settings.json` in play, allows `--spawn worktree`, and isolates project dependencies.

```yaml
x-claude: &claude
  image: ghcr.io/raphaelmue/docker-claude-environment:latest
  working_dir: /workspace
  tty: true
  restart: unless-stopped

services:
  api:
    <<: *claude
    command: claude remote-control --name "api" --spawn worktree
    volumes:
      - ~/workspace/api:/workspace
      - api-claude:/home/node/.claude
      - api-json:/home/node/.claude.json

  frontend:
    <<: *claude
    command: claude remote-control --name "frontend" --spawn worktree
    volumes:
      - ~/workspace/frontend:/workspace
      - fe-claude:/home/node/.claude
      - fe-json:/home/node/.claude.json

volumes:
  api-claude:
  api-json:
  fe-claude:
  fe-json:
```

Log in per container: `docker compose run --rm api claude auth login`. Credential volumes are kept separate on purpose — `.claude.json` holds per-project trust and session records that two containers should not share.

Each container is its own Node process using a few hundred MB. On a 2 GB VPS expect three or four before the OOM killer steps in.
</details>

<details>
<summary><b>Configuration</b></summary>

| Flag | Purpose |
| --- | --- |
| `--name "api"` | title in the session list |
| `--spawn worktree` | each new session gets its own git worktree (needs a repo) |
| `--permission-mode acceptEdits` | starting permission mode |
| `--capacity <N>` | max concurrent sessions (default 32) |
| `--sandbox` | filesystem and network isolation |

Useful environment variables:

```yaml
environment:
  GH_TOKEN: ${GH_TOKEN}        # non-interactive GitHub CLI auth
  GIT_AUTHOR_NAME: Your Name
  GIT_AUTHOR_EMAIL: you@example.com
  TZ: Europe/Berlin
```

For git over SSH, mount your agent socket or a deploy key:

```yaml
volumes:
  - ~/.ssh/id_ed25519:/home/node/.ssh/id_ed25519:ro
```
</details>

<details>
<summary><b>Tags and building</b></summary>

Tags: `latest`, `<version>`, `<major>.<minor>`, `sha-<commit>`. Built for `linux/amd64` and `linux/arm64`, rebuilt weekly so the bundled CLI stays current.

Pin a CLI version yourself:

```bash
docker build --build-arg CLAUDE_CODE_VERSION=2.1.250 -t claude-env .
```

Included: Claude Code CLI, git, GitHub CLI, openssh-client, ripgrep, jq, curl, less. Add language toolchains in your own image with `FROM ghcr.io/raphaelmue/docker-claude-environment:latest`.
</details>

<details>
<summary><b>Notes and gotchas</b></summary>

- **Networking:** outbound HTTPS to `api.anthropic.com` only, no inbound ports. `ANTHROPIC_BASE_URL` must be unset or Remote Control refuses to start.
- **Volumes:** `/home/node/.claude` and `/home/node/.claude.json` must persist, otherwise the login is gone after every restart.
- **`tty: true`** is required — `claude remote-control` expects a real terminal.
- **UID:** user `node` is UID 1000. If your host user differs, set `user: "1001:1001"` or equivalent.
- **Tokens:** `CLAUDE_CODE_OAUTH_TOKEN` and `claude setup-token` do not work for Remote Control; a full login is required.
- **Resuming:** after a crash, sessions can be brought back for about four hours with `claude remote-control --continue` in the same directory.
</details>
