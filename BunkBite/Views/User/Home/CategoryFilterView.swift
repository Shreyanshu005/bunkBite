import SwiftUI

struct CategoryFilterView: View {
    let categories: [String]
    @Binding var selectedCategory: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {

                FilterPill(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )

                ForEach(categories, id: \.self) { category in
                    FilterPill(
                        title: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Urbanist-Medium", size: 16))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(isSelected ? Color(hex: "0D1317") : Color(hex: "F3F4F6"))
                .foregroundStyle(isSelected ? .white : .gray)
                .clipShape(Capsule())
        }
        .animation(.spring(), value: isSelected)
    }
}
