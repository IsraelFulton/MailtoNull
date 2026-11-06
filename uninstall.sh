#!/bin/bash
set -euo pipefail
app="$HOME/Applications/MailtoNull.app"
ctl="$app/Contents/Helpers/mailtoctl"
state="$HOME/Library/Application Support/MailtoNull"
if [[ -L "$app" || ! -x "$ctl" || "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")" != local.MailtoNull ]]; then
    echo "Cannot identify the installed MailtoNull bundle at $app. Nothing removed." >&2
    exit 1
fi
if pgrep -x MailtoNull >/dev/null || pgrep -x MailtoSettings >/dev/null; then
    echo 'Close MailtoNull Settings or wait a second for a link click to finish, then retry.' >&2
    exit 1
fi
# A denied restoration exits here, leaving the installation and backup available.
"$ctl" restore
if defaults read local.MailtoNull >/dev/null 2>&1; then defaults delete local.MailtoNull; fi
if defaults read local.MailtoNull.Settings >/dev/null 2>&1; then defaults delete local.MailtoNull.Settings; fi
rm -rf "$app"
rm -f "$state/previous.plist"
rmdir "$state" 2>/dev/null || true
echo "MailtoNull uninstalled."
