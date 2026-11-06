import AppKit

// A separate accessory app keeps the mailto process permanently nonactivating.
@main
final class Settings: NSObject, NSApplicationDelegate {
    private let preferences = UserDefaults(suiteName: "local.MailtoNull")!
    private let copyKey = "CopyRecipients"
    private var window: NSWindow?

    static func main() {
        let app = NSApplication.shared
        let delegate = Settings()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        window?.makeKeyAndOrderFront(nil)
        return false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 340, height: 118),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "MailtoNull Settings"
        window.isReleasedWhenClosed = false

        let label = NSTextField(labelWithString: "When you click an email link")
        label.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
        let choice = NSPopUpButton(frame: .zero, pullsDown: false)
        choice.addItems(withTitles: ["Ignore", "Copy to Clipboard"])
        choice.selectItem(at: preferences.bool(forKey: copyKey) ? 1 : 0)
        choice.target = self
        choice.action = #selector(changeMode(_:))
        choice.setAccessibilityLabel(label.stringValue)
        let stack = NSStackView(views: [label, choice])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        let content = window.contentView!
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            choice.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
        self.window = window
        window.center()
        window.makeKeyAndOrderFront(nil)
        if #available(macOS 14, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
    }

    @objc private func changeMode(_ sender: NSPopUpButton) {
        preferences.set(sender.indexOfSelectedItem == 1, forKey: copyKey)
    }
}
