//
//  EmailLoginView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct EmailLoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var showContent = false

    var body: some View {
        ZStack {
            Constants.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo and Title
                VStack(spacing: 20) {
                    Circle()
                        .fill(Constants.primaryColor.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "fork.knife.circle.fill")
                                .resizable()
                                .foregroundColor(Constants.primaryColor)
                                .frame(width: 60, height: 60)
                        )
                        .scaleEffect(showContent ? 1 : 0.5)
                        .opacity(showContent ? 1 : 0)

                    Text("BunkBite")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Constants.textColor)
                        .offset(y: showContent ? 0 : 20)
                        .opacity(showContent ? 1 : 0)

                    Text("Your Canteen, Your Way")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Constants.darkGray)
                        .offset(y: showContent ? 0 : 20)
                        .opacity(showContent ? 1 : 0)
                }
                .padding(.bottom, 60)

                // Email Input Form
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Constants.darkGray)

                        CustomTextField(
                            placeholder: "Enter your email",
                            text: $viewModel.email,
                            keyboardType: .emailAddress
                        )
                    }
                    .offset(y: showContent ? 0 : 30)
                    .opacity(showContent ? 1 : 0)

                    if let errorMessage = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(Constants.primaryColor)
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(Constants.primaryColor)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    CustomButton(
                        title: "Send OTP",
                        isLoading: viewModel.isLoading
                    ) {
                        Task {
                            await viewModel.sendOTP()
                        }
                    }
                    .offset(y: showContent ? 0 : 30)
                    .opacity(showContent ? 1 : 0)
                }
                .padding(.horizontal, 24)

                Spacer()

                Text("Made with ❤️ for your campus")
                    .font(.system(size: 12))
                    .foregroundColor(Constants.darkGray)
                    .padding(.bottom, 40)
                    .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(Constants.bouncyAnimation.delay(0.1)) {
                showContent = true
            }
        }
    }
}
