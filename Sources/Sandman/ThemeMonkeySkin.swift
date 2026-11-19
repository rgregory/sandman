//
//  Sandman's one window onto ThemeMonkey.
//
//  ThemeMonkey owns the tokens and the drawing recipe; Sandman owns the app. This is the
//  only file that imports the package, and everything it hands back is in Sandman's own
//  vocabulary — a `Color`, a `PanelLook`, a `ViewModifier` — so no other file has to know
//  the package is there. That also keeps the two `theme` environment keys from ever
//  meeting: Sandman's `\.appTheme` carries which look the user picked, ThemeMonkey's
//  `\.theme` carries the resolved tokens, and only this file sees both.
//
//  Appearance is not pinned for these themes. Each ships a day and a night palette, so
//  the colours below are dynamic NSColors — the same trick `Palette` uses for status
//  colours — and the window follows the system without Sandman asking which it is.
//

import AppKit
import OSLog
import SwiftUI
import ThemeMonkey

/// One of ThemeMonkey's themes, resolved far enough to answer Sandman's questions.
struct MonkeySkin {
    /// Loaded once each, lazily: a static `let` is cached and thread-safe, and ThemeMonkey
    /// asks consumers not to reload the file on every resolve.
    static let modernOS9 = MonkeySkin(resource: ModernOS9.resource)
    static let modernBeOS = MonkeySkin(resource: ModernBeOS.resource)
    static let modernRetro = MonkeySkin(resource: ModernRetro.resource)

    /// The theme file itself, for the injector at the window root.
    let file: ThemeFile

    private let day: ThemeFile.Palette
    private let night: ThemeFile.Palette
    /// Resolved once, for the metrics only — radii and insets don't vary by appearance.
    private let resolved: Theme

    private init(resource: String) {
        // Fails soft: a missing or malformed file degrades to ThemeMonkey's built-in theme
        // and logs, so a bundling mistake is a plain-looking window, never a crash.
        let file = ThemeFile.load(resource: resource)
        self.file = file
        self.day = file.palette(for: .light).palette
        self.night = file.palette(for: .dark).palette
        self.resolved = Theme(file: file, scheme: .light)
    }

    /// The theme's own name, so the View › Theme menu can't drift from the theme files.
    var label: String { file.label }

    /// Window background.
    var paper: Color { adaptive(\.face) }

    var accent: Color { adaptive(\.accent) }

    /// Sandman's panel vocabulary, filled in from the theme. The colours are only the
    /// fallback path: a panel under one of these themes is drawn by `MonkeyPanel` with
    /// ThemeMonkey's own recipe. What the rest of Sandman reads from here is the radius,
    /// which it needs to clip the table and the cards to the same curve.
    var panel: PanelLook {
        PanelLook(fill: adaptive(\.sunken),
                  corner: resolved.radius.well,
                  border: adaptive(\.line),
                  borderWidth: resolved.metrics.bevel.edgeWidth,
                  selection: adaptive(\.selection))
    }

    /// Inset between a panel's edge and its content, from the theme rather than a literal.
    var panelInset: CGFloat { resolved.metrics.pad.wellInset }

    /// Author-time lint, in debug builds only. Real findings are recorded in ThemeMonkey's
    /// own tests; this is here so a theme edited next door shows up while Sandman runs.
    func lint() {
        #if DEBUG
        let log = Logger(subsystem: "com.rgregory.sandman", category: "theme")
        let name = file.name
        for warning in file.validate() {
            log.warning("\(name, privacy: .public).theme: \(warning, privacy: .public)")
        }
        #endif
    }

    /// Light and dark in one colour, resolved by the view's effective appearance.
    private func adaptive(_ role: KeyPath<ThemeFile.Palette, ThemeRGBA>) -> Color {
        let d = day[keyPath: role], n = night[keyPath: role]
        return Color(nsColor: NSColor(name: nil) { appearance in
            let c = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? n : d
            return NSColor(srgbRed: c.r, green: c.g, blue: c.b, alpha: c.a)
        })
    }
}

/// Injects the theme at the window root — appearance, chassis and accessibility resolved
/// once — for the ThemeMonkey looks, and does nothing for Sandman's own.
struct MonkeyRoot: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        if let skin = theme.monkeySkin {
            content
                .themed(skin.file)
                .onAppear { skin.lint() }
        } else {
            content
        }
    }
}

/// A panel drawn by ThemeMonkey's recipe: recessed, because a panel holds data. The tint
/// goes over the well rather than replacing it, and a selected row takes the theme's own
/// selection colour instead of the caller's.
struct MonkeyPanel: ViewModifier {
    @Environment(\.theme) private var t
    var tint: Color?
    var isSelection = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: t.radius.well, style: .continuous)
        return content
            .background {
                if let tint {
                    shape.fill(isSelection ? t.selection : tint)
                }
            }
            .themeWell()
    }
}
