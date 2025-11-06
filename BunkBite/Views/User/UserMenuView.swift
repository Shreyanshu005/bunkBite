//
//  UserMenuView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI
import PopupView

struct UserMenuView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var canteenViewModel: CanteenViewModel
    @ObservedObject var menuViewModel: MenuViewModel
    @ObservedObject var cart: Cart

    @Binding var showLoginSheet: Bool
    @Binding var showCanteenSelector: Bool

    @State private var showCart = false
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showFilters = false
    @State private var menuLoadingTask: Task<Void, Never>?

    var categories: [String] {
        let allCategories = menuViewModel.menuItems.compactMap { item -> String? in
            // Extract category from item name or use a simple classification
            if item.name.localizedCaseInsensitiveContains("samosa") ||
               item.name.localizedCaseInsensitiveContains("pakora") {
                return "Snacks"
            } else if item.name.localizedCaseInsensitiveContains("rice") ||
                      item.name.localizedCaseInsensitiveContains("dal") ||
                      item.name.localizedCaseInsensitiveContains("chawal") {
                return "Main Course"
            } else if item.name.localizedCaseInsensitiveContains("tea") ||
                      item.name.localizedCaseInsensitiveContains("coffee") ||
                      item.name.localizedCaseInsensitiveContains("chai") {
                return "Beverages"
            }
            return "Other"
        }
        return Array(Set(allCategories)).sorted()
    }

    func getCategory(for item: MenuItem) -> String {
        if item.name.localizedCaseInsensitiveContains("samosa") ||
           item.name.localizedCaseInsensitiveContains("pakora") {
            return "Snacks"
        } else if item.name.localizedCaseInsensitiveContains("rice") ||
                  item.name.localizedCaseInsensitiveContains("dal") ||
                  item.name.localizedCaseInsensitiveContains("chawal") {
            return "Main Course"
        } else if item.name.localizedCaseInsensitiveContains("tea") ||
                  item.name.localizedCaseInsensitiveContains("coffee") ||
                  item.name.localizedCaseInsensitiveContains("chai") {
            return "Beverages"
        }
        return "Other"
    }

    var filteredItems: [MenuItem] {
        var items = menuViewModel.menuItems

        // Apply category filter
        if let category = selectedCategory {
            items = items.filter { getCategory(for: $0) == category }
        }

        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return items
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
            .onChange(of: canteenViewModel.selectedCanteen) { newCanteen in
                if let canteen = newCanteen, let token = authViewModel.authToken {
                    // Cancel any existing loading task
                    menuLoadingTask?.cancel()
                    
                    // Start a new loading task
                    menuLoadingTask = Task {
                        await menuViewModel.fetchMenu(canteenId: canteen.id, token: token)
                    }
                }
            }
            .onAppear {
                // Load menu if a canteen is already selected
                if let canteen = canteenViewModel.selectedCanteen, 
                   let token = authViewModel.authToken,
                   menuViewModel.menuItems.isEmpty {
                    menuLoadingTask = Task {
                        await menuViewModel.fetchMenu(canteenId: canteen.id, token: token)
                    }
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
            .if(authViewModel.isAuthenticated) { view in
                view.searchable(text: $searchText, prompt: "Search items")
            }
            .sheet(isPresented: $showCart) {
                CartSheet(cart: cart, canteen: canteenViewModel.selectedCanteen)
            }
        }
    }

    private var loginPrompt: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Animated food icons
                HStack(spacing: 20) {
                    ForEach(["🍕", "🍔", "☕️", "🍜", "🌮"], id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 40))
                    }
                }
                .padding(.top, 40)

                // Main message
                VStack(spacing: 12) {
                    Text("Hungry?")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Constants.primaryColor)

                    Text("Order from your")
                        .font(.title3)
                        .foregroundStyle(.gray)

                    Text("Favorite Canteen")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                }

                // Feature cards
                VStack(spacing: 16) {
                    FeatureCard(
                        icon: "clock",
                        title: "Quick Orders",
                        description: "Get your food in minutes"
                    )

                    FeatureCard(
                        icon: "creditcard",
                        title: "Easy Payments",
                        description: "Pay with UPI instantly"
                    )

                    FeatureCard(
                        icon: "star.fill",
                        title: "Best Quality",
                        description: "Fresh food, every time"
                    )
                }
                .padding(.horizontal)

                // CTA Button
                Button {
                    showLoginSheet = true
                } label: {
                    HStack {
                        Text("Start Ordering")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Constants.primaryColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Text("Join hundreds of hungry students!")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.bottom, 40)
            }
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

            // Category Filter Chips
            if !categories.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // All filter
                            MenuFilterChip(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                action: {
                                    withAnimation {
                                        selectedCategory = nil
                                    }
                                }
                            )

                            // Category filters
                            ForEach(categories, id: \.self) { category in
                                MenuFilterChip(
                                    title: category,
                                    isSelected: selectedCategory == category,
                                    action: {
                                        withAnimation {
                                            selectedCategory = category
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }

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

// MARK: - View Extension
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
