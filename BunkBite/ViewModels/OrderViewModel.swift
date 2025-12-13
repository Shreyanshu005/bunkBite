//
//  OrderViewModel.swift
//  BunkBite
//
//  Created by Shreyanshu on 12/12/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var currentOrder: Order?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    // MARK: - Create Order
    func createOrder(canteenId: String, cart: Cart, token: String) async -> Order? {
        isLoading = true
        errorMessage = nil
        
        // Convert cart items to CreateOrderItem
        let orderItems = cart.items.map { cartItem in
            CreateOrderItem(
                menuItemId: cartItem.menuItem.id,
                quantity: cartItem.quantity
            )
        }
        
        print("🛒 Creating order with \(orderItems.count) items")
        
        do {
            let order = try await apiService.createOrder(
                canteenId: canteenId,
                items: orderItems,
                token: token
            )
            currentOrder = order
            orders.insert(order, at: 0) // Add to beginning of list
            print("✅ Order created successfully: \(order.orderId)")
            isLoading = false
            return order
        } catch {
            errorMessage = "Failed to create order. Please try again."
            print("❌ Order creation error: \(error)")
            isLoading = false
            return nil
        }
    }
    
    // MARK: - Fetch Orders
    func fetchMyOrders(status: String? = nil, token: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            orders = try await apiService.getMyOrders(status: status, token: token)
            print("✅ Fetched \(orders.count) orders")
        } catch {
            errorMessage = "Failed to fetch orders"
            print("❌ Fetch orders error: \(error)")
        }
        
        isLoading = false
    }
    
    func fetchOrderById(id: String, token: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentOrder = try await apiService.getOrderById(id: id, token: token)
            print("✅ Fetched order: \(currentOrder?.orderId ?? "")")
        } catch {
            errorMessage = "Failed to fetch order details"
            print("❌ Fetch order error: \(error)")
        }
        
        isLoading = false
    }

    func fetchOrder(orderId: String, token: String) async -> Order? {
        do {
            let order = try await apiService.getOrderById(id: orderId, token: token)
            return order
        } catch {
            print("❌ Fetch order error: \(error)")
            return nil
        }
    }
    
    // MARK: - Payment
    func initiatePayment(orderId: String, token: String) async -> RazorpayPaymentInitiation? {
        isLoading = true
        errorMessage = nil
        
        do {
            let paymentData = try await apiService.initiatePayment(orderId: orderId, token: token)
            print("✅ Razorpay payment link created")
            isLoading = false
            return paymentData
        } catch {
            errorMessage = "Failed to initiate payment"
            print("❌ Payment initiation error: \(error)")
            isLoading = false
            return nil
        }
    }
    
    func verifyPayment(razorpayOrderId: String, razorpayPaymentId: String, razorpaySignature: String, token: String) async -> Order? {
        isLoading = true
        errorMessage = nil
        
        do {
            let order = try await apiService.verifyPayment(
                razorpayOrderId: razorpayOrderId,
                razorpayPaymentId: razorpayPaymentId,
                razorpaySignature: razorpaySignature,
                token: token
            )
            currentOrder = order
            
            // Update order in list if it exists
            if let index = orders.firstIndex(where: { $0.id == order.id }) {
                orders[index] = order
            }
            
            print("✅ Payment verified: \(order.paymentStatus)")
            isLoading = false
            return order
        } catch {
            errorMessage = "Payment verification failed"
            print("❌ Payment verification error: \(error)")
            isLoading = false
            return nil
        }
    }
    
    // MARK: - Helper Methods
    func clearCurrentOrder() {
        currentOrder = nil
    }
    
    func getOrdersByStatus(_ status: OrderStatus) -> [Order] {
        return orders.filter { $0.status == status }
    }
}
