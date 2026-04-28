import SwiftUI

struct HomeView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var canteenViewModel: CanteenViewModel
    @ObservedObject var menuViewModel: MenuViewModel
    @ObservedObject var cart: Cart

    @Binding var showLoginSheet: Bool
    @Binding var showCanteenSelector: Bool

    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var isSearchOpen = false

    @State private var currentFoodIndex = 0
    @State private var currentText = ""
    @State private var isDeleting = false

    let foodItems = ["samosa", "tea", "coffee", "burger", "pizza"]

    @State private var menuLoadingTask: Task<Void, Never>? = nil

    var categories: [String] {
        let allCategories = menuViewModel.menuItems.compactMap { item -> String? in
            if item.name.localizedCaseInsensitiveContains("samosa") ||
               item.name.localizedCaseInsensitiveContains("pakora") {
                return "Snacks"
            } else if item.name.localizedCaseInsensitiveContains("rice") ||
                      item.name.localizedCaseInsensitiveContains("dal") ||
                      item.name.localizedCaseInsensitiveContains("chawal") {
                return "Meals"
            } else if item.name.localizedCaseInsensitiveContains("tea") ||
                      item.name.localizedCaseInsensitiveContains("coffee") ||
                      item.name.localizedCaseInsensitiveContains("chai") ||
                      item.name.localizedCaseInsensitiveContains("shake") {
                return "Drinks"
            }
            return "Other"
        }
        let cats = Array(Set(allCategories)).sorted()

        return cats
    }

    func getCategory(for item: MenuItem) -> String {
        if item.name.localizedCaseInsensitiveContains("samosa") ||
           item.name.localizedCaseInsensitiveContains("pakora") {
            return "Snacks"
        } else if item.name.localizedCaseInsensitiveContains("rice") ||
                  item.name.localizedCaseInsensitiveContains("dal") ||
                  item.name.localizedCaseInsensitiveContains("chawal") {
            return "Meals"
        } else if item.name.localizedCaseInsensitiveContains("tea") ||
                  item.name.localizedCaseInsensitiveContains("coffee") ||
                  item.name.localizedCaseInsensitiveContains("chai") ||
                  item.name.localizedCaseInsensitiveContains("shake") {
            return "Drinks"
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

    @Namespace private var animation

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {

                if canteenViewModel.selectedCanteen != nil {
                    HStack {

                        HStack(spacing: 8) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 20))
                                .foregroundStyle(Constants.primaryColor)

                            Picker("", selection: $canteenViewModel.selectedCanteen) {
                                Text("Select Canteen").tag(nil as Canteen?)
                                ForEach(canteenViewModel.canteens) { canteen in
                                    Text(canteen.isOpen ? canteen.name : "\(canteen.name) (Closed)")
                                        .tag(canteen as Canteen?)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .lineLimit(1)
                            .fixedSize()
                            .accentColor(.gray)
                        }

                        Spacer()

                        NavigationLink(destination: CartView(cart: cart, authViewModel: authViewModel, selectedTab: .constant(.menu))) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "cart")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.black)

                                if cart.items.count > 0 {
                                    Text("\(cart.items.reduce(0) { $0 + $1.quantity })")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(4)
                                        .background(Constants.primaryColor)
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .background(Color.white)
                } else {

                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(Color.green)

                        if canteenViewModel.isLoading && canteenViewModel.canteens.isEmpty {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Loading canteens...")
                                .font(.custom("Urbanist-Medium", size: 16))
                                .foregroundStyle(.gray)
                        } else {
                            Picker("", selection: $canteenViewModel.selectedCanteen) {
                                Text("Select Canteen").tag(nil as Canteen?)
                                ForEach(canteenViewModel.canteens) { canteen in
                                    Text(canteen.isOpen ? canteen.name : "\(canteen.name) (Closed)")
                                        .tag(canteen as Canteen?)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .accentColor(.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .background(Color.white)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        VStack(spacing: 24) {
                            if let canteen = canteenViewModel.selectedCanteen {

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Hungry?")
                                        .font(.custom("Urbanist-Bold", size: 32))
                                        .foregroundStyle(Color(hex: "0D1317"))

                                    Text("Order & Eat.")
                                        .font(.custom("Urbanist-Medium", size: 28))
                                        .foregroundStyle(Color.gray)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                if !isSearchOpen {
                                    Button {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            isSearchOpen = true
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: "magnifyingglass")
                                                .foregroundStyle(.black)
                                                .font(.system(size: 20))

                                            Text("Search for \(currentText)")
                                                .font(.custom("Urbanist-Medium", size: 16))
                                                .foregroundStyle(Color(hex: "4B5563"))

                                            Spacer()
                                        }
                                        .padding(16)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(hex: "E5E7EB"), lineWidth: 1.0)
                                        )
                                    }
                                    .buttonStyle(.scale)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }

                                let (isOpen, statusMessage) = canteen.isAcceptingOrders
                                if !isOpen {
                                    HStack {
                                        Image(systemName: "clock.badge.exclamationmark")
                                            .foregroundStyle(.white)
                                        Text(statusMessage)
                                            .font(.custom("Urbanist-Bold", size: 14))
                                            .foregroundStyle(.white)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.black.opacity(0.8))
                                    .cornerRadius(12)
                                }
                            } else {

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Hungry?")
                                        .font(.custom("Urbanist-Bold", size: 34))
                                        .foregroundStyle(.black)

                                    Text("Beat the rush.")
                                        .font(.custom("Urbanist-Italic", size: 24))
                                        .foregroundStyle(.gray)
                                }
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {

                                Button {
                                    withAnimation { selectedCategory = nil }
                                } label: {
                                    Text("All")
                                        .font(.custom("Urbanist-Medium", size: 16))
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(selectedCategory == nil ? Color(hex: "0D1317") : Color(hex: "F3F4F6"))
                                        .foregroundStyle(selectedCategory == nil ? .white : Color(hex: "4B5563"))
                                        .clipShape(Capsule())
                                }

                                ForEach(categories, id: \.self) { category in
                                    let isSelected = selectedCategory == category
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedCategory = category
                                        }
                                    } label: {
                                        Text(category)
                                            .font(.custom("Urbanist-Medium", size: 16))
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 12)
                                            .background(
                                                isSelected ? Color(hex: "0D1317") : Color(hex: "F3F4F6")
                                            )
                                            .foregroundStyle(isSelected ? .white : Color(hex: "4B5563"))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }

                        Rectangle()
                            .fill(Color(hex: "E5E7EB"))
                            .frame(height: 1.0)
                            .padding(.horizontal, -20)
                            .padding(.top, 4)

                        if menuViewModel.isLoading {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .tint(Constants.primaryColor)
                                Text("Loading delicious items...")
                                    .font(.custom("Urbanist-Medium", size: 14))
                                    .foregroundStyle(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        } else if filteredItems.isEmpty {
                             VStack(spacing: 16) {
                                 Image(systemName: "magnifyingglass")
                                     .font(.system(size: 40))
                                     .foregroundStyle(.gray.opacity(0.3))
                                 Text("No items found")
                                    .font(.custom("Urbanist-Bold", size: 18))
                                    .foregroundStyle(.gray)
                             }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 24) {
                                ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                    FoodItemCard(
                                        item: item,
                                        cart: cart,
                                        authViewModel: authViewModel,
                                        showLoginSheet: $showLoginSheet
                                    )
                                    .transition(.scale.combined(with: .opacity))

                                }
                            }
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filteredItems)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
                .refreshable {

                    await canteenViewModel.fetchAllCanteens()
                    if let canteenId = canteenViewModel.selectedCanteen?.id {
                        await menuViewModel.fetchMenu(canteenId: canteenId)
                    }
                }
            }

            ZStack {
                if isSearchOpen {

                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isSearchOpen = false
                            }
                        }
                        .transition(.opacity)

                    VStack(spacing: 0) {
                        SearchSheetView(
                            searchText: $searchText,
                            isSearchOpen: $isSearchOpen,
                            menuItems: menuViewModel.menuItems,
                            cart: cart,
                            authViewModel: authViewModel,
                            showLoginSheet: $showLoginSheet
                        )
                        .frame(maxHeight: searchText.isEmpty ? 350 : .infinity)
                        .background(Color.white)
                        .clipShape(RoundedCorner(radius: 30, corners: [.bottomLeft, .bottomRight]))
                        .overlay(
                            RoundedCorner(radius: 30, corners: [.bottomLeft, .bottomRight])
                                .stroke(Color(hex: "E5E7EB"), lineWidth: 1.0)
                        )
                        Spacer(minLength: 0)
                    }
                    .ignoresSafeArea(.all, edges: .top)
                    .transition(.move(edge: .top))
                }
            }
            .zIndex(200)
        }
        .onChange(of: isSearchOpen) { _, isOpen in
            if !isOpen {
                searchText = ""
            }
        }
        .onAppear {

            startTypingAnimation()
        }
        .onChange(of: canteenViewModel.selectedCanteen) { _, newCanteen in
             if let canteen = newCanteen {
                 menuLoadingTask?.cancel()
                 menuLoadingTask = Task { await menuViewModel.fetchMenu(canteenId: canteen.id) }
             }
        }
        .task {

            if canteenViewModel.canteens.isEmpty {
                await canteenViewModel.fetchAllCanteens()
            }

            if canteenViewModel.selectedCanteen == nil, let firstCanteen = canteenViewModel.canteens.first {
                canteenViewModel.selectedCanteen = firstCanteen
            }

            if let canteen = canteenViewModel.selectedCanteen, menuViewModel.menuItems.isEmpty {
                await menuViewModel.fetchMenu(canteenId: canteen.id)
            }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func startTypingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            let targetWord = foodItems[currentFoodIndex]

            if !isDeleting {

                if currentText.count < targetWord.count {
                    let index = targetWord.index(targetWord.startIndex, offsetBy: currentText.count)
                    currentText.append(targetWord[index])
                } else {

                    timer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isDeleting = true
                        startTypingAnimation()
                    }
                }
            } else {

                if currentText.count > 0 {
                    currentText.removeLast()
                } else {

                    timer.invalidate()
                    isDeleting = false
                    currentFoodIndex = (currentFoodIndex + 1) % foodItems.count
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        startTypingAnimation()
                    }
                }
            }
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {
    static var scale: ScaleButtonStyle { ScaleButtonStyle() }
}
