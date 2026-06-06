import SwiftUI
import Combine

// MARK: - Root

struct ContentView: View {
    @StateObject private var state = AppState()
    @State private var selectedTab: Tab = .home
    
    // 🔥 TAMBAHAN BARU: Mengatur status collapse sidebar
    @State private var isSidebarCollapsed = false

    enum Tab: String, Equatable {
        case home, explore, shorts, subs
        case history, watchlater, liked, playlist
    }

    var body: some View {
        ZStack {
            ThemeBackground(state: state)

            HStack(spacing: 16) {
                // KIRI: Sidebar (Lebar dinamis: 75 vs 250)
                SidebarView(state: state, selectedTab: $selectedTab, isCollapsed: $isSidebarCollapsed)
                    .frame(width: isSidebarCollapsed ? 75 : 250) // 🔥 KUNCI ANIMASI LEBAR
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
                    // Berikan efek animasi pegas saat lebar sidebar berubah
                    .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isSidebarCollapsed)

                // KANAN: Main Content
                VStack(spacing: 0) {
                    TopBar(state: state)
                        .frame(height: 60)

                    // Main View Area
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
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
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

// MARK: - Top Bar (Super Clean)

struct TopBar: View {
    @ObservedObject var state: AppState
    @FocusState private var isSearchFocused: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            
            if state.isShowingPlayer && !state.isPlayerMinimized {
                HeaderButton(icon: "chevron.down") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        state.isPlayerMinimized = true
                    }
                }
            } else if state.isSearchActive { // 🔥 Mengacu pada isSearchActive
                HeaderButton(icon: "chevron.left") {
                    withAnimation { state.clearSearch() }
                }
            } else {
                Spacer().frame(width: 36)
            }

            Spacer()

            // Search bar — VisionOS Style
            HStack(spacing: 10) {
                // KUNCI FIX: Ikon pencarian menjadi Button agar bisa diklik manual
                Button {
                    Task { await state.search() }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isSearchFocused ? state.currentTheme.accentColor : .white.opacity(0.5))
                }
                .buttonStyle(.plain)

                TextField("Find Videos...", text: $state.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .focused($isSearchFocused)
                    .onSubmit { Task { await state.search() } } // Enter sekarang bebas bekerja!

                if !state.searchQuery.isEmpty {
                    Button {
                        state.searchQuery = "" // Jangan matikan mode pencarian, hanya kosongkan teks
                        isSearchFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(width: isSearchFocused ? 480 : 380)
            .background {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(Color.white.opacity(isSearchFocused ? 0.08 : (isHovered ? 0.06 : 0.04)))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .strokeBorder(
                        isSearchFocused ? state.currentTheme.accentColor.opacity(0.6) : Color.white.opacity(0.1),
                        lineWidth: isSearchFocused ? 1.5 : 0.5
                    )
            }
            .shadow(color: isSearchFocused ? state.currentTheme.accentColor.opacity(0.15) : .clear, radius: 12)
            // KUNCI FIX: .onTapGesture dihilangkan dari sini agar 'Enter' tidak diblokir!
            .onHover { isHovered = $0 }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSearchFocused)
            .animation(.easeInOut(duration: 0.2), value: isHovered)

            Spacer()

            HeaderButton(icon: "key.fill") {
                state.showApiKeySheet = true
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background {
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.white.opacity(0.0), Color.white.opacity(0.08), Color.white.opacity(0.0)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(height: 1)
            }
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
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isHovered ? .white : .white.opacity(0.7))
                .frame(width: 36, height: 36)
                .background {
                    Circle()
                        .fill(Color.white.opacity(isHovered ? 0.15 : 0.08))
                        .shadow(color: isHovered ? .black.opacity(0.2) : .clear, radius: 4)
                }
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { isHovered = $0 }
    }
}
// MARK: - Home View

struct HomeView: View {
    @ObservedObject var state: AppState
    let selectedTab: ContentView.Tab
    @State private var currentIndex = 0
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 30) {
                
                // 🔥 KATEGORI DISINI: Kembali muncul & di-center
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Spacer() // Dorong ke tengah
                        ForEach(state.categories, id: \.self) { cat in
                            GlassChip(state: state, label: cat, isSelected: state.selectedCategory == cat) {
                                state.selectedCategory = cat
                                Task { await state.loadHome() }
                            }
                        }
                        Spacer() // Dorong ke tengah
                    }
                    .frame(minWidth: 1100) // Sesuai permintaanmu
                }
                .padding(.vertical, 8)

                // 1. Hero Card
                // 1. Carousel Hero (macOS Compatible)
                // 1. Carousel Hero (dengan Autoscroll 3 detik)
                // 1. Carousel Hero (Peek-a-boo style)
                if !state.trendingVideos.isEmpty {
                    let items = Array(state.trendingVideos.prefix(5))
                    
                    // Timer autoscroll 3 detik
                    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
                    
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 20) { // Jarak antar kartu
                                ForEach(0..<items.count, id: \.self) { index in
                                    HeroFeaturedCard(
                                        state: state,
                                        video: items[index],
                                        action: { Task { await state.selectVideo(items[index].id) } }
                                    )
                                    // PENTING: Lebar kartu dibuat dinamis agar kartu kiri/kanan bisa intip
                                    // count: 1 berarti full width, tapi di-inset oleh contentMargins
                                    .containerRelativeFrame(.horizontal, count: 1, spacing: 20)
                                    .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
                                    .id(index)
                                }
                            }
                            .scrollTargetLayout() // Agar scroll bisa "snap" ke kartu
                        }
                        .scrollTargetBehavior(.viewAligned) // Efek "nempel" pas di tengah
                        // INI RAHASIANYA: contentMargins membuat kartu di pinggir terlihat
                        .contentMargins(.horizontal, 80, for: .scrollContent)
                        .frame(height: 370)
                        .onReceive(timer) { _ in
                            withAnimation(.easeInOut(duration: 0.8)) {
                                // Logika pindah ke kanan otomatis
                                let nextIndex = (currentIndex + 1) % items.count
                                currentIndex = nextIndex
                                proxy.scrollTo(nextIndex, anchor: .center)
                            }
                        }
                    }
                }

                // 2. Horizontal Scroll Row
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
                                // 🔥 HAPUS .onTapGesture di sini!
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                // 3. Grid Layout
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

                // Trigger Infinite Scroll
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

                // 🔥 LOGIKA TAMPILAN SEARCH DIPERBAIKI
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
