#!/usr/bin/env bash
# Host launcher for Ciru Halo Agent serve-vision (reuses Docker volume install).
set -euo pipefail

# NixOS stub-ld cannot run Ciru's glibc Python; re-exec in steam-run FHS.
# Resolve toolchain paths BEFORE steam-run (/etc/NIXOS vanishes inside FHS).
if [[ -z "${CIRU_STEAM_RUN:-}" && -f /etc/NIXOS ]] && command -v steam-run >/dev/null 2>&1; then
  export CIRU_STEAM_RUN=1
  export CIRU_NIX_GLIBC_INC="${CIRU_NIX_GLIBC_INC:-$(compgen -G '/nix/store/*-glibc-*-dev/include' | sort | tail -n1)}"
  export CIRU_NIX_GCC_LIB="${CIRU_NIX_GCC_LIB:-$(compgen -G '/nix/store/*-gcc-[0-9]*/lib/gcc/x86_64-unknown-linux-gnu/*' | sort | tail -n1)}"
  exec steam-run "$0" "$@"
fi

CIRU_HOST="${CIRU_HOST:-0.0.0.0}"
CIRU_PORT="${CIRU_PORT:-8000}"

# shellcheck disable=SC1091
source /home/ciru/env.sh

BUNDLE_ROOT="${CIRU_BUNDLE_ROOT}"
RUNTIME_ROOT="${ORNITH_RUNTIME_ROOT}"

if [[ ! -f "${BUNDLE_ROOT}/bundle/serve-vision.sh" ]]; then
  echo "ERROR: Ciru bundle missing under ${BUNDLE_ROOT}" >&2
  exit 1
fi
if [[ ! -e "${RUNTIME_ROOT}/venv/bin/python" ]]; then
  echo "ERROR: Ciru runtime missing under ${RUNTIME_ROOT}" >&2
  exit 1
fi

chmod +x \
  "${BUNDLE_ROOT}/bundle/serve-vision.sh" \
  "${BUNDLE_ROOT}/bundle/serve.sh" \
  "${BUNDLE_ROOT}/bundle/packaging/serve.sh" \
  2>/dev/null || true

mkdir -p "${BUNDLE_ROOT}/bundle/cache"

if [[ "${CIRU_SKIP_GPU_SMOKE:-0}" != "1" ]]; then
  echo "==> GPU smoke test (torch.zeros on cuda)"
  set +e
  "${RUNTIME_ROOT}/venv/bin/python" -u -c \
    'import torch; t=torch.zeros(256, device="cuda"); print("gpu-smoke-ok", float(t.sum()))'
  rc=$?
  set -e
  if [[ "${rc}" -ne 0 ]]; then
    echo "ERROR: first HIP kernel failed (exit ${rc}). Host stack/gfx1151 issue — same as Docker." >&2
    echo "       Set CIRU_SKIP_GPU_SMOKE=1 to start anyway (serve will likely still crash)." >&2
    exit "${rc}"
  fi
fi

# Stock Ciru profile is 44 GiB KV. GTT is still ~62 GiB until reboot with
# NixOS TTM modprobe; 24 GiB fits model+draft+graphs in that window.
CIRU_CACHE_GIB="${CIRU_CACHE_GIB:-24}"

echo "==> Starting Ciru serve-vision on ${CIRU_HOST}:${CIRU_PORT} (model id: ciru-halo-agent, cache ${CIRU_CACHE_GIB} GiB)"
exec bash "${BUNDLE_ROOT}/bundle/serve-vision.sh" \
  --host "${CIRU_HOST}" \
  --port "${CIRU_PORT}" \
  --cache-gib "${CIRU_CACHE_GIB}" \
  "$@"
