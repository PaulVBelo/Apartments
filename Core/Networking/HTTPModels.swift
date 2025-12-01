import Foundation

// MARK: - Primitives used in responses

struct BookingRangeDTO: Codable {
    let from: Date
    let to: Date
}

struct ShortApartmentResponse: Codable, Identifiable {
    let id: String
    let owner_id: String
    let address: String
    let price: Double
}

struct MediumApartmentResponse: Codable {
    let id: String
    let owner_id: String
    let address: String
    let price: Double
    let info: [String:String]
}

struct ShortBookingResponse: Codable, Identifiable {
    let id: String
    let user_id: String
    let time_from: Date
    let time_to: Date
}

struct FullApartmentResponse: Codable, Identifiable {
    let id: String
    let owner_id: String
    let address: String
    let price: Double
    let info: [String:String]
    let bookings: [ShortBookingResponse]
}

struct BookingResponse: Codable, Identifiable {
    let id: String
    let user_id: String
    let ap_id: String
    let address: String
    let time_from: Date
    let time_to: Date
}

// MARK: - Top-level wrappers

struct ApartmentsListDTO: Codable {
    let count: Int
    let apartments: [ShortApartmentResponse]
}

struct ApartmentByIdDTO: Codable {
    let apartment: MediumApartmentResponse
    let bookings: [BookingRangeDTO]

    enum CodingKeys: String, CodingKey {
        case apartment
        case bookings
    }

    init(apartment: MediumApartmentResponse, bookings: [BookingRangeDTO]) {
        self.apartment = apartment
        self.bookings = bookings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        apartment = try container.decode(MediumApartmentResponse.self, forKey: .apartment)
        // если с сервера пришёл null → получим [] вместо креша
        bookings = try container.decodeIfPresent([BookingRangeDTO].self, forKey: .bookings) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(apartment, forKey: .apartment)
        try container.encode(bookings, forKey: .bookings)
    }
}

struct OwnerApartmentsDTO: Codable {
    let count: Int
    let apartments: [FullApartmentResponse]
}

struct BookingsListDTO: Codable {
    let count: Int
    let bookings: [BookingResponse]
}

// MARK: - CREATE / UPDATE DTOs

struct ApartmentCreateDTO: Codable {
    let owner_id: String
    let address: String
    let price: Double
    let info: [String:String]?
}

struct ApartmentUpdateDTO: Codable {
    let owner_id: String
    let price: Double?
    let info: [String:String]?
}

struct BookingCreateDTO: Codable {
    let user_id: String
    let apartment_id: String
    let time_from: Date
    let time_to: Date
}
