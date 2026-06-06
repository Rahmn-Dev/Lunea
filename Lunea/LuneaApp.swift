import SwiftUI

@main
struct WatchTubeApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1300, height: 840)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appInfo) {}
        }
    }
}

// RootView removes ALL native chrome
struct RootView: View {
    var body: some View {
        ContentView()
            .ignoresSafeArea()
            .onAppear {
                // Remove native title bar & set window properties
                DispatchQueue.main.async {
                    guard let window = NSApplication.shared.windows.first else { return }
                    window.titleVisibility = .hidden
                    window.titlebarAppearsTransparent = true
                    window.isMovableByWindowBackground = true
                    window.styleMask.insert(.fullSizeContentView)
                    window.styleMask.remove(.titled)
                    window.styleMask.insert(.borderless)
                    window.backgroundColor = .clear
                    window.isOpaque = false
                    window.hasShadow = true
                    // Re-add close/min/max but hidden — keeps keyboard shortcuts
                    window.standardWindowButton(.closeButton)?.isHidden = true
                    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                    window.standardWindowButton(.zoomButton)?.isHidden = true
                }
            }
    }
}
