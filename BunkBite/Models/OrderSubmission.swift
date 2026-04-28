import Foundation
import UIKit

struct OrderSubmission: Codable {

    let razorpayPaymentId: String
    let razorpayOrderId: String
    let razorpaySignature: String

    let orderId: String
    let totalAmount: Double
    let currency: String
    let itemCount: Int

    let userId: String
    let userPhone: String?
    let userEmail: String?
    let userName: String?

    let canteenId: String
    let canteenName: String

    let items: [OrderItem]

    let orderCreatedAt: Date
    let paymentCompletedAt: Date

    let platform: String
    let appVersion: String
    let deviceModel: String

    enum CodingKeys: String, CodingKey {
        case razorpayPaymentId = "razorpay_payment_id"
        case razorpayOrderId = "razorpay_order_id"
        case razorpaySignature = "razorpay_signature"
        case orderId = "order_id"
        case totalAmount = "total_amount"
        case currency
        case itemCount = "item_count"
        case userId = "user_id"
        case userPhone = "user_phone"
        case userEmail = "user_email"
        case userName = "user_name"
        case canteenId = "canteen_id"
        case canteenName = "canteen_name"
        case items
        case orderCreatedAt = "order_created_at"
        case paymentCompletedAt = "payment_completed_at"
        case platform
        case appVersion = "app_version"
        case deviceModel = "device_model"
    }
}

struct OrderItem: Codable {
    let menuItemId: String
    let name: String
    let quantity: Int
    let unitPrice: Double
    let totalPrice: Double
    let category: String?
    let customizations: [String]?

    enum CodingKeys: String, CodingKey {
        case menuItemId = "menu_item_id"
        case name
        case quantity
        case unitPrice = "unit_price"
        case totalPrice = "total_price"
        case category
        case customizations
    }
}

class OrderSubmissionHelper {

    static func createSubmission(
        from paymentResponse: RazorpayPaymentResponse,
        cart: Cart,
        canteen: Canteen,
        userId: String
    ) -> OrderSubmission {

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let deviceModel = UIDevice.current.model

        let orderItems = cart.items.map { cartItem -> OrderItem in
            OrderItem(
                menuItemId: cartItem.menuItem.id,
                name: cartItem.menuItem.name,
                quantity: cartItem.quantity,
                unitPrice: cartItem.menuItem.price,
                totalPrice: cartItem.totalPrice,
                category: nil,
                customizations: nil
            )
        }

        return OrderSubmission(
            razorpayPaymentId: paymentResponse.razorpayPaymentId,
            razorpayOrderId: paymentResponse.razorpayOrderId,
            razorpaySignature: paymentResponse.razorpaySignature,
            orderId: "ORD_\(Date().timeIntervalSince1970)",
            totalAmount: cart.totalAmount,
            currency: "INR",
            itemCount: cart.items.count,
            userId: userId,
            userPhone: nil,
            userEmail: nil,
            userName: UserDefaults.standard.string(forKey: "userName"),
            canteenId: canteen.id,
            canteenName: canteen.name,
            items: orderItems,
            orderCreatedAt: Date(),
            paymentCompletedAt: Date(),
            platform: "iOS",
            appVersion: appVersion,
            deviceModel: deviceModel
        )
    }

    static func saveOrderLocally(_ submission: OrderSubmission) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if (try? encoder.encode(submission)) != nil {

            var savedOrders = getSavedOrders()
            savedOrders.append(submission)

            if let allEncoded = try? encoder.encode(savedOrders) {
                UserDefaults.standard.set(allEncoded, forKey: "pendingOrders")
                print("✅ Order saved locally: \(submission.orderId)")
                print("📦 Total pending orders: \(savedOrders.count)")
            }
        }
    }

    static func getSavedOrders() -> [OrderSubmission] {
        guard let data = UserDefaults.standard.data(forKey: "pendingOrders") else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return (try? decoder.decode([OrderSubmission].self, from: data)) ?? []
    }

    static func printOrderDetails(_ submission: OrderSubmission) {
        print("\n" + String(repeating: "=", count: 60))
        print("📋 ORDER SUBMISSION DETAILS")
        print(String(repeating: "=", count: 60))

        print("\n🔐 PAYMENT INFORMATION:")
        print("  Payment ID: \(submission.razorpayPaymentId)")
        print("  Order ID: \(submission.razorpayOrderId)")
        print("  Signature: \(submission.razorpaySignature.prefix(20))...")

        print("\n💰 ORDER DETAILS:")
        print("  Amount: ₹\(submission.totalAmount)")
        print("  Currency: \(submission.currency)")
        print("  Items Count: \(submission.itemCount)")

        print("\n👤 USER DETAILS:")
        print("  User ID: \(submission.userId)")
        if let phone = submission.userPhone {
            print("  Phone: \(phone)")
        }
        if let email = submission.userEmail {
            print("  Email: \(email)")
        }

        print("\n🏪 CANTEEN:")
        print("  ID: \(submission.canteenId)")
        print("  Name: \(submission.canteenName)")

        print("\n🛒 ITEMS:")
        for (index, item) in submission.items.enumerated() {
            print("  \(index + 1). \(item.name)")
            print("     Qty: \(item.quantity) × ₹\(item.unitPrice) = ₹\(item.totalPrice)")
        }

        print("\n📱 DEVICE INFO:")
        print("  Platform: \(submission.platform)")
        print("  App Version: \(submission.appVersion)")
        print("  Device: \(submission.deviceModel)")

        print("\n⏰ TIMESTAMPS:")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        print("  Created: \(formatter.string(from: submission.orderCreatedAt))")
        print("  Paid: \(formatter.string(from: submission.paymentCompletedAt))")

        print("\n" + String(repeating: "=", count: 60))
        print("✅ Ready to send to backend when available")
        print(String(repeating: "=", count: 60) + "\n")
    }

    static func generateJSON(_ submission: OrderSubmission) -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        if let jsonData = try? encoder.encode(submission),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return nil
    }
}
