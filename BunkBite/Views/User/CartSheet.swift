//
//  CartSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct CartSheet: View {
    @ObservedObject var cart: Cart
    let canteen: Canteen?

    @Environment(\.dismiss) var dismiss
    @State private var showPaymentSheet = false
    @State private var isAnimating = false

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
                            showPaymentSheet = true
                        } label: {
                            HStack(spacing: 12) {
                                Text("Proceed to Payment")
                                    .font(.urbanist(size: 18, weight: .semibold))
                                Image(systemName: "arrow.right.circle.fill")
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
        .sheet(isPresented: $showPaymentSheet) {
            PaymentSheet(cart: cart, canteen: canteen)
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
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
