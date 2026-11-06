import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var idleTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if CommandLine.arguments.dropFirst().first == "--settings" {
            let settings = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/Settings.app")
            NSWorkspace.shared.openApplication(at: settings, configuration: .init()) { _, error in
                if let error = error { NSLog("Could not open Settings: %@", error.localizedDescription) }
            }
        }
        scheduleExit()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        Mailto.handle(urls, copy: UserDefaults.standard.bool(forKey: "CopyRecipients"))
        scheduleExit()
    }

    // Coalesce clicks already in flight, then exit. AppKit may deliver a cold URL
    // before didFinishLaunching, so neither callback terminates synchronously.
    private func scheduleExit() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
            NSApp.terminate(nil)
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { false }
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
