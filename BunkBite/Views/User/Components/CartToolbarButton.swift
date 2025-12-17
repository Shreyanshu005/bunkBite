//
//  CartToolbarButton.swift
//  BunkBite
//
//  Created by Shreyanshu on 15/12/25.
//

import SwiftUI

struct CartToolbarButton: View {
    @EnvironmentObject var cart: Cart
    @ObservedObject var authViewModel: AuthViewModel
    @State private var cartShake: CGFloat = 0
    @Binding var showCart: Bool
    @Binding var showLoginSheet: Bool
    
    var body: some View {
        Button {
            if authViewModel.isAuthenticated { 
                showCart = true 
            } else { 
                showLoginSheet = true 
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: cart.totalItems > 0 ? "cart.fill" : "cart")
                    .font(.title3)
                
                if cart.totalItems > 0 {
                    Text("\(cart.totalItems)")
                        .font(.urbanist(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Constants.primaryColor)
                        .clipShape(Circle())
                }
            }
            .foregroundStyle(Constants.primaryColor)
            .padding(8)
            .rotationEffect(.degrees(cartShake))
            .onChange(of: cart.totalItems) { oldValue, newValue in
                if newValue > oldValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
                        cartShake = 10
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.3).delay(0.1)) {
                        cartShake = -10
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.3).delay(0.2)) {
                        cartShake = 0
                    }
                }
            }
        }
    }
}
