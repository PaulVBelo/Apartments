import Foundation

final class RealAPIClient: APIClient {

    // MARK: - Private

    private let authBaseURL: URL
    private let bookingBaseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Init

    init(
        authBaseURL: URL = AppConfig.authBaseURL,
        bookingBaseURL: URL = AppConfig.bookingBaseURL,
        session: URLSession = .shared
    ) {
        self.authBaseURL = authBaseURL
        self.bookingBaseURL = bookingBaseURL

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        self.session = session
    }

    // MARK: - APIClient

    // ---------- AUTH ----------

    func login(email: String, password: String) async throws -> LoginSuccessDTO {
        let url = authBaseURL.appendingPathComponent("auth/login")
        let body = LoginRequest(email: email, password: password)

        let (data, response) = try await request(
            url: url,
            method: "POST",
            body: body,
            logLabel: "POST /auth/login"
        )

        switch response.statusCode {
        case 200:
            return try decode(LoginSuccessDTO.self, from: data)
        case 400, 409, 500...599:
            throw mapError(status: response.statusCode, data: data)
        default:
            throw APIError.unknownStatus(response.statusCode)
        }
    }

    func register(email: String, password: String) async throws {
        let url = authBaseURL.appendingPathComponent("auth/register")
        let body = RegisterRequest(email: email, password: password)

        let (data, response) = try await request(
            url: url,
            method: "POST",
            body: body,
            logLabel: "POST /auth/register"
        )

        switch response.statusCode {
        case 201:
            return
        case 400, 409, 500...599:
            throw mapError(status: response.statusCode, data: data)
        default:
            throw APIError.unknownStatus(response.statusCode)
        }
    }

    // ---------- CACHABLE GET ----------

    func searchApartments(city: String?, rooms: Int?, beds: Int?) async throws -> ApartmentsListDTO {
        var components = URLComponents(
            url: bookingBaseURL.appendingPathComponent("apartments"),
            resolvingAgainstBaseURL: false
        )!

        var query: [URLQueryItem] = []
        if let city = city, !city.isEmpty {
            query.append(URLQueryItem(name: "city", value: city))
        }
        if let rooms = rooms {
            query.append(URLQueryItem(name: "rooms", value: String(rooms)))
        }
        if let beds = beds {
            query.append(URLQueryItem(name: "beds", value: String(beds)))
        }
        if !query.isEmpty {
            components.queryItems = query
        }

        let url = components.url!
        let (data, response) = try await request(
            url: url,
            method: "GET",
            body: Optional<LoginRequest>.none as LoginRequest?,
            logLabel: "GET /apartments"
        )

        switch response.statusCode {
        case 200:
            return try decode(ApartmentsListDTO.self, from: data)
        case 400, 409, 500...599:
            throw mapError(status: response.statusCode, data: data)
        default:
            throw APIError.unknownStatus(response.statusCode)
        }
    }

    func apartmentDetails(id: String) async throws -> ApartmentByIdDTO {
        let url = bookingBaseURL.appendingPathComponent("apartments/\(id)")

        let (data, response) = try await request(
            url: url,
            method: "GET",
            body: Optional<LoginRequest>.none as LoginRequest?,
            logLabel: "GET /apartments/\(id)"
        )

        switch response.statusCode {
        case 200:
            return try decode(ApartmentByIdDTO.self, from: data)
        case 400, 404, 409, 500...599:
            throw mapError(status: response.statusCode, data: data)
        default:
            throw APIError.unknownStatus(response.statusCode)
        }
    }

    func apartmentsByOwner(ownerId: String) async throws -> OwnerApartmentsDTO {
        let url = bookingBaseURL.appendingPathComponent("owners/\(ownerId)/apartments")

        let (data, response) = try await request(
            url: url,
            method: "GET",
            body: Optional<LoginRequest>.none as LoginRequest?,
            logLabel: "GET /owners/\(ownerId)/apartments"
        )

        switch response.statusCode {
        case 200:
            return try decode(OwnerApartmentsDTO.self, from: data)
        case 400, 409, 500...599:
            throw mapError(status: response.statusCode, data: data)
        default:
            throw APIError.unknownStatus(response.statusCode)
        }
    }

    func bookingsByUser(userId: String) async throws -> BookingsListDTO {
        let url = bookingBaseURL.appendingPathComponent("users/\(userId)/bookings")

        let (data, response) = try await request(
            url: url,
            method: "GET",
            body: Optional<LoginRequest>.none as LoginRequest?,
            logLabel: "GET /users/\(userId)/bookings"
        )

        switch response.statusCode {
        case 200:
            return try decode(BookingsListDTO.self, from: data)
        case 400, 409, 500...599:
            throw mapError(status: response.statusCode, data: data)
        default:
            throw APIError.unknownStatus(response.statusCode)
        }
    }

    // ---------- CREATE / UPDATE ----------

    func createApartment(_ dto: ApartmentCreateDTO) async throws -> MediumApartmentResponse {
        let url = bookingBaseURL.appendingPathComponent("apartments")

        let (data, response) = try await request(
            url: url,
            method: "POST",
            body: dto,
            logLabel: "POST /apartments"
        )

        switch response.statusCode {
        case 201:
            return try decode(MediumApartmentResponse.self, from: data)
        case 400, 409, 500...599:
            throw mapError(status: response.statusCode, data: data)
        default:
            throw APIError.unknownStatus(response.statusCode)
        }
    }

    func updateApartment(id: String, dto: ApartmentUpdateDTO) async throws {
        let url = bookingBaseURL.appendingPathComponent("apartments/\(id)")

        let (_, response) = try await request(
            url: url,
            method: "PATCH",
            body: dto,
            logLabel: "PATCH /apartments/\(id)"
        )

        switch response.statusCode {
        case 200:
            return
        case 400, 403, 404, 409, 500...599:
            // 403/404 могут прилететь из сервера
            throw mapError(status: response.statusCode, data: Data())
        default:
            throw APIError.unknownStatus(response.statusCode)
        }
    }

    func bookApartment(_ dto: BookingCreateDTO) async throws -> BookingResponse {
        let url = bookingBaseURL.appendingPathComponent("book")

        let (data, response) = try await request(
            url: url,
            method: "POST",
            body: dto,
            logLabel: "POST /book"
        )

        switch response.statusCode {
        case 200:
            return try decode(BookingResponse.self, from: data)
        case 400, 409, 404, 500...599:
            throw mapError(status: response.statusCode, data: data)
        default:
            throw APIError.unknownStatus(response.statusCode)
        }
    }
}

// MARK: - Low-level helpers

private extension RealAPIClient {

    struct ErrorResponse: Decodable {
        let error: String
    }

    func request<Body: Encodable>(
        url: URL,
        method: String,
        body: Body?,
        logLabel: String
    ) async throws -> (Data, HTTPURLResponse) {

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15

        if let body = body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.server(message: "no HTTPURLResponse")
        }

        return (data, http)
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            if let s = String(data: data, encoding: .utf8) {
                print("[API] DECODING ERROR for \(T.self): \(error)\nBody: \(s)")
            } else {
                print("[API] DECODING ERROR for \(T.self): \(error) (non-UTF8 body)")
            }
            throw error
        }
    }

    func mapError(status: Int, data: Data) -> APIError {
        let message: String
        if !data.isEmpty, let err = try? decoder.decode(ErrorResponse.self, from: data) {
            message = err.error
        } else {
            message = "HTTP \(status)"
        }

        switch status {
        case 400:
            return .badRequest(message: message)
        case 409:
            return .conflict(message: message)
        case 500...599:
            return .server(message: message)
        default:
            return .unknownStatus(status)
        }
    }
}
