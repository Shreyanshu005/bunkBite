//
//  AuthViewModel.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var otp: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isOTPSent: Bool = false
    @Published var currentUser: User?
    @Published var authToken: String?
    @Published var isAuthenticated: Bool = false

    private let apiService = APIService.shared

    func sendOTP() async {
        guard !email.isEmpty, isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }

        isLoading = true
        errorMessage = nil

        // APPLE REVIEW TEST CREDENTIALS EXCEPTION
        // Skip API call for test@apple.com
        if email.lowercased() == "test@apple.com" {
            print("✅ Apple Review test email detected - skipping OTP send")
            isOTPSent = true
            isLoading = false
            return
        }

        // Regular OTP send flow
        do {
            let response = try await apiService.sendOTP(email: email)
            if response.success {
                isOTPSent = true
            } else {
                errorMessage = response.message ?? "Failed to send OTP"
            }
        } catch {
            errorMessage = "Failed to send OTP. Please try again."
            print("Send OTP Error: \(error)")
        }

        isLoading = false
    }

    func verifyOTP() async {
        guard otp.count == 6 else {
            errorMessage = "Please enter a valid 6-digit OTP"
            return
        }

        isLoading = true
        errorMessage = nil

        // APPLE REVIEW TEST CREDENTIALS EXCEPTION
        // For App Store review purposes only
        if email.lowercased() == "test@apple.com" && otp == "000000" {
            // Create a test user for Apple Review
            let testUser = User(
                id: "apple_review_test_user",
                email: "test@apple.com",
                name: "Apple Reviewer",
                role: "user"
            )
            let testToken = "apple_review_test_token_\(UUID().uuidString)"

            currentUser = testUser
            authToken = testToken
            isAuthenticated = true

            // Save to UserDefaults
            saveAuthData(user: testUser, token: testToken)

            // Notify RootView about login
            NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)

            print("✅ Apple Review test user logged in")
            isLoading = false
            return
        }

        // Regular OTP verification flow
        do {
            let response = try await apiService.verifyOTP(email: email, otp: otp)
            if response.success, let token = response.token {
                // Decode JWT to get user details
                let claims = JWTDecoder.decode(jwtToken: token)
                print("DEBUG: JWT Claims: \(claims)") // Add logging

                // Try multiple keys for ID: 'sub', 'id', '_id', 'userId'
                let userId = (claims["sub"] as? String) ??
                             (claims["id"] as? String) ??
                             (claims["_id"] as? String) ??
                             (claims["userId"] as? String)

                if let userId = userId {
                    let userRole = claims["role"] as? String ?? "user" // Default to user if role missing
                    let userName = claims["name"] as? String ?? "User"
                    let userEmail = claims["email"] as? String ?? email
                    
                    let user = User(id: userId, email: userEmail, name: userName, role: userRole)
                    
                    currentUser = user
                    authToken = token
                    isAuthenticated = true

                    // Save to UserDefaults
                    saveAuthData(user: user, token: token)

                    // Notify RootView about login
                    NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)

                    print("✅ User logged in with role: \(user.role)")
                    print("✅ User ID: \(user.id)")
                } else {
                    print("❌ Failed to find User ID in claims. Keys found: \(claims.keys)")
                    errorMessage = "Failed to decode user information from token. Check logs."
                }
            } else {
                errorMessage = "Invalid OTP"
            }
        } catch {
            errorMessage = "Invalid OTP. Please try again."
            print("Verify OTP Error: \(error)")
        }

        isLoading = false
    }

    func deleteAccount() async -> Bool {
        guard let token = authToken else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiService.deleteAccount(token: token)
            print("✅ Account deleted successfully")
            
            // Log out locally after successful deletion on server
            logout()
            isLoading = false
            return true
        } catch {
            print("❌ Delete Account Error: \(error)")
            errorMessage = "Failed to delete account. Please try again."
            isLoading = false
            return false
        }
    }

    func logout() {
        currentUser = nil
        authToken = nil
        isAuthenticated = false
        email = ""
        otp = ""
        isOTPSent = false

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "userData")
        UserDefaults.standard.removeObject(forKey: "selectedCanteen")

        // Notify RootView about logout
        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)

        print("✅ User logged out")
    }

    func checkExistingAuth() {
        if let token = UserDefaults.standard.string(forKey: "authToken"),
           let userData = UserDefaults.standard.data(forKey: "userData"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            authToken = token
            currentUser = user
            isAuthenticated = true
        }
    }

    private func saveAuthData(user: User, token: String) {
        UserDefaults.standard.set(token, forKey: "authToken")
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "userData")
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    func resendOTP() async {
        otp = ""
        await sendOTP()
    }
}
