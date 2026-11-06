#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
flags=(-target "$(uname -m)-apple-macos12.0" -module-cache-path "$stage/cache")
case "${1:-unit}" in
    unit)
        xcrun swiftc "${flags[@]}" Sources/Mailto.swift Tests/main.swift -o "$stage/tests"
        "$stage/tests" --pasteboard ;;
    smoke|direct)
        xcrun swiftc "${flags[@]}" Tests/smoke.swift -o "$stage/smoke"
        "$stage/smoke" "$1" ;;
    *) echo 'Usage: ./test.sh [unit|smoke|direct]' >&2; exit 1 ;;
esac
