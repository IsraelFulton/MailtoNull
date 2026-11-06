import AppKit

let cases: [(String, String?)] = [
    ("mailto:test@example.com?subject=Hello", "test@example.com"),
    ("MAILTO:a+b@example.net", "a+b@example.net"),
    ("mailto:a%2Bb%40example.net", "a+b@example.net"),
    ("mailto:a%252Bb@example.org", "a%2Bb@example.org"),
    ("mailto:a@x.org,b@y.org", "a@x.org, b@y.org"),
    ("mailto:a@x.org%2C%20b@y.org", "a@x.org, b@y.org"),
    ("mailto:%22a%2Cb%22@x.org,c@x.org", "\"a,b\"@x.org, c@x.org"),
    ("mailto:O%27Neil%26Co%3F@x.org?body=one%0D%0Atwo", "O'Neil&Co?@x.org"),
    ("mailto:%C3%A9@m%C3%BCller.de", "é@müller.de"),
    ("mailto:user@%5BIPv6:2001:db8::1%5D", "user@[IPv6:2001:db8::1]"),
    ("mailto:a@x.org?TO=b%40y.org&to=c@z.org&cc=d@x.org&bcc=e@x.org&subject=f@x.org&body=g@x.org", "a@x.org, b@y.org, c@z.org"),
    ("mailto:?%74o=a%40x.org&body=%26to%3Db@x.org", "a@x.org"),
    ("mailto:?subject=a@x.org&cc=b@y.org&bcc=c@z.org", nil),
    ("mailto:", nil), ("https://x.org/a@x.org", nil), ("mailto://x@y.org", nil),
    ("mailto:bad", nil), ("mailto:bad,ok@x.org", nil), ("mailto:a@b.org,bad", nil),
    ("mailto:a@@b.org", nil), ("mailto:a@-bad.org", nil), ("mailto:a..b@x.org", nil),
    ("mailto:a%4@x.org", nil), ("mailto:a%FF@x.org", nil),
    ("mailto:a@x.org?to=bad%", nil), ("mailto:a@x.org#fragment", nil),
    ("mailto:a@x.org%0D%0ABcc%3Ab@x.org", nil), ("mailto:a@x.org?to=b@x.org%00", nil),
    ("mailto:a@x.org,", nil), ("mailto:a@x.org,,b@y.org", nil), ("mailto:a@x.org?to", nil)
]
func check(_ condition: Bool, _ message: String) {
    if !condition { FileHandle.standardError.write(Data(("FAIL: " + message + "\n").utf8)); exit(1) }
}
for (input, expected) in cases { check(Mailto.recipients(input) == expected, input) }
print("PASS: \(cases.count) mailto parser cases.")
let link = URL(string: "mailto:test@example.com?subject=Hello")!
func unexpectedBoard() -> NSPasteboard { fatalError("Unexpected pasteboard access") }
Mailto.handle([link], copy: false, board: unexpectedBoard())
Mailto.handle([URL(string: "mailto:bad")!], copy: true, board: unexpectedBoard())
print("PASS: Ignore and invalid recipients skip pasteboard access.")
if CommandLine.arguments.contains("--pasteboard") {
    let board = NSPasteboard.withUniqueName()
    defer { board.releaseGlobally() }
    Mailto.handle([link, URL(string: "mailto:?to=two@x.org")!], copy: true, board: board)
    check(board.string(forType: .string) == "test@example.com, two@x.org", "isolated NSPasteboard copy")
    print("PASS: copy mode wrote only recipients to a private test pasteboard.")
}
