import AppKit
import SwiftUI

/// Status colours, deeper than the system ones so badge text stays readable on its pale
/// capsule in light themes, and lighter in dark ones (Ink, or the system dark mode).
enum Palette {
    private static func adaptive(_ light: (Double, Double, Double), _ dark: (Double, Double, Double)) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let c = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }
    static let red = adaptive((0.70, 0.11, 0.09), (1.00, 0.46, 0.42))
    static let orange = adaptive((0.70, 0.30, 0.00), (1.00, 0.62, 0.26))
    static let yellow = adaptive((0.55, 0.42, 0.00), (0.98, 0.82, 0.30))
    static let green = adaptive((0.07, 0.46, 0.18), (0.38, 0.86, 0.50))
    static let blue = adaptive((0.04, 0.33, 0.78), (0.45, 0.68, 1.00))
    static let indigo = adaptive((0.29, 0.20, 0.74), (0.66, 0.62, 1.00))
}

/// The looks Sandman can wear, chosen under View > Theme.
///
/// The first six are hand-drawn here. The last three come from ThemeMonkey, the theme
/// package next door, which owns their tokens and draws them with its own recipe —
/// `ThemeMonkeySkin.swift` is the whole of the seam.
enum AppTheme: String, CaseIterable, Identifiable {
    case standard, retro, os9, copland, things, ink
    case modernOS9, modernBeOS, modernRetro

    static let storageKey = "theme"
    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard: return "Standard"
        case .retro: return "Retro"
        case .os9: return "OS 9"
        case .copland: return "Copland"
        case .things: return "Things 3"
        case .ink: return "Ink"
        // The theme file's own name, so the menu can't drift from what it draws.
        case .modernOS9, .modernBeOS, .modernRetro: return monkeySkin?.label ?? rawValue
        }
    }

    var isCustom: Bool { self != .standard }
    var isDark: Bool { self == .ink }

    /// The ThemeMonkey theme behind this case, or nil for Sandman's own looks.
    var monkeySkin: MonkeySkin? {
        switch self {
        case .modernOS9: return .modernOS9
        case .modernBeOS: return .modernBeOS
        case .modernRetro: return .modernRetro
        default: return nil
        }
    }

    var isMonkey: Bool { monkeySkin != nil }

    /// The appearance to pin, or nil to follow the system. A ThemeMonkey theme ships both
    /// a day and a night palette, so it is never pinned — it answers the system instead.
    var appearance: ColorScheme? {
        if isMonkey { return nil }
        if isDark { return .dark }
        return isCustom ? .light : nil
    }

    /// Window background. Nil leaves the system's.
    var paper: Color? { monkeySkin?.paper ?? handDrawnPaper }

    var accent: Color? { monkeySkin?.accent ?? handDrawnAccent }

    var panel: PanelLook { monkeySkin?.panel ?? handDrawnPanel }

    /// Room between a panel's edge and its content.
    var panelInset: CGFloat { monkeySkin?.panelInset ?? 10 }

    private var handDrawnPaper: Color? {
        switch self {
        case .retro: return Color(white: 0.95)
        case .os9: return Color(white: 0.867)                               // Platinum grey
        case .copland: return Color(red: 0.78, green: 0.80, blue: 0.84)     // cooler, bluer grey
        case .things: return Color(red: 0.965, green: 0.968, blue: 0.975)
        case .ink: return Color(red: 0.067, green: 0.075, blue: 0.094)      // blue-black
        default: return nil                                                 // .standard keeps the system's
        }
    }

    private var handDrawnAccent: Color? {
        switch self {
        case .os9: return Color(red: 0.40, green: 0.40, blue: 0.80)         // classic lavender highlight
        case .copland: return Color(red: 0.20, green: 0.45, blue: 0.55)     // teal
        case .things: return Color(red: 0.11, green: 0.49, blue: 0.98)
        case .ink: return Color(red: 0.36, green: 0.74, blue: 0.88)         // cold cyan
        default: return nil                                                 // .standard and .retro keep the system's
        }
    }

    private var handDrawnPanel: PanelLook {
        switch self {
        case .retro:
            let ink = Color(white: 0.30)
            return PanelLook(fill: .white, corner: 8, border: ink, borderWidth: 2,
                             hardShadow: 4, hardShadowColor: ink.opacity(0.45))
        case .os9:
            return PanelLook(fill: Color(white: 0.93), corner: 0, border: Color(white: 0.33),
                             borderWidth: 1, bevel: true,
                             selection: Color(red: 0.80, green: 0.80, blue: 1.0))   // classic highlight
        case .copland:
            return PanelLook(fill: Color(red: 0.88, green: 0.89, blue: 0.92), corner: 9,
                             border: Color(white: 0.15), borderWidth: 1, bevel: true, bevelWidth: 2,
                             selection: Color(red: 0.74, green: 0.86, blue: 0.89))
        case .things:
            return PanelLook(fill: .white, corner: 10, border: Color(white: 0.90),
                             borderWidth: 1, softShadow: 5)
        case .ink:
            return PanelLook(fill: Color(red: 0.11, green: 0.12, blue: 0.145), corner: 6,
                             border: Color(red: 0.25, green: 0.28, blue: 0.33), borderWidth: 1,
                             selection: Color(red: 0.13, green: 0.25, blue: 0.34))
        default:
            return PanelLook(fill: .clear, corner: 0, border: .clear, borderWidth: 0)
        }
    }

    /// Extra room to leave right of and below a panel so its shadow isn't clipped.
    var gap: CGFloat {
        switch self {
        case .retro: return 4
        case .things: return 2
        default: return 0
        }
    }

    var uppercaseLabels: Bool { self == .retro }
    var showsHeadings: Bool { self == .retro || self == .os9 || self == .copland || isMonkey }
}

struct PanelLook {
    var fill: Color
    var corner: CGFloat
    var border: Color
    var borderWidth: CGFloat
    var hardShadow: CGFloat = 0
    var hardShadowColor: Color = .clear
    var softShadow: CGFloat = 0
    var bevel = false
    var bevelWidth: CGFloat = 1
    /// Fill for a selected panel. Nil means use the caller's own colour.
    var selection: Color?
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.standard
}

extension EnvironmentValues {
    /// Which look the user picked. ThemeMonkey's `\.theme` is a different thing — the
    /// resolved tokens of one — and the two are deliberately not spelled the same.
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

/// Applies the theme to everything inside. Uses values, not branches, so switching keeps
/// view state — except across the ThemeMonkey boundary, where the injector has to wrap the
/// tree and the subtree is rebuilt once. Switching between the hand-drawn looks, or between
/// the ThemeMonkey ones, keeps state as before.
struct ThemeRoot: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        content
            .environment(\.appTheme, theme)
            .tint(theme.accent)
            .background(theme.paper ?? Color.clear)
            .preferredColorScheme(theme.appearance)
            // Outermost, so ThemeMonkey's tokens reach everything below. A no-op for
            // Sandman's own looks.
            .modifier(MonkeyRoot(theme: theme))
    }
}

/// Draws the current theme's panel behind a view. Does nothing in the standard theme.
/// `tint` colours the panel. With `isSelection`, themes that have their own highlight use that instead.
struct ThemedPanel: ViewModifier {
    var tint: Color?
    var isSelection = false
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        if theme.isMonkey {
            // ThemeMonkey draws its own: recessed, because a panel holds data.
            content.modifier(MonkeyPanel(tint: tint, isSelection: isSelection))
        } else {
            handDrawn(content)
        }
    }

    private func handDrawn(_ content: Content) -> some View {
        let look = theme.panel
        let shape = RoundedRectangle(cornerRadius: look.corner, style: .continuous)
        let wash: Color? = tint == nil ? nil : (isSelection ? (look.selection ?? tint) : tint)
        let solid = isSelection && look.selection != nil && tint != nil
        return content
            // A translucent tint goes over white, not over the panel's grey, so it stays clean.
            .background(shape.fill(wash ?? Color.clear).opacity(theme.isCustom ? 1 : 0))
            .background(shape.fill(theme.isDark ? look.fill : Color.white).opacity(theme.isCustom && wash != nil && !solid ? 1 : 0))
            .background(
                shape.fill(look.fill)
                    .shadow(color: .black.opacity(look.softShadow > 0 ? 0.10 : 0),
                            radius: look.softShadow, y: look.softShadow > 0 ? 2 : 0)
            )
            .overlay(Bevel(width: look.bevelWidth, corner: look.corner).opacity(look.bevel ? 1 : 0))
            .overlay(shape.strokeBorder(look.border, lineWidth: look.borderWidth).allowsHitTesting(false))
            .background(
                shape
                    .fill(look.hardShadowColor)
                    .offset(x: look.hardShadow, y: look.hardShadow)
            )
    }
}

extension View {
    func themedPanel(tint: Color? = nil, isSelection: Bool = false) -> some View {
        modifier(ThemedPanel(tint: tint, isSelection: isSelection))
    }
}

/// The raised edge of a classic Mac OS panel: light along the top and left, dark along the bottom and right.
private struct Bevel: View {
    var width: CGFloat = 1
    var corner: CGFloat = 0

    private func ring(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: max(0, corner - 1), style: .continuous)
            .inset(by: 1)
            .strokeBorder(color, lineWidth: width)
    }

    var body: some View {
        // A grey ring all the way round, with a white ring on top that is cut to the top and
        // left edges. The cut runs at 45 degrees out of the bottom-left and top-right corners,
        // so each edge is one colour along its whole length whatever the panel's proportions.
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let m = min(w, h) / 2
            ring(Color(white: 0.55))
            ring(.white)
                .mask(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: w, y: 0))
                        path.addLine(to: CGPoint(x: w - m, y: m))
                        path.addLine(to: CGPoint(x: m, y: h - m))
                        path.addLine(to: CGPoint(x: 0, y: h))
                        path.closeSubpath()
                    }
                )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A grouped box: the system GroupBox normally, a themed panel otherwise.
struct Panel<Content: View>: View {
    @Environment(\.appTheme) private var theme
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if theme.isCustom {
            content
                .padding(theme.panelInset)
                .themedPanel()
                .padding(.trailing, theme.gap)
                .padding(.bottom, theme.gap)
        } else {
            GroupBox { content }
        }
    }
}

/// A bold heading with a rule under it and an optional count at the right.
struct SectionHeading: View {
    let title: String
    var trailing: String = ""

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.title3.weight(.bold))
                Spacer()
                Text(trailing).font(.callout).foregroundStyle(.secondary)
            }
            Rectangle().fill(Color.secondary).frame(height: 1.5)
        }
    }
}
