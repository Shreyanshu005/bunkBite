
import SwiftUI

struct HomeHeaderView: View {
    let locationName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Top Bar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill") // Using fill variant for better visibility
                        .foregroundStyle(Color.green) // Using simplified color
                    Text(locationName)
                        .font(.custom("Urbanist-Medium", size: 16))
                        .foregroundStyle(.gray)
                }
                
                Spacer()
            }
            
            // Greeter
            VStack(alignment: .leading, spacing: 4) {
                Text("Hungry?")
                    .font(.custom("Urbanist-Bold", size: 34))
                    .foregroundStyle(.black)
                
                Text("Beat the rush.")
                    .font(.custom("Urbanist-Italic", size: 24)) // Attempting Italic
                    .foregroundStyle(.gray)
            }
        }
    }
}
