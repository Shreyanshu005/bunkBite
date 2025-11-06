//
//  NewOwnerMainView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct NewOwnerMainView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var canteenViewModel = CanteenViewModel()
    @StateObject private var menuViewModel = MenuViewModel()

    @State private var showLoginSheet = false
    @State private var showCanteenSelector = false

    var body: some View {
        Group {
            if !authViewModel.isAuthenticated {
                // Show login prompt
                loginPromptView
            } else {
                // Show main tabs (even if no canteen selected)
                mainTabView
            }
        }
        .onAppear {
            authViewModel.checkExistingAuth()
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginSheet(authViewModel: authViewModel)
        }
        .sheet(isPresented: $showCanteenSelector) {
            OwnerCanteenSelectorSheet(
                canteenViewModel: canteenViewModel,
                authViewModel: authViewModel
            )
        }
    }

    private var loginPromptView: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Not Logged In", systemImage: "person.crop.circle.badge.xmark")
            } description: {
                Text("Please log in to manage your canteens")
            } actions: {
                Button("Log In") {
                    showLoginSheet = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Constants.primaryColor)
            }
            .navigationTitle("Owner Panel")
        }
    }

    private var mainTabView: some View {
        TabView {
            // Menu/Inventory Tab
            OwnerMenuTab(
                canteen: canteenViewModel.selectedCanteen,
                menuViewModel: menuViewModel,
                authViewModel: authViewModel,
                canteenViewModel: canteenViewModel,
                onSelectCanteen: {
                    showCanteenSelector = true
                }
            )
            .tabItem {
                Label("Inventory", systemImage: "fork.knife")
            }

            // Orders Tab
            OwnerOrdersTab(
                canteen: canteenViewModel.selectedCanteen,
                authViewModel: authViewModel,
                onSelectCanteen: {
                    showCanteenSelector = true
                }
            )
            .tabItem {
                Label("Orders", systemImage: "list.clipboard")
            }

            // Profile Tab
            OwnerProfileView2(authViewModel: authViewModel, showLoginSheet: $showLoginSheet)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .tint(Constants.primaryColor)
    }
}

