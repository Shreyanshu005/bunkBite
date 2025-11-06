//
//  PaymentSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct PaymentSheet: View {
    @ObservedObject var cart: Cart
    let canteen: Canteen?

    @Environment(\.dismiss) var dismiss
    @State private var upiId = ""
    @State private var showSuccessAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Total Amount")
                            .font(.headline)
                        Spacer()
                        Text("₹\(Int(cart.totalAmount))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Constants.primaryColor)
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    TextField("Enter UPI ID", text: $upiId)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                } header: {
                    Text("UPI Payment")
                } footer: {
                    Text("Enter your UPI ID (e.g., name@paytm)")
                }

                Section {
                    Button("Pay with UPI Apps") {
                        openUPIDeeplink()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .tint(Constants.primaryColor)

                    Button("Pay with UPI ID") {
                        if !upiId.isEmpty {
                            payWithUPI()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(upiId.isEmpty)
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert("Payment Successful", isPresented: $showSuccessAlert) {
            Button("OK") {
                cart.clear()
                dismiss()
            }
        } message: {
            Text("Your order has been placed successfully!")
        }
    }

    private func openUPIDeeplink() {
        let upiURL = "upi://pay?pa=merchant@upi&pn=\(canteen?.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "BunkBite")&am=\(cart.totalAmount)&cu=INR"

        if let url = URL(string: upiURL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    if success {
                        // Simulate payment success after opening UPI app
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showSuccessAlert = true
                        }
                    }
                }
            } else {
                // Fallback to payment success for testing
                showSuccessAlert = true
            }
        }
    }

    private func payWithUPI() {
        // Here you would normally integrate with actual UPI payment gateway
        // For now, we'll simulate success
        showSuccessAlert = true
    }
}
