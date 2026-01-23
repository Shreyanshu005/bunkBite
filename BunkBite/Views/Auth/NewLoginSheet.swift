//
//  NewLoginSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 15/01/26.
//

import SwiftUI

struct NewLoginSheet: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var isPresented: Bool
    @State private var email: String = ""
    @State private var showOTPSheet = false
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Heading
            VStack(spacing: 8) {
                Text("Welcome to BunkBite")
                    .font(.custom("Urbanist-Bold", size: 24))
                    .foregroundStyle(.black)
                
                Text("Order food from your favourite canteen")
                    .font(.custom("Urbanist-Regular", size: 16))
                    .foregroundStyle(Color(hex: "6B7280"))
            }
            
            // Email Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter your Email")
                    .font(.custom("Urbanist-Medium", size: 14))
                    .foregroundStyle(Color(hex: "374151"))
                
                TextField("you@example.com", text: $email)
                    .font(.custom("Urbanist-Regular", size: 16))
                    .padding()
                    .background(Color(hex: "F9FAFB"))
                    .cornerRadius(12)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }
            
            // Continue Button
            Button(action: {
                sendOTP()
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                } else {
                    Text("Send OTP")
                        .font(.custom("Urbanist-Bold", size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
            }
            .background(Color.black)
            .cornerRadius(12)
            .disabled(email.isEmpty || isLoading)
            .opacity(email.isEmpty ? 0.5 : 1.0)
            
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
        .sheet(isPresented: $showOTPSheet) {
            OTPVerificationSheet(
                authViewModel: authViewModel,
                email: email,
                isPresented: $showOTPSheet,
                parentIsPresented: $isPresented
            )
            .presentationDetents([.fraction(0.5), .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.white)
            .interactiveDismissDisabled(false)
        }
    }
    
    private func sendOTP() {
        isLoading = true
        authViewModel.email = email
        Task {
            await authViewModel.sendOTP()
            isLoading = false
            
            if authViewModel.errorMessage == nil {
                showOTPSheet = true
            }
        }
    }
}
