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
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                             .font(.system(size: 28))
                             .foregroundStyle(Constants.primaryColor)

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

                    ScrollView {
                        VStack(spacing: 24) {

                            VStack(spacing: 16) {
                                ForEach(cart.items) { item in
                                    CartItemRow(item: item, cart: cart)
                                }
                            }

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

                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.gray)

                                Text("Orders must be picked up within 12 hours or will be refunded.")
                                    .font(.custom("Urbanist-Medium", size: 13))
                                    .foregroundStyle(.gray)
                            }
                            .padding(12)
                            .background(Color(hex: "F9FAFB"))
                            .cornerRadius(8)
                            .padding(.top, 16)

                            let (isCanteenOpen, closedReason) = canteenViewModel.selectedCanteen?.isAcceptingOrders ?? (true, "")

                            VStack(spacing: 12) {
                                Button {
                                    if isCanteenOpen {
                                        initiatePayment()
                                    }
                                } label: {
                                    ZStack {
                                        if isProcessing {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Text(isCanteenOpen ? "Proceed to Checkout" : "Canteen Closed")
                                                .font(.custom("Urbanist-Bold", size: 16))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(isCanteenOpen ? Color(hex: "0D1317") : Color.gray)
                                    .cornerRadius(16)
                                }
                                .disabled(!isCanteenOpen || isProcessing)

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
                        .padding(.bottom, 80)
                    }
                }
            }
            .background(Color(hex: "FFFFFF"))
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

                    cart.clear()
                    isProcessing = false
                    createdOrder = verifiedOrder

                    NotificationCenter.default.post(name: NSNotification.Name("RefreshOrders"), object: nil)

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

    private func initiatePayment() {
        guard let token = authViewModel.authToken else {

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

            if let order = await orderViewModel.createOrder(canteenId: canteenId, cart: cart, token: token) {

                if let payment = await orderViewModel.initiatePayment(orderId: order.orderId, token: token) {
                    self.razorpayPaymentData = payment

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

extension RazorpayPaymentInitiation: Identifiable {
    var id: String { razorpayOrderId }
}

struct CartItemRow: View {
    let item: CartItem
    @ObservedObject var cart: Cart

    var body: some View {
        HStack(alignment: .top, spacing: 16) {

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

            VStack(alignment: .leading, spacing: 4) {

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

                Text("₹\(Int(item.menuItem.price))")
                    .font(.custom("Urbanist-Bold", size: 16))
                    .foregroundStyle(Constants.primaryColor)

                Spacer()

                HStack(spacing: 16) {

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
