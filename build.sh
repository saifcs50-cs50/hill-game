#!/usr/bin/env bash
# Build the debug APK headlessly. Usage: ./build.sh            (import, run the tests, export the APK)
#                                         ./build.sh test       (import and run the tests only)
#                                         ./build.sh install    (export, then install and launch over adb)
# See env.sh for the environment variables it reads (GODOT, JAVA_HOME, ANDROID_HOME, keystore settings).
set -e
cd "$(dirname "$0")"
source ./env.sh

if [[ -z "$GODOT" || ! -x "$GODOT" ]]; then
  echo "Godot 4.7 not found: put \`godot\` on PATH or export GODOT=/path/to/Godot" >&2
  exit 1
fi

"$GODOT" --headless --path game --import >/dev/null 2>&1
"$GODOT" --headless --path game -s res://tests/run_all.gd
if [[ "$1" == "test" ]]; then
  exit 0
fi

: "${GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD:?export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD (the password of your Android debug keystore) to export the APK}"
mkdir -p build
"$GODOT" --headless --path game --export-debug "Android" ../build/hilldemo.apk 2>&1 | grep -E "ERROR|Signed" || true
ls -la build/hilldemo.apk
if [[ "$1" == "install" ]]; then
  adb install -r build/hilldemo.apk
  adb shell monkey -p com.hillgame.demo -c android.intent.category.LAUNCHER 1 >/dev/null
fi
