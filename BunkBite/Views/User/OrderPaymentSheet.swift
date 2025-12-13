//
//  OrderPaymentSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 12/12/25.
//

import SwiftUI

struct OrderPaymentSheet: View {
    let order: Order
    @ObservedObject var orderViewModel: OrderViewModel
    @ObservedObject var authViewModel: AuthViewModel
    
    @Environment(\.dismiss) var dismiss
    @State private var isProcessingPayment = false
    @State private var showRazorpayCheckout = false
    @State private var paymentData: RazorpayPaymentInitiation?
    @State private var showOrderDetail = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isAnimating = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Constants.primaryColor.opacity(0.05),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Constants.primaryColor.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(isAnimating ? 1 : 0.8)
                                
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(Constants.primaryColor)
                                    .scaleEffect(isAnimating ? 1 : 0.5)
                            }
                            .padding(.top, 40)
                            
                            VStack(spacing: 8) {
                                Text("Complete Payment")
                                    .font(.urbanist(size: 28, weight: .bold))
                                
                                Text("Order #\(order.orderId)")
                                    .font(.urbanist(size: 15, weight: .regular))
                                    .foregroundStyle(.gray)
                            }
                            .opacity(isAnimating ? 1 : 0)
                        }
                        
                        // Total Amount Card
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Amount")
                                    .font(.urbanist(size: 14, weight: .medium))
                                    .foregroundStyle(.gray)
                                
                                Text("₹\(Int(order.totalAmount))")
                                    .font(.urbanist(size: 32, weight: .bold))
                                    .foregroundStyle(Constants.primaryColor)
                            }
                            Spacer()
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 10)
                        .padding(.horizontal, 24)
                        .opacity(isAnimating ? 1 : 0)
                        
                        // Pay Now Button
                        Button {
                            initiatePayment()
                        } label: {
                            HStack(spacing: 12) {
                                if isProcessingPayment {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Processing...")
                                        .font(.urbanist(size: 18, weight: .semibold))
                                } else {
                                    Text("Pay ₹\(Int(order.totalAmount))")
                                        .font(.urbanist(size: 18, weight: .semibold))
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 22))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Constants.primaryColor, Constants.primaryColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Constants.primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isProcessingPayment)
                        .padding(.horizontal, 24)
                        .opacity(isAnimating ? 1 : 0)
                        
                        Spacer(minLength: 40)
                    }
                }
                
                // Close button
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.gray.opacity(0.3))
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isAnimating = true
                }
            }
            .alert("Payment Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .fullScreenCover(isPresented: $showRazorpayCheckout) {
                if let paymentData = paymentData {
                    RazorpayCheckoutView(
                        paymentData: paymentData,
                        onSuccess: { response in
                            handlePaymentSuccess(response)
                        },
                        onFailure: { error in
                            handlePaymentFailure(error)
                        },
                        onDismiss: {
                            showRazorpayCheckout = false
                            errorMessage = "Payment cancelled"
                            showErrorAlert = true
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showOrderDetail) {
                if let updatedOrder = orderViewModel.currentOrder {
                    OrderDetailView(order: updatedOrder, orderViewModel: orderViewModel, authViewModel: authViewModel)
                }
            }
        }
    }
    
    private func initiatePayment() {
        guard let token = authViewModel.authToken else { return }
        
        isProcessingPayment = true
        
        Task {
            if let data = await orderViewModel.initiatePayment(orderId: order.orderId, token: token) {
                paymentData = data
                isProcessingPayment = false
                showRazorpayCheckout = true
            } else {
                isProcessingPayment = false
                errorMessage = "Failed to initiate payment"
                showErrorAlert = true
            }
        }
    }
    
    private func handlePaymentSuccess(_ response: RazorpayPaymentResponse) {
        guard let token = authViewModel.authToken else { return }
        
        showRazorpayCheckout = false
        isProcessingPayment = true
        
        Task {
            if let verifiedOrder = await orderViewModel.verifyPayment(
                razorpayOrderId: response.razorpayOrderId,
                razorpayPaymentId: response.razorpayPaymentId,
                razorpaySignature: response.razorpaySignature,
                token: token
            ) {
                isProcessingPayment = false
                if verifiedOrder.paymentStatus == .success {
                    showOrderDetail = true
                } else {
                    errorMessage = "Payment verification failed"
                    showErrorAlert = true
                }
            } else {
                isProcessingPayment = false
                errorMessage = "Payment verification failed"
                showErrorAlert = true
            }
        }
    }
    
    private func handlePaymentFailure(_ error: String) {
        showRazorpayCheckout = false
        errorMessage = error
        showErrorAlert = true
    }
}
