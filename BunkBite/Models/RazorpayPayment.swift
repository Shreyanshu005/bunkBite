//
//  RazorpayPayment.swift
//  BunkBite
//
//  Created by Shreyanshu on 12/12/25.
//

import Foundation

// MARK: - Razorpay Payment Initiation Response (Standard Checkout)
struct RazorpayPaymentInitiation: Codable {
    let razorpayOrderId: String
    let razorpayKeyId: String
    let amount: Int  // in paise (₹1 = 100 paise)
    let currency: String
    let orderId: String  // Internal order ID
}

// MARK: - Razorpay Verification Request (Standard Checkout)
struct RazorpayVerificationRequest: Codable {
    let razorpayOrderId: String
    let razorpayPaymentId: String
    let razorpaySignature: String
}

// MARK: - Razorpay Payment Response (from JavaScript)
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
