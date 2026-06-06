import SwiftUI

// MARK: - YouTube API Models

struct YouTubeSearchResponse: Codable {
    let items: [YouTubeSearchItem]
    let nextPageToken: String?
    let pageInfo: PageInfo?
}

struct PageInfo: Codable {
    let totalResults: Int
    let resultsPerPage: Int
}

struct YouTubeSearchItem: Codable, Identifiable {
    var id: String { snippet.publishedAt + (videoId ?? UUID().uuidString) }
    let kind: String?
    let etag: String?
    let itemId: ItemId
    let snippet: Snippet

    var videoId: String? { itemId.videoId }
    var channelId: String? { itemId.channelId }
    var playlistId: String? { itemId.playlistId }

    enum CodingKeys: String, CodingKey {
        case kind, etag, snippet
        case itemId = "id"
    }

    struct ItemId: Codable {
        let kind: String?
        let videoId: String?
        let channelId: String?
        let playlistId: String?
    }

    struct Snippet: Codable {
        let publishedAt: String
        let channelId: String
        let title: String
        let description: String
        let thumbnails: Thumbnails
        let channelTitle: String
        let liveBroadcastContent: String?
    }

    struct Thumbnails: Codable {
        let `default`: Thumbnail?
        let medium: Thumbnail?
        let high: Thumbnail?
        let standard: Thumbnail?
        let maxres: Thumbnail?

        var best: Thumbnail? { maxres ?? standard ?? high ?? medium ?? `default` }
    }

    struct Thumbnail: Codable {
        let url: String
        let width: Int?
        let height: Int?
    }

    var isLive: Bool { snippet.liveBroadcastContent == "live" }
    var isUpcoming: Bool { snippet.liveBroadcastContent == "upcoming" }

    var formattedDate: String {
        let iso = ISO8601DateFormatter()
        guard let date = iso.date(from: snippet.publishedAt) else { return snippet.publishedAt }
        let rel = RelativeDateTimeFormatter()
        rel.locale = Locale(identifier: "id_ID")
        rel.unitsStyle = .full
        return rel.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Video Detail

struct YouTubeVideoDetail: Codable, Identifiable {
    let id: String
    let snippet: Snippet?
    let statistics: Statistics?
    let contentDetails: ContentDetails?

    struct Snippet: Codable {
        let title: String
        let description: String
        let channelTitle: String
        let channelId: String
        let publishedAt: String
        let thumbnails: YouTubeSearchItem.Thumbnails
        let tags: [String]?
        let liveBroadcastContent: String?
    }

    struct Statistics: Codable {
        let viewCount: String?
        let likeCount: String?
        let commentCount: String?

        var formattedViews: String {
            guard let v = viewCount, let n = Int(v) else { return "—" }
            if n >= 1_000_000 { return String(format: "%.1fM", Double(n)/1_000_000) }
            if n >= 1_000 { return String(format: "%.1fK", Double(n)/1_000) }
            return "\(n)"
        }

        var formattedLikes: String {
            guard let l = likeCount, let n = Int(l) else { return "—" }
            if n >= 1_000_000 { return String(format: "%.1fM", Double(n)/1_000_000) }
            if n >= 1_000 { return String(format: "%.1fK", Double(n)/1_000) }
            return "\(n)"
        }
    }

    struct ContentDetails: Codable {
        let duration: String? // ISO 8601 duration

        var formattedDuration: String {
            guard let d = duration else { return "" }
            // Parse PT1H2M3S
            var h = 0, m = 0, s = 0
            var num = ""
            for ch in d {
                if ch.isNumber { num += String(ch) }
                else if ch == "H" { h = Int(num) ?? 0; num = "" }
                else if ch == "M" { m = Int(num) ?? 0; num = "" }
                else if ch == "S" { s = Int(num) ?? 0; num = "" }
            }
            if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
            return String(format: "%d:%02d", m, s)
        }
    }
}

struct YouTubeVideoListResponse: Codable {
    let items: [YouTubeVideoDetail]
}

// MARK: - Sidebar navigation items

struct NavItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let key: String
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6: (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8: (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255,
                  blue: Double(b)/255, opacity: Double(a)/255)
    }
}
