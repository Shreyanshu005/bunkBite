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

                    withAnimation(.spring(response: 1.5, dampingFraction: 0.15)) {
                        self?.roll = -(data.gravity.x * 80)
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
    @State private var offset: CGFloat = -200

    var body: some View {
        VStack(spacing: 0) {

            HStack(spacing: 120) {
                Rectangle()
                    .fill(Color.gray.opacity(0.8))
                    .frame(width: 2, height: 60)

                Rectangle()
                    .fill(Color.gray.opacity(0.8))
                    .frame(width: 2, height: 60)
            }
            .frame(height: 60)

            ZStack {

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

        .rotationEffect(.degrees(motion.roll), anchor: .top)
        .offset(y: offset)
        .onAppear {

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                offset = 0
            }
        }
    }
}
