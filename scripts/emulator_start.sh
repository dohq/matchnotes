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

# Start emulator if not running
if adb get-state >/dev/null 2>&1; then
  echo "ADB connected. Checking running devices..."
fi

RUNNING=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')
if [[ -n "$RUNNING" ]]; then
  echo "Emulator/device already running: $RUNNING"
  exit 0
fi

# Boot emulator headless by default; override via EMU_OPTS
# EMU_OPTS=${EMU_OPTS:-"-no-boot-anim -no-snapshot -no-window"}
EMU_OPTS=${EMU_OPTS:-"-no-boot-anim -no-snapshot -accel kvm"}
"$EMULATOR_BIN" -avd "$AVD_NAME" $EMU_OPTS &

# Wait for boot complete
adb wait-for-device
BOOTED=""
ATTEMPTS=0
until [[ "$BOOTED" == "1" || $ATTEMPTS -gt 120 ]]; do
  BOOTED=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r\n') || true
  sleep 1
  ATTEMPTS=$((ATTEMPTS+1))
  if (( ATTEMPTS % 10 == 0 )); then echo "waiting for boot... ($ATTEMPTS s)"; fi
done

if [[ "$BOOTED" != "1" ]]; then
  echo "Emulator did not boot within timeout" >&2
  exit 1
fi

echo "Emulator $AVD_NAME is ready."
