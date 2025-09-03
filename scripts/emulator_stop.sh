#!/usr/bin/env bash
set -euo pipefail
if command -v adb >/dev/null 2>&1; then
  echo "Stopping emulator via adb emu kill (if running)"
  adb emu kill || true
else
  echo "adb not found; nothing to stop" >&2
fi
