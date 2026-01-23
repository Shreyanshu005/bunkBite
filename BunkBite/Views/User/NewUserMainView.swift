
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
            
            // Main Content Area
            // Switch between different tabs
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
            
            // Floating Tab Bar
            CustomFloatingTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 14) // Pixel perfect 14px from bottom
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .ignoresSafeArea(.keyboard) 
        .environmentObject(authViewModel)
        .environmentObject(canteenViewModel)
        .environmentObject(cart)
        .onAppear {
            authViewModel.checkExistingAuth()
            
            // Listen for tab switch notifications
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("SwitchToOrders"),
                object: nil,
                queue: .main
            ) { _ in
                selectedTab = .orders
            }
            
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("SwitchToHome"),
                object: nil,
                queue: .main
            ) { _ in
                selectedTab = .menu
            }
            
            // Fetch orders after successful login
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("UserDidLogin"),
                object: nil,
                queue: .main
            ) { _ in
                Task {
                    if let token = authViewModel.authToken {
                        await orderViewModel.fetchMyOrders(token: token)
                        orderViewModel.hasLoadedInitially = true
                    }
                }
            }
            
            // Refresh orders after order placement
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("RefreshOrders"),
                object: nil,
                queue: .main
            ) { _ in
                Task {
                    if let token = authViewModel.authToken {
                        await orderViewModel.fetchMyOrders(token: token)
                    }
                }
            }
            
            // Clear all data on logout
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("UserDidLogout"),
                object: nil,
                queue: .main
            ) { _ in
                // Clear orders
                orderViewModel.orders = []
                orderViewModel.hasLoadedInitially = false
                
                // Clear cart
                cart.clear()
            }
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
