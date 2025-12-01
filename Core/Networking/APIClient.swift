import Foundation

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
}

struct LoginSuccessDTO: Codable {
    let status: String   // "logged_in"
    let user_id: String
}

enum APIError: Error {
    case badRequest(message: String)    // 400
    case conflict(message: String)      // 409
    case server(message: String)        // 500+
    case unknownStatus(Int)
}

protocol APIClient {
    // Auth
    func login(email: String, password: String) async throws -> LoginSuccessDTO
    func register(email: String, password: String) async throws
    
    // Cachable in Universal Wrapper
    func searchApartments(city: String?, rooms: Int?, beds: Int?) async throws -> ApartmentsListDTO
    func apartmentDetails(id: String) async throws -> ApartmentByIdDTO
    func apartmentsByOwner(ownerId: String) async throws -> OwnerApartmentsDTO
    func bookingsByUser(userId: String) async throws -> BookingsListDTO
    
    // Create/Update
    func createApartment(_ dto: ApartmentCreateDTO) async throws -> MediumApartmentResponse
    func updateApartment(id: String, dto: ApartmentUpdateDTO) async throws
    func bookApartment(_ dto: BookingCreateDTO) async throws -> BookingResponse
}
