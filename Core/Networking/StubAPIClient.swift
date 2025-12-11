import Foundation

final class StubAPIClient: APIClient {
    // MARK: - Config

    private let delay: Double

    // MARK: - Demo IDs

    private let demoOwnerId1 = "11111111-1111-1111-1111-111111111111"
    private let demoOwnerId2 = "22222222-2222-2222-2222-222222222222"

    // MARK: - In-memory storage

    /// Зарегистрированные пользователи в рамках жизни StubAPIClient.
    private var accountsByEmail: [String: StubUser] = [:]

    private var apartments: [StubApartment]
    private var bookings: [StubBooking]

    // MARK: - Init

    init(delay: Double = AppConfig.stubDelaySeconds) {
        self.delay = delay

        self.apartments = [
            StubApartment(
                id: UUID().uuidString,
                ownerId: demoOwnerId2,
                address: "Budapest, Andrássy út 10",
                price: 75.0,
                info: [
                    "rooms": "2",
                    "beds": "2",
                    "wifi": "yes",
                    "text_desc": "Cozy flat near city center, perfect for weekend trips."
                ]
            ),
            StubApartment(
                id: UUID().uuidString,
                ownerId: demoOwnerId1,
                address: "Budapest, Bartók Béla út 5",
                price: 55.0,
                info: [
                    "rooms": "1",
                    "beds": "1",
                    "wifi": "yes",
                    "text_desc": "Small budget studio, great for solo travellers."
                ]
            ),
            StubApartment(
                id: UUID().uuidString,
                ownerId: demoOwnerId2,
                address: "Vienna, Mariahilfer Straße 20",
                price: 110.0,
                info: [
                    "rooms": "2",
                    "beds": "3",
                    "balcony": "yes",
                    "text_desc": "Spacious apartment in Vienna shopping district."
                ]
            ),
            StubApartment(
                id: UUID().uuidString,
                ownerId: demoOwnerId2,
                address: "Prague, Karlova 8",
                price: 130.0,
                info: [
                    "rooms": "3",
                    "beds": "4",
                    "view": "Old Town",
                    "text_desc": "Old Town flat with a beautiful view."
                ]
            )
        ]

        let iso = ISO8601DateFormatter()
        self.bookings = [
            .init(
                id: UUID().uuidString,
                apId: apartments[0].id,
                userId: demoOwnerId1, // не обязательно существующий аккаунт — может быть "другой гость"
                from: iso.date(from: "2025-12-01T15:00:00Z")!,
                to:   iso.date(from: "2025-12-07T11:00:00Z")!
            ),
            .init(
                id: UUID().uuidString,
                apId: apartments[2].id,
                userId: demoOwnerId1,
                from: iso.date(from: "2025-12-12T10:00:00Z")!,
                to:   iso.date(from: "2025-12-15T09:00:00Z")!
            )
        ]
    }

    // MARK: - login / register

    func login(email: String, password: String) async throws -> LoginSuccessDTO {
        try await sleep()

        let normalizedEmail = normalizeEmail(email)

        guard
            let user = accountsByEmail[normalizedEmail],
            user.password == password
        else {
            throw APIError.badRequest(message: "invalid credentials")
        }

        return LoginSuccessDTO(status: "logged_in", user_id: user.id)
    }

    func register(email: String, password: String) async throws {
        try await sleep()
        
        let normalizedEmail = normalizeEmail(email)
        
        guard isValidEmail(normalizedEmail) else {
            throw APIError.badRequest(message: "invalid email")
        }
        
        guard password.count >= 4 else {
            throw APIError.badRequest(message: "invalid password length")
        }
        
        guard accountsByEmail[normalizedEmail] == nil else {
            throw APIError.conflict(message: "email already in use")
        }

        let newUser = StubUser(
            id: UUID().uuidString,
            email: normalizedEmail,
            password: password
        )
        accountsByEmail[normalizedEmail] = newUser
        // register возвращает Void – этого достаточно, дальше UI может вызвать login
    }

    // MARK: - GET /apartments?city=&rooms=&beds=

    func searchApartments(city: String?, rooms: Int?, beds: Int?) async throws -> ApartmentsListDTO {
        try await sleep()

        let filtered = apartments.filter { ap in
            // city — как на бэке: по первому слову адреса
            let okCity: Bool = {
                guard let c = city?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !c.isEmpty else { return true }
                let addrCity = ap.address
                    .split(separator: ",")
                    .first?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return addrCity.caseInsensitiveCompare(c) == .orderedSame
            }()

            let okRooms: Bool = {
                guard let r = rooms else { return true }
                let rInfo = Int(ap.info["rooms"] ?? "") ?? -1
                return rInfo == r
            }()

            let okBeds: Bool = {
                guard let b = beds else { return true }
                let bInfo = Int(ap.info["beds"] ?? "") ?? -1
                return bInfo == b
            }()

            return okCity && okRooms && okBeds
        }

        let items = filtered.map {
            ShortApartmentResponse(
                id: $0.id,
                owner_id: $0.ownerId,
                address: $0.address,
                price: $0.price
            )
        }
        return ApartmentsListDTO(count: items.count, apartments: items)
    }

    // MARK: - GET /apartments/{id}

    func apartmentDetails(id: String) async throws -> ApartmentByIdDTO {
        try await sleep()

        guard let ap = apartments.first(where: { $0.id == id }) else {
            throw APIError.badRequest(message: "apartment not found")
        }

        let medium = MediumApartmentResponse(
            id: ap.id,
            owner_id: ap.ownerId,
            address: ap.address,
            price: ap.price,
            info: ap.info
        )

        let ranges = bookings
            .filter { $0.apId == ap.id }
            .map { BookingRangeDTO(from: $0.from, to: $0.to) }

        return ApartmentByIdDTO(apartment: medium, bookings: ranges)
    }

    // MARK: - GET /owners/{id}/apartments

    func apartmentsByOwner(ownerId: String) async throws -> OwnerApartmentsDTO {
        try await sleep()

        let owned = apartments.filter { $0.ownerId == ownerId }

        let items = owned.map { ap -> FullApartmentResponse in
            let bs = bookings
                .filter { $0.apId == ap.id }
                .map {
                    ShortBookingResponse(
                        id: $0.id,
                        user_id: $0.userId,
                        time_from: $0.from,
                        time_to: $0.to
                    )
                }

            return FullApartmentResponse(
                id: ap.id,
                owner_id: ap.ownerId,
                address: ap.address,
                price: ap.price,
                info: ap.info,
                bookings: bs
            )
        }

        return OwnerApartmentsDTO(count: items.count, apartments: items)
    }

    // MARK: - GET /users/{id}/bookings

    func bookingsByUser(userId: String) async throws -> BookingsListDTO {
        try await sleep()

        let bs = bookings
            .filter { $0.userId == userId }
            .map {
                BookingResponse(
                    id: $0.id,
                    user_id: $0.userId,
                    ap_id: $0.apId,
                    address: apAddress(for: $0.apId),
                    time_from: $0.from,
                    time_to: $0.to
                )
            }

        return BookingsListDTO(count: bs.count, bookings: bs)
    }

    // MARK: - POST /apartments

    func createApartment(_ dto: ApartmentCreateDTO) async throws -> MediumApartmentResponse {
        try await sleep()

        if apartments.contains(where: { $0.address == dto.address }) {
            throw APIError.conflict(message: "apartment with this address is already registered")
        }

        if let info = dto.info {
            if let rooms = info["rooms"], Int(rooms) ?? -1 < 0 {
                throw APIError.badRequest(message: "invalid request form, beds & rooms must be positive integers")
            }
            if let beds = info["beds"], Int(beds) ?? -1 < 0 {
                throw APIError.badRequest(message: "invalid request form, beds & rooms must be positive integers")
            }
        }

        let ap = StubApartment(
            id: UUID().uuidString,
            ownerId: dto.owner_id,
            address: dto.address,
            price: dto.price,
            info: dto.info ?? [:]
        )
        apartments.append(ap)

        return MediumApartmentResponse(
            id: ap.id,
            owner_id: ap.ownerId,
            address: ap.address,
            price: ap.price,
            info: dto.info ?? [:]
        )
    }

    // MARK: - PATCH /apartments/{id}

    func updateApartment(id: String, dto: ApartmentUpdateDTO) async throws {
        try await sleep()

        guard let index = apartments.firstIndex(where: { $0.id == id }) else {
            throw APIError.badRequest(message: "apartment not found")
        }

        if apartments[index].ownerId != dto.owner_id {
            throw APIError.badRequest(message: "forbidden request")
        }

        if let info = dto.info {
            if let rooms = info["rooms"], Int(rooms) ?? -1 < 0 {
                throw APIError.badRequest(message: "invalid request form, beds & rooms must be positive integers")
            }
            if let beds = info["beds"], Int(beds) ?? -1 < 0 {
                throw APIError.badRequest(message: "invalid request form, beds & rooms must be positive integers")
            }
        }

        if let price = dto.price {
            apartments[index].price = price
        }

        if let newInfo = dto.info {
            apartments[index].info = newInfo
        }
    }

    // MARK: - POST /bookings

    func bookApartment(_ dto: BookingCreateDTO) async throws -> BookingResponse {
        try await sleep()

        guard let ap = apartments.first(where: { $0.id == dto.apartment_id }) else {
            throw APIError.badRequest(message: "apartment not found")
        }

        for b in bookings where b.apId == dto.apartment_id {
            if !(dto.time_to <= b.from || dto.time_from >= b.to) {
                throw APIError.conflict(message: "time overlap with other booking")
            }
        }

        let new = StubBooking(
            id: UUID().uuidString,
            apId: dto.apartment_id,
            userId: dto.user_id,
            from: dto.time_from,
            to: dto.time_to
        )
        bookings.append(new)

        return BookingResponse(
            id: new.id,
            user_id: dto.user_id,
            ap_id: dto.apartment_id,
            address: ap.address,
            time_from: dto.time_from,
            time_to: dto.time_to
        )
    }

    // MARK: - helpers

    private func sleep() async throws {
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    private func apAddress(for id: String) -> String {
        apartments.first(where: { $0.id == id })?.address ?? "Unknown address"
    }
    
    private func normalizeEmail(_ email: String) -> String {
        email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func isValidEmail(_ email: String) -> Bool {
        // Очень простая проверка, для stub более чем достаточно
        return email.contains("@") && email.contains(".")
    }

    // MARK: - local models

    private struct StubApartment {
        var id: String
        var ownerId: String
        var address: String
        var price: Double
        var info: [String: String]
    }

    private struct StubBooking {
        let id: String
        let apId: String
        let userId: String
        let from: Date
        let to: Date
    }

    private struct StubUser {
        let id: String
        let email: String
        let password: String
    }
}
