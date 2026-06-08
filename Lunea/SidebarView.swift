import SwiftUI

struct SidebarView: View {
    @ObservedObject var state: AppState
    @State private var isHovered = false
    @Binding var selectedTab: ContentView.Tab
    @State private var isAccordionHovered = false
    @State private var isThemesExpanded = false
    
    
    // 🔥 BINDING BARU: Terhubung langsung ke ContentView
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
            
            // --- TOP HEADER: Window Controls & Collapse Button Side by Side ---
            HStack(spacing: 0) {
                if !isCollapsed {
                    HStack(spacing: 8) {
                        TLButton(color: Color(hex: "FF5F57"), icon: "xmark") { NSApplication.shared.terminate(nil) }
                        TLButton(color: Color(hex: "FFBD2E"), icon: "minus") { NSApplication.shared.windows.first?.miniaturize(nil) }
                        TLButton(color: Color(hex: "28C840"), icon: "arrow.up.left.and.arrow.down.right") { NSApplication.shared.windows.first?.zoom(nil) }
                    }
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                    Spacer()
                }

                // Tombol Icon Collapse (VisionOS style)
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isCollapsed.toggle()
                    }
                } label: {
                    Image(systemName: isCollapsed ? "sidebar.right" : "sidebar.left")
                        .font(.system(size: 13, weight: .bold))
                        // 🔥 Efek warna berubah saat hovered
                        .foregroundColor(isHovered ? .white : .white.opacity(0.6))
                        .frame(width: 32, height: 32)
                        // 🔥 Efek background lebih terang saat hovered
                        .background(Color.white.opacity(isHovered ? 0.15 : (isCollapsed ? 0.08 : 0)))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                // 🔥 Deteksi mouse masuk/keluar
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHovered = hovering
                    }
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 24)
            .padding(.horizontal, isCollapsed ? 0 : 20)
            .frame(width: isCollapsed ? 75 : 250)

            // --- MENU ITEMS SCROLLVIEW ---
            ScrollView(showsIndicators: false) {
                VStack(alignment: isCollapsed ? .center : .leading, spacing: 4) {
                    
                    if !isCollapsed {
                        SidebarSectionLabel(text: "Library")
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
                            action: { // 🔥 PENTING: Bungkus aksinya di dalam parameter 'action'
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    selectedTab = item.key
                                }
                                if item.key == .home {
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
                            action: { // 🔥 Pasang aksinya di dalam parameter action
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { selectedTab = item.key }
                            }
                        )
                    }
                }
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
                    .foregroundColor(.white.opacity(isAccordionHovered ? 1.0 : 0.7))
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isAccordionHovered ? Color.white.opacity(0.08) : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { isAccordionHovered = $0 }

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
            .padding(.bottom, 16)

            // --- BOTTOM USER PROFILE (Menciut jadi Avatar Bulat saja) ---
            Button {} label: {
                HStack(spacing: isCollapsed ? 0 : 12) {
                    if isCollapsed { Spacer() }
                    
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                    .frame(width: 28, height: 28)

                    if !isCollapsed {
                        Text("Paul")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.95))
                            .transition(.opacity)
                        Spacer()
                    } else {
                        Spacer()
                    }
                }
                .padding(.horizontal, isCollapsed ? 8 : 14)
                .padding(.vertical, isCollapsed ? 10 : 12)
                .glassEffect()
               
            }
            .buttonStyle(.plain)
            .padding(.horizontal, isCollapsed ? 10 : 16)
            .padding(.bottom, 16)
        }
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
    @State private var start = UnitPoint(x: 0, y: -0.5)
    @State private var end = UnitPoint(x: 1, y: 1.5)

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let angle = time.remainder(dividingBy: 5) * (Double.pi * 2) / 5
            
            // 🔥 Menggunakan palet khusus dari tema
            LinearGradient(
                colors: state.currentTheme.gradientColors,
                startPoint: start,
                endPoint: end
            )
            .hueRotation(.degrees(sin(angle) * 15)) // Perputaran warna yang lebih halus
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                    start = UnitPoint(x: 1, y: 0)
                    end = UnitPoint(x: 0, y: 1)
                }
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
                        .shadow(color: state.currentTheme.accentColor.opacity(0.3), radius: 6, y: 1)
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
