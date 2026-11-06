#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
app="$HOME/Applications/MailtoNull.app"
ctl="$app/Contents/Helpers/mailtoctl"
if [[ -L "$app" || -e "$app" ]]; then
    if [[ -L "$app" || ! -x "$ctl" || "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")" != local.MailtoNull ]]; then
        echo "Another item occupies $app. Move it before installing." >&2
        exit 1
    fi
    codesign --verify --deep --strict "$app"
fi
if pgrep -x MailtoNull >/dev/null || pgrep -x MailtoSettings >/dev/null; then
    echo "Close MailtoNull Settings and retry after the last click finishes." >&2
    exit 1
fi
mkdir -p "$HOME/Applications"
stage=$(mktemp -d "$HOME/Applications/.MailtoNull.XXXXXX")
trap 'rm -rf "$stage"' EXIT
bundle="$stage/bundle"
mkdir -p "$bundle/Contents/"{MacOS,Helpers}
flags=(-O -target "$(uname -m)-apple-macos12.0" -module-cache-path "$stage/cache")
xcrun swiftc "${flags[@]}" Sources/{Mailto,main}.swift -o "$bundle/Contents/MacOS/MailtoNull"
xcrun swiftc "${flags[@]}" Tools/handler.swift -o "$bundle/Contents/Helpers/mailtoctl"
settings="$bundle/Contents/Helpers/Settings.app"
mkdir -p "$settings/Contents/MacOS"
cp Tools/Settings-Info.plist "$settings/Contents/Info.plist"
xcrun swiftc "${flags[@]}" -parse-as-library Sources/Settings.swift -o "$settings/Contents/MacOS/MailtoSettings"
codesign --force --sign - "$settings"
cp Info.plist "$bundle/Contents/"
plutil -lint "$bundle/Contents/Info.plist"
codesign --force --sign - "$bundle/Contents/Helpers/mailtoctl"
codesign --force --sign - --identifier local.MailtoNull "$bundle"
codesign --verify --deep --strict "$bundle"
# Save the effective default before anything with an .app suffix is installed.
"$bundle/Contents/Helpers/mailtoctl" install "$bundle"
"$ctl" register
current=$("$ctl" status)
echo "Current mailto app: $current"
cat <<'HELP'
To select MailtoNull as the default, run:
  ~/Applications/MailtoNull.app/Contents/Helpers/mailtoctl set-default
Approve macOS's confirmation if prompted. Alternatively, choose MailtoNull in
Mail > Settings > General > Default email reader > Select.
To change Ignore / Copy to Clipboard:
  open -n ~/Applications/MailtoNull.app --args --settings
HELP
