import SwiftUI

struct SidebarView: View {
    @ObservedObject var state: AppState
    @Binding var selectedTab: ContentView.Tab
    @State private var isThemesExpanded = false
    @Binding var isCollapsed: Bool

    private let menuItems: [(icon: String, label: String, key: ContentView.Tab)] = [
        ("house.fill", "Home", .home),
        ("safari.fill", "Explore", .explore),
        ("play.rectangle.fill", "Shorts", .shorts),
        ("play.tv.fill", "Subscribe", .subs),
    ]
    
    private let libraryItems: [(icon: String, label: String, key: ContentView.Tab)] = [
        ("clock.arrow.circlepath", "History", .history),
        ("clock.fill", "Watch Later", .watchlater),
        ("hand.thumbsup.fill", "Liked", .liked),
        ("list.bullet.rectangle.fill", "Playlist", .playlist),
    ]

    var body: some View {
        VStack(alignment: isCollapsed ? .center : .leading, spacing: 0) {
            if !isCollapsed {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR MEDIA SPACE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.32))
                    Text("Discover")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.94))
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 22)
                .transition(.opacity)
            } else {
                Capsule()
                    .fill(state.currentTheme.accentColor)
                    .frame(width: 24, height: 3)
                    .shadow(color: state.currentTheme.accentColor.opacity(0.55), radius: 8)
                    .frame(height: 40)
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: isCollapsed ? .center : .leading, spacing: 4) {
                    if !isCollapsed {
                        SidebarSectionLabel(text: "Browse")
                            .transition(.opacity)
                    } else {
                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 16).padding(.vertical, 8)
                    }
                    
                    ForEach(menuItems, id: \.key) { item in
                        SidebarRow(
                            state: state, icon: item.icon,
                            label: item.label,
                            isActive: selectedTab == item.key,
                            isCollapsed: isCollapsed,
                            action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    selectedTab = item.key
                                    state.clearSearch()
                                }
                                if state.isShowingPlayer {
                                    state.isPlayerMinimized = true
                                }
                                if item.key == .home || item.key == .explore {
                                    Task { await state.loadHome() }
                                }
                            }
                        )
                    }

                    Spacer().frame(height: 24)
                    if !isCollapsed {
                        SidebarSectionLabel(text: "My Collection")
                            .transition(.opacity)
                    } else {
                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 16).padding(.vertical, 8)
                    }
                    
                    ForEach(libraryItems, id: \.key) { item in
                        SidebarRow(
                            state: state, icon: item.icon,
                            label: item.label,
                            isActive: selectedTab == item.key,
                            isCollapsed: isCollapsed,
                            action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    selectedTab = item.key
                                    state.clearSearch()
                                }
                                if state.isShowingPlayer {
                                    state.isPlayerMinimized = true
                                }
                            }
                        )
                    }
                }
                .padding(.bottom, 12)
            }

            Spacer()

            VStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        isThemesExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 14))
                            .frame(width: 20)

                        if !isCollapsed {
                            Text("Themes")
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .rotationEffect(.degrees(isThemesExpanded ? 90 : 0))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .foregroundColor(.white.opacity(0.72))
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.035))
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isThemesExpanded {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(availableThemes, id: \.name) { theme in
                            ThemeButton(theme: theme, state: state, isCollapsed: isCollapsed)
                        }
                    }
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, isCollapsed ? 8 : 12)
            .padding(.bottom, 10)

            Button { state.showApiKeySheet = true } label: {
                HStack(spacing: 11) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(state.currentTheme.accentColor)
                        .frame(width: 30, height: 30)
                        .background(state.currentTheme.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
                    if !isCollapsed {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("YouTube API")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                            Text(state.apiKey.isEmpty ? "Not connected" : "Connected")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        Spacer()
                        Circle()
                            .fill(state.apiKey.isEmpty ? Color.orange : Color.green)
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.6)
                }
            }
            .buttonStyle(.plain)
            .help("Configure YouTube API key")
            .padding(.horizontal, isCollapsed ? 14 : 16)
            .padding(.bottom, 18)
        }
        .background(Color.white.opacity(0.025))
    }
}
// MARK: - Tombol Tema Mandiri (Anti-Bug Hover & Klik Seluruh Area)

struct ThemeButton: View {
    let theme: AppTheme
    @ObservedObject var state: AppState
    let isCollapsed: Bool
    @State private var isHovered = false

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                state.changeTheme(to: theme)
            }
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(theme.accentColor)
                    .frame(width: 8, height: 8)
                
                if !isCollapsed {
                    Text(theme.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(isHovered ? 1.0 : 0.8))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            // Mengatur alignment saat sidebar menciut atau memanjang
            .frame(maxWidth: .infinity, alignment: isCollapsed ? .center : .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(state.currentTheme.name == theme.name ? Color.white.opacity(0.15) : (isHovered ? Color.white.opacity(0.07) : Color.clear))
            )
            .contentShape(Rectangle()) // 🔥 Memaksa area kosong di kanan teks tetap bisa diklik
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
struct ThemeBackground: View {
    @ObservedObject var state: AppState

    var body: some View {
        LinearGradient(
            colors: state.currentTheme.gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            RadialGradient(
                colors: [state.currentTheme.accentColor.opacity(0.13), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 620
            )
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.25), value: state.currentTheme.name)
    }
}

/// Lightweight theme-driven ambience. It animates only gradient transforms,
/// avoiding image decoding and full-window blur during scrolling.
struct AmbientVideoBackdrop: View {
    @ObservedObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimated = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let secondary = state.currentTheme.gradientColors.last ?? state.currentTheme.accentColor

            ZStack {
                LinearGradient(
                    colors: [
                        state.currentTheme.backgroundColor,
                        state.currentTheme.gradientColors.dropFirst().first ?? state.currentTheme.backgroundColor,
                        Color.black.opacity(0.92)
                    ],
                    startPoint: isAnimated ? .topTrailing : .topLeading,
                    endPoint: isAnimated ? .bottomLeading : .bottomTrailing
                )

                RadialGradient(
                    colors: [state.currentTheme.accentColor.opacity(0.48), .clear],
                    center: isAnimated
                        ? UnitPoint(x: 0.76, y: 0.22)
                        : UnitPoint(x: 0.20, y: 0.72),
                    startRadius: 0,
                    endRadius: max(width, height) * 0.72
                )
                .frame(width: width, height: height)

                RadialGradient(
                    colors: [secondary.opacity(0.38), .clear],
                    center: isAnimated
                        ? UnitPoint(x: 0.22, y: 0.76)
                        : UnitPoint(x: 0.80, y: 0.24),
                    startRadius: 0,
                    endRadius: max(width, height) * 0.66
                )
                .frame(width: width, height: height)

                LinearGradient(
                    colors: [Color.white.opacity(0.035), .clear, Color.black.opacity(0.24)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // A subtle vignette keeps text readable without flattening the colors.
                ZStack {
                    Color.black.opacity(0.08)
                    RadialGradient(
                        colors: [.clear, Color.black.opacity(0.30)],
                        center: .center,
                        startRadius: min(width, height) * 0.20,
                        endRadius: max(width, height) * 0.76
                    )
                }
            }
            .frame(width: width, height: height)
            .clipped()
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.55), value: state.currentTheme.name)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                isAnimated = true
            }
        }
    }
}

struct SidebarSectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(1.2) // Spasi antar huruf biar elegan
            .foregroundColor(.white.opacity(0.4))
            .padding(.leading, 24)
            .padding(.bottom, 4)
            .padding(.top, 12)
    }
}

// MARK: - Sidebar Row Component (Responsive Width)

struct SidebarRow: View {
    @ObservedObject var state: AppState
    let icon: String
    let label: String
    let isActive: Bool
    let isCollapsed: Bool
    let action: () -> Void // 🔥 1. Deklarasikan parameter action di sini

    @State private var isHovered = false

    var body: some View {
        // 🔥 2. Gunakan 'action' di dalam Button
        Button(action: action) {
            HStack(spacing: 0) {
                if isCollapsed { Spacer() }
                
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .frame(width: 20)
                
                if !isCollapsed {
                    Text(label)
                        .font(.system(size: 14, weight: isActive ? .bold : .medium))
                        .padding(.leading, 12)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    Spacer()
                } else {
                    Spacer()
                }
            }
            .padding(.horizontal, isCollapsed ? 10 : 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .foregroundColor(isActive ? .white : (isHovered ? .white : .white.opacity(0.65)))
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(state.currentTheme.accentColor)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, isCollapsed ? 8 : 12)
        .onHover { isHovered = $0 }
    }
}
