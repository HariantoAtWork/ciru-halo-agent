# Ciru Halo Agent (Ornith1.5) — AMD Strix Halo

Ubuntu 26.04 image that downloads the Hugging Face Ciru bundle on first start and installs the pinned ROCm 10 / vLLM wheel runtime onto named volumes. Default command is `serve-vision`.

Targets **Ciru v4.1.1** (plugin / native / launchers). Model weights and pinned engine wheels are unchanged across 4.0.x → 4.1.1; the entrypoint refreshes those runtime files in place without wiping volumes.

## Requirements

- Linux host with AMD GPU (gfx1151 / Strix Halo) and working ROCm/KFD device nodes (`/dev/kfd`, `/dev/dri`).
- Docker with Compose v2.
- Roughly 100 GB host RAM for the default vision serve path.

## Quick start

```bash
cp .env.example .env   # set VIDEO_GID / RENDER_GID from `getent group video render`
cp docker-compose.yml.example docker-compose.yml
cp docker-compose.override.yml.example docker-compose.override.yml
bun run docker:build
bun run docker:up
bun run docker:logs
```

Image build only prepares host libs + toolchain. The HF bundle (~24 GB) and ROCm 10 runtime install on first container start onto `ciru-bundle` / `ciru-runtime` / `ciru-uv`.

Hub multi-arch publishes use `Dockerfile.platform` via `bun run docker:push`.

Local Compose files are gitignored. The override attaches only to the external `tsdproxy` network.

## Updating to Ciru v4.1.1 (no volume wipe)

Upstream keeps weights and ROCm/vLLM wheels; only plugin, native libraries (including both `shared_math_reference` files), packaging scripts and launchers change.

On start, the entrypoint compares `RELEASE.json` / `ciru_ornith_g256-*.dist-info` to `CIRU_TARGET_BUNDLE_VERSION` (default `4.1.1`). If older, it runs a partial Hub download into the existing `ciru-bundle` volume, removes stale `dist-info`, clears leftover `optimized-runtime/<pid>` dirs, then serves.

Force a refresh: `CIRU_FORCE_BUNDLE_UPDATE=1`.

Do **not** delete `ciru-bundle` / `ciru-runtime` / `ciru-uv` for this bump.

## ROCm / gfx1151 env

Use native gfx1151 with `HSA_USE_SVM=1` and `HSA_XNACK=1`. Do not set `HSA_OVERRIDE_GFX_VERSION` unless you explicitly set `CIRU_FORCE_HSA_OVERRIDE=1`.

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
