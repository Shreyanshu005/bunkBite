import SwiftUI

struct OrderSuccessView: View {
    let order: Order
    
    @Environment(\.dismiss) var dismiss
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Success Icon
                    Image("success_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1 : 0.8)
                    .padding(.top, 60)
                    
                    // Main Text
                    VStack(spacing: 8) {
                        Text("Order Placed Successfully!")
                            .font(.custom("Urbanist-Bold", size: 24))
                            .foregroundStyle(.black)
                        
                        Text("Your order is being prepared")
                            .font(.custom("Urbanist-Medium", size: 16))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }
                    
                    // Order ID
                    VStack(spacing: 8) {
                        Text("Order ID")
                            .font(.custom("Urbanist-Medium", size: 14))
                            .foregroundStyle(Color(hex: "6B7280"))
                        
                        Text(order.orderId)
                            .font(.custom("Urbanist-Bold", size: 18))
                            .foregroundStyle(.black)
                    }
                    .padding(.top, 8)
                    
                    // QR Code
                    if let qrCodeString = order.qrCode, let qrImage = decodeBase64ToImage(qrCodeString) {
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
                        .padding(.top, 8)
                    }
                    
                    // Status Card
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Constants.primaryColor)
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cooking in Progress")
                                .font(.custom("Urbanist-Bold", size: 16))
                                .foregroundStyle(.black)
                            
                            Text("Your order is being prepared by the canteen staff")
                                .font(.custom("Urbanist-Regular", size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        
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
                    
                    // Order Items
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Order Items")
                            .font(.custom("Urbanist-Bold", size: 18))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20)
                        
                        ForEach(order.items) { item in
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
                            .background(Color(hex: "E9EBEF"))
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Total
                    HStack {
                        Text("Total")
                            .font(.custom("Urbanist-Bold", size: 18))
                            .foregroundStyle(.black)
                        
                        Spacer()
                        
                        Text("₹\(Int(order.totalAmount))")
                            .font(.custom("Urbanist-Bold", size: 24))
                            .foregroundStyle(Constants.primaryColor)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // View Order Details Button
                        Button(action: {
                            dismiss()
                            // Switch to orders tab
                            NotificationCenter.default.post(name: NSNotification.Name("SwitchToOrders"), object: nil)
                        }) {
                            Text("View Order Details")
                                .font(.custom("Urbanist-Bold", size: 16))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "0D1317"))
                                .cornerRadius(12)
                        }
                        
                        Button {
                            NotificationCenter.default.post(name: NSNotification.Name("SwitchToHome"), object: nil)
                            dismiss()
                        } label: {
                            Text("Back to Menu")
                                .font(.custom("Urbanist-Bold", size: 16))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "E9EBEF"))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "A0A0A0"), lineWidth: 1.0)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
    
    private func decodeBase64ToImage(_ base64String: String) -> UIImage? {
        let cleanedString = base64String.replacingOccurrences(of: "data:image/png;base64,", with: "")
        guard let imageData = Data(base64Encoded: cleanedString) else { return nil }
        return UIImage(data: imageData)
    }
}
