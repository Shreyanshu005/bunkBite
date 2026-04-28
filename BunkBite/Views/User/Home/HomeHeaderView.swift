import SwiftUI

struct HomeHeaderView: View {
    let locationName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Color.green)
                    Text(locationName)
                        .font(.custom("Urbanist-Medium", size: 16))
                        .foregroundStyle(.gray)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Hungry?")
                    .font(.custom("Urbanist-Bold", size: 34))
                    .foregroundStyle(.black)

                Text("Beat the rush.")
                    .font(.custom("Urbanist-Italic", size: 24))
                    .foregroundStyle(.gray)
            }
        }
    }
}
