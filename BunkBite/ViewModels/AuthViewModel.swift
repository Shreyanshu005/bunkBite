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

        do {
            let response = try await apiService.sendOTP(email: email)
            if response.success {
                isOTPSent = true
            }
        } catch {
            errorMessage = "Failed to send OTP. Please try again."
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

        do {
            let response = try await apiService.verifyOTP(email: email, otp: otp)
            if response.success, let user = response.user, let token = response.token {
                currentUser = user
                authToken = token
                isAuthenticated = true

                // Save to UserDefaults
                saveAuthData(user: user, token: token)

                // Notify RootView about login
                NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)

                print("✅ User logged in with role: \(user.role)")
            }
        } catch {
            errorMessage = "Invalid OTP. Please try again."
        }

        isLoading = false
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
