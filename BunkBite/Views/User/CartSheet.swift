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
                                .font(.headline)
                            Spacer()
                            Text("₹\(Int(cart.totalAmount))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Constants.primaryColor)
                        }
                    } header: {
                        Text("Bill Details")
                    }

                    Section {
                        Button {
                            showPaymentSheet = true
                        } label: {
                            Text("Proceed to Payment")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Constants.primaryColor)
                        .listRowBackground(Color.clear)
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct CartItemRow: View {
    let cartItem: CartItem
    @ObservedObject var cart: Cart

    var body: some View {
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
                    .font(.headline)

                Text("₹\(Int(cartItem.menuItem.price))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Quantity controls
            HStack(spacing: 12) {
                Button {
                    cart.removeItem(cartItem.menuItem)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                }

                Text("\(cartItem.quantity)")
                    .font(.headline)
                    .frame(minWidth: 20)

                Button {
                    cart.addItem(cartItem.menuItem)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
            .foregroundStyle(Constants.primaryColor)
        }
        .padding(.vertical, 4)
    }
}
