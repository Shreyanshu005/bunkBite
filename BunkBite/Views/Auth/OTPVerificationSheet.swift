//
//  OTPVerificationSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 15/01/26.
//

import SwiftUI

struct OTPVerificationSheet: View {
    @ObservedObject var authViewModel: AuthViewModel
    let email: String
    @Binding var isPresented: Bool
    @Binding var parentIsPresented: Bool
    
    @State private var otp: String = ""
    @State private var isLoading = false
    @State private var isResending = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Heading
            VStack(spacing: 8) {
                Text("Enter OTP")
                    .font(.custom("Urbanist-Bold", size: 24))
                    .foregroundStyle(.black)
                
                Text("We've sent a code to \(maskEmail(email))")
                    .font(.custom("Urbanist-Regular", size: 16))
                    .foregroundStyle(Color(hex: "6B7280"))
            }
            
            // OTP Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter 6-digit code")
                    .font(.custom("Urbanist-Medium", size: 14))
                    .foregroundStyle(Color(hex: "374151"))
                
                TextField("", text: $otp)
                    .font(.custom("Urbanist-Regular", size: 16))
                    .padding()
                    .background(Color(hex: "F9FAFB"))
                    .cornerRadius(12)
                    .keyboardType(.numberPad)
                    .onChange(of: otp) { _, newValue in
                        if newValue.count > 6 {
                            otp = String(newValue.prefix(6))
                        }
                    }
            }
            
            // Verify Button
            Button(action: {
                verifyOTP()
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                } else {
                    Text("Verify")
                        .font(.custom("Urbanist-Bold", size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
            }
            .background(Color.black)
            .cornerRadius(12)
            .disabled(otp.count != 6 || isLoading)
            .opacity(otp.count != 6 ? 0.5 : 1.0)
            
            // Resend OTP
            Button(action: {
                resendOTP()
            }) {
                if isResending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Text("Resend OTP")
                        .font(.custom("Urbanist-Medium", size: 14))
                        .foregroundStyle(.black)
                }
            }
            .disabled(isResending)
            
            // Error message
            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(.custom("Urbanist-Regular", size: 14))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Color.white)
    }
    
    private func verifyOTP() {
        isLoading = true
        authViewModel.email = email
        authViewModel.otp = otp
        Task {
            await authViewModel.verifyOTP()
            isLoading = false
            
            if authViewModel.errorMessage == nil {
                // Success - close both sheets
                isPresented = false
                parentIsPresented = false
            }
        }
    }
    
    private func resendOTP() {
        isResending = true
        authViewModel.email = email
        Task {
            await authViewModel.sendOTP()
            isResending = false
        }
    }
    
    private func maskEmail(_ email: String) -> String {
        let components = email.split(separator: "@")
        guard components.count == 2 else { return email }
        
        let username = String(components[0])
        let domain = String(components[1])
        
        if username.count <= 2 {
            return "\(username)@\(domain)"
        }
        
        let visibleChars = username.prefix(2)
        return "\(visibleChars)...@\(domain)"
    }
}
