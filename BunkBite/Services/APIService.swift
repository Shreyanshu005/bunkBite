//
//  APIService.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import Foundation

class APIService {
    static let shared = APIService()
    private init() {}

    private func createRequest(url: URL, method: String, token: String? = nil, contentType: String = "application/json") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        // Only add auth header if token is provided and not the guest token
        if let token = token, token != "guest_token" {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        // If guest_token, skip auth header (public endpoint)

        return request
    }

    // MARK: - Authentication
    func sendOTP(email: String) async throws -> APIResponse<String> {
        let url = URL(string: "\(Constants.baseURL)/api/v1/auth/email/send-otp")!
        var request = createRequest(url: url, method: "POST")
        request.httpBody = try JSONEncoder().encode(["email": email])

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(APIResponse<String>.self, from: data)
    }

    func verifyOTP(email: String, otp: String) async throws -> AuthResponse {
        let url = URL(string: "\(Constants.baseURL)/api/v1/auth/email/verify-otp")!
        var request = createRequest(url: url, method: "POST")
        request.httpBody = try JSONEncoder().encode(["email": email, "otp": otp])

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func deleteAccount(token: String) async throws {
        let url = URL(string: "\(Constants.baseURL)/api/v1/auth/me")!
        let request = createRequest(url: url, method: "DELETE", token: token)
        
        print("\n🗑️ DELETING ACCOUNT")
        print("URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? ""
        print("Raw Response Data: \(responseString)")
        
        // CHECK FOR HTML (Likely 404 or 500)
        if responseString.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<") {
            print("❌ Server returned HTML. Probable cause: Endpoint not found (404) on this URL.")
            print("Verify if '\(url.absoluteString)' is the correct deployed address.")
            throw APIError.invalidResponse
        }
        
        // Use JSONSerialization for flexibility
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let success = json["success"] as? Bool, success {
                    return // Success!
                } else {
                    let message = json["message"] as? String ?? "Unknown error"
                    print("❌ API returned success=false: \(message)")
                    throw APIError.invalidResponse
                }
            }
        } catch {
            print("❌ JSON Serialization Error: \(error)")
            throw APIError.decodingError
        }
    }

    // MARK: - Canteen APIs
    func getAllCanteens() async throws -> [Canteen] {
        let url = URL(string: "\(Constants.baseURL)/api/v1/canteens")!
        let request = createRequest(url: url, method: "GET")

        print("\n🌐 FETCHING ALL CANTEENS (Public Endpoint)")
        print("URL: \(url.absoluteString)")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")

        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? ""
        print("Response Data: \(responseString)")
        print("Response Data Length: \(data.count) bytes")
        
        do {
            let apiResponse = try JSONDecoder().decode(APIResponse<[Canteen]>.self, from: data)
            let canteens = apiResponse.data ?? []
            print("✅ Successfully decoded \(canteens.count) canteens\n")
            return canteens
        } catch {
            print("❌ Decoding Error: \(error)")
            print("Error details: \(error.localizedDescription)\n")
            throw error
        }
    }

    func getCanteenById(id: String, token: String) async throws -> Canteen {
        let url = URL(string: "\(Constants.baseURL)/api/v1/canteens/\(id)")!
        let request = createRequest(url: url, method: "GET", token: token)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(APIResponse<Canteen>.self, from: data)
        guard let canteen = response.data else { throw APIError.invalidResponse }
        return canteen
    }

    func getMyCanteens(token: String) async throws -> [Canteen] {
        let url = URL(string: "\(Constants.baseURL)/api/v1/canteens/my-canteens")!
        let request = createRequest(url: url, method: "GET", token: token)

        print("\n🏢 FETCHING OWNER CANTEENS")
        print("URL: \(url.absoluteString)")
        print("Token: \(token.prefix(20))...")

        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response Data: \(responseString)")
        }

        let apiResponse = try JSONDecoder().decode(APIResponse<[Canteen]>.self, from: data)
        let canteens = apiResponse.data ?? []
        print("✅ Fetched \(canteens.count) owner canteens\n")
        return canteens
    }

    func createCanteen(name: String, place: String, ownerId: String, token: String) async throws -> Canteen {
        let url = URL(string: "\(Constants.baseURL)/api/v1/canteens")!
        var request = createRequest(url: url, method: "POST", token: token)
        let body = CreateCanteenRequest(name: name, place: place, ownerId: ownerId)
        request.httpBody = try JSONEncoder().encode(body)

        // Debug logging
        print("🚀 Creating Canteen...")
        print("URL: \(url.absoluteString)")
        print("OwnerID: \(ownerId)")
        if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
            print("Request Body: \(bodyString)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response Data: \(responseString)")
        }

        let apiResponse = try JSONDecoder().decode(APIResponse<Canteen>.self, from: data)
        guard let canteen = apiResponse.data else {
            print("❌ API Error Message: \(apiResponse.message ?? "Unknown")")
            throw APIError.invalidResponse
        }
        print("✅ Canteen created: \(canteen.name)")
        return canteen
    }

    func updateCanteen(id: String, name: String, place: String, ownerId: String, token: String) async throws -> Canteen {
        let url = URL(string: "\(Constants.baseURL)/api/v1/canteens?id=\(id)")!
        var request = createRequest(url: url, method: "PUT", token: token)
        request.httpBody = try JSONEncoder().encode(CreateCanteenRequest(name: name, place: place, ownerId: ownerId))

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(APIResponse<Canteen>.self, from: data)
        guard let canteen = response.data else { throw APIError.invalidResponse }
        return canteen
    }

    func deleteCanteen(id: String, token: String) async throws {
        let url = URL(string: "\(Constants.baseURL)/api/v1/canteens/\(id)")!
        let request = createRequest(url: url, method: "DELETE", token: token)
        let (data, _) = try await URLSession.shared.data(for: request)
        _ = try JSONDecoder().decode(APIResponse<EmptyData>.self, from: data)
    }

    // MARK: - Menu APIs
    func getMenu(canteenId: String) async throws -> [MenuItem] {
        let url = URL(string: "\(Constants.baseURL)/api/v1/menu/canteen/\(canteenId)")!
        let request = createRequest(url: url, method: "GET")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(APIResponse<[MenuItem]>.self, from: data)
        return response.data ?? []
    }

    func getMenuItem(canteenId: String, itemId: String, token: String) async throws -> MenuItem {
        let url = URL(string: "\(Constants.baseURL)/api/v1/menu/canteen/\(canteenId)/item/\(itemId)")!
        let request = createRequest(url: url, method: "GET", token: token)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(APIResponse<MenuItem>.self, from: data)
        guard let item = response.data else { throw APIError.invalidResponse }
        return item
    }

    func addMenuItem(canteenId: String, name: String, price: Double, availableQuantity: Int, token: String) async throws -> MenuItem {
        let url = URL(string: "\(Constants.baseURL)/api/v1/menu/canteen/\(canteenId)")!
        var request = createRequest(url: url, method: "POST", token: token, contentType: "application/x-www-form-urlencoded")
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "price", value: String(price)),
            URLQueryItem(name: "availableQuantity", value: String(availableQuantity))
        ]
        
        if let queryString = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B") {
            request.httpBody = queryString.data(using: .utf8)
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(APIResponse<MenuItem>.self, from: data)
            guard let item = response.data else { throw APIError.invalidResponse }
            return item
        }
        
        throw APIError.invalidRequest
    }

    func updateMenuItem(canteenId: String, itemId: String, name: String, price: Double, availableQuantity: Int, token: String) async throws -> MenuItem {
        let url = URL(string: "\(Constants.baseURL)/api/v1/menu/canteen/\(canteenId)/item/\(itemId)")!
        var request = createRequest(url: url, method: "PUT", token: token, contentType: "application/x-www-form-urlencoded")
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "price", value: String(price)),
            URLQueryItem(name: "availableQuantity", value: String(availableQuantity))
        ]
        
        if let queryString = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B") {
            request.httpBody = queryString.data(using: .utf8)
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(APIResponse<MenuItem>.self, from: data)
            guard let item = response.data else { throw APIError.invalidResponse }
            return item
        }
        
        throw APIError.invalidRequest
    }

    func updateMenuItemQuantity(canteenId: String, itemId: String, quantity: Int, token: String) async throws {
        let url = URL(string: "\(Constants.baseURL)/api/v1/menu/canteen/\(canteenId)/item/\(itemId)/quantity")!
        var request = createRequest(url: url, method: "PATCH", token: token, contentType: "application/x-www-form-urlencoded")
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "quantity", value: String(quantity))
        ]
        
        if let queryString = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B") {
            request.httpBody = queryString.data(using: .utf8)
            let (data, _) = try await URLSession.shared.data(for: request)
            _ = try JSONDecoder().decode(APIResponse<MenuItem>.self, from: data)
        } else {
            throw APIError.invalidRequest
        }
    }

    func deleteMenuItem(canteenId: String, itemId: String, token: String) async throws {
        let url = URL(string: "\(Constants.baseURL)/api/v1/menu/canteen/\(canteenId)/item/\(itemId)")!
        let request = createRequest(url: url, method: "DELETE", token: token)
        let (data, _) = try await URLSession.shared.data(for: request)
        _ = try JSONDecoder().decode(APIResponse<EmptyData>.self, from: data)
    }



    // MARK: - Order APIs
    
    // Get orders for a specific canteen (Owner)
    func getCanteenOrders(canteenId: String, status: String? = nil, token: String) async throws -> [Order] {
        var urlString = "\(Constants.baseURL)/api/v1/orders/canteen/\(canteenId)"
        if let status = status {
            urlString += "?status=\(status)"
        }
        let url = URL(string: urlString)!
        let request = createRequest(url: url, method: "GET", token: token)
        
        print("\n📋 FETCHING CANTEEN ORDERS")
        print("Canteen ID: \(canteenId)")
        if let status = status {
            print("Status Filter: \(status)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
        }
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Raw Response:")
            print(responseString)
        }
        
        do {
            let apiResponse = try JSONDecoder().decode(APIResponse<[Order]>.self, from: data)
            let orders = apiResponse.data ?? []
            print("✅ Fetched \(orders.count) orders\n")
            return orders
        } catch {
            print("❌ Decoding Error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Missing key: \(key.stringValue)")
                    print("Context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type: \(type)")
                    print("Context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Value not found for type: \(type)")
                    print("Context: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error")
                }
            }
            throw error
        }
    }
    
    // Update order status (Owner)
    func updateOrderStatus(orderId: String, status: String, token: String) async throws -> Order {
        let url = URL(string: "\(Constants.baseURL)/api/v1/orders/\(orderId)/status")!
        var request = createRequest(url: url, method: "PATCH", token: token)
        
        let body = ["status": status]
        request.httpBody = try JSONEncoder().encode(body)
        
        print("\n🔄 UPDATING ORDER STATUS")
        print("Order ID: \(orderId)")
        print("New Status: \(status)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<Order>.self, from: data)
        guard let order = apiResponse.data else {
            print("❌ Failed to update order status")
            throw APIError.invalidResponse
        }
        
        print("✅ Order status updated to: \(order.status)\n")
        return order
    }
    
    func createOrder(canteenId: String, items: [CreateOrderItem], token: String) async throws -> Order {
        let url = URL(string: "\(Constants.baseURL)/api/v1/orders")!
        var request = createRequest(url: url, method: "POST", token: token)
        let body = CreateOrderRequest(canteenId: canteenId, items: items)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try encoder.encode(body)

        print("\n🛒 CREATING ORDER")
        print("URL: \(url.absoluteString)")
        print("Canteen ID: \(canteenId)")
        print("Items Count: \(items.count)")
        
        // Print request body
        if let requestBody = request.httpBody,
           let requestString = String(data: requestBody, encoding: .utf8) {
            print("Request Body:")
            print(requestString)
        }
        
        // Print items details
        for (index, item) in items.enumerated() {
            print("  Item \(index + 1): menuItemId=\(item.menuItemId), quantity=\(item.quantity)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response Data: \(responseString)")
        }

        let apiResponse = try JSONDecoder().decode(APIResponse<Order>.self, from: data)
        guard let order = apiResponse.data else {
            let errorMsg = apiResponse.message ?? "Failed to create order"
            print("❌ API Error Message: \(errorMsg)")
            throw APIError.apiMessage(errorMsg)
        }
        print("✅ Order created: \(order.orderId)\n")
        return order
    }

    func getMyOrders(status: String? = nil, token: String) async throws -> [Order] {
        var urlString = "\(Constants.baseURL)/api/v1/orders"
        if let status = status {
            urlString += "?status=\(status)"
        }
        let url = URL(string: urlString)!
        let request = createRequest(url: url, method: "GET", token: token)

        let (data, _) = try await URLSession.shared.data(for: request)
        let apiResponse = try JSONDecoder().decode(APIResponse<[Order]>.self, from: data)
        return apiResponse.data ?? []
    }

    func getOrderById(id: String, token: String) async throws -> Order {
        let url = URL(string: "\(Constants.baseURL)/api/v1/orders/\(id)")!
        let request = createRequest(url: url, method: "GET", token: token)

        print("\n🔍 FETCHING ORDER DETAILS")
        print("URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response Data: \(responseString)")
        }

        let apiResponse = try JSONDecoder().decode(APIResponse<Order>.self, from: data)
        guard let order = apiResponse.data else {
            print("❌ invalidResponse: data is nil. Message: \(apiResponse.message ?? "None")")
            throw APIError.invalidResponse
        }
        return order
    }

    func initiatePayment(orderId: String, token: String) async throws -> RazorpayPaymentInitiation {
        let url = URL(string: "\(Constants.baseURL)/api/v1/payments/initiate")!
        var request = createRequest(url: url, method: "POST", token: token)
        request.httpBody = try JSONEncoder().encode(["orderId": orderId])

        print("\n💳 INITIATING RAZORPAY PAYMENT")
        print("Order ID: \(orderId)")

        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response: \(responseString)")
        }

        let apiResponse = try JSONDecoder().decode(APIResponse<RazorpayPaymentInitiation>.self, from: data)
        guard let paymentData = apiResponse.data else {
            print("❌ Payment initiation failed")
            throw APIError.invalidResponse
        }
        print("✅ Razorpay Order Created")
        print("Razorpay Order ID: \(paymentData.razorpayOrderId)")
        print("Amount: \(paymentData.amount)\n")
        return paymentData
    }

    func verifyPayment(razorpayOrderId: String, razorpayPaymentId: String, razorpaySignature: String, token: String) async throws -> Order {
        let url = URL(string: "\(Constants.baseURL)/api/v1/payments/verify")!
        var request = createRequest(url: url, method: "POST", token: token)
        
        let verificationRequest = RazorpayVerificationRequest(
            razorpayOrderId: razorpayOrderId,
            razorpayPaymentId: razorpayPaymentId,
            razorpaySignature: razorpaySignature
        )
        request.httpBody = try JSONEncoder().encode(verificationRequest)

        print("\n✅ VERIFYING RAZORPAY PAYMENT (Standard Checkout)")
        print("Order ID: \(razorpayOrderId)")
        print("Payment ID: \(razorpayPaymentId)")
        print("Signature: \(razorpaySignature.prefix(20))...")

        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response Data: \(responseString)")
        }

        let apiResponse = try JSONDecoder().decode(APIResponse<Order>.self, from: data)
        guard let order = apiResponse.data else {
            print("❌ Payment verification failed")
            throw APIError.invalidResponse
        }
        print("✅ Payment verified successfully")
        print("Order Status: \(order.status)")
        print("Payment Status: \(order.paymentStatus)\n")
        return order
    }


    // MARK: - Scan-to-Pickup Endpoints
    
    func verifyQR(qrData: String, token: String) async throws -> Order {
        let url = URL(string: "\(Constants.baseURL)/api/v1/orders/verify-qr")!
        var request = createRequest(url: url, method: "POST", token: token)
        
        let body = ["qrData": qrData]
        request.httpBody = try JSONEncoder().encode(body)
        
        print("\n🔍 VERIFYING QR CODE")
        print("QR Data: \(qrData)")
        print("Token: \(token.prefix(20))...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Error Response: \(errorString)")
                }
            }
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<Order>.self, from: data)
        guard let order = apiResponse.data else {
            print("❌ No order data in response")
            throw APIError.invalidResponse
        }
        
        print("✅ QR Verified: Order \(order.orderId)")
        return order
    }
    
    func completePickup(qrData: String, token: String) async throws -> Order {
        let url = URL(string: "\(Constants.baseURL)/api/v1/orders/pickup")!
        var request = createRequest(url: url, method: "POST", token: token)
        
        let body = ["qrData": qrData]
        request.httpBody = try JSONEncoder().encode(body)
        
        print("\n✅ COMPLETING PICKUP")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<Order>.self, from: data)
        guard let order = apiResponse.data else {
            // Need to create a new error case for errors from backend
            throw APIError.invalidResponse 
        }
        
        print("✅ Pickup Completed: Order \(order.orderId)")
        return order
    }
    
    // MARK: - Analytics APIs
    
    func getAnalytics(canteenId: String, period: String, token: String) async throws -> AnalyticsSummary {
        let url = URL(string: "\(Constants.baseURL)/api/v1/analytics/canteen/\(canteenId)?period=\(period)")!
        let request = createRequest(url: url, method: "GET", token: token)
        
        print("\n📊 FETCHING ANALYTICS (\(period))")
        print("URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response Data: \(responseString)")
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<AnalyticsSummary>.self, from: data)
        guard let summary = apiResponse.data else { throw APIError.invalidResponse }
        return summary
    }
    
    func getEarnings(canteenId: String, period: String, token: String) async throws -> EarningsData {
        let url = URL(string: "\(Constants.baseURL)/api/v1/analytics/canteen/\(canteenId)/earnings?period=\(period)")!
        let request = createRequest(url: url, method: "GET", token: token)
        
        print("\n💰 FETCHING EARNINGS (\(period))")
        print("URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            // Check for HTML response (often indicates 404 page)
            if responseString.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<!DOCTYPE html>") {
                print("❌ Received HTML response (likely 404 Page Not Found)")
            } else {
                print("Response Data: \(responseString)")
            }
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<EarningsData>.self, from: data)
        guard let earnings = apiResponse.data else { throw APIError.invalidResponse }
        return earnings
    }
    
    // MARK: - Canteen Management
    
    func updateCanteen(canteenId: String, data: [String: Any], token: String) async throws -> Canteen {
        let url = URL(string: "\(Constants.baseURL)/api/v1/canteens?id=\(canteenId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<Canteen>.self, from: responseData)
        guard let canteen = apiResponse.data else { throw APIError.invalidResponse }
        return canteen
    }
    
    func toggleCanteenStatus(canteenId: String, token: String) async throws -> Canteen {
        let url = URL(string: "\(Constants.baseURL)/api/v1/canteens/\(canteenId)/status")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<Canteen>.self, from: responseData)
        guard let canteen = apiResponse.data else { throw APIError.invalidResponse }
        return canteen
    }
}

enum APIError: Error {
    case invalidResponse
    case networkError
    case decodingError
    case invalidRequest
    case apiMessage(String)

    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError:
            return "Network error occurred"
        case .decodingError:
            return "Failed to decode response"
        case .invalidRequest:
            return "Invalid request"
        case .apiMessage(let message):
            return message
        }
    }
}
