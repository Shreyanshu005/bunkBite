//
//  MyOrdersView.swift
//  BunkBite
//
//  Created by Shreyanshu on 12/12/25.
//

import SwiftUI

struct MyOrdersView: View {
    @StateObject private var orderViewModel = OrderViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var cart: Cart
    @EnvironmentObject var canteenViewModel: CanteenViewModel
    
    @State private var selectedFilter: OrderStatus? = nil
    @State private var selectedOrder: Order?
    @State private var showReorderConfirmation = false
    @State private var reorderedItemsCount = 0
    @State private var showCart = false
    @State private var showLoginSheet = false
    
    var filteredOrders: [Order] {
        // Only show paid and completed orders
        let relevantOrders = orderViewModel.orders.filter { 
            $0.status == .paid || $0.status == .completed 
        }
        
        if let filter = selectedFilter {
            return relevantOrders.filter { $0.status == filter }
        }
        return relevantOrders
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            OrderFilterChip(title: "All", isSelected: selectedFilter == nil) {
                                selectedFilter = nil
                            }
                            
                            OrderFilterChip(title: "Paid", isSelected: selectedFilter == .paid) {
                                selectedFilter = .paid
                            }
                            
                            OrderFilterChip(title: "Completed", isSelected: selectedFilter == .completed) {
                                selectedFilter = .completed
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .background(Color.white)
                    
                    // Orders List
                    if orderViewModel.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if filteredOrders.isEmpty {
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
                                        }
                                    )
                                }
                            }
                            .padding(20)
                        }
                    }
                }
            }
            .navigationTitle("My Orders")
            .onAppear {
                fetchOrders()
            }
            .refreshable {
                fetchOrders()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CartToolbarButton(
                        authViewModel: authViewModel,
                        showCart: $showCart,
                        showLoginSheet: $showLoginSheet
                    )
                }
            }
            .sheet(isPresented: $showCart) {
                CartSheet(cart: cart, authViewModel: authViewModel, canteen: canteenViewModel.selectedCanteen)
            }
            .sheet(isPresented: $showLoginSheet) {
                LoginSheet(authViewModel: authViewModel)
            }
            .sheet(item: $selectedOrder) { order in
                OrderDetailView(order: order, orderViewModel: orderViewModel, authViewModel: authViewModel)
            }
            .alert("Items Added to Cart", isPresented: $showReorderConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("\(reorderedItemsCount) items have been added to your cart")
            }
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
    
    private func fetchOrders() {
        guard let token = authViewModel.authToken else { return }
        
        Task {
            await orderViewModel.fetchMyOrders(token: token)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(order.orderId)")
                        .font(.urbanist(size: 16, weight: .bold))
                    
                    if let canteen = order.canteen {
                        Label(canteen.name, systemImage: "building.2.fill")
                            .font(.urbanist(size: 13, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                }
                
                Spacer()
                
                StatusBadge(status: order.status)
            }
            
            Divider()
            
            // Order Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(formatDate(order.createdAt), systemImage: "clock.fill")
                        .font(.urbanist(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // Show payment status
                    Label(order.paymentStatus.rawValue.capitalized, systemImage: order.paymentId != nil ? "creditcard.fill" : "banknote.fill")
                        .font(.urbanist(size: 12, weight: .medium))
                        .foregroundStyle(order.paymentStatus == .success ? .green : .secondary)
                }
            }
            
            Divider()
            
            // Items
            VStack(alignment: .leading, spacing: 8) {
                ForEach(order.items.prefix(3)) { item in
                    HStack(alignment: .top) {
                        Text("\(item.quantity)x")
                            .font(.urbanist(size: 14, weight: .semibold))
                            .foregroundStyle(Constants.primaryColor)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.urbanist(size: 14, weight: .medium))
                            
                            Text("₹\(Int(item.price)) each")
                                .font(.urbanist(size: 11, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("₹\(Int(item.subtotal))")
                            .font(.urbanist(size: 14, weight: .semibold))
                    }
                }
                
                if order.items.count > 3 {
                    Text("+\(order.items.count - 3) more items")
                        .font(.urbanist(size: 12, weight: .medium))
                        .foregroundStyle(.gray)
                        .padding(.leading, 30)
                }
            }
            
            Divider()
            
            // Footer with Total and Action Buttons
            VStack(spacing: 12) {
                // Total Amount
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Amount")
                            .font(.urbanist(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        Text("₹\(Int(order.totalAmount))")
                            .font(.urbanist(size: 18, weight: .bold))
                            .foregroundStyle(Constants.primaryColor)
                    }
                    
                    Spacer()
                }
                
                // Action Buttons
                HStack(spacing: 8) {
                    // View Details Button
                    Button(action: onViewDetails) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text.fill")
                            Text("View Details")
                        }
                        .font(.urbanist(size: 14, weight: .semibold))
                        .foregroundStyle(Constants.primaryColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Constants.primaryColor.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    // Reorder Button
                    Button(action: onReorder) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Reorder")
                        }
                        .font(.urbanist(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Constants.primaryColor)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d, h:mm a"
        return displayFormatter.string(from: date)
    }
}

struct StatusBadge: View {
    let status: OrderStatus
    
    var statusColor: Color {
        switch status {
        case .pending: return .orange
        case .paid: return .blue
        case .preparing: return .purple
        case .ready: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
    
    var statusText: String {
        status.rawValue.capitalized
    }
    
    var body: some View {
        Text(statusText)
            .font(.urbanist(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor)
            .cornerRadius(12)
    }
}

struct EmptyOrdersView: View {
    let filter: OrderStatus?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.5))
            
            Text(filter == nil ? "No orders yet" : "No \(filter!.rawValue) orders")
                .font(.urbanist(size: 20, weight: .semibold))
                .foregroundStyle(.gray)
            
            Text("Your orders will appear here")
                .font(.urbanist(size: 14, weight: .regular))
                .foregroundStyle(.gray.opacity(0.7))
        }
    }
}
