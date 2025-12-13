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
    
    @State private var selectedFilter: OrderStatus? = nil
    @State private var showOrderDetail = false
    @State private var selectedOrder: Order?
    
    var filteredOrders: [Order] {
        if let filter = selectedFilter {
            return orderViewModel.orders.filter { $0.status == filter }
        }
        return orderViewModel.orders
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
                            
                            OrderFilterChip(title: "Preparing", isSelected: selectedFilter == .preparing) {
                                selectedFilter = .preparing
                            }
                            
                            OrderFilterChip(title: "Ready", isSelected: selectedFilter == .ready) {
                                selectedFilter = .ready
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
                                    UserOrderCard(order: order)
                                        .onTapGesture {
                                            selectedOrder = order
                                            showOrderDetail = true
                                        }
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
            .sheet(isPresented: $showOrderDetail) {
                if let order = selectedOrder {
                    OrderDetailView(order: order, orderViewModel: orderViewModel, authViewModel: authViewModel)
                }
            }
        }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(order.orderId)")
                        .font(.urbanist(size: 16, weight: .bold))
                    
                    if let canteen = order.canteen {
                        Text(canteen.name)
                            .font(.urbanist(size: 14, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                }
                
                Spacer()
                
                StatusBadge(status: order.status)
            }
            
            // Items
            VStack(alignment: .leading, spacing: 8) {
                ForEach(order.items.prefix(2)) { item in
                    HStack {
                        Text("\(item.quantity)x")
                            .font(.urbanist(size: 14, weight: .semibold))
                            .foregroundStyle(Constants.primaryColor)
                            .frame(width: 30)
                        
                        Text(item.name)
                            .font(.urbanist(size: 14, weight: .medium))
                        
                        Spacer()
                        
                        Text("₹\(Int(item.subtotal))")
                            .font(.urbanist(size: 14, weight: .semibold))
                    }
                }
                
                if order.items.count > 2 {
                    Text("+\(order.items.count - 2) more items")
                        .font(.urbanist(size: 12, weight: .medium))
                        .foregroundStyle(.gray)
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Text(formatDate(order.createdAt))
                    .font(.urbanist(size: 12, weight: .regular))
                    .foregroundStyle(.gray)
                
                Spacer()
                
                Text("Total: ₹\(Int(order.totalAmount))")
                    .font(.urbanist(size: 16, weight: .bold))
                    .foregroundStyle(Constants.primaryColor)
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
