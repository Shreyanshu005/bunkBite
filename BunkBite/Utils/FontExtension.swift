//
//  FontExtension.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

extension Font {
    // Urbanist Font Weights
    static func urbanist(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName: String

        switch weight {
        case .black:
            fontName = "Urbanist-Black"
        case .bold:
            fontName = "Urbanist-Bold"
        case .semibold:
            fontName = "Urbanist-SemiBold"
        case .medium:
            fontName = "Urbanist-Medium"
        case .light:
            fontName = "Urbanist-Light"
        case .thin:
            fontName = "Urbanist-Thin"
        default:
            fontName = "Urbanist-Regular"
        }

        return .custom(fontName, size: size)
    }
}

// View Modifier for easy font application
struct UrbanistFontModifier: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight

    func body(content: Content) -> some View {
        content
            .font(.urbanist(size: size, weight: weight))
    }
}

extension View {
    func urbanistFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(UrbanistFontModifier(size: size, weight: weight))
    }
    
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
