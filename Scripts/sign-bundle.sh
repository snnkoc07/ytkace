#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: sign-bundle.sh YouTube.app" >&2
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$(cd "$1" && pwd)"
LDID="${LDID:-ldid}"
if ! command -v "$LDID" >/dev/null 2>&1; then
  for candidate in \
    "${THEOS:-$HOME/theos}/toolchain/linux/iphone/bin/ldid" \
    "$HOME/theos/toolchain/linux/iphone/bin/ldid"; do
    if [[ -x "$candidate" ]]; then
      LDID="$candidate"
      break
    fi
  done
fi

test -d "$APP"
command -v "$LDID" >/dev/null 2>&1

EXECUTABLE="$(
  python3 - "$APP/Info.plist" <<'PY'
import plistlib
import sys
with open(sys.argv[1], "rb") as handle:
    print(plistlib.load(handle)["CFBundleExecutable"])
PY
)"
MAIN="$APP/$EXECUTABLE"
ENTITLEMENTS="$(mktemp)"
trap 'rm -f "$ENTITLEMENTS"' EXIT

"$LDID" -e "$MAIN" >"$ENTITLEMENTS" 2>/dev/null || true

while IFS= read -r binary; do
  if [[ "$binary" != "$MAIN" ]]; then
    "$LDID" -S "$binary"
  fi
done < <(python3 "$ROOT/Tools/list_macho.py" "$APP")

if [[ -s "$ENTITLEMENTS" ]]; then
  "$LDID" "-S$ENTITLEMENTS" "$MAIN"
else
  "$LDID" -S "$MAIN"
fi
