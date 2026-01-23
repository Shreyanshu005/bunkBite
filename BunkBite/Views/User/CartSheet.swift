//
//  CartSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct CartSheet: View {
    @ObservedObject var cart: Cart
    @ObservedObject var authViewModel: AuthViewModel
    let canteen: Canteen?

    @Environment(\.dismiss) var dismiss
    @StateObject private var orderViewModel = OrderViewModel()
    @State private var showOrderReview = false
    @State private var isAnimating = false
    @State private var showSuccessPopup = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showLoadingSheet = false
    @State private var showSuccessSheet = false
    @State private var showFailureSheet = false
    @State private var paymentSuccessId = ""
    
    private var isCanteenOpen: Bool {
        canteen?.isAcceptingOrders.0 ?? true
    }

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
                            
                            Rectangle()
                                .fill(Color(hex: "E5E7EB"))
                                .frame(height: 1.0)
                                .padding(.horizontal, -24) // Touching screen edges
                                .padding(.top, 4)
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

                                Rectangle()
                                    .fill(Color(hex: "E5E7EB"))
                                    .frame(height: 1.0)
                                    .padding(.horizontal, -24) // Touching screen edges
                                    .padding(.top, 4)

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
                         .overlay(
                             RoundedRectangle(cornerRadius: 16)
                                 .stroke(Color(hex: "E5E7EB"), lineWidth: 1.0)
                         )
                        .padding(.horizontal, 24)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 30)

                        // Proceed to Checkout Button
                        Button {
                            if isCanteenOpen {
                                showOrderReview = true
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text(isCanteenOpen ? "Proceed to Checkout" : (canteen?.isAcceptingOrders.1 ?? "Canteen Closed"))
                                    .font(.custom("Urbanist-Bold", size: 18))
                                Image(systemName: isCanteenOpen ? "arrow.right.circle.fill" : "lock.fill")
                                    .font(.system(size: 22))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                isCanteenOpen ?
                                LinearGradient(
                                    colors: [Constants.primaryColor, Constants.primaryColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [Color.gray, Color.gray.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .disabled(!isCanteenOpen)
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
        .sheet(isPresented: $showOrderReview) {
            if let canteen = canteen {
                OrderReviewSheet(
                    cart: cart,
                    orderViewModel: orderViewModel,
                    authViewModel: authViewModel,
                    canteen: canteen
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OrderCompleted"))) { _ in
            dismiss()
        }
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
         .overlay(
             RoundedRectangle(cornerRadius: 12)
                 .stroke(Color(hex: "E5E7EB"), lineWidth: 1.0)
         )
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

                    // Payment ID
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

                    Text("• Use test cards or UPI IDs")
                        .font(.urbanist(size: 12, weight: .regular))
                        .foregroundStyle(.gray.opacity(0.8))

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
