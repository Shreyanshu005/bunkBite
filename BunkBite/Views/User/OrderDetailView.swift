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
    @Environment(\.presentationMode) var presentationMode
    @State private var isAnimating = false
    @State private var fullOrder: Order
    
    init(order: Order, orderViewModel: OrderViewModel, authViewModel: AuthViewModel) {
        self.order = order
        self.orderViewModel = orderViewModel
        self.authViewModel = authViewModel
        _fullOrder = State(initialValue: order)
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.black)
                    }
                    
                    Text("Order Details")
                        .font(.custom("Urbanist-Bold", size: 20))
                        .foregroundStyle(.black)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                
                // Separator
                Rectangle()
                    .fill(Color(hex: "E5E7EB"))
                    .frame(height: 1)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Order ID and Date
                        VStack(spacing: 8) {
                            Text("Order ID")
                                .font(.custom("Urbanist-Medium", size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                            
                            Text(fullOrder.orderId)
                                .font(.custom("Urbanist-Bold", size: 18))
                                .foregroundStyle(.black)
                            
                            Text(formatDate(fullOrder.createdAt))
                                .font(.custom("Urbanist-Regular", size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .padding(.top, 24)
                        
                        // QR Code (hide for completed and cancelled orders)
                        if fullOrder.status != .completed && fullOrder.status != .cancelled, let qrCodeString = fullOrder.qrCode, let qrImage = decodeBase64ToImage(qrCodeString) {
                            VStack(spacing: 12) {
                                Image(uiImage: qrImage)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 180, height: 180)
                                    .padding(20)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(hex: "E5E7EB"), lineWidth: 1.5)
                                    )
                                
                                Text("Show this QR code at the counter for pickup")
                                    .font(.custom("Urbanist-Medium", size: 14))
                                    .foregroundStyle(Color(hex: "6B7280"))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                        
                        // Status Card
                        HStack(spacing: 12) {
                            Image(systemName: "clock")
                                .font(.system(size: 20))
                                .foregroundStyle(Constants.primaryColor)
                            
                            Text(getStatusText(fullOrder.status))
                                .font(.custom("Urbanist-Bold", size: 16))
                                .foregroundStyle(.black)
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(Color(hex: "F9FFFC"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "AECEBB"), lineWidth: 1.5)
                        )
                        .padding(.horizontal, 20)
                        
                        // Refund Information (if refunded)
                        if fullOrder.isRefunded {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.blue)
                                    
                                    Text("Refund Processed")
                                        .font(.custom("Urbanist-Bold", size: 16))
                                        .foregroundStyle(.black)
                                    
                                    Spacer()
                                }
                                
                                if let refundId = fullOrder.refundId {
                                    Text("Refund ID: \(refundId)")
                                        .font(.custom("Urbanist-Medium", size: 14))
                                        .foregroundStyle(Color(hex: "6B7280"))
                                }
                                
                                Text("Your refund will be credited to your original payment method within 2-3 business days.")
                                    .font(.custom("Urbanist-Regular", size: 14))
                                    .foregroundStyle(Color(hex: "6B7280"))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(16)
                            .background(Color(hex: "EFF6FF"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "93C5FD"), lineWidth: 1.5)
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Pickup Location
                        if let canteen = fullOrder.canteen {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Pickup Location")
                                    .font(.custom("Urbanist-Bold", size: 18))
                                    .foregroundStyle(.black)
                                
                                Text(canteen.name)
                                    .font(.custom("Urbanist-Regular", size: 16))
                                    .foregroundStyle(Color(hex: "6B7280"))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        }
                        
                        // Order Items
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Order Items")
                                .font(.custom("Urbanist-Bold", size: 18))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 20)
                            
                            ForEach(fullOrder.items) { item in
                                HStack {
                                    Text("\(item.name) x\(item.quantity)")
                                        .font(.custom("Urbanist-Regular", size: 16))
                                        .foregroundStyle(.black)
                                    
                                    Spacer()
                                    
                                    Text("₹\(Int(item.subtotal))")
                                        .font(.custom("Urbanist-Bold", size: 16))
                                        .foregroundStyle(.black)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color(hex: "C4C4C4"))
                                .cornerRadius(8)
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Total Amount
                        HStack {
                            Text("Total Amount")
                                .font(.custom("Urbanist-Bold", size: 18))
                                .foregroundStyle(.black)
                            
                            Spacer()
                            
                            Text("₹\(Int(fullOrder.totalAmount))")
                                .font(.custom("Urbanist-Bold", size: 24))
                                .foregroundStyle(Constants.primaryColor)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(hex: "C4C4C4"))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
                .background(Color.white)
            }
        }
        .navigationBarHidden(true)
        .task {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
            
            if let token = authViewModel.authToken {
                if let fetched = await orderViewModel.fetchOrder(orderId: order.orderId, internalId: order.id, token: token) {
                    self.fullOrder = fetched
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateString) else {
                return dateString
            }
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMMM d, yyyy 'at' h:mm a"
            return displayFormatter.string(from: date)
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMMM d, yyyy 'at' h:mm a"
        return displayFormatter.string(from: date)
    }
    
    private func getStatusText(_ status: OrderStatus) -> String {
        switch status {
        case .preparing: return "Cooking in Progress"
        case .ready: return "Ready for Pickup"
        case .completed: return "Order Completed"
        case .cancelled: return "Order Cancelled"
        case .pending: return "Payment Pending"
        case .paid: return "Paid - Preparing"
        }
    }
    
    private func decodeBase64ToImage(_ base64String: String) -> UIImage? {
        let cleanedString = base64String.replacingOccurrences(of: "data:image/png;base64,", with: "")
        guard let imageData = Data(base64Encoded: cleanedString) else { return nil }
        return UIImage(data: imageData)
    }
}
