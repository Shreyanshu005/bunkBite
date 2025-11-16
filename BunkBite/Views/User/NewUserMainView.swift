//
//  NewUserMainView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct NewUserMainView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var canteenViewModel = CanteenViewModel()
    @StateObject private var menuViewModel = MenuViewModel()
    @StateObject private var cart = Cart()

    @State private var showLoginSheet = false
    @State private var showCanteenSelector = false

    var body: some View {
        TabView {
            // Menu Tab
            UserMenuView(
                authViewModel: authViewModel,
                canteenViewModel: canteenViewModel,
                menuViewModel: menuViewModel,
                cart: cart,
                showLoginSheet: $showLoginSheet,
                showCanteenSelector: $showCanteenSelector
            )
            .tabItem {
                Label("Menu", systemImage: "fork.knife")
            }

            // Past Orders Tab
            UserOrdersView(authViewModel: authViewModel, showLoginSheet: $showLoginSheet)
                .tabItem {
                    Label("Orders", systemImage: "clock")
                }

            // Profile Tab
            UserProfileView(viewModel: authViewModel, showLoginSheet: $showLoginSheet)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .tint(Constants.primaryColor)
        .onAppear {
            authViewModel.checkExistingAuth()
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginSheet(authViewModel: authViewModel)
        }
        .sheet(isPresented: $showCanteenSelector) {
            CanteenSelectorSheet(
                canteenViewModel: canteenViewModel,
                authViewModel: authViewModel,
                menuViewModel: menuViewModel
            )
        }
    }
}
