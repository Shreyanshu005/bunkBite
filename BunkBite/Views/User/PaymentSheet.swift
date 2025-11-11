//
//  PaymentSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI
import PopupView
import ConfettiSwiftUI

struct UPIApp: Identifiable {
    let id = UUID()
    let name: String
    let scheme: String
    let icon: String
}

struct PaymentDetails {
    let transactionId: String
    let amount: Double
    let timestamp: Date
    let status: PaymentStatus
    let upiApp: String
    let merchantUPI: String
    let customerUPI: String?
    let canteenName: String
    let itemCount: Int
    let paymentMethod: String

    enum PaymentStatus: String {
        case pending = "Pending"
        case success = "Success"
        case failed = "Failed"
        case verifying = "Verifying"
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
    @State private var upiId = ""
    @State private var showSuccessPopup = false
    @State private var availableUPIApps: [UPIApp] = []
    @State private var isCheckingPayment = false
    @State private var paymentDetails: PaymentDetails?
    @State private var selectedUPIApp: UPIApp?
    @State private var showPaymentDetails = false

    let upiApps = [
        UPIApp(name: "Google Pay", scheme: "tez://upi/pay", icon: "g.circle.fill"),
        UPIApp(name: "PhonePe", scheme: "phonepe://pay", icon: "phone.circle.fill"),
        UPIApp(name: "Paytm", scheme: "paytmmp://pay", icon: "indianrupeesign.circle.fill"),
        UPIApp(name: "BHIM", scheme: "bhim://pay", icon: "b.circle.fill"),
        UPIApp(name: "Amazon Pay", scheme: "amazonpay://pay", icon: "a.circle.fill")
    ]

    @State private var isAnimating = false

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

                            Text("Choose your payment method")
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

                    // Available UPI Apps
                    if !availableUPIApps.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Pay with UPI")
                                .font(.urbanist(size: 14, weight: .semibold))
                                .foregroundStyle(.gray)
                                .textCase(.uppercase)
                                .tracking(1)
                                .padding(.horizontal, 24)

                            VStack(spacing: 12) {
                                ForEach(availableUPIApps) { app in
                                    Button {
                                        openUPIApp(app)
                                    } label: {
                                        HStack(spacing: 16) {
                                            Circle()
                                                .fill(Constants.primaryColor.opacity(0.1))
                                                .frame(width: 50, height: 50)
                                                .overlay(
                                                    Image(systemName: app.icon)
                                                        .font(.system(size: 24))
                                                        .foregroundStyle(Constants.primaryColor)
                                                )

                                            Text(app.name)
                                                .font(.urbanist(size: 17, weight: .semibold))
                                                .foregroundStyle(.black)

                                            Spacer()

                                            Image(systemName: "arrow.right.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundStyle(Constants.primaryColor.opacity(0.3))
                                        }
                                        .padding(16)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 30)
                    }

                    // Manual UPI Payment Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Or Pay with UPI ID")
                            .font(.urbanist(size: 14, weight: .semibold))
                            .foregroundStyle(.gray)
                            .textCase(.uppercase)
                            .tracking(1)

                        TextField("", text: $upiId, prompt: Text("Enter UPI ID (e.g., name@paytm)").foregroundColor(.gray.opacity(0.5)))
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .font(.urbanist(size: 18, weight: .medium))
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(upiId.isEmpty ? Color.gray.opacity(0.2) : Constants.primaryColor, lineWidth: 2)
                            )

                        Button {
                            if !upiId.isEmpty {
                                payWithUPIID()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                if isCheckingPayment {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Verifying Payment...")
                                        .font(.urbanist(size: 18, weight: .semibold))
                                } else {
                                    Text("Pay Now")
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
                                    colors: [
                                        upiId.isEmpty ? Color.gray : Constants.primaryColor,
                                        upiId.isEmpty ? Color.gray.opacity(0.8) : Constants.primaryColor.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: upiId.isEmpty ? .clear : Constants.primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(upiId.isEmpty || isCheckingPayment)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                    .padding(.horizontal, 24)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 30)

                    // Security Features
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Constants.primaryColor)
                                .frame(width: 24)

                            Text("Secure Payment Gateway")
                                .font(.urbanist(size: 15, weight: .regular))
                                .foregroundStyle(.gray)

                            Spacer()
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Constants.primaryColor)
                                .frame(width: 24)

                            Text("Quick & Easy Checkout")
                                .font(.urbanist(size: 15, weight: .regular))
                                .foregroundStyle(.gray)

                            Spacer()
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.orange)
                                .frame(width: 24)

                            Text("Test mode: Payment verification is simulated")
                                .font(.urbanist(size: 13, weight: .regular))
                                .foregroundStyle(.orange)

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
                            paymentDetails = PaymentDetails(
                                transactionId: "TEST\(Int(Date().timeIntervalSince1970))",
                                amount: cart.totalAmount,
                                timestamp: Date(),
                                status: .success,
                                upiApp: "Mock Payment",
                                merchantUPI: "8178785849@fam",
                                customerUPI: nil,
                                canteenName: canteen?.name ?? "BunkBite",
                                itemCount: cart.items.count,
                                paymentMethod: "TEST"
                            )
                            isCheckingPayment = true
                            verifyPaymentStatus()
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
            checkAvailableUPIApps()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Check payment status when app becomes active (user returns from UPI app)
            if isCheckingPayment {
                verifyPaymentStatus()
            }
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

    private func checkAvailableUPIApps() {
        var available: [UPIApp] = []

        for app in upiApps {
            if let url = URL(string: app.scheme), UIApplication.shared.canOpenURL(url) {
                available.append(app)
            }
        }

        availableUPIApps = available
        print("✅ Found \(available.count) UPI apps: \(available.map { $0.name }.joined(separator: ", "))")
    }

    private func openUPIApp(_ app: UPIApp) {
        let merchantUPI = "8178785849@fam"
        let merchantName = canteen?.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "BunkBite"
        let amount = String(format: "%.2f", cart.totalAmount)
        let transactionNote = "Order%20Payment"

        selectedUPIApp = app

        // Build app-specific UPI URL with parameters
        var upiURL: String

        switch app.name {
        case "Google Pay":
            // Google Pay (Tez) format
            upiURL = "tez://upi/pay?pa=\(merchantUPI)&pn=\(merchantName)&am=\(amount)&cu=INR&tn=\(transactionNote)"
        case "PhonePe":
            // PhonePe format
            upiURL = "phonepe://pay?pa=\(merchantUPI)&pn=\(merchantName)&am=\(amount)&cu=INR&tn=\(transactionNote)"
        case "Paytm":
            // Paytm format
            upiURL = "paytmmp://upi/pay?pa=\(merchantUPI)&pn=\(merchantName)&am=\(amount)&cu=INR&tn=\(transactionNote)"
        case "BHIM":
            // BHIM format
            upiURL = "bhim://upi/pay?pa=\(merchantUPI)&pn=\(merchantName)&am=\(amount)&cu=INR&tn=\(transactionNote)"
        case "Amazon Pay":
            // Amazon Pay format
            upiURL = "amazonpay://upi/pay?pa=\(merchantUPI)&pn=\(merchantName)&am=\(amount)&cu=INR&tn=\(transactionNote)"
        default:
            // Generic UPI format as fallback
            upiURL = "upi://pay?pa=\(merchantUPI)&pn=\(merchantName)&am=\(amount)&cu=INR&tn=\(transactionNote)"
        }

        // Generate transaction details
        paymentDetails = PaymentDetails(
            transactionId: "TXN\(Int(Date().timeIntervalSince1970))",
            amount: cart.totalAmount,
            timestamp: Date(),
            status: .verifying,
            upiApp: app.name,
            merchantUPI: merchantUPI,
            customerUPI: upiId.isEmpty ? nil : upiId,
            canteenName: canteen?.name ?? "BunkBite",
            itemCount: cart.items.count,
            paymentMethod: "UPI"
        )

        print("🔗 Opening \(app.name) with URL: \(upiURL)")

        if let url = URL(string: upiURL) {
            isCheckingPayment = true
            UIApplication.shared.open(url) { success in
                if success {
                    print("✅ \(app.name) opened successfully")
                } else {
                    print("❌ Failed to open \(app.name)")
                    isCheckingPayment = false
                }
            }
        }
    }

    private func payWithUPIID() {
        let merchantUPI = "8178785849@fam"
        let merchantName = canteen?.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "BunkBite"
        let amount = String(format: "%.2f", cart.totalAmount)

        let upiURL = "upi://pay?pa=\(merchantUPI)&pn=\(merchantName)&am=\(amount)&cu=INR&tn=Order%20Payment"

        if let url = URL(string: upiURL) {
            isCheckingPayment = true
            UIApplication.shared.open(url) { success in
                if !success {
                    print("❌ No UPI app found")
                    isCheckingPayment = false
                }
            }
        }
    }

    private func verifyPaymentStatus() {
        // Simulate payment verification
        // In production, this would call your backend API to verify the payment
        print("🔍 Verifying payment status...")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // For demo purposes, we'll assume payment is successful
            // In production, check with your payment gateway/backend
            isCheckingPayment = false
            showSuccessPopup = true
            print("✅ Payment verified successfully")
        }
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
