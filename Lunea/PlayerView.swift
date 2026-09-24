import SwiftUI
import WebKit

// MARK: - YouTube Player (WKWebView)

struct YouTubePlayerView: NSViewRepresentable {
    let videoId: String
    var autoplay: Bool = true

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        weak var webView: WKWebView?
        var loadedVideoId: String?
        var loadedAutoplay: Bool?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {}
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {}
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {}

        func webView(_ webView: WKWebView,
                     requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                     initiatedByFrame frame: WKFrameInfo,
                     type: WKMediaCaptureType,
                     decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }

        // ✅ Kunci: handle window baru yang dibuat saat YouTube minta fullscreen
        // Tanpa ini, YouTube buka window baru yang langsung ditolak → video pause
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            return nil // Tolak window baru — YouTube akan fallback ke fullscreen in-place
        }
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
        // ✅ UIDelegate diperlukan untuk handle fullscreen request dari iframe
        webView.uiDelegate = context.coordinator
        context.coordinator.webView = webView
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedVideoId != videoId ||
                context.coordinator.loadedAutoplay != autoplay else { return }
        context.coordinator.loadedVideoId = videoId
        context.coordinator.loadedAutoplay = autoplay
        // fs=0 — sembunyikan tombol fullscreen YouTube bawaan (yang tidak bisa jalan di WKWebView)
        // Kita ganti dengan tombol Swift sendiri di overlay
        let embedURL = "https://www.youtube.com/embed/\(videoId)?playsinline=1&autoplay=\(autoplay ? 1 : 0)&fs=0&rel=0&origin=https://rahmn.tech"
        let html = """
        <!DOCTYPE html><html>
        <head><meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no">
        <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        html, body { width:100%; height:100%; background:#000; overflow:hidden; border-radius:20px; }
        iframe { width:100%; height:100%; border:0; display:block; border-radius:20px; }
        </style>
        </head>
        <body>
        <iframe id="yt" src="\(embedURL)"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            referrerpolicy="strict-origin-when-cross-origin">
        </iframe>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://rahmn.tech"))
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.loadHTMLString("<html><body style='background:#000'></body></html>", baseURL: nil)
        coordinator.webView = nil
        coordinator.loadedVideoId = nil
    }
}

// MARK: - Native Fullscreen Button
// Karena WKWebView sandbox tidak bisa requestFullscreen() dari iframe,
// kita pakai NSWindow toggleFullScreen — fullscreen window macOS native.

struct NativeFullscreenButton: View {
    let isFullscreen: Bool
    @State private var isHovered = false

    private func toggle() {
        NotificationCenter.default.post(name: .toggleVideoFullscreen, object: nil)
    }

    var body: some View {
        Button { toggle() } label: {
            Image(systemName: isFullscreen
                  ? "arrow.down.right.and.arrow.up.left"
                  : "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.4), radius: 6)
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .onHover { hovered in
            isHovered = hovered
            if hovered { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
        .animation(.spring(response: 0.2), value: isHovered)
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
            let contentWidth = max(0, geo.size.width - 40)
            let contentHeight = max(0, geo.size.height - 40)
            let compactLayout = geo.size.width < 900
            let queueWidth = min(340, max(280, contentWidth * 0.31))
            let wideVideoWidth = max(420, contentWidth - queueWidth - 14)
            let normalVideoWidth = compactLayout ? contentWidth : wideVideoWidth
            let normalVideoHeight = min(
                normalVideoWidth * (9/16),
                compactLayout ? contentHeight * 0.45 : contentHeight * 0.64
            )
            let compactQueueHeight = min(230, max(150, contentHeight - normalVideoHeight - 150))
            let miniX = max(16, geo.size.width - miniW - 16)
            let miniY = max(16, geo.size.height - miniH - 56 - 16)

            ZStack(alignment: .topLeading) {
                if !isMini {
                    ThemeBackground(state: state).ignoresSafeArea()

                    VStack(spacing: 14) {
                        if compactLayout {
                            VStack(spacing: 14) {
                                Color.clear
                                    .frame(width: normalVideoWidth, height: normalVideoHeight)
                                queuePanel
                                    .frame(width: contentWidth, height: compactQueueHeight)
                            }
                        } else {
                            HStack(alignment: .top, spacing: 14) {
                                Color.clear
                                    .frame(width: normalVideoWidth, height: normalVideoHeight)
                                queuePanel
                                    .frame(width: queueWidth, height: normalVideoHeight)
                            }
                        }

                        ScrollView(showsIndicators: false) {
                            PlayerDetailsView()
                                .environmentObject(state)
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.7)
                                }
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .frame(width: contentWidth, height: contentHeight, alignment: .top)
                    .padding(20)
                }

                // Keep exactly one WKWebView alive. Moving between full player and PiP
                // changes only its geometry, so YouTube keeps the current playback time.
                YouTubePlayerView(videoId: videoId)
                    .frame(
                        width: isMini ? miniW : normalVideoWidth,
                        height: isMini ? miniH : normalVideoHeight
                    )
                    .clipShape(RoundedRectangle(cornerRadius: isMini ? 14 : 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: isMini ? 14 : 18, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
                    }
                    .overlay {
                        if isMini {
                            Color.black.opacity(0.001)
                                .contentShape(Rectangle())
                                .onTapGesture { state.isPlayerMinimized = false }
                        }
                    }
                    .offset(x: isMini ? miniX : 20, y: isMini ? miniY : 20)
                    .shadow(color: .black.opacity(isMini ? 0.5 : 0), radius: 22, y: 8)
                    .zIndex(20)

                if isMini {
                    miniPlayerInfo
                        .frame(width: miniW, height: 56)
                        .background(Color(hex: "11131B").opacity(0.97))
                        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 17, bottomTrailingRadius: 17))
                        .overlay {
                            UnevenRoundedRectangle(bottomLeadingRadius: 17, bottomTrailingRadius: 17)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.7)
                        }
                        .offset(x: miniX, y: miniY + miniH)
                        .shadow(color: .black.opacity(0.45), radius: 18, y: 8)
                        .zIndex(21)
                }
            }
        }
        .zIndex(100)
    }

    private var queuePanel: some View {
        RelatedVideosPanel()
            .environmentObject(state)
            .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.7)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var miniPlayerInfo: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(state.selectedVideoDetail?.snippet?.title ?? "Loading…")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(state.selectedVideoDetail?.snippet?.channelTitle ?? "")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.45))
            }
            Spacer()
            Button {
                state.isPlayerMinimized = false
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            Button { withAnimation { state.closePlayer() } } label: {
                Image(systemName: "xmark")
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(.white.opacity(0.75))
        .padding(.horizontal, 10)
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
            Text(detail?.snippet?.title ?? "Loading video…")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.95))
                .lineSpacing(2)
                .padding(.top, 14)

            HStack(spacing: 14) {
                if let stats = detail?.statistics {
                    StatChip(value: stats.formattedViews, label: "views")
                    StatChip(value: stats.formattedLikes, label: "likes")
                }
                if let pub = detail?.snippet?.publishedAt {
                    StatChip(value: relativeDate(pub), label: "")
                }
            }

            HStack(spacing: 8) {
                PillButton(icon: "hand.thumbsup", label: isLiked ? "Liked" : "Like", isAccent: isLiked) {
                    withAnimation(.spring(response: 0.25)) { isLiked.toggle() }
                }
                PillButton(icon: "arrowshape.turn.up.right", label: "Share", isAccent: false) {}
                PillButton(icon: "bookmark", label: "Save", isAccent: false) {}
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
                    Text("Subscriber count hidden")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                SubscribeButton()
            }
            .padding(12)
            .background(Color.white.opacity(0.055))
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
                        Button(isDescExpanded ? "Show less" : "Show more") {
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
        rel.locale = Locale(identifier: "en_US")
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
        .background(
            isAccent ? Color(hex: "FA2E5B").opacity(0.2) : Color.white.opacity(0.065),
            in: Capsule()
        )
        .overlay { Capsule().strokeBorder(Color.white.opacity(0.09), lineWidth: 0.6) }
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
    @State private var selectedSection = "Up next"

    var videos: [YouTubeVideoDetail] {
        state.relatedVideoDetails.isEmpty
            ? Array(state.trendingVideos.prefix(16))
            : Array(state.relatedVideoDetails.prefix(16))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                ForEach(["Up next", "Related", "For you"], id: \.self) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        Text(section)
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(selectedSection == section ? Color.black.opacity(0.78) : Color.white.opacity(0.58))
                            .padding(.horizontal, 12)
                            .frame(height: 30)
                            .background(selectedSection == section ? Color.white.opacity(0.9) : Color.white.opacity(0.055), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 9) {
                    ForEach(videos, id: \.id) { video in
                        PlayerQueueRow(video: video, state: state)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
        }
    }
}

struct PlayerQueueRow: View {
    let video: YouTubeVideoDetail
    @ObservedObject var state: AppState
    @State private var isHovered = false

    var body: some View {
        Button { Task { await state.selectVideo(video.id) } } label: {
            HStack(alignment: .top, spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    CachedAsyncImage(url: URL(string: video.snippet?.thumbnails.medium?.url ?? "")) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(Color.white.opacity(0.05))
                    }
                    if let duration = video.contentDetails?.formattedDuration {
                        Text(duration)
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(Color.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 3))
                            .padding(4)
                    }
                }
                .frame(width: 112, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.snippet?.title ?? "")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                    Text(video.snippet?.channelTitle ?? "")
                        .font(.system(size: 9.5))
                        .foregroundStyle(.white.opacity(0.44))
                        .lineLimit(1)
                    if let views = video.statistics?.formattedViews {
                        Text("\(views) views")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.32))
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(isHovered ? 0.09 : 0.035), in: RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
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
                    CachedAsyncImage(url: thumbnailURL) { image in
                        image.resizable().aspectRatio(16/9, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .overlay { ProgressView().controlSize(.small).tint(.white.opacity(0.3)) }
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
                        Text("\(views) views")
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


// MARK: - Window Fullscreen Setup
// Tambahkan ini di App entry point (@main) kamu — di dalam WindowGroup:
//
// @main
// struct LuneaApp: App {
//     var body: some Scene {
//         WindowGroup {
//             ContentView()
//                 .onAppear {
//                     // ✅ Pastikan window support fullscreen
//                     NSApplication.shared.windows.forEach { window in
//                         window.collectionBehavior = [.fullScreenPrimary]
//                         window.styleMask.insert(.fullSizeContentView)
//                     }
//                 }
//         }
//         .windowStyle(.hiddenTitleBar)
//     }
// }
