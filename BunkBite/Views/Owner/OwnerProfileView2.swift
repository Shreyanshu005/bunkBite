//
//  OwnerProfileView2.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct OwnerProfileView2: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var showLoginSheet: Bool

    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if authViewModel.isAuthenticated {
                    profileContent
                } else {
                    loginPrompt
                }
            }
            .navigationTitle("Profile")
        }
    }

    private var loginPrompt: some View {
        ContentUnavailableView {
            Label("Not Logged In", systemImage: "person.crop.circle.badge.xmark")
        } description: {
            Text("Please log in to view your profile")
        } actions: {
            Button("Log In") {
                showLoginSheet = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Constants.primaryColor)
        }
    }

    private var profileContent: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Text(String(authViewModel.currentUser?.name.prefix(1) ?? "A"))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Constants.primaryColor)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(authViewModel.currentUser?.name ?? "Owner")
                            .font(.title3)
                            .fontWeight(.bold)

                        Text(authViewModel.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("OWNER")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Constants.primaryColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 8)
            }

            Section {
                NavigationLink {
                    Text("Analytics")
                } label: {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }

                NavigationLink {
                    Text("Business Settings")
                } label: {
                    Label("Business Settings", systemImage: "gearshape.fill")
                }
            } header: {
                Text("Business")
            }

            Section {
                NavigationLink {
                    Text("Help & Support")
                } label: {
                    Label("Help & Support", systemImage: "questionmark.circle.fill")
                }

                NavigationLink {
                    Text("Terms & Privacy")
                } label: {
                    Label("Terms & Privacy", systemImage: "doc.text.fill")
                }
            } header: {
                Text("Support")
            }

            Section {
                Button(role: .destructive) {
                    showLogoutAlert = true
                } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                }
            }

            Section {
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .listRowBackground(Color.clear)
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                authViewModel.logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}
