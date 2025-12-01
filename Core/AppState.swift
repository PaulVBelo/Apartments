import Foundation
import SwiftData

enum SearchMode: String, Codable {case builder, results}

struct SearchFilter: Codable, Equatable {
    var city: String? = nil
    var rooms: Int? = nil
    var beds: Int? = nil
}

struct SearchSession: Codable, Equatable {
    var mode: SearchMode = .builder
    var filter = SearchFilter()
    var pageSize: Int = 30
    var priceMin: Double? = nil
    var priceMax: Double? = nil
}

final class AppState: ObservableObject {
    static let shared = AppState()
    private init() {
        let baseClient: APIClient = RealAPIClient()

        if let container = try? ModelContainer(for: APICacheEntry.self) {
            self.cacheContainer = container
            self.api = CachedClientWrapper(client: baseClient, container: container)
        } else {
            self.cacheContainer = nil
            self.api = baseClient
        }
    }

    // GLOBALS
    @Published var userId: String = ""
    @Published var search = SearchSession()

    // API
    private(set) var api: APIClient
    private let cacheContainer: ModelContainer?
}
