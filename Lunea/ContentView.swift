import SwiftUI

// MARK: - Root

struct ContentView: View {
    @StateObject private var state = AppState()
    @State private var selectedTab: Tab = .home

    enum Tab: String, Equatable {
        case home, explore, shorts, subs
        case history, watchlater, liked, playlist
    }

    var body: some View {
        ZStack {
            BackgroundOrbs()

            HStack(spacing: 16) {
                // KIRI: Sidebar
                SidebarView(selectedTab: $selectedTab, state: state)
                    .frame(width: 250)
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

                // KANAN: Main Content
                VStack(spacing: 0) {
                    TopBar(state: state)
                        .frame(height: 60)

                    // Main View Area
                    ZStack {
                        // 1. Base Layer (Home / Search)
                        // 🔥 LOGIKA ROUTING DIPERBAIKI: Sangat stabil mengunci layar
                        if state.isSearchActive {
                            SearchResultsView(state: state)
                                .transition(.opacity)
                        } else {
                            HomeView(state: state, selectedTab: selectedTab)
                                .transition(.opacity)
                        }

                        // 2. Floating Player Layer (Berjalan tanpa memotong Home)
                        if state.isShowingPlayer, let vid = state.selectedVideoId {
                            FloatingPlayerOverlay(videoId: vid)
                                .environmentObject(state)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: state.isShowingPlayer)
                    .animation(.easeInOut(duration: 0.3), value: state.isSearchActive)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background(Color(hex: "0A0A12").opacity(0.75))
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
                        .foregroundColor(isSearchFocused ? Color(hex: "FA2E5B") : .white.opacity(0.5))
                }
                .buttonStyle(.plain)

                TextField("Telusuri video...", text: $state.searchQuery)
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
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(isSearchFocused ? 0.08 : (isHovered ? 0.06 : 0.04)))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSearchFocused ? Color(hex: "FA2E5B").opacity(0.6) : Color.white.opacity(0.1),
                        lineWidth: isSearchFocused ? 1.5 : 0.5
                    )
            }
            .shadow(color: isSearchFocused ? Color(hex: "FA2E5B").opacity(0.15) : .clear, radius: 12)
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
    let columns = [GridItem(.adaptive(minimum: 240), spacing: 20)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Category chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(state.categories, id: \.self) { cat in
                            GlassChip(label: cat, isSelected: state.selectedCategory == cat) {
                                state.selectedCategory = cat
                                Task { await state.loadHome() }
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }

                if state.isLoading {
                    VStack(spacing: 16) {
                        ProgressView().progressViewStyle(.circular).scaleEffect(1.2).tint(Color(hex: "FA2E5B"))
                        Text("Memuat...").font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                } else if let err = state.errorMessage {
                    ErrorView(message: err) { Task { await state.loadHome() } }
                } else {
                    if let first = state.trendingVideos.first {
                        HeroFeaturedCard(video: first) {
                            Task { await state.selectVideo(first.id) }
                        }
                    }

                    if state.trendingVideos.count > 1 {
                        SectionHeader(icon: "play.tv.fill", title: "Top 10 di Trending")
                            .padding(.top, 10)
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(Array(state.trendingVideos.dropFirst())) { video in
                                VideoCard(video: video) {
                                    Task { await state.selectVideo(video.id) }
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 40)
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
                    HStack { Spacer(); ProgressView().scaleEffect(1.4).tint(Color(hex: "FA2E5B")); Spacer() }
                        .padding(.top, 80)
                } else if let err = state.errorMessage {
                    ErrorView(message: err) { Task { await state.search() } }
                } else if state.searchResults.isEmpty {
                    HStack { Spacer(); Text("Video tidak ditemukan.").font(.system(size: 14)).foregroundColor(.white.opacity(0.5)); Spacer() }
                        .padding(.top, 60)
                } else {
                    ForEach(state.searchResults) { item in
                        if let vid = item.videoId {
                            SearchResultCard(item: item)
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
    let message: String; let retry: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 36)).foregroundColor(Color(hex: "FFBD2E"))
            Text(message).font(.system(size: 13)).foregroundColor(.white.opacity(0.55)).multilineTextAlignment(.center)
            Button("Coba Lagi", action: retry)
                .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                .padding(.horizontal, 20).padding(.vertical, 9)
                .background(Color(hex: "FA2E5B")).clipShape(Capsule()).buttonStyle(.plain)
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
                    .background(Color(hex: "FA2E5B")).clipShape(Capsule())
                    .shadow(color: Color(hex: "FA2E5B").opacity(0.4), radius: 12)
            }
            .buttonStyle(.plain).disabled(input.isEmpty)

            Link("Cara dapatkan API key →",
                 destination: URL(string: "https://console.cloud.google.com/apis/library/youtube.googleapis.com")!)
                .font(.system(size: 12)).foregroundColor(Color(hex: "FF6666"))
        }
        .padding(40)
        .background { BackgroundOrbs() }
        .frame(width: 460, height: 380)
        .preferredColorScheme(.dark)
    }
}
