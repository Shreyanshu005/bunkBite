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
    func sendOTP(email: String) async throws -> SendOTPResponse {
        let url = URL(string: "\(Constants.baseURL)/api/v1/auth/email/send-otp")!
        var request = createRequest(url: url, method: "POST")
        request.httpBody = try JSONEncoder().encode(["email": email])

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(SendOTPResponse.self, from: data)
    }

    func verifyOTP(email: String, otp: String) async throws -> AuthResponse {
        let url = URL(string: "\(Constants.baseURL)/api/v1/auth/email/verify-otp")!
        var request = createRequest(url: url, method: "POST")
        request.httpBody = try JSONEncoder().encode(["email": email, "otp": otp])

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    // MARK: - Canteen APIs
    func getAllCanteens(token: String) async throws -> [Canteen] {
        let url = URL(string: "\(Constants.baseURL)/api/v1/canteens")!
        let request = createRequest(url: url, method: "GET", token: token)

        print("\n🌐 FETCHING CANTEENS")
        print("URL: \(url.absoluteString)")
        print("Token: \(token.prefix(20))...")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // Log response
            if let httpResponse = response as? HTTPURLResponse {
                print("Response Status: \(httpResponse.statusCode)")
            }

            let responseString = String(data: data, encoding: .utf8) ?? ""
            print("Response Data: \(responseString)")

            let decodedResponse = try JSONDecoder().decode(CanteenResponse.self, from: data)
            let canteens = decodedResponse.canteens ?? []
            print("✅ Successfully fetched \(canteens.count) canteens\n")
            return canteens
        } catch {
            print("❌ Error fetching canteens: \(error.localizedDescription)")
            print("Error details: \(error)\n")
            throw error
        }
    }

    func getCanteenById(id: String, token: String) async throws -> Canteen {
        let url = URL(string: "\(Constants.baseURL)/api/v1/canteens/\(id)")!
        let request = createRequest(url: url, method: "GET", token: token)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CanteenResponse.self, from: data)
        guard let canteen = response.canteen else { throw APIError.invalidResponse }
        return canteen
    }

    func getMyCanteens(token: String) async throws -> [Canteen] {
        let url = URL(string: "\(Constants.baseURL)/api/v1/canteens/my-canteens")!
        let request = createRequest(url: url, method: "GET", token: token)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CanteenResponse.self, from: data)
        return response.canteens ?? []
    }

    func createCanteen(name: String, place: String, ownerId: String, token: String) async throws -> Canteen {
        let url = URL(string: "\(Constants.baseURL)/api/v1/canteens")!
        var request = createRequest(url: url, method: "POST", token: token)
        request.httpBody = try JSONEncoder().encode(CreateCanteenRequest(name: name, place: place, ownerId: ownerId))

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CanteenResponse.self, from: data)
        guard let canteen = response.canteen else { throw APIError.invalidResponse }
        return canteen
    }

    func updateCanteen(id: String, name: String, place: String, ownerId: String, token: String) async throws -> Canteen {
        let url = URL(string: "\(Constants.baseURL)/api/v1/canteens?id=\(id)")!
        var request = createRequest(url: url, method: "PUT", token: token)
        request.httpBody = try JSONEncoder().encode(CreateCanteenRequest(name: name, place: place, ownerId: ownerId))

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CanteenResponse.self, from: data)
        guard let canteen = response.canteen else { throw APIError.invalidResponse }
        return canteen
    }

    func deleteCanteen(id: String, token: String) async throws {
        let url = URL(string: "\(Constants.baseURL)/api/v1/canteens/\(id)")!
        let request = createRequest(url: url, method: "DELETE", token: token)
        _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - Menu APIs
    func getMenu(canteenId: String, token: String) async throws -> [MenuItem] {
        let url = URL(string: "\(Constants.baseURL)/api/v1/menu/canteen/\(canteenId)")!
        let request = createRequest(url: url, method: "GET", token: token)
        
        print("🌐 Fetching menu for canteen: \(canteenId)")
        print("Request URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Print response status and headers
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status Code: \(httpResponse.statusCode)")
            print("Response Headers: \(httpResponse.allHeaderFields)")
        }
        
        // Print raw response data for debugging
        let responseString = String(data: data, encoding: .utf8) ?? ""
        print("Response Data: \(responseString)")
        
        do {
            // First try to decode the response as a canteen with menu items
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let canteenData = json["canteen"] as? [String: Any],
               let menuItems = canteenData["menu"] as? [[String: Any]] {
                print("✅ Found \(menuItems.count) menu items in canteen.menu")
                return try menuItems.map { itemDict -> MenuItem in
                    guard let id = itemDict["_id"] as? String,
                          let name = itemDict["name"] as? String,
                          let price = itemDict["price"] as? Double,
                          let availableQuantity = itemDict["availableQuantity"] as? Int else {
                        print("❌ Missing required fields in menu item: \(itemDict)")
                        throw APIError.decodingError
                    }
                    let image = itemDict["image"] as? String
                    return MenuItem(
                        id: id,
                        name: name,
                        image: image,
                        price: price,
                        availableQuantity: availableQuantity,
                        createdAt: nil,
                        updatedAt: nil
                    )
                }
            }
            
            // Fall back to the original format if the canteen.menu structure isn't found
            let response = try JSONDecoder().decode(MenuResponse.self, from: data)
            
            if let items = response.items {
                print("✅ Successfully decoded \(items.count) menu items from root items")
                return items
            } else if let message = response.message {
                print("⚠️ API Message: \(message)")
                
                // If we get here, we couldn't find any items
                print("No items found in the response")
                return []
            } else {
                print("❌ Both items and message are nil in the response")
                return []
            }
        } catch {
            print("❌ Failed to decode response: \(error.localizedDescription)")
            throw error
        }
    }

    func getMenuItem(canteenId: String, itemId: String, token: String) async throws -> MenuItem {
        let url = URL(string: "\(Constants.baseURL)/api/v1/menu/canteen/\(canteenId)/item/\(itemId)")!
        let request = createRequest(url: url, method: "GET", token: token)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(MenuResponse.self, from: data)
        guard let item = response.item else { throw APIError.invalidResponse }
        return item
    }

    func addMenuItem(canteenId: String, name: String, price: Double, availableQuantity: Int, token: String) async throws -> MenuItem {
        let url = URL(string: "\(Constants.baseURL)/api/v1/menu/canteen/\(canteenId)")!
        var request = createRequest(url: url, method: "POST", token: token, contentType: "application/x-www-form-urlencoded")
        
        // Create form data with proper encoding
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "price", value: String(price)),
            URLQueryItem(name: "availableQuantity", value: String(availableQuantity))
        ]
        
        // Get the query string and set it as the HTTP body
        if let queryString = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B") {
            request.httpBody = queryString.data(using: .utf8)
            
            // Print the request for debugging
            print("Request URL: \(url.absoluteString)")
            print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
            print("Request Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Print the response for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("Response Status Code: \(httpResponse.statusCode)")
                print("Response Headers: \(httpResponse.allHeaderFields)")
            }
            let responseString = String(data: data, encoding: .utf8) ?? ""
            print("Response Data: \(responseString)")
            
            // Try to decode the response
            do {
                let response = try JSONDecoder().decode(MenuResponse.self, from: data)
                if response.success, let item = response.item {
                    return item
                } else if let message = response.message {
                    print("API Message: \(message)")
                    // If the API returns success but no item, try to construct one from the response
                    if response.success, let itemDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let menuItemDict = itemDict["menuItem"] as? [String: Any],
                       let id = menuItemDict["_id"] as? String,
                       let name = menuItemDict["name"] as? String,
                       let price = menuItemDict["price"] as? Double,
                       let availableQuantity = menuItemDict["availableQuantity"] as? Int {
                        let image = menuItemDict["image"] as? String
                        return MenuItem(id: id, name: name, image: image, price: price, availableQuantity: availableQuantity, createdAt: nil, updatedAt: nil)
                    }
                    // If we can't construct an item, throw the message as an error
                    throw NSError(domain: "APIError", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                } else {
                    throw APIError.invalidResponse
                }
            } catch {
                print("Decoding Error: \(error)")
                throw error
            }
        }
        
        throw APIError.invalidRequest
    }

    func updateMenuItem(canteenId: String, itemId: String, name: String, price: Double, availableQuantity: Int, token: String) async throws -> MenuItem {
        let url = URL(string: "\(Constants.baseURL)/api/v1/menu/canteen/\(canteenId)/item/\(itemId)")!
        var request = createRequest(url: url, method: "PUT", token: token, contentType: "application/x-www-form-urlencoded")
        
        // Create form data with proper encoding
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "price", value: String(price)),
            URLQueryItem(name: "availableQuantity", value: String(availableQuantity))
        ]
        
        // Get the query string and set it as the HTTP body
        if let queryString = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B") {
            request.httpBody = queryString.data(using: .utf8)
            
            // Print the request for debugging
            print("🔄 Updating menu item:")
            print("Request URL: \(url.absoluteString)")
            print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
            print("Request Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Print the response for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("Response Status Code: \(httpResponse.statusCode)")
                print("Response Headers: \(httpResponse.allHeaderFields)")
            }
            let responseString = String(data: data, encoding: .utf8) ?? ""
            print("Response Data: \(responseString)")
            
            // Try to decode the response
            do {
                let response = try JSONDecoder().decode(MenuResponse.self, from: data)
                
                if response.success, let item = response.item {
                    print("✅ Successfully updated menu item: \(item.name)")
                    return item
                } else if let message = response.message {
                    print("⚠️ API Message: \(message)")
                    // If the API returns success but no item, try to construct one from the response
                    if response.success, let itemDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let menuItemDict = itemDict["menuItem"] as? [String: Any],
                       let id = menuItemDict["_id"] as? String,
                       let name = menuItemDict["name"] as? String,
                       let price = menuItemDict["price"] as? Double,
                       let availableQuantity = menuItemDict["availableQuantity"] as? Int {
                        let image = menuItemDict["image"] as? String
                        return MenuItem(id: id, name: name, image: image, price: price, availableQuantity: availableQuantity, createdAt: nil, updatedAt: nil)
                    }
                    // If we can't construct an item, throw the message as an error
                    throw NSError(domain: "APIError", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                } else {
                    throw APIError.invalidResponse
                }
            } catch {
                print("❌ Decoding Error: \(error)")
                throw error
            }
        }
        
        throw APIError.invalidRequest
    }

    func updateMenuItemQuantity(canteenId: String, itemId: String, quantity: Int, token: String) async throws {
        let url = URL(string: "\(Constants.baseURL)/api/v1/menu/canteen/\(canteenId)/item/\(itemId)/quantity")!
        var request = createRequest(url: url, method: "PATCH", token: token, contentType: "application/x-www-form-urlencoded")
        
        // Create form data with proper encoding
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "quantity", value: String(quantity))
        ]
        
        // Get the query string and set it as the HTTP body
        if let queryString = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B") {
            request.httpBody = queryString.data(using: .utf8)
            
            // Print the request for debugging
            print("🔄 Updating menu item quantity:")
            print("Request URL: \(url.absoluteString)")
            print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
            print("Request Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Print the response for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("Response Status Code: \(httpResponse.statusCode)")
                print("Response Headers: \(httpResponse.allHeaderFields)")
                
                // Check for error status codes
                if !(200...299).contains(httpResponse.statusCode) {
                    let responseString = String(data: data, encoding: .utf8) ?? ""
                    print("❌ Error Response: \(responseString)")
                    throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
                }
            }
            
            // Try to parse the response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ Successfully updated quantity for item \(itemId) to \(quantity)")
                    print("Response: \(json)")
                }
            } catch {
                print("⚠️ Warning: Failed to parse response: \(error)")
                // Don't throw here as the update might have been successful
            }
        } else {
            throw APIError.invalidRequest
        }
    }

    func deleteMenuItem(canteenId: String, itemId: String, token: String) async throws {
        let url = URL(string: "\(Constants.baseURL)/api/v1/menu/canteen/\(canteenId)/item/\(itemId)")!
        let request = createRequest(url: url, method: "DELETE", token: token)
        _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - Payment APIs (Cashfree)
    func createCashfreeOrder(amount: Double, canteenId: String, items: [[String: Any]], token: String) async throws -> CashfreeOrderResponse {
        let url = URL(string: "\(Constants.baseURL)/api/v1/payments/create-order")!
        var request = createRequest(url: url, method: "POST", token: token)

        let orderData: [String: Any] = [
            "amount": amount,
            "canteenId": canteenId,
            "items": items
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: orderData)

        print("\n🚀 CREATING CASHFREE ORDER")
        print("URL: \(url.absoluteString)")
        print("Amount: ₹\(amount)")
        print("Canteen ID: \(canteenId)")
        print("Items: \(items.count)")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
        }

        let responseString = String(data: data, encoding: .utf8) ?? ""
        print("Response: \(responseString)\n")

        let orderResponse = try JSONDecoder().decode(CashfreeOrderResponse.self, from: data)
        return orderResponse
    }
}

enum APIError: Error {
    case invalidResponse
    case networkError
    case decodingError
    case invalidRequest

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
        }
    }
}
