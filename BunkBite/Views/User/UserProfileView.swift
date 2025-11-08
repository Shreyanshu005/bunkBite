//
//  UserProfileView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct UserProfileView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Binding var showLoginSheet: Bool
    @State private var showContent = false
    @State private var showLogoutAlert = false

    var body: some View {
        ZStack {
            Constants.backgroundColor.ignoresSafeArea()

            if viewModel.isAuthenticated {
                profileContent
            } else {
                loginPrompt
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
        .onAppear {
            withAnimation(Constants.bouncyAnimation.delay(0.1)) {
                showContent = true
            }
        }
    }

    private var loginPrompt: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Animated icons
                HStack(spacing: 20) {
                    ForEach(["👤", "⚙️", "❤️", "🎯"], id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 40))
                    }
                }
                .padding(.top, 60)

                // Main message
                VStack(spacing: 12) {
                    Text("Your Profile")
                        .font(.urbanist(size: 32, weight: .bold))
                        .foregroundStyle(Constants.primaryColor)

                    Text("Personalize Your")
                        .font(.urbanist(size: 20, weight: .semibold))

                    Text("Experience!")
                        .font(.urbanist(size: 20, weight: .regular))
                        .foregroundStyle(.gray)
                }

                // Feature cards
                VStack(spacing: 16) {
                    FeatureCard(
                        icon: "person.circle.fill",
                        title: "Personal Info",
                        description: "Manage your profile details"
                    )
                    FeatureCard(
                        icon: "heart.fill",
                        title: "Your Favorites",
                        description: "Save and reorder favorites"
                    )
                    FeatureCard(
                        icon: "bell.badge.fill",
                        title: "Notifications",
                        description: "Stay updated on orders"
                    )
                }
                .padding(.horizontal, 24)

                // CTA Button
                Button {
                    showLoginSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Text("Access Profile")
                            .font(.urbanist(size: 16, weight: .semibold))
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

                Text("Login to manage your account")
                    .font(.urbanist(size: 12, weight: .regular))
                    .foregroundStyle(.gray)
                    .padding(.bottom, 40)
            }
        }
    }

    private var profileContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    Circle()
                        .fill(Constants.primaryColor.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String(viewModel.currentUser?.name.prefix(1) ?? "U"))
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(Constants.primaryColor)
                        )
                        .scaleEffect(showContent ? 1 : 0.5)
                        .opacity(showContent ? 1 : 0)

                    VStack(spacing: 4) {
                        Text(viewModel.currentUser?.name ?? "User")
                            .font(.urbanist(size: 24, weight: .bold))
                            .foregroundColor(Constants.textColor)

                        Text(viewModel.currentUser?.email ?? "")
                            .font(.urbanist(size: 14, weight: .regular))
                            .foregroundColor(Constants.darkGray)
                    }
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)

                // Profile Options
                VStack(spacing: 16) {
                    ProfileOptionCard(icon: "person.fill", title: "Edit Profile", subtitle: "Update your details")
                    ProfileOptionCard(icon: "heart.fill", title: "Favorites", subtitle: "Your favorite items")
                    ProfileOptionCard(icon: "questionmark.circle.fill", title: "Help & Support", subtitle: "Get help")
                }
                .padding(.horizontal, 24)
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)

                // Logout Button
                Button(action: {
                    showLogoutAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 20))
                        Text("Logout")
                            .font(.urbanist(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Constants.primaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Constants.primaryColor.opacity(0.1))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)

                Text("Version 1.0.0")
                    .font(.urbanist(size: 12, weight: .regular))
                    .foregroundColor(Constants.darkGray)
                    .padding(.top, 16)
                    .opacity(showContent ? 1 : 0)

                Spacer(minLength: 100)
            }
        }
    }
}

struct ProfileOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
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
            HStack(spacing: 16) {
                Circle()
                    .fill(Constants.lightGray)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(Constants.primaryColor)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.urbanist(size: 16, weight: .semibold))
                        .foregroundColor(Constants.textColor)

                    Text(subtitle)
                        .font(.urbanist(size: 13, weight: .regular))
                        .foregroundColor(Constants.darkGray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Constants.darkGray)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
    }
}
