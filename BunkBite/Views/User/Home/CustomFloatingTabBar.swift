
import SwiftUI

struct CustomFloatingTabBar: View {
    @Binding var selectedTab: Tab
    @EnvironmentObject var cart: Cart
    
    enum Tab: String {
        case menu
        case orders
        case profile
    }
    
    var body: some View {
        HStack(spacing: 25) {
            // Menu Tab
            TabBarButton(
                icon: "fork.knife",
                text: "Menu",
                isSelected: selectedTab == .menu,
                action: { selectedTab = .menu }
            )
            
            // Orders Tab (was Cart)
            TabBarButton(
                icon: "bag",
                text: "Orders",
                isSelected: selectedTab == .orders,
                action: { selectedTab = .orders }
            )
            
            // Profile Tab
            TabBarButton(
                icon: "person",
                text: "Profile",
                isSelected: selectedTab == .profile,
                action: { selectedTab = .profile }
            )
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 9)
        .background(Color.black)
        .clipShape(Capsule())
        .padding(.horizontal, 40)
        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: selectedTab)
        .ignoresSafeArea(.keyboard) 
    }
}

struct TabBarButton: View {
    let icon: String
    let text: String
    let isSelected: Bool
    var badgeCount: Int = 0
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .frame(width: 24, height: 24)
                    
                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(Constants.primaryColor)
                            .clipShape(Circle())
                            .offset(x: 8, y: -8)
                    }
                }
                
                if isSelected {
                    Text(text)
                        .font(.custom("Urbanist-Bold", size: 14))
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .frame(height: 24)
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, isSelected ? 25 : 12)
            .background(
                ZStack {
                     if isSelected {
                         Capsule()
                             .fill(Constants.primaryColor)
                         Capsule()
                             .stroke(Color(hex: "06BD52"), lineWidth: 1)
                     }
                }
            )
            .clipShape(Capsule())
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: isSelected)
    }
}
