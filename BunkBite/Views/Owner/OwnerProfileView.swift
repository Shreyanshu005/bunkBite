//
//  OwnerProfileView2.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct OwnerProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var canteenViewModel: CanteenViewModel // Added dependency
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
// ...
            }

            Section {
                if canteenViewModel.selectedCanteen != nil {
                    NavigationLink {
                        OwnerCanteenSettingsView(canteenViewModel: canteenViewModel, authViewModel: authViewModel)
                    } label: {
                        Label("Canteen Settings", systemImage: "gear.circle.fill")
                    }
                    
                    NavigationLink {
                        if let canteen = canteenViewModel.selectedCanteen {
                            AnalyticsView(canteenId: canteen.id, token: authViewModel.authToken ?? "")
                        }
                    } label: {
                        Label("Analytics", systemImage: "chart.bar.fill")
                    }
                } else {
                    // Disabled State
                    HStack {
                        Label("Canteen Settings", systemImage: "gear.circle.fill")
                        Spacer()
                        Image(systemName: "lock.fill").font(.caption).foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.tertiary)
                    
                    HStack {
                        Label("Analytics", systemImage: "chart.bar.fill")
                        Spacer()
                        Image(systemName: "lock.fill").font(.caption).foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.tertiary)
                }
            } header: {
                Text("Business")
            } footer: {
                if canteenViewModel.selectedCanteen == nil {
                    Text("Select a canteen to access settings & analytics.")
                }
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
