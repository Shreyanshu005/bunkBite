import SwiftUI

struct NewUserMainView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var canteenViewModel = CanteenViewModel()
    @StateObject private var menuViewModel = MenuViewModel()
    @StateObject private var cart = Cart()
    @StateObject private var orderViewModel = OrderViewModel()

    @State private var showLoginSheet = false
    @State private var showCanteenSelector = false
    @State private var selectedTab: CustomFloatingTabBar.Tab = .menu

    init() {}

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            switch selectedTab {
            case .menu:
                HomeView(
                    authViewModel: authViewModel,
                    canteenViewModel: canteenViewModel,
                    menuViewModel: menuViewModel,
                    cart: cart,
                    showLoginSheet: $showLoginSheet,
                    showCanteenSelector: $showCanteenSelector
                )
            case .orders:
                MyOrdersView(orderViewModel: orderViewModel)
            case .profile:
                UserProfileView(
                     viewModel: authViewModel,
                     orderViewModel: orderViewModel,
                     showLoginSheet: $showLoginSheet
                )
            }

            CustomFloatingTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 14)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .ignoresSafeArea(.keyboard)
        .environmentObject(authViewModel)
        .environmentObject(canteenViewModel)
        .environmentObject(cart)
        .onAppear {
            authViewModel.checkExistingAuth()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SwitchToOrders"))) { _ in
            selectedTab = .orders
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SwitchToHome"))) { _ in
            selectedTab = .menu
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UserDidLogin"))) { _ in
            Task {
                if let token = authViewModel.authToken {
                    await orderViewModel.fetchMyOrders(token: token)
                    orderViewModel.hasLoadedInitially = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RefreshOrders"))) { _ in
            Task {
                if let token = authViewModel.authToken {
                    await orderViewModel.fetchMyOrders(token: token)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UserDidLogout"))) { _ in
            orderViewModel.orders = []
            orderViewModel.hasLoadedInitially = false

            cart.clear()
        }
        .sheet(isPresented: $showLoginSheet) {
            NewLoginSheet(authViewModel: authViewModel, isPresented: $showLoginSheet)
                .presentationDetents([.fraction(0.5), .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.white)
                .interactiveDismissDisabled(false)
        }
    }
}
