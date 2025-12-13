//
//  Order.swift
//  BunkBite
//
//  Created by Shreyanshu on 12/12/25.
//

import Foundation

// MARK: - Order Status Enums
enum OrderStatus: String, Codable {
    case pending = "pending"
    case paid = "paid"
    case preparing = "preparing"
    case ready = "ready"
    case completed = "completed"
    case cancelled = "cancelled"
}

enum PaymentStatus: String, Codable {
    case pending = "pending"
    case success = "success"
    case failed = "failed"
}

// MARK: - Order Line Item (renamed to avoid conflict)
struct OrderLineItem: Codable, Identifiable, Hashable {
    let id: String
    let menuItemId: String
    let name: String
    let price: Double
    let quantity: Int
    
    var subtotal: Double {
        return price * Double(quantity)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case menuItemId, name, price, quantity
    }
}

// MARK: - Order
struct Order: Codable, Identifiable {
    let id: String
    let orderId: String
    let userId: String
    let canteenId: String
    let items: [OrderLineItem]
    let totalAmount: Double
    let status: OrderStatus
    let paymentStatus: PaymentStatus
    let paymentId: String?
    let qrCode: String?
    let createdAt: String
    let updatedAt: String
    
    // Populated fields (optional)
    let canteen: Canteen?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case orderId, userId, canteenId, items, totalAmount
        case status, paymentStatus, paymentId, qrCode
        case createdAt, updatedAt, canteen
    }
    
    // Helper for decoding partial canteen object
    private struct PartialCanteen: Codable {
        let id: String
        enum CodingKeys: String, CodingKey {
            case id = "_id"
        }
    }
    
    // Helper for decoding partial user object
    private struct PartialUser: Codable {
        let id: String
        let email: String?
        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case email
        }
    }
    
    // Custom decoder to handle flexible canteenId and userId fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        orderId = try container.decode(String.self, forKey: .orderId)
        
        // Handle userId as:
        // 1. Partial User object (extract _id)
        // 2. String ID
        if let partialUser = try? container.decode(PartialUser.self, forKey: .userId) {
            userId = partialUser.id
        } else {
            userId = try container.decode(String.self, forKey: .userId)
        }
        
        items = try container.decode([OrderLineItem].self, forKey: .items)
        totalAmount = try container.decode(Double.self, forKey: .totalAmount)
        status = try container.decode(OrderStatus.self, forKey: .status)
        paymentStatus = try container.decode(PaymentStatus.self, forKey: .paymentStatus)
        paymentId = try? container.decode(String.self, forKey: .paymentId)
        qrCode = try? container.decode(String.self, forKey: .qrCode)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        
        // Handle canteenId as:
        // 1. Full Canteen object (ideal)
        // 2. Partial Canteen object (extract _id)
        // 3. String ID
        if let canteenObj = try? container.decode(Canteen.self, forKey: .canteenId) {
            canteen = canteenObj
            canteenId = canteenObj.id
        } else if let partialCanteen = try? container.decode(PartialCanteen.self, forKey: .canteenId) {
            canteenId = partialCanteen.id
            canteen = nil
        } else {
            canteenId = try container.decode(String.self, forKey: .canteenId)
            canteen = nil
        }
    }
    
    // Manual encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(orderId, forKey: .orderId)
        try container.encode(userId, forKey: .userId)
        try container.encode(canteenId, forKey: .canteenId)
        try container.encode(items, forKey: .items)
        try container.encode(totalAmount, forKey: .totalAmount)
        try container.encode(status, forKey: .status)
        try container.encode(paymentStatus, forKey: .paymentStatus)
        try container.encodeIfPresent(paymentId, forKey: .paymentId)
        try container.encodeIfPresent(qrCode, forKey: .qrCode)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - Hashable conformance
extension Order: Hashable {
    static func == (lhs: Order, rhs: Order) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - API Request/Response Models
struct CreateOrderRequest: Codable {
    let canteenId: String
    let items: [CreateOrderItem]
}

struct CreateOrderItem: Codable {
    let menuItemId: String
    let quantity: Int
}

struct PaymentSession: Codable {
    let paymentSessionId: String
    let orderId: String
    let amount: Double
}
