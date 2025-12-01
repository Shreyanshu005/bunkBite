//
//  CashfreeDelegate.swift
//  BunkBite
//
//  Created by Claude on 17/11/25.
//

import Foundation
import SafariServices

// MARK: - Cashfree Payment Response Model
struct CashfreePaymentResponse {
    let paymentId: String?
    let orderId: String
    let orderAmount: String
    let txStatus: String
    let txMsg: String?
    let referenceId: String?
    let signature: String?
    let paymentMethod: String?
    let paymentTime: String?

    var isSuccess: Bool {
        return txStatus.uppercased() == "SUCCESS"
    }
}

// MARK: - Payment Link Manager for Web Checkout
class CashfreeWebCheckoutManager: NSObject {
    static let shared = CashfreeWebCheckoutManager()

    private var onSuccess: ((CashfreePaymentResponse) -> Void)?
    private var onFailure: ((String) -> Void)?
    private var currentOrderId: String?
    private var currentAmount: Double = 0.0

    private override init() {
        super.init()
    }

    // Open payment link in SFSafariViewController
    func openPaymentLink(
        paymentLink: String,
        orderId: String,
        amount: Double,
        from viewController: UIViewController,
        onSuccess: @escaping (CashfreePaymentResponse) -> Void,
        onFailure: @escaping (String) -> Void
    ) {
        guard let url = URL(string: paymentLink) else {
            onFailure("Invalid payment link")
            return
        }

        self.onSuccess = onSuccess
        self.onFailure = onFailure
        self.currentOrderId = orderId
        self.currentAmount = amount

        print("\n" + String(repeating: "=", count: 60))
        print("🌐 OPENING CASHFREE WEB CHECKOUT")
        print(String(repeating: "=", count: 60))
        print("📦 Order ID: \(orderId)")
        print("💰 Amount: ₹\(amount)")
        print("🔗 Payment Link: \(paymentLink)")
        print("📱 Opening in SFSafariViewController")
        print(String(repeating: "=", count: 60) + "\n")

        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = self
        safariVC.modalPresentationStyle = .pageSheet

        viewController.present(safariVC, animated: true)
    }

    // Handle deep link redirect
    func handlePaymentCallback(url: URL) {
        print("\n" + String(repeating: "=", count: 60))
        print("🔗 RECEIVED PAYMENT DEEP LINK")
        print(String(repeating: "=", count: 60))
        print("URL: \(url.absoluteString)")

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            handleFailure("Invalid callback URL")
            return
        }

        // Parse query parameters
        var params: [String: String] = [:]
        components.queryItems?.forEach { item in
            params[item.name] = item.value
        }

        print("📝 Parameters: \(params)")
        print(String(repeating: "=", count: 60) + "\n")

        // Extract payment status
        guard let orderId = params["order_id"] ?? currentOrderId else {
            handleFailure("Missing order ID in callback")
            return
        }

        let status = params["order_status"] ?? params["status"] ?? "UNKNOWN"

        if status.uppercased() == "PAID" || status.uppercased() == "SUCCESS" {
            let response = CashfreePaymentResponse(
                paymentId: params["cf_payment_id"],
                orderId: orderId,
                orderAmount: String(currentAmount),
                txStatus: "SUCCESS",
                txMsg: params["txMsg"],
                referenceId: params["reference_id"],
                signature: params["signature"],
                paymentMethod: params["payment_method"],
                paymentTime: ISO8601DateFormatter().string(from: Date())
            )

            handleSuccess(response)
        } else {
            let errorMsg = params["txMsg"] ?? "Payment failed or cancelled"
            handleFailure(errorMsg)
        }
    }

    private func handleSuccess(_ response: CashfreePaymentResponse) {
        print("✅ Payment successful - Order ID: \(response.orderId)")
        DispatchQueue.main.async {
            self.onSuccess?(response)
            self.cleanup()
        }
    }

    private func handleFailure(_ error: String) {
        print("❌ Payment failed: \(error)")
        DispatchQueue.main.async {
            self.onFailure?(error)
            self.cleanup()
        }
    }

    private func cleanup() {
        onSuccess = nil
        onFailure = nil
        currentOrderId = nil
        currentAmount = 0.0
    }
}

// MARK: - SFSafariViewControllerDelegate
extension CashfreeWebCheckoutManager: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        print("\n⚠️  Safari view controller was dismissed by user")
        handleFailure("Payment cancelled by user")
    }
}
