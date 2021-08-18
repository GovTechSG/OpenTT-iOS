//
//  ColorExtension.swift
//  TraceTogetherWidget
//  OpenTraceTogether


import SwiftUI

private var light = true

extension Color {

    /// This logic is copied from UIColorExtension.swift in MAIN target
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }

    /// Seems the only way to call this function inside a `body` is to make it return a `View`.
    struct set: View {
        init(_ colorScheme: ColorScheme) {
            light = colorScheme == .light
        }
        var body: some View {
            EmptyView()
        }
    }

    static var themeFF: Color { return Color(hexString: light ? "#FFFFFF" : "#121212") }
    static var themeF2: Color { return Color(hexString: light ? "#F2F2F2" : "#323136") }
    static var theme82: Color { return Color(hexString: light ? "#828282" : "#A4A3A9") }
    static var theme4F: Color { return Color(hexString: light ? "#4F4F4f" : "#FFFFFF") }
    static var theme33: Color { return Color(hexString: light ? "#333333" : "#FFFFFF") }

    static let navBarStart: Color = Color(hexString: "#F06566")
    static let navBarEnd: Color = Color(hexString: "#C93E3C")
    static let buttonBlue: Color = Color(hexString: "#0070E0")
}
