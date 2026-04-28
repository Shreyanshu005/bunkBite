import SwiftUI

struct WelcomeScreen: View {
    @Binding var hasSeenWelcome: Bool

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {

                Text("BunkBite")
                    .font(.custom("Urbanist-Bold", size: 28))
                    .foregroundStyle(.black)
                    .padding(.top, 60)

                Spacer()

                Image("get_start")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .clipped()

                Spacer()

                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Text("What are you")
                            .font(.custom("Urbanist-Bold", size: 34))
                            .foregroundStyle(.black)
                    }

                    Text("craving today?")
                        .font(.custom("Urbanist-Bold", size: 34))
                        .foregroundStyle(Constants.primaryColor)
                }
                .multilineTextAlignment(.center)

                Text("Quick order from your college canteen")
                    .font(.custom("Urbanist-Regular", size: 16))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .padding(.top, 12)
                    .multilineTextAlignment(.center)

                Spacer()

                Button(action: {
                    hasSeenWelcome = true
                }) {
                    Text("Get started")
                        .font(.custom("Urbanist-Bold", size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
