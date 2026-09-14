# Ciru Halo Agent — host install (NixOS)

Reuses the Docker named-volume data (no second ~34 GB download):

| Path | Points to |
|------|-----------|
| `/home/ciru/bundle-src` | `ciru-bundle` volume (`/var/lib/docker/volumes/ciru-bundle/_data`) |
| `/home/ciru/runtime` | `ciru-runtime` volume (`…/installed`) |
| uv CPython 3.14 | `/root/.local/share/uv/python/…` → `ciru-uv` volume |

On NixOS, Ciru’s glibc Python needs an FHS wrapper. `smoke-gpu.sh` and
`serve-vision.sh` re-exec under `steam-run` automatically.

## Rehydrate after reboot / new OS

```bash
/docker/ciru-halo-agent/build/ciru-halo-agent/install-host.sh
# or from the project root: bun run host:install
```

## Run

```bash
# Keep the Docker container stopped (shared volumes + GPU)
docker stop ciru-halo-agent

# Smoke (first HIP kernel)
/home/ciru/smoke-gpu.sh
# or: bun run host:smoke

# Vision OpenAI-compatible server (port 8000)
/home/ciru/serve-vision.sh
# or: bun run host:serve

# Skip smoke if you only want to try serve anyway
CIRU_SKIP_GPU_SMOKE=1 /home/ciru/serve-vision.sh
```

Load env only (still needs steam-run for Python on NixOS):

```bash
steam-run bash -lc 'source /home/ciru/env.sh; python -V'
```

Do **not** `source /home/rocm/env-10.0.sh` together with Ciru’s wheel ROCm unless
you are deliberately debugging — `env.sh` uses Ciru’s `runtime-env.sh`.
