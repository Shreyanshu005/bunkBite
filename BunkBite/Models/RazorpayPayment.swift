import Foundation

struct RazorpayPaymentInitiation: Codable {
    let razorpayOrderId: String
    let razorpayKeyId: String
    let amount: Int
    let currency: String
    let orderId: String
}

struct RazorpayVerificationRequest: Codable {
    let razorpayOrderId: String
    let razorpayPaymentId: String
    let razorpaySignature: String
}

struct RazorpayPaymentResponse {
    let razorpayOrderId: String
    let razorpayPaymentId: String
    let razorpaySignature: String

    init?(from dictionary: [String: Any]) {
        guard let orderId = dictionary["razorpay_order_id"] as? String,
              let paymentId = dictionary["razorpay_payment_id"] as? String,
              let signature = dictionary["razorpay_signature"] as? String else {
            return nil
        }

        self.razorpayOrderId = orderId
        self.razorpayPaymentId = paymentId
        self.razorpaySignature = signature
    }
}
