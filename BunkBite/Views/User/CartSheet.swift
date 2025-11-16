//
//  CartSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI
import Razorpay

struct CartSheet: View {
    @ObservedObject var cart: Cart
    let canteen: Canteen?

    @Environment(\.dismiss) var dismiss
    @State private var showPaymentSheet = false
    @State private var isAnimating = false
    @State private var isProcessingPayment = false
    @State private var showSuccessPopup = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var razorpay: RazorpayCheckout?
    @State private var razorpayDelegate: RazorpayDelegate?
    @State private var showLoadingSheet = false
    @State private var showSuccessSheet = false
    @State private var showFailureSheet = false
    @State private var paymentSuccessId = ""

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Constants.primaryColor.opacity(0.05),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if cart.items.isEmpty {
                // Empty Cart State
                VStack(spacing: 32) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Constants.primaryColor.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimating ? 1 : 0.8)

                        Image(systemName: "cart")
                            .font(.system(size: 50))
                            .foregroundStyle(Constants.primaryColor)
                            .scaleEffect(isAnimating ? 1 : 0.5)
                    }

                    VStack(spacing: 12) {
                        Text("Your Cart is Empty")
                            .font(.urbanist(size: 28, weight: .bold))
                            .foregroundStyle(.black)

                        Text("Add items from the menu")
                            .font(.urbanist(size: 16, weight: .regular))
                            .foregroundStyle(.gray)
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)

                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 32) {
                        // Header with cart icon
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Constants.primaryColor.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(isAnimating ? 1 : 0.8)

                                Image(systemName: "cart.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(Constants.primaryColor)
                                    .scaleEffect(isAnimating ? 1 : 0.5)
                            }
                            .padding(.top, 40)

                            VStack(spacing: 8) {
                                Text("Your Cart")
                                    .font(.urbanist(size: 28, weight: .bold))
                                    .foregroundStyle(.black)

                                Text("\(cart.items.count) item\(cart.items.count == 1 ? "" : "s") added")
                                    .font(.urbanist(size: 15, weight: .regular))
                                    .foregroundStyle(.gray)
                            }
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                        }
                        .padding(.horizontal, 24)

                        // Cart Items
                        VStack(spacing: 12) {
                            ForEach(cart.items) { cartItem in
                                CartItemCard(cartItem: cartItem, cart: cart)
                            }
                        }
                        .padding(.horizontal, 24)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 30)

                        // Bill Details Card
                        VStack(spacing: 16) {
                            Text("Bill Details")
                                .font(.urbanist(size: 14, weight: .semibold))
                                .foregroundStyle(.gray)
                                .textCase(.uppercase)
                                .tracking(1)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(spacing: 12) {
                                HStack {
                                    Text("Subtotal")
                                        .font(.urbanist(size: 15, weight: .regular))
                                        .foregroundStyle(.gray)
                                    Spacer()
                                    Text("₹\(Int(cart.totalAmount))")
                                        .font(.urbanist(size: 15, weight: .semibold))
                                        .foregroundStyle(.black)
                                }

                                HStack {
                                    Text("Taxes & Fees")
                                        .font(.urbanist(size: 15, weight: .regular))
                                        .foregroundStyle(.gray)
                                    Spacer()
                                    Text("₹0")
                                        .font(.urbanist(size: 15, weight: .semibold))
                                        .foregroundStyle(.black)
                                }

                                Divider()

                                HStack {
                                    Text("Total")
                                        .font(.urbanist(size: 18, weight: .bold))
                                        .foregroundStyle(.black)
                                    Spacer()
                                    Text("₹\(Int(cart.totalAmount))")
                                        .font(.urbanist(size: 24, weight: .bold))
                                        .foregroundStyle(Constants.primaryColor)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                        .padding(.horizontal, 24)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 30)

                        // Proceed to Payment Button
                        Button {
                            initiateRazorpayPayment()
                        } label: {
                            HStack(spacing: 12) {
                                if isProcessingPayment {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Processing...")
                                        .font(.urbanist(size: 18, weight: .semibold))
                                } else {
                                    Text("Pay ₹\(Int(cart.totalAmount))")
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
                        .scaleEffect(isAnimating ? 1 : 0.9)

                        Spacer(minLength: 40)
                    }
                }
            }

            // Close button
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 32))
                            Text("Close")
                                .font(.urbanist(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.gray.opacity(0.6))
                    }
                    .padding()

                    Spacer()

                    if !cart.items.isEmpty {
                        Button(role: .destructive) {
                            cart.clear()
                        } label: {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.red.opacity(0.6))
                        }
                        .padding()
                    }
                }
                Spacer()
            }

            // Loading overlay (instead of sheet to avoid presentation conflicts)
            if showLoadingSheet {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                RazorpayLoadingOverlay()
                    .transition(.scale.combined(with: .opacity))
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
        .sheet(isPresented: $showSuccessSheet) {
            PaymentSuccessSheet(paymentId: paymentSuccessId) {
                dismiss()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFailureSheet) {
            PaymentFailureSheet(errorMessage: errorMessage) {
                // Retry
                initiateRazorpayPayment()
            } onDismiss: {
                showFailureSheet = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Razorpay Payment Functions

    private func initiateRazorpayPayment() {
        guard let canteen = canteen else {
            errorMessage = "Canteen information not available"
            showErrorAlert = true
            return
        }

        isProcessingPayment = true

        // Generate a temporary order ID
        let tempOrderId = "order_\(UUID().uuidString.prefix(14))"
        let amountInPaise = Int(cart.totalAmount * 100)

        print("\n🚀 INITIATING PAYMENT (Direct to Razorpay)")
        print("Order ID: \(tempOrderId)")
        print("Amount: ₹\(cart.totalAmount) (\(amountInPaise) paise)")
        print("Canteen: \(canteen.name)")
        print("Items: \(cart.items.count)\n")

        // Show loading overlay
        withAnimation(.easeInOut(duration: 0.2)) {
            showLoadingSheet = true
        }

        // Wait 0.8s for loading animation, then open Razorpay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.showLoadingSheet = false
            }

            // Small delay after loading sheet dismisses
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.openRazorpayCheckout(orderId: tempOrderId, amount: amountInPaise, key: Constants.razorpayKey)
            }
        }
    }

    private func openRazorpayCheckout(orderId: String, amount: Int, key: String) {
        print("\n" + String(repeating: "=", count: 60))
        print("🔔 OPENING RAZORPAY CHECKOUT - TEST MODE")
        print(String(repeating: "=", count: 60))
        print("📦 Order ID: \(orderId)")
        print("💰 Amount: ₹\(Double(amount) / 100) (\(amount) paise)")
        print("🔑 Using Test Key: \(key.prefix(20))...")
        print("🏪 Canteen: \(canteen?.name ?? "BunkBite")")
        print("📱 Mode: TEST (Use test cards for payment)")
        print(String(repeating: "=", count: 60) + "\n")

        // Create delegate
        let delegate = RazorpayDelegate(
            cart: cart,
            canteen: canteen,
            currentOrderId: orderId,
            onSuccess: { [self] paymentId, orderId in
                self.handlePaymentSuccess(paymentId: paymentId, orderId: orderId)
            },
            onFailure: { [self] error in
                self.handlePaymentFailure(error: error)
            }
        )
        razorpayDelegate = delegate

        // Initialize Razorpay
        razorpay = RazorpayCheckout.initWithKey(key, andDelegateWithData: delegate)

        // Configure payment options for TEST MODE
        let options: [String: Any] = [
            "amount": amount,
            "currency": "INR",
            "name": canteen?.name ?? "BunkBite",
            "description": "Order Payment - \(cart.items.count) items",
            "prefill": [
                "contact": "9876543210",
                "email": "test@bunkbite.com"
            ],
            "theme": [
                "color": "#f62f56"
            ],
            "notes": [
                "local_order_id": orderId,
                "canteen_id": canteen?.id ?? "",
                "canteen_name": canteen?.name ?? "",
                "items_count": String(cart.items.count),
                "test_mode": "true"
            ]
        ]

        print("💳 TEST PAYMENT OPTIONS:")
        print("- Test Card: 4111 1111 1111 1111")
        print("- CVV: Any 3 digits")
        print("- Expiry: Any future date")
        print("- Test UPI: success@razorpay")
        print("")

        // Open Razorpay checkout - find the topmost view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {

            // Find the topmost presented view controller
            var topController = rootViewController
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }

            print("✅ Launching Razorpay UI from: \(type(of: topController))\n")
            razorpay?.open(options, displayController: topController)
        } else {
            print("❌ Error: Could not find root view controller")
            handlePaymentFailure(error: "Unable to open payment window")
        }
    }

    private func handlePaymentSuccess(paymentId: String, orderId: String) {
        isProcessingPayment = false

        print("\n✅ Payment Successful!")
        print("📋 Order ID: \(orderId)")
        print("💳 Payment ID: \(paymentId)")
        print("💾 Order data saved - ready to send to backend\n")

        // Store payment ID and show success sheet
        paymentSuccessId = paymentId
        showSuccessSheet = true

        // Clear cart after a small delay to allow success sheet to show
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            cart.clear()
        }
    }

    private func handlePaymentFailure(error: String) {
        isProcessingPayment = false
        print("❌ Payment Failed: \(error)")
        errorMessage = error
        showFailureSheet = true
    }
}

struct CartItemCard: View {
    let cartItem: CartItem
    @ObservedObject var cart: Cart

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Item image
                Circle()
                    .fill(Constants.primaryColor.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: 24))
                            .foregroundStyle(Constants.primaryColor)
                    )

                // Item details
                VStack(alignment: .leading, spacing: 6) {
                    Text(cartItem.menuItem.name)
                        .font(.urbanist(size: 17, weight: .semibold))
                        .foregroundStyle(.black)

                    Text("₹\(Int(cartItem.menuItem.price)) × \(cartItem.quantity)")
                        .font(.urbanist(size: 14, weight: .regular))
                        .foregroundStyle(.gray)
                }

                Spacer()

                // Total price for this item
                Text("₹\(Int(cartItem.totalPrice))")
                    .font(.urbanist(size: 18, weight: .bold))
                    .foregroundStyle(Constants.primaryColor)
            }

            // Quantity controls
            HStack {
                Spacer()

                HStack(spacing: 12) {
                    Button {
                        if cartItem.quantity > 1 {
                            cart.updateQuantity(for: cartItem.menuItem, quantity: cartItem.quantity - 1)
                        } else {
                            cart.removeItem(cartItem.menuItem)
                        }
                    } label: {
                        Circle()
                            .fill(cartItem.quantity == 1 ? Color.red.opacity(0.1) : Constants.primaryColor.opacity(0.1))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: cartItem.quantity == 1 ? "trash.fill" : "minus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(cartItem.quantity == 1 ? .red : Constants.primaryColor)
                            )
                    }
                    .buttonStyle(.plain)

                    Text("\(cartItem.quantity)")
                        .font(.urbanist(size: 18, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 40)

                    Button {
                        cart.updateQuantity(for: cartItem.menuItem, quantity: cartItem.quantity + 1)
                    } label: {
                        Circle()
                            .fill(Constants.primaryColor.opacity(0.1))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Constants.primaryColor)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}


// MARK: - Razorpay Loading Overlay
struct RazorpayLoadingOverlay: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Constants.primaryColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Constants.primaryColor, lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }

            VStack(spacing: 8) {
                Text("Initializing Payment")
                    .font(.urbanist(size: 18, weight: .semibold))
                    .foregroundStyle(.black)

                Text("Please wait...")
                    .font(.urbanist(size: 14, weight: .regular))
                    .foregroundStyle(.gray)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Payment Success Sheet
struct PaymentSuccessSheet: View {
    let paymentId: String
    let onDismiss: () -> Void

    @State private var showConfetti = false
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Constants.primaryColor.opacity(0.05),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Success icon with animation
                ZStack {
                    Circle()
                        .fill(Constants.primaryColor.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1 : 0.5)

                    Circle()
                        .fill(Constants.primaryColor)
                        .frame(width: 100, height: 100)
                        .scaleEffect(isAnimating ? 1 : 0.5)

                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(isAnimating ? 1 : 0.3)
                }

                VStack(spacing: 12) {
                    Text("Payment Successful!")
                        .font(.urbanist(size: 32, weight: .bold))
                        .foregroundStyle(.black)
                        .opacity(isAnimating ? 1 : 0)

                    Text("Your order has been placed")
                        .font(.urbanist(size: 16, weight: .regular))
                        .foregroundStyle(.gray)
                        .opacity(isAnimating ? 1 : 0)

                    // Payment ID (optional - can be hidden)
                    Text("Payment ID: \(paymentId.prefix(20))...")
                        .font(.urbanist(size: 12, weight: .regular))
                        .foregroundStyle(.gray.opacity(0.7))
                        .padding(.top, 8)
                        .opacity(isAnimating ? 1 : 0)
                }

                Spacer()

                // Done button
                Button {
                    onDismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text("Done")
                            .font(.urbanist(size: 18, weight: .semibold))
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
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
                .padding(.horizontal, 24)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)

                Spacer(minLength: 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Payment Failure Sheet
struct PaymentFailureSheet: View {
    let errorMessage: String
    let onRetry: () -> Void
    let onDismiss: () -> Void

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.red.opacity(0.05),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Error icon with animation
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1 : 0.5)

                    Circle()
                        .fill(Color.red)
                        .frame(width: 100, height: 100)
                        .scaleEffect(isAnimating ? 1 : 0.5)

                    Image(systemName: "xmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(isAnimating ? 1 : 0.3)
                }

                VStack(spacing: 12) {
                    Text("Payment Failed")
                        .font(.urbanist(size: 32, weight: .bold))
                        .foregroundStyle(.black)
                        .opacity(isAnimating ? 1 : 0)

                    Text(errorMessage)
                        .font(.urbanist(size: 16, weight: .regular))
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(isAnimating ? 1 : 0)
                }

                // Test mode tips
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Test Mode Tips:")
                        .font(.urbanist(size: 14, weight: .semibold))
                        .foregroundStyle(.gray)

                    Text("• Test Card: 4111 1111 1111 1111")
                        .font(.urbanist(size: 12, weight: .regular))
                        .foregroundStyle(.gray.opacity(0.8))

                    Text("• Test UPI: success@razorpay")
                        .font(.urbanist(size: 12, weight: .regular))
                        .foregroundStyle(.gray.opacity(0.8))
                }
                .padding(16)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .opacity(isAnimating ? 1 : 0)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    // Retry button
                    Button {
                        onDismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onRetry()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text("Try Again")
                                .font(.urbanist(size: 18, weight: .semibold))
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 22))
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

                    // Cancel button
                    Button {
                        onDismiss()
                    } label: {
                        Text("Cancel")
                            .font(.urbanist(size: 16, weight: .semibold))
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .padding(.horizontal, 24)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)

                Spacer(minLength: 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
}

