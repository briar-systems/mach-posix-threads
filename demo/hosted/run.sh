#!/usr/bin/env bash
# build the demo and run it, with and without the backend
#
# usage: run.sh [path-to-mach]
set -euo pipefail
mach="${1:-mach}"
cd "$(dirname "${BASH_SOURCE[0]}")"
"$mach" dep pull .
"$mach" build . -a with_backend
"$mach" build . -a without_backend
work=out/linux-x86_64/debug
LD_LIBRARY_PATH="$work/lib" "$work/bin/with_backend"
LD_LIBRARY_PATH="$work/lib" "$work/bin/without_backend"
