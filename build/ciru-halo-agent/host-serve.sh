#!/usr/bin/env bash
# Thin wrapper: Ciru Halo Agent on the host (see /home/ciru/README.md).
# Reuses Docker named volumes under /home/ciru/{bundle-src,runtime}.
exec /home/ciru/serve-vision.sh "$@"
