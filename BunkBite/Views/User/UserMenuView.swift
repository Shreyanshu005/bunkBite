//
//  UserMenuView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI
import PopupView
import Shimmer

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
    @State private var cartShake: CGFloat = 0
    @State private var isAnimating = false

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
                            Image(systemName: cart.totalItems > 0 ? "cart.fill" : "cart")
                                .font(.title2)
                                .foregroundStyle(Constants.primaryColor)
                                .padding(8)
                                .rotationEffect(.degrees(cartShake))
                                .onChange(of: cart.totalItems) { oldValue, newValue in
                                    if newValue > oldValue {
                                        // Shake animation
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
                                            cartShake = 10
                                        }
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.3).delay(0.1)) {
                                            cartShake = -10
                                        }
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.3).delay(0.2)) {
                                            cartShake = 0
                                        }
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
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Icon with animation
                ZStack {
                    Circle()
                        .fill(Constants.primaryColor.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1 : 0.8)

                    Image(systemName: "fork.knife")
                        .font(.urbanist(size: 50, weight: .light))
                        .foregroundStyle(Constants.primaryColor)
                        .rotationEffect(.degrees(isAnimating ? 0 : -90))
                }

                // Message
                VStack(spacing: 12) {
                    Text("Hungry?")
                        .font(.urbanist(size: 28, weight: .bold))
                        .foregroundStyle(.black)

                    Text("Login to start ordering")
                        .font(.urbanist(size: 16, weight: .regular))
                        .foregroundStyle(.gray)
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)

                // CTA Button
                Button {
                    showLoginSheet = true
                } label: {
                    Text("Login")
                        .font(.urbanist(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 200)
                        .padding(.vertical, 16)
                        .background(Constants.primaryColor)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.9)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.backgroundColor)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
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
                            .font(.urbanist(size: 22, weight: .bold))

                        Label(canteenViewModel.selectedCanteen?.place ?? "", systemImage: "mappin.circle")
                            .font(.urbanist(size: 14, weight: .regular))
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
                ForEach(0..<6, id: \.self) { _ in
                    ShimmerMenuItemRow()
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
                    .font(.urbanist(size: 17, weight: .semibold))

                Text("₹\(Int(item.price))")
                    .font(.urbanist(size: 20, weight: .bold))
                    .foregroundStyle(Constants.primaryColor)

                if item.availableQuantity > 0 {
                    Text("\(item.availableQuantity) available")
                        .font(.urbanist(size: 12, weight: .regular))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Out of stock")
                        .font(.urbanist(size: 12, weight: .regular))
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            // Add to cart button
            if item.availableQuantity > 0 {
                if cart.getQuantity(for: item) > 0 {
                    HStack(spacing: 12) {
                        Button {
                            let currentQuantity = cart.getQuantity(for: item)
                            if currentQuantity > 1 {
                                cart.updateQuantity(for: item, quantity: currentQuantity - 1)
                            } else {
                                cart.removeItem(item)
                            }
                        } label: {
                            Image(systemName: cart.getQuantity(for: item) == 1 ? "trash.fill" : "minus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(cart.getQuantity(for: item) == 1 ? .red : Constants.primaryColor)
                        }
                        .buttonStyle(.plain)

                        Text("\(cart.getQuantity(for: item))")
                            .font(.urbanist(size: 17, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(minWidth: 30)

                        Button {
                            cart.addItem(item)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Constants.primaryColor)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        cart.addItem(item)
                    } label: {
                        Text("Add")
                            .font(.urbanist(size: 15, weight: .semibold))
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

// MARK: - Shimmer Loading Skeleton
struct ShimmerMenuItemRow: View {
    var body: some View {
        HStack(spacing: 16) {
            // Placeholder image
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 70, height: 70)
                .shimmering()

            // Placeholder text
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 16)
                    .shimmering()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 14)
                    .shimmering()
            }

            Spacer()

            // Placeholder button
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 36)
                .shimmering()
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
