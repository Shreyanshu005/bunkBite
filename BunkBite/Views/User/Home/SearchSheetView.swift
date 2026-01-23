
import SwiftUI

struct SearchSheetView: View {
    @Binding var searchText: String
    // @Binding var isPresented: Bool // Not used, isSearchOpen is enough
    @Binding var isSearchOpen: Bool
    
    var menuItems: [MenuItem]
    @ObservedObject var cart: Cart
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var showLoginSheet: Bool
    
    // Recent Searches - Persisted
    @AppStorage("recentSearches") private var recentSearchesData: Data = Data()
    @State private var recentSearches: [String] = []
    
    var searchResults: [MenuItem] {
        if searchText.isEmpty { return [] }
        return menuItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Top Row: Back Button
            HStack {
                Button {
                   withAnimation {
                       isSearchOpen = false
                       hideKeyboard()
                   }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundStyle(.black)
                        .padding(8)
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            
            // Search Bar (Active)
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundStyle(.black)
                
                TextField("Search for food...", text: $searchText)
                    .font(.custom("Urbanist-Regular", size: 16))
                    .submitLabel(.search)
                    .onSubmit {
                         addToHistory(searchText)
                    }
                    .focused($isFocused)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "E5E7EB"), lineWidth: 1.0)
            )
            
            if !searchText.isEmpty {
                // Search Results or Empty State
                if searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray.opacity(0.3))
                        Text("No items found for \"\(searchText)\"")
                            .font(.custom("Urbanist-Bold", size: 18))
                            .foregroundStyle(.gray)
                        Spacer() // Push content up
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 20) {
                            ForEach(searchResults) { item in
                                FoodItemCard(
                                    item: item,
                                    cart: cart,
                                    authViewModel: authViewModel,
                                    showLoginSheet: $showLoginSheet
                                )
                            }
                        }
                        .padding(.top, 10)
                    }
                    .scrollIndicators(.hidden)
                }
            } else {
                // Recent and Suggested Searches Scrollable
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Recent Searches
                        if !recentSearches.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Recent Searches")
                                        .font(.custom("Urbanist-Bold", size: 16))
                                        .foregroundStyle(.black)
                                    Spacer()
                                    Button { clearHistory() } label: {
                                        Text("Clear")
                                            .font(.custom("Urbanist-Medium", size: 14))
                                            .foregroundStyle(Constants.primaryColor)
                                    }
                                }
                                
                                FlowLayout(items: recentSearches.prefix(3)) { search in
                                    SearchChip(text: search, icon: "clock") {
                                        withAnimation { searchText = search }
                                    }
                                }
                            }
                        }
                        
                        // Suggested Searches
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Suggested for You")
                                .font(.custom("Urbanist-Bold", size: 16))
                                .foregroundStyle(.black)
                            
                            let suggestions = ["Samosa", "Coffee", "Rice"] // Limited to 3
                            FlowLayout(items: suggestions) { search in
                                SearchChip(text: search, icon: "sparkles") {
                                    withAnimation { searchText = search }
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
        .padding(20)
        .padding(.top, 50) 
        .padding(.bottom, 20)
        .contentShape(Rectangle()) // Ensure the whole area is tappable
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            loadHistory()
            isFocused = true
        }
    }
    
    @FocusState private var isFocused: Bool
    
    // MARK: - Helpers
    private func addToHistory(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        if let index = recentSearches.firstIndex(of: text) {
            recentSearches.remove(at: index)
        }
        recentSearches.insert(text, at: 0)
        
        // Limit to 10
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
        saveHistory()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(recentSearches) {
            recentSearchesData = encoded
        }
    }
    
    private func loadHistory() {
        if let decoded = try? JSONDecoder().decode([String].self, from: recentSearchesData) {
            recentSearches = decoded
        }
    }
    
    private func clearHistory() {
        recentSearches.removeAll()
        saveHistory()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct SearchChip: View {
    let text: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.gray.opacity(0.7))
                
                Text(text)
                    .font(.custom("Urbanist-Medium", size: 14))
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "E5E7EB"), lineWidth: 1.0)
            )
        }
    }
}

// Simple Flow Layout
struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content
    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                self.content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > g.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == self.items.last! {
                            width = 0 //last item
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: {d in
                        let result = height
                        if item == self.items.last! {
                            height = 0 // last item
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}


