#!/bin/bash
set -e
cd "$(dirname "$0")/.."
mkdir -p bin
if [ -f src/system_info.c ]; then gcc src/system_info.c -o bin/system_info; fi
echo "Build completed."
