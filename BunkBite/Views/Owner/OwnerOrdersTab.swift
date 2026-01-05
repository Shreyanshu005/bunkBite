//
//  OwnerOrdersTab.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct OwnerOrdersTab: View {
    let canteen: Canteen?
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var orderCompletedTrigger: Bool
    let onSelectCanteen: () -> Void
    
    @StateObject private var ordersViewModel = OwnerOrdersViewModel()
    @State private var selectedFilter: OrderStatusFilter = .all
    
    enum OrderStatusFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case preparing = "Preparing"
        case ready = "Ready"
        case completed = "Completed"
        
        var apiValue: String? {
            switch self {
            case .all: return nil
            case .pending: return "pending"
            case .preparing: return "preparing"
            case .ready: return "ready"
            case .completed: return "completed"
            }
        }
    }

    var body: some View {
        NavigationStack {
            if let selectedCanteen = canteen {
                ordersView(for: selectedCanteen)
            } else {
                noCanteenView
            }
        }
    }

    private var noCanteenView: some View {
        List {
            ContentUnavailableView {
                Label("No Canteen Selected", systemImage: "building.2")
            } description: {
                Text("Select a canteen to view orders")
            } actions: {
                Button("Select Canteen") {
                    onSelectCanteen()
                }
                .buttonStyle(.borderedProminent)
                .tint(Constants.primaryColor)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Orders")
    }

    private func ordersView(for selectedCanteen: Canteen) -> some View {
        VStack(spacing: 0) {
            // Status Filter Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(OrderStatusFilter.allCases, id: \.self) { filter in
                        OwnerFilterChip(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                            Task {
                                await loadOrders(for: selectedCanteen)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
            
            Divider()
            
            // Orders List
            if ordersViewModel.isLoading && ordersViewModel.orders.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if ordersViewModel.orders.isEmpty {
                ContentUnavailableView(
                    "No \(selectedFilter.rawValue) Orders",
                    systemImage: "list.clipboard",
                    description: Text("Orders will appear here when customers place them")
                )
            } else {
                List {
                    ForEach(ordersViewModel.orders) { order in
                        OrdersTabCard(
                            order: order,
                            onStatusUpdate: { newStatus in
                                await updateStatus(orderId: order.id, newStatus: newStatus)
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await loadOrders(for: selectedCanteen)
                }
            }
        }
        .navigationTitle("Orders")
        .task(id: selectedCanteen.id) {
            await loadOrders(for: selectedCanteen)
        }
        .onChange(of: orderCompletedTrigger) {
            Task {
                await loadOrders(for: selectedCanteen)
            }
        }
    }
    
    private func loadOrders(for canteen: Canteen) async {
        guard let token = authViewModel.authToken else { return }
        await ordersViewModel.fetchOrders(
            canteenId: canteen.id,
            status: selectedFilter.apiValue,
            token: token
        )
    }
    
    private func updateStatus(orderId: String, newStatus: String) async {
        guard let token = authViewModel.authToken else { return }
        let success = await ordersViewModel.updateOrderStatus(
            orderId: orderId,
            newStatus: newStatus,
            token: token
        )
        
        if success {
            // Optionally show success feedback
            print("✅ Order status updated successfully")
        }
    }
}

// MARK: - Owner Filter Chip
private struct OwnerFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.urbanist(size: 14, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Constants.primaryColor : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Orders Tab Card
private struct OrdersTabCard: View {
    let order: Order
    let onStatusUpdate: (String) async -> Void
    
    @State private var showStatusMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Order ID and Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(order.orderId)")
                        .font(.urbanist(size: 16, weight: .bold))
                    
                    HStack(spacing: 12) {
                        Label(formatDate(order.createdAt), systemImage: "clock.fill")
                            .font(.urbanist(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        // Show payment status
                        Label(order.paymentStatus.rawValue.capitalized, systemImage: order.paymentId != nil ? "creditcard.fill" : "banknote.fill")
                            .font(.urbanist(size: 12, weight: .medium))
                            .foregroundStyle(order.paymentStatus == .success ? .green : .secondary)
                    }
                }
                
                Spacer()
                
                StatusBadge(status: order.status)
            }
            
            Divider()
            
            // Items
            VStack(alignment: .leading, spacing: 8) {
                ForEach(order.items) { item in
                    HStack(alignment: .top) {
                        Text("\(item.quantity)x")
                            .font(.urbanist(size: 14, weight: .semibold))
                            .foregroundStyle(Constants.primaryColor)
                            .frame(width: 30, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.urbanist(size: 14, weight: .medium))
                            
                            Text("₹\(Int(item.price)) each")
                                .font(.urbanist(size: 11, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("₹\(Int(item.price) * item.quantity)")
                            .font(.urbanist(size: 14, weight: .semibold))
                    }
                }
            }
            
            Divider()
            
            // Footer with Total and Actions
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
                
                if order.status != .completed && order.status != .cancelled {
                    if order.status == .preparing {
                        Button {
                            Task {
                                await onStatusUpdate("ready")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mark Ready")
                            }
                            .font(.urbanist(size: 14, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Constants.primaryColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }
                    } else if order.status == .ready {
                        Button {
                            Task {
                                await onStatusUpdate("completed")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Complete")
                            }
                            .font(.urbanist(size: 14, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.green)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func formatDate(_ dateString: String) -> String {
        return DateFormatter.formatOrderDate(dateString)
    }
}
