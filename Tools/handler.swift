// Installer CLI only. The URL handler never calls this program.
import AppKit
import CoreServices

let files = FileManager.default
let app = files.homeDirectoryForCurrentUser.appendingPathComponent("Applications/MailtoNull.app")
let ourID = "local.MailtoNull"
let probe = URL(string: "mailto:test@example.com")!
let workspace = NSWorkspace.shared
let state = files.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("MailtoNull/previous.plist")

struct Previous: Codable {
    let path: String
    let bundleID: String
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("MailtoNull: " + message + "\n").utf8))
    exit(1)
}

func current() -> URL {
    guard let url = workspace.urlForApplication(toOpen: probe) else {
        fail("Cannot resolve mailto in this login session. Run from a local Terminal.")
    }
    return url.resolvingSymlinksInPath()
}

func previous() throws -> Previous {
    try PropertyListDecoder().decode(Previous.self, from: Data(contentsOf: state))
}

func capture() throws {
    if files.fileExists(atPath: state.path) {
        print("Retained previous handler:", try previous().path)
        return
    }
    let url = current()
    guard let id = Bundle(url: url)?.bundleIdentifier, id != ourID else {
        fail("Cannot identify the previous mailto app. Select it manually before installing.")
    }
    let record = Previous(path: url.path, bundleID: id)
    try files.createDirectory(at: state.deletingLastPathComponent(), withIntermediateDirectories: true)
    try PropertyListEncoder().encode(record).write(to: state, options: .withoutOverwriting)
    print("Saved previous handler:", url.path)
}

func select(_ url: URL) -> Never {
    let target = url.resolvingSymlinksInPath()
    if current() == target { print("Default mailto app:", target.path); exit(0) }
    print("Requesting", target.path, "for mailto. Respond to macOS if prompted.")
    fflush(stdout)
    workspace.setDefaultApplication(at: target, toOpenURLsWithScheme: "mailto") { error in
        if let error = error { fail(error.localizedDescription + " Check the current handler with status.") }
        guard current() == target else { fail("macOS did not select the requested app. Check status.") }
        print("Default mailto app:", target.path)
        exit(0)
    }
    RunLoop.main.run()
    fail("The request ended before macOS confirmed the default.")
}

do {
    switch CommandLine.arguments.dropFirst().first {
    case "status": print(current().path)
    case "is-default": exit(current() == app.resolvingSymlinksInPath() ? 0 : 1)
    case "install":
        guard CommandLine.arguments.count == 3 else { fail("Expected a staged bundle path.") }
        let staged = URL(fileURLWithPath: CommandLine.arguments[2])
        guard Bundle(url: staged)?.bundleIdentifier == ourID else { fail("Invalid staged bundle.") }
        try capture()
        if files.fileExists(atPath: app.path) {
            guard Bundle(url: app)?.bundleIdentifier == ourID,
                  (try app.resourceValues(forKeys: [.isSymbolicLinkKey])).isSymbolicLink != true else {
                fail("Refusing to replace a different app or a symlink.")
            }
            _ = try files.replaceItemAt(app, withItemAt: staged, options: .usingNewMetadataOnly)
        } else {
            try files.moveItem(at: staged, to: app)
        }
    case "register":
        let result = LSRegisterURL(app as CFURL, true)
        guard result == noErr else { fail("Launch Services registration failed (\(result)). Run install.sh again.") }
        print("Registered:", app.path)
    case "set-default":
        _ = try previous() // Require a recovery record before changing the binding.
        guard Bundle(url: app)?.bundleIdentifier == ourID else { fail("Run install.sh first.") }
        select(app)
    case "restore":
        let url = current()
        guard Bundle(url: url)?.bundleIdentifier == ourID else {
            print("Keeping current mailto app:", url.path)
            exit(0)
        }
        let record = try previous()
        var target = URL(fileURLWithPath: record.path)
        if Bundle(url: target)?.bundleIdentifier != record.bundleID {
            guard let moved = workspace.urlForApplication(withBundleIdentifier: record.bundleID) else {
                fail("Previous app is unavailable. Select another mailto app, then run uninstall.sh again.")
            }
            target = moved
        }
        guard record.bundleID != ourID else { fail("Invalid previous handler. Select another mailto app first.") }
        select(target)
    default: fail("Expected status, is-default, install, register, set-default, or restore.")
    }
} catch { fail(error.localizedDescription) }
