//
//  PaymentSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI
import PopupView
import ConfettiSwiftUI
import SafariServices

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
    @State private var currentOrderId: String = ""

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

                            Text("Secure payment via Cashfree")
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
                            PaymentMethodCard(
                                icon: "indianrupeesign.circle.fill",
                                title: "UPI",
                                subtitle: "Google Pay, PhonePe, Paytm & More",
                                color: .green
                            )

                            PaymentMethodCard(
                                icon: "creditcard.fill",
                                title: "Cards",
                                subtitle: "Credit & Debit Cards",
                                color: .blue
                            )

                            PaymentMethodCard(
                                icon: "building.columns.fill",
                                title: "Netbanking",
                                subtitle: "All major banks supported",
                                color: .orange
                            )

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

                            Text("Secured by Cashfree")
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
        print("\n" + String(repeating: "=", count: 60))
        print("🔵 PAYMENT BUTTON CLICKED - initiatePayment() called")
        print(String(repeating: "=", count: 60))

        guard let canteen = canteen else {
            print("❌ ERROR: No canteen information available")
            handlePaymentFailure(error: "Canteen information not available")
            return
        }

        isProcessingPayment = true
        print("✅ isProcessingPayment set to true")

        let amountInRupees = cart.totalAmount

        print("\n🚀 INITIATING PAYMENT (Cashfree Web Checkout)")
        print("Amount: ₹\(amountInRupees)")
        print("Canteen: \(canteen.name)")
        print("Items: \(cart.items.count)")
        print("Cashfree App ID: \(Constants.cashfreeAppId.prefix(20))...")
        print("Environment: \(Constants.cashfreeEnvironment.rawValue)\n")

        // Create order and get payment link from Cashfree
        Task {
            do {
                let orderId = "order_\(UUID().uuidString.prefix(12))"

                print("⚠️  Creating order with Cashfree API")
                print("📝 TODO: Move this to backend /api/v1/payments/create-order endpoint")

                // Call Cashfree API to create order and get payment link
                let paymentLink = try await createCashfreeOrderAndGetLink(
                    orderId: orderId,
                    amount: amountInRupees
                )

                print("✅ Received payment link from Cashfree:")
                print("   Order ID: \(orderId)")
                print("   Payment Link: \(paymentLink)")
                print("")

                await MainActor.run {
                    currentOrderId = orderId
                    openWebCheckout(
                        paymentLink: paymentLink,
                        orderId: orderId,
                        amount: amountInRupees
                    )
                }
            } catch {
                print("❌ Failed to create order: \(error.localizedDescription)")
                await MainActor.run {
                    handlePaymentFailure(error: "Failed to create order: \(error.localizedDescription)")
                }
            }
        }
    }

    // TEMPORARY: Direct Cashfree API call for testing
    // TODO: Move this to backend
    private func createCashfreeOrderAndGetLink(orderId: String, amount: Double) async throws -> String {
        let url = URL(string: "https://sandbox.cashfree.com/pg/orders")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Constants.cashfreeAppId, forHTTPHeaderField: "x-client-id")
        request.setValue(Constants.cashfreeSecretKey, forHTTPHeaderField: "x-client-secret")
        request.setValue("2023-08-01", forHTTPHeaderField: "x-api-version")

        print("\n🔍 DEBUG: Cashfree API Request Details")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Endpoint: \(url.absoluteString)")
        print("Method: POST")
        print("App ID: \(Constants.cashfreeAppId)")
        print("Secret Key (first 20 chars): \(Constants.cashfreeSecretKey.prefix(20))...")
        print("API Version: 2023-08-01")
        print("Environment: \(Constants.cashfreeEnvironment.rawValue)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

        let orderData: [String: Any] = [
            "order_id": orderId,
            "order_amount": amount,
            "order_currency": "INR",
            "customer_details": [
                "customer_id": "test_user_\(Int.random(in: 1000...9999))",
                "customer_phone": "9999999999",
                "customer_email": "test@bunkbite.com"
            ],
            "order_meta": [
                "return_url": "https://test.cashfree.com/pgappsdemos/return.php?order_id=\(orderId)"
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: orderData)

        // Print the actual JSON being sent
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 Request Body:\n\(jsonString)\n")
        }

        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("Cashfree API Response Status: \(httpResponse.statusCode)")

            if httpResponse.statusCode != 200 {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Cashfree API Error: \(errorMsg)")
                throw NSError(domain: "CashfreeError", code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
        }

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("Full API Response: \(json)")

            // Try to get payment_link if it exists
            if let paymentLink = json["payment_link"] as? String {
                return paymentLink
            }

            // If payment_link doesn't exist, construct it from payment_session_id
            if let paymentSessionId = json["payment_session_id"] as? String {
                // Construct the Cashfree hosted checkout URL
                let baseUrl = Constants.cashfreeEnvironment == .sandbox
                    ? "https://sandbox.cashfree.com/pg/view/pay"
                    : "https://payments.cashfree.com/pg/view/pay"
                return "\(baseUrl)?payment_session_id=\(paymentSessionId)"
            }
        }

        throw NSError(domain: "CashfreeError", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response from Cashfree - missing payment_link or payment_session_id"])
    }

    private func openWebCheckout(paymentLink: String, orderId: String, amount: Double) {
        print("\n💳 TEST PAYMENT OPTIONS:")
        print("- Test Card: 4111 1111 1111 1111")
        print("- CVV: 123")
        print("- Expiry: Any future date (e.g., 12/25)")
        print("- Test UPI: testsuccess@gocash")
        print("")

        // Get the topmost view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            handlePaymentFailure(error: "Unable to open payment window")
            return
        }

        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }

        // Open payment link in SFSafariViewController
        CashfreeWebCheckoutManager.shared.openPaymentLink(
            paymentLink: paymentLink,
            orderId: orderId,
            amount: amount,
            from: topController,
            onSuccess: { [self] response in
                self.handlePaymentSuccess(response: response)
            },
            onFailure: { [self] error in
                self.handlePaymentFailure(error: error)
            }
        )
    }

    private func handlePaymentSuccess(response: CashfreePaymentResponse) {
        isProcessingPayment = false
        paymentDetails = PaymentDetails(
            transactionId: response.paymentId ?? response.orderId,
            amount: cart.totalAmount,
            timestamp: Date(),
            status: .success,
            paymentMethod: "Cashfree",
            canteenName: canteen?.name ?? "BunkBite",
            itemCount: cart.items.count
        )

        print("\n✅ Payment Successful")
        print("📋 Order ID: \(response.orderId)")
        print("💳 Payment ID: \(response.paymentId ?? "N/A")")
        print("💾 Order data saved - ready to send to backend\n")

        showSuccessPopup = true
    }

    private func handlePaymentFailure(error: String) {
        isProcessingPayment = false
        print("❌ Payment Failed: \(error)")

        // More detailed error message for debugging
        let detailedError = """
        Payment Error:
        \(error)

        Check console for more details.
        """

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
