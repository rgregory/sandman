import SwiftUI

/// What an app's signature actually lets it reach, in plain words.
///
/// A modern bundle carries dozens or hundreds of entitlement keys, and reading them is a
/// specialist job. This picks out the ones that change what the app can touch, says what each
/// would cost you if the app were taken over, and leaves the rest counted instead of listed.
/// Widest reach first, so the line that matters is the one read first.
struct Capability: Identifiable, Hashable {
    enum Weight: Int, Comparable {
        /// Reaches past the sandbox, or past the protections around its own code.
        case broad
        /// Your data, your devices, other apps.
        case notable
        /// Ordinary, and expected of most apps.
        case routine

        static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }

        var tint: Color {
            switch self {
            case .broad: return Palette.red
            case .notable: return Palette.orange
            case .routine: return .secondary
            }
        }
    }

    var id: String { title }
    let title: String
    let detail: String
    let symbol: String
    let weight: Weight
    /// The entitlement keys this was read from.
    let keys: [String]
}

struct CapabilityReport {
    var capabilities: [Capability] = []
    /// Keys that are set but widen nothing worth a sentence.
    var otherCount = 0
    /// Of those, the ones only Apple can grant itself.
    var appleInternalCount = 0
    var total = 0
}

/// One entitlement, or a family of them, turned into a sentence.
private struct Rule {
    let title: String
    let symbol: String
    let weight: Capability.Weight
    let matches: (String) -> Bool
    /// Takes the keys that matched, so a rule can name the folders or devices it found.
    let detail: ([String]) -> String

    init(_ title: String, _ symbol: String, _ weight: Capability.Weight,
         matches: @escaping (String) -> Bool,
         detail: @escaping ([String]) -> String) {
        self.title = title
        self.symbol = symbol
        self.weight = weight
        self.matches = matches
        self.detail = detail
    }

    /// The common case: fixed keys and a fixed sentence.
    init(_ title: String, _ symbol: String, _ weight: Capability.Weight,
         keys: [String], _ detail: String) {
        self.init(title, symbol, weight,
                  matches: { keys.contains($0) },
                  detail: { _ in detail })
    }
}

enum CapabilityReader {
    static func read(_ entitlements: [EntitlementItem]) -> CapabilityReport {
        // A key counts as set unless it is explicitly false or empty. Strings, arrays and
        // dictionaries all describe to something non-empty.
        let on = entitlements.filter { !$0.value.isEmpty && $0.value != "false" }.map(\.key)

        var report = CapabilityReport()
        report.total = entitlements.count
        var consumed = Set(ignored)

        for rule in rules {
            let hits = on.filter { !consumed.contains($0) && rule.matches($0) }
            guard !hits.isEmpty else { continue }
            consumed.formUnion(hits)
            report.capabilities.append(Capability(title: rule.title,
                                                  detail: rule.detail(hits),
                                                  symbol: rule.symbol,
                                                  weight: rule.weight,
                                                  keys: hits))
        }

        let rest = on.filter { !consumed.contains($0) }
        report.otherCount = rest.count
        report.appleInternalCount = rest.filter { $0.hasPrefix("com.apple.private.") }.count
        report.capabilities.sort { ($0.weight, $0.title) < ($1.weight, $1.title) }
        return report
    }

    /// Keys that say what the app is rather than what it can reach. Shown in the full list,
    /// never as a capability of their own.
    private static let ignored: [String] = [
        "com.apple.security.app-sandbox",
        "com.apple.application-identifier",
        "application-identifier",
        "com.apple.developer.team-identifier",
    ]

    private static func tail(_ key: String) -> String {
        key.split(separator: ".").last.map(String.init) ?? key
    }

    private static let folderNames: [String: String] = [
        "downloads": "Downloads", "desktop": "Desktop", "documents": "Documents",
        "movies": "Movies", "music": "Music", "pictures": "Pictures",
    ]

    private static let rules: [Rule] = [
        // ---- Reaches past its own sandbox, or past the protections around its code

        Rule("Holes punched in its own sandbox", "lock.trianglebadge.exclamationmark.fill", .broad,
             matches: { $0.hasPrefix("com.apple.security.temporary-exception.") },
             detail: { keys in
                 "Temporary exceptions let it reach \(keys.count == 1 ? "a path or service" : "paths and services") "
                 + "the sandbox would otherwise block. They are meant as a stopgap, and they are the usual way a "
                 + "sandbox ends up wider than it looks."
             }),

        Rule("Loads code Apple didn't sign", "shippingbox.fill", .broad,
             keys: ["com.apple.security.cs.disable-library-validation"],
             "Another program's library can be loaded into it. Code that gets in that way inherits everything this app is allowed to do."),

        Rule("Starts with library paths from the environment", "arrow.triangle.branch", .broad,
             keys: ["com.apple.security.cs.allow-dyld-environment-variables"],
             "Whatever starts it can point it at libraries of its own choosing."),

        Rule("Runs code it writes into memory", "memorychip.fill", .broad,
             keys: ["com.apple.security.cs.allow-unsigned-executable-memory"],
             "It can execute instructions that were never signed or checked, so a bug that writes memory can become a bug that runs code."),

        Rule("Can attach to other programs", "ladybug.fill", .broad,
             keys: ["com.apple.security.cs.debugger"],
             "A debugger entitlement: it can read and change the memory of other processes you run."),

        Rule("Other programs can attach to it", "ladybug", .broad,
             keys: ["com.apple.security.get-task-allow"],
             "Anything you run can read and change this app's memory while it works. Shipping builds normally turn this off, so it usually means a debug build."),

        Rule("Tells other apps what to do", "app.connected.to.app.below.fill", .broad,
             keys: ["com.apple.security.automation.apple-events",
                    "com.apple.security.scripting-targets"],
             "Sends Apple events, so it can drive your other applications and reach, through them, whatever they can reach."),

        // ---- Your data, your devices, other apps

        Rule("Reaches your folders without asking", "folder.fill", .notable,
             matches: { key in
                 CapabilityReader.folderNames.keys.contains { key.hasPrefix("com.apple.security.files.\($0)") }
                     || key.hasPrefix("com.apple.security.assets.")
             },
             detail: { keys in
                 let names = Set(keys.compactMap { key -> String? in
                     CapabilityReader.folderNames.first { key.contains(".\($0.key)") }?.value
                 }).sorted()
                 let list = names.isEmpty ? "media folders" : names.joined(separator: ", ")
                 return "Standing access to \(list). No open panel, no prompt."
             }),

        Rule("Camera", "camera.fill", .notable,
             keys: ["com.apple.security.device.camera"],
             "Can open the camera. macOS still asks you the first time."),

        Rule("Microphone", "mic.fill", .notable,
             keys: ["com.apple.security.device.audio-input", "com.apple.security.device.microphone"],
             "Can record audio. macOS still asks you the first time."),

        Rule("Your location", "location.fill", .notable,
             keys: ["com.apple.security.personal-information.location"],
             "Can ask the system where you are."),

        Rule("Contacts, calendar and photos", "person.crop.circle.fill", .notable,
             matches: { $0.hasPrefix("com.apple.security.personal-information.") },
             detail: { keys in
                 let names = keys.map { CapabilityReader.tail($0).replacingOccurrences(of: "-", with: " ") }.sorted()
                 return "Reads your \(names.joined(separator: ", "))."
             }),

        Rule("Accepts incoming connections", "antenna.radiowaves.left.and.right", .notable,
             keys: ["com.apple.security.network.server"],
             "Listens for connections from outside, so other machines can start a conversation with it."),

        Rule("Compiles code as it runs", "bolt.fill", .notable,
             keys: ["com.apple.security.cs.allow-jit"],
             "A just-in-time compiler. Normal for a browser or anything with a JavaScript engine, and a smaller hole than unsigned memory."),

        Rule("Connected devices", "cable.connector", .notable,
             matches: { $0.hasPrefix("com.apple.security.device.") },
             detail: { keys in
                 "Talks to \(keys.map { CapabilityReader.tail($0) }.sorted().joined(separator: ", ")) hardware."
             }),

        // ---- Ordinary

        Rule("Reaches the internet", "globe", .routine,
             keys: ["com.apple.security.network.client"],
             "Makes outgoing connections, like most apps."),

        Rule("Files you pick yourself", "doc.badge.plus", .routine,
             matches: { $0.hasPrefix("com.apple.security.files.user-selected")
                 || $0.hasPrefix("com.apple.security.files.bookmarks") },
             detail: { _ in "Only what you hand it in an open or save panel, plus anything you handed it before." }),

        Rule("Shares storage with its own family", "square.stack.3d.up.fill", .routine,
             matches: { $0.hasPrefix("com.apple.security.application-groups")
                 || $0.hasPrefix("keychain-access-groups") },
             detail: { _ in "A container and keychain items shared with the same developer's other apps." }),

        Rule("Inherits its parent's sandbox", "arrow.down.right.circle", .routine,
             keys: ["com.apple.security.inherit"],
             "A helper process: it runs inside whatever sandbox started it, and can't widen it."),

        Rule("Printing", "printer.fill", .routine,
             keys: ["com.apple.security.print"],
             "Can send jobs to your printers."),
    ]
}

/// The capability section of the details sidebar: what the signature lets the app reach,
/// in sentences, with the raw entitlements kept behind a disclosure.
struct CapabilitiesPanel: View {
    let app: AppRecord
    @State private var showAll = false
    @State private var open: Set<String> = []
    private let report: CapabilityReport

    init(app: AppRecord) {
        self.app = app
        self.report = CapabilityReader.read(app.entitlements)
    }

    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("What it's allowed to do").font(.headline)
                    Spacer()
                    Text("\(report.total) entitlement\(report.total == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(lead)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if report.capabilities.isEmpty {
                    Text(app.entitlements.isEmpty
                         ? "Its signature declares no entitlements at all."
                         : "Nothing in its signature widens what it can reach.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(report.capabilities) { capability in
                        row(capability)
                    }
                }

                if report.otherCount > 0 {
                    Text(rest)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !app.entitlements.isEmpty {
                    Divider()
                    Disclosure(isExpanded: $showAll) {
                        Text("All entitlements (\(report.total))").font(.caption.weight(.medium))
                    } content: {
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(app.entitlements) { item in
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.key)
                                        .font(.system(.caption, design: .monospaced))
                                        .textSelection(.enabled)
                                    Text(item.value)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                        .padding(.leading, 18)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        }
    }

    private func row(_ capability: Capability) -> some View {
        Disclosure(isExpanded: Binding(
            get: { open.contains(capability.id) },
            set: { isOpen in
                if isOpen { open.insert(capability.id) } else { open.remove(capability.id) }
            }
        )) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Image(systemName: capability.symbol)
                    .foregroundStyle(capability.weight.tint)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(capability.title)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(capability.weight == .broad ? capability.weight.tint : Color.primary)
                    Text(capability.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        } content: {
            VStack(alignment: .leading, spacing: 1) {
                ForEach(capability.keys, id: \.self) { key in
                    Text(key)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .padding(.leading, 41)
        }
    }

    /// Entitlements only mean something inside a sandbox. Outside one they are a statement of
    /// intent, except for the hardened-runtime keys, which say what other code may do to the app.
    private var lead: String {
        if app.isIOSApp {
            return "An iPhone or iPad app, so it always runs in a container. Everything below is what that container lets through; anything not listed is blocked."
        }
        if app.isSandboxed {
            return "Sandboxed, so this list is the whole of what it can reach. Anything not below is blocked, whatever the app tries."
        }
        return "Not sandboxed, so these don't hold it back: \(app.name) can already reach anything you can. They still tell you what it was built to do — and the lines about its own code say what another program may do to it."
    }

    private var rest: String {
        let others = "\(report.otherCount) more entitlement\(report.otherCount == 1 ? "" : "s") that don't widen what it reaches"
        guard report.appleInternalCount > 0 else { return others + "." }
        return others + ", \(report.appleInternalCount) of them Apple-internal keys only Apple can grant itself."
    }
}
