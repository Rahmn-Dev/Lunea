import Foundation
import Combine
import SwiftUI

// MARK: - YouTube API Service

@MainActor
class YouTubeService: ObservableObject {

    // ⚠️ Paste your YouTube Data API v3 key here
    static var apiKey: String = "YOUR_API_KEY_HERE"

    private let baseURL = "https://www.googleapis.com/youtube/v3"
    
    // MARK: - Search

    func search(query: String, maxResults: Int = 20, pageToken: String? = nil) async throws -> YouTubeSearchResponse {
        var components = URLComponents(string: "\(baseURL)/search")!
        var params: [URLQueryItem] = [
            .init(name: "part", value: "snippet"),
            .init(name: "q", value: query),
            .init(name: "maxResults", value: "\(maxResults)"),
            .init(name: "type", value: "video"),
            .init(name: "key", value: Self.apiKey),
            .init(name: "relevanceLanguage", value: "id"),
        ]
        if let token = pageToken { params.append(.init(name: "pageToken", value: token)) }
        components.queryItems = params

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        try checkResponse(response)
        return try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
    }

    // MARK: - Trending / Home feed

    func fetchTrending(regionCode: String = "ID", maxResults: Int = 20, pageToken: String? = nil) async throws -> YouTubeVideoListResponse {
        var components = URLComponents(string: "\(baseURL)/videos")!
        var params: [URLQueryItem] = [
            .init(name: "part", value: "snippet,statistics,contentDetails"),
            .init(name: "chart", value: "mostPopular"),
            .init(name: "regionCode", value: regionCode),
            .init(name: "maxResults", value: "\(maxResults)"),
            .init(name: "key", value: Self.apiKey),
        ]
        if let token = pageToken { params.append(.init(name: "pageToken", value: token)) }
        components.queryItems = params
        
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        try checkResponse(response)
        return try JSONDecoder().decode(YouTubeVideoListResponse.self, from: data)
    }

    // MARK: - Video details (for stats)

    func fetchVideoDetails(ids: [String]) async throws -> YouTubeVideoListResponse {
        var components = URLComponents(string: "\(baseURL)/videos")!
        components.queryItems = [
            .init(name: "part", value: "snippet,statistics,contentDetails"),
            .init(name: "id", value: ids.joined(separator: ",")),
            .init(name: "key", value: Self.apiKey),
        ]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        try checkResponse(response)
        return try JSONDecoder().decode(YouTubeVideoListResponse.self, from: data)
    }

    // MARK: - Related videos

    func fetchRelated(videoId: String, maxResults: Int = 15) async throws -> YouTubeSearchResponse {
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            .init(name: "part", value: "snippet"),
            .init(name: "relatedToVideoId", value: videoId),
            .init(name: "type", value: "video"),
            .init(name: "maxResults", value: "\(maxResults)"),
            .init(name: "key", value: Self.apiKey),
        ]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        try checkResponse(response)
        return try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
    }

    // MARK: - Categories / suggestions

    func fetchByCategory(categoryId: String, regionCode: String = "ID", maxResults: Int = 20) async throws -> YouTubeVideoListResponse {
        var components = URLComponents(string: "\(baseURL)/videos")!
        components.queryItems = [
            .init(name: "part", value: "snippet,statistics,contentDetails"),
            .init(name: "chart", value: "mostPopular"),
            .init(name: "videoCategoryId", value: categoryId),
            .init(name: "regionCode", value: regionCode),
            .init(name: "maxResults", value: "\(maxResults)"),
            .init(name: "key", value: Self.apiKey),
        ]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        try checkResponse(response)
        return try JSONDecoder().decode(YouTubeVideoListResponse.self, from: data)
    }

    // MARK: - Error handling

    private func checkResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode == 403 { throw YouTubeError.forbidden }
        if http.statusCode == 400 { throw YouTubeError.badRequest }
        if http.statusCode != 200 { throw YouTubeError.httpError(http.statusCode) }
    }

    enum YouTubeError: LocalizedError {
        case forbidden, badRequest, httpError(Int)
        var errorDescription: String? {
            switch self {
            case .forbidden: return "API key tidak valid atau quota habis"
            case .badRequest: return "Request tidak valid"
            case .httpError(let code): return "HTTP Error \(code)"
            }
        }
    }
}

// MARK: - App State (ViewModel)

@MainActor
class AppState: ObservableObject {
    @Published var apiKey: String = "" {
        didSet { YouTubeService.apiKey = apiKey }
    }
    @Published var isPlayerMinimized = false
    @Published var isSearchActive = false
    @Published var trendingVideos: [YouTubeVideoDetail] = []
    @Published var searchResults: [YouTubeSearchItem] = []
    @Published var selectedVideoId: String? = nil
    @Published var selectedVideoDetail: YouTubeVideoDetail? = nil
    @Published var relatedVideos: [YouTubeSearchItem] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String? = nil
    @Published var searchQuery = ""
    @Published var selectedCategory = "Semua"
    @Published var showApiKeySheet = false
    @Published var nextPageToken: String? = nil

    let categories = ["Semua", "Musik", "Gaming", "Berita", "Olahraga", "Tech", "Komedi", "Film"]
    // YouTube category IDs mapping
    let categoryIds: [String: String] = [
        "Musik": "10", "Gaming": "20", "Berita": "25",
        "Olahraga": "17", "Tech": "28", "Komedi": "23", "Film": "1"
    ]

    private let service = YouTubeService()
    private let keyStorageKey = "watchtube_api_key"

    init() {
        // Load saved API key
        if let saved = UserDefaults.standard.string(forKey: keyStorageKey), !saved.isEmpty {
            apiKey = saved
            YouTubeService.apiKey = saved
        } else {
            showApiKeySheet = true
        }
    }

    func saveApiKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: keyStorageKey)
        showApiKeySheet = false
        Task { await loadHome() }
    }

    func loadHome() async {
        guard !apiKey.isEmpty && apiKey != "YOUR_API_KEY_HERE" else {
            showApiKeySheet = true; return
        }
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            if selectedCategory == "Semua" {
                            let res = try await service.fetchTrending()
                            trendingVideos = res.items
                            nextPageToken = res.nextPageToken // 🔥 Tambahkan ini agar loadMore bisa jalan
                        } else if let catId = categoryIds[selectedCategory] {
                            let res = try await service.fetchByCategory(categoryId: catId)
                            trendingVideos = res.items
                            nextPageToken = res.nextPageToken // 🔥 Tambahkan ini agar loadMore bisa jalan
                        }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    func loadMore() async {
            guard !isLoading && nextPageToken != nil else { return }
            isLoading = true
            do {
                let res = try await service.fetchTrending(pageToken: nextPageToken)
                trendingVideos.append(contentsOf: res.items)
                nextPageToken = res.nextPageToken
            } catch {
                print("❌ Gagal load lebih banyak:", error)
            }
            isLoading = false
        }

    func search() async {
            let query = searchQuery.trimmingCharacters(in: .whitespaces)
            guard !query.isEmpty else { return }
        NSApplication.shared.keyWindow?.makeFirstResponder(nil)
            
            // 🔥 KUNCI: Gerbang anti-spam HARUS ditaruh sebelum isSearching diubah jadi true!
            guard !isSearching else { return }
            
            isSearching = true
            isSearchActive = true
            errorMessage = nil
            
            // UX MAGIC: Jika player sedang layar penuh, otomatis minimize agar hasil search terlihat
            if selectedVideoId != nil && !isPlayerMinimized {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isPlayerMinimized = true
                }
            }
            
            do {
                let res = try await service.search(query: query)
                searchResults = res.items
                nextPageToken = res.nextPageToken
            } catch {
                errorMessage = error.localizedDescription
                print("❌ Search Error:", error)
            }
            isSearching = false
        }

    func selectVideo(_ videoId: String) async {
        NSApplication.shared.keyWindow?.makeFirstResponder(nil)
            // 🔥 KUNCI: Cek dulu apakah video yang diklik SAMA dengan yang sedang diputar.
            // Jika iya (dan sudah ada detailnya), cukup besarkan playernya lalu berhentikan fungsinya.
            if self.selectedVideoId == videoId && self.selectedVideoDetail != nil {
                self.isPlayerMinimized = false
                return
            }
            
            // BARU kita ganti ID-nya dan reset detail lama karena ini pasti video baru!
            self.selectedVideoId = videoId
            self.selectedVideoDetail = nil // Mengosongkan judul lama agar UI jadi "Memuat..."
            self.isPlayerMinimized = false
            
            do {
                let detailResponse = try await service.fetchVideoDetails(ids: [videoId])
                self.selectedVideoDetail = detailResponse.items.first
            } catch {
                self.errorMessage = error.localizedDescription
                print("❌ Gagal load detail video:", error)
            }
        }
    func closePlayer() {
            selectedVideoId = nil
            selectedVideoDetail = nil
            isPlayerMinimized = false
        }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        isSearchActive = false
       // selectedVideoId = nil
       // selectedVideoDetail = nil
    }

    var isShowingPlayer: Bool { selectedVideoId != nil }
    var displayVideos: [YouTubeVideoDetail] { trendingVideos }
}
