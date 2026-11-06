// Run from the GUI login session. Inspect the general pasteboard's counter only.
import AppKit

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("FAIL: " + message + "\n").utf8))
    exit(1)
}
let id = "local.MailtoNull"
let app = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications/MailtoNull.app")
let link = "mailto:test@example.com?subject=Hello"
let direct = CommandLine.arguments.last == "direct"
let ws = NSWorkspace.shared
func running() -> NSRunningApplication? {
    NSRunningApplication.runningApplications(withBundleIdentifier: id).first
}
guard Bundle(url: app)?.bundleIdentifier == id else { fail("Run install.sh first.") }
guard running() == nil else { fail("Close MailtoNull Settings and wait a second, then retry.") }
guard UserDefaults(suiteName: id)?.bool(forKey: "CopyRecipients") == false else {
    fail("Select Ignore in Settings before running the smoke test.")
}
guard let front = ws.frontmostApplication?.processIdentifier else { fail("A GUI login session is required.") }
let counter = NSPasteboard.general.changeCount
func openLink() throws {
    if !direct && ws.urlForApplication(toOpen: URL(string: link)!)?.resolvingSymlinksInPath() != app.resolvingSymlinksInPath() {
        fail("MailtoNull is not the default. Skipped open to avoid launching another app.")
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = (direct ? ["-a", app.path] : []) + [link]
    try process.run()
    process.waitUntilExit()
    if process.terminationStatus != 0 { fail("open returned \(process.terminationStatus).") }
}
func sample() {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02))
    if NSPasteboard.general.changeCount != counter { fail("Clipboard changed during Ignore test.") }
    if ws.frontmostApplication?.processIdentifier != front { fail("Frontmost app changed during test.") }
    if let handler = running(), handler.activationPolicy != .prohibited { fail("Handler became activatable.") }
}
try openLink()
let deadline = Date(timeIntervalSinceNow: 5)
while running()?.isFinishedLaunching != true && Date() < deadline { sample() }
guard let cold = running(), cold.isFinishedLaunching else { fail("Did not observe the cold handler launch.") }
// After a second delivery the same process should survive its original idle deadline.
let secondClick = Date(timeIntervalSinceNow: 0.45)
while Date() < secondClick { sample() }
try openLink()
let afterFirstTimeout = Date(timeIntervalSinceNow: 0.43)
while Date() < afterFirstTimeout {
    sample()
    if running()?.processIdentifier != cold.processIdentifier { fail("Warm click did not extend the same process.") }
}
let exitDeadline = Date(timeIntervalSinceNow: 3)
while running() != nil && Date() < exitDeadline { sample() }
guard running() == nil else { fail("Handler did not exit.") }
print("PASS (\(direct ? "explicit app" : "system default")): cold and warm delivery, background policy, steady focus and clipboard, process exited.")
