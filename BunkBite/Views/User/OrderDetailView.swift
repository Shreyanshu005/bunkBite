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
                        // Success Header (if paid)
                        if order.paymentStatus == .success {
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.1))
                                        .frame(width: 100, height: 100)
                                        .scaleEffect(isAnimating ? 1 : 0.8)
                                    
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.green)
                                        .scaleEffect(isAnimating ? 1 : 0.5)
                                }
                                
                                Text("Order Placed Successfully!")
                                    .font(.urbanist(size: 24, weight: .bold))
                                
                                Text("Order #\(order.orderId)")
                                    .font(.urbanist(size: 16, weight: .medium))
                                    .foregroundStyle(.gray)
                            }
                            .padding(.top, 20)
                            .opacity(isAnimating ? 1 : 0)
                        }
                        
                        // QR Code (if ready)
                        if order.status == .ready || order.status == .paid, let qrCodeString = order.qrCode {
                            VStack(spacing: 16) {
                                Text("Show this QR code at pickup")
                                    .font(.urbanist(size: 16, weight: .semibold))
                                    .foregroundStyle(.gray)
                                
                                if let qrImage = decodeBase64ToImage(qrCodeString) {
                                    Image(uiImage: qrImage)
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 250, height: 250)
                                        .padding(20)
                                        .background(Color.white)
                                        .cornerRadius(20)
                                        .shadow(color: .black.opacity(0.1), radius: 15)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 250, height: 250)
                                        .cornerRadius(20)
                                        .overlay(
                                            Text("QR Code")
                                                .foregroundStyle(.gray)
                                        )
                                }
                            }
                            .padding(.vertical, 20)
                        }
                        
                        // Status Card
                        VStack(spacing: 16) {
                            HStack {
                                Text("Order Status")
                                    .font(.urbanist(size: 18, weight: .semibold))
                                Spacer()
                                StatusBadge(status: order.status)
                            }
                            
                            // Status Timeline
                            OrderStatusTimeline(currentStatus: order.status)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 10)
                        .padding(.horizontal, 20)
                        
                        // Order Items
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Order Items")
                                .font(.urbanist(size: 18, weight: .semibold))
                                .padding(.horizontal, 20)
                            
                            ForEach(order.items) { item in
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
                                Text("₹\(Int(order.totalAmount))")
                                    .font(.urbanist(size: 20, weight: .bold))
                                    .foregroundStyle(Constants.primaryColor)
                            }
                            
                            if let paymentId = order.paymentId {
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
                }
            }
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isAnimating = true
                }
            }
        }
    }
    
    private func decodeBase64ToImage(_ base64String: String) -> UIImage? {
        // Remove data:image/png;base64, prefix if present
        let cleanedString = base64String.replacingOccurrences(of: "data:image/png;base64,", with: "")
        
        guard let imageData = Data(base64Encoded: cleanedString) else {
            return nil
        }
        
        return UIImage(data: imageData)
    }
}

struct OrderStatusTimeline: View {
    let currentStatus: OrderStatus
    
    let statuses: [OrderStatus] = [.paid, .preparing, .ready, .completed]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(statuses.enumerated()), id: \.offset) { index, status in
                VStack(spacing: 8) {
                    // Circle
                    ZStack {
                        Circle()
                            .fill(isStatusReached(status) ? Constants.primaryColor : Color.gray.opacity(0.2))
                            .frame(width: 30, height: 30)
                        
                        if isStatusReached(status) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    
                    // Label
                    Text(status.rawValue.capitalized)
                        .font(.urbanist(size: 11, weight: .medium))
                        .foregroundStyle(isStatusReached(status) ? Color.primary : Color.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                
                // Line
                if index < statuses.count - 1 {
                    Rectangle()
                        .fill(isStatusReached(statuses[index + 1]) ? Constants.primaryColor : Color.gray.opacity(0.2))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .offset(y: -15)
                }
            }
        }
    }
    
    private func isStatusReached(_ status: OrderStatus) -> Bool {
        guard let currentIndex = statuses.firstIndex(of: currentStatus),
              let statusIndex = statuses.firstIndex(of: status) else {
            return false
        }
        return statusIndex <= currentIndex
    }
}
