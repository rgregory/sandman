import AppKit
import SwiftUI

/// The Layered tile's view: one card per app whose helpers sandbox themselves, each drawing
/// its sandboxes and how they talk to the main process.
struct LayeredGallery: View {
    let apps: [AppRecord]
    @Binding var selection: AppRecord.ID?
    @Binding var showInspector: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            if theme.showsHeadings {
                SectionHeading(title: "Layered applications", trailing: "\(apps.count)")
                    .padding([.horizontal, .top], 14)
            }
            LazyVStack(spacing: 16) {
                ForEach(apps) { app in
                    LayeredCard(app: app, isSelected: selection == app.id)
                        .onTapGesture(count: 2) {
                            selection = app.id
                            showInspector = true
                        }
                        .onTapGesture { selection = app.id }
                }
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.paper ?? Color(nsColor: .windowBackgroundColor))
        .overlay {
            if apps.isEmpty {
                ContentUnavailableView(
                    "No layered applications",
                    systemImage: "square.stack.3d.up",
                    description: Text("Chromium, Electron and Firefox apps whose helpers sandbox themselves show up here.")
                )
            }
        }
    }
}

/// One layered app: who it is, then its sandboxes drawn as a diagram.
struct LayeredCard: View {
    let app: AppRecord
    let isSelected: Bool
    @EnvironmentObject private var store: AppStore
    @State private var report: SandboxLayerReport?

    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
                        .resizable()
                        .frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(app.name).font(.title3.weight(.semibold))
                        Text(app.runtime == .notRunning ? "Not running · read from the app's files" : "Running · checked live")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    ExposureMeter(exposure: app.exposure)
                }

                if let risk = app.rendererRisk {
                    Label(risk.explanation, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(Palette.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let report {
                    SandboxDiagram(report: report)
                } else {
                    ProgressView().controlSize(.small)
                }

                Text(caption)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.accentColor, lineWidth: isSelected ? 2 : 0)
        )
        .contentShape(Rectangle())
        .task(id: app.id + app.runtimeLabel) {
            let app = self.app
            let code = store.replaced[app.url.path].map { URL(fileURLWithPath: $0) }
            report = await Task.detached(priority: .userInitiated) {
                SandboxLayerScanner.report(for: app, codeURL: code)
            }.value
        }
    }

    private var caption: String {
        switch app.ownSandbox {
        case .firefox?:
            return "Each helper runs in its own sandbox and can't open your files or the network itself. It asks the main process over IPC, and the main process does it on its behalf if it should. Getting out takes a bug in a helper and then another in the main process, which runs with your full permissions."
        default:
            return "Each helper runs in its own sandbox and can't open your files or the network itself. The main process is the broker: helpers ask it over IPC (Chromium's Mojo), and it connects them to each other or does the work for them. Getting out takes a bug in a helper and then another in the main process, which runs with your full permissions."
        }
    }
}

/// The main process on the left, an IPC bus, and each sandboxed helper on the right.
struct SandboxDiagram: View {
    let report: SandboxLayerReport

    private let rowHeight: CGFloat = 54
    private let rowGap: CGFloat = 8

    private var main: SandboxLayer? { report.layers.first { $0.order == 0 } }
    private var helpers: [SandboxLayer] { report.layers.filter { $0.order != 0 } }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ProcessBox(name: main?.name ?? "Main process",
                       role: "Broker: opens files, talks to the network",
                       state: main?.stateLabel ?? "No sandbox",
                       sandboxed: main?.isSandboxed ?? false,
                       isMain: true)
                .frame(width: 200, height: rowHeight + 14)

            // main process -> bus
            VStack(spacing: 2) {
                Text("IPC")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.indigo)
                Rectangle().fill(Palette.indigo.opacity(0.6)).frame(height: 2)
                Color.clear.frame(height: 12)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: rowGap) {
                ForEach(helpers) { layer in
                    HStack(spacing: 0) {
                        Rectangle().fill(Palette.indigo.opacity(0.6)).frame(width: 18, height: 2)
                        Image(systemName: "arrowtriangle.right.fill")
                            .font(.system(size: 7))
                            .foregroundStyle(Palette.indigo.opacity(0.8))
                        ProcessBox(name: layer.name, role: layer.role,
                                   state: layer.unsandboxedByDesign ? byDesignLabel(layer) : layer.stateLabel,
                                   sandboxed: layer.isSandboxed, isMain: false,
                                   byDesign: layer.unsandboxedByDesign)
                            .frame(height: rowHeight)
                    }
                }
            }
            // the bus: a vertical line joining every helper's branch
            .overlay(alignment: .leading) {
                if helpers.count > 1 {
                    Rectangle()
                        .fill(Palette.indigo.opacity(0.6))
                        .frame(width: 2)
                        .padding(.vertical, rowHeight / 2)
                }
            }
        }
    }
}

private func byDesignLabel(_ layer: SandboxLayer) -> String {
    if case let .live(running, _) = layer.state { return "\(running) running · unsandboxed by design" }
    return "Unsandboxed by design"
}

/// One process in the diagram. The main process is dashed orange (open); a sandboxed helper
/// is solid indigo with a lock; a helper running without its sandbox is red.
struct ProcessBox: View {
    let name: String
    let role: String
    let state: String
    let sandboxed: Bool?
    let isMain: Bool
    /// Never sandboxed on purpose (the crash reporter): grey, not red.
    var byDesign = false

    private var tint: Color {
        if byDesign { return .secondary }
        if isMain { return sandboxed == true ? Palette.green : Palette.orange }
        switch sandboxed {
        case true?: return Palette.indigo
        case false?: return Palette.red
        case nil: return Palette.yellow
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isMain ? (sandboxed == true ? "lock.shield.fill" : "lock.open.fill")
                  : byDesign ? "lock.open" : (sandboxed == false ? "lock.open.fill" : "lock.fill"))
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.callout.weight(.semibold))
                Text(role).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                if isMain {
                    Text(state).font(.caption.weight(.medium)).foregroundStyle(tint)
                }
            }
            Spacer(minLength: 6)
            if !isMain {
                Text(state)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(tint)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(tint.opacity(0.08)))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(tint.opacity(0.85),
                              style: StrokeStyle(lineWidth: isMain ? 1.5 : 2, dash: isMain && sandboxed != true ? [6, 4] : []))
        )
    }
}
