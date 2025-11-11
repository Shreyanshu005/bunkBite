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

            // Logo with glowing red effect
            ZStack {
                // Glowing red effect behind logo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Constants.primaryColor.opacity(0.4),
                                Constants.primaryColor.opacity(0.2),
                                Constants.primaryColor.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: isPulsing ? 30 : 20)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .opacity(isPulsing ? 0.8 : 1.0)

                // Logo
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(Constants.primaryColor)

                    Text("BunkBite")
                        .font(.urbanist(size: 20, weight: .bold))
                        .foregroundStyle(Constants.primaryColor)
                }
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
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
