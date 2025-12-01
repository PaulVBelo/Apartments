import SwiftUI

extension Color {
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") { hex.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

let appBarColor = Color(hex: "40A5CF")

enum UIConst {
    static let headerHeight: CGFloat = 32
}

private struct TopHeaderPadding: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.top, UIConst.headerHeight + 2)
    }
}

extension View {
    func respectsTopHeader() -> some View {
        modifier(TopHeaderPadding())
    }
}

extension Optional where Wrapped == String {
    var nilIfBlank: String? {
        guard let s = self?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }
}
extension Int {
    var string: String { String(self) }
}
extension Double {
    var string: String { String(format: "%.2f", self) }
}

enum SearchPrompts {
    static let variants = [
        "What kind of apartment do you need?",
        "What are you looking for today?",
        "Pick a city and we’ll find a place.",
        "Where would you like to stay?"
    ]
    static func random() -> String { variants.randomElement() ?? variants[0] }
}
