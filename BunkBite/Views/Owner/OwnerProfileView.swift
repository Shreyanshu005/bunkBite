//
//  OwnerProfileView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct OwnerProfileView: View {
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
                                Text(String(viewModel.currentUser?.name.prefix(1) ?? "A"))
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(Constants.primaryColor)
                            )
                            .scaleEffect(showContent ? 1 : 0.5)
                            .opacity(showContent ? 1 : 0)

                        VStack(spacing: 4) {
                            Text(viewModel.currentUser?.name ?? "Admin")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Constants.textColor)

                            Text(viewModel.currentUser?.email ?? "")
                                .font(.system(size: 14))
                                .foregroundColor(Constants.darkGray)

                            Text("OWNER")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Constants.primaryColor)
                                .cornerRadius(8)
                                .padding(.top, 4)
                        }
                        .offset(y: showContent ? 0 : 20)
                        .opacity(showContent ? 1 : 0)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)

                    // Business Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Overview")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Constants.textColor)
                            .padding(.horizontal, 24)

                        HStack(spacing: 12) {
                            BusinessStatsCard(icon: "bag.fill", title: "Orders", value: "24", color: .blue)
                            BusinessStatsCard(icon: "indianrupeesign.circle.fill", title: "Revenue", value: "₹3.2K", color: .green)
                        }
                        .padding(.horizontal, 24)
                    }
                    .offset(y: showContent ? 0 : 30)
                    .opacity(showContent ? 1 : 0)

                    // Management Options
                    VStack(spacing: 16) {
                        Text("Management")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Constants.textColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)

                        OwnerOptionCard(icon: "chart.bar.fill", title: "Analytics", subtitle: "View detailed analytics")
                        OwnerOptionCard(icon: "clock.fill", title: "Business Hours", subtitle: "Set opening hours")
                        OwnerOptionCard(icon: "megaphone.fill", title: "Promotions", subtitle: "Manage offers & deals")
                        OwnerOptionCard(icon: "person.2.fill", title: "Staff Management", subtitle: "Manage team members")
                        OwnerOptionCard(icon: "bell.badge.fill", title: "Notifications", subtitle: "Order alerts & updates")
                    }
                    .padding(.horizontal, 24)
                    .offset(y: showContent ? 0 : 30)
                    .opacity(showContent ? 1 : 0)

                    // Settings
                    VStack(spacing: 16) {
                        Text("Settings")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Constants.textColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)

                        OwnerOptionCard(icon: "gearshape.fill", title: "App Settings", subtitle: "Preferences & configuration")
                        OwnerOptionCard(icon: "questionmark.circle.fill", title: "Help & Support", subtitle: "Get help")
                        OwnerOptionCard(icon: "doc.text.fill", title: "Terms & Privacy", subtitle: "Legal information")
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

struct BusinessStatsCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                )

            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Constants.textColor)

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(Constants.darkGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct OwnerOptionCard: View {
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
