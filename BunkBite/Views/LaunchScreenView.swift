//
//  LaunchScreenView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Constants.primaryColor,
                    Constants.primaryColor.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // Animated Logo Container
                ZStack {
                    // Outer rotating circle
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(rotationAngle))

                    // Middle pulsing circle
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 130, height: 130)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)

                    // Logo Icon
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 100, height: 100)

                        VStack(spacing: 4) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(Constants.primaryColor)

                            Text("BB")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(Constants.primaryColor)
                        }
                    }
                    .scaleEffect(scale)
                }
                .opacity(opacity)

                // App Name with Bouncy Animation
                VStack(spacing: 8) {
                    Text("BunkBite")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)

                    Text("Fresh Food, Instant Delivery")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .opacity(opacity)
                .offset(y: isAnimating ? 0 : 20)

                // Loading Dots
                HStack(spacing: 12) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .opacity(opacity)
                .padding(.top, 20)
            }
        }
        .onAppear {
            // Start animations
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1.0
            }

            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                scale = 1.0
            }

            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(0.3)) {
                isAnimating = true
            }

            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenView()
    }
}
