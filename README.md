# Ciru Halo Agent (Ornith1.5) — AMD Strix Halo

Ubuntu 26.04 image that downloads the Hugging Face Ciru bundle on first start and installs the pinned ROCm 10 / vLLM wheel runtime onto named volumes. Default command is `serve-vision`.

## Requirements

- Linux host with AMD GPU (gfx1151 / Strix Halo) and working ROCm/KFD device nodes (`/dev/kfd`, `/dev/dri`).
- Docker with Compose v2.
- Roughly 100 GB host RAM for the default vision serve path.

## Quick start

```bash
cp .env.example .env   # set VIDEO_GID / RENDER_GID from `getent group video render`
bun run docker:build
bun run docker:up
bun run docker:logs
```

Image build only prepares host libs + toolchain. The HF bundle (~24 GB) and ROCm 10 runtime install on first container start onto `ciru-bundle` / `ciru-runtime` / `ciru-uv`.

Hub multi-arch publishes use `Dockerfile.platform` via `bun run docker:push`.

## Host install (NixOS)

Reuses the same Docker volumes (no second download):

```bash
bun run host:install
docker stop ciru-halo-agent
bun run host:smoke
bun run host:serve
```

Details: [build/ciru-halo-agent/host/README.md](build/ciru-halo-agent/host/README.md).

## Volumes

| Volume | Mount | Purpose |
|--------|-------|---------|
| `ciru-bundle` | `/opt/ciru-halo-agent` | HF bundle + launchers |
| `ciru-runtime` | `/opt/ciru-runtime` | Installed ROCm10 / vLLM stack |
| `ciru-cache` | `/root/.cache` | HF / pip / uv caches |
| `ciru-uv` | `/root/.local/share` | uv-managed CPython |

Volume names are fixed so data from the former layout under `/docker/unsloth-amd` keeps working.

## Host install (Alpine YOLO)

On Alpine Edge with YOLO 7.2.6 (GPD WIN 5):

```bash
# GIDs for Alpine video/render (see .env.alpine)
docker compose --env-file .env.alpine -f docker-compose.yml -f docker-compose.alpine.yml up -d
# or: ciru-compose-smoke
```

Host needs `/dev/kfd` + `/dev/dri` (`amdgpu`). Setup stages / GRUB menu: `/home/ISO/alpine-win5-overlay/`.
