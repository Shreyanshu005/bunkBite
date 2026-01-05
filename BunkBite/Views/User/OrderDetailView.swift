//
//  OrderDetailView.swift
//  BunkBite
//
//  Created by Shreyanshu on 12/12/25.
//

import SwiftUI

struct OrderDetailView: View {
    let order: Order
    @ObservedObject var orderViewModel: OrderViewModel
    @ObservedObject var authViewModel: AuthViewModel
    
    @Environment(\.dismiss) var dismiss
    @State private var isAnimating = false
    @State private var fullOrder: Order
    
    init(order: Order, orderViewModel: OrderViewModel, authViewModel: AuthViewModel) {
        self.order = order
        self.orderViewModel = orderViewModel
        self.authViewModel = authViewModel
        _fullOrder = State(initialValue: order)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Constants.textColor)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 5)
                }
                
                Spacer()
                
                Text("Order Details")
                    .font(.urbanist(size: 18, weight: .bold))
                    .foregroundStyle(Constants.textColor)
                
                Spacer()
                
                // Invisible spacer for balance
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .padding(8)
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)
            .background(Color.white)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Success Header (if paid and not cancelled)
                    if fullOrder.paymentStatus == .success && fullOrder.status != .cancelled {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                    .scaleEffect(isAnimating ? 1 : 0.8)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.green)
                            }
                            
                            Text("Order Placed Successfully!")
                                .font(.urbanist(size: 22, weight: .bold))
                                .foregroundStyle(Constants.textColor)
                            
                            Text("Order #\(fullOrder.orderId)")
                                .font(.urbanist(size: 16, weight: .medium))
                                .foregroundStyle(.gray)
                        }
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // QR Code (if ready or paid)
                    if (fullOrder.status == .ready || fullOrder.status == .paid), let qrCodeString = fullOrder.qrCode {
                        VStack(spacing: 16) {
                            Text("Show this QR code at pickup")
                                .font(.urbanist(size: 16, weight: .semibold))
                                .foregroundStyle(.gray)
                            
                            if let qrImage = decodeBase64ToImage(qrCodeString) {
                                Image(uiImage: qrImage)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                                    .padding(20)
                                    .background(Color.white)
                                    .cornerRadius(20)
                                    .shadow(color: .black.opacity(0.1), radius: 15)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    
                    // Status Visuals & Animation
                    SimplifiedOrderStatusView(order: fullOrder)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    
                    // Order Items
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Order Items")
                            .font(.urbanist(size: 18, weight: .semibold))
                            .padding(.horizontal, 20)
                        
                        ForEach(fullOrder.items) { item in
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Constants.primaryColor.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    
                                    Text("\(item.quantity)")
                                        .font(.urbanist(size: 16, weight: .bold))
                                        .foregroundStyle(Constants.primaryColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.urbanist(size: 16, weight: .semibold))
                                    
                                    Text("₹\(Int(item.price)) each")
                                        .font(.urbanist(size: 14, weight: .regular))
                                        .foregroundStyle(.gray)
                                }
                                
                                Spacer()
                                
                                Text("₹\(Int(item.subtotal))")
                                    .font(.urbanist(size: 16, weight: .bold))
                                    .foregroundStyle(Constants.primaryColor)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 10)
                    .padding(.horizontal, 20)
                    
                    // Price Summary
                    VStack(spacing: 12) {
                        HStack {
                            Text("Total Amount")
                                .font(.urbanist(size: 16, weight: .medium))
                            Spacer()
                            Text("₹\(Int(fullOrder.totalAmount))")
                                .font(.urbanist(size: 20, weight: .bold))
                                .foregroundStyle(Constants.primaryColor)
                        }
                        
                        if let paymentId = fullOrder.paymentId {
                            Divider()
                            HStack {
                                Text("Payment ID")
                                    .font(.urbanist(size: 14, weight: .medium))
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text(paymentId)
                                    .font(.urbanist(size: 12, weight: .regular))
                                    .foregroundStyle(.gray)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 10)
                    .padding(.horizontal, 20)
                    
                    // Done Button
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.urbanist(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Constants.primaryColor)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 10)
            }
        }
        .task {
            // Show initial data immediately using animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
            
            // Then fetch fresh data in background
            if let token = authViewModel.authToken {
                if let fetched = await orderViewModel.fetchOrder(orderId: order.orderId, token: token) {
                    self.fullOrder = fetched
                }
            }
        }
    }
    
    private func decodeBase64ToImage(_ base64String: String) -> UIImage? {
        let cleanedString = base64String.replacingOccurrences(of: "data:image/png;base64,", with: "")
        guard let imageData = Data(base64Encoded: cleanedString) else { return nil }
        return UIImage(data: imageData)
    }
}


