//
//  OwnerInventoryView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct OwnerInventoryView: View {
    @State private var showContent = false
    @State private var searchText = ""

    var body: some View {
        ZStack {
            Constants.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Inventory")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Constants.textColor)

                    Spacer()

                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Constants.primaryColor)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .opacity(showContent ? 1 : 0)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Constants.darkGray)

                    TextField("Search items...", text: $searchText)
                        .font(.system(size: 16))

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Constants.darkGray)
                        }
                    }
                }
                .padding()
                .background(Constants.lightGray)
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .offset(y: showContent ? 0 : -20)
                .opacity(showContent ? 1 : 0)

                // Stats Cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        StatsCard(icon: "bag.fill", title: "Total Items", value: "42", color: .blue)
                        StatsCard(icon: "exclamationmark.triangle.fill", title: "Low Stock", value: "5", color: .orange)
                        StatsCard(icon: "xmark.circle.fill", title: "Out of Stock", value: "2", color: .red)
                    }
                    .padding(.horizontal, 24)
                }
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, 16)

                // Categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryFilterChip(title: "All", isSelected: true)
                        CategoryFilterChip(title: "Beverages", isSelected: false)
                        CategoryFilterChip(title: "Meals", isSelected: false)
                        CategoryFilterChip(title: "Snacks", isSelected: false)
                        CategoryFilterChip(title: "Healthy", isSelected: false)
                    }
                    .padding(.horizontal, 24)
                }
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, 16)

                // Inventory List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(0..<8, id: \.self) { index in
                            InventoryItemCard(
                                name: "Item \(index + 1)",
                                category: "Category",
                                price: "₹\(50 + index * 10)",
                                stock: index % 4 == 0 ? 0 : (index % 3 == 0 ? 5 : 20),
                                isAvailable: index % 5 != 0
                            )
                            .offset(y: showContent ? 0 : 30)
                            .opacity(showContent ? 1 : 0)
                            .animation(Constants.bouncyAnimation.delay(Double(index) * 0.05), value: showContent)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
    }
}

struct StatsCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(color)
                    )

                Spacer()
            }

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Constants.textColor)

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(Constants.darkGray)
        }
        .frame(width: 140, height: 120)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(Constants.quickBounce) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(Constants.quickBounce) {
                    isPressed = false
                }
            }
        }) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Constants.textColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Constants.primaryColor : Constants.lightGray)
                .cornerRadius(20)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
    }
}

struct InventoryItemCard: View {
    let name: String
    let category: String
    let price: String
    let stock: Int
    let isAvailable: Bool
    @State private var isPressed = false

    var stockColor: Color {
        if stock == 0 { return .red }
        else if stock < 10 { return .orange }
        else { return .green }
    }

    var stockText: String {
        if stock == 0 { return "Out of Stock" }
        else if stock < 10 { return "Low Stock: \(stock)" }
        else { return "In Stock: \(stock)" }
    }

    var body: some View {
        Button(action: {
            withAnimation(Constants.quickBounce) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(Constants.quickBounce) {
                    isPressed = false
                }
            }
        }) {
            HStack(spacing: 16) {
                // Item Image Placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Constants.lightGray)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Constants.darkGray)
                    )

                // Item Details
                VStack(alignment: .leading, spacing: 6) {
                    Text(name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Constants.textColor)

                    Text(category)
                        .font(.system(size: 13))
                        .foregroundColor(Constants.darkGray)

                    HStack(spacing: 8) {
                        Text(stockText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(stockColor)

                        Circle()
                            .fill(stockColor)
                            .frame(width: 6, height: 6)
                    }
                }

                Spacer()

                // Price and Toggle
                VStack(alignment: .trailing, spacing: 8) {
                    Text(price)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Constants.primaryColor)

                    Toggle("", isOn: .constant(isAvailable))
                        .labelsHidden()
                        .scaleEffect(0.8)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
    }
}
