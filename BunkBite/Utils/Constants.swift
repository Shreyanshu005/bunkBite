//
//  Constants.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct Constants {
    // API
    static let baseURL = "https://steellike-giana-periphrastic.ngrok-free.dev"

    // Colors
    static let primaryColor = Color(hex: "0B7D3B") // Updated Green
    static let backgroundColor = Color(hex: "FFFFFF")
    static let secondaryColor = Color(hex: "F3F4F6")
    static let darkColor = Color(hex: "0D1317")
    static let textColor = Color.black
    static let lightGray = Color(hex: "#F5F5F5")
    static let darkGray = Color(hex: "#666666")
    
    // App Info
    static let appVersion = "2.0"

    // Animation
    static let bouncyAnimation = Animation.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3)
    static let quickBounce = Animation.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.2)
}

// Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
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
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
