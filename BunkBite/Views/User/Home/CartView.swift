
import SwiftUI


struct CartView: View {
    @ObservedObject var cart: Cart
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var selectedTab: CustomFloatingTabBar.Tab
    
    @EnvironmentObject var canteenViewModel: CanteenViewModel
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var orderViewModel = OrderViewModel()
    
    @State private var isProcessing = false
    @State private var razorpayPaymentData: RazorpayPaymentInitiation? = nil
    @State private var errorMessage: String? = nil
    @State private var showLoginSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("My Cart")
                            .font(.custom("Urbanist-Bold", size: 28))
                            .foregroundStyle(.black)
                        Spacer()
                        Text("\(cart.items.reduce(0) { $0 + $1.quantity }) items")
                            .font(.custom("Urbanist-Medium", size: 16))
                            .foregroundStyle(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Rectangle()
                        .fill(Color(hex: "E5E7EB"))
                        .frame(height: 1.0)
                        .padding(.horizontal, -20)
                        .padding(.top, 4)
                }
                .background(Color.white)
                
                if cart.items.isEmpty {
                    // Empty State
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Circle()
                            .fill(Color(hex: "F3F4F6"))
                            .frame(width: 140, height: 140)
                            .overlay(
                                Image(systemName: "cart")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color.gray)
                            )
                        
                        VStack(spacing: 8) {
                            Text("Your cart is empty")
                                .font(.custom("Urbanist-Bold", size: 24))
                                .foregroundStyle(.black)
                            
                            Text("Add items to get started")
                                .font(.custom("Urbanist-Medium", size: 16))
                                .foregroundStyle(.gray)
                        }
                        
                        Button {
                            selectedTab = .menu
                            dismiss()
                        } label: {
                            Text("Browse Menu")
                                .font(.custom("Urbanist-Bold", size: 16))
                                .foregroundStyle(.white)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 32)
                                .background(Color(hex: "0D1317"))
                                .cornerRadius(12)
                        }
                        .padding(.top, 16)
                        
                        Spacer()
                        Spacer()
                    }
                } else {
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Cart Items
                            VStack(spacing: 16) {
                                ForEach(cart.items) { item in
                                    CartItemRow(item: item, cart: cart)
                                }
                            }
                            
                            // Bill Details
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Subtotal")
                                        .font(.custom("Urbanist-Medium", size: 16))
                                        .foregroundStyle(.gray)
                                    Spacer()
                                    Text("₹\(Int(cart.totalAmount))")
                                        .font(.custom("Urbanist-Bold", size: 16))
                                        .foregroundStyle(.black)
                                }
                                
                                Rectangle()
                                    .fill(Color(hex: "E5E7EB"))
                                    .frame(height: 1.0)
                                
                                HStack {
                                    Text("Total")
                                        .font(.custom("Urbanist-Bold", size: 20))
                                        .foregroundStyle(.black)
                                    Spacer()
                                    Text("₹\(Int(cart.totalAmount))")
                                        .font(.custom("Urbanist-Bold", size: 20))
                                        .foregroundStyle(Constants.primaryColor)
                                }
                            }
                            .padding(.top, 10)
                            
                            // Checkout Button
                            let (isCanteenOpen, closedReason) = canteenViewModel.selectedCanteen?.isAcceptingOrders ?? (true, "")
                            
                            VStack(spacing: 12) {
                                Button {
                                    initiatePayment()
                                } label: {
                                    ZStack {
                                        if isProcessing {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Text("Proceed to Checkout")
                                                .font(.custom("Urbanist-Bold", size: 16))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(Color(hex: "0D1317"))
                                    .cornerRadius(16)
                                }
                                .disabled(isProcessing)
                                
                                // Warning when canteen is closed
                                if !isCanteenOpen {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.orange)
                                        Text(closedReason)
                                            .font(.custom("Urbanist-Medium", size: 14))
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                            .padding(.top, 16)
                        }
                        .padding(20)
                        .padding(.bottom, 80) // Space for TabBar
                    }
                }
            }
            .background(Color(hex: "FFFFFF")) // White background
            .fullScreenCover(item: $razorpayPaymentData) { data in
                RazorpayCheckoutView(
                    paymentData: data,
                    onSuccess: { response in
                        print("Razorpay Success: \(response)")
                        verifyPayment(response)
                    },
                    onFailure: { error in
                        print("Razorpay Failed: \(error)")
                        isProcessing = false
                        razorpayPaymentData = nil
                        errorMessage = error
                    },
                    onDismiss: {
                        isProcessing = false
                        razorpayPaymentData = nil
                    }
                )
            }
            .fullScreenCover(item: $createdOrder) { order in
                OrderSuccessView(order: order)
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Something went wrong")
            }
            .onChange(of: selectedTab) { _, newTab in
                // Dismiss cart when user switches to a different tab
                dismiss()
            }
            .sheet(isPresented: $showLoginSheet) {
                NewLoginSheet(authViewModel: authViewModel, isPresented: $showLoginSheet)
                    .presentationDetents([.fraction(0.5), .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color.white)
                    .interactiveDismissDisabled(false)
            }
    }
    
    @State private var createdOrder: Order? = nil
    
    private func verifyPayment(_ response: RazorpayPaymentResponse) {
        guard let token = authViewModel.authToken else { return }
        razorpayPaymentData = nil
        
        Task {
            if let verifiedOrder = await orderViewModel.verifyPayment(
                razorpayOrderId: response.razorpayOrderId,
                razorpayPaymentId: response.razorpayPaymentId,
                razorpaySignature: response.razorpaySignature,
                token: token
            ) {
                if verifiedOrder.paymentStatus == .success {
                    // Success!
                    cart.clear()
                    isProcessing = false
                    createdOrder = verifiedOrder
                    
                    // Refresh orders list
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshOrders"), object: nil)
                    
                    // Logic to send notification if needed
                    if let canteenName = canteenViewModel.selectedCanteen?.name {
                        NotificationManager.shared.sendOrderPlacedNotification(
                            orderId: verifiedOrder.orderId,
                            canteenName: canteenName
                        )
                    }
                } else {
                    isProcessing = false
                    errorMessage = "Payment verification failed. Please check your orders."
                }
            } else {
                isProcessing = false
                errorMessage = "Failed to verify payment."
            }
        }
    }
    
    // Helper to start payment
    private func initiatePayment() {
        guard let token = authViewModel.authToken else {
            // Show login prompt if not authenticated
            showLoginSheet = true
            return
        }
        
        guard let canteenId = canteenViewModel.selectedCanteen?.id else {
            errorMessage = "Please select a canteen first"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        Task {
            // 1. Create Order
            if let order = await orderViewModel.createOrder(canteenId: canteenId, cart: cart, token: token) {
                // 2. Initiate Payment
                if let payment = await orderViewModel.initiatePayment(orderId: order.orderId, token: token) {
                    self.razorpayPaymentData = payment
                    // isProcessing will be reset on success/dismiss of sheet
                } else {
                    self.errorMessage = orderViewModel.errorMessage ?? "Failed to initiate payment"
                    isProcessing = false
                }
            } else {
                self.errorMessage = orderViewModel.errorMessage ?? "Failed to create order"
                isProcessing = false
            }
        }
    }
}

// Extension to make RazorpayPaymentInitiation Identifiable for Sheet
extension RazorpayPaymentInitiation: Identifiable {
    var id: String { razorpayOrderId }
}

struct CartItemRow: View {
    let item: CartItem
    @ObservedObject var cart: Cart
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Image
            ZStack {
                 Image("food_placeholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 90)
                    .background(Color.gray.opacity(0.1))
                    .clipped()
            }
            .background(
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundStyle(.gray.opacity(0.3))
            )
            .frame(width: 90, height: 90)
            .cornerRadius(12)
            .clipped()
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Header Row: Name + Trash
                HStack(alignment: .top) {
                    Text(item.menuItem.name)
                        .font(.custom("Urbanist-Bold", size: 18))
                        .foregroundStyle(.black)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            cart.removeItem(item.menuItem)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                }
                
                // Price
                Text("₹\(Int(item.menuItem.price))")
                    .font(.custom("Urbanist-Bold", size: 16))
                    .foregroundStyle(Constants.primaryColor)
                
                Spacer()
                
                // Low Row: Quantity Controls
                HStack(spacing: 16) {
                    // Decrease
                    Button {
                        if item.quantity > 1 {
                             cart.updateQuantity(for: item.menuItem, quantity: item.quantity - 1)
                        } else {
                             cart.removeItem(item.menuItem)
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "E5E7EB"), lineWidth: 1.0)
                            .frame(width: 36, height: 36)
                            .overlay(Image(systemName: "minus").font(.system(size: 14, weight: .bold)).foregroundStyle(.black))
                    }
                    
                    Text("\(item.quantity)")
                        .font(.custom("Urbanist-Bold", size: 18))
                        .frame(minWidth: 20)
                    
                    // Increase
                    Button {
                        cart.updateQuantity(for: item.menuItem, quantity: item.quantity + 1)
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "F3F4F6"))
                            .frame(width: 36, height: 36)
                            .overlay(Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundStyle(.black))
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "E5E7EB"), lineWidth: 1.0)
        )
    }
}
