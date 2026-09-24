import SwiftUI
import Combine
import AppKit

// MARK: - Root

struct GlassCapsule: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.35),
                                .white.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
    }
}

extension View {
    func glassCapsule() -> some View {
        modifier(GlassCapsule())
    }
}

struct ContentView: View {
    @StateObject private var state = AppState()
    @State private var selectedTab: Tab = .home
    @State private var isSidebarCollapsed = true
    @State private var isVideoFullscreen = false

    enum Tab: String, Equatable {
        case home, explore, shorts, subs
        case history, watchlater, liked, playlist
    }

    var body: some View {
        ZStack {
            AmbientVideoBackdrop(state: state)

            VStack(spacing: 0) {
                if !isVideoFullscreen {
                    WindowTitleBar(
                        state: state,
                        isSidebarCollapsed: $isSidebarCollapsed
                    )
                    .frame(height: 58)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                HStack(spacing: 0) {
                    if !isVideoFullscreen {
                        SidebarView(
                            state: state,
                            selectedTab: $selectedTab,
                            isCollapsed: $isSidebarCollapsed
                        )
                        .frame(width: isSidebarCollapsed ? 76 : 228)
                        .background(Color.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.7)
                        }
                        .padding(.leading, 14)
                        .padding(.trailing, 10)
                        .padding(.bottom, 14)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    workspaceContent
                    .background(Color.black.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: isVideoFullscreen ? 0 : 22, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.11), lineWidth: 0.7)
                    }
                    .padding(.trailing, isVideoFullscreen ? 0 : 14)
                    .padding(.bottom, isVideoFullscreen ? 0 : 14)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleVideoFullscreen)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isVideoFullscreen.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .exitVideoFullscreen)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isVideoFullscreen = false
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: isSidebarCollapsed)
        .frame(minWidth: 980, minHeight: 680)
        .sheet(isPresented: $state.showApiKeySheet) { ApiKeySheet(state: state) }
        .task { await state.loadHome() }
    }

    @ViewBuilder
    private var workspaceContent: some View {
        ZStack {
            Group {
                if state.isSearchActive {
                    SearchResultsView(state: state)
                } else {
                    HomeView(state: state, selectedTab: selectedTab)
                }
            }
            .transition(.opacity)

            if state.isShowingPlayer, let videoId = state.selectedVideoId {
                FloatingPlayerOverlay(videoId: videoId)
                    .environmentObject(state)
                    .id(videoId)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: state.isShowingPlayer)
        .animation(.easeInOut(duration: 0.22), value: state.isSearchActive)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Window chrome and search

struct WindowTitleBar: View {
    @ObservedObject var state: AppState
    @Binding var isSidebarCollapsed: Bool
    @FocusState private var isSearchFocused: Bool
    @State private var isSearchHovered = false

    var body: some View {
        ZStack {
            WindowDragArea()

            HStack(spacing: 14) {
                HStack(spacing: 8) {
                    TLButton(color: Color(hex: "FF5F57"), icon: "xmark") { NSApp.terminate(nil) }
                    TLButton(color: Color(hex: "FFBD2E"), icon: "minus") { NSApp.keyWindow?.miniaturize(nil) }
                    TLButton(color: Color(hex: "28C840"), icon: "plus") { NSApp.keyWindow?.zoom(nil) }
                }
                .frame(width: 72)

                Button {
                    isSidebarCollapsed.toggle()
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .help(isSidebarCollapsed ? "Show sidebar" : "Hide sidebar")

                HStack(spacing: 8) {
                    Image("LuneaMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 27, height: 27)
                        .shadow(color: Color(hex: "E7B94A").opacity(0.32), radius: 7, y: 2)
                    Text("Lunea")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .tracking(0.25)
                        .foregroundStyle(.white.opacity(0.94))
                }
                .padding(.leading, 8)
                .padding(.trailing, 13)
                .frame(height: 38)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(Color.white.opacity(0.035), in: Capsule())
                }
                .overlay {
                    Capsule().strokeBorder(
                        LinearGradient(
                            colors: [Color(hex: "F6D77A").opacity(0.30), .white.opacity(0.07)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
                }
                .shadow(color: Color.black.opacity(0.18), radius: 10, y: 4)

                Spacer(minLength: 18)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(
                            isSearchFocused
                                ? state.currentTheme.accentColor
                                : (isSearchHovered ? Color.primary : Color.secondary)
                        )

                    TextField("Search videos, music, or channels", text: $state.searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .medium))
                        .focused($isSearchFocused)
                        .onSubmit { Task { await state.search() } }

                    if !state.searchQuery.isEmpty {
                        Button {
                            state.searchQuery = ""
                            isSearchFocused = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(isSearchHovered ? Color.primary : Color.secondary)
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 14)
                .frame(width: isSearchFocused ? 460 : 360, height: 36)
                .contentShape(Capsule())
                .onTapGesture { isSearchFocused = true }
                .background(Color.white.opacity(isSearchFocused ? 0.13 : (isSearchHovered ? 0.10 : 0.07)), in: Capsule())
                .overlay {
                    Capsule().strokeBorder(
                        isSearchFocused ? state.currentTheme.accentColor.opacity(0.65) : Color.white.opacity(0.1),
                        lineWidth: 0.8
                    )
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSearchFocused)
                .onHover { isSearchHovered = $0 }

                if state.isShowingPlayer {
                    HStack(spacing: 7) {
                        SearchBarButton(icon: state.isPlayerMinimized ? "arrow.up.left.and.arrow.down.right" : "chevron.down") {
                            state.isPlayerMinimized.toggle()
                        }
                        .help(state.isPlayerMinimized ? "Expand player" : "Minimize player")

                        SearchBarButton(icon: "xmark") {
                            withAnimation(.easeInOut(duration: 0.2)) { state.closePlayer() }
                        }
                        .help("Close player")
                    }
                } else if state.isSearchActive {
                    SearchBarButton(icon: "arrow.uturn.backward") {
                        state.clearSearch()
                    }
                    .help("Back")
                } else {
                    Color.clear.frame(width: 38, height: 38)
                }

                Spacer(minLength: 18)

                HStack(spacing: 9) {
                    TitleBarGlassButton(
                        icon: "bell.fill",
                        help: "Notifications",
                        accent: state.currentTheme.accentColor,
                        showsBadge: true
                    ) { }

                    TitleBarGlassButton(
                        icon: "person.fill",
                        help: "Profile",
                        accent: state.currentTheme.accentColor,
                        isProfile: true
                    ) { }
                }
                .frame(width: 92, alignment: .trailing)
            }
            .padding(.horizontal, 18)
        }
        .environment(\.colorScheme, .dark)
    }
}

struct TitleBarGlassButton: View {
    let icon: String
    let help: String
    let accent: Color
    var showsBadge = false
    var isProfile = false
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(isProfile ? accent.opacity(0.20) : Color.white.opacity(isHovered ? 0.13 : 0.075))
                    .overlay {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .opacity(isProfile ? 0.26 : 0.42)
                    }
                    .overlay {
                        Circle().strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.28), .white.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                    }
                    .shadow(color: accent.opacity(isHovered ? 0.20 : 0.07), radius: 10, y: 3)

                Image(systemName: icon)
                    .font(.system(size: isProfile ? 15 : 14, weight: .semibold))
                    .foregroundStyle(isProfile ? accent : Color.white.opacity(isHovered ? 0.96 : 0.78))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if showsBadge {
                    Circle()
                        .fill(accent)
                        .frame(width: 7, height: 7)
                        .overlay { Circle().stroke(Color.black.opacity(0.55), lineWidth: 1) }
                        .offset(x: -1, y: 1)
                }
            }
            .frame(width: isProfile ? 38 : 36, height: isProfile ? 38 : 36)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.055 : 1)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
        .help(help)
    }
}

struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DraggableView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DraggableView: NSView {
        override func mouseDown(with event: NSEvent) {
            if event.clickCount == 2 {
                window?.zoom(nil)
            } else {
                window?.performDrag(with: event)
            }
        }
    }
}

// MARK: - Category Bar (floating, liquid glass pills)

// MARK: - Category Chip (satu pill, punya hover sendiri)

struct CategoryChip: View {
    @ObservedObject var state: AppState
    let cat: String
    @State private var isHovered = false

    var isSelected: Bool { state.selectedCategory == cat }

    var body: some View {
        // ✅ Button di luar glassEffect — hit area = seluruh capsule, bukan cuma teks
        Button {
            state.selectedCategory = cat
            Task { await state.loadHome() }
        } label: {
            Text(cat)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(
                    isSelected
                        ? Color.black.opacity(0.86)
                        : (isHovered ? Color.white : Color.white.opacity(0.74))
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                // ✅ contentShape Capsule = seluruh area pill bisa diklik & di-hover
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .background(
            isSelected
                ? Color.white.opacity(0.94)
                : (isHovered ? state.currentTheme.accentColor.opacity(0.24) : Color.white.opacity(0.075)),
            in: Capsule()
        )
        .overlay {
            Capsule().strokeBorder(
                isSelected ? Color.white.opacity(0.75) : Color.white.opacity(isHovered ? 0.24 : 0.12),
                lineWidth: 0.7
            )
        }
        .shadow(
            color: isSelected ? Color.white.opacity(0.13) : state.currentTheme.accentColor.opacity(isHovered ? 0.18 : 0),
            radius: 10
        )
        .scaleEffect(isHovered && !isSelected ? 1.035 : 1)
        .animation(.easeOut(duration: 0.14), value: isHovered)
        .animation(.easeOut(duration: 0.18), value: isSelected)
        .onHover { hovered in
            isHovered = hovered
            if hovered { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}

struct CategoryBar: View {
    @ObservedObject var state: AppState

    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(state.categories, id: \.self) { cat in
                        CategoryChip(state: state, cat: cat)
                    }
                }
                .frame(minWidth: geo.size.width, alignment: .center)
            }
        }
        .frame(height: 44)
    }
}

// MARK: - Search Bar Button

struct SearchBarButton: View {
    let icon: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isHovered ? Color.primary : Color.secondary)
                .frame(width: 38, height: 38)
                // ✅ contentShape = hit area penuh circle, bukan cuma ikon
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .background(Color.white.opacity(isHovered ? 0.12 : 0.06), in: Circle())
        .overlay { Circle().strokeBorder(Color.white.opacity(0.09), lineWidth: 0.6) }
        .onHover { hovered in
            isHovered = hovered
            if hovered { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}

// MARK: - Traffic Light Button

struct TLButton: View {
    let color: Color
    let icon: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(color).frame(width: 12, height: 12)
                    .shadow(color: color.opacity(0.4), radius: 3)
                if isHovered {
                    Image(systemName: icon).font(.system(size: 6, weight: .black)).foregroundColor(.black.opacity(0.6))
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct HeaderButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
    }
}

// MARK: - Home View
// Kategori DIHAPUS dari sini karena sudah floating di atas

struct HomeView: View {
    @ObservedObject var state: AppState
    let selectedTab: ContentView.Tab
    @State private var currentHeroIndex = 0
    @State private var featureWidth: CGFloat = 0
    private let heroTimer = Timer.publish(every: 6, on: .main, in: .common).autoconnect()

    private var fourColumnGrid: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)
    }

    private var heroVideos: [YouTubeVideoDetail] {
        Array(state.trendingVideos.prefix(5))
    }

    private var currentHero: YouTubeVideoDetail? {
        guard !heroVideos.isEmpty else { return nil }
        return heroVideos[currentHeroIndex % heroVideos.count]
    }

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                homeDashboard
            case .explore:
                videoGrid(title: "Explore", icon: "safari.fill", videos: state.trendingVideos)
            case .shorts:
                videoGrid(
                    title: "Shorts",
                    subtitle: "Quick videos under three minutes",
                    icon: "play.rectangle.fill",
                    videos: shortVideos
                )
            case .subs:
                CollectionEmptyState(
                    icon: "play.tv.fill",
                    title: "Subscriptions",
                    message: "Connect your YouTube account to see videos from channels you follow."
                )
            case .history:
                CollectionEmptyState(icon: "clock.arrow.circlepath", title: "History", message: "Videos you finish watching will appear here.")
            case .watchlater:
                CollectionEmptyState(icon: "clock.fill", title: "Watch Later", message: "Save videos from the player to watch them later.")
            case .liked:
                CollectionEmptyState(icon: "hand.thumbsup.fill", title: "Liked Videos", message: "Videos you like will be collected here.")
            case .playlist:
                CollectionEmptyState(icon: "list.bullet.rectangle.fill", title: "Playlists", message: "Your playlist collections will appear here.")
            }
        }
        .overlay {
            if state.isLoading && state.trendingVideos.isEmpty {
                ProgressView("Loading videos…")
                    .tint(state.currentTheme.accentColor)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private var homeDashboard: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if !state.trendingVideos.isEmpty {
                    featureArea
                }

                CategoryBar(state: state)

                if state.trendingVideos.count > 4 {
                    SectionHeader(icon: "sparkles", title: "For you")
                    LazyVGrid(columns: fourColumnGrid, spacing: 18) {
                        ForEach(state.trendingVideos.dropFirst(4)) { video in
                            VideoCard(
                                state: state, video: video,
                                action: { Task { await state.selectVideo(video.id) } }
                            )
                        }
                    }
                }

                if !shortVideos.isEmpty {
                    SectionHeader(icon: "bolt.fill", title: "Shorts")
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: 12) {
                            ForEach(shortVideos.prefix(8)) { video in
                                ShortVideoCard(state: state, video: video)
                            }
                        }
                    }
                }

                paginationFooter
            }
            .padding(24)
        }
        .onChange(of: state.selectedCategory) { _, _ in currentHeroIndex = 0 }
    }

    private var featureArea: some View {
        GeometryReader { geo in
            let isWide = geo.size.width >= 760
            let quickWidth: CGFloat = 310
            let heroWidth = max(0, geo.size.width - quickWidth - 14)

            if isWide {
                HStack(alignment: .top, spacing: 14) {
                    heroCarousel
                        .frame(width: heroWidth, height: 382)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    quickPicksPanel
                        .frame(width: quickWidth, height: 382)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .frame(width: geo.size.width, height: 382, alignment: .topLeading)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    heroCarousel
                        .frame(width: geo.size.width, height: 382)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    quickPicksPanel
                        .frame(width: geo.size.width, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .frame(width: geo.size.width, height: 696, alignment: .topLeading)
            }
        }
        .frame(height: featureWidth >= 760 ? 382 : 696, alignment: .top)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            if abs(featureWidth - width) > 1 { featureWidth = width }
        }
        .animation(.easeInOut(duration: 0.3), value: currentHeroIndex)
        .onReceive(heroTimer) { _ in
            guard heroVideos.count > 1 else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                currentHeroIndex = (currentHeroIndex + 1) % heroVideos.count
            }
        }
    }

    private var heroCarousel: some View {
        ZStack(alignment: .bottom) {
            if let video = currentHero {
                HeroFeaturedCard(
                    state: state,
                    video: video,
                    action: { Task { await state.selectVideo(video.id) } }
                )
                .id(video.id)
                .transition(.opacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            HStack(spacing: 6) {
                ForEach(heroVideos.indices, id: \.self) { index in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) { currentHeroIndex = index }
                    } label: {
                        Capsule()
                            .fill(index == currentHeroIndex ? Color.white : Color.white.opacity(0.35))
                            .frame(width: index == currentHeroIndex ? 28 : 10, height: 5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.black.opacity(0.44), in: Capsule())
            .padding(.bottom, 14)
            .zIndex(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var quickPicksPanel: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("Quick picks")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.35))
            }

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(state.trendingVideos.dropFirst()) { video in
                        CompactVideoRow(state: state, video: video)
                    }

                    if let token = state.nextPageToken {
                        ProgressView()
                            .controlSize(.small)
                            .tint(state.currentTheme.accentColor)
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .id("quick-\(token)")
                            .onAppear { Task { await state.loadMore() } }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.09), lineWidth: 0.6)
        }
    }

    private var shortVideos: [YouTubeVideoDetail] {
        let filtered = state.trendingVideos.filter {
            guard let seconds = $0.contentDetails?.durationSeconds else { return false }
            return seconds > 0 && seconds <= 180
        }
        return filtered.isEmpty ? state.trendingVideos : filtered
    }

    private func videoGrid(
        title: String,
        subtitle: String = "Browse what is popular right now",
        icon: String,
        videos: [YouTubeVideoDetail]
    ) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                FeedSummaryHeader(
                    category: title,
                    subtitle: subtitle,
                    videoCount: videos.count,
                    accent: state.currentTheme.accentColor,
                    icon: icon
                )
                LazyVGrid(columns: fourColumnGrid, spacing: 18) {
                    ForEach(videos) { video in
                        VideoCard(state: state, video: video) {
                            Task { await state.selectVideo(video.id) }
                        }
                    }
                }
                paginationFooter
            }
            .padding(24)
        }
    }

    @ViewBuilder
    private var paginationFooter: some View {
        if let token = state.nextPageToken {
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Loading more…")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .frame(height: 44)
                Spacer()
            }
            .id(token)
            .onAppear { Task { await state.loadMore() } }
        }
    }
}

struct FeedSummaryHeader: View {
    let category: String
    var subtitle: String? = nil
    let videoCount: Int
    let accent: Color
    var icon: String = "sparkles"

    private var detail: String {
        if let subtitle { return subtitle }
        return category == "All"
            ? "A fresh mix of trending videos across every category"
            : "Popular \(category.lowercased()) videos, updated for you"
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 42, height: 42)
                .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 3) {
                Text(category == "All" ? "For You" : category)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.94))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.42))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(videoCount)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
                Text("VIDEOS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 4)
    }
}

struct CollectionEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.white.opacity(0.28))
                .frame(width: 72, height: 72)
                .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20))
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.42))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 330)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

// MARK: - Search Results

struct SearchResultsView: View {
    @ObservedObject var state: AppState
    @State private var uploadDate: SearchUploadDate = .any
    @State private var resultType: SearchResultType = .all
    @State private var duration: SearchDuration = .any
    @State private var feature: SearchFeature = .all
    @State private var sort: SearchSort = .relevance

    private var filteredResults: [YouTubeVideoDetail] {
        var results = state.searchResultDetails

        if let days = uploadDate.days,
           let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) {
            results = results.filter {
                guard let value = $0.snippet?.publishedAt,
                      let date = ISO8601DateFormatter().date(from: value) else { return false }
                return date >= cutoff
            }
        }

        switch resultType {
        case .all: break
        case .videos: results = results.filter { ($0.contentDetails?.durationSeconds ?? 0) > 180 }
        case .shorts: results = results.filter { (1...180).contains($0.contentDetails?.durationSeconds ?? 0) }
        }

        switch duration {
        case .any: break
        case .underFour: results = results.filter { (1..<240).contains($0.contentDetails?.durationSeconds ?? 0) }
        case .medium: results = results.filter { (240...1200).contains($0.contentDetails?.durationSeconds ?? 0) }
        case .long: results = results.filter { ($0.contentDetails?.durationSeconds ?? 0) > 1200 }
        }

        switch feature {
        case .all: break
        case .hd: results = results.filter { $0.contentDetails?.definition == "hd" }
        case .live: results = results.filter { $0.snippet?.liveBroadcastContent == "live" }
        }

        switch sort {
        case .relevance: break
        case .uploadDate:
            results.sort { ($0.snippet?.publishedAt ?? "") > ($1.snippet?.publishedAt ?? "") }
        case .viewCount:
            results.sort { Int($0.statistics?.viewCount ?? "0") ?? 0 > Int($1.statistics?.viewCount ?? "0") ?? 0 }
        case .rating:
            results.sort { Int($0.statistics?.likeCount ?? "0") ?? 0 > Int($1.statistics?.likeCount ?? "0") ?? 0 }
        }
        return results
    }

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Search results")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.94))
                            Text("\(filteredResults.count) results for “\(state.searchQuery)”")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.42))
                        }
                        Spacer()
                    }
                    .padding(.bottom, 8)

                    if state.isSearching {
                        HStack { Spacer(); ProgressView().tint(state.currentTheme.accentColor); Spacer() }
                            .padding(.top, 80)
                    } else if let err = state.errorMessage {
                        ErrorView(state: state, message: err) { Task { await state.search() } }
                    } else if filteredResults.isEmpty {
                        HStack { Spacer(); Text("No videos match these filters.").font(.system(size: 13)).foregroundStyle(.white.opacity(0.45)); Spacer() }
                            .padding(.top, 60)
                    } else {
                        ForEach(filteredResults) { video in
                            SearchDetailResultCard(state: state, video: video)
                        }

                        if let token = state.searchNextPageToken {
                            HStack(spacing: 8) {
                                ProgressView().controlSize(.small)
                                Text(state.isLoadingMoreSearch ? "Loading more results…" : "More results")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.42))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .id("search-\(token)")
                            .onAppear { Task { await state.loadMoreSearch() } }
                        }
                    }

                    Spacer(minLength: 30)
                }
                .padding(22)
            }

            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 0.6)

            SearchFiltersPanel(
                accent: state.currentTheme.accentColor,
                uploadDate: $uploadDate,
                resultType: $resultType,
                duration: $duration,
                feature: $feature,
                sort: $sort
            )
            .frame(width: 258)
        }
    }
}

enum SearchUploadDate: String, CaseIterable {
    case any = "Any time", today = "Today", week = "This week", month = "This month", year = "This year"
    var days: Int? {
        switch self { case .any: nil; case .today: 1; case .week: 7; case .month: 30; case .year: 365 }
    }
}

enum SearchResultType: String, CaseIterable {
    case all = "All", videos = "Videos", shorts = "Shorts"
}

enum SearchDuration: String, CaseIterable {
    case any = "Any length", underFour = "Under 4 min", medium = "4–20 min", long = "Over 20 min"
}

enum SearchFeature: String, CaseIterable {
    case all = "All", hd = "HD", live = "Live"
}

enum SearchSort: String, CaseIterable {
    case relevance = "Relevance", uploadDate = "Upload date", viewCount = "View count", rating = "Rating"
}

struct SearchFiltersPanel: View {
    let accent: Color
    @Binding var uploadDate: SearchUploadDate
    @Binding var resultType: SearchResultType
    @Binding var duration: SearchDuration
    @Binding var feature: SearchFeature
    @Binding var sort: SearchSort

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Label("Search filters", systemImage: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))

                filterSection("Upload date", values: SearchUploadDate.allCases, selection: $uploadDate)
                filterSection("Type", values: SearchResultType.allCases, selection: $resultType)
                filterSection("Duration", values: SearchDuration.allCases, selection: $duration)
                filterSection("Features", values: SearchFeature.allCases, selection: $feature)
                filterSection("Sort by", values: SearchSort.allCases, selection: $sort)
            }
            .padding(18)
        }
        .background(Color.white.opacity(0.035))
    }

    private func filterSection<Value: RawRepresentable & CaseIterable & Hashable>(
        _ title: String,
        values: Value.AllCases,
        selection: Binding<Value>
    ) -> some View where Value.RawValue == String, Value.AllCases: RandomAccessCollection {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))

            FlowLayout(spacing: 7) {
                ForEach(Array(values), id: \.self) { value in
                    FilterChip(
                        title: value.rawValue,
                        isSelected: selection.wrappedValue == value,
                        accent: accent
                    ) { selection.wrappedValue = value }
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10.5, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 11)
                .frame(height: 30)
                .background(isSelected ? accent.opacity(0.34) : Color.white.opacity(0.055), in: Capsule())
                .overlay { Capsule().strokeBorder(isSelected ? accent.opacity(0.6) : Color.white.opacity(0.09), lineWidth: 0.6) }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Error

struct ErrorView: View {
    @ObservedObject var state: AppState
    let message: String; let retry: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 36)).foregroundColor(Color(hex: "FFBD2E"))
            Text(message).font(.system(size: 13)).foregroundColor(.white.opacity(0.55)).multilineTextAlignment(.center)
            Button("Try Again", action: retry)
                .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                .padding(.horizontal, 20).padding(.vertical, 9)
                .background(state.currentTheme.accentColor).clipShape(Capsule()).buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
    }
}

// MARK: - API Key Sheet

struct ApiKeySheet: View {
    @ObservedObject var state: AppState
    @State private var input = ""

    var body: some View {
        VStack(spacing: 24) {
            YouTubeLogo(size: 32)
            VStack(spacing: 6) {
                Text("YouTube API Key")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(.white.opacity(0.95))
                Text("console.cloud.google.com → YouTube Data API v3")
                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.4)).multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("API KEY").font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.white.opacity(0.3))
                SecureField("AIzaSy...", text: $input)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced)).foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.08))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.8)
                            }
                    }
            }
            .frame(width: 340)

            Button {
                guard !input.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                state.saveApiKey(input.trimmingCharacters(in: .whitespaces))
            } label: {
                Text("Save & Continue")
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .frame(width: 180, height: 42)
                    .background(state.currentTheme.accentColor).clipShape(Capsule())
                    .shadow(color: state.currentTheme.accentColor.opacity(0.4), radius: 12)
            }
            .buttonStyle(.plain).disabled(input.isEmpty)

            Link("How to get an API key →",
                 destination: URL(string: "https://console.cloud.google.com/apis/library/youtube.googleapis.com")!)
                .font(.system(size: 12)).foregroundColor(Color(hex: "FF6666"))
        }
        .padding(40)
        .background { ThemeBackground(state: state) }
        .frame(width: 460, height: 380)
        .preferredColorScheme(.dark)
        .onAppear { input = state.apiKey }
        .overlay(alignment: .topTrailing) {
            Button { state.showApiKeySheet = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.07), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Close")
            .padding(16)
        }
    }
}
