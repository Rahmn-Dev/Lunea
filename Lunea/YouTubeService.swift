import Foundation
import Combine
import SwiftUI
import Security

private enum LuneaKeychain {
    private static let service = "rahmn.Lunea"
    private static let account = "youtube-data-api-key"

    static func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func save(_ value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let identity: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let update: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(identity as CFDictionary, update as CFDictionary)
        if status == errSecSuccess { return true }
        guard status == errSecItemNotFound else { return false }

        var item = identity
        item[kSecValueData as String] = data
        return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
    }
}

// MARK: - YouTube API Service

@MainActor
class YouTubeService: ObservableObject {

    // ⚠️ Paste your YouTube Data API v3 key here
    static var apiKey: String = "YOUR_API_KEY_HERE"

    private let baseURL = "https://www.googleapis.com/youtube/v3"
    
    // MARK: - Search

    func search(query: String, maxResults: Int = 50, pageToken: String? = nil) async throws -> YouTubeSearchResponse {
        var components = URLComponents(string: "\(baseURL)/search")!
        var params: [URLQueryItem] = [
            .init(name: "part", value: "snippet"),
            .init(name: "q", value: query),
            .init(name: "maxResults", value: "\(maxResults)"),
            .init(name: "type", value: "video"),
            .init(name: "key", value: Self.apiKey),
            .init(name: "relevanceLanguage", value: "en"),
            .init(name: "regionCode", value: "US"),
        ]
        if let token = pageToken { params.append(.init(name: "pageToken", value: token)) }
        components.queryItems = params

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        try checkResponse(response)
        return try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
    }

    // MARK: - Trending / Home feed

    func fetchTrending(regionCode: String = "US", maxResults: Int = 20, pageToken: String? = nil) async throws -> YouTubeVideoListResponse {
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

    func fetchByCategory(categoryId: String, regionCode: String = "US", maxResults: Int = 20, pageToken: String? = nil) async throws -> YouTubeVideoListResponse {
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
        if http.statusCode == 429 {
            let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init) ?? 2
            throw YouTubeError.rateLimited(retryAfter)
        }
        if http.statusCode == 403 { throw YouTubeError.forbidden }
        if http.statusCode == 400 { throw YouTubeError.badRequest }
        if http.statusCode != 200 { throw YouTubeError.httpError(http.statusCode) }
    }

    enum YouTubeError: LocalizedError {
        case forbidden, badRequest, rateLimited(TimeInterval), httpError(Int)
        var errorDescription: String? {
            switch self {
            case .forbidden: return "The API key is invalid or its quota has been exceeded"
            case .badRequest: return "The request is invalid"
            case .rateLimited:
                return "YouTube search is temporarily limited or today's search allowance has been reached. It resets at midnight Pacific Time (around 2–3 PM Jakarta)."
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
    @Published var isLoadingMoreSearch = false
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
    private var searchRequestID = UUID()
    private var lastSearchRequestAt = Date.distantPast
    private var lastSearchPaginationAt = Date.distantPast
    private var searchCooldownUntil = Date.distantPast

    private struct SearchCacheEntry {
        let items: [YouTubeSearchItem]
        let details: [YouTubeVideoDetail]
        let nextPageToken: String?
        let storedAt: Date
    }
    private var searchCache: [String: SearchCacheEntry] = [:]

    init() {
        self.currentTheme = availableThemes[0]
        // Migrate keys saved by older builds that accidentally used an empty defaults key.
        let savedKey = LuneaKeychain.read()
            ?? UserDefaults.standard.string(forKey: keyStorageKey)
            ?? UserDefaults.standard.string(forKey: "")
        if let saved = savedKey, !saved.isEmpty {
            apiKey = saved
            YouTubeService.apiKey = saved
            UserDefaults.standard.set(saved, forKey: keyStorageKey)
            LuneaKeychain.save(saved)
        } else {
            showApiKeySheet = true
        }
    }

    func saveApiKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: keyStorageKey)
        LuneaKeychain.save(key)
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
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !isSearching else { return }
        NSApplication.shared.keyWindow?.makeFirstResponder(nil)

        let cacheKey = query.lowercased()
        let requestID = UUID()
        searchRequestID = requestID
        isSearchActive = true
        errorMessage = nil

        if selectedVideoId != nil && !isPlayerMinimized { isPlayerMinimized = true }

        if let cached = searchCache[cacheKey],
           Date().timeIntervalSince(cached.storedAt) < 86_400 {
            searchResults = cached.items
            searchResultDetails = cached.details
            searchNextPageToken = cached.nextPageToken
            return
        }

        isSearching = true
        defer {
            if searchRequestID == requestID { isSearching = false }
        }

        do {
            let res = try await fetchSearchPage(query: query)
            guard searchRequestID == requestID else { return }
            let details = try await orderedDetails(for: res.items)
            guard searchRequestID == requestID else { return }

            searchResults = res.items
            searchResultDetails = details
            searchNextPageToken = res.nextPageToken
            searchCache[cacheKey] = SearchCacheEntry(
                items: res.items,
                details: details,
                nextPageToken: res.nextPageToken,
                storedAt: Date()
            )
        } catch is CancellationError {
            return
        } catch {
            guard searchRequestID == requestID else { return }
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty,
              !isSearching,
              !isLoadingMoreSearch,
              let pageToken = searchNextPageToken else { return }

        isLoadingMoreSearch = true
        defer { isLoadingMoreSearch = false }

        do {
            let paginationGap = Date().timeIntervalSince(lastSearchPaginationAt)
            if paginationGap < 1.8 {
                try await Task.sleep(for: .seconds(1.8 - paginationGap))
            }
            lastSearchPaginationAt = Date()
            let res = try await fetchSearchPage(query: query, pageToken: pageToken)
            let details = try await orderedDetails(for: res.items)
            let existingItemIDs = Set(searchResults.compactMap(\.videoId))
            let existingDetailIDs = Set(searchResultDetails.map(\.id))
            searchResults.append(contentsOf: res.items.filter {
                guard let id = $0.videoId else { return false }
                return !existingItemIDs.contains(id)
            })
            searchResultDetails.append(contentsOf: details.filter { !existingDetailIDs.contains($0.id) })
            searchNextPageToken = res.nextPageToken

            searchCache[query.lowercased()] = SearchCacheEntry(
                items: searchResults,
                details: searchResultDetails,
                nextPageToken: searchNextPageToken,
                storedAt: Date()
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchSearchPage(query: String, pageToken: String? = nil) async throws -> YouTubeSearchResponse {
        let cooldown = searchCooldownUntil.timeIntervalSinceNow
        if cooldown > 0 {
            throw YouTubeService.YouTubeError.rateLimited(cooldown)
        }

        let elapsed = Date().timeIntervalSince(lastSearchRequestAt)
        if elapsed < 1.2 {
            try await Task.sleep(for: .seconds(1.2 - elapsed))
        }
        lastSearchRequestAt = Date()

        do {
            return try await service.search(query: query, pageToken: pageToken)
        } catch YouTubeService.YouTubeError.rateLimited(let retryAfter) {
            // A 429 can represent the granular daily search allowance. Repeating
            // the same request only wastes time and may intensify a short burst.
            searchCooldownUntil = Date().addingTimeInterval(max(60, retryAfter))
            throw YouTubeService.YouTubeError.rateLimited(max(60, retryAfter))
        }
    }

    private func orderedDetails(for items: [YouTubeSearchItem]) async throws -> [YouTubeVideoDetail] {
        let orderedIDs = items.compactMap(\.videoId)
        guard !orderedIDs.isEmpty else { return [] }
        for attempt in 0..<3 {
            do {
                let response = try await service.fetchVideoDetails(ids: orderedIDs)
                let byID = Dictionary(uniqueKeysWithValues: response.items.map { ($0.id, $0) })
                return orderedIDs.compactMap { byID[$0] }
            } catch YouTubeService.YouTubeError.rateLimited(let retryAfter) {
                let backoff = max(retryAfter, 1.5 * pow(2, Double(attempt)))
                searchCooldownUntil = Date().addingTimeInterval(backoff)
                if attempt == 2 { throw YouTubeService.YouTubeError.rateLimited(backoff) }
                try await Task.sleep(for: .seconds(backoff))
            }
        }
        return []
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
        searchRequestID = UUID()
        isSearching = false
        isLoadingMoreSearch = false
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
