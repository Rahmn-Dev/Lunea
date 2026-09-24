import SwiftUI
import AppKit

final class ThumbnailCache {
    static let shared = ThumbnailCache()
    let images: NSCache<NSURL, NSImage> = {
        let cache = NSCache<NSURL, NSImage>()
        cache.countLimit = 140
        cache.totalCostLimit = 96 * 1024 * 1024
        return cache
    }()
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    @State private var loadedImage: NSImage?

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let loadedImage {
                content(Image(nsImage: loadedImage))
            } else {
                placeholder()
                    .task(id: url) { await load() }
            }
        }
    }

    private func load() async {
        guard let url else { return }
        if let cached = ThumbnailCache.shared.images.object(forKey: url as NSURL) {
            loadedImage = cached
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled,
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let image = NSImage(data: data) else { return }
            ThumbnailCache.shared.images.setObject(image, forKey: url as NSURL, cost: data.count)
            loadedImage = image
        } catch {
            // Keep the lightweight placeholder when loading fails.
        }
    }
}

// MARK: - Real Video Card (from API)

struct VideoCard: View {
    @ObservedObject var state: AppState
    let video: YouTubeVideoDetail
    let action: () -> Void
    @State private var isHovered = false

    var optimizedThumbnail: String {
        video.snippet?.thumbnails.medium?.url ??
        video.snippet?.thumbnails.high?.url ?? ""
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                ZStack(alignment: .bottomTrailing) {
                    CachedAsyncImage(url: URL(string: optimizedThumbnail)) { image in
                        image.resizable().aspectRatio(16/9, contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(Color.white.opacity(0.05))
                    }
                    .aspectRatio(16/9, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    if let dur = video.contentDetails?.formattedDuration, !dur.isEmpty {
                        Text(dur)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.black.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .padding(8)
                    }

                    Color.white.opacity(isHovered ? 0.08 : 0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.snippet?.title ?? "")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(2)
                        .frame(height: 34, alignment: .topLeading)

                    Text(video.snippet?.channelTitle ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if let v = video.statistics?.formattedViews { Text(v + " views") }
                        if let pub = video.snippet?.publishedAt {
                            Text("·")
                            Text(relativeDate(pub))
                        }
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
                }
            }
            .padding(8)
            .background(Color.white.opacity(isHovered ? 0.075 : 0), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(Color.white.opacity(isHovered ? 0.16 : 0), lineWidth: 0.7)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.14), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private func relativeDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        guard let d = f.date(from: iso) else { return "" }
        let rel = RelativeDateTimeFormatter()
        rel.locale = Locale(identifier: "en_US")
        rel.unitsStyle = .abbreviated
        return rel.localizedString(for: d, relativeTo: Date())
    }
}

// MARK: - Hero Card (Super Smooth 60FPS)

struct HeroFeaturedCard: View {
    @ObservedObject var state: AppState
    let video: YouTubeVideoDetail
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                CachedAsyncImage(url: URL(string: video.snippet?.thumbnails.best?.url ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.white.opacity(0.05))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.12), .black.opacity(0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 7) {
                    Spacer(minLength: 0)

                    Text(state.selectedCategory == "All" ? "FEATURED" : state.selectedCategory.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(state.currentTheme.accentColor)

                    Text(video.snippet?.title ?? "")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 10) {
                        Label("Play", systemImage: "play.fill")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 15)
                            .frame(height: 36)
                            .foregroundStyle(.white)
                            .background(Color.white.opacity(0.18), in: Capsule())

                        Text(video.snippet?.channelTitle ?? "")
                        if let views = video.statistics?.formattedViews { Text("· \(views) views") }
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 48)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(isHovered ? 0.045 : 0))
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(isHovered ? 0.2 : 0.1), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeOut(duration: 0.14), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

struct CompactVideoRow: View {
    @ObservedObject var state: AppState
    let video: YouTubeVideoDetail
    @State private var isHovered = false

    var body: some View {
        Button { Task { await state.selectVideo(video.id) } } label: {
            HStack(spacing: 11) {
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
                            .background(Color.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 3))
                            .padding(4)
                    }
                }
                .frame(width: 112, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 9))

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.snippet?.title ?? "")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                    Text(video.snippet?.channelTitle ?? "")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.42))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(7)
            .background(Color.white.opacity(isHovered ? 0.09 : 0.025), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(isHovered ? 0.15 : 0), lineWidth: 0.6)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.13), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

struct ShortVideoCard: View {
    @ObservedObject var state: AppState
    let video: YouTubeVideoDetail

    var body: some View {
        Button { Task { await state.selectVideo(video.id) } } label: {
            VStack(alignment: .leading, spacing: 7) {
                ZStack(alignment: .bottomTrailing) {
                    CachedAsyncImage(url: URL(string: video.snippet?.thumbnails.high?.url ?? "")) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(Color.white.opacity(0.05))
                    }
                    if let duration = video.contentDetails?.formattedDuration {
                        Text(duration)
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(Color.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 3))
                            .padding(6)
                    }
                }
                .frame(width: 142, height: 196)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 13))

                Text(video.snippet?.title ?? "")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
                    .frame(width: 142, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
// MARK: - Search Result Card

struct SearchResultCard: View {
    @ObservedObject var state: AppState
    let item: YouTubeSearchItem
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: URL(string: item.snippet.thumbnails.medium?.url ?? "")) { image in
                image.resizable().aspectRatio(16/9, contentMode: .fill)
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
                .font(.system(size: 28)).foregroundColor(isHovered ? state.currentTheme.accentColor : .white.opacity(0.2))
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

struct SearchDetailResultCard: View {
    @ObservedObject var state: AppState
    let video: YouTubeVideoDetail
    @State private var isHovered = false

    var body: some View {
        Button { Task { await state.selectVideo(video.id) } } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    CachedAsyncImage(url: URL(string: video.snippet?.thumbnails.medium?.url ?? "")) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(Color.white.opacity(0.05))
                    }

                    if let duration = video.contentDetails?.formattedDuration, !duration.isEmpty {
                        Text(duration)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 3)
                            .background(Color.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 4))
                            .padding(6)
                    }
                }
                .frame(width: 190, height: 107)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 11))

                VStack(alignment: .leading, spacing: 6) {
                    Text(video.snippet?.title ?? "")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.94))
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(video.snippet?.channelTitle ?? "")
                        if let views = video.statistics?.formattedViews { Text("· \(views) views") }
                        if let published = video.snippet?.publishedAt { Text("· \(relativeDate(published))") }
                    }
                    .font(.system(size: 10.5))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)

                    Text(video.snippet?.description ?? "")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.38))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.top, 4)
            }
            .padding(9)
            .contentShape(Rectangle())
            .background(Color.white.opacity(isHovered ? 0.055 : 0), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private func relativeDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: iso) else { return "" }
        let relative = RelativeDateTimeFormatter()
        relative.locale = Locale(identifier: "en_US")
        relative.unitsStyle = .abbreviated
        return relative.localizedString(for: date, relativeTo: Date())
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
                Button("View all", action: action)
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.4)).buttonStyle(.plain)
            }
        }
    }
}
