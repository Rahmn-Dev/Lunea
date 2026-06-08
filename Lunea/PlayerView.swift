import SwiftUI
import WebKit

// MARK: - YouTube Player (WKWebView)

struct YouTubePlayerView: NSViewRepresentable {
    let videoId: String
    var autoplay: Bool = true

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {}
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {}
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {}
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = autoplay ? [] : [.all]
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.layer?.backgroundColor = NSColor.clear.cgColor
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let embedURL = "https://www.youtube.com/embed/\(videoId)?playsinline=1&autoplay=\(autoplay ? 1 : 0)&origin=https://rahmn.tech"
        let html = """
        <!DOCTYPE html><html>
        <head><meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no">
        <style>* { margin:0; padding:0; box-sizing:border-box; } html,body { width:100%; height:100%; background:#000; overflow:hidden; border-radius:20px; } iframe { width:100%; height:100%; border:0; display:block; border-radius:20px; }</style>
        </head>
        <body><iframe src="\(embedURL)" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe></body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://rahmn.tech"))
    }
}

// MARK: - Floating Player Overlay

struct FloatingPlayerOverlay: View {
    @EnvironmentObject var state: AppState
    let videoId: String

    var body: some View {
        GeometryReader { geo in
            let isMini = state.isPlayerMinimized
            let miniW: CGFloat = 300
            let miniH: CGFloat = miniW * (9/16)
            let miniInfoH: CGFloat = 56
            let fullVideoW = geo.size.width * 0.62 - 24
            let fullVideoH = fullVideoW * (9/16)
            let miniX = geo.size.width - miniW - 16
            let miniY = geo.size.height - miniH - miniInfoH - 16

            ZStack(alignment: .topLeading) {

                if !isMini {
                    // ✅ Pakai ThemeBackground langsung — sama persis dengan beranda
                    // Tidak ada blur layer, tidak ngelag, warna ngikutin tema yang dipilih
                    ThemeBackground(state: state)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }

                YouTubePlayerView(videoId: videoId)
                    .frame(
                        width:  isMini ? miniW      : fullVideoW,
                        height: isMini ? miniH      : fullVideoH
                    )
                    .clipShape(RoundedRectangle(cornerRadius: isMini ? 12 : 10, style: .continuous))
                    .overlay {
                        if isMini {
                            Color.black.opacity(0.01)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                                        state.isPlayerMinimized = false
                                    }
                                }
                        }
                    }
                    .shadow(color: .black.opacity(isMini ? 0.5 : 0), radius: 20, y: 6)
                    .offset(x: isMini ? miniX : 24, y: isMini ? miniY : 20)
                    .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isMini)
                    .zIndex(10)

                if isMini {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(state.selectedVideoDetail?.snippet?.title ?? "Memuat...")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(state.selectedVideoDetail?.snippet?.channelTitle ?? "")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                                state.isPlayerMinimized = false
                            }
                        } label: {
                            Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        Button { withAnimation { state.closePlayer() } } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .frame(width: miniW, height: miniInfoH)
                    .glassEffect(in: .rect(cornerRadius: 17.0))
                    .shadow(color: .black.opacity(0.45), radius: 16, y: 6)
                    .offset(x: miniX, y: miniY + miniH)
                    .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isMini)
                    .zIndex(10)
                }

                if !isMini {
                    HStack(alignment: .top, spacing: 0) {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: fullVideoH + 20 + 14)
                            ScrollView(showsIndicators: false) {
                                PlayerDetailsView()
                                    .environmentObject(state)
                                    .padding(.trailing, 20)
                                    .padding(.bottom, 32)
                            }
                        }
                        .frame(width: fullVideoW)
                        .padding(.leading, 24)

                        Rectangle()
                            .fill(Color.white.opacity(0.07))
                            .frame(width: 0.5)

                        RelatedVideosPanel()
                            .environmentObject(state)
                            .frame(width: geo.size.width * 0.38)
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
        .zIndex(100)
    }
}

// MARK: - Player Details

struct PlayerDetailsView: View {
    @EnvironmentObject var state: AppState
    @State private var isDescExpanded = false
    @State private var isLiked = false
    var detail: YouTubeVideoDetail? { state.selectedVideoDetail }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(detail?.snippet?.title ?? "Memuat video...")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.95))
                .lineSpacing(2)
                .padding(.top, 14)

            HStack(spacing: 14) {
                if let stats = detail?.statistics {
                    StatChip(value: stats.formattedViews, label: "tayangan")
                    StatChip(value: stats.formattedLikes, label: "suka")
                }
                if let pub = detail?.snippet?.publishedAt {
                    StatChip(value: relativeDate(pub), label: "")
                }
            }

            HStack(spacing: 8) {
                PillButton(icon: "hand.thumbsup", label: isLiked ? "Disukai" : "Suka", isAccent: isLiked) {
                    withAnimation(.spring(response: 0.25)) { isLiked.toggle() }
                }
                PillButton(icon: "arrowshape.turn.up.right", label: "Bagikan", isAccent: false) {}
                PillButton(icon: "bookmark", label: "Simpan", isAccent: false) {}
            }

            HStack(spacing: 10) {
                ChannelAvatar(
                    initial: String(detail?.snippet?.channelTitle.prefix(1) ?? "?"),
                    size: 34
                )
                VStack(alignment: .leading, spacing: 1) {
                    Text(detail?.snippet?.channelTitle ?? "—")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text("Subscriber disembunyikan")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                SubscribeButton()
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
            }

            if let desc = detail?.snippet?.description, !desc.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(isDescExpanded ? desc : String(desc.prefix(160)) + (desc.count > 160 ? "…" : ""))
                        .font(.system(size: 12.5))
                        .foregroundColor(.white.opacity(0.72))
                        .lineSpacing(3)
                    if desc.count > 160 {
                        Button(isDescExpanded ? "Lebih sedikit" : "Selengkapnya") {
                            withAnimation(.easeInOut(duration: 0.2)) { isDescExpanded.toggle() }
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(state.currentTheme.accentColor)
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
                }
            }
        }
    }

    private func relativeDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        guard let d = f.date(from: iso) else { return iso }
        let rel = RelativeDateTimeFormatter()
        rel.locale = Locale(identifier: "id_ID")
        rel.unitsStyle = .abbreviated
        return rel.localizedString(for: d, relativeTo: Date())
    }
}

// MARK: - Stat Chip

struct StatChip: View {
    let value: String
    let label: String
    var body: some View {
        HStack(spacing: 3) {
            Text(value).font(.system(size: 12, weight: .bold)).foregroundColor(.white.opacity(0.8))
            if !label.isEmpty {
                Text(label).font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
            }
        }
    }
}

// MARK: - Pill Button (hover dihapus, pakai glassEffect)

struct PillButton: View {
    let icon: String
    let label: String
    let isAccent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11))
                Text(label).font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isAccent ? Color(hex: "FA2E5B") : .white.opacity(0.8))
            .padding(.horizontal, 12).padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isAccent
                ? .regular.tint(Color(hex: "FA2E5B").opacity(0.35))
                : .regular.interactive(),
            in: Capsule()
        )
    }
}

// MARK: - Supporting Components

struct StatBadge: View {
    let icon: String; let value: String
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11))
            Text(value).font(.system(size: 12, weight: .medium))
        }.foregroundColor(.white.opacity(0.5))
    }
}

struct ActionButton: View {
    let icon: String; let label: String
    var body: some View {
        Button {} label: {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 12))
                Text(label).font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 12).padding(.vertical, 7)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Capsule())
    }
}

struct SubscribeButton: View {
    @State private var subscribed = false
    var body: some View {
        Button { withAnimation(.spring(response: 0.25)) { subscribed.toggle() } } label: {
            Text(subscribed ? "✓ Subscribed" : "Subscribe")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(subscribed ? .white.opacity(0.5) : .white)
                .padding(.horizontal, 14).padding(.vertical, 7)
        }
        .buttonStyle(.plain)
        .glassEffect(
            subscribed ? .regular : .regular.tint(Color.white.opacity(0.1)),
            in: Capsule()
        )
    }
}

// MARK: - Related Videos Panel

struct RelatedVideosPanel: View {
    @EnvironmentObject var state: AppState

    var videos: [YouTubeVideoDetail] {
        state.relatedVideoDetails.isEmpty
            ? Array(state.trendingVideos.prefix(16))
            : Array(state.relatedVideoDetails.prefix(16))
    }

    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Selanjutnya")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.white.opacity(0.35))
                Spacer()
                if !state.relatedVideoDetails.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green.opacity(0.6))
                } else {
                    ProgressView()
                        .scaleEffect(0.55)
                        .tint(.white.opacity(0.35))
                }
            }
            // ✅ Padding kanan disamain dengan kiri (24) biar simetris
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(videos, id: \.id) { video in
                        RelatedVideoCard(video: video, state: state)
                    }
                }
                // ✅ Padding kanan 20 — sejajar dengan panel kiri
                .padding(.leading, 10)
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Related Video Card
// ✅ Hover: hanya background berubah, TIDAK ada scaleEffect / animasi gambar
// ✅ Thumbnail pakai .default (120x90px) bukan .medium → lebih kecil, lebih cepat load
// ✅ Tinggi card konsisten: thumbnail 16:9 fixed + info area height fixed

struct RelatedVideoCard: View {
    let video: YouTubeVideoDetail
    @ObservedObject var state: AppState
    @State private var isHovered = false

    // ✅ Ambil URL thumbnail terkecil yang tersedia (default = 120x90)
    // Jauh lebih ringan dari medium (320x180) untuk grid kecil
    private var thumbnailURL: URL? {
        let t = video.snippet?.thumbnails
        // Pakai medium saja — sesuaikan jika nama property berbeda di struct kamu
        let urlStr = t?.medium?.url ?? t?.high?.url ?? ""
        return URL(string: urlStr)
    }

    var body: some View {
        Button {
            Task { await state.selectVideo(video.id) }
        } label: {
            VStack(alignment: .leading, spacing: 0) {

                // Thumbnail — fixed 16:9, tidak bisa stretch
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .success(let img):
                            img
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundColor(.white.opacity(0.2))
                                }
                        default:
                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .overlay {
                                    ProgressView().tint(.white.opacity(0.3))
                                }
                        }
                    }
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipped()

                    if let dur = video.contentDetails?.formattedDuration, !dur.isEmpty {
                        Text(dur)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.black.opacity(0.82))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .padding(5)
                    }
                }
                .frame(maxWidth: .infinity)
                .clipped()

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(video.snippet?.title ?? "")
                        .font(.system(size: 11, weight: .semibold))
                        // ✅ Warna teks berubah saat hover — ringan, tidak perlu animasi
                        .foregroundColor(isHovered ? .white : .white.opacity(0.88))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(video.snippet?.channelTitle ?? "")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)

                    if let views = video.statistics?.formattedViews {
                        Text("\(views) tayangan")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.28))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(height: 72, alignment: .top)
            }
            // ✅ Hover: background saja yang berubah, tanpa animasi → 0 GPU cost
            .background(Color.white.opacity(isHovered ? 0.09 : 0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        Color.white.opacity(isHovered ? 0.14 : 0.07),
                        lineWidth: 0.5
                    )
            }
            // ✅ TIDAK ada .scaleEffect sama sekali
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }  // ✅ onHover ada, tapi hanya trigger warna background
    }
}
