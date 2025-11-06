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
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
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

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CanteenResponse.self, from: data)
        return response.canteens ?? []
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

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(MenuResponse.self, from: data)
        return response.items ?? []
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

        let bodyString = "name=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&price=\(price)&availableQuantity=\(availableQuantity)"
        request.httpBody = bodyString.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(MenuResponse.self, from: data)
        guard let item = response.item else { throw APIError.invalidResponse }
        return item
    }

    func updateMenuItem(canteenId: String, itemId: String, name: String, price: Double, availableQuantity: Int, token: String) async throws -> MenuItem {
        let url = URL(string: "\(Constants.baseURL)/api/v1/menu/canteen/\(canteenId)/item/\(itemId)")!
        var request = createRequest(url: url, method: "PUT", token: token, contentType: "application/x-www-form-urlencoded")

        let bodyString = "name=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&price=\(price)&availableQuantity=\(availableQuantity)"
        request.httpBody = bodyString.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(MenuResponse.self, from: data)
        guard let item = response.item else { throw APIError.invalidResponse }
        return item
    }

    func updateMenuItemQuantity(canteenId: String, itemId: String, quantity: Int, token: String) async throws {
        let url = URL(string: "\(Constants.baseURL)/api/v1/menu/canteen/\(canteenId)/item/\(itemId)/quantity")!
        var request = createRequest(url: url, method: "PATCH", token: token, contentType: "application/x-www-form-urlencoded")
        request.httpBody = "quantity=\(quantity)".data(using: .utf8)
        _ = try await URLSession.shared.data(for: request)
    }

    func deleteMenuItem(canteenId: String, itemId: String, token: String) async throws {
        let url = URL(string: "\(Constants.baseURL)/api/v1/menu/canteen/\(canteenId)/item/\(itemId)")!
        let request = createRequest(url: url, method: "DELETE", token: token)
        _ = try await URLSession.shared.data(for: request)
    }
}

enum APIError: Error {
    case invalidResponse
    case networkError
    case decodingError

    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError:
            return "Network error occurred"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
