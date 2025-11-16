//
//  LoginSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct LoginSheet: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showOTPSheet = false
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Constants.primaryColor.opacity(0.05),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header with animation
                    VStack(spacing: 16) {
                        // Animated logo
                        ZStack {
                            Circle()
                                .fill(Constants.primaryColor.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .scaleEffect(isAnimating ? 1 : 0.8)

                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(Constants.primaryColor)
                                .scaleEffect(isAnimating ? 1 : 0.5)
                                .rotationEffect(.degrees(isAnimating ? 0 : -180))
                        }
                        .padding(.top, 40)

                        VStack(spacing: 8) {
                            Text("Welcome to BunkBite")
                                .font(.urbanist(size: 32, weight: .bold))
                                .foregroundStyle(.black)

                            Text("Order food from your favorite canteen")
                                .font(.urbanist(size: 16, weight: .regular))
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    }
                    .padding(.horizontal, 24)

                    // Email input card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Enter your email")
                            .font(.urbanist(size: 14, weight: .semibold))
                            .foregroundStyle(.gray)
                            .textCase(.uppercase)
                            .tracking(1)

                        TextField("", text: $authViewModel.email, prompt: Text("you@example.com").foregroundColor(.gray.opacity(0.5)))
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .font(.urbanist(size: 18, weight: .medium))
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(authViewModel.email.isEmpty ? Color.gray.opacity(0.2) : Constants.primaryColor, lineWidth: 2)
                            )

                        if let error = authViewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.urbanist(size: 14, weight: .regular))
                                    .foregroundStyle(.red)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)

                    // Features
                    VStack(spacing: 12) {
                        FeatureRow(icon: "bolt.fill", text: "Quick & Easy Login")
                        FeatureRow(icon: "lock.shield.fill", text: "Secure OTP Verification")
                        FeatureRow(icon: "sparkles", text: "Instant Access")
                    }
                    .padding(.horizontal, 24)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 30)

                    // Send OTP Button
                    Button {
                        Task {
                            await authViewModel.sendOTP()
                            if authViewModel.isOTPSent {
                                showOTPSheet = true
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Sending...")
                                    .font(.urbanist(size: 18, weight: .semibold))
                            } else {
                                Text("Send OTP")
                                    .font(.urbanist(size: 18, weight: .semibold))
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 22))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [
                                    authViewModel.email.isEmpty ? Color.gray : Constants.primaryColor,
                                    authViewModel.email.isEmpty ? Color.gray.opacity(0.8) : Constants.primaryColor.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: authViewModel.email.isEmpty ? .clear : Constants.primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(authViewModel.isLoading || authViewModel.email.isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0.9)

                    Spacer(minLength: 40)
                }
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.gray.opacity(0.3))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
        .sheet(isPresented: $showOTPSheet) {
            OTPSheet(authViewModel: authViewModel, onSuccess: {
                showOTPSheet = false
                dismiss()
            })
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Constants.primaryColor)
                .frame(width: 24)

            Text(text)
                .font(.urbanist(size: 15, weight: .regular))
                .foregroundStyle(.gray)

            Spacer()
        }
    }
}

struct OTPSheet: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    var onSuccess: () -> Void

    @State private var countdown = 30
    @State private var canResend = false
    @FocusState private var isOTPFocused: Bool
    @State private var isAnimating = false
    @State private var otpDigits: [String] = ["", "", "", "", "", ""]

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Constants.primaryColor.opacity(0.05),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        // Animated envelope
                        ZStack {
                            Circle()
                                .fill(Constants.primaryColor.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .scaleEffect(isAnimating ? 1 : 0.8)

                            Image(systemName: "envelope.badge.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(Constants.primaryColor)
                                .scaleEffect(isAnimating ? 1 : 0.5)
                        }
                        .padding(.top, 40)

                        VStack(spacing: 8) {
                            Text("Check Your Email")
                                .font(.urbanist(size: 28, weight: .bold))
                                .foregroundStyle(.black)

                            Text("We sent a code to")
                                .font(.urbanist(size: 15, weight: .regular))
                                .foregroundStyle(.gray)

                            Text(authViewModel.email)
                                .font(.urbanist(size: 15, weight: .semibold))
                                .foregroundStyle(Constants.primaryColor)
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    }
                    .padding(.horizontal, 24)

                    // OTP Input Card
                    VStack(spacing: 20) {
                        Text("Enter 6-Digit Code")
                            .font(.urbanist(size: 14, weight: .semibold))
                            .foregroundStyle(.gray)
                            .textCase(.uppercase)
                            .tracking(1)

                        // OTP Input
                        TextField("", text: $authViewModel.otp, prompt: Text("000000").foregroundColor(.gray.opacity(0.3)))
                            .textContentType(.oneTimeCode)
                            .keyboardType(.numberPad)
                            .focused($isOTPFocused)
                            .multilineTextAlignment(.center)
                            .font(.urbanist(size: 36, weight: .bold))
                            .tracking(8)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(authViewModel.otp.isEmpty ? Color.gray.opacity(0.2) : Constants.primaryColor, lineWidth: 2)
                            )
                            .onChange(of: authViewModel.otp) { oldValue, newValue in
                                if newValue.count > 6 {
                                    authViewModel.otp = String(newValue.prefix(6))
                                }
                            }

                        if let error = authViewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.urbanist(size: 14, weight: .regular))
                                    .foregroundStyle(.red)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)

                    // Verify Button
                    Button {
                        Task {
                            await authViewModel.verifyOTP()
                            if authViewModel.isAuthenticated {
                                onSuccess()
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Verifying...")
                                    .font(.urbanist(size: 18, weight: .semibold))
                            } else {
                                Text("Verify & Continue")
                                    .font(.urbanist(size: 18, weight: .semibold))
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [
                                    authViewModel.otp.count == 6 ? Constants.primaryColor : Color.gray,
                                    authViewModel.otp.count == 6 ? Constants.primaryColor.opacity(0.8) : Color.gray.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: authViewModel.otp.count == 6 ? Constants.primaryColor.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
                    }
                    .disabled(authViewModel.isLoading || authViewModel.otp.count != 6)
                    .padding(.horizontal, 24)
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0.9)

                    // Resend section
                    VStack(spacing: 8) {
                        if canResend {
                            Button {
                                Task {
                                    canResend = false
                                    countdown = 30
                                    await authViewModel.resendOTP()
                                    startCountdown()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Resend Code")
                                        .font(.urbanist(size: 16, weight: .semibold))
                                }
                                .foregroundStyle(Constants.primaryColor)
                            }
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 14))
                                Text("Resend code in \(countdown)s")
                                    .font(.urbanist(size: 15, weight: .regular))
                            }
                            .foregroundStyle(.gray)
                        }
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }

            // Back button
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 32))
                            Text("Back")
                                .font(.urbanist(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.gray.opacity(0.6))
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear {
            isOTPFocused = true
            startCountdown()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                isAnimating = true
            }
        }
    }

    private func startCountdown() {
        countdown = 30
        canResend = false

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
}
