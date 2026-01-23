//
//  MyOrdersView.swift
//  BunkBite
//
//  Created by Shreyanshu on 12/12/25.
//

import SwiftUI

struct MyOrdersView: View {
    @ObservedObject var orderViewModel: OrderViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var cart: Cart
    @EnvironmentObject var canteenViewModel: CanteenViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedFilter: OrderStatus? = nil
    @State private var selectedOrder: Order?
    @State private var showReorderConfirmation = false
    @State private var reorderedItemsCount = 0
    @State private var showCart = false
    @State private var showLoginSheet = false
    
    // Payment-related state
    @State private var showPaymentGateway = false
    @State private var paymentData: RazorpayPaymentInitiation?
    @State private var processingOrderId: String?
    @State private var isProcessing = false
    
    var filteredOrders: [Order] {
        // Show all orders
        let relevantOrders = orderViewModel.orders
        
        if let filter = selectedFilter {
            return relevantOrders.filter { $0.status == filter }
        }
        return relevantOrders
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        Text("My Orders")
                            .font(.custom("Urbanist-Bold", size: 28))
                            .foregroundStyle(.black)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Rectangle()
                        .fill(Color(hex: "E5E7EB"))
                        .frame(height: 1.0)
                        .padding(.horizontal, -20)
                        .padding(.top, 4)
                }
                .background(Color.white)
                
                // Orders List
                if orderViewModel.isLoading && orderViewModel.orders.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredOrders.isEmpty && !orderViewModel.isLoading {
                    Spacer()
                    EmptyOrdersView(filter: selectedFilter)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredOrders) { order in
                                UserOrderCard(
                                    order: order,
                                    onReorder: {
                                        reorderItems(from: order)
                                    },
                                    onViewDetails: {
                                        selectedOrder = order
                                    },
                                    onPayNow: { orderToPay in
                                        payForPendingOrder(orderToPay)
                                    },
                                    isProcessing: isProcessing,
                                    processingOrderId: processingOrderId
                                )
                            }
                        }
                        .padding(20)
                    }
                    .refreshable {
                        // Use detached task to prevent cancellation
                        await Task.detached { @MainActor in
                            guard let token = authViewModel.authToken else { return }
                            await orderViewModel.fetchMyOrders(token: token)
                        }.value
                    }
                }
            }
        }
        .onAppear {
            if !orderViewModel.hasLoadedInitially {
                orderViewModel.hasLoadedInitially = true
                // Use unstructured task that won't be cancelled
                Task.detached { @MainActor in
                    guard let token = authViewModel.authToken else {
                        print("❌ No auth token available")
                        return
                    }
                    print("🔄 Initial order fetch")
                    await orderViewModel.fetchMyOrders(token: token)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showCart) {
            CartSheet(cart: cart, authViewModel: authViewModel, canteen: canteenViewModel.selectedCanteen)
        }
        .fullScreenCover(isPresented: $showLoginSheet) {
            NewLoginSheet(authViewModel: authViewModel, isPresented: $showLoginSheet)
        }
        .fullScreenCover(item: $selectedOrder) { order in
            OrderDetailView(order: order, orderViewModel: orderViewModel, authViewModel: authViewModel)
        }
            .fullScreenCover(isPresented: $showPaymentGateway) {
                if let data = paymentData {
                    RazorpayCheckoutView(
                        paymentData: data,
                        onSuccess: { response in verifyPayment(response) },
                        onFailure: { error in
                            isProcessing = false
                            orderViewModel.errorMessage = error
                        },
                        onDismiss: {
                            showPaymentGateway = false
                            isProcessing = false
                        }
                    )
                }
            }
            .alert("Items Added to Cart", isPresented: $showReorderConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("\(reorderedItemsCount) items have been added to your cart")
            }
    }
    
    private func reorderItems(from order: Order) {
        // Clear existing cart or add to existing items
        var addedCount = 0
        
        for item in order.items {
            // Create a MenuItem from OrderLineItem
            let menuItem = MenuItem(
                id: item.menuItemId,
                name: item.name,
                image: nil,
                price: item.price,
                availableQuantity: 999, // Assume available
                createdAt: "",
                updatedAt: ""
            )
            
            // Add the quantity from the order
            for _ in 0..<item.quantity {
                cart.addItem(menuItem)
                addedCount += 1
            }
        }
        
        reorderedItemsCount = addedCount
        showReorderConfirmation = true
    }
    
    private func fetchOrders() async {
        guard let token = authViewModel.authToken else { 
            return 
        }
        await orderViewModel.fetchMyOrders(token: token)
    }
    
    private func payForPendingOrder(_ order: Order) {
        guard let token = authViewModel.authToken else { return }
        isProcessing = true
        processingOrderId = order.id
        
        Task {
            if let payData = await orderViewModel.initiatePayment(orderId: order.orderId, token: token) {
                paymentData = payData
                showPaymentGateway = true
            } else {
                isProcessing = false
            }
        }
    }
    
    private func verifyPayment(_ response: RazorpayPaymentResponse) {
        guard let token = authViewModel.authToken else { return }
        showPaymentGateway = false
        
        Task {
            if let verifiedOrder = await orderViewModel.verifyPayment(
                razorpayOrderId: response.razorpayOrderId,
                razorpayPaymentId: response.razorpayPaymentId,
                razorpaySignature: response.razorpaySignature,
                token: token
            ) {
                if verifiedOrder.paymentStatus == .success {
                    // Refresh orders to show updated status
                    Task { await fetchOrders() }
                    
                    // Show detail view
                    selectedOrder = verifiedOrder
                    
                    // Clear state
                    isProcessing = false
                    processingOrderId = nil
                } else {
                    isProcessing = false
                    orderViewModel.errorMessage = "Payment verification failed"
                }
            } else {
                isProcessing = false
            }
        }
    }
}

struct OrderFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.urbanist(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Constants.primaryColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    isSelected ? Constants.primaryColor : Constants.primaryColor.opacity(0.1)
                )
                .cornerRadius(20)
        }
    }
}

struct UserOrderCard: View {
    let order: Order
    let onReorder: () -> Void
    let onViewDetails: () -> Void
    let onPayNow: (Order) -> Void
    let isProcessing: Bool
    let processingOrderId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Order ID + Status Badge
            HStack {
                Text(order.orderId)
                    .font(.custom("Urbanist-Bold", size: 16))
                    .foregroundStyle(.black)
                
                Spacer()
                
                StatusBadge(status: order.status)
            }
            
            // Timestamp
            Text(formatDate(order.createdAt))
                .font(.custom("Urbanist-Medium", size: 14))
                .foregroundStyle(Color(hex: "6B7280"))
            
            // Items count
            Text("\(order.items.count) item\(order.items.count == 1 ? "" : "s")")
                .font(.custom("Urbanist-Regular", size: 14))
                .foregroundStyle(Color(hex: "6B7280"))
                .padding(.top, 4)
            
            // Item list (first 2 items)
            ForEach(order.items.prefix(2)) { item in
                Text("\(item.name) x\(item.quantity)")
                    .font(.custom("Urbanist-Regular", size: 14))
                    .foregroundStyle(.black)
            }
            
            if order.items.count > 2 {
                Text("+\(order.items.count - 2) more")
                    .font(.custom("Urbanist-Regular", size: 14))
                    .foregroundStyle(Color(hex: "6B7280"))
            }
            
            // Separator before Total
            Rectangle()
                .fill(Color(hex: "E5E7EB"))
                .frame(height: 1)
                .padding(.top, 8)
            
            // Total
            HStack {
                Text("Total")
                    .font(.custom("Urbanist-Medium", size: 14))
                    .foregroundStyle(Color(hex: "6B7280"))
                
                Spacer()
                
                Text("₹\(Int(order.totalAmount))")
                    .font(.custom("Urbanist-Bold", size: 18))
                    .foregroundStyle(Constants.primaryColor)
            }
            .padding(.top, 8)
            
            // Action Buttons
            HStack(spacing: 12) {
                // View Details Button
                Button(action: onViewDetails) {
                    Text("View Details")
                        .font(.custom("Urbanist-Bold", size: 14))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "C4C4C4"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "A0A0A0"), lineWidth: 1.0)
                        )
                }
                .buttonStyle(.plain)
                
                // Pay Now button for pending orders, Reorder for others
                if order.status == .pending {
                    Button(action: { onPayNow(order) }) {
                        HStack(spacing: 6) {
                            if isProcessing && processingOrderId == order.orderId {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 14))
                                Text("Pay Now")
                                    .font(.custom("Urbanist-Bold", size: 14))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Constants.primaryColor)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                } else {
                    Button(action: onReorder) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                            Text("Reorder")
                                .font(.custom("Urbanist-Bold", size: 14))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "0D1317"))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color(hex: "F9FAFB"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "E5E7EB"), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            // Fallback: try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateString) else {
                return dateString
            }
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d, h:mm a"
        return displayFormatter.string(from: date)
    }
}

struct StatusBadge: View {
    let status: OrderStatus
    
    var badgeColor: (background: Color, text: Color, border: Color) {
        switch status {
        case .preparing:
            return (Color(hex: "F9FFFC"), Color(hex: "0B7D3B"), Color(hex: "AECEBB"))
        case .cancelled:
            return (Color(hex: "FFDFE0"), Color(hex: "FF373D"), Color(hex: "FF373D"))
        case .pending:
            return (Color(hex: "FFF3E0"), Color(hex: "F57C00"), Color(hex: "F57C00"))
        case .paid:
            return (Color(hex: "E3F2FD"), Color(hex: "1976D2"), Color(hex: "1976D2"))
        case .ready:
            return (Color(hex: "F9FFFC"), Color(hex: "0B7D3B"), Color(hex: "AECEBB"))
        case .completed:
            return (Color(hex: "F0FFF6"), Color(hex: "0B7D3B"), Color(hex: "AECEBB"))
        }
    }
    
    var statusText: String {
        switch status {
        case .preparing: return "Cooking"
        case .cancelled: return "Cancelled"
        case .pending: return "Pending"
        case .paid: return "Paid"
        case .ready: return "Ready"
        case .completed: return "Completed"
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.system(size: 16))
                .foregroundStyle(badgeColor.text)
            
            Text(statusText)
                .font(.custom("Urbanist-Bold", size: 14))
                .foregroundStyle(badgeColor.text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(badgeColor.background)
        .cornerRadius(100)
        .overlay(
            RoundedRectangle(cornerRadius: 100)
                .stroke(badgeColor.border, lineWidth: 1.5)
        )
    }
}

struct EmptyOrdersView: View {
    let filter: OrderStatus?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(hex: "F3F4F6"))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "shippingbox")
                    .font(.system(size: 60))
                    .foregroundStyle(.gray.opacity(0.6))
            }
            
            VStack(spacing: 8) {
                Text(filter == nil ? "No orders yet" : "No \(filter!.rawValue) orders")
                    .font(.custom("Urbanist-Bold", size: 22))
                    .foregroundStyle(.black)
                
                Text("Your order history will appear here")
                    .font(.custom("Urbanist-Medium", size: 16))
                    .foregroundStyle(.gray)
            }
            
            Button {
                // Return to home/menu
                NotificationCenter.default.post(name: NSNotification.Name("SwitchToHome"), object: nil)
            } label: {
                Text("Start Ordering")
                    .font(.custom("Urbanist-Bold", size: 16))
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 32)
                    .background(Color(hex: "0D1317"))
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 40)
    }
}
