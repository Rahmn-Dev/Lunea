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
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
            iframe { width: 100%; height: 100%; border: 0; display: block; }
        </style>
        </head>
        <body>
        <iframe src="\(embedURL)" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://rahmn.tech"))
    }
}

// MARK: - Floating Player Overlay (Mini & Full Mode)

struct FloatingPlayerOverlay: View {
    @EnvironmentObject var state: AppState
    let videoId: String

    var body: some View {
        GeometryReader { geo in
            let isMini = state.isPlayerMinimized
            let miniWidth: CGFloat = 340
            let miniHeight: CGFloat = miniWidth * (9/16)
            
            ZStack(alignment: .topLeading) {
                // Background Solid saat layar penuh (menutupi HomeView)
                if !isMini {
                    Color(hex: "0A0A12").ignoresSafeArea()
                        .transition(.opacity)
                }

                VStack(alignment: .leading, spacing: 0) {
                    // --- 1. KOMPONEN VIDEO ---
                    YouTubePlayerView(videoId: videoId)
                        .frame(
                            width: isMini ? miniWidth : geo.size.width,
                            height: isMini ? miniHeight : min(geo.size.width * (9/16), geo.size.height * 0.75)
                        )
                        .overlay {
                            if isMini {
                                // Klik pada video mini untuk membesarkan kembali layarnya
                                Color.black.opacity(0.01)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            state.isPlayerMinimized = false
                                        }
                                    }
                            }
                        }

                    // --- 2. KOMPONEN INFO ---
                    if isMini {
                        // Title bar untuk Mini Player
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(state.selectedVideoDetail?.snippet?.title ?? "Memuat...")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text(state.selectedVideoDetail?.snippet?.channelTitle ?? "")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Spacer()
                            
                            // Tombol Silang (X) untuk mematikan Mini Player
                            Button {
                                withAnimation { state.closePlayer() }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(8)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(width: miniWidth)
                        .background(.ultraThinMaterial)
                    } else {
                        // Layar penuh untuk info dan deskripsi (Tanpa Related Videos)
                        ScrollView(showsIndicators: false) {
                            PlayerDetailsView()
                                .environmentObject(state)
                        }
                        .transition(.opacity)
                    }
                }
                .background(isMini ? Color.clear : Color(hex: "0A0A12"))
                .clipShape(RoundedRectangle(cornerRadius: isMini ? 16 : 0, style: .continuous))
                .shadow(color: .black.opacity(isMini ? 0.6 : 0), radius: 24, y: 12)
                .overlay {
                    if isMini {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                    }
                }
                // Logika pergerakan Mini Player ke pojok kanan bawah
                .offset(
                    x: isMini ? geo.size.width - miniWidth - 24 : 0,
                    y: isMini ? geo.size.height - (miniHeight + 60) - 24 : 0
                )
            }
        }
        .zIndex(100) // Memastikan selalu berada di atas layer lain
    }
}

// MARK: - Simplified Player Details (Murni Info Saja)

struct PlayerDetailsView: View {
    @EnvironmentObject var state: AppState
    @State private var isDescExpanded = false

    var detail: YouTubeVideoDetail? { state.selectedVideoDetail }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            // Judul
            Text(detail?.snippet?.title ?? "Memuat judul video...")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white.opacity(0.95))

            // View, Date & Tombol Aksi
            HStack {
                HStack(spacing: 8) {
                    if let stats = detail?.statistics {
                        Text("\(stats.formattedViews) tayangan")
                    }
                    if let pub = detail?.snippet?.publishedAt {
                        Text("·")
                        Text(formatDate(pub))
                    }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

                Spacer()

                ActionButton(icon: "hand.thumbsup", label: detail?.statistics?.formattedLikes ?? "Suka")
                ActionButton(icon: "arrowshape.turn.up.right", label: "Bagikan")
                ActionButton(icon: "bookmark", label: "Simpan")
            }

            Divider().background(Color.white.opacity(0.1))

            // Channel Info
            HStack(spacing: 16) {
                ChannelAvatar(
                    initial: String(detail?.snippet?.channelTitle.prefix(1) ?? "?"),
                    size: 48
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(detail?.snippet?.channelTitle ?? "—")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Subscriber disembunyikan")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                SubscribeButton()
            }

            // Deskripsi
            if let desc = detail?.snippet?.description, !desc.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isDescExpanded ? desc : String(desc.prefix(250)) + (desc.count > 250 ? "..." : ""))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(4)

                    if desc.count > 250 {
                        Button(isDescExpanded ? "Lebih sedikit" : "Selengkapnya") {
                            withAnimation { isDescExpanded.toggle() }
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "FA2E5B"))
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(32)
        .frame(maxWidth: 1000) // Center it nicely on big screens
        .frame(maxWidth: .infinity)
    }

    private func formatDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        guard let d = f.date(from: iso) else { return iso }
        let rel = RelativeDateTimeFormatter()
        rel.locale = Locale(identifier: "id_ID")
        rel.unitsStyle = .full
        return rel.localizedString(for: d, relativeTo: Date())
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
    @State private var isHovered = false
    var body: some View {
        Button {} label: {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 12))
                Text(label).font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background {
                Capsule().fill(Color.white.opacity(isHovered ? 0.14 : 0.08))
                    .overlay { Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5) }
            }
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { isHovered = h } }
    }
}

struct SubscribeButton: View {
    @State private var subscribed = false
    var body: some View {
        Button { withAnimation(.spring(response: 0.25)) { subscribed.toggle() } } label: {
            Text(subscribed ? "✓ Disubscribe" : "Subscribe")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(subscribed ? .white.opacity(0.6) : .white)
                .padding(.horizontal, 18).padding(.vertical, 10)
                .background { Capsule().fill(subscribed ? Color.white.opacity(0.1) : Color.white.opacity(0.15)) }
        }.buttonStyle(.plain)
    }
}

