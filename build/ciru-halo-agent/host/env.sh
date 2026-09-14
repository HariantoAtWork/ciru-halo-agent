#!/usr/bin/env bash
# Source-only host environment for Ciru Halo Agent (reuses Docker volume data).
# Usage: source /home/ciru/env.sh

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf 'source this file; do not execute it directly\n' >&2
  exit 2
fi

# Bundle + runtime live in Docker named volumes (no second 34 GB copy).
export CIRU_BUNDLE_ROOT="${CIRU_BUNDLE_ROOT:-/home/ciru/bundle-src}"
export ORNITH_RUNTIME_ROOT="${ORNITH_RUNTIME_ROOT:-/home/ciru/runtime}"

# Empty CUDA_VISIBLE_DEVICES still trips ROCm; prefer HIP_* only.
unset CUDA_VISIBLE_DEVICES || true
# Do not set HSA_OVERRIDE_GFX_VERSION on gfx1151 — use native + SVM/XNACK.
unset HSA_OVERRIDE_GFX_VERSION || true
export HIP_VISIBLE_DEVICES="${HIP_VISIBLE_DEVICES:-0}"
export ROCR_VISIBLE_DEVICES="${ROCR_VISIBLE_DEVICES:-0}"
export HSA_ENABLE_SDMA="${HSA_ENABLE_SDMA:-0}"
export HSA_USE_SVM="${HSA_USE_SVM:-1}"
export HSA_XNACK="${HSA_XNACK:-1}"
export HSA_ENABLE_INTERRUPT="${HSA_ENABLE_INTERRUPT:-0}"
export AMD_SERIALIZE_KERNEL="${AMD_SERIALIZE_KERNEL:-3}"
export PYTORCH_ROCM_ARCH="${PYTORCH_ROCM_ARCH:-gfx1151}"
export GPU_ARCHS="${GPU_ARCHS:-gfx1151}"
# Prefer core SDK libs for inference (devel layout can GPF with Ciru wheels).
export ROCM_DEVEL_ROOT="${ROCM_DEVEL_ROOT:-/nonexistent}"

export VLLM_SOURCE="${ORNITH_RUNTIME_ROOT}/vllm"
export VLLM_VENV="${ORNITH_RUNTIME_ROOT}/venv"
export AITER_SOURCE="${ORNITH_RUNTIME_ROOT}/aiter"

# Optional HF token from the project .env (not required for this public repo).
_env_file="${CIRU_DOTENV:-/docker/unsloth-amd/.env}"
if [[ -z "${HF_TOKEN:-${HUGGING_FACE_HUB_TOKEN:-}}" && -f "${_env_file}" ]]; then
  # shellcheck disable=SC1090
  set -a
  # shellcheck disable=SC1091
  source <(grep -E '^(HF_TOKEN|HUGGING_FACE_HUB_TOKEN)=' "${_env_file}" || true)
  set +a
fi
export HF_TOKEN="${HF_TOKEN:-${HUGGING_FACE_HUB_TOKEN:-}}"

# NixOS host: Ciru/Triton JIT needs glibc headers + -lgcc.
# Detect via /run/current-system ( /etc/NIXOS is missing inside steam-run FHS ).
# Prefer pre-resolved CIRU_NIX_* from the outer launcher when present.
if [[ -n "${CIRU_NIX_GLIBC_INC:-}" || -n "${CIRU_NIX_GCC_LIB:-}" || -e /run/current-system ]]; then
  if [[ -z "${CIRU_NIX_GLIBC_INC:-}" ]]; then
    CIRU_NIX_GLIBC_INC="$(compgen -G '/nix/store/*-glibc-*-dev/include' | sort | tail -n1 || true)"
  fi
  if [[ -z "${CIRU_NIX_GCC_LIB:-}" ]]; then
    CIRU_NIX_GCC_LIB="$(compgen -G '/nix/store/*-gcc-[0-9]*/lib/gcc/x86_64-unknown-linux-gnu/*' | sort | tail -n1 || true)"
  fi
  if [[ -n "${CIRU_NIX_GLIBC_INC:-}" && -f "${CIRU_NIX_GLIBC_INC}/stdlib.h" ]]; then
    export C_INCLUDE_PATH="${CIRU_NIX_GLIBC_INC}${C_INCLUDE_PATH:+:}${C_INCLUDE_PATH:-}"
    export CPLUS_INCLUDE_PATH="${CIRU_NIX_GLIBC_INC}${CPLUS_INCLUDE_PATH:+:}${CPLUS_INCLUDE_PATH:-}"
    export CPATH="${CIRU_NIX_GLIBC_INC}${CPATH:+:}${CPATH:-}"
  fi
  if [[ -n "${CIRU_NIX_GCC_LIB:-}" && -e "${CIRU_NIX_GCC_LIB}/libgcc.a" ]]; then
    export LIBRARY_PATH="${CIRU_NIX_GCC_LIB}${LIBRARY_PATH:+:}${LIBRARY_PATH:-}"
  fi
fi

# Ciru wheel ROCm paths (do not mix with /home/rocm TheRock env unless debugging).
# shellcheck disable=SC1091
source "${ORNITH_RUNTIME_ROOT}/runtime-env.sh"
