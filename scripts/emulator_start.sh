#!/usr/bin/env bash
set -euo pipefail
AVD_NAME="${1:-Pixel_8a_API_34}"

# Find emulator binary
if command -v emulator >/dev/null 2>&1; then
  EMULATOR_BIN="$(command -v emulator)"
elif [[ -n "${ANDROID_HOME:-}" && -x "$ANDROID_HOME/emulator/emulator" ]]; then
  EMULATOR_BIN="$ANDROID_HOME/emulator/emulator"
elif [[ -n "${ANDROID_SDK_ROOT:-}" && -x "$ANDROID_SDK_ROOT/emulator/emulator" ]]; then
  EMULATOR_BIN="$ANDROID_SDK_ROOT/emulator/emulator"
else
  echo "emulator binary not found. Ensure Android SDK is installed and emulator is in PATH" >&2
  exit 1
fi

# Start emulator if not running (ignore physical devices)
if adb get-state >/dev/null 2>&1; then
  echo "ADB connected. Checking running devices..."
fi

# If any emulator-* device is already running, exit quietly
RUNNING_EMU=$(adb devices | awk 'NR>1 && $2=="device" && $1 ~ /^emulator-/ {print $1}')
if [[ -n "$RUNNING_EMU" ]]; then
  echo "Emulator already running: $RUNNING_EMU"
  exit 0
fi

# Pick a free emulator port (even number, default range 5554..5584)
pick_free_port() {
  for port in 5554 5556 5558 5560 5562 5564 5566 5568 5570 5572 5574 5576 5578 5580 5582 5584; do
    if ! adb devices | awk 'NR>1 {print $1}' | grep -q "^emulator-${port}$"; then
      echo "$port"
      return 0
    fi
  done
  return 1
}

PORT=$(pick_free_port)
if [[ -z "${PORT:-}" ]]; then
  echo "No free emulator port found in 5554..5584" >&2
  exit 1
fi
SERIAL="emulator-${PORT}"

# Boot emulator headless by default; override via EMU_OPTS
EMU_OPTS=${EMU_OPTS:-"-no-boot-anim -no-snapshot"}
"$EMULATOR_BIN" -avd "$AVD_NAME" -port "$PORT" $EMU_OPTS &

# Wait for boot complete
adb -s "$SERIAL" wait-for-device
BOOTED=""
ATTEMPTS=0
until [[ "$BOOTED" == "1" || $ATTEMPTS -gt 120 ]]; do
  BOOTED=$(adb -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r\n') || true
  sleep 1
  ATTEMPTS=$((ATTEMPTS+1))
  if (( ATTEMPTS % 10 == 0 )); then echo "waiting for boot... ($ATTEMPTS s)"; fi
done

if [[ "$BOOTED" != "1" ]]; then
  echo "Emulator did not boot within timeout" >&2
  exit 1
fi

echo "Emulator $AVD_NAME ($SERIAL) is ready."
