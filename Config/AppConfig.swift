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

    private static func info(_ key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? ""
    }
}
