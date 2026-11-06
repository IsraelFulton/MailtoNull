import AppKit

enum Mailto {
    // Match one mailbox at the current position. A quoted local part can contain a comma.
    private static let mailbox: NSRegularExpression = {
        let atom = #"[\p{L}\p{M}\p{N}!#$%&'*+/=?^_`{|}~-]+"#
        let local = #"(?:\#(atom)(?:\.\#(atom))*|"(?:[^"\\]|\\.)*")"#
        let label = #"[\p{L}\p{N}](?:[\p{L}\p{M}\p{N}-]*[\p{L}\p{M}\p{N}])?"#
        let domain = #"(?:\#(label)(?:\.\#(label))*|\[[A-Za-z0-9:.]+\])"#
        return try! NSRegularExpression(pattern: #"\G *(\#(local)@\#(domain)) *(?:,|\z)"#)
    }()

    static func recipients(_ raw: String) -> String? {
        guard raw.prefix(7).lowercased() == "mailto:",
              raw.rangeOfCharacter(from: .controlCharacters) == nil,
              !raw.contains("#") else { return nil }
        // Split URI syntax before decoding so encoded '?' and '&' stay in their field.
        let parts = raw.dropFirst(7).split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        guard let path = parts.first, !path.contains("/"),
              let primary = path.removingPercentEncoding else { return nil }
        var lists = primary.isEmpty ? [] : [primary]
        if parts.count == 2 && !parts[1].isEmpty {
            for field in parts[1].split(separator: "&", omittingEmptySubsequences: false) {
                let pair = field.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                guard pair.count == 2, let name = pair[0].removingPercentEncoding, !name.isEmpty,
                      let value = pair[1].removingPercentEncoding else { return nil }
                if name.lowercased() == "to" { lists.append(value) }
            }
        }
        var addresses: [String] = []
        for list in lists {
            guard !list.isEmpty, !list.hasSuffix(","),
                  list.rangeOfCharacter(from: .controlCharacters) == nil else { return nil }
            let ns = list as NSString
            var end = 0
            for match in mailbox.matches(in: list, range: NSRange(location: 0, length: ns.length)) {
                addresses.append(ns.substring(with: match.range(at: 1)))
                end = NSMaxRange(match.range)
            }
            guard end == ns.length else { return nil }
        }
        return addresses.isEmpty ? nil : addresses.joined(separator: ", ")
    }

    static func handle(_ urls: [URL], copy: Bool, board: @autoclosure () -> NSPasteboard = .general) {
        guard copy else { return }
        let text = urls.compactMap { recipients($0.absoluteString) }.joined(separator: ", ")
        guard !text.isEmpty else { return }
        let pasteboard = board()
        pasteboard.prepareForNewContents(with: .currentHostOnly)
        pasteboard.setString(text, forType: .string)
    }
}
