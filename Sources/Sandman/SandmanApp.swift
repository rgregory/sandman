import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Lets the app come forward even when launched unbundled via `swift run`.
        NSApp.setActivationPolicy(.regular)
        // Set the Dock icon from our own bundle. When Launch Services hasn't caught up with
        // the bundle (after the rename, or when run unbundled) the Dock otherwise shows the
        // generic "exec" icon.
        if let path = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let icon = NSImage(contentsOfFile: path) {
            NSApp.applicationIconImage = icon
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct SandmanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = AppStore()
    @StateObject private var seatbelts = SeatbeltStore()
    @StateObject private var telemetry = TelemetryStore()
    @AppStorage(AppTheme.storageKey) private var theme = AppTheme.standard

    init() {
        LegacyMigration.run()
    }

    var body: some Scene {
        Window("Sandman", id: "main") {
            ContentView()
                .environmentObject(store)
                .environmentObject(seatbelts)
                .environmentObject(telemetry)
                .frame(minWidth: 920, minHeight: 540)
        }
        .defaultSize(width: 1180, height: 720)
        .commands {
            CommandGroup(after: .toolbar) {
                Picker("Theme", selection: $theme) {
                    // Sandman's own looks first, then the ones ThemeMonkey draws.
                    ForEach(AppTheme.allCases.filter { !$0.isMonkey }) { theme in
                        Text(theme.label).tag(theme)
                    }
                    Divider()
                    ForEach(AppTheme.allCases.filter(\.isMonkey)) { theme in
                        Text(theme.label).tag(theme)
                    }
                }
            }
            CommandGroup(replacing: .newItem) {
                Button("Rescan Applications") { store.scan() }
                    .keyboardShortcut("r", modifiers: .command)
                    .disabled(store.isScanning)
            }
        }
    }
}
