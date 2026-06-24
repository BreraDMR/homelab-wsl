# homelab

Single repo for all home-lab services, running as Docker containers inside
WSL2 Ubuntu on the under-desk PC. Caddy is the single HTTP(S) ingress; Ollama
is a shared LLM backend; each site and each bot is its own container.

## Layout
- `compose.yaml`        — root aggregator (`include:`s active stacks).
- `infra/`              — Caddy (reverse proxy) + Ollama.
- `infra/caddy/sites.d/`— per-site Caddy snippets (`*.caddy`).
- `sites/<name>/`       — one folder per site (own compose.yaml).
- `bots/<name>/`        — one folder per bot (own compose.yaml).
- `bin/bootstrap.sh`    — creates shared docker networks.

## Networks (shared, external)
- `homelab_edge`     — Caddy + sites (public-facing path).
- `homelab_internal` — Ollama + bots (no ingress). Bots call `http://ollama:11434`.

## First-time setup
    ./bin/bootstrap.sh           # create networks
    cp .env.example .env         # fill in secrets
    docker compose up -d         # bring up infra (+ any included stacks)

## Add a site
1. `cp -r sites/_template sites/<name>` and edit compose.yaml.
2. Copy `caddy.snippet` -> `infra/caddy/sites.d/<name>.caddy`, set host + upstream.
3. Add `- sites/<name>/compose.yaml` under `include:` in root compose.yaml.
4. `docker compose up -d` then `docker compose restart caddy`.

## Add a bot
1. `cp -r bots/_template bots/<name>` and add code + Dockerfile.
2. Put the token in `.env`, reference it in the bot's compose.yaml.
3. Add `- bots/<name>/compose.yaml` under `include:` in root compose.yaml.
4. `docker compose up -d`.

## GPU — none (CPU-only)
The host is a Ryzen 7 5700G (Vega iGPU, no discrete GPU), so Ollama runs
CPU-only. ~16 vCPU / ~21 GB RAM are allocated to WSL — fine for small
quantized models (e.g. qwen2.5:3b, llama3.2:3b). Keep model sizes modest.
