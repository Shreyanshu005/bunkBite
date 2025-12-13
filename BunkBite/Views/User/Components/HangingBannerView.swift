import SwiftUI
import CoreMotion
import Combine

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    
    init() {
        startUpdates()
    }
    
    func startUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.02
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                guard let data = data else { return }
                
                DispatchQueue.main.async {
                    // Calculate rotation based on gravity (accelerometer)
                    // We only care about rotation around the Z axis (roll) for the 2D hanging effect
                    // data.gravity.x ranges from -1 to 1. -1 is tilted left, 1 is tilted right.
                    // We map -1...1 to -45...45 degrees for a realistic swing range
                    
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        self?.roll = data.gravity.x * 60 // Max 60 degrees tilt
                    }
                }
            }
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct HangingBannerView: View {
    let message: String
    let subMessage: String
    
    @StateObject private var motion = MotionManager()
    @State private var offset: CGFloat = -200 // Start above screen
    
    var body: some View {
        VStack(spacing: 0) {
            // Strings
            HStack(spacing: 120) {
                Rectangle()
                    .fill(Color.gray.opacity(0.8))
                    .frame(width: 2, height: 60)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.8))
                    .frame(width: 2, height: 60)
            }
            .frame(height: 60)
            
            // Sign Board
            ZStack {
                // Board Texture
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "D9534F"), Color(hex: "C9302C")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 280, height: 100)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                
                // Text Content
                VStack(spacing: 4) {
                    Text("CLOSED")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 1, y: 1)
                    
                    Text(message)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    if !subMessage.isEmpty {
                        Text(subMessage)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                
                // Nail Heads
                HStack(spacing: 120) {
                    Circle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
                .offset(y: -40)
            }
        }
        // Physics-like swinging animation based on Gyro/Gravity
        .rotationEffect(.degrees(motion.roll), anchor: .top)
        .offset(y: offset)
        .onAppear {
            // Drop down animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                offset = 0
            }
        }
    }
}


