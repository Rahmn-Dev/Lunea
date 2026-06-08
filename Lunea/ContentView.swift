import SwiftUI
import Combine

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
    @State private var isSidebarCollapsed = false

    enum Tab: String, Equatable {
        case home, explore, shorts, subs
        case history, watchlater, liked, playlist
    }

    var body: some View {
        ZStack {
            ThemeBackground(state: state)

            HStack(spacing: 16) {
                // KIRI: Sidebar
                SidebarView(state: state, selectedTab: $selectedTab, isCollapsed: $isSidebarCollapsed)
                    .frame(width: isSidebarCollapsed ? 75 : 250)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.8)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                    .padding(.vertical, 16)
                    .padding(.leading, 16)
                    .environment(\.colorScheme, .dark)
                    .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isSidebarCollapsed)

                // KANAN: Main Content
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {  // ← alignment .top, floating di atas

                        // Layer 1: Konten utama
                        ZStack {
                            if state.isSearchActive {
                                SearchResultsView(state: state)
                                    .transition(.opacity)
                            } else {
                                HomeView(state: state, selectedTab: selectedTab)
                                    .transition(.opacity)
                            }

                            if state.isShowingPlayer, let vid = state.selectedVideoId {
                                FloatingPlayerOverlay(videoId: vid)
                                    .environmentObject(state)
                                    .id(vid)
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: state.isShowingPlayer)
                        .animation(.easeInOut(duration: 0.3), value: state.isSearchActive)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        // Padding atas agar konten tidak tertutup TopBar + kategori
                        .safeAreaInset(edge: .top) {
                            Color.clear.frame(height: 120)
                        }

                        // Layer 2: TopBar + kategori floating di atas
                        VStack(spacing: 8) {
                            TopBar(state: state)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                            // Kategori floating — hanya muncul kalau tidak search
                            if !state.isSearchActive {
                                CategoryBar(state: state)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 4)
                            }
                        }
                    }
                }
                .glassEffect(
                    .regular,
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
                .padding(.vertical, 16)
                .padding(.trailing, 16)
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
        }
        .sheet(isPresented: $state.showApiKeySheet) { ApiKeySheet(state: state) }
        .task { await state.loadHome() }
    }
}

// MARK: - Top Bar

struct TopBar: View {
    @ObservedObject var state: AppState
    @FocusState private var isSearchFocused: Bool
    @State private var isSearchHovered = false

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {

                if state.isShowingPlayer && !state.isPlayerMinimized {
                    SearchBarButton(icon: "chevron.down") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            state.isPlayerMinimized = true
                        }
                    }
                } else if state.isSearchActive {
                    SearchBarButton(icon: "chevron.left") {
                        withAnimation { state.clearSearch() }
                    }
                }

                // Search bar pill — klik di mana saja = focus TextField
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(
                            isSearchFocused
                                ? state.currentTheme.accentColor
                                : (isSearchHovered ? Color.primary : Color.secondary)
                        )

                    TextField("Find Videos...", text: $state.searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15, weight: .medium))
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
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(width: isSearchFocused ? 520 : 400)
                // ✅ Tap di mana saja dalam capsule → focus ke TextField
                .contentShape(Capsule())
                .onTapGesture { isSearchFocused = true }
                .glassEffect(
                    isSearchFocused
                        ? .regular.interactive().tint(state.currentTheme.accentColor.opacity(0.3))
                        : isSearchHovered
                            ? .regular.interactive().tint(Color.white.opacity(0.12))
                            : .regular.interactive(),
                    in: Capsule()
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSearchFocused)
                .onHover { hovered in
                    isSearchHovered = hovered
                    if hovered { NSCursor.iBeam.push() } else { NSCursor.pop() }
                }

                SearchBarButton(icon: "key.fill") {
                    state.showApiKeySheet = true
                }
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
                        ? state.currentTheme.accentColor
                        : (isHovered ? Color.primary : Color.secondary)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                // ✅ contentShape Capsule = seluruh area pill bisa diklik & di-hover
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        // ✅ glassEffect di luar button — jadi background, hit area tetap penuh
        .glassEffect(
            isSelected
                ? .regular.interactive().tint(state.currentTheme.accentColor.opacity(0.35))
                : isHovered
                    ? .regular.interactive().tint(Color.white.opacity(0.12))
                    : .regular.interactive(),
            in: Capsule()
        )
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
                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(state.categories, id: \.self) { cat in
                            CategoryChip(state: state, cat: cat)
                        }
                    }
                    .frame(minWidth: geo.size.width, alignment: .center)
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
                .frame(width: 50, height: 50)
                // ✅ contentShape = hit area penuh circle, bukan cuma ikon
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        // ✅ glassEffect SATU kali di luar button — tidak double layer
        .glassEffect(
            isHovered
                ? .regular.interactive().tint(Color.white.opacity(0.15))
                : .regular.interactive(),
            in: Circle()
        )
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
    @State private var currentIndex = 0
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 30) {

                // Hero Carousel
                if !state.trendingVideos.isEmpty {
                    let items = Array(state.trendingVideos.prefix(5))
                    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 20) {
                                ForEach(0..<items.count, id: \.self) { index in
                                    HeroFeaturedCard(
                                        state: state,
                                        video: items[index],
                                        action: { Task { await state.selectVideo(items[index].id) } }
                                    )
                                    .containerRelativeFrame(.horizontal, count: 1, spacing: 20)
                                    .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
                                    .id(index)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .contentMargins(.horizontal, 80, for: .scrollContent)
                        .frame(height: 370)
                        .onReceive(timer) { _ in
                            withAnimation(.easeInOut(duration: 0.8)) {
                                let nextIndex = (currentIndex + 1) % items.count
                                currentIndex = nextIndex
                                proxy.scrollTo(nextIndex, anchor: .center)
                            }
                        }
                    }
                }

                // Recommendation Row
                if state.trendingVideos.count > 5 {
                    SectionHeader(icon: "rectangle.stack.fill", title: "Reccomendation")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(state.trendingVideos.prefix(5).dropFirst()) { video in
                                VideoCard(
                                    state: state, video: video,
                                    action: { Task { await state.selectVideo(video.id) } }
                                )
                                .frame(width: 280)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                // Explore Grid
                if state.trendingVideos.count > 6 {
                    SectionHeader(icon: "square.grid.3x3.fill", title: "Explore All")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(state.trendingVideos.dropFirst(6)) { video in
                            VideoCard(
                                state: state, video: video,
                                action: { Task { await state.selectVideo(video.id) } }
                            )
                        }
                    }
                }

                Color.clear.onAppear {
                    Task { await state.loadMore() }
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Search Results

struct SearchResultsView: View {
    @ObservedObject var state: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(icon: "magnifyingglass", title: "\"\(state.searchQuery)\"")
                    .padding(.bottom, 4)

                if state.isSearching {
                    HStack { Spacer(); ProgressView().scaleEffect(1.4).tint(state.currentTheme.accentColor); Spacer() }
                        .padding(.top, 80)
                } else if let err = state.errorMessage {
                    ErrorView(state: state, message: err) { Task { await state.search() } }
                } else if state.searchResults.isEmpty {
                    HStack { Spacer(); Text("Video tidak ditemukan.").font(.system(size: 14)).foregroundColor(.white.opacity(0.5)); Spacer() }
                        .padding(.top, 60)
                } else {
                    ForEach(state.searchResults) { item in
                        if let vid = item.videoId {
                            SearchResultCard(state: state, item: item)
                                .onTapGesture { Task { await state.selectVideo(vid) } }
                        }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(20)
        }
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
            Button("Coba Lagi", action: retry)
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
                Text("Simpan & Mulai")
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .frame(width: 180, height: 42)
                    .background(state.currentTheme.accentColor).clipShape(Capsule())
                    .shadow(color: state.currentTheme.accentColor.opacity(0.4), radius: 12)
            }
            .buttonStyle(.plain).disabled(input.isEmpty)

            Link("Cara dapatkan API key →",
                 destination: URL(string: "https://console.cloud.google.com/apis/library/youtube.googleapis.com")!)
                .font(.system(size: 12)).foregroundColor(Color(hex: "FF6666"))
        }
        .padding(40)
        .background { ThemeBackground(state: state) }
        .frame(width: 460, height: 380)
        .preferredColorScheme(.dark)
    }
}
