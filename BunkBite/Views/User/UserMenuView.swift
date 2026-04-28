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

        if let category = selectedCategory {
            items = items.filter { getCategory(for: $0) == category }
        }

        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return items
    }

    @State private var showReadOnlyMenu = false

    var body: some View {
        NavigationStack {
            Group {

                if canteenViewModel.selectedCanteen != nil {
                     mainContent
                } else {
                    canteenSelectionPrompt
                }
            }
            .onChange(of: canteenViewModel.selectedCanteen) { _, newCanteen in
                if let canteen = newCanteen {
                    menuLoadingTask?.cancel()
                    menuLoadingTask = Task { await menuViewModel.fetchMenu(canteenId: canteen.id) }
                }
            }
            .onAppear {
                if let canteen = canteenViewModel.selectedCanteen, menuViewModel.menuItems.isEmpty {
                    menuLoadingTask = Task { await menuViewModel.fetchMenu(canteenId: canteen.id) }
                }
            }
            .navigationTitle("Menu")
            .toolbar {

                if canteenViewModel.selectedCanteen != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        if !authViewModel.isAuthenticated {
                            Button { showLoginSheet = true } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.circle")
                                    Text("Sign In").font(.urbanist(size: 15, weight: .medium))
                                }
                                .foregroundStyle(Constants.primaryColor)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Constants.primaryColor.opacity(0.1)).cornerRadius(20)
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if authViewModel.isAuthenticated { showCart = true } else { showLoginSheet = true }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: cart.totalItems > 0 ? "cart.fill" : "cart").font(.title3)
                                if cart.totalItems > 0 {
                                    Text("\(cart.totalItems)").font(.urbanist(size: 12, weight: .bold)).foregroundStyle(.white)
                                        .frame(minWidth: 18, minHeight: 18).background(Constants.primaryColor).clipShape(Circle())
                                }
                            }
                            .foregroundStyle(Constants.primaryColor).padding(8)
                            .rotationEffect(.degrees(cartShake))
                            .onChange(of: cart.totalItems) { oldValue, newValue in
                                if newValue > oldValue {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) { cartShake = 10 }
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.3).delay(0.1)) { cartShake = -10 }
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.3).delay(0.2)) { cartShake = 0 }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search items")
            .sheet(isPresented: $showCart) {
                CartSheet(cart: cart, authViewModel: authViewModel, canteen: canteenViewModel.selectedCanteen)
            }
            .sheet(isPresented: $showReadOnlyMenu) {
                ReadOnlyMenuSheet(
                    canteenViewModel: canteenViewModel,
                    menuViewModel: menuViewModel,
                    cart: cart,
                    authViewModel: authViewModel,
                    categories: categories,
                    filteredItems: filteredItems
                )
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {

            if let canteen = canteenViewModel.selectedCanteen {
                let (isOpen, statusMessage) = canteen.isAcceptingOrders

                if !isOpen {

                    ScrollView {
                         VStack(spacing: 20) {
                             CanteenHeaderView(canteen: canteen, showCanteenSelector: $showCanteenSelector)
                                 .padding(.horizontal)
                                 .padding(.top, 16)

                             Spacer(minLength: 40)

                             HangingBannerView(message: "SORRY WE'RE CLOSED", subMessage: statusMessage)

                             Button {
                                 showReadOnlyMenu = true
                             } label: {
                                 Text("View Menu")
                                     .font(.urbanist(size: 18, weight: .semibold))
                                     .foregroundStyle(.white)
                                     .frame(width: 200, height: 50)
                                     .background(Constants.primaryColor)
                                     .cornerRadius(25)
                             }
                             .padding(.top, 20)
                         }
                    }
                    .refreshable {
                        await canteenViewModel.refreshSelectedCanteen()
                    }
                } else {

                    MenuListView(
                        canteenViewModel: canteenViewModel,
                        menuViewModel: menuViewModel,
                        cart: cart,
                        authViewModel: authViewModel,
                        showLoginSheet: $showLoginSheet,
                        showCanteenSelector: $showCanteenSelector,
                        selectedCategory: $selectedCategory,
                        categories: categories,
                        filteredItems: filteredItems,
                        isReadOnly: false
                    )
                }
            }
        }
        .background(Constants.backgroundColor)
    }

    private var loginPrompt: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {

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
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 40) {

                ZStack {
                    Circle()
                        .fill(Constants.primaryColor.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .scaleEffect(isAnimating ? 1 : 0.8)

                    Circle()
                        .fill(Constants.primaryColor.opacity(0.05))
                        .frame(width: 110, height: 110)
                        .scaleEffect(isAnimating ? 1 : 0.85)

                    Image(systemName: "building.2.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Constants.primaryColor, Constants.primaryColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isAnimating ? 1 : 0.5)
                }

                VStack(spacing: 16) {
                    Text("Welcome to BunkBite!")
                        .font(.urbanist(size: 32, weight: .bold))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)

                    Text("Select a canteen to browse\ndelicious menu items")
                        .font(.urbanist(size: 17, weight: .regular))
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)

                Button {
                    showCanteenSelector = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "building.2.circle.fill")
                            .font(.system(size: 22))

                        Text("Browse Canteens")
                            .font(.urbanist(size: 18, weight: .semibold))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: 280)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Constants.primaryColor, Constants.primaryColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .scaleEffect(isAnimating ? 1 : 0.9)
                .opacity(isAnimating ? 1 : 0)

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
}

struct MenuListView: View {
    @ObservedObject var canteenViewModel: CanteenViewModel
    @ObservedObject var menuViewModel: MenuViewModel
    @ObservedObject var cart: Cart
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var showLoginSheet: Bool
    @Binding var showCanteenSelector: Bool
    @Binding var selectedCategory: String?
    let categories: [String]
    let filteredItems: [MenuItem]
    let isReadOnly: Bool

    var body: some View {
        List {

            Section {

                 if !isReadOnly {
                     CanteenHeaderView(canteen: canteenViewModel.selectedCanteen, showCanteenSelector: $showCanteenSelector)
                 }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if !categories.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            MenuFilterChip(title: "All", isSelected: selectedCategory == nil, action: { withAnimation { selectedCategory = nil } })
                            ForEach(categories, id: \.self) { category in
                                MenuFilterChip(title: category, isSelected: selectedCategory == category, action: { withAnimation { selectedCategory = category } })
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if menuViewModel.isLoading {
                ForEach(0..<6, id: \.self) { _ in ShimmerMenuItemRow() }
            } else if filteredItems.isEmpty {
                ContentUnavailableView("No items available", systemImage: "tray")
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 40)
            } else {
                ForEach(filteredItems) { item in
                    MenuItemRow(item: item, cart: cart, authViewModel: authViewModel, showLoginSheet: $showLoginSheet, isReadOnly: isReadOnly)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Constants.backgroundColor)
        .refreshable {
            if let canteenId = canteenViewModel.selectedCanteen?.id {

                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await menuViewModel.fetchMenu(canteenId: canteenId) }
                    group.addTask { await canteenViewModel.refreshSelectedCanteen() }
                }
            }
        }
    }
}

struct ReadOnlyMenuSheet: View {
    @ObservedObject var canteenViewModel: CanteenViewModel
    @ObservedObject var menuViewModel: MenuViewModel
    @ObservedObject var cart: Cart
    @ObservedObject var authViewModel: AuthViewModel
    let categories: [String]
    let filteredItems: [MenuItem]
    @State private var selectedCategory: String? = nil

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            MenuListView(
                canteenViewModel: canteenViewModel,
                menuViewModel: menuViewModel,
                cart: cart,
                authViewModel: authViewModel,
                showLoginSheet: .constant(false),
                showCanteenSelector: .constant(false),
                selectedCategory: $selectedCategory,
                categories: categories,
                filteredItems: filteredItems,
                isReadOnly: true
            )
            .navigationTitle("Menu (View Only)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct MenuItemRow: View {
    let item: MenuItem
    @ObservedObject var cart: Cart
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var showLoginSheet: Bool
    var isReadOnly: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .frame(width: 80, height: 80)
                .overlay(Image(systemName: "fork.knife").font(.title).foregroundStyle(.secondary))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name).font(.urbanist(size: 17, weight: .semibold))
                Text("₹\(Int(item.price))").font(.urbanist(size: 20, weight: .bold)).foregroundStyle(Constants.primaryColor)
                if item.availableQuantity > 0 {
                    Text("\(item.availableQuantity) available")
                        .font(.urbanist(size: 12, weight: .regular))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Out of stock").font(.urbanist(size: 12, weight: .regular)).foregroundStyle(.red)
                }
            }

            Spacer()

            if !isReadOnly && item.availableQuantity > 0 {

                if cart.getQuantity(for: item) > 0 {
                    HStack(spacing: 12) {
                        Button {
                           let currentQuantity = cart.getQuantity(for: item)
                           if currentQuantity > 1 { cart.updateQuantity(for: item, quantity: currentQuantity - 1) }
                           else { cart.removeItem(item) }
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
                            if authViewModel.isAuthenticated {

                                if cart.getQuantity(for: item) < item.availableQuantity {
                                    cart.addItem(item)
                                }
                            } else {
                                showLoginSheet = true
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(cart.getQuantity(for: item) >= item.availableQuantity ? .gray : Constants.primaryColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(cart.getQuantity(for: item) >= item.availableQuantity)
                    }
                } else {
                    Button {
                        if authViewModel.isAuthenticated { cart.addItem(item) } else { showLoginSheet = true }
                    } label: {
                        Text("Add").font(.urbanist(size: 15, weight: .semibold))
                            .padding(.horizontal, 20).padding(.vertical, 8)
                            .background(Constants.primaryColor).foregroundStyle(.white).clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ShimmerMenuItemRow: View {
    var body: some View {
        HStack(spacing: 16) {

            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 70, height: 70)
                .shimmering()

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

            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 36)
                .shimmering()
        }
        .padding(.vertical, 4)
    }
}

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

struct CanteenHeaderView: View {
    let canteen: Canteen?
    @Binding var showCanteenSelector: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(canteen?.name ?? "")
                    .font(.urbanist(size: 22, weight: .bold))
                    .foregroundStyle(.black)

                Label(canteen?.place ?? "", systemImage: "mappin.circle")
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
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "E5E7EB"), lineWidth: 1.0)
        )
    }
}
