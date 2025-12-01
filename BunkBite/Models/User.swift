//
//  User.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let role: String

    var isOwner: Bool {
        return role.lowercased() == "admin"
    }
}

struct AuthResponse: Codable {
    let success: Bool
    let message: String
    let token: String?
    let user: User?
}

struct SendOTPResponse: Codable {
    let success: Bool
    let message: String
}

struct CashfreeOrderResponse: Codable {
    let success: Bool
    let message: String?
    let orderId: String
    let paymentSessionId: String
    let orderAmount: Double?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case orderId = "order_id"
        case paymentSessionId = "payment_session_id"
        case orderAmount = "order_amount"
    }
}
