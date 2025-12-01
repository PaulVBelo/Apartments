import Foundation

enum AppConfig {
    static var authBaseURL: URL {
        URL(string: "http://\(info("AUTH_BASE_URL"))")!
    }

    static var bookingBaseURL: URL {
        URL(string: "http://\(info("BOOKING_BASE_URL"))")!
    }
    
    static var cacheTTLSeconds: Double {
        Double(info("CACHE_TTL_SECONDS")) ?? 180.0
    }

    static var stubDelaySeconds: Double {
        Double(info("STUB_DELAY_SECONDS")) ?? 1
    }

    static var stubLoginStatus: Int {
        Int(info("STUB_LOGIN_STATUS")) ?? 200
    }

    static var stubRegisterStatus: Int {
        Int(info("STUB_REGISTER_STATUS")) ?? 201
    }
    
    static var stubAptsStatus: Int {
        Int(info("STUB_APARTMENTS_STATUS")) ?? 200
    }
    static var stubApartmentStatus: Int { 
        Int(info("STUB_APARTMENT_STATUS")) ?? 200
    }
    static var stubOwnerAptsStatus: Int {
        Int(info("STUB_OWNER_APTS_STATUS")) ?? 200
    }
    static var stubUserBooksStatus: Int {
        Int(info("STUB_USER_BOOKS_STATUS")) ?? 200
    }

    private static func info(_ key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? ""
    }
}
