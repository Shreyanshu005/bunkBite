//
//  RazorpayService.swift
//  BunkBite
//
//  Created by Claude on 11/11/25.
//

import Foundation

// MARK: - Response Models
struct RazorpayOrderResponse: Codable {
    let success: Bool
    let orderId: String
    let amount: Int
    let currency: String
    let key: String?

    enum CodingKeys: String, CodingKey {
        case success
        case orderId = "order_id"
        case amount
        case currency
        case key
    }
}

struct PaymentVerificationResponse: Codable {
    let success: Bool
    let message: String?
    let orderId: String?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case orderId = "order_id"
    }
}

// MARK: - Razorpay Service
class RazorpayService {
    static let shared = RazorpayService()

    private init() {}

    // MARK: - Create Razorpay Order
    /// Creates a Razorpay order on the backend
    /// - Parameters:
    ///   - amount: Total amount in rupees (will be converted to paise)
    ///   - canteenId: ID of the canteen
    ///   - items: Array of cart items
    ///   - token: Authentication token
    /// - Returns: RazorpayOrderResponse with order_id
    func createOrder(
        amount: Double,
        canteenId: String,
        items: [CartItem],
        token: String
    ) async throws -> RazorpayOrderResponse {
        guard let url = URL(string: "\(Constants.baseURL)/api/payments/create-order") else {
            throw RazorpayError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Convert amount to paise (1 rupee = 100 paise)
        let amountInPaise = Int(amount * 100)

        // Convert cart items to dictionary format
        let itemsDict = items.map { item -> [String: Any] in
            return [
                "menu_item_id": item.menuItem.id,
                "name": item.menuItem.name,
                "quantity": item.quantity,
                "price": item.menuItem.price
            ]
        }

        let body: [String: Any] = [
            "amount": amountInPaise,
            "currency": "INR",
            "canteen_id": canteenId,
            "items": itemsDict
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RazorpayError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw RazorpayError.serverError(errorMessage)
            }
            throw RazorpayError.serverError("Failed to create order. Status: \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            return try decoder.decode(RazorpayOrderResponse.self, from: data)
        } catch {
            print("❌ Decoding error: \(error)")
            throw RazorpayError.decodingError(error)
        }
    }

    // MARK: - Verify Payment
    /// Verifies the payment with the backend
    /// - Parameters:
    ///   - orderId: Razorpay order ID
    ///   - paymentId: Razorpay payment ID
    ///   - signature: Payment signature from Razorpay
    ///   - token: Authentication token
    /// - Returns: PaymentVerificationResponse
    func verifyPayment(
        orderId: String,
        paymentId: String,
        signature: String,
        token: String
    ) async throws -> PaymentVerificationResponse {
        guard let url = URL(string: "\(Constants.baseURL)/api/payments/verify") else {
            throw RazorpayError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = [
            "razorpay_order_id": orderId,
            "razorpay_payment_id": paymentId,
            "razorpay_signature": signature
        ]

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RazorpayError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw RazorpayError.verificationFailed(errorMessage)
            }
            throw RazorpayError.verificationFailed("Payment verification failed")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(PaymentVerificationResponse.self, from: data)
    }
}

// MARK: - Razorpay Errors
enum RazorpayError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case orderCreationFailed
    case verificationFailed(String)
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)
    case paymentCancelled
    case paymentFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for payment service"
        case .invalidResponse:
            return "Invalid response from server"
        case .orderCreationFailed:
            return "Failed to create payment order"
        case .verificationFailed(let message):
            return "Payment verification failed: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .paymentCancelled:
            return "Payment was cancelled"
        case .paymentFailed(let message):
            return "Payment failed: \(message)"
        }
    }
}
