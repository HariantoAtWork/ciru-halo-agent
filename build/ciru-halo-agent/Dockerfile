FROM ubuntu:26.04

# Ciru Halo Agent (Ornith1.5) for AMD Strix Halo (gfx1151).
#
# Unlike build/unsloth-amd (apt ROCm 7.2.x + gfx1151 torch pin), this image does
# **not** install distro ROCm. Ciru's INSTALL-ORNITH-RUNTIME.sh pulls the pinned
# wheel stack itself:
#   ROCm SDK 10.0.0, PyTorch 2.13.0+rocm10.0.0, vLLM/AITER forks, Python 3.14.3
# from https://stable.repo.amd.com/rocm/whl-next/
#
# The image only provides Ubuntu 26.04 host libs (glibc 2.43+) and a toolchain.
# Model weights + installed runtime live on volumes; first start downloads the
# Hugging Face bundle and runs the Ciru installer, then serve-vision.

ARG HF_REPO=jcbtc/Ornith1.5-Ciru-Halo-Agent-vllm-strix-halo

ENV DEBIAN_FRONTEND=noninteractive \
    HF_REPO=${HF_REPO} \
    CIRU_BUNDLE_ROOT=/opt/ciru-halo-agent \
    CIRU_RUNTIME_VOLUME=/opt/ciru-runtime \
    ORNITH_RUNTIME_ROOT=/opt/ciru-runtime/installed \
    CIRU_HOST=0.0.0.0 \
    CIRU_PORT=8000 \
    CIRU_TARGET_BUNDLE_VERSION=4.1.1 \
    PATH="/root/.local/bin:/root/.cargo/bin:${PATH}" \
    PYTORCH_ROCM_ARCH=gfx1151 \
    GPU_ARCHS=gfx1151 \
    HIP_VISIBLE_DEVICES=0 \
    ROCR_VISIBLE_DEVICES=0 \
    HSA_ENABLE_SDMA=0 \
    HSA_USE_SVM=1 \
    HSA_XNACK=1 \
    HSA_ENABLE_INTERRUPT=0 \
    AMD_SERIALIZE_KERNEL=3

EXPOSE 8000

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        tar \
        xz-utils \
        build-essential \
        cmake \
        ninja-build \
        pkg-config \
        xxd \
        libnuma-dev \
        libdrm-dev \
        libelf-dev \
        libssl-dev \
        zlib1g-dev \
        libvulkan-dev \
        python3 \
        python3-venv; \
    rm -rf /var/lib/apt/lists/*

# uv installs Python 3.14.3 and drives the Ciru wheel installer.
RUN set -eux; \
    curl -fsSL https://astral.sh/uv/install.sh | sh; \
    uv --version

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /opt/ciru-halo-agent

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["serve-vision"]
