//
//  RazorpayDelegate.swift
//  BunkBite
//
//  Created by Claude on 16/11/25.
//

import Foundation
import Razorpay

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
            print("\n" + String(repeating: "=", count: 60))
            print("❌ PAYMENT FAILED - RAZORPAY ERROR")
            print(String(repeating: "=", count: 60))
            print("🔴 Error Code: \(code)")
            print("📝 Description: \(str)")
            print("📦 Order ID: \(self.currentOrderId)")

            if let response = response {
                print("\n📦 ERROR RESPONSE DATA:")
                for (key, value) in response {
                    print("  \(key): \(value)")
                }

                // Extract specific error fields if available
                if let errorDescription = response["error_description"] as? String {
                    print("\n💬 Error Details: \(errorDescription)")
                }
                if let errorReason = response["error_reason"] as? String {
                    print("🔍 Reason: \(errorReason)")
                }
                if let errorSource = response["error_source"] as? String {
                    print("📍 Source: \(errorSource)")
                }
                if let errorStep = response["error_step"] as? String {
                    print("👣 Failed Step: \(errorStep)")
                }
            }

            print("\n💡 TEST MODE TIPS:")
            print("- Use test card: 4111 1111 1111 1111")
            print("- Use test UPI: success@razorpay")
            print("- For netbanking: Select any bank and use Success")
            print(String(repeating: "=", count: 60) + "\n")

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
                    print("Method: \(method.uppercased())")
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

                print("\n🔑 SIGNATURE VERIFICATION:")
                print("Signature: \(signature.isEmpty ? "❌ NOT PROVIDED" : "✅ \(signature.prefix(20))...")")
                print("Status: \(signature.isEmpty ? "⚠️ CANNOT VERIFY" : "✅ READY FOR VERIFICATION")")

                print("\n💰 TRANSACTION SUMMARY:")
                print("Amount Paid: ₹\(Double(self.cart.totalAmount))")
                print("Amount in Paise: \(Int(self.cart.totalAmount * 100))")
                print("Currency: INR")
                print("Items: \(self.cart.items.count)")
                print("Canteen: \(self.canteen?.name ?? "Unknown")")

                print("\n📊 KEY FIELDS FOR BACKEND API:")
                print("┌─────────────────────────────────────────────────")
                print("│ razorpay_payment_id: \(payment_id)")
                print("│ razorpay_order_id: \(self.currentOrderId)")
                print("│ razorpay_signature: \(signature.isEmpty ? "NOT PROVIDED" : signature)")
                print("│ amount: \(Int(self.cart.totalAmount * 100)) (paise)")
                print("│ currency: INR")
                print("│ method: \(method ?? "unknown")")
                print("│ status: captured")
                print("└─────────────────────────────────────────────────")

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
