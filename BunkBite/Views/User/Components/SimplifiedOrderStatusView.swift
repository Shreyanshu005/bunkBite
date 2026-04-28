import SwiftUI

struct SimplifiedOrderStatusView: View {
    let order: Order

    var body: some View {
        VStack(spacing: 24) {

            Group {
                if order.status == .completed {

                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.green)
                            .symbolEffect(.bounce)

                        Text("Enjoy your meal!")
                            .font(.urbanist(size: 20, weight: .bold))
                            .foregroundStyle(.green)
                    }
                } else if order.status == .ready {

                    VStack(spacing: 12) {
                        Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Constants.primaryColor)
                            .symbolEffect(.pulse)

                        Text("Ready for Pickup!")
                            .font(.urbanist(size: 20, weight: .bold))
                            .foregroundStyle(Constants.primaryColor)

                        Text("Show QR code at counter")
                            .font(.urbanist(size: 14, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                } else if order.status == .cancelled {

                    VStack(spacing: 12) {
                        Image(systemName: order.isRefunded ? "arrow.uturn.backward.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(order.isRefunded ? .blue : .red)

                        Text(order.isRefunded ? "Refunded ✓" : "Order Cancelled")
                            .font(.urbanist(size: 20, weight: .bold))
                            .foregroundStyle(order.isRefunded ? .blue : .red)

                        if order.isRefunded {
                            Text("Refund will reflect in 2-3 business days")
                                .font(.urbanist(size: 14, weight: .medium))
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                } else {

                    VStack(spacing: 16) {
                        CookingAnimationView()
                            .frame(height: 80)

                        Text("Cooking in progress...")
                            .font(.urbanist(size: 20, weight: .bold))
                            .foregroundStyle(.orange)

                        Text("We're preparing your yummy food!")
                            .font(.urbanist(size: 14, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 15)
        }
    }
}
