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
    @State private var isAnimating = false

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
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Icon with animation
                ZStack {
                    Circle()
                        .fill(Constants.primaryColor.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1 : 0.8)

                    Image(systemName: "clock.arrow.circlepath")
                        .font(.urbanist(size: 50, weight: .light))
                        .foregroundStyle(Constants.primaryColor)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                }

                // Message
                VStack(spacing: 12) {
                    Text("No Orders Yet")
                        .font(.urbanist(size: 28, weight: .bold))
                        .foregroundStyle(.black)

                    Text("Login to track your orders")
                        .font(.urbanist(size: 16, weight: .regular))
                        .foregroundStyle(.gray)
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)

                // CTA Button
                Button {
                    showLoginSheet = true
                } label: {
                    Text("Login")
                        .font(.urbanist(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 200)
                        .padding(.vertical, 16)
                        .background(Constants.primaryColor)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.9)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.backgroundColor)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }

    private var ordersContent: some View {
        List {
            ContentUnavailableView("No orders yet", systemImage: "clock")
                .listRowBackground(Color.clear)
        }
    }
}
