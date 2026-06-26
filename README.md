<div align="center">

# 🏠 homelab-wsl

**My whole home lab as one Docker-Compose repo — sites, Telegram bots, a reverse proxy and a shared local LLM, running headless inside WSL2.**

[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white&style=for-the-badge)](compose.yaml)
[![Docker Compose](https://img.shields.io/badge/Compose-multi--stack-2496ED?logo=docker&logoColor=white&style=for-the-badge)](compose.yaml)
[![Caddy](https://img.shields.io/badge/Caddy-reverse%20proxy-1F88C0?logo=caddy&logoColor=white&style=for-the-badge)](infra/caddy/Caddyfile)
[![Ollama](https://img.shields.io/badge/Ollama-shared%20LLM-000000?logo=ollama&logoColor=white&style=for-the-badge)](infra/)
[![WSL2](https://img.shields.io/badge/WSL2-Ubuntu-E95420?logo=ubuntu&logoColor=white&style=for-the-badge)](#hardware--constraints)
[![Cloudflare Tunnel](https://img.shields.io/badge/Cloudflare-Tunnel-F38020?logo=cloudflare&logoColor=white&style=for-the-badge)](#)

</div>

A single Docker-Compose repo that runs my whole home lab — several websites,
several Telegram bots, a reverse proxy and a shared local LLM — as containers
inside **WSL2 Ubuntu** on an under-desk PC, headless, with no Docker Desktop
and no cloud bill.

This is the **infrastructure** layer behind my app projects (e.g.
[sphynx-cattery-website](https://github.com/BreraDMR/sphynx-cattery-website) +
[sphynx-cats-crm-bot](https://github.com/BreraDMR/sphynx-cats-crm-bot)): those
repos hold the code, this one holds how it's all wired together, deployed and
kept running.

## The problems it solves

- **A pile of one-off services with no common shape.** Every site and every
  bot used to be started by hand, its own way. Here each one is a small
  container with a tiny **deploy wrapper** (`compose.yaml` + `*.env.example`),
  all aggregated by one root `compose.yaml` — `docker compose up -d` brings the
  whole lab up.
- **Adding service #11 shouldn't be a project.** There are **templates**
  (`sites/_template`, `bots/_template`): copy, drop in code, add one line to the
  root aggregator, done. The design is meant to scale to dozens of visit-card
  sites and ~10 bots without copy-paste drift.
- **One LLM, many consumers, no leaks.** Ollama runs once as a **shared
  backend** on an internal-only network; bots reach it at `http://ollama:11434`
  and it has **no public ingress**. The edge network (Caddy + sites) physically
  can't reach it.
- **Secrets must never hit git.** App code lives in each project's own GitHub
  repo and is `git clone`d into `*/app/` at deploy time (gitignored here), so
  this repo tracks **only** non-secret wiring: compose wrappers, the Caddyfile,
  templates and scripts. Every runtime `.env` is gitignored; only `.example`
  files are committed.
- **Docker Desktop needs a Windows login + GUI — useless for a headless box.**
  So this uses **native Docker Engine inside WSL2** (systemd), and the lab
  **auto-starts on boot without anyone logging in** (a one-shot systemd unit +
  a Windows Task-Scheduler trigger that boots the WSL VM).
- **No domain, no static IP, but sites still need a public URL.** A Cloudflare
  tunnel publishes each site; the live URL is auto-written into its repo's
  README on every boot (`bin/publish-site-url.sh`). Caddy is the single HTTP
  ingress, ready to switch to a real domain + per-host routing when one exists.

## Architecture

```
                         Internet
                            │  (Cloudflare tunnel, per site)
                            ▼
   ┌───────────────── homelab_edge (public-facing) ─────────────────┐
   │   Caddy  ──▶  site A   site B   ...   (one container each)      │
   └────────────────────────────────────────────────────────────────┘

   ┌──────────────── homelab_internal (no ingress) ─────────────────┐
   │   Ollama (shared LLM)  ◀──  bot A   bot B   ...                 │
   └────────────────────────────────────────────────────────────────┘

   WSL2 Ubuntu · native Docker Engine (systemd) · auto-start on boot
   Host: Ryzen 7 5700G, CPU-only (no GPU) → small quantized models
```

Two shared external networks keep the boundary explicit: `homelab_edge`
(Caddy + sites) and `homelab_internal` (Ollama + bots). Verified isolated —
the edge network cannot reach Ollama.

## Layout

| Path | Contents |
|---|---|
| `compose.yaml` | Root aggregator — `include:`s every active stack. |
| `infra/` | Caddy (reverse proxy) + Ollama (shared LLM), and the `Caddyfile`. |
| `infra/caddy/sites.d/` | Per-site Caddy snippets (`*.caddy`), imported by the Caddyfile. |
| `sites/<name>/` | One folder per site: its `compose.yaml` deploy wrapper + `*.env.example`. App code is cloned into `app/` at deploy time (gitignored). |
| `bots/<name>/` | Same, per bot. |
| `sites/_template`, `bots/_template` | Copy-to-create templates for a new service. |
| `bin/bootstrap.sh` | Creates the shared external Docker networks (idempotent). |
| `bin/publish-site-url.sh` | Grabs the Cloudflare-tunnel URL and writes it into a site's README. |

## First-time setup

```sh
./bin/bootstrap.sh            # create the shared networks
cp .env.example .env          # fill in secrets (gitignored)
docker compose up -d          # bring up infra + every included stack
```

## Add a site

1. `cp -r sites/_template sites/<name>` and edit its `compose.yaml`.
2. Copy `caddy.snippet` → `infra/caddy/sites.d/<name>.caddy`, set host + upstream.
3. Add `- sites/<name>/compose.yaml` under `include:` in the root `compose.yaml`.
4. `docker compose up -d` then `docker compose restart caddy`.

## Add a bot

1. `cp -r bots/_template bots/<name>`, clone the bot's code into `app/`.
2. Put its token in the stack's `.env`; reference it in the bot's `compose.yaml`.
3. Add `- bots/<name>/compose.yaml` under `include:` in the root `compose.yaml`.
4. `docker compose up -d`.

## Hardware / constraints

Host is a **Ryzen 7 5700G** (Vega iGPU, no discrete GPU), so Ollama is
**CPU-only**; ~16 vCPU / ~21 GB RAM are given to WSL — fine for small quantized
models (e.g. `qwen2.5:3b`, and `qwen2.5:14b` for jobs that want more quality).
`OLLAMA_MAX_LOADED_MODELS=2` keeps both resident so consumers can switch
without a reload stall.

## Notes

- This repo is intentionally **secret-free**: no tokens, no passwords, no app
  code — only the wiring. Runtime config is supplied via gitignored `.env`
  files (see the `.example`s).
- It documents a personal learning lab, not a production setup — but the
  patterns (per-service containers, network isolation, templated onboarding,
  headless auto-start) are the real, transferable part.
