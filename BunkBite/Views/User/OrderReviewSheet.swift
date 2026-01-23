//
//  OrderReviewSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 12/12/25.
//

import SwiftUI

struct OrderReviewSheet: View {
    @ObservedObject var cart: Cart
    @ObservedObject var orderViewModel: OrderViewModel
    @ObservedObject var authViewModel: AuthViewModel
    let canteen: Canteen
    
    @Environment(\.dismiss) var dismiss
    @State private var showPaymentGateway = false
    @State private var createdOrder: Order?
    @State private var paymentData: RazorpayPaymentInitiation?
    @State private var isProcessing = false
    @State private var navigateToDetail = false
    
    // Blocking Logic State
    @State private var showBlockingAlert = false
    @State private var blockingMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(colors: [Constants.primaryColor.opacity(0.05), .white], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerView
                        
                        orderItemsView
                        
                        priceBreakdownView
                        
                        checkoutButton
                    }
                }
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            // Razorpay Presentation
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
            // Detail Navigation (Order Success)
            .fullScreenCover(isPresented: $navigateToDetail, onDismiss: {
                if createdOrder != nil {
                     dismiss()
                }
            }) {
                if let order = createdOrder {
                    OrderSuccessView(order: order)
                }
            }
            // Alerts
            .alert("Error", isPresented: .constant(orderViewModel.errorMessage != nil)) {
                Button("OK") { orderViewModel.errorMessage = nil }
            } message: {
                Text(orderViewModel.errorMessage ?? "")
            }
            .alert("Canteen Closed", isPresented: $showBlockingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(blockingMessage)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "cart.fill")
                .font(.system(size: 50))
                .foregroundStyle(Constants.primaryColor)
            Text("Review Your Order")
                .font(.urbanist(size: 28, weight: .bold))
            Text(canteen.name)
                .font(.urbanist(size: 16, weight: .medium))
                .foregroundStyle(.gray)
        }
        .padding(.top, 20)
    }
    
    private var orderItemsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Order Items")
                .font(.urbanist(size: 18, weight: .semibold))
                .padding(.horizontal, 20)
            ForEach(cart.items) { item in OrderItemRow(item: item) }
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "E5E7EB"), lineWidth: 1.0)
        )
        .padding(.horizontal, 20)
    }
    
    private var priceBreakdownView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Subtotal")
                    .font(.urbanist(size: 16, weight: .medium))
                Spacer()
                Text("₹\(Int(cart.totalAmount))")
                    .font(.urbanist(size: 16, weight: .semibold))
            }
            Rectangle()
                .fill(Color(hex: "E5E7EB"))
                .frame(height: 1.0)
            HStack {
                Text("Total")
                    .font(.urbanist(size: 20, weight: .bold))
                Spacer()
                Text("₹\(Int(cart.totalAmount))")
                    .font(.urbanist(size: 24, weight: .bold))
                    .foregroundStyle(Constants.primaryColor)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "E5E7EB"), lineWidth: 1.0)
        )
        .padding(.horizontal, 20)
    }
    
    private var checkoutButton: some View {
        Button {
            startCheckout()
        } label: {
            HStack(spacing: 12) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Processing...")
                        .font(.urbanist(size: 18, weight: .semibold))
                } else {
                    Text("Pay ₹\(Int(cart.totalAmount))")
                        .font(.urbanist(size: 18, weight: .semibold))
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 22))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(LinearGradient(colors: [Constants.primaryColor, Constants.primaryColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
            .cornerRadius(16)
        }
        .disabled(isProcessing)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Checkout Logic
    
    private func startCheckout() {
        // Check Status First
        let (isAccepting, reason) = canteen.isAcceptingOrders
        if !isAccepting {
            blockingMessage = reason
            showBlockingAlert = true
            return
        }
        
        guard let token = authViewModel.authToken else { return }
        isProcessing = true
        
        Task {
            // 1. Create Order
            if let order = await orderViewModel.createOrder(canteenId: canteen.id, cart: cart, token: token) {
                createdOrder = order
                // 2. Initiate Payment immediately
                if let payData = await orderViewModel.initiatePayment(orderId: order.orderId, token: token) {
                    paymentData = payData
                    showPaymentGateway = true
                } else {
                    isProcessing = false
                }
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
                    createdOrder = verifiedOrder
                    // 3. Clear Cart and Show Detail
                    cart.clear()
                    
                    // Trigger Local Notification
                    NotificationManager.shared.sendOrderPlacedNotification(
                        orderId: verifiedOrder.orderId,
                        canteenName: canteen.name
                    )
                    
                    // Notify other views that order is completed
                    NotificationCenter.default.post(name: NSNotification.Name("OrderCompleted"), object: nil)
                    
                    navigateToDetail = true
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

// Helper Row
struct OrderItemRow: View {
    let item: CartItem
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Constants.primaryColor.opacity(0.1)).frame(width: 40, height: 40)
                Text("\(item.quantity)").font(.urbanist(size: 16, weight: .bold)).foregroundStyle(Constants.primaryColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.menuItem.name).font(.urbanist(size: 16, weight: .semibold))
                Text("₹\(Int(item.menuItem.price)) each").font(.urbanist(size: 14, weight: .regular)).foregroundStyle(.gray)
            }
            Spacer()
            Text("₹\(Int(item.totalPrice))").font(.urbanist(size: 16, weight: .bold)).foregroundStyle(Constants.primaryColor)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
    }
}
