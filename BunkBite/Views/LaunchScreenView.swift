//
//  LaunchScreenView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var logoScale: CGFloat = 0.1
    @State private var logoOpacity: Double = 0
    @State private var logoRotation: Double = -5
    @State private var glowIntensity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 20
    @State private var backgroundScale: CGFloat = 0
    @State private var backgroundOpacity: Double = 0
    @State private var blurRadius: CGFloat = 0
    @State private var zoomScale: CGFloat = 1
    @State private var finalZoomOpacity: Double = 1
    
    var body: some View {
        ZStack {
            // Background layer
            ZStack {
                // White base
                Color.white
                    .ignoresSafeArea()
                
                // Animated gradient background
                if backgroundOpacity > 0 {
                    RadialGradient(
                        colors: [
                            Constants.primaryColor.opacity(0.9),
                            Constants.primaryColor,
                            Constants.primaryColor.opacity(0.8)
                        ],
                        center: .center,
                        startRadius: 100,
                        endRadius: 600
                    )
                    .ignoresSafeArea()
                    .scaleEffect(backgroundScale)
                    .opacity(backgroundOpacity)
                    .blur(radius: blurRadius)
                }
            }
            
            // Main content layer
            VStack(spacing: 20) {
                ZStack {
                    // Outer glow rings
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Constants.primaryColor.opacity(0.3 - Double(index) * 0.1),
                                        Constants.primaryColor.opacity(0.1 - Double(index) * 0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 140 + CGFloat(index) * 30, height: 140 + CGFloat(index) * 30)
                            .opacity(glowIntensity * 0.6)
                            .scaleEffect(glowIntensity)
                    }
                    
                    // Radial glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Constants.primaryColor.opacity(0.4),
                                    Constants.primaryColor.opacity(0.2),
                                    Constants.primaryColor.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .opacity(glowIntensity)
                        .blur(radius: 15)
                    
                    // Logo container
                    ZStack {
                        // Shadow layer
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 130, height: 130)
                            .blur(radius: 20)
                            .offset(y: 8)
                        
                        // Main logo card
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.white.opacity(0.95)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 130, height: 130)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Constants.primaryColor.opacity(0.6),
                                                Constants.primaryColor.opacity(0.3),
                                                Constants.primaryColor.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(
                                color: Constants.primaryColor.opacity(0.3),
                                radius: 30,
                                x: 0,
                                y: 15
                            )
                            .overlay(
                                VStack(spacing: 6) {
                                    // Icon
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 48, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [
                                                    Constants.primaryColor,
                                                    Constants.primaryColor.opacity(0.8)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                    
                                    // App name
                                    Text("BunkBite")
                                        .font(.urbanist(size: 18, weight: .bold))
                                        .foregroundStyle(Constants.primaryColor)
                                        .tracking(0.5)
                                }
                            )
                    }
                    .rotation3DEffect(
                        .degrees(logoRotation),
                        axis: (x: 1, y: 1, z: 0)
                    )
                }
                
                // Tagline
                Text("Skip the Queue, Savor the Flavor")
                    .font(.urbanist(size: 15, weight: .medium))
                    .foregroundStyle(backgroundOpacity > 0.5 ? .white : Constants.primaryColor)
                    .tracking(0.8)
                    .opacity(taglineOpacity)
                    .offset(y: taglineOffset)
                    .shadow(color: .black.opacity(taglineOpacity * 0.2), radius: 10)
            }
            .drawingGroup() // Fix jitter by rasterizing before scaling
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            .scaleEffect(zoomScale)
            .opacity(finalZoomOpacity)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Phase 1: Logo entrance with bounce (0.0s - 1.0s)
        withAnimation(.spring(response: 0.9, dampingFraction: 0.65, blendDuration: 0)) {
            logoScale = 1.0
            logoOpacity = 1.0
            logoRotation = 0
        }
        
        // Glow appears slightly after logo
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            glowIntensity = 1.0
        }
        
        // Tagline slides up (0.6s)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6)) {
            taglineOpacity = 1.0
            taglineOffset = 0
        }
        
        // Phase 2: Background transition (1.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.5)) {
                backgroundScale = 1.0
                backgroundOpacity = 1.0
            }
        }
        
        // Phase 3: Zoom out effect (1.8s - 2.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                zoomScale = 12.0
                finalZoomOpacity = 0
                blurRadius = 30
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
