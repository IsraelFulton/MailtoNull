# MailtoNull

Click an email address on your Mac and keep reading. MailtoNull handles `mailto:` links quietly, so a click won’t open Apple Mail, Outlook, or a browser tab. If you usually click an address because you want to paste it somewhere else, turn on **Copy to Clipboard**.

| Mode | What happens when you click |
| --- | --- |
| **Ignore** (default) | You stay in the app you were using. Your clipboard stays as it was. |
| **Copy to Clipboard** | MailtoNull copies the destination addresses to this Mac’s clipboard. You stay in the app you were using. |

It’s a small native Swift and AppKit utility. The handler has no Dock icon, opens no window, and exits about a second after the last click. It runs locally, makes no network requests, and requires no account, login item, browser extension, or Accessibility permission.

## Install

You’ll need a Mac and Apple’s Command Line Tools for Xcode. The app targets macOS 12 or later. To build from source, use tools with the macOS 14 SDK or newer. If you need the tools, run `xcode-select --install` in Terminal and let the installation finish.

```sh
git clone https://github.com/IsraelFulton/MailtoNull.git
cd MailtoNull
./install.sh
~/Applications/MailtoNull.app/Contents/Helpers/mailtoctl set-default
```

The installer builds and signs the app on your Mac, saves your current email-link handler, and installs MailtoNull in `~/Applications`. The last command asks macOS to use it for email links. Confirm if prompted. Installation is per user and requires no `sudo`. You can still open your mail app directly.

Keep the source directory for updates and removal. To update, run `git pull --ff-only` and `./install.sh` from that directory. The installer retains the original handler for uninstall.

## Copy the address instead

Open Settings explicitly from Terminal, choose **Copy to Clipboard**, and close the window. The choice saves immediately. Use the same window to switch back to **Ignore**.

```sh
open -n ~/Applications/MailtoNull.app --args --settings
```

With Copy enabled, clicking this link

```text
mailto:alex%2Bwork@example.com,sam@example.org?subject=Hello&cc=other@example.net
```

puts these two addresses on your clipboard.

```text
alex+work@example.com, sam@example.org
```

MailtoNull reads recipients from the address and any explicit `to=` fields. It skips the subject, body, cc, and bcc. If there’s no usable destination, it leaves the clipboard alone. Copy mode marks the pasteboard contents for this Mac only.

## Verify it

Run these from the source directory in a logged-in Mac session.

| Command | What it checks |
| --- | --- |
| `./test.sh` | Address parsing, Ignore mode, and copying to a private test pasteboard. Works before installation. |
| `./test.sh direct` | Delivers two links to the installed app, even if another app is the default. |
| `./test.sh smoke` | Checks that MailtoNull is the system default, then opens the same link twice through macOS. |

For the last two tests, select **Ignore**, close Settings, and leave focus and the clipboard alone for a few seconds. The smoke test runs `open 'mailto:test@example.com?subject=Hello'` from a cold start and again while the handler is running. It checks focus, clipboard change count, background activation policy, and process exit.

## If a mail app still opens

Run `~/Applications/MailtoNull.app/Contents/Helpers/mailtoctl status` to see which app macOS would use. If it lists another app, rerun `set-default`. You can also choose MailtoNull under **Mail → Settings → General → Default email reader → Select**. [Apple’s instructions](https://support.apple.com/en-us/102362)

If the smoke test passes but one website still opens a composer, check how that site or browser handles email links. A site that opens its own compose page can bypass the macOS handler entirely.

## Uninstall

Close MailtoNull Settings and run the uninstaller from the source directory.

```sh
./uninstall.sh
```

If MailtoNull is still the default, the script restores the app saved during installation. If you selected a different default yourself, it keeps your choice. It then removes the installed bundle, preferences, and recovery record. If restoration fails, it stops before removal. If the previous mail app is gone, select another email reader and rerun the script.

## How it works

The bundle claims the `mailto` scheme in [Info.plist](Info.plist). macOS delivers the URL to a [background-only AppKit delegate](Sources/main.swift). In Ignore mode the handler returns before accessing the pasteboard. In Copy mode it [parses the recipients](Sources/Mailto.swift) and writes the result with `NSPasteboard`. [Settings](Sources/Settings.swift) runs in a separate process so an incoming link can’t bring its window forward.

The [installer helper](Tools/handler.swift) registers the bundle with Launch Services and uses `NSWorkspace` to query and change the default. It saves the previous handler’s bundle ID and path in `~/Library/Application Support/MailtoNull/previous.plist`. The handler keeps no link history.

## License

[MIT](LICENSE)
