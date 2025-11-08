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

    var body: some View {
        NavigationStack {
            List {
                if cart.items.isEmpty {
                    ContentUnavailableView("Your cart is empty", systemImage: "cart")
                } else {
                    Section {
                        ForEach(cart.items) { cartItem in
                            CartItemRow(cartItem: cartItem, cart: cart)
                        }
                    } header: {
                        Text("Items (\(cart.items.count))")
                    }

                    Section {
                        HStack {
                            Text("Subtotal")
                            Spacer()
                            Text("₹\(Int(cart.totalAmount))")
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("Taxes & Fees")
                            Spacer()
                            Text("₹0")
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("Total")
                                .font(.urbanist(size: 17, weight: .semibold))
                            Spacer()
                            Text("₹\(Int(cart.totalAmount))")
                                .font(.urbanist(size: 20, weight: .bold))
                                .foregroundStyle(Constants.primaryColor)
                        }
                    } header: {
                        Text("Bill Details")
                    }

                    Section {
                        Button {
                            showPaymentSheet = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Proceed to Payment")
                                    .font(.urbanist(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Constants.primaryColor)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
            }
            .navigationTitle("Cart")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                if !cart.items.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            cart.clear()
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .sheet(isPresented: $showPaymentSheet) {
                PaymentSheet(cart: cart, canteen: canteen)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

struct CartItemRow: View {
    let cartItem: CartItem
    @ObservedObject var cart: Cart

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Item image
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.secondary)
                    )

                // Item details
                VStack(alignment: .leading, spacing: 4) {
                    Text(cartItem.menuItem.name)
                        .font(.urbanist(size: 16, weight: .semibold))
                        .foregroundStyle(.black)

                    Text("₹\(Int(cartItem.menuItem.price)) each")
                        .font(.urbanist(size: 14, weight: .regular))
                        .foregroundStyle(.gray)
                }

                Spacer()

                // Total price for this item
                Text("₹\(Int(cartItem.totalPrice))")
                    .font(.urbanist(size: 16, weight: .semibold))
                    .foregroundStyle(Constants.primaryColor)
            }

            // Quantity controls
            HStack {
                Spacer()

                HStack(spacing: 0) {
                    Button {
                        if cartItem.quantity > 1 {
                            cart.updateQuantity(for: cartItem.menuItem, quantity: cartItem.quantity - 1)
                        } else {
                            cart.removeItem(cartItem.menuItem)
                        }
                    } label: {
                        Image(systemName: cartItem.quantity == 1 ? "trash.fill" : "minus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(cartItem.quantity == 1 ? .red : Constants.primaryColor)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)

                    Text("\(cartItem.quantity)")
                        .font(.urbanist(size: 17, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 40)

                    Button {
                        cart.updateQuantity(for: cartItem.menuItem, quantity: cartItem.quantity + 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Constants.primaryColor)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1))
                )
            }
        }
        .padding(.vertical, 4)
    }
}
