import Foundation
import SwiftData

final class CachedClientWrapper: APIClient {
    private let client: APIClient
    private let cache: CacheStore

    init(client: APIClient, container: ModelContainer) {
        self.client = client
        self.cache = CacheStore(
            context: ModelContext(container),
            ttl: AppConfig.cacheTTLSeconds
        )
    }
    
    private func cachedCall<T: Codable>(
        method: String,
        args: [String: Any?],
        fetch: @escaping () async throws -> T
    ) async throws -> T {
        let key = await cache.key(args, method: method)

        if let saved: T = await cache.load(key, as: T.self) {
            return saved
        }

        let fresh = try await fetch()
        await cache.store(key, object: fresh)
        return fresh
    }
    
    func searchApartments(city: String?, rooms: Int?, beds: Int?) async throws -> ApartmentsListDTO {
        try await cachedCall(
            method: "searchApartments",
            args: ["city": city, "rooms": rooms, "beds": beds]
        ) { [client] in
            try await client.searchApartments(city: city, rooms: rooms, beds: beds)
        }
    }

    func apartmentDetails(id: String) async throws -> ApartmentByIdDTO {
        try await client.apartmentDetails(id: id)
    }

    func apartmentsByOwner(ownerId: String) async throws -> OwnerApartmentsDTO {
        try await cachedCall(
            method: "apartmentsByOwner",
            args: ["ownerId": ownerId]
        ) { [client] in
            try await client.apartmentsByOwner(ownerId: ownerId)
        }
    }

    func bookingsByUser(userId: String) async throws -> BookingsListDTO {
        try await cachedCall(
            method: "bookingsByUser",
            args: ["userId": userId]
        ) { [client] in
            try await client.bookingsByUser(userId: userId)
        }
    }
    
    func login(email: String, password: String) async throws -> LoginSuccessDTO {
        try await client.login(email: email, password: password)
    }

    func register(email: String, password: String) async throws {
        try await client.register(email: email, password: password)
    }

    func createApartment(_ dto: ApartmentCreateDTO) async throws -> MediumApartmentResponse {
        try await client.createApartment(dto)
    }

    func updateApartment(id: String, dto: ApartmentUpdateDTO) async throws {
        try await client.updateApartment(id: id, dto: dto)
    }

    func bookApartment(_ dto: BookingCreateDTO) async throws -> BookingResponse {
        try await client.bookApartment(dto)
    }
}


extension CachedClientWrapper {
    // Сброс всех результатов searchApartments(...)
    func invalidateSearch() async {
        await cache.invalidate(prefix: "searchApartments")
    }

    // Сброс всех apartmentDetails(...)
    func invalidateApartmentDetails() async {
        await cache.invalidate(prefix: "apartmentDetails")
    }

    // Сброс всех apartmentsByOwner(...)
    func invalidateOwnerApartments() async {
        await cache.invalidate(prefix: "apartmentsByOwner")
    }

    // Сброс всех bookingsByUser(...)
    func invalidateBookings() async {
        await cache.invalidate(prefix: "bookingsByUser")
    }

    // Полный сброс
    func invalidateAllCache() async {
        await cache.invalidateAll()
    }
}
