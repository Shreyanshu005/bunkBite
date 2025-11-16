//
//  OTPVerificationView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct OTPVerificationView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var showContent = false
    @State private var countdown = 30
    @State private var canResend = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Constants.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        withAnimation(Constants.quickBounce) {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Constants.textColor)
                            .frame(width: 40, height: 40)
                            .background(Constants.lightGray)
                            .clipShape(Circle())
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .opacity(showContent ? 1 : 0)

                Spacer()

                // Icon
                Circle()
                    .fill(Constants.primaryColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "envelope.fill")
                            .resizable()
                            .foregroundColor(Constants.primaryColor)
                            .frame(width: 40, height: 30)
                    )
                    .scaleEffect(showContent ? 1 : 0.5)
                    .opacity(showContent ? 1 : 0)
                    .padding(.bottom, 30)

                // Title and Description
                VStack(spacing: 12) {
                    Text("Verify Your Email")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Constants.textColor)

                    Text("Enter the 6-digit code sent to")
                        .font(.system(size: 14))
                        .foregroundColor(Constants.darkGray)

                    Text(viewModel.email)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Constants.primaryColor)
                }
                .multilineTextAlignment(.center)
                .offset(y: showContent ? 0 : 20)
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, 40)

                // OTP Input
                OTPTextField(otp: $viewModel.otp)
                    .padding(.horizontal, 24)
                    .offset(y: showContent ? 0 : 30)
                    .opacity(showContent ? 1 : 0)
                    .padding(.bottom, 24)

                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(Constants.primaryColor)
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(Constants.primaryColor)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .padding(.bottom, 16)
                }

                // Resend OTP
                HStack(spacing: 4) {
                    Text("Didn't receive the code?")
                        .font(.system(size: 14))
                        .foregroundColor(Constants.darkGray)

                    if canResend {
                        Button(action: {
                            Task {
                                canResend = false
                                countdown = 30
                                await viewModel.resendOTP()
                                startCountdown()
                            }
                        }) {
                            Text("Resend")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Constants.primaryColor)
                        }
                    } else {
                        Text("in \(countdown)s")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Constants.darkGray)
                    }
                }
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, 32)

                // Verify Button
                CustomButton(
                    title: "Verify OTP",
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        await viewModel.verifyOTP()
                    }
                }
                .padding(.horizontal, 24)
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(Constants.bouncyAnimation.delay(0.1)) {
                showContent = true
            }
            startCountdown()
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
