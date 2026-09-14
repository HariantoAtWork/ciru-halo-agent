#!/usr/bin/env bash
# GPU smoke: first HIP kernel via Ciru torch (cuda device).
set -euo pipefail

# NixOS stub-ld cannot run Ciru's glibc Python; re-exec in steam-run FHS.
# Resolve toolchain paths BEFORE steam-run (/etc/NIXOS vanishes inside FHS).
if [[ -z "${CIRU_STEAM_RUN:-}" && -f /etc/NIXOS ]] && command -v steam-run >/dev/null 2>&1; then
  export CIRU_STEAM_RUN=1
  export CIRU_NIX_GLIBC_INC="${CIRU_NIX_GLIBC_INC:-$(compgen -G '/nix/store/*-glibc-*-dev/include' | sort | tail -n1)}"
  export CIRU_NIX_GCC_LIB="${CIRU_NIX_GCC_LIB:-$(compgen -G '/nix/store/*-gcc-[0-9]*/lib/gcc/x86_64-unknown-linux-gnu/*' | sort | tail -n1)}"
  exec steam-run "$0" "$@"
fi

# shellcheck disable=SC1091
source /home/ciru/env.sh
echo "==> GPU smoke (torch.zeros on cuda)"
"${ORNITH_RUNTIME_ROOT}/venv/bin/python" -u -c \
  'import torch; t=torch.zeros(256, device="cuda"); print("gpu-smoke-ok", float(t.sum()))'
