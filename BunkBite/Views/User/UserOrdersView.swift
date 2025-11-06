//
//  UserOrdersView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct UserOrdersView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var showLoginSheet: Bool

    var body: some View {
        NavigationStack {
            Group {
                if authViewModel.isAuthenticated {
                    ordersContent
                } else {
                    loginPrompt
                }
            }
            .navigationTitle("Past Orders")
        }
    }

    private var loginPrompt: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Animated icons
                HStack(spacing: 20) {
                    ForEach(["📦", "🛵", "✅", "🎉"], id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 40))
                    }
                }
                .padding(.top, 60)

                // Main message
                VStack(spacing: 12) {
                    Text("Track Your Orders")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Constants.primaryColor)

                    Text("Your Order History")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Awaits You!")
                        .font(.title3)
                        .foregroundStyle(.gray)
                }

                // Feature cards
                VStack(spacing: 16) {
                    FeatureCard(
                        icon: "clock.arrow.circlepath",
                        title: "Order History",
                        description: "View all your past orders"
                    )
                    FeatureCard(
                        icon: "location.fill",
                        title: "Real-time Tracking",
                        description: "Track your order status"
                    )
                    FeatureCard(
                        icon: "arrow.counterclockwise",
                        title: "Reorder Easily",
                        description: "Order your favorites again"
                    )
                }
                .padding(.horizontal, 24)

                // CTA Button
                Button {
                    showLoginSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Text("View My Orders")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Constants.primaryColor)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Text("Login to access your order history")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.bottom, 40)
            }
        }
        .background(Constants.backgroundColor)
    }

    private var ordersContent: some View {
        List {
            ContentUnavailableView("No orders yet", systemImage: "clock")
                .listRowBackground(Color.clear)
        }
    }
}
