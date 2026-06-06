import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: ContentView.Tab
    @ObservedObject var state: AppState

    private let menuItems: [(icon: String, label: String, key: ContentView.Tab)] = [
        ("house.fill", "Beranda", .home),
        ("safari.fill", "Jelajahi", .explore),
        ("play.rectangle.fill", "Shorts", .shorts),
        ("play.tv.fill", "Langganan", .subs),
    ]
    
    private let libraryItems: [(icon: String, label: String, key: ContentView.Tab)] = [
        ("clock.arrow.circlepath", "Riwayat", .history),
        ("clock.fill", "Tonton Nanti", .watchlater),
        ("hand.thumbsup.fill", "Disukai", .liked),
        ("list.bullet.rectangle.fill", "Playlist", .playlist),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Area Window Controls (Traffic Lights) di integrasi ke sudut Sidebar
            HStack(spacing: 8) {
                TLButton(color: Color(hex: "FF5F57"), icon: "xmark") { NSApplication.shared.terminate(nil) }
                TLButton(color: Color(hex: "FFBD2E"), icon: "minus") { NSApplication.shared.windows.first?.miniaturize(nil) }
                TLButton(color: Color(hex: "28C840"), icon: "arrow.up.left.and.arrow.down.right") { NSApplication.shared.windows.first?.zoom(nil) }
            }
            .padding(.top, 24)
            .padding(.leading, 20)
            .padding(.bottom, 24)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    
                    SidebarSectionLabel(text: "Library")
                    ForEach(menuItems, id: \.key) { item in
                        SidebarRow(icon: item.icon, label: item.label, isActive: selectedTab == item.key) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { selectedTab = item.key }
                            if item.key == .home { Task { await state.loadHome() } }
                        }
                    }

                    Spacer().frame(height: 24)
                    
                    SidebarSectionLabel(text: "Koleksi Saya")
                    ForEach(libraryItems, id: \.key) { item in
                        SidebarRow(icon: item.icon, label: item.label, isActive: selectedTab == item.key) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { selectedTab = item.key }
                        }
                    }
                }
            }

            Spacer()

            // Bottom Profile Area (Hanya User Profil)
            Button {} label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)

                    Text("Paul")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.05)) // Elegan touch area
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

struct SidebarSectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white.opacity(0.4))
            .padding(.horizontal, 24).padding(.bottom, 6).padding(.top, 8)
    }
}
struct SidebarRow: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .frame(width: 20)
                Text(label)
                    .font(.system(size: 14, weight: isActive ? .bold : .medium))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle()) // KUNCI 1: Hitbox selebar kapsul penuh
            .foregroundColor(isActive ? .white : (isHovered ? .white : .white.opacity(0.65)))
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "FA2E5B"))
                        .shadow(color: Color(hex: "FA2E5B").opacity(0.4), radius: 8, y: 2)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .onHover { isHovered = $0 }
    }
}
