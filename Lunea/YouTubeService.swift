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

    func fetchByCategory(categoryId: String, regionCode: String = "ID", maxResults: Int = 20, pageToken: String? = nil) async throws -> YouTubeVideoListResponse {
        var components = URLComponents(string: "\(baseURL)/videos")!
        var params: [URLQueryItem] = [
            .init(name: "part", value: "snippet,statistics,contentDetails"),
            .init(name: "chart", value: "mostPopular"),
            .init(name: "videoCategoryId", value: categoryId),
            .init(name: "regionCode", value: regionCode),
            .init(name: "maxResults", value: "\(maxResults)"),
            .init(name: "key", value: Self.apiKey),
        ]
        if let pageToken { params.append(.init(name: "pageToken", value: pageToken)) }
        components.queryItems = params
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
            case .forbidden: return "The API key is invalid or its quota has been exceeded"
            case .badRequest: return "The request is invalid"
            case .httpError(let code): return "HTTP Error \(code)"
            }
        }
    }
}

// MARK: - App State (ViewModel)
struct AppTheme {
    let name: String
    let accentColor: Color
    let backgroundColor: Color
    let sidebarColor: Color
    let gradientColors: [Color] // 🔥 Palet warna untuk BackgroundOrbs
}

let availableThemes: [AppTheme] = [
    AppTheme(
        name: "Midnight Red",
        accentColor: Color(hex: "FA2E5B"),
        backgroundColor: Color(hex: "0A0A12"),
        sidebarColor: Color(hex: "12121A"),
        gradientColors: [Color(hex: "0A0A12"), Color(hex: "1A1A2E"), Color(hex: "16213E")]
    ),
    AppTheme(
        name: "Cyber Blue",
        accentColor: Color(hex: "00C8FF"),
        backgroundColor: Color(hex: "050A10"),
        sidebarColor: Color(hex: "0A121A"),
        gradientColors: [Color(hex: "050A10"), Color(hex: "0A1929"), Color(hex: "003366")]
    ),
    AppTheme(
        name: "Emerald Forest",
        accentColor: Color(hex: "00FF9D"),
        backgroundColor: Color(hex: "05100A"),
        sidebarColor: Color(hex: "0A1A12"),
        gradientColors: [Color(hex: "05100A"), Color(hex: "0A251A"), Color(hex: "004D2D")]
    )
]

@MainActor
class AppState: ObservableObject {
    
    
    @Published var apiKey: String = "" {
        didSet { YouTubeService.apiKey = apiKey }
    }
    @Published var currentTheme: AppTheme
    @Published var isPlayerMinimized = false
    @Published var isSearchActive = false
    @Published var trendingVideos: [YouTubeVideoDetail] = []
    @Published var searchResults: [YouTubeSearchItem] = []
    @Published var searchResultDetails: [YouTubeVideoDetail] = []
    @Published var selectedVideoId: String? = nil
    @Published var selectedVideoDetail: YouTubeVideoDetail? = nil
    @Published var relatedVideos: [YouTubeSearchItem] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String? = nil
    @Published var searchQuery = ""
    @Published var selectedCategory = "All"
    @Published var showApiKeySheet = false
    @Published var nextPageToken: String? = nil
    @Published var searchNextPageToken: String? = nil
    @Published var relatedVideoDetails: [YouTubeVideoDetail] = []
    
    let categories = ["All", "Music", "Gaming", "News", "Sports", "Tech", "Comedy", "Movies"]
    // YouTube category IDs mapping
    let categoryIds: [String: String] = [
        "Music": "10", "Gaming": "20", "News": "25",
        "Sports": "17", "Tech": "28", "Comedy": "23", "Movies": "1"
    ]

    private let service = YouTubeService()
    private let keyStorageKey = "lunea.youtubeDataAPIKey"
    private var homeRequestID = UUID()

    init() {
        self.currentTheme = availableThemes[0]
        // Migrate keys saved by older builds that accidentally used an empty defaults key.
        let savedKey = UserDefaults.standard.string(forKey: keyStorageKey)
            ?? UserDefaults.standard.string(forKey: "")
        if let saved = savedKey, !saved.isEmpty {
            apiKey = saved
            YouTubeService.apiKey = saved
            UserDefaults.standard.set(saved, forKey: keyStorageKey)
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
    
    func changeTheme(to theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.currentTheme = theme
        }
    }
    // Di dalam AppState, tambahkan method ini:
    func loadRelatedVideos(for videoId: String) async {
        do {
            let res = try await service.fetchRelated(videoId: videoId)
            // Ambil ID-nya, lalu fetch detail lengkap biar ada thumbnail medium + durasi
            let ids = res.items.compactMap { $0.videoId }
            if !ids.isEmpty {
                let details = try await service.fetchVideoDetails(ids: ids)
                // Keep related results separate from the home feed.
                self.relatedVideoDetails = details.items
            }
        } catch {
            guard let title = selectedVideoDetail?.snippet?.title, !title.isEmpty else { return }
            do {
                let fallback = try await service.search(query: title, maxResults: 15)
                let ids = fallback.items.compactMap(\.videoId).filter { $0 != videoId }
                guard !ids.isEmpty else { return }
                let details = try await service.fetchVideoDetails(ids: ids)
                relatedVideoDetails = details.items
            } catch {
                relatedVideoDetails = []
            }
        }
    }

    func loadHome() async {
        guard !apiKey.isEmpty && apiKey != "YOUR_API_KEY_HERE" else {
            showApiKeySheet = true; return
        }
        let requestID = UUID()
        homeRequestID = requestID
        let requestedCategory = selectedCategory
        isLoading = true
        defer {
            if homeRequestID == requestID { isLoading = false }
        }
        errorMessage = nil
        do {
            let response: YouTubeVideoListResponse
            if requestedCategory == "All" {
                response = try await service.fetchTrending()
            } else if let categoryId = categoryIds[requestedCategory] {
                response = try await service.fetchByCategory(categoryId: categoryId)
            } else {
                response = try await service.fetchTrending()
            }
            guard homeRequestID == requestID, selectedCategory == requestedCategory else { return }
            trendingVideos = response.items
            nextPageToken = response.nextPageToken
        } catch {
            guard homeRequestID == requestID else { return }
            errorMessage = error.localizedDescription
        }
    }
    func loadMore() async {
        guard !isLoading, let pageToken = nextPageToken else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let response: YouTubeVideoListResponse
            if selectedCategory == "All" {
                response = try await service.fetchTrending(pageToken: pageToken)
            } else if let categoryId = categoryIds[selectedCategory] {
                response = try await service.fetchByCategory(categoryId: categoryId, pageToken: pageToken)
            } else {
                return
            }
            let existing = Set(trendingVideos.map(\.id))
            trendingVideos.append(contentsOf: response.items.filter { !existing.contains($0.id) })
            nextPageToken = response.nextPageToken
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func search() async {
            let query = searchQuery.trimmingCharacters(in: .whitespaces)
            guard !query.isEmpty else { return }
        NSApplication.shared.keyWindow?.makeFirstResponder(nil)
            
            // 🔥 KUNCI: Gerbang anti-spam HARUS ditaruh sebelum isSearching diubah jadi true!
            guard !isSearching else { return }
            
            isSearching = true
            defer { isSearching = false }
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
                searchNextPageToken = res.nextPageToken
                let orderedIDs = res.items.compactMap(\.videoId)
                if !orderedIDs.isEmpty {
                    let details = try await service.fetchVideoDetails(ids: orderedIDs)
                    let detailsByID = Dictionary(uniqueKeysWithValues: details.items.map { ($0.id, $0) })
                    searchResultDetails = orderedIDs.compactMap { detailsByID[$0] }
                } else {
                    searchResultDetails = []
                }
            } catch {
                errorMessage = error.localizedDescription
                print("❌ Search Error:", error)
            }
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
            self.selectedVideoDetail = nil
            self.relatedVideoDetails = []
            self.isPlayerMinimized = false
            
            do {
                let detailResponse = try await service.fetchVideoDetails(ids: [videoId])
                self.selectedVideoDetail = detailResponse.items.first
                await loadRelatedVideos(for: videoId)
            } catch {
                self.errorMessage = error.localizedDescription
                print("❌ Failed to load video details:", error)
            }
        }
    func closePlayer() {
            selectedVideoId = nil
            selectedVideoDetail = nil
            relatedVideoDetails = []
            isPlayerMinimized = false
        }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        searchResultDetails = []
        searchNextPageToken = nil
        isSearchActive = false
       // selectedVideoId = nil
       // selectedVideoDetail = nil
    }

    var isShowingPlayer: Bool { selectedVideoId != nil }
    var displayVideos: [YouTubeVideoDetail] { trendingVideos }
}
