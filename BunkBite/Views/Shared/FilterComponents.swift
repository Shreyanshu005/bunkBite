//
//  FilterComponents.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

// MARK: - Menu Filter Chip Component
struct MenuFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            Text(title)
                .font(.urbanist(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : Constants.primaryColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Constants.primaryColor : Constants.primaryColor.opacity(0.1))
                )
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .buttonStyle(.plain)
    }
}

// MARK: - Feature Card Component
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Constants.primaryColor.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .foregroundStyle(Constants.primaryColor)
                        .font(.title3)
                )
                .scaleEffect(isVisible ? 1.0 : 0.5)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.urbanist(size: 16, weight: .semibold))
                    .foregroundStyle(.black)

                Text(description)
                    .font(.urbanist(size: 13, weight: .regular))
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                isVisible = true
            }
        }
    }
}
