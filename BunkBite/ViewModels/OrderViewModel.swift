import Foundation
import SwiftUI
import Combine

@MainActor
class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var currentOrder: Order?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoadedInitially = false

    private let apiService = APIService.shared

    func createOrder(canteenId: String, cart: Cart, token: String) async -> Order? {
        isLoading = true
        errorMessage = nil

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
            orders.insert(order, at: 0)
            print("✅ Order created successfully: \(order.orderId)")
            isLoading = false
            return order
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.localizedDescription
            } else {
                errorMessage = "Failed to create order. Please try again."
            }
            print("❌ Order creation error: \(error)")
            isLoading = false
            return nil
        }
    }

    func fetchMyOrders(status: String? = nil, token: String) async {

        guard !isLoading else {
            print("⚠️ Already loading orders, skipping duplicate request")
            return
        }

        isLoading = true
        errorMessage = nil

        print("🔄 Fetching orders from API...")

        do {
            let fetchedOrders = try await apiService.getMyOrders(status: status, token: token)
            orders = fetchedOrders
            print("✅ Fetched \(orders.count) orders - Data refreshed")
        } catch {
            errorMessage = error.localizedDescription
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

    func fetchOrder(orderId: String, internalId: String, token: String) async -> Order? {

        if let existing = orders.first(where: { $0.id == internalId }) {

            Task {
                do {
                    let updated = try await apiService.getOrderById(id: internalId, token: token)
                    await MainActor.run {
                        if let index = self.orders.firstIndex(where: { $0.id == internalId }) {
                            self.orders[index] = updated
                        }
                    }
                } catch {
                    print("⚠️ Background refresh failed for order \(internalId)")
                }
            }
            return existing
        }

        do {
            let order = try await apiService.getOrderById(id: internalId, token: token)

            if !orders.contains(where: { $0.id == order.id }) {
                orders.append(order)
            }
            return order
        } catch {
            print("❌ Fetch order error: \(error)")
            return nil
        }
    }

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

    func clearCurrentOrder() {
        currentOrder = nil
    }

    func getOrdersByStatus(_ status: OrderStatus) -> [Order] {
        return orders.filter { $0.status == status }
    }
}
