
import SwiftUI

struct FoodItemCard: View {
    let item: MenuItem
    @ObservedObject var cart: Cart
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var showLoginSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image Area
            ZStack {
                if item.availableQuantity > 0 {
                    Image(systemName: "fork.knife")
                        .font(.largeTitle)
                        .foregroundStyle(.gray.opacity(0.3))
                    
                    Image("food_placeholder")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .clipped()
                } else {
                    // Out of stock overlay
                    ZStack {
                        Color.black
                        Text("Unavailable")
                            .font(.custom("Urbanist-Bold", size: 16))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(height: 120)
            .background(Color.gray.opacity(0.1))
            .clipped()
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Name
                Text(item.name)
                    .font(.custom("Urbanist-Bold", size: 16))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                
                // Price and Quantity Left
                HStack {
                    Text("₹\(Int(item.price))")
                        .font(.custom("Urbanist-Bold", size: 16))
                        .foregroundStyle(Constants.primaryColor)
                    
                    Spacer()
                    
                    if item.availableQuantity > 0 {
                        Text("\(item.availableQuantity) left")
                            .font(.custom("Urbanist-Medium", size: 12))
                            .foregroundStyle(.gray) // Or subtle green
                    } else {
                        Text("Sold Out")
                            .font(.custom("Urbanist-Bold", size: 10))
                            .foregroundStyle(.red)
                    }
                }
                
                // Add Button (Full Width Dark)
                if cart.getQuantity(for: item) > 0 {
                    HStack(spacing: 0) {
                        Button {
                            cart.updateQuantity(for: item, quantity: cart.getQuantity(for: item) - 1)
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Color(hex: "0D1317"))
                                .cornerRadius(12, corners: [.topLeft, .bottomLeft])
                        }
                        
                        Text("\(cart.getQuantity(for: item))")
                            .font(.custom("Urbanist-Bold", size: 16))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color(hex: "0D1317"))
                        
                        Button {
                            if cart.getQuantity(for: item) < item.availableQuantity {
                                cart.addItem(item)
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Color(hex: "0D1317"))
                                .cornerRadius(12, corners: [.topRight, .bottomRight])
                        }
                    }
                    .background(Color(hex: "0D1317"))
                    .cornerRadius(12)
                } else {
                    Button {
                        if cart.getQuantity(for: item) < item.availableQuantity {
                            cart.addItem(item)
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "0D1317")) // Dark / Black
                                .frame(height: 40)
                                .overlay(
                                    Group {
                                        if item.availableQuantity > 0 {
                                            Image(systemName: "plus")
                                                .font(.system(size: 20, weight: .regular))
                                                .foregroundStyle(.white)
                                        } else {
                                            Text("N/A")
                                                .font(.custom("Urbanist-Bold", size: 14))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                )
                        }
                    }
                    .disabled(item.availableQuantity == 0)
                    .opacity(item.availableQuantity == 0 ? 0.8 : 1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "E5E7EB"), lineWidth: 1.0)
        )
    }
}


