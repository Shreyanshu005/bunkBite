//
//  UserHomeView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct UserHomeView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var showContent = false

    var body: some View {
        ZStack {
            Constants.backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hello, \(viewModel.currentUser?.name ?? "Guest")!")
                            .font(.urbanist(size: 28, weight: .bold))
                            .foregroundColor(Constants.textColor)

                        Text("What would you like to eat today?")
                            .font(.urbanist(size: 16, weight: .regular))
                            .foregroundColor(Constants.darkGray)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .offset(y: showContent ? 0 : -20)
                    .opacity(showContent ? 1 : 0)

                    // Featured Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Constants.primaryColor, Constants.primaryColor.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 180)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.white)
                                Text("TODAY'S SPECIAL")
                                    .font(.urbanist(size: 12, weight: .bold))
                                    .foregroundColor(.white)

                                Spacer()
                            }

                            Text("Fresh & Delicious")
                                .font(.urbanist(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text("Order now and get it fresh from the kitchen")
                                .font(.urbanist(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))

                            Spacer()

                            HStack {
                                Button(action: {}) {
                                    Text("Order Now")
                                        .font(.urbanist(size: 14, weight: .semibold))
                                        .foregroundColor(Constants.primaryColor)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.white)
                                        .cornerRadius(20)
                                }
                                Spacer()
                            }
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 24)
                    .scaleEffect(showContent ? 1 : 0.9)
                    .opacity(showContent ? 1 : 0)

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.urbanist(size: 20, weight: .bold))
                            .foregroundColor(Constants.textColor)
                            .padding(.horizontal, 24)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                QuickActionCard(icon: "list.bullet.rectangle", title: "Menu", color: .orange)
                                QuickActionCard(icon: "star.fill", title: "Favorites", color: .yellow)
                                QuickActionCard(icon: "clock.fill", title: "Repeat", color: .blue)
                                QuickActionCard(icon: "gift.fill", title: "Offers", color: .green)
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .offset(y: showContent ? 0 : 30)
                    .opacity(showContent ? 1 : 0)

                    // Categories
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Categories")
                            .font(.urbanist(size: 20, weight: .bold))
                            .foregroundColor(Constants.textColor)
                            .padding(.horizontal, 24)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                CategoryCard(icon: "cup.and.saucer.fill", title: "Beverages")
                                CategoryCard(icon: "fork.knife", title: "Meals")
                                CategoryCard(icon: "birthday.cake.fill", title: "Snacks")
                                CategoryCard(icon: "leaf.fill", title: "Healthy")
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .offset(y: showContent ? 0 : 30)
                    .opacity(showContent ? 1 : 0)

                    Spacer(minLength: 100)
                }
            }
        }
        .onAppear {
            withAnimation(Constants.bouncyAnimation.delay(0.1)) {
                showContent = true
            }
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(Constants.quickBounce) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(Constants.quickBounce) {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 12) {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(color)
                    )

                Text(title)
                    .font(.urbanist(size: 14, weight: .medium))
                    .foregroundColor(Constants.textColor)
            }
            .frame(width: 100)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
    }
}

struct CategoryCard: View {
    let icon: String
    let title: String
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(Constants.quickBounce) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(Constants.quickBounce) {
                    isPressed = false
                }
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                Circle()
                    .fill(Constants.primaryColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 22))
                            .foregroundColor(Constants.primaryColor)
                    )

                Text(title)
                    .font(.urbanist(size: 16, weight: .semibold))
                    .foregroundColor(Constants.textColor)
            }
            .frame(width: 140, height: 120)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}
