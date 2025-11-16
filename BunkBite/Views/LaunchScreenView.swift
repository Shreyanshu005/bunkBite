//
//  LaunchScreenView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Square logo with rounded borders
                ZStack {
                    // Logo container with rounded square
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                        .shadow(color: Constants.primaryColor.opacity(0.2), radius: 20, x: 0, y: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Constants.primaryColor.opacity(0.3),
                                            Constants.primaryColor.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 44, weight: .medium))
                                    .foregroundStyle(Constants.primaryColor)

                                Text("BunkBite")
                                    .font(.urbanist(size: 16, weight: .bold))
                                    .foregroundStyle(Constants.primaryColor)
                            }
                        )
                }
                .padding(.bottom, 24)

                // Red gradient pulse below logo
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Constants.primaryColor,
                                Constants.primaryColor.opacity(0.7),
                                Constants.primaryColor.opacity(0.4)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: isPulsing ? 80 : 60, height: 6)
                    .opacity(isPulsing ? 0.6 : 1.0)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
