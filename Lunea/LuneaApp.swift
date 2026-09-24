import SwiftUI

@main
struct LuneaApp: App {
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

struct RootView: View {
    var body: some View {
        ContentView()
            .ignoresSafeArea()
            .onAppear {
                DispatchQueue.main.async {
                    guard let window = NSApplication.shared.windows.first else { return }
                    window.titleVisibility = .hidden
                    window.titlebarAppearsTransparent = true
                    window.isMovableByWindowBackground = true
                    window.styleMask.insert(.fullSizeContentView)
                    window.backgroundColor = .clear
                    window.isOpaque = false
                    window.hasShadow = true
                    window.standardWindowButton(.closeButton)?.isHidden = true
                    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                    window.standardWindowButton(.zoomButton)?.isHidden = true
                    window.collectionBehavior = [.fullScreenPrimary, .managed]
                }
            }
            // ✅ Escape key untuk exit video fullscreen
            .onKeyPress(.escape) {
                NotificationCenter.default.post(name: .exitVideoFullscreen, object: nil)
                return .ignored
            }
    }
}

extension Notification.Name {
    static let exitVideoFullscreen = Notification.Name("exitVideoFullscreen")
    static let toggleVideoFullscreen = Notification.Name("toggleVideoFullscreen")
}
