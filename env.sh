# Environment for build.sh. Source it (build.sh does), after optionally exporting any of these:
#   GODOT                 path to the Godot 4.7 editor binary (default: `godot` on PATH, else the macOS app)
#   JAVA_HOME             JDK 17 or newer, only needed to export the APK
#   ANDROID_HOME          Android SDK folder, only needed to export the APK
#   GODOT_ANDROID_KEYSTORE_DEBUG_PATH / _USER / _PASSWORD
#                         the debug keystore Godot signs the APK with (the password is never set here)
# The headless tests only need GODOT.

if [ -z "${GODOT:-}" ]; then
  GODOT="$(command -v godot || true)"
  if [ -z "$GODOT" ] && [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
  fi
fi
export GODOT

if [ -z "${JAVA_HOME:-}" ] && [ -x /usr/libexec/java_home ]; then
  JAVA_HOME="$(/usr/libexec/java_home 2>/dev/null || true)"
fi
[ -n "${JAVA_HOME:-}" ] && export JAVA_HOME

export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="${JAVA_HOME:+$JAVA_HOME/bin:}$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="${GODOT_ANDROID_KEYSTORE_DEBUG_PATH:-$HOME/.android/debug.keystore}"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="${GODOT_ANDROID_KEYSTORE_DEBUG_USER:-androiddebugkey}"
