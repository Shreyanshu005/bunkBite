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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $authViewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } header: {
                    Text("Enter your email")
                } footer: {
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task {
                            await authViewModel.sendOTP()
                            if authViewModel.isOTPSent {
                                showOTPSheet = true
                            }
                        }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Send OTP")
                                .font(.urbanist(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(authViewModel.isLoading || authViewModel.email.isEmpty)
                }
            }
            .navigationTitle("Welcome to BunkBite")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showOTPSheet) {
                OTPSheet(authViewModel: authViewModel, onSuccess: {
                    showOTPSheet = false
                    dismiss()
                })
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

struct OTPSheet: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    var onSuccess: () -> Void

    @State private var countdown = 30
    @State private var canResend = false
    @FocusState private var isOTPFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "envelope.badge.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(Constants.primaryColor)

                            Text("Check your email")
                                .font(.urbanist(size: 18, weight: .semibold))

                            Text(authViewModel.email)
                                .font(.urbanist(size: 14, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)

                Section {
                    TextField("Enter 6-digit OTP", text: $authViewModel.otp)
                        .textContentType(.oneTimeCode)
                        .keyboardType(.numberPad)
                        .focused($isOTPFocused)
                        .multilineTextAlignment(.center)
                        .font(.urbanist(size: 28, weight: .semibold))
                        .onChange(of: authViewModel.otp) { oldValue, newValue in
                            if newValue.count > 6 {
                                authViewModel.otp = String(newValue.prefix(6))
                            }
                        }
                } header: {
                    Text("OTP")
                } footer: {
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task {
                            await authViewModel.verifyOTP()
                            if authViewModel.isAuthenticated {
                                onSuccess()
                            }
                        }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Verify OTP")
                                .font(.urbanist(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(authViewModel.isLoading || authViewModel.otp.count != 6)
                }

                Section {
                    if canResend {
                        Button("Resend OTP") {
                            Task {
                                canResend = false
                                countdown = 30
                                await authViewModel.resendOTP()
                                startCountdown()
                            }
                        }
                        .font(.urbanist(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Resend OTP in \(countdown)s")
                            .font(.urbanist(size: 15, weight: .regular))
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Verify OTP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            isOTPFocused = true
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
