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
    @State private var showPaymentSheet = false
    @State private var createdOrder: Order?
    @State private var isCreatingOrder = false
    
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
                    VStack(spacing: 24) {
                        // Header
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
                        
                        // Order Items
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Order Items")
                                .font(.urbanist(size: 18, weight: .semibold))
                                .padding(.horizontal, 20)
                            
                            ForEach(cart.items) { item in
                                OrderItemRow(item: item)
                            }
                        }
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 10)
                        .padding(.horizontal, 20)
                        
                        // Price Breakdown
                        VStack(spacing: 12) {
                            HStack {
                                Text("Subtotal")
                                    .font(.urbanist(size: 16, weight: .medium))
                                Spacer()
                                Text("₹\(Int(cart.totalAmount))")
                                    .font(.urbanist(size: 16, weight: .semibold))
                            }
                            
                            Divider()
                            
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
                        .shadow(color: .black.opacity(0.05), radius: 10)
                        .padding(.horizontal, 20)
                        
                        // Place Order Button
                        Button {
                            placeOrder()
                        } label: {
                            HStack(spacing: 12) {
                                if isCreatingOrder {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Creating Order...")
                                        .font(.urbanist(size: 18, weight: .semibold))
                                } else {
                                    Text("Place Order")
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
                        .disabled(isCreatingOrder)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Order Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(orderViewModel.errorMessage != nil)) {
                Button("OK") {
                    orderViewModel.errorMessage = nil
                }
            } message: {
                Text(orderViewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $showPaymentSheet) {
                if let order = createdOrder {
                    OrderPaymentSheet(order: order, orderViewModel: orderViewModel, authViewModel: authViewModel)
                }
            }
        }
    }
    
    private func placeOrder() {
        guard let token = authViewModel.authToken else { return }
        
        isCreatingOrder = true
        
        Task {
            if let order = await orderViewModel.createOrder(
                canteenId: canteen.id,
                cart: cart,
                token: token
            ) {
                createdOrder = order
                isCreatingOrder = false
                showPaymentSheet = true
            } else {
                isCreatingOrder = false
            }
        }
    }
}

struct OrderItemRow: View {
    let item: CartItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Quantity Badge
            ZStack {
                Circle()
                    .fill(Constants.primaryColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text("\(item.quantity)")
                    .font(.urbanist(size: 16, weight: .bold))
                    .foregroundStyle(Constants.primaryColor)
            }
            
            // Item Details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.menuItem.name)
                    .font(.urbanist(size: 16, weight: .semibold))
                
                Text("₹\(Int(item.menuItem.price)) each")
                    .font(.urbanist(size: 14, weight: .regular))
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            // Subtotal
            Text("₹\(Int(item.totalPrice))")
                .font(.urbanist(size: 16, weight: .bold))
                .foregroundStyle(Constants.primaryColor)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
