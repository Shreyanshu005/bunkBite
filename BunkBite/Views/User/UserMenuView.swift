//
//  UserMenuView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct UserMenuView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var canteenViewModel: CanteenViewModel
    @ObservedObject var menuViewModel: MenuViewModel
    @ObservedObject var cart: Cart

    @Binding var showLoginSheet: Bool
    @Binding var showCanteenSelector: Bool

    @State private var showCart = false
    @State private var searchText = ""

    var filteredItems: [MenuItem] {
        if searchText.isEmpty {
            return menuViewModel.menuItems
        }
        return menuViewModel.menuItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if authViewModel.isAuthenticated {
                    if let canteen = canteenViewModel.selectedCanteen {
                        menuContent
                    } else {
                        canteenSelectionPrompt
                    }
                } else {
                    loginPrompt
                }
            }
            .navigationTitle("Menu")
            .toolbar {
                if authViewModel.isAuthenticated && canteenViewModel.selectedCanteen != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showCart = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "cart")
                                    .font(.title3)

                                if cart.totalItems > 0 {
                                    Text("\(cart.totalItems)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .padding(4)
                                        .background(Constants.primaryColor)
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search items")
            .sheet(isPresented: $showCart) {
                CartSheet(cart: cart, canteen: canteenViewModel.selectedCanteen)
            }
        }
    }

    private var loginPrompt: some View {
        ContentUnavailableView {
            Label("Not Logged In", systemImage: "person.crop.circle.badge.xmark")
        } description: {
            Text("Please log in to view the menu")
        } actions: {
            Button("Log In") {
                showLoginSheet = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Constants.primaryColor)
        }
    }

    private var canteenSelectionPrompt: some View {
        ContentUnavailableView {
            Label("No Canteen Selected", systemImage: "building.2")
        } description: {
            Text("Please select a canteen to view its menu")
        } actions: {
            Button("Select Canteen") {
                showCanteenSelector = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Constants.primaryColor)
        }
    }

    private var menuContent: some View {
        List {
            // Canteen Header
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(canteenViewModel.selectedCanteen?.name ?? "")
                            .font(.title2)
                            .fontWeight(.bold)

                        Label(canteenViewModel.selectedCanteen?.place ?? "", systemImage: "mappin.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Change") {
                        showCanteenSelector = true
                    }
                    .buttonStyle(.bordered)
                    .tint(Constants.primaryColor)
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )

            // Menu Items
            if menuViewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } else if filteredItems.isEmpty {
                ContentUnavailableView("No items available", systemImage: "tray")
            } else {
                ForEach(filteredItems) { item in
                    MenuItemRow(item: item, cart: cart)
                }
            }
        }
        .refreshable {
            if let canteenId = canteenViewModel.selectedCanteen?.id,
               let token = authViewModel.authToken {
                await menuViewModel.fetchMenu(canteenId: canteenId, token: token)
            }
        }
        .task {
            if let canteenId = canteenViewModel.selectedCanteen?.id,
               let token = authViewModel.authToken {
                await menuViewModel.fetchMenu(canteenId: canteenId, token: token)
            }
        }
    }
}

struct MenuItemRow: View {
    let item: MenuItem
    @ObservedObject var cart: Cart

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Item image placeholder with glass effect
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.title)
                        .foregroundStyle(.secondary)
                )

            // Item details
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)

                Text("₹\(Int(item.price))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Constants.primaryColor)

                if item.availableQuantity > 0 {
                    Text("\(item.availableQuantity) available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Out of stock")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            // Add to cart button
            if item.availableQuantity > 0 {
                if cart.getQuantity(for: item) > 0 {
                    HStack(spacing: 12) {
                        Button {
                            cart.removeItem(item)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                        }

                        Text("\(cart.getQuantity(for: item))")
                            .font(.headline)
                            .frame(minWidth: 20)

                        Button {
                            cart.addItem(item)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                    .foregroundStyle(Constants.primaryColor)
                } else {
                    Button {
                        cart.addItem(item)
                    } label: {
                        Text("Add")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Constants.primaryColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
