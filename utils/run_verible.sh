#!/bin/bash
set -e
ROOT=$(cd "$(dirname "$0}")/.." && pwd)

find $ROOT/src/       \
    -iname "*.sv"     \
    -o -iname "*.svh" \
    | xargs verible-verilog-lint \
    --lint_fatal --parse_fatal
