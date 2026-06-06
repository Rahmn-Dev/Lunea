import SwiftUI

// MARK: - Real Video Card (from API)

struct VideoCard: View {
    let video: YouTubeVideoDetail
    let action: () -> Void
    @State private var isHovered = false

    var optimizedThumbnail: String {
        video.snippet?.thumbnails.medium?.url ??
        video.snippet?.thumbnails.high?.url ?? ""
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                // --- THUMBNAIL AREA ---
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: URL(string: optimizedThumbnail)) { phase in
                        if let img = phase.image {
                            img.resizable()
                               .aspectRatio(16/9, contentMode: .fill)
                        } else {
                            Rectangle().fill(Color.white.opacity(0.05))
                        }
                    }
                    .aspectRatio(16/9, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    // Durasi
                    if let dur = video.contentDetails?.formattedDuration, !dur.isEmpty {
                        Text(dur)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.black.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .padding(8)
                    }

                    // Hover Play Button (Ringan, Tanpa Material)
                    if isHovered {
                        Color.black.opacity(0.3)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color(hex: "FA2E5B")) // Aksen merah Lunea
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // Rata tengah
                    }
                }
                .padding([.top, .horizontal], 10) // Padding di dalam card

                // --- TEXT INFO AREA ---
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.snippet?.title ?? "")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(2)
                        .frame(height: 36, alignment: .topLeading) // Kunci presisi tinggi

                    Text(video.snippet?.channelTitle ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if let v = video.statistics?.formattedViews { Text(v + " tayangan") }
                        if let pub = video.snippet?.publishedAt {
                            Text("·")
                            Text(relativeDate(pub))
                        }
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .contentShape(Rectangle())
            .background {
                // UI "Putih Bening" ala Search Result
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(isHovered ? 0.08 : 0.04))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(isHovered ? 0.18 : 0.08), lineWidth: 0.5)
                    }
            }
            // 🔥 KUNCI SMOOTH: Tidak ada shadow, tidak ada scaleEffect, pakai easeInOut ringan
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private func relativeDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        guard let d = f.date(from: iso) else { return "" }
        let rel = RelativeDateTimeFormatter()
        rel.locale = Locale(identifier: "id_ID")
        rel.unitsStyle = .abbreviated
        return rel.localizedString(for: d, relativeTo: Date())
    }
}

// MARK: - Hero Card (Super Smooth 60FPS)

struct HeroFeaturedCard: View {
    let video: YouTubeVideoDetail
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: URL(string: video.snippet?.thumbnails.best?.url ?? "")) { phase in
                        if let img = phase.image {
                            img.resizable()
                               .aspectRatio(16/9, contentMode: .fill)
                        } else {
                            Rectangle().fill(Color.white.opacity(0.05))
                        }
                    }
                    .frame(height: 280)
                    .clipped()
                    
                    LinearGradient(colors: [.clear, Color.black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 120)
                        .frame(maxHeight: .infinity, alignment: .bottom)

                    if isHovered {
                        Color.black.opacity(0.2)
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "FA2E5B"))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    if let dur = video.contentDetails?.formattedDuration {
                        Text(dur)
                            .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.black.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .padding(16)
                    }
                }
                .overlay(alignment: .topLeading) {
                    Text("Top Trending")
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color(hex: "FA2E5B").opacity(0.8))
                        .clipShape(Capsule())
                        .padding(16)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(video.snippet?.title ?? "")
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        Text(video.snippet?.channelTitle ?? "")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        if let v = video.statistics?.formattedViews {
                            Text("·  \(v) tayangan")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
            }
            .contentShape(Rectangle())
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(isHovered ? 0.2 : 0.1), lineWidth: 0.5)
            }
            // 🔥 KUNCI SMOOTH: Hanya pakai animasi easeInOut ringan
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
// MARK: - Search Result Card

struct SearchResultCard: View {
    let item: YouTubeSearchItem
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: item.snippet.thumbnails.medium?.url ?? "")) { img in
                img.resizable().aspectRatio(16/9, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(hex: "1a1a3e"))
                    .overlay { ProgressView().tint(.white.opacity(0.3)) }
            }
            .frame(width: 160, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(alignment: .topLeading) {
                if item.isLive {
                    Text("● LIVE").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Color.red.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(item.snippet.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                Text(item.snippet.channelTitle)
                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.45))
                Text(item.formattedDate)
                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.3))
                Text(item.snippet.description)
                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.35))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "play.circle.fill")
                .font(.system(size: 28)).foregroundColor(isHovered ? Color(hex: "FA2E5B") : .white.opacity(0.2))
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(isHovered ? 0.1 : 0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(isHovered ? 0.18 : 0.1), lineWidth: 0.5)
                }
        }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let icon: String
    let title: String
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(.white.opacity(0.55))
                Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(.white.opacity(0.92))
            }
            Spacer()
            if let action {
                Button("Lihat semua", action: action)
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.4)).buttonStyle(.plain)
            }
        }
    }
}
