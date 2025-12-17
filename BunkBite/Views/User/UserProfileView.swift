//
//  UserProfileView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct UserProfileView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject var cart: Cart
    @EnvironmentObject var canteenViewModel: CanteenViewModel
    @Binding var showLoginSheet: Bool
    @State private var showContent = false
    @State private var showLogoutAlert = false
    @State private var showCart = false

    var body: some View {
        NavigationStack {
            ZStack {
                Constants.backgroundColor.ignoresSafeArea()

                if viewModel.isAuthenticated {
                    profileContent
                } else {
                    loginPrompt
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CartToolbarButton(
                        authViewModel: viewModel,
                        showCart: $showCart,
                        showLoginSheet: $showLoginSheet
                    )
                }
            }
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    withAnimation {
                        viewModel.logout()
                    }
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .sheet(isPresented: $showCart) {
                CartSheet(cart: cart, authViewModel: viewModel, canteen: canteenViewModel.selectedCanteen)
            }
            .onAppear {
                withAnimation(Constants.bouncyAnimation.delay(0.1)) {
                    showContent = true
                }
            }
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
                        .scaleEffect(showContent ? 1 : 0.8)

                    Image(systemName: "person.circle")
                        .font(.urbanist(size: 50, weight: .light))
                        .foregroundStyle(Constants.primaryColor)
                        .scaleEffect(showContent ? 1 : 0.5)
                }

                // Message
                VStack(spacing: 12) {
                    Text("Profile")
                        .font(.urbanist(size: 28, weight: .bold))
                        .foregroundStyle(.black)

                    Text("Login to access your profile")
                        .font(.urbanist(size: 16, weight: .regular))
                        .foregroundStyle(.gray)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

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
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.backgroundColor)
    }

    private var profileContent: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Profile Header
                VStack(spacing: 20) {
                    // Avatar
                    Circle()
                        .fill(Constants.primaryColor.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String(viewModel.currentUser?.name.prefix(1) ?? "U"))
                                .font(.urbanist(size: 40, weight: .bold))
                                .foregroundColor(Constants.primaryColor)
                        )
                        .scaleEffect(showContent ? 1 : 0.5)
                        .opacity(showContent ? 1 : 0)

                    // User Info
                    VStack(spacing: 8) {
                        Text(viewModel.currentUser?.name ?? "User")
                            .font(.urbanist(size: 28, weight: .bold))
                            .foregroundColor(.black)

                        Text(viewModel.currentUser?.email ?? "")
                            .font(.urbanist(size: 15, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)
                }
                .padding(.top, 60)

                // User Details Card
                VStack(spacing: 0) {
                    ProfileDetailRow(
                        icon: "person.fill",
                        label: "Name",
                        value: viewModel.currentUser?.name ?? "N/A"
                    )

                    Divider()
                        .padding(.leading, 56)

                    ProfileDetailRow(
                        icon: "envelope.fill",
                        label: "Email",
                        value: viewModel.currentUser?.email ?? "N/A"
                    )
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                .padding(.horizontal, 24)
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)

                // Logout Button
                Button(action: {
                    showLogoutAlert = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 20))
                        Text("Logout")
                            .font(.urbanist(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Constants.primaryColor)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)

                Spacer(minLength: 60)
            }
        }
    }
}

struct ProfileDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(Constants.primaryColor.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(Constants.primaryColor)
                )

            // Label & Value
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.urbanist(size: 13, weight: .medium))
                    .foregroundColor(.gray)

                Text(value)
                    .font(.urbanist(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}
