//
//  PaymentSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI
import PopupView
import ConfettiSwiftUI
import Razorpay

struct PaymentDetails {
    let transactionId: String
    let amount: Double
    let timestamp: Date
    let status: PaymentStatus
    let paymentMethod: String
    let canteenName: String
    let itemCount: Int

    enum PaymentStatus: String {
        case pending = "Pending"
        case success = "Success"
        case failed = "Failed"
        case processing = "Processing"
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var formattedAmount: String {
        return String(format: "₹%.2f", amount)
    }
}

struct PaymentSheet: View {
    @ObservedObject var cart: Cart
    let canteen: Canteen?

    @Environment(\.dismiss) var dismiss
    @State private var showSuccessPopup = false
    @State private var isProcessingPayment = false
    @State private var paymentDetails: PaymentDetails?
    @State private var isAnimating = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var razorpay: RazorpayCheckout?
    @State private var currentOrderId: String = ""
    @State private var currentRazorpayKey: String = ""
    @State private var razorpayDelegate: RazorpayDelegate?

    var body: some View {
        ZStack {
            // Gradient Background
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
                VStack(spacing: 32) {
                    // Header with animated payment icon
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Constants.primaryColor.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .scaleEffect(isAnimating ? 1 : 0.8)

                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(Constants.primaryColor)
                                .scaleEffect(isAnimating ? 1 : 0.5)
                        }
                        .padding(.top, 40)

                        VStack(spacing: 8) {
                            Text("Complete Payment")
                                .font(.urbanist(size: 28, weight: .bold))
                                .foregroundStyle(.black)

                            Text("Secure payment via Razorpay")
                                .font(.urbanist(size: 15, weight: .regular))
                                .foregroundStyle(.gray)
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    }
                    .padding(.horizontal, 24)

                    // Total Amount Card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Amount")
                                .font(.urbanist(size: 14, weight: .medium))
                                .foregroundStyle(.gray)

                            Text("₹\(Int(cart.totalAmount))")
                                .font(.urbanist(size: 32, weight: .bold))
                                .foregroundStyle(Constants.primaryColor)
                        }
                        Spacer()
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                    .padding(.horizontal, 24)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)

                    // Payment Methods
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Payment Options")
                            .font(.urbanist(size: 14, weight: .semibold))
                            .foregroundStyle(.gray)
                            .textCase(.uppercase)
                            .tracking(1)
                            .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            // UPI Payment Option
                            PaymentMethodCard(
                                icon: "indianrupeesign.circle.fill",
                                title: "UPI",
                                subtitle: "Google Pay, PhonePe, Paytm & More",
                                color: .green
                            )

                            // Card Payment Option
                            PaymentMethodCard(
                                icon: "creditcard.fill",
                                title: "Cards",
                                subtitle: "Credit & Debit Cards",
                                color: .blue
                            )

                            // Netbanking Option
                            PaymentMethodCard(
                                icon: "building.columns.fill",
                                title: "Netbanking",
                                subtitle: "All major banks supported",
                                color: .orange
                            )

                            // Wallet Option
                            PaymentMethodCard(
                                icon: "wallet.pass.fill",
                                title: "Wallets",
                                subtitle: "Paytm, PhonePe, Amazon Pay & More",
                                color: .purple
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 30)

                    // Pay Now Button
                    Button {
                        initiatePayment()
                    } label: {
                        HStack(spacing: 12) {
                            if isProcessingPayment {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Processing...")
                                    .font(.urbanist(size: 18, weight: .semibold))
                            } else {
                                Text("Pay ₹\(Int(cart.totalAmount))")
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
                    .disabled(isProcessingPayment)
                    .padding(.horizontal, 24)
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0.9)

                    // Security Features
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Constants.primaryColor)
                                .frame(width: 24)

                            Text("Secured by Razorpay")
                                .font(.urbanist(size: 15, weight: .regular))
                                .foregroundStyle(.gray)

                            Spacer()
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Constants.primaryColor)
                                .frame(width: 24)

                            Text("PCI DSS Compliant")
                                .font(.urbanist(size: 15, weight: .regular))
                                .foregroundStyle(.gray)

                            Spacer()
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Constants.primaryColor)
                                .frame(width: 24)

                            Text("Instant Payment Confirmation")
                                .font(.urbanist(size: 15, weight: .regular))
                                .foregroundStyle(.gray)

                            Spacer()
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(isAnimating ? 1 : 0)

                    #if DEBUG
                    // Mock Payment Button
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Development Testing")
                            .font(.urbanist(size: 14, weight: .semibold))
                            .foregroundStyle(.gray)
                            .textCase(.uppercase)
                            .tracking(1)
                            .padding(.horizontal, 24)

                        Button {
                            mockSuccessfulPayment()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 20))
                                Text("Mock Successful Payment")
                                    .font(.urbanist(size: 17, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 24)

                        Text("Instantly triggers successful payment for testing")
                            .font(.urbanist(size: 13, weight: .regular))
                            .foregroundStyle(.gray)
                            .padding(.horizontal, 24)
                    }
                    .opacity(isAnimating ? 1 : 0)
                    #endif

                    Spacer(minLength: 40)
                }
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.gray.opacity(0.3))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
        .alert("Payment Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .popup(isPresented: $showSuccessPopup) {
            PaymentSuccessPopup {
                cart.clear()
                showSuccessPopup = false
                dismiss()
            }
        } customize: {
            $0
                .type(.floater(verticalPadding: 20, useSafeAreaInset: true))
                .position(.center)
                .animation(.spring())
                .closeOnTapOutside(false)
                .backgroundColor(.black.opacity(0.5))
        }
    }

    // MARK: - Payment Functions

    private func initiatePayment() {
        guard let canteen = canteen else {
            handlePaymentFailure(error: "Canteen information not available")
            return
        }

        isProcessingPayment = true

        // TEMPORARY: Direct Razorpay payment without backend
        // When backend is ready, uncomment the backend order creation code below

        // Generate a temporary order ID
        let tempOrderId = "order_\(UUID().uuidString.prefix(14))"
        let amountInPaise = Int(cart.totalAmount * 100)

        print("\n🚀 INITIATING PAYMENT (No Backend Mode)")
        print("Temporary Order ID: \(tempOrderId)")
        print("Amount: ₹\(cart.totalAmount) (\(amountInPaise) paise)")
        print("Canteen: \(canteen.name)")
        print("Items: \(cart.items.count)\n")

        currentOrderId = tempOrderId
        currentRazorpayKey = Constants.razorpayKey
        openRazorpayCheckout(
            orderId: tempOrderId,
            amount: amountInPaise,
            key: currentRazorpayKey
        )

        /* UNCOMMENT THIS WHEN BACKEND IS READY:

        Task {
            do {
                // Create order on backend
                let orderResponse = try await RazorpayService.shared.createOrder(
                    amount: cart.totalAmount,
                    canteenId: canteen.id,
                    items: cart.items,
                    token: UserDefaults.standard.string(forKey: "authToken") ?? ""
                )

                // Store order details
                await MainActor.run {
                    currentOrderId = orderResponse.orderId
                    currentRazorpayKey = orderResponse.key ?? Constants.razorpayKey
                    openRazorpayCheckout(
                        orderId: orderResponse.orderId,
                        amount: orderResponse.amount,
                        key: currentRazorpayKey
                    )
                }
            } catch let error as RazorpayError {
                await MainActor.run {
                    handlePaymentFailure(error: error.localizedDescription)
                }
            } catch {
                await MainActor.run {
                    handlePaymentFailure(error: "Failed to create order: \(error.localizedDescription)")
                }
            }
        }
        */
    }

    private func openRazorpayCheckout(orderId: String, amount: Int, key: String) {
        print("🔔 Opening Razorpay Checkout")
        print("📦 Order ID: \(orderId)")
        print("💰 Amount: ₹\(Double(amount) / 100)")

        // Create delegate
        let delegate = RazorpayDelegate(
            cart: cart,
            canteen: canteen,
            currentOrderId: orderId,
            onSuccess: { [self] paymentId, orderId in
                self.handlePaymentSuccess(paymentId: paymentId, orderId: orderId)
            },
            onFailure: { [self] error in
                self.handlePaymentFailure(error: error)
            }
        )
        razorpayDelegate = delegate

        // Initialize Razorpay
        razorpay = RazorpayCheckout.initWithKey(key, andDelegateWithData: delegate)

        // Configure payment options
        let options: [String: Any] = [
            "amount": amount,
            "currency": "INR",
            "name": canteen?.name ?? "BunkBite",
            "description": "Order Payment - \(cart.items.count) items",
            "order_id": orderId,
            "prefill": [
                "contact": "",
                "email": ""
            ],
            "theme": [
                "color": "#f62f56"
            ],
            "image": ""  // Add your logo URL here if needed
        ]

        // Open Razorpay checkout
        razorpay?.open(options, displayController: UIApplication.shared.windows.first?.rootViewController)
    }

    private func handlePaymentSuccess(paymentId: String, orderId: String) {
        // TEMPORARY: Skip backend verification (no backend yet)
        // All payment data has been captured and saved locally
        // When backend is ready, uncomment the verification code below

        isProcessingPayment = false
        paymentDetails = PaymentDetails(
            transactionId: paymentId,
            amount: cart.totalAmount,
            timestamp: Date(),
            status: .success,
            paymentMethod: "Razorpay",
            canteenName: canteen?.name ?? "BunkBite",
            itemCount: cart.items.count
        )

        print("\n✅ Payment Successful (Saved Locally)")
        print("📋 Order ID: \(orderId)")
        print("💳 Payment ID: \(paymentId)")
        print("💾 Order data saved - ready to send to backend\n")

        showSuccessPopup = true

        /* UNCOMMENT THIS WHEN BACKEND IS READY:

        // Verify payment on backend
        Task {
            do {
                let _ = try await RazorpayService.shared.verifyPayment(
                    orderId: orderId,
                    paymentId: paymentId,
                    signature: "",  // Razorpay SDK provides this in response
                    token: UserDefaults.standard.string(forKey: "authToken") ?? ""
                )

                await MainActor.run {
                    isProcessingPayment = false
                    paymentDetails = PaymentDetails(
                        transactionId: paymentId,
                        amount: cart.totalAmount,
                        timestamp: Date(),
                        status: .success,
                        paymentMethod: "Razorpay",
                        canteenName: canteen?.name ?? "BunkBite",
                        itemCount: cart.items.count
                    )

                    print("✅ Payment Successful & Verified")
                    print("📋 Order ID: \(orderId)")
                    print("💳 Payment ID: \(paymentId)")

                    showSuccessPopup = true
                }
            } catch {
                await MainActor.run {
                    handlePaymentFailure(error: "Payment verification failed: \(error.localizedDescription)")
                }
            }
        }
        */
    }

    private func handlePaymentFailure(error: String) {
        isProcessingPayment = false
        print("❌ Payment Failed: \(error)")
        errorMessage = error
        showErrorAlert = true
    }

    #if DEBUG
    private func mockSuccessfulPayment() {
        isProcessingPayment = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isProcessingPayment = false

            paymentDetails = PaymentDetails(
                transactionId: "TEST\(Int(Date().timeIntervalSince1970))",
                amount: cart.totalAmount,
                timestamp: Date(),
                status: .success,
                paymentMethod: "Mock Payment",
                canteenName: canteen?.name ?? "BunkBite",
                itemCount: cart.items.count
            )

            showSuccessPopup = true
        }
    }
    #endif
}

// MARK: - Payment Method Card
struct PaymentMethodCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(color)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.urbanist(size: 17, weight: .semibold))
                    .foregroundStyle(.black)

                Text(subtitle)
                    .font(.urbanist(size: 14, weight: .regular))
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Payment Success Popup
struct PaymentSuccessPopup: View {
    let onDismiss: () -> Void
    @State private var isAnimating = false
    @State private var showCheckmark = false
    @State private var showContent = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var confettiCounter = 0

    var body: some View {
        VStack(spacing: 24) {
            // Success animation icon with pulse effect
            ZStack {
                // Outer pulsing circle
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseScale)

                // Main circle
                Circle()
                    .fill(Color.green.gradient)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.white)
                            .scaleEffect(showCheckmark ? 1 : 0)
                            .rotationEffect(.degrees(showCheckmark ? 0 : -180))
                    )
                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                    .scaleEffect(isAnimating ? 1 : 0)
            }

            // Success message
            VStack(spacing: 8) {
                Text("Payment Successful!")
                    .font(.urbanist(size: 22, weight: .bold))
                    .foregroundStyle(.black)

                Text("Your order has been placed")
                    .font(.urbanist(size: 14, weight: .regular))
                    .foregroundStyle(.gray)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            // Done button
            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .font(.urbanist(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Constants.primaryColor)
                    .cornerRadius(12)
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.8)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .padding(40)
        .scaleEffect(isAnimating ? 1 : 0.8)
        .confettiCannon(trigger: $confettiCounter, num: 50, confettis: [.text("🎉"), .text("✨"), .text("🍕"), .text("🍔"), .text("☕️")], confettiSize: 20, rainHeight: 600, radius: 400)
        .onAppear {
            // Sequence animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                isAnimating = true
            }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2)) {
                showCheckmark = true
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showContent = true
            }

            // Pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }

            // Trigger confetti celebration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                confettiCounter += 1
            }
        }
    }
}

// MARK: - Razorpay Delegate Class
class RazorpayDelegate: NSObject, RazorpayPaymentCompletionProtocolWithData {
    let cart: Cart
    let canteen: Canteen?
    let currentOrderId: String
    let onSuccess: (String, String) -> Void
    let onFailure: (String) -> Void

    init(cart: Cart, canteen: Canteen?, currentOrderId: String, onSuccess: @escaping (String, String) -> Void, onFailure: @escaping (String) -> Void) {
        self.cart = cart
        self.canteen = canteen
        self.currentOrderId = currentOrderId
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }

    func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable : Any]?) {
        DispatchQueue.main.async {
            print("❌ Payment Error")
            print("Code: \(code)")
            print("Description: \(str)")
            if let response = response {
                print("Response Data: \(response)")
            }
            self.onFailure(str)
        }
    }

    func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable : Any]?) {
        DispatchQueue.main.async {
            print("\n" + String(repeating: "=", count: 60))
            print("🎉 PAYMENT SUCCESS - RAZORPAY RESPONSE")
            print(String(repeating: "=", count: 60))

            // Extract all payment details
            print("\n💳 PAYMENT DETAILS:")
            print("Payment ID: \(payment_id)")
            print("Order ID: \(self.currentOrderId)")

            if let response = response {
                print("\n📦 COMPLETE RESPONSE DATA:")
                for (key, value) in response {
                    print("  \(key): \(value)")
                }

                // Extract specific fields
                let signature = response["razorpay_signature"] as? String ?? ""
                let email = response["email"] as? String
                let contact = response["contact"] as? String
                let method = response["method"] as? String
                let cardId = response["card_id"] as? String
                let bank = response["bank"] as? String
                let wallet = response["wallet"] as? String
                let vpa = response["vpa"] as? String

                print("\n🔐 PAYMENT METHOD DETAILS:")
                if let method = method {
                    print("Method: \(method)")
                }
                if let email = email {
                    print("Email: \(email)")
                }
                if let contact = contact {
                    print("Contact: \(contact)")
                }
                if let cardId = cardId {
                    print("Card ID: \(cardId)")
                }
                if let bank = bank {
                    print("Bank: \(bank)")
                }
                if let wallet = wallet {
                    print("Wallet: \(wallet)")
                }
                if let vpa = vpa {
                    print("UPI ID: \(vpa)")
                }

                // Create comprehensive payment response
                let paymentResponse = RazorpayPaymentResponse(
                    paymentId: payment_id,
                    orderId: self.currentOrderId,
                    signature: signature,
                    email: email,
                    contact: contact,
                    method: method,
                    cardId: cardId,
                    bank: bank,
                    wallet: wallet,
                    vpa: vpa,
                    amountPaid: Int(self.cart.totalAmount * 100),
                    currency: "INR"
                )

                // Create order submission with ALL details
                if let canteen = self.canteen {
                    let userId = UserDefaults.standard.string(forKey: "userId") ?? "user_\(Date().timeIntervalSince1970)"

                    let orderSubmission = OrderSubmissionHelper.createSubmission(
                        from: paymentResponse,
                        cart: self.cart,
                        canteen: canteen,
                        userId: userId
                    )

                    // Print complete order details
                    OrderSubmissionHelper.printOrderDetails(orderSubmission)

                    // Save order locally
                    OrderSubmissionHelper.saveOrderLocally(orderSubmission)

                    // Generate JSON for backend (when ready)
                    if let json = OrderSubmissionHelper.generateJSON(orderSubmission) {
                        print("\n📤 JSON FOR BACKEND:")
                        print(json)
                        print("\n💾 Order saved locally. Send this to backend when ready!")
                    }
                }
            }

            print("\n" + String(repeating: "=", count: 60) + "\n")

            self.onSuccess(payment_id, self.currentOrderId)
        }
    }
}
