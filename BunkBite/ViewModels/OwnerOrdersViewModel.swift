//
//  OwnerOrdersViewModel.swift
//  BunkBite
//
//  Created by Shreyanshu on 13/12/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class OwnerOrdersViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedStatus: String? = nil
    
    private let apiService = APIService.shared
    
    func fetchOrders(canteenId: String, status: String? = nil, token: String) async {
        isLoading = true
        errorMessage = nil
        selectedStatus = status
        
        do {
            orders = try await apiService.getCanteenOrders(canteenId: canteenId, status: status, token: token)
        } catch {
            errorMessage = "Failed to fetch orders"
            print("❌ Error fetching orders: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func updateOrderStatus(orderId: String, newStatus: String, token: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedOrder = try await apiService.updateOrderStatus(orderId: orderId, status: newStatus, token: token)
            
            // Update the order in the list
            if let index = orders.firstIndex(where: { $0.id == orderId }) {
                orders[index] = updatedOrder
            }
            
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update order status"
            print("❌ Error updating order status: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }
    
    func refreshOrders(canteenId: String, token: String) async {
        await fetchOrders(canteenId: canteenId, status: selectedStatus, token: token)
    }
    
    // Filter orders by status locally
    var pendingOrders: [Order] {
        orders.filter { $0.status == .pending }
    }
    
    var preparingOrders: [Order] {
        orders.filter { $0.status == .preparing }
    }
    
    var readyOrders: [Order] {
        orders.filter { $0.status == .ready }
    }
    
    var completedOrders: [Order] {
        orders.filter { $0.status == .completed }
    }
}
