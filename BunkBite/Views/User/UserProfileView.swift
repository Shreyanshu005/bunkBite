//
//  UserProfileView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct UserProfileView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var showContent = false
    @State private var showLogoutAlert = false

    var body: some View {
        ZStack {
            Constants.backgroundColor.ignoresSafeArea()

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
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Constants.textColor)

                            Text(viewModel.currentUser?.email ?? "")
                                .font(.system(size: 14))
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
                        ProfileOptionCard(icon: "bell.fill", title: "Notifications", subtitle: "Manage notifications")
                        ProfileOptionCard(icon: "creditcard.fill", title: "Payment Methods", subtitle: "Manage payment options")
                        ProfileOptionCard(icon: "mappin.circle.fill", title: "Saved Addresses", subtitle: "Manage delivery addresses")
                        ProfileOptionCard(icon: "heart.fill", title: "Favorites", subtitle: "Your favorite items")
                        ProfileOptionCard(icon: "questionmark.circle.fill", title: "Help & Support", subtitle: "Get help with your orders")
                        ProfileOptionCard(icon: "doc.text.fill", title: "Terms & Privacy", subtitle: "Legal information")
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
                                .font(.system(size: 16, weight: .semibold))
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
                        .font(.system(size: 12))
                        .foregroundColor(Constants.darkGray)
                        .padding(.top, 16)
                        .opacity(showContent ? 1 : 0)

                    Spacer(minLength: 100)
                }
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
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Constants.textColor)

                    Text(subtitle)
                        .font(.system(size: 13))
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
