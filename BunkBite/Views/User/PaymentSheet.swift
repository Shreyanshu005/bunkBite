//
//  PaymentSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI
import PopupView

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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Total Amount")
                            .font(.urbanist(size: 17, weight: .semibold))
                        Spacer()
                        Text("₹\(Int(cart.totalAmount))")
                            .font(.urbanist(size: 22, weight: .bold))
                            .foregroundStyle(Constants.primaryColor)
                    }
                    .padding(.vertical, 8)
                }

                // Available UPI Apps
                if !availableUPIApps.isEmpty {
                    Section {
                        ForEach(availableUPIApps) { app in
                            Button {
                                openUPIApp(app)
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: app.icon)
                                        .font(.title2)
                                        .foregroundStyle(Constants.primaryColor)
                                        .frame(width: 40)

                                    Text(app.name)
                                        .font(.urbanist(size: 17, weight: .semibold))
                                        .foregroundStyle(.black)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    } header: {
                        Text("Pay with UPI Apps")
                    } footer: {
                        Text("Select an app to complete payment")
                    }
                }

                Section {
                    TextField("Enter UPI ID", text: $upiId)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                } header: {
                    Text("Manual UPI Payment")
                } footer: {
                    Text("Enter your UPI ID (e.g., name@paytm)")
                }

                Section {
                    Button {
                        if !upiId.isEmpty {
                            payWithUPIID()
                        }
                    } label: {
                        if isCheckingPayment {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(.circular)
                                Text("Verifying Payment...")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        } else {
                            Text("Pay with UPI ID")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Constants.primaryColor)
                    .disabled(upiId.isEmpty || isCheckingPayment)
                }
                .listRowBackground(Color.clear)

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Secure Payment", systemImage: "lock.shield")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Label("Quick Checkout", systemImage: "bolt.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            checkAvailableUPIApps()
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
        let merchantUPI = "8178785849@ptyes"
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
        let merchantUPI = "8178785849@ptyes"
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

    var body: some View {
        VStack(spacing: 24) {
            // Success animation icon
            Circle()
                .fill(Color.green.gradient)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                )
                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)

            // Success message
            VStack(spacing: 8) {
                Text("Payment Successful!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)

                Text("Your order has been placed")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }

            // Done button
            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Constants.primaryColor)
                    .cornerRadius(12)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .padding(40)
    }
}
