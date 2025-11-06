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
            } else if canteenViewModel.selectedCanteen == nil {
                // Show canteen selector
                canteenSelectorView
            } else {
                // Show main tabs for selected canteen
                mainTabView
            }
        }
        .onAppear {
            authViewModel.checkExistingAuth()

            // Show canteen selector when logged in but no canteen selected
            if authViewModel.isAuthenticated && canteenViewModel.selectedCanteen == nil {
                showCanteenSelector = true
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            if newValue && canteenViewModel.selectedCanteen == nil {
                showCanteenSelector = true
            }
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

    private var canteenSelectorView: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("No Canteen Selected", systemImage: "building.2")
            } description: {
                Text("Select a canteen to manage")
            } actions: {
                Button("Select Canteen") {
                    showCanteenSelector = true
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
                canteen: canteenViewModel.selectedCanteen!,
                menuViewModel: menuViewModel,
                authViewModel: authViewModel,
                onChangeCanteen: {
                    canteenViewModel.selectedCanteen = nil
                    showCanteenSelector = true
                }
            )
            .tabItem {
                Label("Menu", systemImage: "fork.knife")
            }

            // Orders Tab
            OwnerOrdersTab(
                canteen: canteenViewModel.selectedCanteen!,
                authViewModel: authViewModel
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

