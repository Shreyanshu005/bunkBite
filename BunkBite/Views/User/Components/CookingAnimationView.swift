import SwiftUI

struct CookingAnimationView: View {
    @State private var isAnimating = false
    @State private var steamOffset: CGFloat = 0
    @State private var panRotate: Double = 0
    @State private var foodOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Pan Handle
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray)
                .frame(width: 80, height: 12)
                .offset(x: 60, y: 0)
            
            // Pan Body
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 100, y: 0))
                path.addCurve(to: CGPoint(x: 50, y: 40), control1: CGPoint(x: 90, y: 40), control2: CGPoint(x: 60, y: 40))
                path.addCurve(to: CGPoint(x: 0, y: 0), control1: CGPoint(x: 40, y: 40), control2: CGPoint(x: 10, y: 40))
            }
            .fill(Color.black.opacity(0.8))
            .frame(width: 100, height: 40)
            
            // Food Items
            ForEach(0..<3) { i in
                Circle()
                    .fill(i == 0 ? Color.orange : (i == 1 ? Color.green : Color.red))
                    .frame(width: 12, height: 12)
                    .offset(x: CGFloat(i * 15 - 15), y: foodOffset)
            }
            
            // Steam
            ForEach(0..<3) { i in
                Path { path in
                    path.move(to: CGPoint(x: 20 + (i * 20), y: -20))
                    path.addQuadCurve(to: CGPoint(x: 30 + (i * 20), y: -50), control: CGPoint(x: 40 + (i * 20), y: -35))
                }
                .stroke(Color.gray.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .offset(y: steamOffset)
                .opacity(1.0 - (steamOffset / -40.0)) // Fade out as it rises
            }
        }
        .rotationEffect(.degrees(panRotate))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                panRotate = 10
            }
            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                foodOffset = -15
            }
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                steamOffset = -40
            }
        }
    }
}
