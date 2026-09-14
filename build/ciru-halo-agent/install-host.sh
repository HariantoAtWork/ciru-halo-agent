#!/usr/bin/env bash
# Rehydrate Ciru Halo Agent host install on NixOS (or any host with Docker volumes).
# Reuses ciru-bundle / ciru-runtime / ciru-uv — no second ~34 GB download.
set -euo pipefail

DOCKER_ROOT="${DOCKER_ROOT:-/var/lib/docker}"
CIRU_HOME="${CIRU_HOME:-/home/ciru}"
UV_SRC="${DOCKER_ROOT}/volumes/ciru-uv/_data/uv/python/cpython-3.14.3-linux-x86_64-gnu"
UV_DST_DIR="/root/.local/share/uv/python"
UV_DST="${UV_DST_DIR}/cpython-3.14.3-linux-x86_64-gnu"

if [[ ! -d "${DOCKER_ROOT}/volumes/ciru-bundle/_data" ]]; then
  echo "ERROR: ciru-bundle volume missing under ${DOCKER_ROOT}/volumes" >&2
  echo "       Bring up Docker Ciru once first: bun run docker:up" >&2
  exit 1
fi
if [[ ! -x "${UV_SRC}/bin/python3.14" ]]; then
  echo "ERROR: uv CPython missing in ciru-uv volume: ${UV_SRC}" >&2
  exit 1
fi

mkdir -p "${CIRU_HOME}" "${UV_DST_DIR}"

ln -sfn "${DOCKER_ROOT}/volumes/ciru-bundle/_data" "${CIRU_HOME}/bundle-src"
ln -sfn "${DOCKER_ROOT}/volumes/ciru-runtime/_data/installed" "${CIRU_HOME}/runtime"
ln -sfn "${UV_SRC}" "${UV_DST}"
ln -sfn "${UV_DST}" "${UV_DST_DIR}/cpython-3.14-linux-x86_64-gnu"

# Prefer repo-managed launchers when present; otherwise keep existing /home/ciru scripts.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for name in env.sh smoke-gpu.sh serve-vision.sh README.md; do
  if [[ -f "${REPO_DIR}/host/${name}" ]]; then
    install -m 0755 "${REPO_DIR}/host/${name}" "${CIRU_HOME}/${name}"
    # README is not executable
    if [[ "${name}" == "README.md" ]]; then
      chmod 0644 "${CIRU_HOME}/${name}"
    fi
  fi
done

docker stop ciru-halo-agent >/dev/null 2>&1 || true

echo "==> Ciru host paths"
ls -la "${CIRU_HOME}/bundle-src" "${CIRU_HOME}/runtime" "${UV_DST}"

if [[ -f /etc/NIXOS ]] && command -v steam-run >/dev/null 2>&1; then
  echo "==> NixOS: verifying torch via steam-run"
  steam-run bash -lc "source ${CIRU_HOME}/env.sh; ${CIRU_HOME}/runtime/venv/bin/python -u -c 'import torch; print(\"torch\", torch.__version__); print(\"cuda_available\", torch.cuda.is_available()); print(\"device\", torch.cuda.get_device_name(0) if torch.cuda.is_available() else None)'"
else
  echo "==> Verifying torch"
  # shellcheck disable=SC1091
  source "${CIRU_HOME}/env.sh"
  "${CIRU_HOME}/runtime/venv/bin/python" -u -c \
    'import torch; print("torch", torch.__version__); print("cuda_available", torch.cuda.is_available())'
fi

echo "OK — smoke: ${CIRU_HOME}/smoke-gpu.sh   serve: ${CIRU_HOME}/serve-vision.sh"
